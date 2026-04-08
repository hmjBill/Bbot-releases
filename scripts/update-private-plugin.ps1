[CmdletBinding()]
param(
  [Parameter(Mandatory = $false)]
  [string]$Version = "dev"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Pkg = if ($env:BBOT_PRIVATE_PKG) { $env:BBOT_PRIVATE_PKG } else { "@hmjbill/bbot-private" }
$OpenClawHome = Join-Path $HOME ".openclaw"
$Cfg = Join-Path $OpenClawHome "openclaw.json"
$Ext = Join-Path $OpenClawHome "extensions/bbot"
$InstalledPkgJson = Join-Path $Ext "package.json"
$Ts = Get-Date -Format "yyyyMMdd-HHmmss"
$Bak = Join-Path $OpenClawHome "openclaw.json.bak.$Ts"
$TmpOnebot = Join-Path $OpenClawHome ".onebot-channel.tmp.$Ts.json"

function Step([string]$Message) {
  Write-Host "[onebot-private-update] $Message"
}

function Save-Json([Parameter(Mandatory = $true)]$Object, [Parameter(Mandatory = $true)][string]$Path) {
  $Object | ConvertTo-Json -Depth 100 | Set-Content -Path $Path -Encoding UTF8
}

function Sanitize-ConfigForInstall {
  if (-not (Test-Path -LiteralPath $Cfg)) { return }
  $cfgObj = Get-Content -LiteralPath $Cfg -Raw | ConvertFrom-Json

  if ($null -ne $cfgObj.channels -and $null -ne $cfgObj.channels.onebot) {
    Save-Json -Object $cfgObj.channels.onebot -Path $TmpOnebot
    $cfgObj.channels.PSObject.Properties.Remove("onebot")
  }

  $cleanupNames = @("bbot", "openclaw-onebot", "@hmjbill/bbot", "@hmjbill/openclaw-onebot", $Pkg)
  if ($null -ne $cfgObj.plugins) {
    if ($cfgObj.plugins.allow -is [System.Array]) {
      $cfgObj.plugins.allow = @(
        $cfgObj.plugins.allow | Where-Object { $cleanupNames -notcontains [string]$_ }
      )
    }
    if ($null -ne $cfgObj.plugins.entries) {
      foreach ($name in $cleanupNames) {
        $cfgObj.plugins.entries.PSObject.Properties.Remove($name)
      }
    }
  }

  Save-Json -Object $cfgObj -Path $Cfg
}

function Restore-OnebotConfig {
  if (-not (Test-Path -LiteralPath $Cfg)) { return }
  if (-not (Test-Path -LiteralPath $TmpOnebot)) { return }

  $cfgObj = Get-Content -LiteralPath $Cfg -Raw | ConvertFrom-Json
  $onebotObj = Get-Content -LiteralPath $TmpOnebot -Raw | ConvertFrom-Json

  if ($null -eq $cfgObj.channels) {
    $cfgObj | Add-Member -NotePropertyName "channels" -NotePropertyValue ([pscustomobject]@{})
  }
  $cfgObj.channels | Add-Member -NotePropertyName "onebot" -NotePropertyValue $onebotObj -Force

  if ($null -eq $cfgObj.plugins) {
    $cfgObj | Add-Member -NotePropertyName "plugins" -NotePropertyValue ([pscustomobject]@{})
  }
  if ($null -eq $cfgObj.plugins.allow) {
    $cfgObj.plugins | Add-Member -NotePropertyName "allow" -NotePropertyValue @("bbot") -Force
  } else {
    $allow = @($cfgObj.plugins.allow)
    if ($allow -notcontains "bbot") { $allow += "bbot" }
    $cfgObj.plugins.allow = $allow
  }

  Save-Json -Object $cfgObj -Path $Cfg
}

function Sync-InstallMetadata {
  if (-not (Test-Path -LiteralPath $Cfg)) { return }
  if (-not (Test-Path -LiteralPath $InstalledPkgJson)) { return }

  $cfgObj = Get-Content -LiteralPath $Cfg -Raw | ConvertFrom-Json
  $pkgObj = Get-Content -LiteralPath $InstalledPkgJson -Raw | ConvertFrom-Json
  $now = (Get-Date).ToUniversalTime().ToString("o")

  if ($null -eq $cfgObj.plugins) {
    $cfgObj | Add-Member -NotePropertyName "plugins" -NotePropertyValue ([pscustomobject]@{})
  }
  if ($null -eq $cfgObj.plugins.installs) {
    $cfgObj.plugins | Add-Member -NotePropertyName "installs" -NotePropertyValue ([pscustomobject]@{}) -Force
  }

  $existing = $cfgObj.plugins.installs.'bbot'
  if ($null -eq $existing) { $existing = $cfgObj.plugins.installs.'openclaw-onebot' }
  if ($null -eq $existing) { $existing = [pscustomobject]@{} }

  $existing | Add-Member -NotePropertyName "source" -NotePropertyValue "npm" -Force
  $existing | Add-Member -NotePropertyName "spec" -NotePropertyValue $Pkg -Force
  $existing | Add-Member -NotePropertyName "installPath" -NotePropertyValue $Ext -Force
  $existing | Add-Member -NotePropertyName "version" -NotePropertyValue $pkgObj.version -Force
  $existing | Add-Member -NotePropertyName "resolvedName" -NotePropertyValue $Pkg -Force
  $existing | Add-Member -NotePropertyName "resolvedVersion" -NotePropertyValue $pkgObj.version -Force
  $existing | Add-Member -NotePropertyName "resolvedSpec" -NotePropertyValue "$Pkg@$($pkgObj.version)" -Force
  $existing | Add-Member -NotePropertyName "installedAt" -NotePropertyValue $now -Force

  $cfgObj.plugins.installs | Add-Member -NotePropertyName "bbot" -NotePropertyValue $existing -Force
  $cfgObj.plugins.installs.PSObject.Properties.Remove("openclaw-onebot")
  Save-Json -Object $cfgObj -Path $Cfg
}

function Install-Plugin {
  if ($Version -eq "latest" -or $Version -eq "dev") {
    # OpenClaw 对预发布要求显式声明 tag 或版本，这里固定使用 dev tag
    & openclaw plugins install "$Pkg@dev"
  } else {
    & openclaw plugins install "$Pkg@$Version"
  }
}

try {
  if (-not (Get-Command openclaw -ErrorAction SilentlyContinue)) {
    throw "openclaw 命令不存在，请先安装 OpenClaw。"
  }

  if (Test-Path -LiteralPath $Cfg) {
    Step "备份配置 -> $Bak"
    Copy-Item -LiteralPath $Cfg -Destination $Bak -Force
  } else {
    Step "未发现 $Cfg，跳过配置备份"
  }

  Step "停止网关"
  Get-Process -Name "openclaw-gateway" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

  Step "临时清理冲突配置（安装后自动恢复）"
  Sanitize-ConfigForInstall

  Step "清理旧插件目录（无交互） -> $Ext"
  if (Test-Path -LiteralPath $Ext) {
    Remove-Item -LiteralPath $Ext -Recurse -Force -ErrorAction SilentlyContinue
  }

  if ($Version -eq "latest" -or $Version -eq "dev") {
    Step "安装私有最新 dev 版本 $Pkg@dev"
  } else {
    Step "安装私有指定版本 $Pkg@$Version"
  }

  try {
    Install-Plugin
  } catch {
    Step "安装失败，尝试自动修复配置并重试"
    & openclaw doctor --fix | Out-Null
    Install-Plugin
  }

  Step "恢复 onebot 渠道配置"
  Restore-OnebotConfig

  Step "同步插件安装元数据"
  Sync-InstallMetadata

  Step "启动网关"
  & openclaw gateway start

  Step "当前状态"
  & openclaw status

  Step "私有更新完成（配置未改动，备份: $Bak）"
} finally {
  if (Test-Path -LiteralPath $TmpOnebot) {
    Remove-Item -LiteralPath $TmpOnebot -Force -ErrorAction SilentlyContinue
  }
}

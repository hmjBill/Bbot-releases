# Bbot 安装与更新脚本

本仓库用于提供 **Bbot 的安装、更新与运维脚本**，面向最终用户。

- 核心实现由私有仓库维护（闭源开发）
- 本仓库公开内容仅包含脚本与使用文档
- 你可以通过这里完成安装、升级、回滚与常见问题排查

## 适用环境

- OpenClaw 已安装并可用（`openclaw` 命令存在）
- 已配置 OneBot 端（NapCat / Lagrange.Core / go-cqhttp 等）
- 建议 Node.js >= 22（由插件侧要求）

## 插件包名

统一包名：`@hmjbill/bbot`

## 快速安装

### 方式 1：OpenClaw 直接安装（推荐）

```bash
openclaw plugins install @hmjbill/bbot
openclaw onebot setup
```

### 方式 2：使用更新脚本（首次安装同样可用）

macOS / Linux：

```bash
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot_Script/main/scripts/update-plugin.sh | bash
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/hmjBill/Bbot_Script/main/scripts/update-plugin.ps1 | iex
```

## 更新插件

更新脚本默认安装 `latest`，并自动执行：

1. 备份 `~/.openclaw/openclaw.json`
2. 停止网关
3. 从 `manifest.json` 解析目标版本
4. 下载插件包并校验 `SHA256`
5. 清理旧插件目录并安装新版本
6. 恢复 OneBot 渠道配置
7. 启动网关并显示状态

### 更新到最新版本

macOS / Linux：

```bash
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot_Script/main/scripts/update-plugin.sh | bash
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/hmjBill/Bbot_Script/main/scripts/update-plugin.ps1 | iex
```

### 更新到指定版本

macOS / Linux（示例 `1.1.7`）：

```bash
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot_Script/main/scripts/update-plugin.sh | bash -s -- 1.1.7
```

Windows PowerShell（示例 `1.1.7`）：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/hmjBill/Bbot_Script/main/scripts/update-plugin.ps1))) -Version 1.1.7
```

## 卸载

```bash
openclaw gateway stop
openclaw onebot cleanup-config
openclaw plugins uninstall @hmjbill/bbot
openclaw gateway start
```

如果你曾经使用“本地路径安装”，请额外手动移除对应路径安装项。

## 最小配置示例

`~/.openclaw/openclaw.json` 示例（请按实际网络和 token 修改）：

```json
{
  "channels": {
    "onebot": {
      "type": "forward-websocket",
      "host": "127.0.0.1",
      "port": 3001,
      "accessToken": "your-token",
      "enabled": true,
      "requireMention": true
    }
  },
  "plugins": {
    "allow": ["bbot"]
  }
}
```

## 常见问题

### 1) `openclaw` 命令不存在

请先安装或修复 OpenClaw，使 `openclaw` 可在终端直接运行。

### 2) 更新后插件未生效

按顺序检查：

```bash
openclaw status
openclaw plugins list
```

必要时重启网关：

```bash
openclaw gateway stop
openclaw gateway start
```

### 3) OneBot 无法连接

检查 OneBot 服务地址、端口和 `accessToken` 是否一致，确认网络可达。

### 4) 需要回滚旧版本

直接安装指定版本即可：

```bash
openclaw plugins install @hmjbill/bbot@<版本号>
```

或用上面的“指定版本更新脚本”。

## 版本与发布建议

建议仅将以下内容放在此公开仓库：

- 安装/更新脚本
- 用户文档（本 README）
- 版本清单（`manifest.json`）
- 发布说明（Release Notes）

这样既能保证用户可安装更新，也能保持核心实现闭源。

## 维护者发布步骤（manifest）

每次发布新版本时，请同步更新仓库根目录 `manifest.json`：

1. 填写 `latest` 为新版本号
2. 在 `versions.<version>.tarballUrl` 写入 npm tarball 地址
3. 在 `versions.<version>.sha256` 写入 tarball 的 SHA256
4. 提交并推送脚本仓库

只有当 `manifest.json` 中存在该版本且哈希匹配，更新脚本才会安装。

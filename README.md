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
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-plugin.sh | bash
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-plugin.ps1 | iex
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
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-plugin.sh | bash
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-plugin.ps1 | iex
```

### 更新到指定版本

macOS / Linux（示例 `1.1.7`）：

```bash
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-plugin.sh | bash -s -- 1.1.7
```

Windows PowerShell（示例 `1.1.7`）：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-plugin.ps1))) -Version 1.1.7
```

## 私有测试版更新（内部）

仅供内部调试使用，需要你对私有 npm 包有读取权限（已登录且 token 有效）。

- 私有包无权限用户会安装失败（预期行为）
- 本节命令不面向公开用户
- 脚本参数 `latest` 在私有通道中等价于 `dev` dist-tag（不会走公开 `latest`）
- 私有脚本走 npm 直接安装链路，不读取本仓库 `manifest.json` 也不做其 SHA256 校验

### 私有更新前自检（建议）

```bash
npm whoami
npm view @hmjbill/bbot-private dist-tags --json
```

### 更新到私有测试版（dev tag）

macOS / Linux：

```bash
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-private-plugin.sh | bash
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-private-plugin.ps1 | iex
```

### 更新到指定私有测试版

macOS / Linux（示例 `1.4.0-dev.2`）：

```bash
curl -fsSL https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-private-plugin.sh | bash -s -- 1.4.0-dev.2
```

Windows PowerShell（示例 `1.4.0-dev.2`）：

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/hmjBill/Bbot-releases/main/scripts/update-private-plugin.ps1))) -Version 1.4.0-dev.2
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

## 使用配置指南

完整参数手册见：[docs/config-reference.md](docs/config-reference.md)

### 快速跑通（建议顺序）

1. 安装插件：`openclaw plugins install @hmjbill/bbot`
2. 执行初始化：`openclaw onebot setup`
3. 重启网关：`openclaw gateway restart`
4. 在 QQ 私聊发送消息，或在群聊中 `@` 机器人测试

### 常用配置项（推荐先调这些）

| 配置项 | 作用 | 建议值 |
|---|---|---|
| `channels.onebot.requireMention` | 群聊是否必须 @ 才触发 | 群聊噪声大时 `true` |
| `channels.onebot.triggerKeywords` | 群聊关键字触发列表 | 如 `["AI","助手","帮我问"]` |
| `channels.onebot.triggerMode` | 关键字匹配方式 | `contains` |
| `channels.onebot.longMessageMode` | 长消息发送模式 | `normal` / `og_image` / `forward` |
| `channels.onebot.longMessageThreshold` | 超过该长度走长消息策略 | `300` |
| `channels.onebot.thinkingEmojiEnabled` | 是否显示“思考中”表情 | 不喜欢可设 `false` |

### 关键字触发示例（无需 @）

```json
{
  "channels": {
    "onebot": {
      "requireMention": false,
      "triggerKeywords": ["AI", "助手", "帮我问"],
      "triggerMode": "contains"
    }
  }
}
```

### 长消息模式示例

`normal`（推荐默认）：

```json
{
  "channels": {
    "onebot": {
      "longMessageMode": "normal",
      "normalModeFlushIntervalMs": 1200,
      "normalModeFlushChars": 160
    }
  }
}
```

`og_image`（超长内容更易读）：

```json
{
  "channels": {
    "onebot": {
      "longMessageMode": "og_image",
      "longMessageThreshold": 300,
      "ogImageRenderTheme": "dust"
    }
  }
}
```

### 多账号路由（按 `accountId`）

当你接入多个 OneBot 账号时，可以在 `bindings` 中按 `accountId` 路由到不同 agent：

```json
{
  "bindings": [
    {
      "agentId": "xiaob",
      "match": { "channel": "onebot", "accountId": "xiaob" }
    },
    {
      "agentId": "xiaoxiaob",
      "match": { "channel": "onebot", "accountId": "xiaoxiaob" }
    }
  ]
}
```

### 群聊拟人化定时回复（可选高级）

如需“定时看群聊并拟人化短回复”，可开启 `humanizeDigest`：

```json
{
  "channels": {
    "onebot": {
      "humanizeDigest": {
        "enabled": true,
        "replyMode": "llm",
        "intervalSecMin": 180,
        "intervalSecMax": 420,
        "windowMinutes": 6,
        "minNewMessages": 6,
        "targetGroups": [1046693162]
      }
    }
  }
}
```

建议先小流量群测试，再逐步放量。

### 白名单与黑名单（群控常用）

```json
{
  "channels": {
    "onebot": {
      "whitelistUserIds": [1193466151],
      "blacklistUserIds": [123456789]
    }
  }
}
```

说明：白名单优先级高于黑名单；账号级配置优先于全局配置。

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

说明：手动 `openclaw plugins install @hmjbill/bbot@<版本号>` 属于直接 npm 安装路径，不经过本仓库 `manifest.json` 的版本指针与哈希校验链路。

## 版本与发布规范（SOP，防漂移）

本仓库是 Bbot 的公开分发通道，负责安装脚本、版本清单和用户文档。  
为避免多仓库漂移，发布动作遵循“内部发布完成 -> 公开仓库同步”的固定顺序。

### 1) 仓库边界

- 本仓库仅保留公开内容：脚本、`manifest.json`、用户文档、发布说明
- 内部实现细节、敏感路径、内网信息、密钥禁止进入本仓库

### 2) 发布前置（公开仓库视角）

更新本仓库前，先确认：

1. 目标版本已完成内部发布流程
2. npm 公开包 `@hmjbill/bbot@x.y.z` 可查询可下载

### 3) 双 npm 通道约束

- 正式公开通道：`@hmjbill/bbot`（稳定版本，tag=`latest`）
- 私有调试通道：`@hmjbill/bbot-private`（预发布版本，tag=`dev`/`rc`）
- 私有通道版本必须带后缀：`-dev.N` / `-rc.N` / `-exp.N`

### 4) 发布后同步（本仓库强制）

每次新版本发布后，本仓库至少同步：

1. `README.md`
2. `docs/config-reference.md`
3. `manifest.json`

同步要求：

1. `manifest.json.latest` 指向目标版本
2. 新增 `versions.<version>` 的 `tarballUrl`、`sha256`、`publishedAt`（UTC ISO 8601）
3. 历史版本条目仅新增，不覆盖
4. 脚本下载链接必须指向 `Bbot-releases`

### 5) 发布后验收（强制）

每次发布后执行并记录：

```bash
npm view @hmjbill/bbot version
npm view @hmjbill/bbot readme
npm view <old-pkg>@<version> deprecated
```

验收目标：

1. npm 线上版本与目标版本一致
2. npm README 为公开文档（不含内部实现信息）
3. 旧包迁移提示（deprecated）生效

### 6) 异常与回滚

- 新版本异常：将 `manifest.json.latest` 回指稳定版本并立即推送
- `EOTP` 中断：改为手动命令补发并记录
- README/元数据错误：立刻发新 patch 版本修正
- 旧包无法下线：至少保留 `deprecated` 迁移提示

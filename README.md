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

## 版本与发布规范（SOP）

本仓库作为公开发布通道，建议只包含：

- 安装/更新脚本
- 用户文档（本 README）
- 版本清单（`manifest.json`）
- 发布说明（Release Notes）

### 1) 版本策略

- 使用 SemVer：`MAJOR.MINOR.PATCH`
- `feat` 且向后兼容：升级 `MINOR`
- `fix`：升级 `PATCH`
- 存在破坏性变更：升级 `MAJOR`，并在发布说明标注 `BREAKING`

### 2) 发布前检查

发布新版本前，至少确认：

1. npm 已发布目标版本（`@hmjbill/bbot@x.y.z`）
2. tarball URL 可下载
3. tarball 的 `SHA256` 已正确计算
4. Linux/macOS 与 PowerShell 更新命令都可执行
5. `openclaw plugins install @hmjbill/bbot@x.y.z` 可安装成功

### 3) manifest 更新规则

每次发布新版本时，更新仓库根目录 `manifest.json`：

1. 填写 `latest` 为目标版本号
2. 新增 `versions.<version>` 节点（建议只新增，不修改历史条目）
3. `tarballUrl` 指向 npm 对应 tarball
4. `sha256` 写入 tarball 的 SHA256（小写）
5. `publishedAt` 使用 UTC 时间（ISO 8601）

更新脚本仅在“版本存在且哈希匹配”时安装。

### 4) 回滚流程

发现新版本异常时：

1. 将 `manifest.json` 的 `latest` 指回稳定版本
2. 提交并推送本仓库
3. 在 Release Notes 标注“已回滚”与建议版本

如需强制指定版本，用户可执行：

```bash
openclaw plugins install @hmjbill/bbot@<稳定版本>
```

### 5) 安全要求

- 不安装未在 `manifest.json` 声明的版本
- 不安装哈希不匹配的 tarball
- 出现哈希不一致时，暂停发布并重新核验构建产物
- 禁止在脚本中写死密钥或敏感配置

### 6) 发布说明模板

每次发布建议包含以下小节：

- `新增`：用户可感知的新能力
- `修复`：已解决的问题
- `兼容性`：是否影响旧配置
- `升级建议`：是否建议立即升级或观察

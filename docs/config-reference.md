# Bbot 配置参数参考

本文档面向需要精细调参的用户，配置根路径默认为：`channels.onebot`。

> 说明：默认值以当前插件 schema 为准。若你的 OpenClaw 版本行为不同，请以实际运行结果为准。

## 1. 基础连接与触发

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `type` | `forward-websocket`/`backward-websocket` | - | OneBot 连接类型 |
| `host` | string | - | OneBot 服务地址（不要带 `ws://`） |
| `port` | number | - | OneBot 服务端口 |
| `accessToken` | string | - | 访问令牌 |
| `path` | string | - | WS 路径（常用 `/onebot/v11/ws`） |
| `defaultAccount` | string | - | 多账号模式默认账号 ID（建议设置） |
| `requireMention` | boolean | `true` | 群聊是否必须 @ 才触发 |
| `triggerKeywords` | string[] | `[]` | 关键词触发列表 |
| `triggerMode` | `prefix`/`contains` | `prefix` | 关键词匹配方式 |
| `replyWhenWhitelistDenied` | boolean | `true` | 白名单拒绝时是否回复提示 |

`enabled` 一般由 OpenClaw 渠道层统一管理，不属于 Bbot 专有参数。

## 2. 文本与长消息行为

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `renderMarkdownToPlain` | boolean | `true` | 将 Markdown 渲染为纯文本后发送 |
| `collapseDoubleNewlines` | boolean | `true` | 将连续空行压缩 |
| `normalModeFlushIntervalMs` | number | `1200` | `normal` 模式聚合等待窗口 |
| `normalModeFlushChars` | number | `160` | `normal` 模式达到该长度提前发送 |
| `longMessageMode` | `normal`/`og_image`/`forward` | `normal` | 长消息处理模式 |
| `longMessageThreshold` | number | `300` | 超过该字符数触发长消息策略 |
| `ogImageRenderTheme` | `default`/`dust`/`custom` | `default` | `og_image` 渲染主题 |
| `ogImageRenderThemePath` | string | - | `custom` 主题 CSS 绝对路径 |

## 3. 多账号覆盖（`accounts`）

路径：`channels.onebot.accounts.<accountId>.*`

账号级可覆盖常用模块：

- 连接参数：`type`、`host`、`port`、`accessToken`、`path`、`enabled`、`agentId`
- 访问控制：`whitelistUserIds`、`blacklistUserIds`、`managementPermissions`
- 行为模块：`humanizeDigest`、`mentionImageAnalyze`、`stickerPack`、`emojiLike`

## 4. 白名单、黑名单与 ACL

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `whitelistUserIds` | number[] | `[]` | 白名单用户 ID |
| `blacklistUserIds` | number[] | `[]` | 黑名单用户 ID |
| `managementPermissions.defaultPolicy` | `allow`/`deny` | `deny` | 管理动作默认策略 |
| `managementPermissions.allowAgents` | string[] | `[]` | 全局允许的 agent |
| `managementPermissions.denyAgents` | string[] | `[]` | 全局拒绝的 agent |
| `managementPermissions.actions.<action>` | object | - | 按动作粒度覆写 allow/deny |

优先级：账号级 > 全局；白名单 > 黑名单。

## 5. 群聊拟人化汇总（`humanizeDigest`）

路径：`channels.onebot.humanizeDigest`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 是否启用 |
| `intervalSecMin` | number | `180` | 最小轮询间隔（秒） |
| `intervalSecMax` | number | `420` | 最大轮询间隔（秒） |
| `windowMinutes` | number | `6` | 汇总窗口（分钟） |
| `minNewMessages` | number | `6` | 低于该新消息数不回复 |
| `cooldownSec` | number | `120` | 同群冷却时间（秒） |
| `targetGroups` | number[] | `[]` | 生效群号列表 |
| `maxMessages` | number | `120` | 每轮最大取样消息数 |
| `maxSummaryMessages` | number | `12` | 汇总阶段最大消息数 |
| `maxReplyChars` | number | `900` | 自动回复最大字符数 |
| `replyTemplate` | string | - | `summary` 模板 |
| `replyMode` | `summary`/`selective`/`llm` | `selective` | 回复策略 |
| `replyProbability` | number(0-1) | `0.35` | `selective` 基础概率 |
| `questionBoost` | number(0-1) | `0.30` | 问句增益 |
| `mentionBoost` | number(0-1) | `0.25` | 点名增益 |
| `atUserProbability` | number(0-1) | `0.25` | @ 焦点用户概率 |
| `quoteReplyProbability` | number(0-1) | `0.20` | 引用回复概率（与 @ 互斥） |
| `maxFocusChars` | number | `50` | 焦点消息截断长度 |
| `botNicknames` | string[] | `[]` | 机器人昵称词 |
| `selectiveReplyTemplate` | string | - | `selective` 模板 |
| `llmMaxReplyChars` | number | `140` | `llm` 回复长度上限 |
| `suppressAfterInteractionSec` | number | `180` | 近期互动后抑制秒数 |
| `imageChimeEnabled` | boolean | `false` | 看图接梗开关 |
| `imageChimeProbability` | number(0-1) | `0.25` | 看图接梗触发概率 |
| `imageChimeMaxImages` | number | `3` | 单次参考图片数 |
| `imageChimeMaxContextMessages` | number | `12` | 图梗上下文消息上限 |
| `imageChimePrompt` | string | - | 图梗提示词模板 |

## 6. 被 @ 后图片分析（`mentionImageAnalyze`）

路径：`channels.onebot.mentionImageAnalyze`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 开关 |
| `windowMessages` | number | `3` | 被 @ 后生效消息窗口 |
| `maxImageUrlsPerMessage` | number | `3` | 单条消息最多附带图片数 |

## 7. 表情包发送（`stickerPack`）

路径：`channels.onebot.stickerPack`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 开关 |
| `directories` | string[] | `[]` | 表情目录（可递归） |
| `includeHumanizeDigest` | boolean | `true` | 是否参与 digest 场景 |
| `replyProbability` | number(0-1) | `0.12` | 普通回复场景概率 |
| `digestReplyProbability` | number(0-1) | `0.08` | digest 场景概率 |
| `maxCandidates` | number | `5` | 语义候选上限 |
| `maxFileMB` | number | `8` | 文件大小上限（MB） |

## 8. 消息表情回应（`emojiLike`）

路径：`channels.onebot.emojiLike`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 开关 |
| `includeHumanizeDigest` | boolean | `true` | 是否参与 digest 场景 |
| `replyProbability` | number(0-1) | `0.16` | 普通回复场景概率 |
| `digestReplyProbability` | number(0-1) | `0.10` | digest 场景概率 |
| `emojiIds` | number[] | `[]` | 可选 emoji_id 列表 |

约束：与 `stickerPack` 互斥，同轮优先 `stickerPack`。

## 9. 群成员加入欢迎（`groupIncrease`）

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 是否启用欢迎流程 |
| `message` | string | - | 欢迎语模板 |
| `command` | string | - | 已禁用（仅保留兼容字段） |
| `cwd` | string | - | 已禁用（仅保留兼容字段） |

## 10. 思考态表情

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `thinkingEmojiEnabled` | boolean | `true` | 是否启用 |
| `thinkingEmojiId` | number | `60` | 表情 ID，`<=0` 视为关闭 |

## 11. 回调与定时任务

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `onReplySessionEnd` | string | - | 回复会话结束回调脚本路径 |
| `cronJobs` | object[] | - | 内置定时任务列表 |

`cronJobs[]` 常用字段：

- `name`：任务名（必填）
- `cron`：cron 表达式（必填）
- `timezone`：时区（默认 `Asia/Shanghai`）
- `script`：脚本路径（必填）
- `groupIds`：推送群号列表（必填）

## 12. 综合示例

```json
{
  "channels": {
    "onebot": {
      "type": "forward-websocket",
      "host": "127.0.0.1",
      "port": 3001,
      "accessToken": "your-token",
      "requireMention": false,
      "triggerKeywords": ["AI", "助手"],
      "triggerMode": "contains",
      "renderMarkdownToPlain": true,
      "collapseDoubleNewlines": true,
      "longMessageMode": "og_image",
      "longMessageThreshold": 300,
      "ogImageRenderTheme": "dust",
      "humanizeDigest": {
        "enabled": true,
        "replyMode": "llm",
        "targetGroups": [1046693162]
      },
      "stickerPack": {
        "enabled": true,
        "directories": ["/data/stickers/common"]
      }
    }
  }
}
```

## 13. 调参建议

- 先只开连接与触发，再逐步开启 `humanizeDigest`、`stickerPack`
- 生产群先低概率观察，再放量
- 涉及管理动作时优先收紧 `managementPermissions`
- 每次只改一组参数，便于回归定位

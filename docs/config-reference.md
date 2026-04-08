# Bbot 配置参数参考

本文档面向需要精细调参的用户，配置根路径默认为：`channels.onebot`。

> 说明：表格中的“默认”用于快速参考；不同版本可能存在细微差异。  
> 若出现冲突，请以当前插件实际配置 schema 与运行结果为准。

## 1. 基础连接与触发

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `type` | string | `forward-websocket` | OneBot 连接模式，常用 `forward-websocket` |
| `host` | string | - | OneBot 服务地址（不要带 `ws://`） |
| `port` | number | - | OneBot 服务端口 |
| `accessToken` | string | - | OneBot 访问令牌 |
| `enabled` | boolean | `true` | 渠道开关 |
| `requireMention` | boolean | `true` | 群聊是否必须 @ 才触发 |
| `triggerKeywords` | string[] | `[]` | 关键字触发列表（命中即可触发） |
| `triggerMode` | `prefix`/`contains` | `contains` | 关键字匹配方式 |

## 2. 长消息处理

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `longMessageMode` | `normal`/`og_image`/`forward` | `normal` | 长消息处理模式 |
| `longMessageThreshold` | number | `300` | 超过该字符数触发长消息策略 |
| `normalModeFlushIntervalMs` | number | `1200` | `normal` 模式聚合发送时间窗口 |
| `normalModeFlushChars` | number | `160` | `normal` 模式聚合发送长度阈值 |
| `ogImageRenderTheme` | `default`/`dust`/`custom` | `default` | `og_image` 渲染主题 |
| `ogImageRenderThemePath` | string | - | `custom` 主题 CSS 绝对路径 |

## 3. 多账号覆盖

账号级配置路径：`channels.onebot.accounts.<accountId>.*`。

支持按账号覆盖的常用模块：

- `humanizeDigest`
- `mentionImageAnalyze`
- `stickerPack`
- `emojiLike`
- `whitelistUserIds`
- `blacklistUserIds`
- `managementPermissions`

## 4. 白名单与黑名单

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `whitelistUserIds` | number[] | `[]` | 仅允许触发回复的用户 ID 列表 |
| `blacklistUserIds` | number[] | `[]` | 屏蔽触发回复的用户 ID 列表 |

优先级规则：

1. 账号级高于全局
2. 白名单高于黑名单

## 5. 群聊拟人化汇总（`humanizeDigest`）

路径：`channels.onebot.humanizeDigest`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 是否启用 |
| `replyMode` | `llm`/`selective`/`summary` | `llm` | 回复策略 |
| `intervalSecMin` | number | `180` | 轮询最小间隔（秒） |
| `intervalSecMax` | number | `420` | 轮询最大间隔（秒） |
| `windowMinutes` | number | `6` | 统计窗口（分钟） |
| `minNewMessages` | number | `6` | 低于该新消息数只读不回 |
| `cooldownSec` | number | `120` | 同一群冷却（秒） |
| `targetGroups` | number[] | `[]` | 生效群号列表（必填） |
| `maxMessages` | number | `120` | 每轮最大取样消息数 |
| `maxSummaryMessages` | number | `12` | 汇总阶段最大消息数 |
| `maxReplyChars` | number | `220` | 单条最大字符数 |
| `llmMaxReplyChars` | number | `140` | `llm` 模式回复长度上限 |
| `replyProbability` | number(0-1) | `0.35` | `selective` 基础概率 |
| `questionBoost` | number(0-1) | `0.3` | 问句概率增益 |
| `mentionBoost` | number(0-1) | `0.25` | 点名概率增益 |
| `atUserProbability` | number(0-1) | `0.25` | 概率 @ 用户 |
| `quoteReplyProbability` | number(0-1) | `0.2` | 概率引用回复（与 @ 互斥） |
| `maxFocusChars` | number | `50` | 焦点消息截断长度 |
| `botNicknames` | string[] | `[]` | 机器人昵称词 |
| `selectiveReplyTemplate` | string | - | `selective` 模板 |
| `replyTemplate` | string | - | `summary` 模板 |
| `suppressAfterInteractionSec` | number | `0` | 近期互动后抑制时长 |
| `imageChimeEnabled` | boolean | `false` | 看图接梗开关 |
| `imageChimeProbability` | number(0-1) | `0.28` | 看图接梗概率 |
| `imageChimeMaxImages` | number | `3` | 单次参考图片数 |
| `imageChimeMaxContextMessages` | number | `12` | 图梗上下文消息上限 |
| `imageChimePrompt` | string | - | 图梗提示词 |

说明：`humanizeDigest` 配置支持热更新，修改后通常无需重启网关。

## 6. @ 后图片分析窗口（`mentionImageAnalyze`）

路径：`channels.onebot.mentionImageAnalyze`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 开关 |
| `windowMessages` | number | `3` | 被 @ 后额外分析的消息条数 |
| `maxImageUrlsPerMessage` | number | `3` | 单条消息附带图片 URL 上限 |

## 7. 表情包概率发送（`stickerPack`）

路径：`channels.onebot.stickerPack`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 开关 |
| `directories` | string[] | `[]` | 表情目录（递归索引） |
| `replyProbability` | number(0-1) | `0.18` | 普通回复概率 |
| `includeHumanizeDigest` | boolean | `false` | 是否用于 digest 场景 |
| `digestReplyProbability` | number(0-1) | `0.06` | digest 概率 |
| `maxCandidates` | number | `6` | 语义候选上限 |
| `maxFileMB` | number | `8` | 文件大小上限（MB） |

## 8. 消息表情回应（`emojiLike`）

路径：`channels.onebot.emojiLike`

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `enabled` | boolean | `false` | 开关 |
| `emojiIds` | number[] | `[]` | 可选 emoji_id 列表 |
| `replyProbability` | number(0-1) | `0.2` | 普通回复概率 |
| `includeHumanizeDigest` | boolean | `true` | 是否用于 digest |
| `digestReplyProbability` | number(0-1) | `0.12` | digest 概率 |

约束：

- 与 `stickerPack` 互斥（同轮只会触发其一）
- 受 ACL 权限控制（见下节）

## 9. 思考中表情

| 参数 | 类型 | 默认 | 说明 |
|---|---|---|---|
| `thinkingEmojiEnabled` | boolean | `true` | 是否启用处理中表情 |
| `thinkingEmojiId` | number | `60` | 表情 ID；`<=0` 视为关闭 |

## 10. 管理动作权限 ACL（`managementPermissions`）

支持全局与账号级配置：

- 全局：`channels.onebot.managementPermissions`
- 账号级：`channels.onebot.accounts.<accountId>.managementPermissions`

可用于限制敏感动作（例如禁言、踢人、改群名、emoji like、删消息等）按 agent 授权。

建议至少区分：

- 默认只读 agent
- 管理员 agent（允许管理动作）

## 11. 综合示例

```json
{
  "channels": {
    "onebot": {
      "type": "forward-websocket",
      "host": "127.0.0.1",
      "port": 3001,
      "accessToken": "your-token",
      "enabled": true,
      "requireMention": false,
      "triggerKeywords": ["AI", "助手"],
      "triggerMode": "contains",
      "longMessageMode": "og_image",
      "longMessageThreshold": 300,
      "ogImageRenderTheme": "dust",
      "humanizeDigest": {
        "enabled": true,
        "replyMode": "llm",
        "intervalSecMin": 180,
        "intervalSecMax": 420,
        "windowMinutes": 6,
        "minNewMessages": 6,
        "targetGroups": [1046693162]
      },
      "mentionImageAnalyze": {
        "enabled": true,
        "windowMessages": 3,
        "maxImageUrlsPerMessage": 3
      },
      "stickerPack": {
        "enabled": true,
        "directories": ["/data/stickers/common"],
        "replyProbability": 0.18
      },
      "emojiLike": {
        "enabled": true,
        "emojiIds": [1, 60, 66],
        "replyProbability": 0.2
      },
      "accounts": {
        "xiaob": {
          "whitelistUserIds": [1193466151],
          "humanizeDigest": {
            "enabled": true,
            "targetGroups": [123456789]
          }
        }
      }
    }
  }
}
```

## 12. 调参建议

- 先只开基础能力（连接、触发、长消息），确认稳定后再开启 `humanizeDigest`
- 生产群先低概率（`replyProbability`、`digestReplyProbability`）观察
- 涉及管理动作时，优先收紧 `managementPermissions`
- 每次只改一组参数，便于定位行为变化

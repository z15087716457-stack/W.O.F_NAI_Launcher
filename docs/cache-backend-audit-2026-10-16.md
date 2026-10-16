# F19 · 词库与缓存后端核验（修前调查）

> 后续用户已授权修复，本地累计完成，尚未安装；当前结果见 [F19／F22 修复](cache-storage-backend-fix-2026-10-16.md)。下文保留修前核验快照。

用户要求检查“缓存”及下方“缓存统计”的后端。核验有效源码 `58fbbc985` 和本机 r9 的实际数据库；本次没有修改生产代码、清理用户缓存或安装程序。

## 结论

| 入口 | 当前实际范围 | 结果 |
|---|---|---|
| Danbooru 缓存 | `AutocompleteCacheDatabase.remote_queries`，旧补全搜索／关联标签请求的持久缓存 | 读写、字节与删除正常；没有覆盖当前在线画廊分页／详情状态缓存、Wiki 示例元数据／图片缓存。旧补全来源的五分钟内存缓存也未清除 |
| AI 翻译缓存 | 同一数据库的 `ai_translations`，旧 `LlmTranslationResolver` 的标签翻译 | 读写、字节与删除正常；未统计、清除当前 `VisibleTagTranslationCache` 中的 Wiki／标签名称、释义及正文翻译，也不是提示词全文翻译的总缓存 |
| L1／L2 | `ImageMetadataService` 的内存／Hive 图片元数据缓存 | 条目与命中率来自真实服务；重置只清命中／未命中计数，保留缓存内容 |
| L3 SQLite | 管理器可读图库图片及元数据数量，但没有独立命中率 | 新适配层直接返回 `l3: null`，界面显示“—”，没有展示已有数量 |

上方两个入口不是全局缓存管理器：当前仍连接旧补全库，界面说明的范围大于实际后端。下方 L1／L2 是另一套缓存，不能用它们的条目数推算上面两行。

本机在 **2026-10-16 10:25:31 +08:00** 以 SQLite `mode=ro`／`query_only=ON` 读取汇总：旧库 `remote_queries=0`、`ai_translations=0`；当前翻译库 `tag_translations=1018`，其中 `169` 条有百科正文译文。没有输出译文、原文或账号内容。“0 条／0 B”对旧表本身成立，字节统计只计 UTF-8 有效载荷，不代表整个 SQLite 文件大小。

## 验证与接线证据

- `settings_inventory.dart` 的 `settingsDictionaryDataProvider` 只读旧库；`settings_storage.dart` 的 `clearCache` 只删对应旧表。`settings_create.dart` 在条数为零时禁用清除。
- `autocomplete_providers.dart` 的旧聚合服务在现行界面无消费者；现行自动标签／Wiki 翻译使用 `auto_tag_translation_controller.dart` 与 `visible_tag_translation_cache.dart`。在线画廊使用 `OnlineGalleryState` 的分来源模式缓存，Wiki 示例另有专用仓库／图片缓存。
- 隔离 SQLite／Hive 与合成 Dio 响应验证 4 项：旧表两种清除互不误删、UTF-8 字节正确；现用翻译不在旧库统计且不受其清除；删旧 Danbooru 表后内存仍能复用；重置 L1／L2 命中率不删元数据。与既有来源／翻译缓存回归合计 **15 项通过**；其中两项刻意复现当前缺口，不代表问题已经修复。
- 自动刷新开关有持久化，设置页每 10 秒请求一次；管理器另有 30 秒统计缓存，所以数值可能到下一次过期才更新。重置会使统计缓存立即失效。

本机证据 `.dart_tool/cache-backend-audit-20261016/` 保存只含汇总的只读结果、隔离核验脚本／日志和合成资料。未连接真实网络、调用模型、生图、清理用户资料或操作 Studio；桌面仍为 r9，F16–F18 本地积攒保持。

后续需按现行服务重新明确统计及清除范围，并同步取消／失效内存和进行中的旧请求。AI 翻译还被术语表及 RAG 复用，修复时不得把“核对统计”变成自动删除已有译文或资料索引。

# F29 · 标签与 Wiki 补充来源调查

2026-10-16（Asia/Taipei）核验。用户要求调查可下载的可靠来源，以便提供直接点击补充本地数据的入口。本次完成来源调查、文件格式与现有架构核对，下载／导入入口尚未实现，不能算作已补充用户数据。

## 现有本地数据

只读检查有效源码随包 SQLite：基础标签 221,787 条、Wiki 原文 141,802 条、共现关系 3,236,959 条。对应 `tool/tag_catalog/source_lock.json`、`tool/database/build_tag_wiki.py`、`tool/database/cooccurrence_source_lock.json`。基础库为 Danbooru/e621 合并来源，Wiki 从旧 `github_chening233.csv` 建库，共现锁定 2025-05-09 的文件版本；译文使用现行 sidecar／模型接口，旧 ffdkj 索引已退役。

## 核验结果

| 用途 | 来源 | 结论 |
|---|---|---|
| 批量基础标签 | [DraconicDragon/dbr-e621-lists-archive](https://github.com/DraconicDragon/dbr-e621-lists-archive) | 现有基础库的上游链路已使用此来源。作者说明每月运行采集、季度提交仓库；公开仓库实际存在 2026-10-01 Danbooru CSV，适合作为可追溯的补充源。 |
| 批量 Wiki 原文 | [patvessel/danbooru-wiki-2606](https://huggingface.co/datasets/patvessel/danbooru-wiki-2606) | 发布者标注 2026-06-01、266,777 条原始 Wiki 记录。第三方快照，保留原文／别名／时间／删除状态；可作为待全量校验的候选，不能称为官方实时数据。 |
| 单条或增量补齐 | [Danbooru 官方 API 说明](https://safebooru.donmai.us/wiki_pages/help:api) | 官方原文优先。适合缺失条目及刷新当前条目；需要应用身份、限速、缓存和失败重试，不把几百万次请求作为启动默认行为。 |
| 共现数据 | [newtextdoc1111/danbooru-tag-csv](https://huggingface.co/datasets/newtextdoc1111/danbooru-tag-csv) | 当前锁定源仍可定位。标签和共现 CSV 结构不同，数据集预览报错不等于共现文件损坏；继续按具体文件和哈希处理，不将其标签 CSV 替换当前基础库。未核验到更合适的新共现快照。 |

### 标签文件实读

实际下载 [固定提交的 2026-10-01 CSV](https://raw.githubusercontent.com/DraconicDragon/dbr-e621-lists-archive/0d3b4e4d7e9890329a884afee4fada2b76f794eb/tag-lists/danbooru/danbooru_2026-10-01_pt20-ia-dd.csv)，HTTP 200，5,602,650 字节；全部 220,510 行均为四列，规范名去重后仍为 220,510 个。SHA-256：`45afb2554525464ee49112512f6367ee004bd351afcef5f2435e99d6286884e3`。

与当前随包基础库按规范标签名比较：交集 136,482 个，候选中未收录名字 84,028 个，合并去重后为 305,815 个。现库有 85,305 个名字不在该候选中，来源范围和过滤阈值不同，不能把这些当作删除列表。作者也明确建议各站点分开载入，避免依赖合并 CSV 的类别偏移。因此建议更新时按来源补充、保留 e621 和其他既有标签，不直接整库覆盖。

### Wiki 文件抽样

固定修订 `f10616722a3d4c88a4cb16747e24b08568df4afd`；[JSONL 下载页](https://huggingface.co/datasets/patvessel/danbooru-wiki-2606/blob/main/danbooru-wiki-2606.jsonl) 对应文件 137,932,215 字节，SHA-256 `0c53a96a8decce725a3fed3a7b835b5344a01012dd73b7eb3197f4fea923ed9e`。同源 CSV 为 105,781,308 字节，Parquet 为 56,271,713 字节，大小不是安装后 SQLite 体积。

HTTP Range 返回 206，实际仅读取前 65,536 字节，解析 74 条完整记录，字段含 `title/body/other_names/created_at/updated_at/is_deleted`；65 条有正文。未下载全部 Wiki，也未核验全部文章内容，发布者总条数不等于有效文章数，不能据此承诺补入 12 万余篇。真正导入须过滤空正文／删除标记、规范名去重并保留原文格式与更新时间。中文全文翻译另走现有译文链，不能把原文下载包当成中文翻译库。来源页列有许可及原作者署名说明，后续分发数据包须保留来源并按实际许可处理。

其他候选：[kierarkia/danbooru-wiki-2026](https://huggingface.co/datasets/kierarkia/danbooru-wiki-2026) 为 2026-04-28 快照，含人工整理过的类别，可作备选；[isek-ai/danbooru-wiki-2024](https://huggingface.co/datasets/isek-ai/danbooru-wiki-2024) 只有较旧且按频次筛选的范围，不优先用于当前补齐。没有核验到当前可用的 Danbooru 官方全量下载站，不能把旧 `cache/tags.json` 或假定的 `db_export` 地址写进应用。

## 建议入口与接线边界（待施工）

- 词库与缓存中，基础词库旁放“检查更新／补充”；单列“Wiki 百科”，展示当前有效文章数和数据日期，提供“下载补充”。
- Wiki 文章为空时提供“从 Danbooru 获取”，已有文章可手动刷新。批量数据包与按需网络请求分开呈现，显示大小、进度、取消及错误。
- 数据包版本独立于应用版本，固定修订／哈希校验、临时建库和完整性验证通过后再切换；失败保持现有可用数据，更新后刷新受影响的查询／缓存。按原设置维护已启用的 RAG 来源，不自动打开关闭中的来源。
- 当前 `AssetDatabaseManager._install` 按随包 manifest 比较哈希，重启时会把不同版本的活动库换回随包版本；`TagCatalogRepository` 又持有数据库连接。必须先完善独立数据版本和连接切换机制，再接下载按钮，否则会出现“下载成功、重启还原”。本次未改这条生产链。

核验文件位于 `.dart_tool/dictionary-sources-f29-20261016/`：`verified-source-metadata.json` 记录固定 URL、大小、哈希、HTTP 状态、抽样字段及标签差集，5.6 MB 标签文件仅作研究夹具。未接入下载按钮、安装数据、调用模型／生图、操作运行中的 Studio 或更新桌面版；没有代码变更，不运行 Flutter 测试或构建。已有 `DEVELOPMENT.md` 与 `.runs/` 保留。

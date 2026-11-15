# Tag／Wiki 来源复核

> 后续已完成 [本机数据更新及来源登记](dictionary-data-update-2026-11-14.md)。下文保留实施前的比较基线，不代表现用数据仍停留六月／十月。

调查日期：2026-11-14（Asia/Taipei）。本次只读调查上游、下载研究样本并与当前安装数据比较，没有更新应用词库、源码、RAG、桌面安装或 Git 发布。

## 结论

- 官方 Danbooru API 是原始 Tag／Wiki 的首选来源，本次两类公开接口均实测 HTTP 200，返回含台北时间 11 月 14 日的更新记录。适合单条刷新或制作增量快照，不能把少量接口成功当作全库采集已经验证。
- 批量 Tag 找到同一维护者的 **2026-11-03 月度构建包**，比现用 10 月 1 日数据更新。已完整下载、校验并解析；应用检查器只扫描季度提交目录，因此漏掉这个月度版本。
- Wiki 找到 **2026-09-02 快照**，确认内容确有更新。但来源／过滤过程说明不足，且缺少当前库里的部分帮助页，不能直接整库替换；适合作为补充候选。
- “11 月构建”的第三方聚合库有沿用 **2025 年 9 月 Danbooru 原料**的情况。文件上传日期、数据库打包日期与实际内容日期必须分开判断。

建议保留现有离线库和合并流程：近期采用同源月度 Tag，官方 API 承担原文刷新；Wiki 候选核清采集范围后再合并。稳定下载包仍须固定版本与摘要，不把会过期、要求登录的 Actions 附件地址直接交给桌面用户。

## 当前基线与检查器范围

安装目录 `user-data/dictionary_updates` 最新有效记录及只读 SQLite 核验一致：

| 数据 | 当前来源日期 | 合并后数量 | 来源 SHA-256 |
|---|---|---:|---|
| Tag | 2026-10-01 | 305,815 | `45afb2554525464ee49112512f6367ee004bd351afcef5f2435e99d6286884e3` |
| Wiki | 2026-06-01 | 288,187 | `0c53a96a8decce725a3fed3a7b835b5344a01012dd73b7eb3197f4fea923ed9e` |

这些是补充合并后的库规模，不是单个上游文件的有效条数。随包基础库、共现和中文语义库的构建日期不代表以上补充源的日期。

`lib/core/database/dictionary_update_checker.dart` 当前范围：

- Tag：查询 `DraconicDragon/dbr-e621-lists-archive/tag-lists/danbooru`，识别 `danbooru_YYYY-MM-DD_pt20-ia-dd.csv`；没有查询 Actions 月度附件。
- Wiki：固定查询 `patvessel/danbooru-wiki-2606` 的修订与指定 JSONL 文件；同名库没更新，不代表其他发布者没有新快照。

因此此前“已是最新”的表述只适用于检查器覆盖的地址，不能外推为全部可用来源。

## 已有 DanbooruSearchOnline 中文资料

用户提醒后补充现场核验：本地仍保留从 DanbooruSearchOnline 导入、清洗和打包的中文资料，不能只列主标签库及英文 Wiki。

- 固定上游 `SuzumiyaAkizuki/DanbooruSearchOnline@4e99f95adfcd53a8cabd1eb097294b1c7af069a6`，原始 `origin_database/tags_enhanced.csv` 保留在 `tool/tag_semantics/sources/`；版本、GBK 编码、摘要及清洗数量见 `tool/tag_semantics/source_lock.json`。
- 本次只读查询当前桌面包内 `tag_semantics.db`，实际为 **53,860 个标签资料条目、53,859 份非空中文简释义**；文件 SHA-256 为 `1814ae269a6fbda6add512768f3fc391cd00661fce30e36db17c484e27421209`，与构建记录一致。安装数据目录中也存在同名资源。
- 内容是中文核心词、同义词和简释义。现行 `tag_expansion_providers.dart` 的中文名称搜索及 `auto_tag_translation_controller.dart` 已接入该资料；个人／后续语义补充另存 `user-data/tag_semantics/supplements.db`，本次不修改或重建它。
- 与上表 305,815 条的补充合并 Tag 库按标签名精确比较，**53,629 个重合、231 个未精确命中**。未命中不等于错误或需要删除，还可能涉及来源范围和名称对应；不能把 53,860 全部作为额外新标签叠加计数。
- 这是已有中文语义资料层，不替代标签名／别名／热度主库，也不等于完整 Wiki 原文。十月导入日期不代表原文采集日期；上游后续更新核验如下。

用户明确要求：**保留这份中文资料作为底座，再往上补充新标签**。后续更新保留既有资料和个人补充，不用新增的英文标签包整库覆盖；分别评估主词库、英文 Wiki 和中文资料的来源版本，不能混成一个“词库日期”。

### 中文资料上游更新核验

2026-11-14 查询 GitHub 默认分支文件树及该 CSV 的提交历史，最新文件提交是 [2026-10-30 更新数据库](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/commit/dfaae36836bc690bee3338904096a4e1d98534f0)，完整提交 `dfaae36836bc690bee3338904096a4e1d98534f0`。仓库本身后续还有推送，不能把仓库活动日期当作 CSV 更新日期。

完整下载固定提交的 `origin_database/tags_enhanced.csv`，HTTP 200，8,093,341 字节，SHA-256 `3ae2c21347b57b23f4b7f62fcc78a60eb079a228d00264b0041e0edb269798a1`；Git blob SHA-1 `9bf480ec39fd242340862f28cc457017349bec16`，与当前默认分支文件树一致。

沿用现有 `build_profiles.py` 的只读解析规则，以内存中的候选 lock 校验全文件，没有改写正式 lock 或执行建库：

| 项目 | 本地底座 | 10 月 30 日候选 |
|---|---:|---:|
| 原始 CSV 行 | 53,863 | 54,410 |
| 有效资料 | 53,860 | 54,407 |
| 隔离异常行 | 3 | 3 |
| 缺少简释义 | 1 | 1 |

- 新增有效名字 **547** 个；原有 **53,860** 个全部仍在，未发现旧有效名字消失。
- 同名条目中 **3** 个中文核心词／同义词／简释义变化，应单独核对再决定采用，不能将文本变化自动视为质量改进。
- **39,109** 个同名条目热度变化，**2** 个类别变化；其中 39,107 个只有元数据变化。没有简释义变空或敏感标记变化。
- 三行异常仍是原先同名异文／非规范名问题，继续隔离，不为了数量猜测改名。

可以在保留底座及个人补充的前提下增补 547 个条目；新增英文标签仍通过后续中文语义补充逐步扩展覆盖。本次只作对比，现用数据库、原始来源文件、正式 source lock 及向量索引均未改。证据为 `.dart_tool/dictionary-source-research-20261114/search-*.json`、`search-tags-enhanced-20261030.csv`，统计见 `search-semantic-comparison.json`。

## 官方 API：原始内容优先

来源：[API 总说明](https://safebooru.donmai.us/wiki_pages/help:api)、[Wiki API](https://safebooru.donmai.us/wiki_pages/api:wiki_pages)、[官方源码](https://github.com/danbooru/danbooru)。

使用本次研究 User-Agent，匿名实际读取以下接口，每次只取 1 条必要字段：

```text
https://danbooru.donmai.us/tags.json?limit=1&search[order]=date&only=id,name,category,post_count,updated_at
https://danbooru.donmai.us/wiki_pages.json?limit=1&search[order]=updated_at&only=id,title,updated_at,is_deleted
```

- Tag：HTTP 200，ID 2776241，`updated_at=2026-11-13T23:51:44.212-05:00`。
- Wiki：HTTP 200，ID 313655，`updated_at=2026-11-13T23:47:45.051-05:00`。
- 两者换算台北时间均为 11 月 14 日。本机 Safebooru JSON 尝试曾返回 403，不能据此判定主站官方 API 不可用。

官方提供更新时间筛选、分页及字段筛选。持续采集按文档约 1 请求／秒控制，不按瞬时 10 请求／秒额度持续抓取；正式采集使用可识别的应用身份，保留分页／更新时间依据。当前只核验少量读取及文档，没有跑全库抓取或测定全量覆盖。

[官方 BigQuery 讨论](https://github.com/danbooru/danbooru/issues/5222)也可作为批量路线线索，但需要调用者的 Google 项目／作业环境，本次未验证表的新鲜度、执行查询或发生费用，不建议为了本轮更新给桌面新增该依赖。

## Tag：同源 11 月月度包

来源：[维护者采集程序](https://github.com/DraconicDragon/danbooru-e621-tag-list-processor)、[月度构建记录](https://github.com/DraconicDragon/dbr-e621-lists-archive/actions/runs/41648330147)、[附件元数据 API](https://api.github.com/repos/DraconicDragon/dbr-e621-lists-archive/actions/artifacts?per_page=15)。

| 项目 | 实测值 |
|---|---|
| 工作流提交 | `b46f08e5bc5ff98063c1f955786c43850a94b7c0` |
| 附件 | `13236079143`，`tag-list-processor-output-11` |
| 创建／到期 | 2026-11-03T13:59:04Z／2027-02-01T13:52:59Z |
| ZIP 大小 | 11,624,840 字节 |
| ZIP SHA-256 | `eba144821704fc26b2beaaf9f4a165fe6a671d10491d915390455c7d9223f129`，与 GitHub 摘要一致 |
| 目标 CSV | `tag_lists/danbooru_2026-11-03_pt20-ia-dd.csv` |
| CSV SHA-256 | `86d2829874a494391fb1e96facdfabe0f99ec4648e48b6d5d84a89464ef0bc8b` |
| 完整解析 | 223,786 行，全部四列；规范名去重 223,784 个 |
| 相对安装库 | 3,626 个未收录主标签名 |

规范化按现有规则 trim、转小写、空格换下划线；2 个规范名碰撞不等于原始 CSV 含两条完全重复行。类别含 general、meta、copyright、character、artist。

当前库有 85,657 个名字不在这个候选中；当前库保留其他来源和历史条目，不能把差集当删除清单。建议继续按 Danbooru 数据合并，保留 e621 等既有来源，不能直接用候选规模替代合并库规模。

匿名请求附件 ZIP 返回 401；本次使用已有 GitHub 凭据下载成功，未打印凭据。加上到期机制，这个地址适合维护流程取料，不适合直接作为应用下载源。接入时可将验证后的固定快照放到稳定公开地址，并保留来源、日期及摘要；本次没有上传或修改接入。

## Wiki：9 月快照确有新内容，但范围不同

来源：[dartags/danbooru-wiki-2609](https://huggingface.co/datasets/dartags/danbooru-wiki-2609)。固定修订 `fcf861cf9c75954f4fba9d7c254724c3d9051a1c`，文件 `data/train-00000-of-00001.parquet`，55,281,256 字节；实读 SHA-256 与 LFS 一致：`1efcc2ccb76280d801d104616ba94079cc18aaec8eef2a0d1129c3f36c2ebbcd`。

完整解析而非仅看数据集预览：

| 项目 | 数量／结果 |
|---|---:|
| 原始记录／唯一 title | 264,338／264,338 |
| 空正文 | 61,739 |
| `is_deleted=true` | 0 |
| 按现有导入边界过滤后的有效唯一条目 | 202,599 |
| 最晚条目更新时间 | 2026-09-02 20:49:30.345+08 |
| 更新时间晚于 2026-06-01 UTC 当日结束 | 35,373 |
| 当前安装库没有的名字 | 10,735 |
| 同名正文有差异（归一化空白后） | 20,010 |
| 同名正文一致（同上） | 171,854 |

正文差异只是文本比较，未逐篇判断正确性，也不保证每条都比本地内容新。按候选缺失当前 96,323 个条目，不能视为删除或据此证明候选错误。

额外抽查：`help:api`、`tag_group:body_parts`、`howto:tag`、`tag_groups` 当前库存在而候选没有；`1girl`、`original` 两边均有。该样本说明直接替换会丢页面，但不足以推断全部采集过滤策略。

数据卡没有明确标注许可字段，也没有完整说明采集来源／过滤规则；这不等于断言原文没有许可，但再分发前需要核清继承许可与署名。当前为 Parquet，现有批量入口为 JSONL，接入还需相应转换。结论是保留为合并候选，当前六月库及不在候选里的文章继续保留。

## 其他候选的取舍

| 来源 | 查到的事实 | 结论 |
|---|---|---|
| [patvessel/danbooru-wiki-2606](https://huggingface.co/datasets/patvessel/danbooru-wiki-2606) | 指定 JSONL 摘要仍与现用六月文件一致，修订 `f10616722a3d4c88a4cb16747e24b08568df4afd`；未找到该发布者更新的 Wiki 数据集 | 保留稳定回退，不称实时源 |
| [NEXTAltair 聚合库](https://huggingface.co/datasets/NEXTAltair/genai-image-tag-db-CC4)／[构建清单](https://huggingface.co/datasets/NEXTAltair/genai-image-tag-db-CC4/blob/main/build_manifest.json) | 自标 2026-11-02 构建，实际锁定 `deepghs/site_tags@2b4de8c3f79540b10387a6fa7f251274f0b224a8` | 新打包不代表原料新；不是新 Wiki 原文源 |
| [deepghs 的 Danbooru 文件](https://huggingface.co/datasets/deepghs/site_tags/tree/main/danbooru.donmai.us) | Tag／alias 原料最近内容提交为 2025-09-25，提交 `058abf56130e433f92cb8de17ff990e8b890b467` | 上述聚合库的 Danbooru 原料比当前还旧，不采用 |
| [Jannchie/danbooru_metadata](https://huggingface.co/datasets/Jannchie/danbooru_metadata) | 2026-08-07 修订有采集程序与说明，当前文件树没有可下载的数据／数据库产物 | 可看采集实现，不能当作已核验的新数据库 |
| [JackBinary/danbooru-db](https://huggingface.co/datasets/JackBinary/danbooru-db) | 2026 年 5 月、general 且高频过滤，约 9,322 条 | 范围更窄且更旧，不作全库替代 |
| [Krita 标签构建说明](https://github.com/Acly/krita-ai-diffusion/blob/main/ai_diffusion/tags/README.md) | 提供官方 BigQuery 构建路线，但分发列表有频次门槛及数量上限 | 可作实现参考，不误认为完整词库 |

聚合库只检查数据卡、构建清单、原料树及提交元数据，没有下载约 2.9 GB SQLite，也没有独立验证其自报全库行数。上述是本次查到并核验的候选，不宣称穷尽所有公开镜像。

## 后续实施建议与本次边界

1. Tag 更新发现覆盖同源月度产物；维护端取料后验证并形成稳定公开快照，继续走现有哈希校验、建库和切换流程。
2. Wiki 优先使用官方原文刷新；批量源另记录内容日期、来源修订及采集范围。九月候选核清范围和署名后再合并，保留现有帮助页及其他候选缺失内容。
3. 不因数据集改名就要求重发应用：数据版本发现与具体文件版本分开；具体实现以用户后续需求为准，本次不增加机制。

证据保存在有效源码 `.dart_tool/dictionary-source-research-20261114/`：上游 API／文件树／数据卡、完整候选文件及摘要、`compare.py`、`candidate-comparison.json`、`access-and-coverage.json`。本地 SQLite 使用只读 immutable 连接；比较只输出统计，不写用户数据。

本次仅增加调查文档和工作区更新日志；无需 Flutter 测试或构建。公开版本仍 2.3.4+102，桌面仍 2.3.3+101；没有提交 Git、启动 Studio、调用模型／NAI 或改动 RAG 索引。

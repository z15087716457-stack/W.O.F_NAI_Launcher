# 标签检索、共现与压缩历史 · 实现记录

2026-10-31（Asia/Taipei）。用户确认按建议的精简范围开工。本批**源码完成、尚未构建／安装／发布**；桌面仍为 2.2.2+66。此前资源小窗／服务商输入和 `studio_context.search` 两批源码保留，分别见[小窗记录](resource-window-polish-2026-10-30.md)、[上下文状态](agent-context-search-status-2026-10-30.md)。

## 最终范围与行为

### RAG 状态、锁与慢路径

- 搜索初始化或索引状态未知时返回 `busy / warming`；只有确认空库才报 `not_indexed`。部分索引继续可查，GPU 让出与真实错误保持区别。
- 个人语义补充库启用 WAL、短忙碌等待。现有写事务内未发现网络操作，不能把故障归因为已证实的“忘记提交”。只对补充库的 SQLite BUSY／LOCKED 做本次查询的局部降级，返回 `degraded: [supplements_unavailable]`；基础来源继续可读。其他结构／读错继续报错，不一律吞掉。
- 降级副本不改变建库来源或指纹；只有基础文件仍匹配建库快照时才允许保留带旧补充资料的向量，类别与当前标签仍核对。状态计数不再无谓附加详情库，补充 revision 读取最多等待 200ms；这不是整条查询的总超时保证。
- 分类成员按数据版本复用；全局 ANN 后过滤不足时逐步扩大取回，最多四轮，再沿用原有范围精确回退。小来源与跨集合隔离保持，不新增 ANN 分片或全库常驻矩阵。
- Worker 返回安全的 `database_locked`／`source_unavailable` 类别，不透出原始路径或 stderr。

### 标签召回与排序

普通手动标签查询先取较宽的视觉候选，以 `cosine + 0.04 × log10(Danbooru post_count + 1)` 排序，并保留实体候选通道、精确名／别名及概念覆盖。最终普通手动查询不再调用 CrossEncoder；识别为实体的手动查询和原有空框上下文推荐保留重排。词频仅取已有 Danbooru 表，不用混合目录中的其他站点频次当作 Danbooru 先验。

Wiki／块库／图库的检索流程、模型依赖和向量格式保持；没有增加重排开关、黑名单、负 logit 阈值或实体硬过滤，也没有自动重建索引。

### 共现与 `tag_related`

- 编辑器和 Agent 共用现有 `CooccurrenceCompletionSource`。读取输入词的完整双向邻接，批量取标签元数据，先算关联再取 top-k，修正原来先按次数截断的问题。
- 默认沿用 Jaccard。不同快照中超出边际频数的共现次数先钳制；缺少有效边际频数的候选不伪造分数。多输入先按支持来源数、再按关联总分排序，返回平均分和 `sources / support`，不称为联合概率。
- 对照 NPMI、条件概率 × 正 PMI 后保留这个默认值：当前数据没有可信的同快照总帖子数，避免为了换算法引入任意总体估计或评分模式。借鉴上游的来源归因和精简返回，参考固定提交 [dfaae368](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/blob/dfaae36836bc690bee3338904096a4e1d98534f0/core/engine.py#L1422)。
- 新业务工具 `tag_related`：`tags` 1–20、`exclude` 最多 500、`categories` 默认 general、`limit` 默认 20／最多 50。只规范已有名称／确切别名；返回未知词，不模糊猜测。结果含 `source / network_requests / algorithm / resolved / unknown / items`，每项为标签、类别、词频、分数、支持来源及本地已有中文名。
- 纯本地只读，不创建 RAG controller/settings，不调用翻译或网络。无共现文件沿用真实数据源错误，不混同普通零结果。没有新增表、数据下载、页面、自动推荐或草稿写入。未使用的旧 `CooccurrenceService` 不为本批另行重构。

### 对话压缩与原文回查

- 主对话和历史导航共用一次完整当前分支映射，流式消息覆盖持久化副本；Pi 的模型上下文仍保持压缩。压缩分隔线留在真实位置，旧轮次、附件和编辑／重发入口继续可用；当前分支校验保持。
- 消息身份使用 role／timestamp，已验证原生 Pi 压缩摘要与历史记录时间一致。重复摘要文字不会合并两次压缩；没有实际用户发言的拆分轮次不画空用户气泡。保留原卡片样式、惰性列表与 renderKey 复用。
- 原生 Pi 扩展 `session_history` 经按需发现提供 outline/search/read/read_turn，仅使用 `ctx.sessionManager.getBranch()`；不自行读 JSONL，不接受跨会话路径。省略思考和图片／二进制，先脱敏再截取，结果最多 20000 字符并提供 `next_offset`。
- `tag_related` 是按需业务工具，`session_history` 是原生 deferred 工具；默认直接声明仍为 read/write/edit/bash/studio_context/ask_user/codemode 七个。nai-studio lookup 只补简短分工，不增加系统提示或摘要索引注入。

## 真实只读质量对照

用当前生效的标签／Wiki 修订、既有 f32 USearch 索引、原有 EmbeddingGemma 与 Qwen3-Reranker-0.6B 对比 HEAD 基线和本批候选方案。模型本地加载，未请求付费服务、生图或建库。索引指纹为 `351a8fe4d173546e21bc2d22e169746dd6290c6b1a17496173882cfdfe231266`；标签修订 `30ab4770…`、Wiki 修订 `d5172ef8…`，查询前核对 source_base 与样例 digest，前后源文件及索引统计未变。

原报告 39 条加预先另列的 13 条保留样本，覆盖多语言、多要素、实体和冷门标签。R@10 为每条 gold 命中率的均值，MRR 在返回的 30 项内计算。没有另做完整的无关查询误报评测。

| 配置 | 原 39 条 R@10 / MRR | 原 39 条 P50 / P95 | 保留 13 条 R@10 / MRR | 保留 13 条 P50 / P95 |
|---|---|---|---|---|
| 原 HEAD | 0.533 / 0.622 | 1303 / 3546ms | 0.859 / 0.865 | 3424 / 3465ms |
| 扩大召回＋先验，继续重排 | 0.762 / 0.912 | 509 / 1244ms | 0.936 / 0.872 | 450 / 506ms |
| 最终：普通手动查询不重排 | **0.818 / 0.937** | **248 / 1087ms** | **1.000 / 0.949** | **228 / 454ms** |

本机 RTX 4080 16GB，auto 设备选择；模型预热后串行测组件查询，首次分类缓存仍计入。模型加载另约 9.61 秒。这些是单机小样本，不是完整 Dart／IPC／大画布端到端延迟、FPS 或普遍质量保证；未采集完整应用峰值内存。保留集用于比较三种候选选择，后续不应再把它当未看过的盲测集。

第一轮误用了包内旧标签／Wiki 快照，发现 digest 不匹配后弃用，失败材料另存 `quality-bundled-source-invalid.*`；上表只使用修正后的活动来源。最后的 200ms 状态读取和无详情计数调整未改变排序公式，对应 Python 回归重新通过，未冒称重新跑了质量表。

## 共现性能与界面证据

活动共现库 3,236,959 条关系／约 307MiB，Dart 直接只读共享查询层；各输入首轮后再测五次，不包含 Pi IPC、首次 provider／词库加载或中文资料读取。双标签热查询 P50/P95：

| 输入 | P50 / P95 |
|---|---|
| holding_umbrella + rain | 22 / 25ms |
| school_uniform + cherry_blossoms | 78 / 78ms |
| snow + winter | 16 / 16ms |
| underwater + fish | 17 / 18ms |
| maid + twintails | 105 / 107ms |
| 20 个高频标签压力输入 | 1104 / 1128ms |

常用输入多数接近首版 100ms 目标，maid 组合略超，最大输入没有达到该目标；保留 20 词能力，不为追逐单一数字引入新整图索引。结果样例为雨伞、冬装、珊瑚、女仆头饰等相关搭配。共现评分不使用 GPU。

真实字体的 420×900 合成历史实绘已检查：压缩前旧消息、原有压缩卡片、后续消息连续展示，没有伪造的“你”行；这是测试组件截图，不是用户正在运行的桌面窗口。当前 UI 风格保持。

## 回归与材料

本地原始材料位于源码 `.dart_tool/rag-related-20261031/`，不提交用户数据、原始会话或模型／构建产物。

| 检查 | 实跑结果与日志 |
|---|---|
| Dart 范围回归 | 911 通过；autocomplete、tag_expansion、Agent provider／wiring／UI、RAG startup/runtime 和 UI 分层。`dart-regression.log` |
| 最后历史边界修改 | 31 通过，含重复摘要两次压缩与历史 UI。`history-boundary-final.log` |
| 共现最终查询与性能 | 7 通过（含临时只读性能用例）。`related-final.log` |
| 共现真实 Pi 链路追加 | 4 通过，含 Dart → Node/Pi → CodeMode → 真实 Dart 业务闭包、中文结果和七入口验证。`related-wire-final.log` |
| 登记 Node 的既有宿主／状态链路 | 15 通过。`bundled-node-wire.log` |
| Node 全套串行 | **117 通过，0 跳过**。`node-release-check.log` |
| Python RAG 全套 | **122 通过，3 跳过**／共 125。跳过的是需显式 `RAG_TEST_PYTHON` 的原生宿主所有权用例。`python-release-check.log` |
| 完整静态分析 | **No issues found**，15.0 秒。`analyze-release-check.log` |
| 合成历史实绘 | 1 通过，已目视检查。`capture.log`、`history.png` |

追加检查与 911 存在重叠，不把各轮数字简单相加。测试覆盖 WAL 双连接、实际排他锁／降级、非锁结构错误、来源／向量不变、ANN 缓存和扩取、精确实体／idle 重排保留、别名／未知／排除／类别／取消、压缩前附件及分支限制、历史输出脱敏／分页／大小上限。中途失败日志保留；固定扩展数量的旧断言已改为验证所选扩展与 deferred 暴露行为，最终完整 Node 套件重新通过。

## 未纳入和交付边界

摘要索引／固定提示注入、UI／传输历史分页、画师共现资料、自动多跳推荐与新推荐面板继续暂缓；原“继续建库耗时”专项不在本次查询优化内。没有实施外部报告的全部 T1–T13。

本批不升版本、不自动热重载或启动 Studio，不改用户草稿、角色框、实际图库文件或索引。构建／安装和实机反馈仍需按用户之后的具体更新指令开展；源码已完成项不会继续列为待开发。

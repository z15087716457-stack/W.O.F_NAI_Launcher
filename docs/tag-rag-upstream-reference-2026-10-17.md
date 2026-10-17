# 标签 RAG 结果替换与 DanbooruSearchOnline 对照

2026-10-17 用户报告插入光标后出现相关标签，稍后又被其他结果挤走，并要求先参考日常使用的 Danbooru 搜索开源项目。本轮只调查，检索实现、模型、正式索引和桌面包均未修改。

## 当前链路的复现

源码为 `6df1ae6b5011c1bfbf0e850bb70f515acd5a83ae`，桌面仍 r22。使用此前已验证的 969535 条独立副本，SQLite 以 immutable 只读打开、ANN 只读映射，加载现有本地 Gemma 嵌入与 Qwen 重排模型；未连接正式索引、未生成图片或请求云模型。证据在 `.dart_tool/tag-rag-ranking-investigation-20261017/`。

- 弹窗先显示普通查询／共现推荐，再等待完整 `Engine.search`，后者包括嵌入、80 条向量候选召回、与普通候选融合、32 条候选重排。界面没有单独显示“向量召回完成、重排未完成”的结果。
- `_runRag` 把精确匹配放前，然后放 RAG，最后才放其余普通结果，整体截断到展示上限。同一请求也会改变列表顺序并把旧候选挤出截断范围。现有取消、序号、草稿变化和用户选择冻结保护已有；本症状不据此认定为过期请求回填。
- “绿色的植被”真实链路前列为 grassy、veggie、viridian_forest、greening、feuille_vert，与用户截图一致。向量前 32 项只有 14 项通用类，画师／角色／作品已经混入召回；grass、forest、leaf、tree、plant、vegetation 均未进入前 80。英文 green vegetation 同样遗漏这六项。
- 对照实验把这六项补进同一候选集，原重排可将 grass 排第一；仅对重排输入补标签类别后，grass、vegetation、grassy、forest 排前四。此为候选集消融，尚未接入生产，不能证明所有查询均改善。说明直接删除重排不足以解决召回遗漏，当前类别信息缺失也会影响消歧。

## 上游实现（核对当前代码）

参考 [SuzumiyaAkizuki/DanbooruSearchOnline](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline)，固定提交 `4e99f95adfcd53a8cabd1eb097294b1c7af069a6`。只读克隆在 `.dart_tool/danbooru-search-reference-20261017/upstream/`，没有执行项目服务、安装依赖、下载模型或合并代码。历史归档仅用于定位仓库，其旧数据量／阈值不作为当前事实。

1. [四路检索](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/blob/4e99f95adfcd53a8cabd1eb097294b1c7af069a6/core/engine.py#L205)：英文名、中文扩展词、中文简释义、中文核心词各自嵌入，使用 BGE-M3；完整查询、显式分段和可选关键词分别检索。每路用归一化向量矩阵乘法取候选，按查询语言和长度分配各路配额；代码把 Top K 分摊给层，README 的参数概述不能直接替代实现。
2. [评分](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/blob/4e99f95adfcd53a8cabd1eb097294b1c7af069a6/core/engine.py#L578)：候选分为语义相似度与归一化 log 热度的加权和，默认热度权重 0.15；同 tag 多路命中取较高分。启用分词时，再用完整查询与候选的向量一致性作软调整，保护每个概念的高分结果并提供分组多样性。没有独立 CrossEncoder，但有轻量评分与排序。上游阈值随其模型和数据校准，不能直接移到 Gemma。
3. [主搜索数据](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/blob/4e99f95adfcd53a8cabd1eb097294b1c7af069a6/origin_database/tags_enhanced.csv)：实读 GBK CSV 共 53863 行，通用 25098、作品 5872、角色 22890、画师 2、元标签 1；最小 post_count=10，并非旧归档所称所有词至少 100 次。veggie、greening 等本次噪声不在此主表。画师另有名称匹配与共现入口。当前本地标签副本为 638024 条，检索范围差异很大。
4. 中文文本经过专门扩充与整理，覆盖同义称呼、视觉含义及短说明；`cn_core` 取中文同义串首项。我们的标签文本为英文名／别名加可用 Wiki 前 500 字符，属于原文截段，不能等同这类专门制作的简释义。即使有 Wiki 文本，短名称向量和正文向量也没有被独立检索。
5. [共现](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/blob/4e99f95adfcd53a8cabd1eb097294b1c7af069a6/core/engine.py#L1422)按多种子累加 NPMI。搜索和共现推荐使用不同区域／响应；[刷新调度](https://github.com/SuzumiyaAkizuki/DanbooruSearchOnline/blob/4e99f95adfcd53a8cabd1eb097294b1c7af069a6/webui/recommendations.py)合并同选择快照、丢弃旧 generation，并保留仍被选中的旧关联项。主搜索等待完成后一次更新，不经过当前弹窗“普通结果先显示、另一套评分后顶到前面”的合并方式。

## 后续建议与边界

优先验证当前弹窗的列表稳定策略、场景／名称查询的类别区别、常用标签覆盖和适度热度评分，再评估常用标签的简释义／同义表达及额外检索视图。保留全词库供精确名称查找，不据通用场景误命中而全局删除画师／角色。

标签重排是否默认启用，应在同样候选、同样语料和查询集下做有／无重排对照；上游无重排模型本身不能证明当前模型无效。四路表示会增加向量存储，后续应按常用子集和现有内存映射方案设计，不直接把 64 万标签全套扩为四份。

本轮未调用上游在线服务或运行其 BGE-M3，未做两系统同查询的在线质量／速度比赛；不能把源码差异当作已测收益。未改现有 Wiki 独立检索，也未实施用户已暂缓的标签＋Wiki 混合检索。待安装的默认重试与内存映射源码保持。本报告只借鉴机制，未复制上游实现或打包其数据库。

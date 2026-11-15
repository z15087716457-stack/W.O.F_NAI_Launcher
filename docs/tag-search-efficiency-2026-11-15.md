# Tag 字面搜索、共现与 RAG 效率调查

2026-11-15。本次只调查和测量，没有修改产品逻辑、内置指引或用户设置，没有构建／安装、启动 Studio、联网请求模型或调用生图接口。

## 结论

- 已知英文标签名／别名时，`tag_query` 默认搜索最合适；RAG 并不增加本次明确名称样本的命中率。
- 不知道标签名，只有中文、动作、构图或画面描述时，`studio_search(source=tags)` 明显更有效。热查询中位数约176ms，相比默认字面搜索多约131ms；不能把这4倍的后端耗时比直接解释成整个 Agent 任务慢4倍。
- 共现适合找已有标签的搭配。本次7组具体双种子查询的热中位数35ms；单个高频 `long_hair` 则254ms，整段20种子1365ms。开销取决于邻接量和种子特点，不能只按种子个数推断。
- 少调用不等于效果差。本地记录确实明显偏向字面搜索；工具可发现性没有单独封锁另外两项，已就绪状态也不少。现有指引描述用途，却没有明确的选用触发条件，可能影响选择；本轮没有对模型决策做付费 A/B，不能认定因果。

## 数据与方法

有效源码：`.devin/wt/ui-integration`。复用当前桌面 `user-data` 的数据库、模型与索引。RTX4080、16GiB显存，RAG设置已开启、tags来源开启、device=auto，实际使用CUDA。Embedding为本地 embeddinggemma-2，实体查询使用本地 Qwen3-Reranker-0.6B。

| 数据 | 数量 |
|---|---:|
| 基础 Tag 库 | 309,441行 |
| 已同步 Danbooru Tag | 553,864行 |
| Wiki | 298,922行 |
| 共现边 | 3,236,959行 |
| 现有标签向量 | 638,857个 |

以上库有重叠，不能相加作为唯一标签数。索引 `source_base` 与当前来源匹配；97个参考标签中，96个存在且向量摘要与实时数据一致，另一个 `transparent_raincoat` 在字典中不存在，质量统计排除该查询，不当作检索失败。

复用此前已登记的70条查询及参考标签，覆盖明确名称、别名、英文短语、中日文、抽象描述、角色名、错字、复合标签和留出样本；另用9组已知标签测试共现。统一limit=20，每种字面／RAG模式跑4遍，第一遍与后三遍分开；共现跑12遍。合计948次查询，热样本729个。遍历顺序逐遍反转，没有对结果专门调参。

- 字面和共现调用真实 `naiAgentKnowledgeTools` 执行器，保留统一标签库、同步标签覆盖、别名解析、Wiki／中文缓存查询与结果序列化。用真实只读基础库／Wiki／共现库；运行库和可写译文缓存使用 SQLite 一致性副本。两项隔离 Flutter 测试均通过，最终日志无回退警告。
- RAG调用真实 `Engine.search`，只读打开现有 pool SQLite，并以 `Index.view` 映射现有ANN；跳过会恢复／保存索引的构造和 Worker.configure。参数与 Agent adapter 一致，输出按同一字段投影。不建库、不改索引。
- 测量含实际查询、实时候选复核和JSON序列化；不含模型规划、工具发现、IPC、完整应用启动或付费LLM往返。Dart端为Flutter测试运行环境，不是桌面Release端到端实测。
- 测试串行运行，不清OS缓存，不冒充机器冷启动。后台GPU占用存在：RAG开始31%、结束25%，各遍结束约25–32%；这是当前使用环境测量，不是无背景负载的硬件极限测试。

## 耗时与返回体积

| 入口／场景 | 热样本数 | 中位数 | P95 |
|---|---:|---:|---:|
| tag_query 默认 | 210 | 44.36ms | 56.15ms |
| tag_query contains=true | 210 | 112.07ms | 123.28ms |
| tag_related，全部9组 | 99 | 71.73ms | 1395.05ms |
| └ 7组具体双种子 | 77 | 34.75ms | 133.93ms |
| └ 单种子 long_hair | 11 | 253.64ms | 378.86ms |
| └ 完整20种子 | 11 | 1364.98ms | 1638.60ms |
| studio_search tags | 210 | 175.75ms | 502.03ms |

RAG测试进程首次搜索29.45秒，包括惰性导入、tokenizer／embedding模型加载、首次查询及缓存准备；索引视图初始化另计0.28秒。第一次实体重排查询1.62秒，后续实体查询通常约0.3–0.5秒。这里没有重建模型／索引，也没有测系统冷开机。

RAG热查询embedding阶段中位41.08ms，ANN阶段66.57ms；其余主要是来源查询、候选复核及结果整理。280次RAG查询中只有24次进入重排，均为实体相关查询；普通手动描述搜索沿用现有混合排序，不能将全部RAG耗时归因于逐条重排。

仅看确实返回20项的样本，JSON正文体积中位数：默认字面5065B、contains4685.5B、共现3017B、RAG3300.5B。样本内容不同，不能据此宣称固定token比例；空结果正文只有73B，也不能把“没搜到所以返回少”当效率优势。未实测具体LLM tokenizer成本。

## 效果

下表为每条查询参考标签的Top10召回率，再按查询平均。它衡量这份小型参考集的覆盖，不是人盲评、全量精度或最终生图效果。尤其中文描述直接交给只支持英文名称／别名的字面工具，是能力边界对照，不能解释成“模型先翻译成合适英文关键词”之后的端到端胜率。

| 样本 | 条数 | 默认字面 | contains | RAG入口 |
|---|---:|---:|---:|---:|
| 明确名称 | 5 | 100% | 100% | 100% |
| 别名／近义表达 | 4 | 37.5% | 50% | 87.5% |
| 英文画面短语 | 6 | 16.7% | 16.7% | 77.5% |
| 中文描述 | 10 | 0% | 0% | 95% |

RAG入口本身含语义召回、精确名称和中文概念召回，以上不是“纯向量单独贡献”的成绩。

实际例子：

- `鱼眼镜头`：字面工具为空；RAG第一项 `fisheye`。
- `雨中撑伞的少女`：字面为空；RAG前十包含 `holding_umbrella`、`1girl`、`umbrella`、`rain`。
- `girl sitting by the window reading a book`：字面为空；RAG找到 `reading`、`sitting_in_window`、`holding_book`、`book_on_lap`，也有 `book_skirt` 等噪声，仍需模型筛选。
- `holding_umbrella + rain` 的共现前列：`umbrella`、`oil-paper_umbrella`、`transparent_umbrella`、`hydrangea`、`shared_umbrella`。
- `school_uniform + cherry_blossoms`：`serafuku`、`petals`、`pleated_skirt`、`sailor_collar`、`falling_petals`。
- 单用 `long_hair` 会带出 `breasts`、`large_breasts` 等常见相关标签；20种子例中也有 `swimsuit`。共现关联不代表用户意图或应当添加。

共现未强行套用语义参考集评分：它需要已有标签作输入，回答的是互补搭配，和把一句描述翻译成标签不是同一任务。

## 模型实际使用与接线

只统计本地工作区保存的9个会话，去重tool_call_id，不导出对话正文或查询参数：

| 指标 | tag_query | tag_related | studio_search（所有来源） |
|---|---:|---:|---:|
| 持久化的实际工具结果 | 664 | 1 | 4 |
| 引用该工具的codemode调用 | 42 | 3 | 2 |

两行口径不同：一次脚本可能循环／并发很多次，脚本引用也不保证成功执行；旧会话可能缺投影。因此664不能当作664次独立模型选择，studio_search也不能全部视为标签RAG。22次保存的studio_context中，tags状态ready17次、unknown4次、error1次。

接线检查：三项业务工具同样通过codemode按需发现；没有基础搜索直出而另外两项额外隐藏的区别。`studio_context.search_hint`始终提示名称／别名用tag_query、已知标签共现用tag_related；有ready／partial来源时才提示自然语言用studio_search。`nai-prompt`要求遵循search_hint，`lookup.md`和`search.md`也分别解释了分工。

这些证据能排除“因为共现／RAG根本没接上”及“标签RAG始终不可用”的笼统解释，不能证明模型少用的唯一原因。建议在原有一处指引里写清触发条件，先不加新工具或额外分支：

1. 已知英文名／别名：tag_query；只知道名称片段时再contains。
2. 不知道名称、描述构图／动作／气氛，或字面搜索未解决：若tags ready/partial，用studio_search(tags)，筛选后必要时wiki_query核义。
3. 用户要补充搭配／探索变体：选少量有区分度的已知标签调用tag_related；exclude已有提示词，避免把1girl、solo、long_hair等整段通用标签当完整种子组。
4. 用户请求已用确定标签解决时，无须为了调用而调用另外两项。

以上是后续建议，本次没有改提示词。要测模型是否按分工选择，应另用固定模型、相同创作任务及预算做工具选择A/B；当前报告仅含检索能力／成本实测和历史使用统计。

## 证据与复现

本地证据：`.dart_tool/tag-search-efficiency-20261115/`。

- `prepare.py`、`paths.json`、`environment.json`：当前数据身份、只读源戳与测试副本准备。
- `inspect_settings.dart`只导出RAG设置；完整Hive临时副本已删除。
- `catalog_benchmark_test.dart`、`catalog.log`、`contains.log`：真实Dart执行器，分别用默认参数及`--dart-define=BENCH_CONTAINS=true`运行。
- `rag_benchmark.py`、`rag.log`：现有只读索引及实际本地模型；`check_coverage.py`单独审计全部参考标签，修正覆盖审计默认limit=64的截断，不改搜索调用与计时。
- `catalog-results.json`、`contains-results.json`、`rag-results.json`、`queries.json`、`summary.json`：原始查询、结果、耗时与统计。`analyze.py`复算统计，P95用nearest-rank。
- `usage.py`、`usage-summary.json`：仅工具元数据汇总，脚本引用和确认结果分别统计。
- 运行前后所有登记源数据库、缓存及ANN的大小／mtime保持，SQLite原始连接均只读；完整设置副本和临时可写运行库／译文库副本清理，复现时由prepare重建。

源码依据：`nai_agent_knowledge_tools.dart`、`nai_agent_search_binding.dart`、`nai_agent_studio_provider.dart`、`cooccurrence_completion_source.dart`、`tool/rag/engine.py`及`tool/nai_agent/skills/nai-studio/references/{lookup,search}.md`。

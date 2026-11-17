# 维护债务清理完成核验

2026-11-17。用户授权清理后于11-16暂停，11-17继续并完成源码收尾。有效源码仍为`codex/uiux-integration`当前工作目录，既有未提交改动保留。本批没有构建、安装、启动桌面程序或发布；本机仍为2.4.1+117。

## 完成范围

- **标签RAG协议收口**：Python使用`TagEngine.search(query, existing, limit, cancelled, options)`，Dart使用`RagController.searchTags`；worker只接收明确`query`及现行过滤／数量／按次选项。旧`text/cursor/mode/lexical/negative/budget`与旧上下文选项移除，Ctrl浮层、Agent绑定、测试和截图替身同步。对外`studio_search`工具契约保持。实际用于本地共现的`ragContext`改名`relatedFromPrompt`，字段身份`ragScope`保留。
- **孤立旧词库退役**：删除脱离应用与开发入口的旧TagLibrary同步服务、provider及独占模型／生成文件；最后仅被繁中资源测试引用的旧分类／分组模型也已收敛，相应无用标签映射删除。没有删除旧Hive文件或现行catalog、语义资料与翻译存储。
- **旧页面和旧测试入口退役**：删除旧设置、生图、角色及关联视觉壳的独占分支与失去调用的后续依赖。共157个lib源码／生成文件、46个旧测试文件和3个旧捕获工具；退役文件原共59,729行，其中lib为44,046行。这些计数包含生成代码与旧测试，不作为功能质量指标。
- **有效测试保留并接到当前入口**：混合贴士测试迁至`GenerationEditorWiring`；图片卡、历史与蒙版行为保留，退役组件的树结构断言由当前画布交互测试承担。原生拖放测试设置提取为独立helper，当前测试不再导入退役测试文件。6套编辑器接线测试补齐标签服务替身，避免无关交互测试启动真实数据库；原交互断言保留，标签检索由专属provider／浮层集成测试覆盖。

当前导入图包含1,464个Dart文件，从main可达的仍为1,421个，与清理前一致。其余43个手写组件均有现存测试或工具引用；没有继续按“不可达”批量删除。SAM手动smoke、资源拖入解析等开发用途保留。图只能证明静态入口关系，不能代替运行回归。

## 当前覆盖入口

| 行为 | 当前验证所有者 |
|---|---|
| 设置、RAG环境与来源状态、缓存、Agent设置 | `test/presentation/ui/settings/`与`test/presentation/wiring/settings*` |
| 生图编辑、导入、画布、参考图、参数与后端 | `test/presentation/wiring/generation*`与`test/presentation/ui/gen/` |
| 参考库导入导出与展示 | `refs_library_wiring_test.dart`、`refs_import_export_test.dart`与`test/presentation/ui/refs/` |
| Ctrl搜索、Wiki图片、翻译与语义补充 | `test/core/{rag,autocomplete,tag_expansion,wiki}/`、prompt／tag_expansion组件及RAG／Agent provider测试 |
| 贴士与在用图片卡 | `tip_layout_test.dart`、`selectable_image_card_test.dart`及当前画布接线测试 |

## 验证结果

- 实际运行环境Python **145项通过**，包括5项固定DanbooruSearch代码同向量对照、3项原生worker进程检查。
- 主Flutter批次 **2,045项通过**；另1项仅在tearDown删除Windows临时目录时遇到共享占用，业务断言未失败。该文件随后纳入UI补充批次，并单独7项复测全部通过；原始失败日志保留。
- 当前设置／生图／参考库60个非独立golden测试文件，加随包真实worker和上述文件复测，**1,089项全部通过**。随包检查验证原生worker启动和固定CSV原始字节，使用隔离目录与指纹替身模型，不加载真实权重或写正式索引。
- Agent工具／协议／schema **40项Node通过**；繁中资源 **4项通过**；最终全仓静态分析 **0问题**，`git diff --check`通过。
- 生成器成功：263 outputs／690 actions。148个保留的`.g.dart`／`.freezed.dart`与开工前字节一致；语言生成器只改变换行的5个文件恢复原字节，既有ARB与未提交生成内容保持，只有退役标签的繁中映射按需收敛。

此前11项设置PNG差异已在改前复现。本轮未把独立golden文件计入上述UI功能批次，也没有修改PNG、遮罩或容差。不能据此宣称全部视觉基线已通过，亦未完成所有平台实机验收。

## 数据与后续边界

正式池只读核对仍为提示词块726段，原始向量行、元数据及容量摘要hash均与清理前一致；没有建库、清库、补编码或修改草稿。固定参考CSV hash保持。必要共享池迁移、旧缓存统计／清理与现行数据补充链继续保留。

本次收尾覆盖[审计](system-maintenance-audit-2026-11-16.md)中的旧协议、孤立分支和旧UI入口。活跃大文件仍有职责集中的维护风险，后续随具体问题调整，不因行数另建平行控制器。全库Gemma效果和端到端耗时仍需明确建库后的实际使用验证；本报告不替代[检索对齐边界](danbooru-search-alignment-2026-11-16.md)。

证据位于`.dart_tool/system-cleanup-20261116/`：`verification.json`、四份`*-retirement.json`、`before.json`和`before/`、`final-graph/import-inventory.json`、`python-final.log`、`flutter-functional-final.log`、`flutter-ui.log`、`settings-activation-rerun.log`、`node-final.log`、`analyze-complete.log`与`data-final.json`。开工前备份保留，不能重跑一次性capture／退役脚本。

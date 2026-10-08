# 生图07 · 整页收尾与检查点②（2026-10-08）

本段完成生图02–07，按每个任务的文字、所选A方案完整index/mock及跨页统一规定核对。检查点①复查修正基线为 `db2a7a3d`。检查点②待用户在外部Agent工具中交给Opus 5.5复查；真实窗口使用验收单独待确认。本段未构建、安装、启动、重启或热重载Studio，未调用真实NovelAI生成接口。

## 本任务修正

- V3没有角色模块时，提示词卡到参考图模块只留一处12px间距；主生图页与探索编辑列同步。V5/V4.5仍为角色、参考图、图像模块顺序。模块之外的基础提示词、生成链和探索Run控制条保持任务明确的不改范围。
- 历史栏底部回到HTML的40px高、左右6px内边距、2px按钮间隔；自动保存及其他工具均为28px按钮、16px原型SVG，折叠角按钮圆角5px。`AutoSaveToggleIcon`增加可选prototypeStyle，其他页面默认外观与原行为保持。
- 删除无引用的生图 `section_header.dart`；保留仍被经典 `SizeSelector` 使用的 `SidebarTitleScope`，统计页同名类不受影响。生图02已经移除无引用的旧图像小节文案键。
- 更新branding的模块/参考图/窄窗材质说明，Unreleased用户变化及中英文README旧截图说明。四份文档均有另一会话的改动，只暂存本任务段落，不整份提交。
- 修正生图05记录中的HTML按钮尺寸：浏览器实测参数摘要与历史底部按钮同为28px，摘要箭头为15px；实现箭头18px依据任务05。

## 整页验证

新增 `test/presentation/screens/generation/widgets/uiux_final_capture_test.dart` 使用真实 `GenerationScreen`、`WebStyleLayout`、探索页和窄窗 `ParameterPanel`，加载实际字体、HTML同一提示词/角色/历史原图和模拟状态。设置仅用内存、Hive仅用临时目录；探索Run存储与Agent偏好替换为测试实例，预热只引用只读素材路径。

- 常规2项通过：V3的12px间距与模型切换；三模型×两主题×1280/1600/1920窗口（左栏352/420/560）没有布局异常，模块数量正确。
- 最终采集3项通过：32个V5/V4.5×浅深×简中/英/日/韩×352/420主页面，加V3简中、探索页编辑列、窄窗面板，共35场景、69张PNG（每个桌面场景另采参数抽屉展开）。保留原始尺寸和模块边界测量。
- 最终历史栏采集1项通过，72张按生图07最新底部外观重生成。
- 本任务4个生产路径及新夹具共5路径分析 `No issues found`。全量分析只有下述原有探索测试的6项签名诊断。
- `flutter gen-l10n`成功；台湾正体与生成本地化按任务02–06规定更新。
- 全量 `flutter test --reporter=failures-only`：**4953通过、5设计跳过、9失败**。本阶段的UIUX测试没有失败。以下列出全部失败，不把有失败的全量结果写成通过。

## 全量失败与复测

1. `test/l10n/i18n_regression_test.dart`：7个原有未使用naiAgent键；生图02已用开工备份验证，键清单见 `.dart_tool/uiux-task02/existing-l10n-failure.json`。
2. `test/presentation/providers/nai_agent/questions_test.dart`：期望旧字符串 `Clarify missing inputs/preferences: ask_user`，实际Agent提示使用 `Missing input/preferences: ask_user`。单独复测仍失败，不属于UIUX改动。
3. `test/presentation/providers/nai_agent/workspace_controller_test.dart`：全量中的会话恢复报Connection error、停止队列等待10秒超时；两文件单独复测结果9通过/1失败（仅上一项文案失败），这两个会话测试复测通过。
4. 五个探索测试文件加载失败：`explore_lineage_panel_test`、`explore_pile_manage_dialog_test`、`explore_preference_sort_dialog_test`、`explore_run_control_bar_test`、`style_explore_screen_test`。另一会话源码的 `putRun`新增 `beforeWrite`，`startDeepRound`新增 `beforeGenerate`，这些旧fake没有对应参数。全量分析的6项invalid_override均在这五个文件。检查点①复查也已提示这组问题，本段没有改这些函数或测试。

日志：`.dart_tool/uiux-final/{gen-l10n,full-test,full-analyze,changed-analyze,unrelated-agent-retest,capture-final}.log`。保留完整错误和退出码，复查方可以复现，不修改别的会话源码来清绿本段。

## 原型对照与明确任务差异

`.dart_tool/uiux-final/comparison/index.html`有4组整页和4组完整左栏的并排/50%叠加，原型来自1600×1120、DPR1浏览器截图；整页裁去原型任务外导航48px，与生产页面1552×1120对照。两边都不缩放匹配。其他任务的组件对照也保留在 `.dart_tool/uiux-task02` 至 `06`。全段共389张原始widget实绘、22组同场景对照；均不是用户运行窗口截图。

| 出入 | 依据 |
|---|---|
| 基础提示词卡和角色内部文字行高、工具栏与HTML不同，模块纵坐标随原内部高度变化 | 页面README明确不改基础提示词卡内部；任务04明确不改角色头、标签、工具栏和编辑器，保留14px正文/28px角色头。模块外壳、排列、间距和定位控制按新要求实现 |
| 画布图像、三条浮动工具条及窗口按钮与HTML不同 | 页面README明确列为本段不改；使用真实当前画布，没有用HTML截图替换生产渲染 |
| 模块圆角6px/标题w600，图像模块底部8px；HTML圆角8px/w700/底部10px | 任务01、02具体数值优先；生图02记录有实测 |
| 嵌入参考行图标20px/箭头18px，HTML18px/15px；部分既有说明文案与动作仍在 | 任务03明确图标尺寸、复用字幕键、保留原按钮顺序与行为。含图收起背景按任务保留180px cover、2.4px模糊及遮罩 |
| 参数条箭头18px，HTML15px；摘要45px与HTML45.1875px | 任务05具体尺寸；字体排版亚像素取整差。两边按钮实测均28px |
| 历史列表194px正方格与HTML固定190px图高，后续批次位置不同；×N和来源内容尺寸仍为既有实现 | 任务06明确square、18+4标题与8px尾距，并明确保留来源、×N、占位及生成/拖出行为；轮廓按图片真实显示区域对齐 |
| HTML没有V3或完整外语/352px状态 | 按模型规格和任务文字验证，保留真实实现截图，不伪造对应HTML |

这些差异附材料依据供复查；不能据此跳过视觉审查，也没有宣称整页像素完全相同。用户要求以原型与任务文字为绝对要求，外部复查应复核每项依据及作用范围。

## 共用工作区保护与后续

开工73个已改的跟踪文件中，59个与本段无关的文件SHA256逐一相同；5份ARB的结构变化仅含本段8个新增键及删除1个旧键，未改变Agent键。其余为生成本地化和上述4份混合文档。本段索引与提交仅包含任务自己的变更，开工其他未跟踪目录未纳入。证据 `.dart_tool/uiux-final/protection-verification.json`。

源码仍在 `E:/A.I/NovelAI/.devin/wt/nai-launcher-src`，分支 `devin/gallery-redesign`。下一段为参考库01→大图01→大图02；检查点②复查通过前不开始。用户的实机验收和任何构建/安装另行记录，不冒充已经完成。

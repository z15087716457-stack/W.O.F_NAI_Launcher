# NAI Agent 方案 B 接线报告

日期：2026-10-18。工作树：`E:/A.I/NovelAI/.devin/wt/ui-integration`，分支 `codex/uiux-integration`；起点 `2858ab8f9`。

## 交付与映射

- `lib/presentation/wiring/nai_agent/agent_wiring.dart`：ConsumerStatefulWidget 观察既有 controller / providers，构造 `AgentViewData`、`AgentActions`、`AgentSlots`，渲染 `AgentPanel`。接通工作区／聊天创建、选择、改名、文件夹、压缩、原格式 JSONL 导出、设置／模型设置、输入持久化、发送／引导／排队、停止、队列编辑／撤回／恢复、消息编辑／重新回答。
- `agent_toggle_wiring.dart` 与 `NaiAgentDock`：三个旧开关挂载点均使用新 `AgentToggleButton`；保留外层 `nai-agent-toggle` key。宿主揭示动画、原生窗口增长／恢复、divider、resize 行为不变。
- 图片：文件选择、画布、对话／产物／近期图片 id、图片优先的剪贴板读取与文字回退、移除、元数据字符串，复用原图片导入和 `presentAgentImageImport` 反馈。drop slot 继续使用原 `NaiAgentDropTarget`（包含内部历史拖放协议），拖入状态回传 UI；可登记图片使用原生拖出包装。
- `agent_pending_mapper.dart`：ask_user／扩展 select、confirm、input、editor 映射为 AgentAsk；权限请求映射为 AgentApproval；生成／变体／增强／图像工具映射为 AgentGate。价格、余额、请求次数 × 每次张数、源图、额外配置来自 Studio 冻结报价；ready 每次重跑 check，点击仍经过原 `decide()` 再检查，未改变付费授权机制。
- `agent_thread_mapper.dart`：消息与 entryId、Markdown、连续步骤、工具状态／耗时／短参数摘要、嵌套 CodeMode 步骤、≤4 KiB 格式化且隐去图片字节的详情、逐字段 prompt diff、图片 artifact 与 Anlas／historyId、逐轮 shelf 图片和可确定的本地文件。
- `agent_resources.dart`：异步缓存本地图片／附件／备份／instructions.md／文件属性。图片有体积、像素与完整解码验证；artifact、备份和打开文件均限制在当前工作区，拒绝路径穿越和 junction／symlink 逃逸。
- `agent_diff_undo.dart`：从备份恢复单栏文本及 pill 文档；修改前备份当前草稿，在异步备份前后两次比较 `bridgeDraftVersion`，最后同步调用既有 bridge writer。新版本不匹配即拒绝；撤销成功变为 undone，后续编辑使其他 diff locked。
- `agent_context.dart`：草稿摘要、提示词／负面／角色 tag 数引用、积木名称；接线层补近期图片（上限 8）与启用 Skill、记忆内容、用量、运行／等待状态和 revision。
- 记忆编辑：设置路由增加 `anchor` 接线，支持 `agentInstructions`、`agentWorkspaceRules`、`agentSkills`。工作区规则一行使用已存在文案并通过系统编辑器打开当前 `instructions.md`；返回应用时刷新规则。
- 关键勘察修正：现有 CodeMode 历史只聚合 artifact，没有内层 prompt_update 结果，无法仅靠 Dart 重建可撤销 diff。因此 `tool/nai_agent/lib/extensions/interaction.mjs` 增加 `details.studio_results`，只保留 diff／artifact／计费所需的原生投影，不加入给模型的 content；宿主合成集成测试验证了持久化与内容隔离。

## 契约与限制

- **没有修改 `lib/presentation/ui/agent/` 中任何文件，Agent 契约也没有增加字段**；UI shell boundary 测试通过。
- controller 增加只读 `heldRuntimes`，用于聊天状态；image approval 增加可选 `expiresAt`，传递原审批定时器实际截止时间。
- 设置契约增加可空 `workspaceRulesPath`、`onEditWorkspaceRules`；设置壳增加可选初始 anchor。公共 `WindowPanelHeader` 在超宽 caption accessory 留下不足 112px 时缩放紧凑标题行，避免 320px 面板溢出，不改新 Agent UI。
- 未知工作区聊天数保持 null；未持有 runtime 的聊天显示 idle。聊天顺序沿用 createdAt，没有伪造 updatedAt。
- 没有工具起始时间，仅映射实际 durationMs；未知 context window 保持 null。没有编造费用、余额或运行进度。
- 历史会话的 CodeMode 结果若没有新投影，不能倒推旧 prompt_update 备份或缺失的 historyId／费用：只显示原有步骤和可读 artifact，不伪造可撤销 diff、历史入口或 Anlas。新会话已保留这些数据。
- 缺失／越界／损坏的 artifact 和备份被安全省略；附件读失败保留 UI 的破图状态。文件 shelf 只列出消息 artifact 或成功 write/edit 中能确定、真实存在且工作区内的文件，不扫描用户全部工作区。
- 新 UI 的附件元数据按契约提供为原文字符串并显示在 tooltip；图片查看、卡片布局和交互外观均使用既定方案 B，不恢复旧视觉组件。

## 删除与保留

删除 `lib/presentation/widgets/nai_agent/` 下：

- `nai_agent_panel.dart`
- `nai_agent_composer.dart`
- `nai_agent_controls.dart`
- `nai_agent_generation_card.dart`
- `nai_agent_image_approval_card.dart`
- `nai_agent_image_artifact.dart`

保留 `nai_agent_dock.dart`、`nai_agent_image_input.dart`；精简 `nai_agent_shared.dart`，仅保留旧设置页／宿主仍使用的 action 错误处理与模型选择器。删除已无生产引用的 **97 个 naiAgent_* 消息**及 **2 个旧卡片消息**（generation_generate、detail_imageDetails），四份手工 ARB 同步移除，按规定重新生成 zh_TW 与 localizations。保留 controller、设置页和导入反馈仍使用的消息。

## 验证

全部 Flutter 命令均显式使用登记 SDK `flutter-3.47.7`，测试／分析加 `--no-pub`。package_config 的 Flutter／flutter_test 均指向该 SDK。Node 使用登记包的 `tools/nai-agent/node.exe`。

| 验证 | 最终结果 | 本目录证据 |
|---|---|---|
| 全项目 `flutter analyze --no-pub` | **No issues found** | `analyze-final.log` |
| grep 定位的全部 Agent 相关 *_test.dart + `test/presentation/ui/agent` + UI boundary + `test/l10n` | **550 通过，40 跳过，0 失败** | `test-agent-final.log` |
| Node 全部本地合成宿主测试 | **48 通过，0 失败** | `test-node-final.log` |
| 全项目 `flutter test --no-pub`（最后一次，含新增平台测试） | **7719 通过，77 跳过，32 失败** | `test-project-final.log` |
| 方案 B 实字体实绘 capture | **40 通过**，生成 40 张本批 PNG；抽查 `new/chat-360.png`、`new/shelf-dark-460.png` | `test-captures.log`、`new/` |
| 台湾正体重生成 | **4 通过** + gen-l10n 成功 | `l10n-regenerate.log` |

新回归覆盖：mapper steps/diff/images/CodeMode、真实 bridge undo 和结构恢复／并发 guard、两类付费 gate 的按钮与 stale check、图片安全、原生窗口开合／精确恢复／clipping／resize／页面保留、输入 IME／剪贴板／跨会话导入、导入文件选择、JSONL 原样导出和取消、画布与 mention 附图、disabled skills、记忆与设置路由、多语言明暗窄宽／短窗和实字体。没有调用真实 NovelAI 或真实模型；宿主测试只使用 loopback 合成服务。

### 全量失败归属（没有隐藏或更新 golden）

任务预先注明的 5 项均仍失败：settings goldens `dictionaries`、`models`、`models-dark`；tools wiring 的 enhance、upscale。

另外 **27 项**在隔离的原始 `2858ab8f9` worktree、同 SDK 下逐项复现（`test-baseline-extra.log`，29 通过／27 失败；仅补入与当前未变输入对应的 172 个 ignored 生成文件以使基线编译，没有运行 pub get）。该临时 worktree 已移除：

1. `test/core/constants/app_version_test.dart`：preview 机器版本／build 断言。
2. `test/presentation/screens/settings/model_menu_activity_test.dart`：`test marker returns after failure`。
3. `test/presentation/screens/settings/settings_hover_feedback_test.dart`：`all four task hints and hover/tap reasoning advice leave configured effort untouched`。
4. `test/presentation/ui/channel/channel_golden_test.dart` 全部 24 张：random、random-dark、circuit、circuit-dark、stars、stars-dark、herb、herb-dark、arcade、arcade-dark、abyss、abyss-dark、wave、wave-dark、overview、overview-dark、transition、popover、popover-dark、popover-fixed、popover-off、generating、soft、strong。差异仍在旧 toolbar 左上区域；未改基准 PNG。

第一次全量另遇通道随机测试误判：新 seed `739884393` 被 `isNot(contains('seed: 7'))` 错判。单独复跑 `channel_test.dart` 为 **21 通过**（`test-channel-rerun.log`），最后一次全量也通过；没有修改这个无关测试。

## 硬规则核对

- 未运行 pub get、未更新依赖、未启动／重启／热重载用户应用、未调用真实生成、未推送。
- 未读写用户正式草稿／桥接／账号状态；测试只用隔离临时数据和生成替身。
- `DEVELOPMENT.md`、`pubspec.lock`、`.runs/` 原有改动未修改、未暂存、未提交。前两项首尾 SHA-256 完全一致：
  - DEVELOPMENT.md：`7b7a061e7c23a008d52cd2bcdb32bf9d64a9121db35ac6d7bd44de945485a98d`
  - pubspec.lock：`40cc50d969147cc44c105f8a2496b9cf8f39e903bc875d94fced3dee11e9e06e`
- 原宿主 reveal／divider／resize 和开关兼容 key 的行为测试仍保留。生产旧组件删除前已迁移其行为测试；旧视觉断言随旧界面退役。

## 提交

1. `b7e8d3fcb` — feat(agent): connect command-desk sidebar to existing runtime and paid gates
2. `45e7adfe5` — feat(agent): harden projections, memory navigation and migrate sidebar regressions
3. `3d4a20319` — fix(agent): persist CodeMode diff projections and retire unused sidebar messages
4. `4a768fa66` — test(agent): cover picker export, canvas attachments, memory and settings routes
5. 本报告单独以 `docs(agent): record command-desk wiring verification` 提交；未推送。

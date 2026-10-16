# 设置页两项边界修正 · 2026-10-16

用户在接线前检查后明确授权调整这两项；只补当前前端交付的边界，不代表 17 页后端已经接通。源码为 `devin/ui-settings`，基线 `78cb246857fb9ec6e6f5e0c4e0caf28a860b9bc3`。

## 已修正

- 语义检索下载、安装或建库期间，计划卡“开始”、暂停来源的“继续”和来源“更多”都不可用。已展开的菜单遇到忙碌状态自动关闭；已打开的清除确认框在确认时再核对最新状态。暂停建库、取消下载／安装及取消计划继续可用。
- 新增 `SettingsUpscaleData.seedOffloadMaxBlocks`（默认 32）。接线时由当前 SeedVR2 模型的 `Seedvr2Options.maxBlocks(modelId)` 提供：3B 为 32，7B／Sharp／INT8 为 36。`SettingsViewData.numberMax` 统一提供本页和可编辑搜索结果的控件上限。显示和切换数据不回写旧值；32 上限下的 31、36 上限下的 35 等自定义值不改写。静态 `SettingSpec.max` 表示该族最大 36，具体控件必须使用动态上限。

生产改动仅在 `settings_contract.dart`、`settings_controls.dart`、`settings_intel.dart`。没有改变文案、依赖、生成输入或其他页面。原计划卡测试改用真实的空闲／环境就绪条件，补充 12 项边界回归。

## 验证

登记 SDK Flutter 3.47.7 / Dart 3.13.5；执行：

```text
flutter test --no-pub test/presentation/ui/settings test/presentation/ui/ui_shell_boundary_test.dart test/l10n
```

- `flutter analyze --no-pub` 全仓无诊断；Dart formatter 与差异空白检查通过。
- 224 项通过，其中设置页 195 项（原 183 项加 12 项边界回归），包含原有 27 张中文基准截图比较。没有重录基准或扩大截图排除范围。
- 覆盖下载／安装／建库三种忙碌状态、取消与暂停、环境未就绪、展开菜单及确认框遇状态变化、32／36 在本页和搜索的端点，以及按模型切换时保留各自数值。
- 真实字体实绘 7 张；已查看忙碌计划卡及 7B 自定义值滑块。证据在 `.dart_tool/settings-boundaries-20261016/`（本机保留，不提交运行日志或图片）。
- 基线哈希核对 2467 个输入：只有本次预期的 3 个生产文件与 2 个已有测试文件变化；原 277 张 PNG（其中设置页 27 张）、语言／生成资源、主整合源码及已安装收据／AOT 保持。

## 正式后端接线仍须落实

- RAG 控制器、模型下载和环境安装需要共享执行层互斥；“开始／继续／重建／清除”执行前重新检查最新状态与计划。当前 UI 禁用不能替代后端互斥，本次没有修改这些 provider。
- 从所选模型读取并写回它自己的 SeedVR2 配置；低显存模式是卸载数量的派生显示，不另立状态覆盖用户自定义值；VAE 自定义分块同样保留。
- 本来源分支基于 F14 `ffdaba944`，不含整合分支 F15 `b73eb2156`。后续只取设置增量接入 `codex/uiux-integration`，保留已有首次语言入口；不能整份覆盖共享文件。

本次没有安装／启动／热重载 Studio、制作便携包或推送 GitHub；没有调用生成、模型下载或用户资料建库。主整合分支原有 `DEVELOPMENT.md` 修改和 `.runs/` 保留。

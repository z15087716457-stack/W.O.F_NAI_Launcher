# 开发与发布参考

按当前任务读取对应节。命令在 `nai-launcher-src/` 下执行；项目约束见 [AGENTS.md](AGENTS.md)，本机环境和功能不变量见 [OPERATIONAL_NOTES.md](OPERATIONAL_NOTES.md)。

## 构建、测试与开发命令

Flutter/Dart 版本要求以 `pubspec.yaml` 和 README 为准；下列命令按任务选择，不是每次修改的必跑清单。

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/dev_hot_reload_window.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/dev_hot_reload.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/trigger_hot_reload.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/capture_dev_window.ps1
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
flutter test
flutter analyze
flutter build windows --release
```

Windows 桌面热重载优先使用 `scripts/dev_hot_reload_window.ps1`，它会打开独立 PowerShell 窗口并调用 `scripts/dev_hot_reload.ps1`。后者会先运行 `build_runner`，再进入 `flutter run -d windows`，之后可在该窗口按 `r` 热重载、`R` 热重启、`q` 退出。已有该开发会话时，代码修改并完成最小验证后应自动运行 `scripts/trigger_hot_reload.ps1`；该脚本直接向现有 Flutter 控制台发送热重载，不启动第二个 `flutter attach`，需要完整状态重置时传入 `-Restart`。桌面 UI 改动可用 `scripts/capture_dev_window.ps1` 截取实际 Debug 窗口，默认输出到 `tool/.tmp/nai_launcher_window.png`；截图验证完需删除临时图片。依赖变更后运行 `flutter pub get`。新增或修改 Riverpod providers、Freezed models、JSON models、Hive adapters 或生成路由后运行 `build_runner`。

## 代码风格与命名约定

遵循 `analysis_options.yaml` 和 Dart 默认格式化规则，使用两个空格缩进。变量和方法使用 `lowerCamelCase`，类型使用 `UpperCamelCase`。Riverpod provider 命名应以 `Provider` 或 `NotifierProvider` 结尾。新增功能优先复用现有 service、provider、widget 和 utility，保持 `core`、`data`、`presentation` 的职责边界清晰。

## 测试规范

测试使用 `flutter_test`，需要 mock 时使用 `mocktail`。测试文件以 `_test.dart` 结尾，并放在对应功能路径下，例如 `test/core/utils/`、`test/data/services/`、`test/presentation/providers/`。UI 行为、状态管理、请求构造和文件处理的变更，按实际风险选择 widget、provider 或 service 回归覆盖。仅文档修改不运行 Flutter 测试或构建。

## 资源、生成文件与发布注意事项

`assets/databases/*.db` 通过 Git LFS 管理，发布前应确认本地文件是真实 SQLite 数据库而不是 LFS pointer。`assets/translations/`、`assets/data/` 和 `assets/images/` 会随 Flutter assets 打包，移动或重命名后需要同步检查 `pubspec.yaml`。发布前确认 `CHANGELOG.md`、`dist/release_notes_<tag>.md`、`pubspec.yaml` 版本号和 Windows release build。

### Windows 品牌图标

方形应用图标的母版是 `assets/icons/wof_icon.svg`：纯蓝底、完整白色 W，与标题栏的完整 `assets/images/wof_logo_block.png` 分开维护。不要从完整 Logo 裁切应用图标。

使用 Node.js 和 `sharp` 运行 `node tool/branding/generate_windows_icons.cjs`，同步导出程序资源 `windows/runner/resources/app_icon.ico` 与 Windows 托盘资源 `assets/icons/app_icon.ico`。ICO 内嵌 16、20、24、32、40、48、64、96、128、256px，共十档。可追加 `--brand-dir <目录>` 导出 SVG、1024px PNG、多尺寸 PNG 和 ICO 到品牌资产库。

ICO 属于原生程序资源；更新后必须重新构建 Windows 程序才能改变 EXE 自身的图标，仅 Flutter 热重载不会更新。macOS 和移动端的图标资源独立维护。

### Studio 字体与界面图标

显示名为 `W.O.F NAI Studio`；数据目录、单实例标识、可执行文件名和更新仓库保持既有标识。界面字族使用随包提供的 Geist Sans / Mono / Pixel Line 与 HarmonyOS Sans SC，字体角色、图标语义映射、许可和实绘验证见 [tool/branding/README.md](tool/branding/README.md)。新 UI 使用 `StudioIcon` 和 `StudioTypography`；没有语义准确的 Geist 替代时保留原图，不随意替换专用符号。字体、SVG、许可或原生显示名变更后需交付包含新资源的完整运行包。

## Changelog 与 Release Notes 规范

`CHANGELOG.md` 是 GitHub Release notes 的“更新内容”来源；Release workflow 不会自动根据 git commit 生成变更摘要。准备发布前必须对比上一个 tag 到当前 HEAD 的提交，把本版本用户可见变化整理进对应版本段落，例如 `## [1.0.0] - YYYY-MM-DD`。

Changelog 条目应面向用户描述结果，不要只写内部实现名。常用分类为 `### ✨ 新增`、`### 🛠 改进`、`### 🐛 修复`，必要时才增加 `### ⚠️ 注意`。不要在 `CHANGELOG.md` 中写发布文件列表；安装版、便携版、macOS 包说明由 `scripts/generate_release_metadata.ps1` 自动生成，避免 Release notes 重复。

准备发布时需要检查：

- 当前版本段落是否覆盖登录、更新、生成、设置、启动、安装包等用户实际能感知到的变化。
- bug 修复是否写成用户看到的问题和结果，例如“修复 Token 登录后无法获取会员状态”，而不是只写接口名或类名。
- 新功能开发期间顺手修掉的问题，如果用户从未用过损坏版本，可以合并进新功能描述，不必拆成多条。
- `CHANGELOG.md` 中不要重复自动生成的下载文件表；Release 页面会自动附带文件说明、校验文件和更新内容。

## README 双语同步规范

`README.md`（简体中文）与 `README.en-US.md`（English）内容必须保持同步：新增功能、平台支持、构建步骤、发布流程、项目结构等任一变化涉及 README 时，两份文件在同一提交中一起更新，不允许只改一份。两份文件顶部均保留指向对方的语言切换链接。仓库约定（如提交消息格式）以中文版表述为准，英文版只做翻译说明，不得改写约定本身。

## 提交与 Pull Request 规范

Git 历史使用 Conventional Commits，例如 `fix(generation): cancel stale results`、`feat(prompt): add random mode`。提交应保持范围清晰、标题简洁。Pull Request 需要说明用户可见变化，列出已运行的验证命令，标注生成文件、LFS 资源或 assets 变更；涉及界面变化时附截图。

# 开发与发布参考

按任务读取对应章节。命令在当前有效启动器源码目录执行，不从桌面包所在的旧源码分支施工；本机路径与当前交付见工作区接手说明。通用约束见 [AGENTS.md](AGENTS.md)，功能不变量见 [OPERATIONAL_NOTES.md](OPERATIONAL_NOTES.md)。

## 构建、测试与开发命令

当前整合分支使用登记的 `E:/A.I/NovelAI/.devin/sdk/flutter-3.47.7/`（Flutter 3.47.7 / Dart 3.13.5），最低约束以 `pubspec.yaml` 为准。PATH / `C:/flutter` 上旧 3.44.2 不作为本分支验证入口，执行前核对 `flutter --version`。Shell 使用 Bash，原生 `.ps1` 使用 PowerShell 执行。以下按实际修改选用，不是每次必跑清单：

```bash
studio_sdk="E:/A.I/NovelAI/.devin/sdk/flutter-3.47.7"
export PATH="$studio_sdk/bin:$PATH"
flutter --version
flutter pub get
dart run tool/generate.dart
flutter gen-l10n
flutter test test/core/utils/justified_layout_test.dart
flutter analyze
flutter build windows --release --no-tree-shake-icons
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/validate_windows_data_identity.ps1
```

依赖改变后 `pub get`；Riverpod、Freezed、JSON、Hive 或路由生成输入改变后运行 `dart run tool/generate.dart`；该入口读取 `.devin/codegen.json`，定向生成并备份 / 恢复原有未提交生成文件，不能用宽范围 `build_runner --delete-conflicting-outputs` 覆盖它们。界面文案进入各语言 ARB，再运行本节下方的繁体生成与 `gen-l10n`。纯文档或纯注释维护不运行 Flutter 测试 / 构建，也不调用桥接写参、模型或生图接口。

只有需要并获准建立独立开发会话时，才使用 `scripts/dev_hot_reload_window.ps1` / `scripts/dev_hot_reload.ps1`；已有同一开发会话时用 `scripts/trigger_hot_reload.ps1`，状态重置用 `-Restart`，不另开第二个 attach。`capture_dev_window.ps1` 捕获该 Debug 开发窗口，不能把它当当前安装包。用户自行实机核验时只交付，不自动热重载、重启或操作其运行实例。

### NAI Agent 紧凑面板验证

功能工作树的紧凑面板使用独立固定的 Flutter 3.47.7 / Dart 3.13.5 SDK 验证，不自动替换全局 SDK 或安装包。PowerShell 调用 `flutter_studio.ps1` 必须显式传 `-SdkRoot`、`-FlutterArgs`；否则位置参数 `test` 会被误当作 SDK 目录。

```powershell
$sdk = (Resolve-Path '../../sdk/flutter-3.47.7').Path
./scripts/flutter_studio.ps1 -SdkRoot $sdk -FlutterArgs @('test', '--no-pub', 'test/core/nai_agent', 'test/presentation/providers/nai_agent', 'test/presentation/widgets/nai_agent', 'test/l10n/zh_tw_resources_test.dart')
./scripts/flutter_studio.ps1 -SdkRoot $sdk -FlutterArgs @('analyze', '--no-pub', 'lib/presentation/widgets/nai_agent', 'lib/presentation/providers/nai_agent')
```

Pi 本地回归在 `tool/nai_agent/` 执行 `npm test`，使用本地合成服务，不请求真实模型或 NAI。`NAI_AGENT_COMPOSER_CAPTURES` 指定 widget 实绘输出目录；紧凑面板测试覆盖五种语言、320/380/460px、深浅色及六种状态。运行中状态有持续进度动画，使用定时 `pump` 而非 `pumpAndSettle`。截图仅作组件／合成数据证据，不代表已安装版本。

## 当前 Glass 包交付

本机桌面实际使用 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/`，不是标准 Release 或 Debug 目录。完整交付状态以该源码根 `.dart_tool/glass-rollout-delivery.json` 与安装文件为准；当前有效源码位置从工作区接手说明读取。

本机累计更新的交付材料按批次放在有效源码 `.dart_tool/cumulative-r<N>-<日期>/`（最近一批见工作区接手说明登记），复用上一批的 `snapshot` → `run_build` → `prepare` → `verify_package` → `install` → `finalize` 链；r26 起安装器支持带备份的退役文件删除，`tools/nai-agent` 按源码整树同步。历史 Glass 组包曾使用 `.dart_tool/assemble_glass.py` / `build/glass-bundle/`；这些不是当前批次固定入口，后续使用当次登记的构建输入与组包脚本。先完成按范围测试、analyze、资源与原生数据身份核验，再使用本次交付的安装脚本；本机脚本是交付材料，不假设所有 clone 都带有 `.dart_tool/`。

覆盖前现场检查 `nai_launcher` 进程路径，等用户从托盘完全退出，备份当前程序 `data/` 与记录；安装后逐项复验并保存单步回退，不自动启动。不要用标准 `build/windows/x64/runner/Release/` 整目录覆盖既有 Glass 包，尤其不能移除其原生插件。Release 发布流程另按下方规范执行。

## 代码风格与输入组件

遵循 `analysis_options.yaml` 和 Dart formatter；复用 core / data / presentation 现有 service、provider 和 widget。生成工具的语法支持以锁定依赖和实际诊断为准，不根据旧 SDK 记录推定能力。

可写标签框复用 `TagExpansionWrapper`：Ctrl+单击 / Ctrl+拖选显式查标签，按原输入框语义提交；普通输入不弹旧补全。空格查询设置 `splitOnSpaces: true`。本地图库、在线 AI TAG 搜索、块管理、黑名单与批量元数据框沿用各自提交路径。中文输入不再依赖已退役的 ffdkj 词库。

## 测试规范

使用 `flutter_test` / `mocktail`，测试放在对应 `test/` 路径。选择实际影响的 service、provider、widget 与布局路径；必要时扩大范围，全量结果记录实际通过 / 跳过 / 失败，不引用旧数字冒充新验证。界面检查使用 `test/helpers/studio_capture_fonts.dart` 的真实字体，覆盖涉及语言、主题、宽窄和字号；临时存储 / 合成数据不读取用户账号、数据库或提示词。

日志测试使用 `test/helpers/app_logger_test_isolation.dart` 隔离输出，避免并发套件互相污染。可用测试与采集入口见 [test/README.md](test/README.md)。交付记录、历史报告和用户验收是不同证据；widget 实绘不能写成运行中用户窗口截图。

## 资源与国际化

界面支持 `zh`、`zh-TW`、`en`、`ja`、`ko`。英文 ARB 是模板，简中 / 日文 / 韩文手工维护；台湾正体 ARB 与 `zh_tw_labels.dart` 由 `tool/l10n` 使用 OpenCC 1.4.2 `s2twp` 与产品术语生成，不手改。更改简中 ARB、Wiki 目录、分组 / 分类中文名后：

```bash
UPDATE_ZH_TW=1 flutter test test/l10n/zh_tw_resources_test.dart
flutter gen-l10n
```

通用台湾用语写 `tool/l10n/zh_tw_terms.dart`，单条完整句子覆盖写 `tool/l10n/zh_tw_overrides.json`。有 context 使用 `context.l10n`，无 context 使用 `currentL10n`；不在代码内临时写中文或语言三元分支。

`assets/databases/*.db` 经 Git LFS 管理，发布前确认是真 SQLite 而非 pointer。CSV 建库源不随应用打包；`github_chening233.csv` 用于 `tag_wiki.db`，co-occurrence 独立构建器以来源 lock 为准。当前不分发 ffdkj 中文词库与已删除的旧 translation.db 建库链，不能重新恢复旧预构建包。资源增删与 `pubspec.yaml`、许可、清单和本次交付必须一致。

### 小贴士与彩蛋

正文在 ARB 的 `tips_<位置>_<类型>_<序号>` / `genButton_<分档>_<序号>`；`tip_catalog.dart` 登记位置、guide / trick / wolf、short 与 night，生成按钮规则在 `generate_button_copy.dart`。四份手工 ARB同步维护，再生成台湾正体。

教程只写真实功能，`@description` 记录依赖；功能改名 / 删除时同步搜索。狼采用温和第一人称，英日韩按各自语言成文；欢迎页可成段，角色提示最多三行，搜索和生成占位只一行。报错、扣费、删除和设置说明不加梗，避免 NSFW、真实画师与催消费内容。布局检查见 `test/presentation/tips/tip_layout_test.dart`，`CAPTURE_TIPS=1` 可保存部件实绘。

## 字体、图标与窗口身份

默认正文 HarmonyOS Sans SC，等宽参数 Geist Mono，韩文回退 Pretendard；用户选字族保持有效。主界面固定 100%，设置页及其弹窗共用独立 1.1 基准，不能重复缩放。功能入口使用 StudioIcons，常规操作使用 Material；画廊火车流图标保留 `view_day_outlined`，网格 / 瀑布流为细线字形。母版、生成器、字位和字体许可见 [品牌文档](tool/branding/README.md)。

独立品牌标题栏已经移除。页面内容直达顶边，窗口按钮由各路由页面绘制，Navigator 浮层在按钮上方；主工作区只有明确空白区可拖窗，登录 / 载入保留自己的原生命中区，原生 Acrylic 当前禁用。

桌面 / Explorer 用完整长方形 Logo，窗口 / 任务栏 / 托盘用方形 W；`generate_windows_icons.cjs` 生成两套 ICO，原生图标修改需重编 Windows runner。原生 `CompanyName=com.example`、`ProductName=nai_launcher`、单实例身份和可执行文件名保持稳定，品牌显示名写 FileDescription / 窗口标题。Windows 内部数据统一放 EXE 旁 `user-data/`，原生版本身份只用于识别历史 AppData 目录并保留迁移兼容。迁移在数据库打开前创建独立备份、校验并切换，不能覆盖两端不同数据；打包拒绝含用户数据的运行目录，更新／卸载保留 `user-data/`、Agent 数据和迁移备份。

构建后运行 `scripts/validate_windows_data_identity.ps1`，可用 `-ExecutablePath` 核对指定包。其检查只读 EXE；打包脚本也执行。字体、SVG / 图标字体、许可或资源清单变更须随完整资源交付，不只换 AOT。

## Changelog、README 与发布

`CHANGELOG.md` 记录用户可见结果；当前开发变化放 Unreleased，真正发布时核对上一 tag 至当前代码、版本号、LFS、Windows 构建、release notes 和资产清单，再整理对应版本段落。交付到本机和发布 GitHub Release 是不同状态，不能把本地安装当新 Release 已发布。

README 中英文同批同步，保留相互切换和上游归属链接。截图须说明是否为历史界面或合成数据的部件实绘，不能把旧图包装成当前窗口。保留原创项目归属、许可和本分支更新仓库；观察上游后自主实现需要的变化，不 merge / cherry-pick 上游。

提交采用 Conventional Commits，限定改动范围。PR 描述面向未看过聊天的读者，说明实际结果、验证、资源 / 生成文件和界面证据；不提交账号、API Key、本机运行日志、构建产物或私有工作流。

本地高级放大宿主构建入口为 `tool/local_upscale/build_worker.ps1`；源码、组件固定版本与用户暂缓大模型下载的边界见 `docs/advanced-upscale-2026-10-05.md`。

## NAI Agent 当前交付

10-30 新增五项浏览与统计优化已完成源码及范围验证，尚未构建／安装；当前桌面仍为下述 +65。新增范围为会话活动排序、存储统计缓存、最近浏览、删除池共用画廊和紧凑排序菜单，详见 [本批记录](docs/usage-polish-2026-10-30.md)。

本机 2.2.2+65（编译 `2d1453213`）已累计安装完整 Agent 域工具、MCP／CodeMode、Node 24.18.0／Pi 1.3.0、Skill 管理、框内块／翻译快捷操作及流式性能优化；角色元数据、桥接依赖提示与保存提示条对齐同批交付。[本机交付](docs/local-2.2.2-build65-2026-10-30.md)。公开 [2.2.2+64](docs/release-2.2.2-2026-10-29.md) 已包含本机 +62／+63 全部六项更新，本机 +65 已另行安装图库首次 Ctrl 多选修复，Shift 范围和其余 UI 保持。当前安装与恢复入口见 [工作区接手说明](../../../04_工具/启动器接手说明.md)，实机验收见 [Agent 进度](../../../04_工具/NAI_Agent_开发/06_实施进度.md)。E5D 文件管理与扫描互斥已累计包含，[历史报告](docs/nai-agent-stage-e5d-2026-10-07.md) 不作为未完成项。

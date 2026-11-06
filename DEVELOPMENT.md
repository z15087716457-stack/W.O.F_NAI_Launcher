# 开发与发布参考

本机版本、实际载荷、有效源码与恢复边界统一见[工作区接手说明](../../../04_工具/启动器接手说明.md)。公开功能及产物验证见 [2.3.0 发布核验](docs/release-2.3.0-2026-11-06.md)。用户完成应用内更新后的运行状态另行核对，历史直装收据不自动代表当前安装。

命令在当前有效源码执行。通用约束见 [AGENTS.md](AGENTS.md)，功能不变量见 [OPERATIONAL_NOTES.md](OPERATIONAL_NOTES.md)，当前待修与暂缓项见[活跃待办](../../../04_工具/开发计划/待办清单.md)。

## 构建、测试与开发命令

当前整合分支使用登记的 `E:/A.I/NovelAI/.devin/sdk/flutter-3.47.7/`（Flutter 3.47.7 / Dart 3.13.5），最低约束以 `pubspec.yaml` 为准。执行前核对登记 SDK，不使用 PATH 中的旧版。Shell 优先 Bash；使用 PowerShell 且输出含中文时设 UTF-8，原生 `.ps1` 用 PowerShell 执行。以下按实际修改选用，不是每次必跑清单：

```bash
studio_sdk="/e/A.I/NovelAI/.devin/sdk/flutter-3.47.7"
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

Agent 依赖变化还须覆盖分发入口：`python -m unittest discover -s test/scripts -p windows_release_payload_test.py` 验证版本预检和包信息；Pi 组件版本从锁文件核对，发布元数据读取实际包内版本，不另留版本常量。

### macOS 通用包

通用包在配有 Rosetta 的 Apple 芯片 Mac 上构建，需要登记的 Flutter SDK、Xcode、CocoaPods、Git LFS 和 Rust 的 `aarch64-apple-darwin`、`x86_64-apple-darwin` 目标。产物最低支持 macOS 13.5。

```bash
flutter pub get --enforce-lockfile
bash scripts/build_macos.sh --release
bash scripts/package_macos_release.sh
```

`macos-build.yml` 在 `main` 或 `codex/macos-ci` 收到构建输入变更时自动构建，通用包与校验文件从 Actions 的 `macos-release-assets` 下载。发布工作流通过手动 `include_macos` 纳入 Mac 资产。当前构建使用临时签名，对外分发前需确认 Developer ID 签名与公证方案。

## 当前 Glass 包交付

本机桌面实际使用 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/`，不是标准 Release 或 Debug 目录。完整交付状态以该源码根 `.dart_tool/glass-rollout-delivery.json` 与安装文件为准；当前有效源码位置从工作区接手说明读取。

每批交付从接手说明读取当前脚本与收据，重新冻结本次输入、核对真实安装基线，再执行构建、组包、安装与核验。可以复用上一批脚本，不能重跑旧批次的载荷或版本常量。安装器沿用已有备份、失败恢复与退役文件删除；Agent 运行资源变化时，`tools/nai-agent` 按源码整树同步。本机交付脚本不作为所有 clone 的前置依赖。

仅 Dart 代码／文案变化，且原生依赖、Agent、RAG 与资源未变时，沿用完整收据构造差量载荷，不复制完整 `program/`。重编 Release 并核对源码、资源和原生库哈希；源码与产物均未变的模块复用原验证，不重复跑无关的 Node／RAG 冒烟。差量 `prepare.py` 已包含包核验，流程为 `snapshot` → `run_build` → `prepare` → `install` → `finalize`；原生、资源或运行依赖变化时，按实际影响组包和验证。正式分发包仍走发布流程。

覆盖前现场检查 `nai_launcher` 进程路径，等用户从托盘完全退出，备份当前程序 `data/` 与记录；安装后逐项复验并保存单步回退，不自动启动。不要用标准 `build/windows/x64/runner/Release/` 整目录覆盖既有 Glass 包，尤其不能移除其原生插件。Release 发布流程另按下方规范执行。

安装和回退核验通过后，通常按当批清单清理已用 `payload` 与空暂存目录，保留 `rollback`、当前编译缓存和核验记录。当前本机安装暂存清理已有自动审批拦截并暂停的记录，适用[接手说明](../../../04_工具/启动器接手说明.md)的具体边界，不据本节重试或改道清理。其他获准清理前仍核对绝对路径、清单和当前用途，不把回退材料当作暂存删除。

## 代码风格与输入组件

遵循 `analysis_options.yaml` 和 Dart formatter；复用 core / data / presentation 现有 service、provider 和 widget。生成工具的语法支持以锁定依赖和实际诊断为准，不根据旧 SDK 记录推定能力。

可写标签框复用 `TagExpansionWrapper`：Ctrl+单击 / Ctrl+拖选显式查标签，按原输入框语义提交；普通输入不弹旧补全。空格查询设置 `splitOnSpaces: true`。本地图库、在线 AI TAG 搜索、块管理、黑名单与批量元数据框沿用各自提交路径。中文输入不再依赖已退役的 ffdkj 词库。

## 测试规范

使用 `flutter_test` / `mocktail`，测试放在对应 `test/` 路径。按实际依赖覆盖 service、provider、widget 与布局；公共契约变化要包含调用方，不以单一目录划死范围，也不一律运行全量。新失败、共享影响或未解决的问题支持扩大范围时再扩测；源码哈希一致的既有验证注明复用，不冒称重跑。界面检查使用 `test/helpers/studio_capture_fonts.dart` 的真实字体，覆盖涉及语言、主题、宽窄和字号；临时存储 / 合成数据不读取用户账号、数据库或提示词。

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

## NAI Agent 当前能力

Agent、MCP／CodeMode、Skill 管理、提示词框内块操作、完整历史与检索等已交付能力及验证统一见[Agent 进度](../../../04_工具/NAI_Agent_开发/06_实施进度.md)。运行时说明读取 `tool/nai_agent/skills/`，详细流程按需读取 `references/`。

工作区收纳与迁移见[布局说明](docs/agent-workspace-layout-2026-10-31.md)，Skill／声明精简见[实现记录](docs/agent-skill-declaration-polish-2026-10-31.md)。现行待修与实机反馈按工作区入口维护；带日期的交付报告保留当时的安装、测试与恢复边界。

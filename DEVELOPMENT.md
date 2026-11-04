# 开发与发布参考

本机版本、实际载荷、有效源码与恢复边界统一见[工作区接手说明](../../../04_工具/启动器接手说明.md)。公开功能及产物验证见 [2.2.6 发布报告](docs/release-2.2.6-2026-11-04.md)。用户完成应用内更新后的运行状态另行核对，历史直装收据不自动代表当前安装。

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

## macOS 构建、测试与发布

GitHub Actions 的 runner、签名和产物交付见 [macOS Actions](docs/macos-actions.md)。PR 与 Release 共用 `macos-build.yml`，固定 ad-hoc 签名，不需要 Apple 证书或 secret；Mac 专属 Dart 回归清单在 `scripts/test_macos.sh`，真实应用宿主的 XCTest 通过 `scripts/test_macos_native.sh` 运行。Node 归档中的 npm/npx 也随包复制，Agent 子进程将包内工具目录放到 PATH 前面，兼容访达启动；Git 来源的扩展仍需要系统 Git。

工具：完整 Xcode（`scripts/build_macos.sh` 默认用 `/Applications/Xcode.app`，不改 `xcode-select`，别的位置用 `DEVELOPER_DIR`）、CocoaPods、rustup（`super_native_extensions` 用 cargokit 编 Rust；Homebrew 的 rustup 不进 PATH，脚本会补上）、Flutter 3.47.7（`FLUTTER_ROOT` 指向登记的 SDK，或放在 PATH 上）。应用主体的部署目标为 macOS 12，随包 Node 所需的最低系统版本为 macOS 13.5，bundle id `com.wof.naiStudio`；设置、数据库和 Agent 数据在「应用支持」目录（`~/Library/Application Support/com.wof.naiStudio/`），Agent 运行时和 `studio-bridge` 放在 `Contents/Resources/tools`，不往应用包里写（见 `lib/core/utils/app_bundle_paths.dart`）。

```bash
scripts/build_macos.sh                       # debug，本机架构
scripts/build_macos.sh tools <应用包>         # flutter run 之后补进 Node、Pi、studio-bridge 和放大引擎
scripts/build_macos.sh --release             # 通用应用包（arm64 + x86_64）
scripts/package_macos_release.sh [--version <版本>] [--dist-dir <目录>]
```

- Node 和 Windows 包同一版本（v24.18.0），官方 darwin-arm64 / darwin-x64 两个包校验后用 `lipo` 合成；Pi 依赖用同版本的 npm 执行 `npm ci`。下载缓存在 `build/macos-runtime-cache/`。
- `--release` 的 `studio-bridge` 也是通用二进制：Intel 那一份用官方 macOS x64 Dart SDK（版本同 Flutter 自带的 Dart，校验 `.sha256sum`）在 Rosetta 下编，所以发布构建要在装了 Rosetta 的 Apple 芯片 Mac 上做（`softwareupdate --install-rosetta`）。没有 Rosetta 时只编本机架构并给出警告，打包脚本默认拒收；只给自己用的本地包可以设 `ALLOW_HOST_ONLY_BRIDGE=1`。
- 本地放大：Real-ESRGAN NCNN/Vulkan 用官方 v0.2.0 Release 里的 macOS 包（`realesrgan-ncnn-vulkan-v0.2.0-macos.zip`，和 Windows 包出自同一个 Release、同一份源码 37026f4）。它本身就是 arm64 + x86_64 的通用二进制，静态链接 MoltenVK 1.1.1（走 Metal）和 LLVM OpenMP，只依赖系统框架。`build_macos.sh` 按固定的 sha256 校验 zip 和程序，连同上游 LICENSE 和 `tool/local_upscale/macos/` 里 MoltenVK、cereal、LLVM OpenMP 的许可放进 `Contents/Resources/tools/local-upscale/`，签名后再重签整个包；固定的版本和 `assets/local_upscale/manifest.json` 的 `engine_version` 对不上时构建直接失败。模型照旧从 flutter_assets 释放到「应用支持」目录，下载的可选模型也和 Windows 共用同一个官方模型包。Mac 上不用 `studio_upscale_worker`：它只给 SeedVR2 / RTX 组件管进程（Windows Job Object）和调 RTX Video SDK（Direct3D 11），常规放大在 Windows 上也是直接启动引擎。真机审计：`RUN_LOCAL_UPSCALE_AUDIT=1 LOCAL_UPSCALE_MAC_TOOLS=<应用包>/Contents/Resources/tools flutter test test/data/services/local_upscale_service_test.dart`。设置页“本地放大”的显卡卡片在 Apple 芯片上显示芯片名（`sysctl -n machdep.cpu.brand_string`，如 Apple M2 Max，不带显存）；Intel Mac 那里读到的是 CPU，和读不到时一样，仍写“没有检测到独立显卡”。
- `package_macos_release.sh` 先把应用包复制到 `build/release-stage/`（不改 Flutter 产物），由 `scripts/macos_release_payload.py` 检查：Release 构建、`Info.plist` 版本号和 `--version` 一致、没有开发机上的用户数据（`user-data`、`agent-data`、`.runs` 等）和指向包外的符号链接、数据库是真 SQLite 而不是 LFS 指针、锁文件中的 Pi 版本 / Node v24.18.0、放大引擎和许可在 `tools/local-upscale` 而 flutter_assets 里没有 Windows 放大程序、每个 Mach-O 都有 arm64 和 x86_64。然后写 `Contents/Resources/package-info.json`（`platform: macos-universal`）和许可文件，重签，用 `ditto -c -k --keepParent --norsrc` 打成 `WOF_NAI_Studio_macOS_<版本>_Portable.zip` 和 `.sha256`，最后解压一遍核对签名和符号链接。`--norsrc` 不能省：系统给每个文件打的 `com.apple.provenance` 会在 zip 里变成上万个 `._` 文件，用别的工具解压时落进应用包，签名一坏，系统就说应用“已损坏”。
- 签名：没有证书时用 ad-hoc，用户第一次打开会被 Gatekeeper 拦，打开方法写在 README。有 Developer ID 证书时，两个脚本都用 `CODESIGN_IDENTITY` 指定；要公证还得加 hardened runtime（Node 需要 JIT 相关的 entitlements）、时间戳和 `notarytool`，目前没做。
- 应用内更新：Mac 包和 Windows 一样下载、校验大小和 SHA-256，然后解压到更新目录、在访达中选中新版本，由用户退出后拖进「应用程序」替换；不在退出后自动覆盖（ad-hoc 包静默替换既要「应用程序」的写权限，也绕过了用户确认）。从安装位置运行新版本后清理更新包和解压目录。在临时目录直接打开时，应用保留这两处文件，并提示移动到「应用程序」。
- RAG：Apple 芯片的 Mac 上可用。运行时和 Windows 一样在应用内安装到「应用支持」的 `rag/v1/`：固定版本的 uv 0.13.1（`uv-aarch64-apple-darwin.tar.gz`，sha256 写在 `rag_runtime.dart`）建 Python 3.12.11 venv（`runtime/bin/python3`），PyTorch 2.10.0 / torchvision 0.25.0 取自 PyPI（Mac 版自带 MPS），其余依赖同 `tool/rag/requirements.txt`。没有 CUDA；设备“自动”在内存 18 GB 及以上的 Mac 上走 MPS，16 GB 及以下或读不到内存（`hw.memsize`）时走 CPU，规则只在 `RagSettings.deviceOn`，平台和内存都能注入；手动选的设备照旧。MPS 仍是 fp32，向量和排序与 CPU 一致。Intel Mac 不支持（PyTorch 2.3 起没有 macOS x86_64 的包），界面显示“不支持”、安装按钮置灰。平台判断在 `rag_platform.dart`，服务和 `ragPlatformProvider` 都能注入。
- RAG 进程宿主：`tool/rag/stdio_host.cpp` 的 macOS 实现用进程组代替 Job Object：子进程在执行前进新进程组；子进程退出、应用（argv[1]）退出或宿主收到 SIGTERM / SIGINT / SIGHUP 时整组 SIGKILL，宿主再以同一信号退出。`build_macos.sh` 的 `bundle_rag_host` 用 clang 直接编通用二进制（不需要 Rosetta）放进 `Contents/Resources/tools/rag-stdio-host` 并签名，同时在签名前从 flutter_assets 删掉 `assets/rag/windows/`、重签 App.framework；`macos_release_payload.py` 检查这两点。应用包里没有宿主（如直接 `flutter run`）时子进程直接启动，只能靠 stdin 关闭退出。宿主测试：`RAG_TEST_HOST=<编出的宿主> python3 -m unittest discover -s tool/rag -p test_host.py`。
- 资源小窗：Windows 用 `desktop_multi_window` 开独立的原生子窗口（`windows/runner/resource_window.cpp`）；macOS 上 `nativeResourceWindowsProvider` 为 false，资源小窗开成主窗口里的浮动面板（`FloatingResourceWindowsHost`），不建子窗口，也不调 `com.nailauncher/resource_window_native` 通道（关主窗口时同样不调 `closeAll`，Mac 上那个通道没有实现）。`desktop_multi_window` 自带 macOS 实现，会随包编译、注册到主窗口，但 Mac 上没有代码调用它。
- 只有 Windows 版的功能：本地放大的 SeedVR2 和 RTX Video 组件（要 CUDA、RTX Video SDK 和 Direct3D 11，界面上写明“目前只支持 Windows”，安装按钮不可点）。`assets/local_upscale/windows/`（Windows 引擎、worker、vcomp140.dll）在 `build_macos.sh` 签名前从 flutter_assets 里剔掉，Mac 的代码路径不读它们。
- 沙箱（`NAI_STUDIO_SANDBOX` 设成一个绝对路径）：Mac 上同样只用沙箱里的 `user-data/`、`documents/` 和 `user-data/temp/`，偏好写在沙箱的 `shared_preferences.json`，登录凭据只放内存，不写正式的凭据目录，窗口标题带 `[sandbox]`，也不做 1.x 旧数据的首启复制。Windows 原生层按沙箱区分单实例和唤醒消息。Mac 在迁移、同步和开库前锁定当前资料目录。单独运行另一个沙箱时直接启动可执行文件，例如 `NAI_STUDIO_SANDBOX="$(mktemp -d)" "build/macos/Build/Products/Debug/W.O.F NAI Studio.app/Contents/MacOS/W.O.F NAI Studio"`。值不是绝对路径时和 Windows 一样直接退出、不碰数据。核对：`NAI_STUDIO_SANDBOX=<绝对路径> flutter test test/core/utils/studio_sandbox_test.dart`。
- 测试：在 Mac 上跑 `flutter test` 时，一批按 Windows 窗口写的组件测试（集成标题栏、页头拖动、窗口外框等）本来就不过，结果以 Windows CI 为准，比对时看有没有新增失败。测平台分支用 `debugDefaultTargetPlatformOverride` 或给服务注入平台，不依赖跑测试的机器。
- 发布：`Release` 的 `build-macos` 与 PR 校验的 `macos-validation` 共用 `.github/workflows/macos-build.yml`，在 `macos-15` 构建和打包。PR 上传 Actions 产物供核对；Release 的 Mac 包和 Windows 包发布到同一个 Release，`generate_release_metadata.ps1` 将 Mac 包登记到 `release_manifest.json`（`type: macos-portable`），供应用内更新选择。Mac 回归清单统一在 `scripts/test_macos.sh`，其余全量测试仍由 Windows 任务执行；两种入口都采用 ad-hoc 签名，详见 `docs/macos-actions.md`。
- 首次启动复制旧版数据（`lib/core/services/mac_legacy_data_import.dart`）：来源默认是 bundle id `com.aaalice.naiLauncher`（W.O.F 1.x 和上游 NAI Launcher）。开发构建可以用 `--dart-define=MAC_LEGACY_BUNDLE_ID=<bundle id>` 指向别的应用，用 `--dart-define=MAC_LEGACY_APP_NAME=<程序坞里的名字>` 改提示里的名字；`MAC_LEGACY_BUNDLE_ID` 设为空就不复制。`flutter test` 下不运行，测试用临时目录注入新旧目录。

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

`CHANGELOG.md` 记录用户可见结果；当前开发变化放 Unreleased，真正发布时核对上一 tag 至当前代码、版本号、LFS、Windows 和 macOS 构建、release notes 和资产清单，再整理对应版本段落。交付到本机和发布 GitHub Release 是不同状态，不能把本地安装当新 Release 已发布。

README 中英文同批同步，保留相互切换和上游归属链接。截图须说明是否为历史界面或合成数据的部件实绘，不能把旧图包装成当前窗口。保留原创项目归属、许可和本分支更新仓库；观察上游后自主实现需要的变化，不 merge / cherry-pick 上游。

提交采用 Conventional Commits，限定改动范围。PR 描述面向未看过聊天的读者，说明实际结果、验证、资源 / 生成文件和界面证据；不提交账号、API Key、本机运行日志、构建产物或私有工作流。

本地高级放大宿主构建入口为 `tool/local_upscale/build_worker.ps1`；源码、组件固定版本与用户暂缓大模型下载的边界见 `docs/advanced-upscale-2026-10-05.md`。

## NAI Agent 当前能力

Agent、MCP／CodeMode、Skill 管理、提示词框内块操作、完整历史与检索等已交付能力及验证统一见[Agent 进度](../../../04_工具/NAI_Agent_开发/06_实施进度.md)。运行时说明读取 `tool/nai_agent/skills/`，详细流程按需读取 `references/`。

工作区收纳与迁移见[布局说明](docs/agent-workspace-layout-2026-10-31.md)，Skill／声明精简见[实现记录](docs/agent-skill-declaration-polish-2026-10-31.md)。现行待修与实机反馈按工作区入口维护；带日期的交付报告保留当时的安装、测试与恢复边界。

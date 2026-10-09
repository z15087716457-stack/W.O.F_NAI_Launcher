# Flutter 3.47.7 / Impeller 独立升级验证

2026-10-09，Asia/Taipei。用户授权升级验证，并另行安排 Opus 5.5 审查 UIUX 阶段 4；随后确认“仍在审查，先完成升级验证”。本轮完成独立 SDK、Windows 编译兼容检查、真实字体对照与候选包校验，运行包尚未安装。

## 结果

- 官方 Flutter 3.47.7 / Dart 3.13.5 已能正常运行。新 SDK 源码无本地修改。
- 固定源码快照的完整 Windows Release 构建成功，包括自研 runner、Pixel Snap 与原生插件。
- 83 项相关测试全部通过：Windows 单实例、原型字体配置、主题、颜色对比、输入框、大图查看器、时间线、本地图库多语言明暗布局及设置字体范围。
- 完整 analyze 为 0 个 error、17 条 warning / info，退出码 1，不能记作“分析通过”。同一代码在旧 SDK 有 2 条既有代码诊断；新版额外检出 12 条 `unawaited_return_in_try_block`、1 条 `unused_catch_stack`、2 条 `use_super_parameters`。本轮未改动这些业务代码。旧版对照只复制代码，缺少资源目录的诊断已单独排除，不冒充业务代码问题。
- 6 个独立 Windows Release 字体窗口完成首帧并捕获。3.47.7 / Skia 的明暗截图均与 3.44.2 / Skia 逐像素一致；显式启用 Impeller 后，浅色正文稍浓、深色正文比旧版更轻。没有出现浏览器 RGB 子像素边缘，不能认定升级即可完全对齐网页原型。

字体探针使用相同 Dart 文件和字体文件，13px 正文 / 1.45 行高、字距词距 0、均分 leading、400 / 500 / 600 / 700。覆盖 HarmonyOS Sans SC、Geist、Geist Mono、中文、英文数字、输入框、按钮与模糊材质。Windows 客户区 1084 × 741，DPR 1；显式使用 `DartProject.set_impeller_switch` 选择后端。截图来自实际 GPU 首帧，未用离屏 Canvas 或改字重模拟改善。

正文行归一化像素覆盖总量：浅色约 +3.5% ～ +6.3%，深色约 −11.2% ～ −16.5%。这是像素观察，不是字号或字体字重变化，也不单独代表视觉优劣。HarmonyOS 的 600 / 700 共用 Bold、Mono 的 500–700 共用 Medium 字形，与字体对齐提交 `09782439` 的原型规则一致。

## SDK 与使用入口

本机新 SDK：`E:/A.I/NovelAI/.devin/sdk/flutter-3.47.7`。现有 `C:/flutter` 3.44.2 / Dart 3.12.2 保留给正在进行的审查，未改系统 PATH。

- 官方 tag / framework：`abaf9c523780a608bd46686fd5e53740a07077f8`。
- engine：`deb287481e3ce9468f3434937ced4240a70539ca`。
- 官方 tag 源码与对应 Google Storage 引擎归档完成下载、ZIP CRC 和 SHA256 检查；下载记录保存在本机验证目录。首次工具快照初始化未退出，使用同一 SDK 自带 Dart 构建工具快照后，实际 `flutter --version`、编译、测试均正常。
- [版本登记](../tool/flutter-sdk.json) 固定 Flutter / framework / engine / Dart 四项身份。
- [执行入口](../scripts/flutter_studio.ps1) 核对实际 `--version --machine` 后转发参数；错误 SDK 会在执行工程命令前被拒绝。可用 `-SdkRoot` 或 `WOF_FLUTTER_SDK_ROOT` 指定 SDK。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter_studio.ps1 --version
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter_studio.ps1 pub get
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter_studio.ps1 test test/presentation/themes
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/flutter_studio.ps1 build windows --release
```

快照中因 SDK 固定依赖而更新的五项为 `intl 0.20.3`、`matcher 0.12.20`、`meta 1.19.0`、`test_api 0.7.12`、`vector_math 2.4.3`；没有批量升级第三方库。快照重新生成 527 个构建输出。主工作树的 `pubspec.yaml` / `pubspec.lock` 和业务文件未因本轮 SDK 验证改写；阶段 4 结束后的最终组包再应用相应 SDK 依赖。

## 本机证据与候选包

独立对照材料：`E:/A.I/NovelAI/04_工具/Flutter升级验证/2026-10-09/`。`index.html` 提供明暗切换、1× / 2× / 4×、同步滚动和可选新版 Skia。已实际打开并检查图像加载、切换、倍率与控制台；浏览器错误日志为空。

完整验证目录：有效源码的 `.dart_tool/impeller-upgrade-2026-10-09/`。

- `source-manifest.json`：`09782439` 基线、2254 个输入与哈希，包含当时已有的未提交 Agent 源码；隔离快照未复制账号、数据库状态、提示词或运行缓存。
- `source/`、`probe/`、`probe344/`：应用及字体探针。
- `source-build-347-final.log`、`source-tests-347.log`、`source-analyze-347.log`、`source-analyze-344.log`、`source-codegen-347.log`：实际验证记录。
- `results/`、`native-comparison.json`、`analyzer-comparison.json`：6 张原生截图、首帧收据、像素统计与诊断对比。
- `candidate/payload/`、`candidate/manifest.json`：245 个已校验程序文件；新 SDK 引擎 DLL 与对应 AOT、runner、插件配套。31 个现有原生文件均有候选对应项；保留新构建未包含的 emoji / permission / share 三个插件。现有 Agent / tools / WebView2 状态目录不在替换范围。
- `install_candidate.ps1`：默认 `Validate`，核验程序哈希、源码是否漂移、Studio 进程；`Install` 在退出与基线核对后建立完整程序备份并安装，失败自动恢复；`Rollback -BackupPath` 校验备份后回退。安装与回退路径尚未实际执行，不能记为已验证成功。

初次构建在 CMake 组包阶段失败：前一次中断配置留下默认 `C:/Program Files/nai_launcher` 安装前缀。现场确认未创建该目录；仅将隔离快照的 CMake 缓存前缀指定到自身 Release 目录，重新构建成功。没有修改工程 CMake 或写入安装目录。

## 后续交付边界

阶段 4 文件正在由审查方修改，候选基线已与当前源码不同。安装器会拒绝以该旧候选覆盖新审查结果。审查结束后，读取最终源码与审查记录，刷新快照、运行受影响检查、重建配套原生包并核对当前安装身份，再按 [DEVELOPMENT.md](../DEVELOPMENT.md) 的 Glass 交付流程安装；安装前确认 Studio 已从托盘完全退出。

本轮未推进 UIUX 阶段 5、未替换或启动 Studio、未写用户草稿或 Agent 私有状态、未调用真实模型 / NovelAI 接口。真实 Studio 的 Glass 材质与工作区交互留待最终包安装后由用户核验。

官方依据：[Windows Impeller](https://docs.flutter.dev/perf/impeller#windows)、[3.47 发布记录](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0)、[Gamma 修正](https://github.com/flutter/flutter/pull/187871)。字体观感结论以本机实测为准。

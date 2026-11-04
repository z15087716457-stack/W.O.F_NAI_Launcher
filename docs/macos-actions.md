# macOS 的 GitHub Actions 构建

PR 校验和 Release 都调用 `.github/workflows/macos-build.yml`，使用 GitHub 托管的 `macos-15`（Apple 芯片）runner。无需维护自托管 Mac，无需 Apple Developer 账号、证书或签名 secret。默认使用 runner 通过 xcode-select 选中的 Xcode，可通过仓库变量 `MACOS_XCODE_DEVELOPER_DIR` 覆盖。Flutter 版本读取 `tool/flutter-sdk.json`，Node 固定为与 Windows 包相同的 v24.18.0。

## PR 与发布

- PR 或手动运行 **Pull Request Validation**：运行 Mac 专属回归、静态分析、Agent 合成服务测试，再构建、打包；产物名 `macos-validation`，保留 14 天，可下载 ZIP 与 SHA-256。不会创建 Release。
- 推送版本 tag 或手动运行 **Release**：校验 tag 和 `pubspec.yaml` 版本一致，调用同一套 Mac 构建，产物名 `macos-release`。Windows 构建成功即可发布 Windows 成品。Mac 构建、原生 XCTest 及打包校验也成功时，同一 Release 加入 Mac 成品。被构建的 tag 必须已经包含 macOS 源码和脚本；旧的 Windows-only tag 不能补出 Mac 包。
- 失败时保留已产生的构建／打包日志 7 天。生成文件不一致、测试或分析失败、缺少 LFS 实体数据库、通用二进制缺架构、签名损坏都会阻止上传正式包。
- 来自 fork 的 PR 只需只读仓库权限，不使用 secrets，不使用 `pull_request_target`。首次外部贡献的 Actions 是否需要批准由仓库现有设置决定。

## Runner 做什么

1. 取得 LFS 资源，准备 Flutter、Node、Xcode、CocoaPods 和 Rust 双架构目标。
2. 只在 GitHub 的临时 VM 安装 Rosetta，使同版本 x64 Dart 能编译 Intel `studio-bridge`；不会修改贡献者自己的 Mac。
3. 生成业务代码，校验繁体资源并生成本地化，要求跟踪文件没有生成差异；执行 `dart analyze`。
4. 在正式应用的 Runner 测试宿主中运行 macOS XCTest，测试采用临时数据目录。
5. `scripts/test_macos.sh` 跑 Mac 平台和数据隔离回归；Python 测试 npm 打包与路径；Node 回归只用合成服务。
5. `scripts/build_macos.sh --release` 编译 universal app，加入 Node、npm/npx、Pi、Real-ESRGAN、RAG 宿主及 `studio-bridge`。Node 和 Dart 归档校验官方 SHA-256，Real-ESRGAN 校验固定 SHA-256。
6. `scripts/package_macos_release.sh` 在副本上排除私有数据，检查版本、LFS、资源许可、每个 Mach-O 的两种架构，并验证 npm/npx 在只有系统 PATH 时也能运行。生成 ZIP 后再次解压检查签名。

## 签名与兼容性

CI 明确使用 `CODESIGN_IDENTITY=-` 做 ad-hoc 临时签名，不执行证书导入或公证。包的完整性仍受 `codesign --verify --deep --strict` 检查。没有 Apple 公证意味着用户首次打开仍需按 README 的 Gatekeeper 步骤操作。

应用主体的部署目标为 macOS 12。完整 ZIP 需要 macOS 13.5 及以上，随包 Node v24.18.0 的 arm64 和 x86_64 二进制均以 13.5 为最低系统版本。Apple 芯片与 Intel 共用一个 ZIP。CI 的架构检查不等于 Intel 实机验收。RAG 只支持 Apple 芯片；SeedVR2、RTX Video 仍仅支持 Windows。Agent 的 npm/npx 随包提供，Git 来源的扩展仍要求系统 Git 可用。

## 维护依据

- [GitHub 托管 runner 标签与架构](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)：`macos-15` 为 arm64，`macos-15-intel` 为 Intel。
- [macOS 15 arm64 镜像的软件清单](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)：升级 Xcode 或 runner 时先核对工具可用性。
- [Flutter action 的版本与架构选项](https://github.com/subosito/flutter-action)：版本仍以项目登记为准，不自动追随最新 Flutter。

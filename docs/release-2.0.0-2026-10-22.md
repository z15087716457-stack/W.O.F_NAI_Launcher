# W.O.F NAI Studio 2.0.0 · Windows 正式版出包

日期：2026-10-22。显示版本 `2.0.0`，构建版本 `2.0.0+42`，渠道 stable，平台 Windows x64。本次仅本地构建与验证，**未发布 GitHub，未安装到正式运行目录，也未启动应用**。

## 流水线

入口为 `scripts/package_windows_release.ps1`；参数保留 `-Version`、`-SkipFlutterBuild`、`-DistDir`，新增 `-DisplayVersion`、`-NodeRuntimeDirectory`、`-CrtDirectory`。默认从 pubspec 取完整版本和去掉 `+build` 的显示版本。

```powershell
# 先确保 PATH 指向登记的 Flutter 3.47.7 / Dart 3.13.5。
# CI 负责依赖解析、业务代码生成和 Agent npm ci；本地复用已有生成文件。
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/package_windows_release.ps1 `
  -NodeRuntimeDirectory '<含 node.exe / NODE-LICENSE / PI-LICENSE 的目录>'
```

1. 预检 Agent 锁文件 packages 键集合、七个 Pi 包均为 1.3.0、无 chord、Node 为 v24.18.0；检查业务生成 part 存在。
2. 非跳过构建模式运行 NuGet 校验、`flutter gen-l10n`、`flutter build windows --release --no-pub --no-tree-shake-icons`。gen-l10n 没有 `--no-pub` 选项，且不会解析依赖。本机没有执行 pub get 或 build_runner。
3. 只读复制 Flutter Release 到独立 `build/release-stage/WOF_NAI_Studio_2.0.0/`，构建 standalone bridge，复制 git 跟踪的 Agent 非测试文件及完整 node_modules、Node 和许可。
4. Python stdlib helper 使用 Windows `\\?\` 长路径 IO；14,994 个 node_modules 文件复制前后数量相同，验收还逐文件核对 SHA-256。运行时源目录仅只读取得三个指定文件。
5. 自动选择最新 VS x64 CRT，根目录附带十个 DLL，源与暂存签名均为 Valid；已有同名文件不覆盖，记录哈希比较。本次十个均为新增且哈希相同。
6. 附带中英文 README、CHANGELOG、THIRD_PARTY_NOTICES 与 LICENSE.txt；写 package-info、应用文件清单及 SHA256SUMS。Release 或暂存目录发现私有数据、内部恢复材料时拒绝打包；已有暂存目录也先拒绝私有数据再清空。
7. 验证 `com.example/nai_launcher` 原生身份；Python zipfile 生成支持 ZIP64 的 Deflate ZIP，顶层固定 `WOF_NAI_Studio_2.0.0/`；NSIS 编译安装包；生成每个产物的 `.sha256` 和 `dist/checksums.txt`。

CI 中 `scripts/prepare_windows_node_runtime.ps1` 下载 Node 24.18.0 官方 win-x64 ZIP，对照官方 SHASUMS256 校验，用该运行时的 npm ci 安装 Agent，再准备 Node/Pi 许可并显式传入运行时目录。当前 pi-coding-agent 包没有 LICENSE，因此新增源码 `tool/nai_agent/PI-LICENSE`，内容只读复制自登记运行目录的 PI-LICENSE。两个工作流均已改新文件名与登记 SDK；2026-10-23 已在 GitHub runner 实跑通过。

## 正式发布（2026-10-23）

GitHub Release `v2.0.0` 由 `release.yml` 在 GitHub runner 上构建发布，tag 指向 `9032e904d`（在 `d55842ba9` 之后补了 1.x 升级修复，见下）。Release 资源即正式分发包：

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_Windows_2.0.0_Setup.exe` | 199823470 | `e9770276fa405b42998df9772f4771557869386d009d6a2435fac8e02905b73a` |
| `WOF_NAI_Studio_Windows_2.0.0_Portable.zip` | 322185425 | `cc0eb3e6e44fe907f58f88ab6f406c646574a412ced03f6fc23855c9bb0e2353` |

- CI 包 AOT `eefde9f10e6b0286e61c4f71a679a74ece684a15d1f9b6d9bf314524f7194356`，sourceCommit `9032e904d2aeb174cef5d9e64bd1331014dcfc4c`。
- 下载回本机复验：`checksums.txt` 两项一致；便携包按原脚本（去掉与本地暂存目录逐字节比较一项）通过 ZIP、清单、15299 条 SUMS、SQLite×4、Node v24.18.0、两项内置 Skill、Agent 合成冒烟与数据身份检查；与本地包相比只有原生二进制（runner 重新编译）和文本换行不同，无内容差异。Setup ProductVersion `2.0.0+42`，未签名。
- **1.x 升级修复（`9032e904d`）**：1.x 应用内更新只用 `/S` 静默运行安装包并重启旧 exe 路径。安装器 `.onInit` 在没有新键 InstallLocation、且未显式 `/D=` 时，沿用旧键 `Aaalice NAI Launcher` 的目录（目录内须有 exe），就地升级并迁移注册项。`.dart_tool/release-2.0.0/verify_legacy_upgrade.ps1` 四种场景通过：旧版就地升级、再次升级留原地、旧键指向不存在目录时装到新默认、显式 `/D=` 优先。
- 推送：本机代理单连接上传约 100 KB/s 且长连接会被重置，整推失败；按首父链切成每批约 20 MB 原始大小逐批推送（`.devin/runs/release-2.0.0/chunk_push.sh`）。本地旧的未推送 tag `v2.0.0`（指向 8 月旧提交）已改存为 `refs/backup/old-tag-v2.0.0`。
- 远程除 `main` 外 160 个分支已删除，备份见 `04_工具/发布包/github-branches-backup-20261022/`；tag 与 1.x Releases 保留。

以下“本地最终产物”与验证是发布前本机出包的记录。

## 本地最终产物

路径相对于源码根 `E:/A.I/NovelAI/.devin/wt/ui-integration/`。

| 产物 | 字节数 | SHA-256 |
|---|---:|---|
| `dist/WOF_NAI_Studio_Windows_2.0.0_Setup.exe` | 199975501 | `1e5cfa4cad3d31e1f1cb63815f68bdee7b94cb97d08b0f893f028636896c36b0` |
| `dist/WOF_NAI_Studio_Windows_2.0.0_Portable.zip` | 322315134 | `1dc8b89fe78b05021890aeae467549809d308e0fa5e94d9315c18189c6071734` |

程序载荷共 **15,300 文件 / 842,991,740 字节**。应用清单 15,298 条，另有清单自身和 SHA256SUMS；SUMS 有 15,299 条。ZIP 条目数 15,300；安装后为同一载荷加 `Uninstall.exe`（运行时可能额外生成诊断日志）。

- AOT SHA-256：`d1d3e39f4954fe2f5aaaacceaf3ab9f058aba16590b0fe9ccdb6de4a512a38e5`。
- sourceCommit：`d55842ba911b49e7afcafc8751b024738362f405`。最终包从该提交的干净工作树重新组装（`-SkipFlutterBuild`，复用同一 Release 构建，AOT 不变），之后重跑便携包、安装／升级／卸载和最终审计，全部通过。
- Flutter 3.47.7 / Dart 3.13.5 / Node v24.18.0 / Pi 1.3.0。

## 验证结果

本机审计证据在 `.dart_tool/release-2.0.0/`，不作为发布资源。

| 检查 | 结果 |
|---|---|
| `flutter test --no-pub test/core/services test/core/constants` | 200 通过，0 失败；新增稳定版显示与新旧键顺序测试，不读写真实注册表 |
| `flutter analyze --no-pub` | 全仓 No issues found |
| 完整 Windows Release 流水线 | 通过；Flutter 构建 836.9 秒，冷目录重新下载原生依赖；仅第三方 CMake/MSVC 警告 |
| 私有路径拒绝 | 九种代表名称均被拒绝，正常载荷被接受 |
| ZIP | CRC、解压、全部文件 SHA-256、清单数量、与暂存目录一致性均通过；临时目录已清理 |
| SQLite | cooccurrence、tag_catalog、tag_semantics、tag_wiki 四库 `mode=ro&immutable=1` quick_check 均为 ok |
| Agent | 解压 Node v24.18.0；builtin nai-studio / nai-prompt；合成 CodeMode、MCP 调用与会话恢复通过，20 个业务工具，2 次 loopback 合成请求，真实模型与 NAI 请求均为 0 |
| 安装器 | 测试专用键/名称/临时目录重新编译，NO_SHORTCUTS；静默安装后逐文件等同暂存目录加 Uninstall.exe；覆盖安装后所有程序哈希一致 |
| 升级和卸载保护 | user-data、agent-data、WebView2、.studio-data-* 哨兵升级/卸载保留；未知普通文件升级保留；卸载后所有程序文件删除、测试键删除 |
| 旧键迁移 | 使用测试专用旧键：同目录删除、不同目录保留；未写入新旧正式卸载键 |
| 进程处理四场景 | 原验证脚本通过；没有修改进程枚举/软化 fail-closed/探锁/诊断算法 |
| EXE 版本与签名 | 应用与正式 Setup 的 ProductVersion / FileVersion 都是 2.0.0+42；Setup CompanyName=W.O.F，应用原生身份不变；两者均 NotSigned |
| CI 静态检查与更新元数据 | 两份 YAML 可解析；PowerShell 语法通过；元数据脚本成功识别两种新文件名和哈希 |

安装精确比对前，原有进程检查在本机一次发生 snapshot 查询失败，目标 EXE 不存在，探锁正常放行并生成 `install_diagnostics.log`。该日志已归档到审计目录后从测试安装目录移除，再严格比较载荷加卸载器。没有更改、绕过或关闭安装器诊断行为。便携校验首轮在验证全部通过后清理失败，原因是 Python SQLite context manager 不关闭连接；验证脚本改用 `closing()` 后完整重跑通过，旧临时副本已清理。

## 分发边界与遗留风险

- **未签名**：本地产物未配置发布者签名，Windows SmartScreen 可能警告；随包 CRT 的微软签名均有效。CI 保留可选签名，并在签安装器后刷新产物校验文件。
- 本机出包与验证阶段未替换正在运行的正式版本；用户数据、正式快捷方式和正式卸载键未写入。
- 升级采用保守覆盖，不实现旧 app_files_manifest 的退役文件删除，避免根据可被用户修改的 JSON 误删未知文件。旧程序退役文件可能残留；升级不会主动删除清单之外文件。卸载延续原行为：仅明确保护四类私有目录，其余安装目录内容删除。
- CI 已在 GitHub runner 实跑并发布 v2.0.0。未启动真实 GUI，因此不宣称完成交互式安装向导或应用界面人工验收。

# W.O.F NAI Studio 2.0 Preview · Windows x64 本地交付

本批按用户授权累计更新当前 Studio，并重做最新版免安装便携包。有效源码继续为 `.devin/wt/ui-integration` / `codex/uiux-integration`；既有正式运行根、原检查点、旧便携 ZIP 和应用数据身份保持。

## 版本与内容

界面显示版本为 **2.0 Preview**；Flutter / Windows / 更新比较使用内部版本 `2.0.0-preview+6`。启动入口的版本行、关于页和许可页使用同一显示格式，中英文 README 徽标、当前说明及包信息同步。Windows 资源回退版本也更新，`CompanyName=com.example`、`ProductName=nai_launcher`、可执行文件名和单实例窗口身份保持，继续使用既有数据目录。

本次包含 UIUX 九页与完整 NAI Agent，及当前分支累计的窗口拖拽 / 底色、侧边块库、无限画布、历史时间标注、图片右键菜单、退役词库入口撤除、SVG 几何修正与轻微平滑、三条玻璃工具条和 Anlas 胶囊。新纳入尚未安装的 Vibe 编码防溢出 / 重复费用精简 `a748aae45` 和 OLD 原图 / 局部重绘蒙版对比 `444c67184`。

## 便携包与本机更新约定

便携包从已登记程序文件白名单组装，累计替换经过核验的 AOT / 必要原生版本资源，保留完整字体、图标、数据库、桥接客户端和 Node / Pi。另附未修改的 Microsoft x64 Release CRT、许可、中英文说明、公开包信息、程序文件清单和 SHA-256 文件。

不从运行目录递归打包个人状态；不包含打包者账号、密钥、Agent 会话 / 配置、浏览器资料、图库、日志、内部安装收据或本机源码路径。此处便携指免安装 ZIP；用户配置仍按原程序存放在 `%APPDATA%/com.example/nai_launcher`，不是 EXE 旁的数据沙盒。在已有 Studio 的电脑上使用同一用户数据，测试者使用自己的账号。

本机更新在所有构建、包与完整内容核验完成后执行。覆盖前重新核对 Studio 与捆绑 Agent 已从托盘完全退出，复制回退备份，仅替换本批登记的差异程序文件并复验安装收据。不自动启动、重启或热重载，不触发生成 / 模型调用。

## 本轮材料

源码、版本修改备份、构建输入冻结、测试 / 分析 / 构建日志、打包与解压核验、原生依赖检查、隔离更新器案例、回退材料和本机安装结果保存在 `.dart_tool/studio-2-preview-20261014/`。它们是本轮审计材料，不随用户便携包分发。

## 最终结果

- 编译源码：`bdc0e6634d5862ea81737299ed2eed417858d7ef`。最终全量 Flutter **6716 通过 / 5 跳过 / 0 失败**；全仓 analyze 无诊断，Windows Release 使用 `--no-pub --no-tree-shake-icons`，1813 份生产输入冻结并复验。
- 版本显示覆盖启动入口、关于与许可页，以及更新弹窗的当前 / 最新版本；统一使用 `2.0 Preview`，机器比较仍使用原始 SemVer。新显示回归核对两种字段，不改版本比较。
- 最终便携包：`04_工具/UIUX重做/测试包/WOF_NAI_Studio_2.0_Preview_20261014_r2_Windows_x64_Portable.zip`，317328202 字节（约 302.63 MiB），15363 文件；同目录附 `.sha256`。SHA-256：`cc12e9e483f3290601190c24a2b8072681010a57885ebd11d29f736be65b0635`。
- ZIP CRC、每份内容哈希、实际解压、程序清单、三个 SQLite 的只读 quick_check、完整字体 / 214 资源、48 个原生模块依赖闭包通过，无未解决依赖；十份 Microsoft CRT 签名均有效。解压后 Node 24.18.0 / Pi 1.1.0 的 Agent / CodeMode / 会话恢复六项检查通过，七个默认入口与十九个业务工具保持；两次模型请求只到本地合成服务，没有真实模型或 NAI 请求。
- 本机已于 **2026-10-14T20:03:44.619435+08:00** 更新，安装前 / 期间均重新检查完全退出；没有强行结束进程，也没有自动启动。正式收据与最终 `installed-delivery.json` 字节一致，installed=true / ready_to_install=false / installation_hold=false。
- 最终 AOT：`744a1069d068b0c979e76dd493703a4b985c13b246adcfe179a270ce4e14caa5`。15345 程序文件、214 资源、31 原生文件与 15095 Agent 文件全量哈希通过；本批只受控替换 AOT、EXE 和程序清单。原 EXE 的代码 / 展开信息保持，第一阶段仅更新版本资源，后续补全更新弹窗显示。字体、图标、数据库、桥接客户端和 Agent 内容保持。
- 本轮先交付并安装一份已核验的 Preview，再在最后版本入口检查中发现更新弹窗仍显示内部版本串，完成格式化和新增回归后交付 `r2`；第一份 Preview 和原 1.1.1 便携 ZIP 均保留。两阶段程序回退材料分别在 `.dart_tool/studio-2-preview-20261014/rollback/` 与 `.dart_tool/studio-2-preview-final-20261014/rollback/`，合并入口 `rollback_all.py` 默认只验证，显式 `--restore` 才按序恢复到本任务前的 16:28 运行包；只读回退预检已通过，未实际回退。

最终审计以 `.dart_tool/studio-2-preview-final-20261014/` 为准，第一阶段记录保留。版本入口的真实字体组件实绘在其 `captures/`，不冒充正式窗口实机验收。本地交付不代表 GitHub Release 已发布。

# UIUX Windows 工程验收与完整包（2026-10-14）

2026-10-13 启动，10-14 完成工程验收和完整包；用户明确选择“现在安装”后，已于 2026-10-14 06:45（Asia/Taipei）完成正式安装。用户实机验收尚未完成。继续原整合候选，不重做原版设计。安装包沿用本轮启动日标识 `20261013`。

## 编译输入与设计保护

- 有效候选：`E:/A.I/NovelAI/.devin/wt/ui-integration`，分支 `codex/uiux-integration`。编译输入固定在 `80cadc7d`；应用界面及业务仍为前端收口 `bbd5414f`，本轮只提交合成服务的测试端口适配与诊断。
- Flutter 3.47.7 / Dart 3.13.5；Windows Release 使用 `--no-pub --no-tree-shake-icons`。不改布局、颜色、字体家族、字重、契约、假数据、原中文/繁中文案或金图。
- 首次默认 Release 对 `StudioIcons.ttf` 裁剪了 2756 字节。关闭图标字体裁剪后重新构建，完整原版图标保持；包内所有源码字体逐份 SHA-256 相同，数据库为真实 SQLite 并与源码字节一致。
- 1621 份源码/资源/原生/Agent 输入与 878 份测试输入冻结；九个原来源 HEAD、状态与 765 份原改动哈希保持。安装前正式程序的 15337 份托管文件及收据已核验并保留程序备份；本轮未启动 Studio 或写入用户状态。

## 最终验证

| 检查 | 结果 |
|---|---|
| 最终全仓 Flutter，默认全部测试，并发 3 | **6490 通过 / 5 既有跳过 / 0 失败**，结束标记 success=true；不排除标签、不更新金图、不削弱原断言 |
| 全目录 analyze | 无诊断 |
| Agent 全专项，并发 3 | 316 项通过；包含于最终全仓，不另相加 |
| 包内同版 Node 的 Agent 核心与生产宿主 | 连续 5 轮，每轮 73 项通过，不相加为全仓数字 |
| Node 24.18.0 合成宿主回归 | 43 项通过 |
| Windows Release / 原生存储身份 | 编译通过，`com.example/nai_launcher` 保持，显示名 W.O.F NAI Studio |
| 完整包 Agent 实际 SDK / CodeMode / 会话恢复 | 6 项检查通过；7 默认入口、19 个 Studio 业务工具，Pi 八组件均 1.1.0；2 次本地合成模型请求，真实模型与 NAI 请求均为 0 |
| 安装/回退脚本隔离验证 | 安装回退、换完故障恢复、进程占用、源码漂移、私有状态保留共 5 场景通过；没有替换正式目录 |
| ZIP | 全 CRC 与 15344 项程序文件逐项 SHA-256 通过；没有打包 agent-data / WebView2 用户状态 |

## 本轮连接偶发问题

首次完整串行保留真实结果：6487 通过 / 5 跳过 / 1 失败，21 分 11 秒。失败为合成模型未收到请求，Pi 返回 Connection error。诊断轮记录与负对照均保留，不用局部通过覆盖该全仓结果。

本机 TCP 动态端口范围为 1024–15000。临时端口探针实际分配到 10080、1720、1723 等 Fetch 禁用端口，Node 在请求到达服务前返回 bad port。以原生产宿主测试固定 10080，精确复现 Connection error / 零请求；底层 trace 明确 bad port。首轮随机失败没有记录当时端口，不能声称逐个历史偶发根因全部确证。

`80cadc7d` 只为 Dart 与 Node 测试替身选择 Fetch 可访问的本地端口，并补简短终态诊断和两个真实 Node 回归。不修改生产适配器，不放宽断言、不延长超时、不自动重试模型请求。最终完整并发测试及五轮宿主稳定性通过。

## 完整包

- 目录：`build/uiux-integration-delivery-20261013/`。
- ZIP：`build/nai-studio-uiux-integration-20261013.zip`。
- 大小：336186882 字节。
- ZIP SHA-256：`3d0490c6de179cfda2ffe526087a2fa57cb922385be208378046f0fc4251b6a9`。
- AOT SHA-256：`f40087ad9ab2a1cc7b32b98feeb48be375882e6906993336daa7e17da3eb07dd`。
- 31 个配套原生文件、213 个资源、15095 个 Agent 文件，共 15344 项程序文件；保留新构建未带出的 emoji / permission / share 三个既有 DLL。PI-LICENSE 从已核验正式包保留，源码未携带该无后缀许可文件；没有省略许可。
- Agent 生产代码来自整合源码，固定 node_modules、Node / Pi 版本与许可随包交付。桥接客户端与本地放大辅助程序沿原已安装字节保留。可选模型权重及私有状态不在本次替换范围。

## 本机正式安装（2026-10-14 06:45，Asia/Taipei）

- 用户回答“现在安装”；安装前及替换前核对 Studio / Agent 完全退出，按本次 `deploy.ps1 -Mode Install` 执行，没有绕过预检或自动关闭进程。
- 登记运行目录：`E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`。
- 当前收据 `E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`、候选 `delivery.json` 与 `installed-delivery.json` 字节一致，installed=true、ready_to_install=false、installation_hold=false；ZIP 与构建目录原包收据保持不可变。
- 15344 项安装文件逐项 SHA-256 匹配，包括 213 资源、31 原生与 15095 Agent 文件；原生存储身份复验保持 `com.example/nai_launcher`。
- 562 份用户状态文件（AppData / agent-data / WebView2）安装前后文件集合和哈希相同；未触及的可选模型目录 `upscale` 不纳入大权重指纹复验。九个来源工作树与 765 份原改动保持。
- 单步回退：`E:/A.I/NovelAI/.devin/wt/ui-integration/.dart_tool/uiux-windows-20261013/rollback`。真实备份 `ValidateRollback` 只读核验通过；没有执行实际回退。回退只替换程序，保留后续用户状态。
- 没有启动 / 重启 / 热重载 Studio，没有真实模型或 NAI 请求。用户可从原入口自行启动，实际界面与工作流验收另记。

## 安装及实机边界

默认只读预检：`.dart_tool/uiux-windows-20261013/deploy.ps1 -Mode Validate`。安装使用登记 Glass 目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`；不能用普通 Release 目录直接整目录覆盖。

脚本 `Install` 核对编译输入、包内哈希、旧程序/收据以及 Studio/Agent 完全退出，再建立完整 data、Agent 运行时、根程序文件与收据备份，分阶段替换；失败恢复旧程序。`ValidateRollback` 只读核验本次真实备份，`Rollback` 回退程序，保留用户 agent-data 与 WebView2 状态。不自动启动、重启或热重载。

正式目录只读预检通过：包内完整性、冻结编译输入、旧程序与收据均匹配，现场没有 Studio 或包内 Agent 进程。预检不执行替换，安装前仍重新核对。

目前完整包已替换正式运行程序，未自动启动。Windows 整合包真实运行时的字体/布局、拖窗/DPI/路由、九页交互与 Agent Dock 仍待用户实机验收。原中文金图与 widget 实绘不冒充桌面验收；真实生图/付费编码另需用户明确授权及单价/余额报告。

本机收据、冻结输入、所有日志、负对照和安装器在 `.dart_tool/uiux-windows-20261013/`，不提交程序、日志、私有状态或密钥。首次及完整字体构建日志均保留。

两次未完成组包的临时目录 `build/uiux-integration-delivery-20261013-partial-1/` 与 `-partial-2/` 仍保留；自动审批拒绝其清理，返回 `blocked by policy`，没有绕过限制。它们不进入完整 ZIP，也不是安装来源。

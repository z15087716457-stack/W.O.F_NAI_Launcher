# 2.3.4 发布核验

版本 `2.3.4+102`，标签 `v2.3.4` 固定源码 `f6ff6c002cb654195c76241525a919e1771a2ccd`。2026-11-13（Asia/Taipei）完成 Windows 与 Mac 发布。

- [正式发布页](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.3.4)
- [两端构建](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/43392078183)
- [更新清单](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.3.4/release_manifest.json)
- [公开校验值](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.3.4/checksums.txt)

## 发布范围

包含块多图预览、独立裁切及五行悬浮卡词条；外部 Agent 的 Skill／原生工具、独立会话和画布通知；Agent 图片历史压缩、运行中开启缓存保温、空回提示及额外等待计时器撤除；新版 PR 导入弹窗、质量词预设命名、普通增强尺寸对齐和在线大图顶栏拖窗。完整用户说明见 [CHANGELOG](../CHANGELOG.md#234---2026-11-13)。

`main` 与标签正常快进／新建推送，没有重写既有发布标签。中英文 README 的说明和 Mac 下载链接同步更新，保留原项目归属。125 个文件提交包含累计源码、测试和文档；首次纳入打包清单的四个 Agent 模块在两端成品中均已核对。

## 构建与检查

- Git LFS 对象检查和 4 个数据库来源核验通过。发布前复用已通过的相关回归，最近为完整 160 项 Node、74 项 Flutter；本机 +101 交付时全仓分析 0 问题、3 项打包检查通过。
- 同一发布流程的 Windows 与 Mac 构建成功后，统一生成 Release、三种下载类型的更新清单与完整更新说明。9 个附件齐全，发布为最新稳定版；公开 body 与附带更新说明一致，完整对应本次 CHANGELOG。
- 三份包的 GitHub 摘要、公开 SHA-256 文件及更新清单一致。Mac 包先从本次发布流程的成功产物下载，再核对与公开资产摘要和大小一致。

## Windows

便携包 15,558 个文件，15,557 条内部校验全部通过；Setup 解出的程序载荷与便携包逐文件一致。4 个数据库 `quick_check` 通过，所有 46 个已跟踪 Agent 源文件与发布源码按文本换行规范核对一致。

Node 24.18.0、Pi 1.5.0、内置 Skill、资源窗口插件和存储身份检查通过。成品中的合成工具调用、RAG 宿主启停、8 项检查点回归及 2 项 ChatGPT 适配器测试通过；没有真实模型／NAI 请求，也没有启动 Studio。

Windows 包仍未配置代码签名，首次运行说明见 README。

## Mac 通用包

通用包共有 19,787 个条目、41 个 Mach-O 文件；所有共用可执行文件／动态库覆盖 arm64 与 x86_64，npm 平台预编译模块按两架构成对提供。版本、源码提交、AOT 摘要及 4 个数据库来源核对通过；46 个 Agent 源文件与发布源码一致，包含本次新增的外部入口、共享工具和图片处理模块。

Mac CI 的共享平台测试、通用构建和签名检查通过。最低 macOS 13.5，仍使用临时签名（ad-hoc），未 Apple 公证；本批没有 Mac 实机启动验收。

## 公开产物

| 文件 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_macOS_2.3.4_Portable.zip` | 410,331,496 | `fcf717206aef16c70120b128d3338134c0781ca045fa423d8b3fcabb48ed3ad3` |
| `WOF_NAI_Studio_Windows_2.3.4_Portable.zip` | 324,068,725 | `0a06e895c4d6a71a922f7836310986af6fd5f5acedbe574eb92d0cf5971ee424` |
| `WOF_NAI_Studio_Windows_2.3.4_Setup.exe` | 200,977,592 | `ffdc6f865a5a4cfc32d8ad9d572e91b7c0ae95fb9aa923b395abaca214c53e72` |

本机桌面仍为此前交付的 `2.3.3+101`，本次不另行替换、启动或回退桌面程序。它与公开包的交付状态分别记录。

完整本地证据在 `.dart_tool/release-2.3.4/`：`push-result.json`、`run.json`、`jobs.json`、`release.json`、`metadata-validation.json`、`verification.json`、`macos-verification.json`、下载及成品测试日志。核验文档作为普通后续提交补入 main，发布标签保持不变。

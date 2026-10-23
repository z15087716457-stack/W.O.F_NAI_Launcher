# 2.1.1 · 本机验收更新

2026-10-23 用户要求“然后推送更新到桌面，我检查一下没问题就发2.1.1”。已按本地交付约定安装到原桌面入口，版本 **2.1.1+44**，编译提交 `bf4309a354f9d3f91cf388b016780dbd4ef08bb0`。GitHub 正式版仍为 2.1.0；2.1.1 等待用户实机验收和后续发布授权。后续文档提交不代表重新编译。

## 累计内容

- 提示词组卡点击“生成”直接导入当前项并授权一张图，保留报价、余额、备份和状态复核、原生准入、停止、防连点及持久化；模型主动生成仍需真实价格卡，包括 0 Anlas。源码 `927381455`。
- 修复新装配置二次启动白屏：首次建立兼容联接；对已分叉的已知插件文件带备份恢复，冲突保留双方并显示恢复页。源码 `426b74ee7`；[验证与恢复边界](startup-data-recovery-2026-10-23.md)。
- 提示词组局部编辑指导：一次 CodeMode 中读取原卡，仅修改指定字段，复用其余内容回写，减少全量重新输出。源码 `2024fcf56`。
- 卡片类型、标题、单位和说明按用户语言描写；生成提示词在 V5 以下用英文，V5 优先英文，可直接用更清楚的其他语言。只改说明，不做自动翻译或语言映射。源码 `1bd7c45c2`。
- 生成按钮去掉左侧装饰，价格胶囊按数字、现有 Anlas 图标排列。源码 `a9158aac2`。
- 画廊按文件事件合并更新，后台积累路径，返回后局部处理实际变化，保留浏览状态和未变化缓存；手动刷新仍完整核对。没有轮询或失败自动重扫。源码 `1a1532ba0`；[实现与验证](gallery-file-events-2026-10-23.md)。
- 内置提示词 Skill 两句通用建议：V5 多用自然语言、词条按需作锚点；V4／V4.5 优先词条。用户工作区仍可定义创作规则。源码 `9bedceda1`。

版本及发布记录提交 `8fe1a83eb`。本次全量回归发现旧主题测试未隔离新增文件监听，`bf4309a35` 仅在测试 harness 注入监听替身，生产代码未改。

## 验证

- 全量默认 Flutter 测试首轮为 8517 通过、2 失败、5 跳过，失败均在主题测试文件。测试替身修正后完整重跑该文件，14 项通过；合并结果 **8519 通过、0 未解决失败、5 跳过**。这不是一次全部通过的全量重跑，原始失败及补跑日志均保留。两次运行间只修改该测试文件，生产输入一致。
- Node 测试 **88 通过、0 失败**；`flutter analyze --no-pub` 无问题。
- Windows Release 使用登记 SDK、`--no-pub --no-tree-shake-icons` 构建，2025 项生产输入在构建及安装核验间一致。
- 12 项安装／回退夹具，4 个 SQLite 资源 quick_check，19 个字体文件，原生数据身份、版本与依赖核验通过。
- 包内 Node 24.18.0／Pi 1.3.0、两项内置 Skill、Agent／CodeMode／会话恢复合成冒烟，以及 RAG 原生宿主 ready／shutdown 通过。没有真实模型、NovelAI、生图、模型下载或建库请求。

日志位于 `.dart_tool/cumulative-2.1.1-20261023/`：`regression.jsonl`、`theme-rerun.jsonl`、`release-validation.json`、`node-tests.log`、`analyze.log`、`package-verification.json` 和 `final-verification.json`。

## 本机安装

安装时间 `2026-10-23T17:30:50.728641+08:00`。正式运行目录仍为 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/`，原桌面 `W.O.F NAI Studio.lnk` 保持。正式收据与本次 `installed-delivery.json` 一致，`installed=true`、`ready_to_install=false`、`installation_hold=false`。

完整核对 15288 个程序文件、226 个资源，实际替换 7 个程序文件，新增和退役均为 0。保留现有原生 DLL，数据身份仍为 `com.example/nai_launcher`。

AOT SHA-256：`371db68fff6ddce2933d0c84981a2d13f4f33d3619712f468f529ef2576a508e`。

安装后逐文件哈希、清单、收据与回退备份通过。用户数据／Agent 数据根目录、兼容联接及桌面快捷方式保持；3 个正式索引文件的大小、时间戳和身份保持，没有打开正式 SQLite 或 ANN。

审计与单步回退材料：`.dart_tool/cumulative-2.1.1-20261023/rollback/`，保存被替换的 2.1.0 程序文件、原收据及完整程序 `data/`，备份已验证，未实际回退。这里的 `data/` 是程序资源，不是用户 `user-data/`。

未自动启动、重启或热重载 Studio，未推送远程、打 tag、发布 GitHub Release 或制作便携包。用户手动打开原桌面入口后检查；线上发布另待确认。

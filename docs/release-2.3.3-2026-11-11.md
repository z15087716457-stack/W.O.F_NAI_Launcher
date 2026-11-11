# 2.3.3 发布核验

版本 `2.3.3+99`，发布标签 `v2.3.3`，源码提交 `0f6f760a4454141f44430526ab1ceb83bbd09fec`。日期为 2026-11-11（Asia/Taipei）。

- [发布页](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.3.3)
- [两端构建](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/42967207976)
- [更新清单](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.3.3/release_manifest.json)
- [公开校验值](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.3.3/checksums.txt)

## 范围

侧栏更新入口、后台下载、安装前任务检查，以及自公开 2.3.2 以来的本地放大下载进度、跨行选择、参考图交互、Agent 动画与会话收尾、Windows 离屏恢复和隐藏页面缩放优化。完整说明见 [CHANGELOG](../CHANGELOG.md#233---2026-11-11)。

正常标签发布现在同时构建 Windows 与 Mac，手动发布默认也包含 Mac；两端成功后才统一发布产物和更新清单。README 中英下载页已同步。

## 本机交付

Windows Release 编译通过，冻结 2,147 个生产输入；15,553 个程序文件核验通过，差量替换5个，保留2.3.2+98单步回退。快捷方式、用户数据、图库数据库和3个RAG索引元数据保持。没有自动启动 Studio。

相关543项Flutter回归通过，1项需要RTX与缓存SDK的可选实机审计未启用；全仓静态分析0问题，3项发布载荷测试通过，4个SQLite数据库及Git LFS对象核验通过。

## Mac 通用包

Mac CI 构建与签名验证成功；本地解包核验版本、源码提交、AOT摘要和4个数据库与源文件一致。包内 19,783 个条目、41个Mach-O文件，所有需共用的可执行文件／动态库均包含arm64与x86_64；npm平台预编译模块按两架构成对提供。

最低macOS 13.5。使用临时签名（ad-hoc），尚未Apple公证；本批没有Mac实机启动验收，首次启动方法见README。

## 正式产物与发布

公开Release为最新稳定版，9个附件齐全。三份包的GitHub摘要、公开SHA-256文件与更新清单一致；Mac包先从本次成功构建的产物下载，再与公开资产的SHA-256及大小核对一致。

Windows便携包共15,554个文件，15,553条内部校验全部通过；Setup解出后的程序文件与便携包逐项一致。4个数据库quick_check通过，资源窗口插件、Node/Pi版本、内置Skill、RAG宿主启停及合成工具调用核验通过，包内检查点回归8项、ChatGPT适配器替身回归2项通过；真实模型与NAI请求均为0。

Mac包共19,783个条目，版本、AOT摘要、4个数据库与发布源码一致，41个Mach-O文件的架构覆盖通过。没有在本机执行Mac应用。

| 公开包 | 字节数 | SHA-256 |
|---|---:|---|
| `WOF_NAI_Studio_macOS_2.3.3_Portable.zip` | 410,162,736 | `846a2a360355dcf1c242c8ad862782a0a1171b7bad3271c714dc42258b6d6f5d` |
| `WOF_NAI_Studio_Windows_2.3.3_Portable.zip` | 323,985,905 | `b0d3421f05094cb867a5fd7838c558b277afcd58723a993a9a9532da0a560ce7` |
| `WOF_NAI_Studio_Windows_2.3.3_Setup.exe` | 200,848,213 | `e149433f2868235e6a729cff1b5590eca74f7121d00488ea9d9251f48aad9451` |


发布后的核验文档作为普通后续提交补入main；发布标签保持不变。

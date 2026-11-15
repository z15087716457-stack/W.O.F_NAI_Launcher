# 2.4.0 修正版发布核验

2026-11-15（Asia/Taipei）。**[v2.4.0已正式发布](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.4.0)，当前公开最新版为2.4.0，两端构建号均为2.4.0+108。** 桌面已更新至相同源码的+108；[本机交付与最终核验](local-2.4.0-build108-2026-11-15.md)。

## 修正与来源

轻量翻译改为原文直接编辑、只读译文持续显示；局部修改显示小扳手＋待更新，整段删除联动移除。保留此前已确认的逐逗号翻译、居中拖入、工作区前置内容及其余2.4.0功能。见[实现与回归](inline-translation-edit-2026-11-15.md)。

源码与发布标签指向`3999baffedd34d26fbbe52ae1411275df7c8a423`；[正式两端流程43688552895](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/43688552895)全部成功，包括Windows、Mac通用包及发布任务。旧候选2d75c84c0的流程43684954810已取消，未形成正式2.4.0 Release；旧标签对象先保存在本地备份ref及审计材料，再按用户授权经精确lease替换。未重写其他历史发布标签。

## 下载与校验

共9项公开资产：Windows安装版／便携版、Mac通用便携包、三份独立校验文件、checksums.txt、release_manifest.json及完整release notes。全部实际下载，大小与GitHub SHA-256匹配；更新清单、独立校验文件和压缩包一致，发布正文与所附说明及CHANGELOG一致。

| 公开程序包 | 字节 | SHA-256 |
|---|---:|---|
| [WOF_NAI_Studio_macOS_2.4.0_Portable.zip](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.4.0/WOF_NAI_Studio_macOS_2.4.0_Portable.zip) | 410,505,436 | `f61d2824eff6ae50c7de4e7f8f23125c0bebd7fd08fd05f552279495fb033d2e` |
| [WOF_NAI_Studio_Windows_2.4.0_Portable.zip](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.4.0/WOF_NAI_Studio_Windows_2.4.0_Portable.zip) | 324,221,303 | `85a6e8099f9b93c040d089033b5811eaa781da39148a50dc456176f510a1dfee` |
| [WOF_NAI_Studio_Windows_2.4.0_Setup.exe](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/download/v2.4.0/WOF_NAI_Studio_Windows_2.4.0_Setup.exe) | 201,050,103 | `e909160d24076f184134cd720a5ca6c30c4e2e3783fb7e73ad05acdfc6d0aa9d` |

Windows：15558个程序文件、15557项内部校验，4个SQLite数据库quick_check通过；安装包仅解包，载荷与便携版逐文件一致。Node24.18.0／Pi1.5.0、内置Skills、Agent及RAG源码匹配；实际包执行隔离Agent冒烟、RAG原生宿主启动／关闭、8项checkpoint和2项ChatGPT适配检查。真实模型与NAI请求均为0，未启动Studio或安装公开Setup。

Mac：19787项ZIP记录、41个Mach-O、46项Agent源码及四个数据库核验通过；主程序、Flutter框架、Node、桥接与RAG宿主均覆盖arm64／x86_64，npm原生预构建按两端配对检查。最低macOS13.5，CI已核验临时签名；**未Apple公证，没有Mac图形界面的实机启动验收**，README保留首次打开说明。

## 验证与恢复

源码相关回归396项、最终布局／语法／生成接线179项、全仓分析0问题、3项打包及4项隔离安装器检查通过。桌面最终15,557项程序、14项关键用户文件、图库、索引与快捷方式核验通过。回退误操作及重新应用同一冻结载荷的完整记录保留，最终桌面为+108，未启动用户应用。

公开资产与流水线材料在`.dart_tool/release-2.4.0-corrected/`，包括`verification.json`、`macos-verification.json`、`release.json`、`run.json`及全部公开下载；本机交付与+107回退在`.dart_tool/local-2.4.0-build108-20261115/`。资产核验不替代用户实测；临时安装载荷清理仍暂停。

# 2.4.1 发布核验

**2026-11-15已正式发布[W.O.F NAI Studio 2.4.1](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.4.1)，完整版本2.4.1+115；公开latest已核对。** Windows安装版、便携版及Mac通用包均已发布并下载核验。本机+115已获用户确认，版本与正式版一致，本轮保持原桌面安装。

## 内容

汇总2.4.0之后的轻量翻译语义分段、V5混合格式、完整长译文与直接原文编辑修复，以及输入法重复组词、选区细缝、补全自适应换行／仅键入触发／键盘滚动、默认值和热度数字排版修复。Ctrl标签扩展原有自动定位保持。

完整九项说明已合入[CHANGELOG](../CHANGELOG.md#241---2026-11-15)，中英README同步；公开Release正文与附件说明一致，未遗漏此前Unreleased中的六项修复。

## 发布来源

- 发布提交：`929ed4bcadfd1a6ac6a75cace37536715a556c6e`；main正常快进。此前未发布标签已独立备份，并使用精确租约更新；发布后标签保持，不重跑旧取消载荷。
- [正式流程43719440710](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/actions/runs/43719440710)的元数据、Windows、Mac及Publish均成功；已取消的仅为同一提交额外触发的main分支Mac构建。
- 源码发布前2,171项生产输入与已安装+115匹配，之后仅整理CHANGELOG及双语README。复用源码一致的66项浮层／4项繁中检查、4组实绘及分析；另跑38项版本更新检查，LFS、SQLite头和完整发布说明夹具通过。

## 正式产物

三个包的实际大小、GitHub摘要、附属SHA-256、checksums.txt和release_manifest.json一致，更新清单版本为2.4.1+115。

| 产物 | 字节 | SHA-256 |
|---|---:|---|
| WOF_NAI_Studio_macOS_2.4.1_Portable.zip | 410,590,560 | `506e42582592dce41f4d909cc2e21d4bcc2d22f426b31fa585f453f78a357c67` |
| WOF_NAI_Studio_Windows_2.4.1_Portable.zip | 324,254,662 | `7f231764f2be3fb205e6236c1f310ca188cba0a1f07c4b33d262129ad2f9ccc5` |
| WOF_NAI_Studio_Windows_2.4.1_Setup.exe | 200,999,735 | `d366c40b00f58c535b015a4e095874ae11fe65d16a9cdca5c3ae0320989838ff` |

另附三个单独sha256文件、checksums.txt、release_manifest.json及release_notes_v2.4.1.md，共9项附件。

## 包内核验

- Windows Portable共15,558文件，15,557项内部校验通过；Setup解包后与Portable逐文件一致。版本、提交、AOT、原生存储身份、资源小窗插件、4份SQLite、字体及Agent／RAG来源核对通过，包内无发布者用户数据。
- Windows包内Node24.18.0／Pi1.5.0、内置Skill和隔离Agent流程通过；原生RAG宿主启动／关闭、8项checkpoint与2项ChatGPT协议检查通过，真实模型／NAI请求为0，未启动Studio。
- Mac包元数据及plist为2.4.1+115／build115，最低macOS13.5，41个Mach-O文件的架构检查通过；主程序、Dart AOT、桥接、RAG宿主及Node包含arm64／x86_64，npm分架构预构建保留配对。4份SQLite与源码一致，46项Agent源文件核对通过，ZIP完整。
- Mac临时签名由Mac CI核验，尚未Apple公证；Windows上的静态核验不代表真实Mac启动验收。

## 桌面与材料

原桌面仍[2.4.1+115](local-2.4.1-build115-2026-11-15.md)，收据与AOT保持，未重启或重装；原+114回退和暂停中的安装暂存清理边界保持。

本批材料：`.dart_tool/release-2.4.1-verified-20261115/`，含发布授权、原标签备份、源码核验、完整说明夹具、版本测试、推送／流程记录、下载资产及双平台核验。此前取消流程只作历史证据，不重跑。

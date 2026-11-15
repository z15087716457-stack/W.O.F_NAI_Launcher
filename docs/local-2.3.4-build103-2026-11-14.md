# 本机安装 2.3.4+103

2026-11-14，按用户“推送到桌面更新，并升本地版本号”指令完成 Windows 本机交付。公开 GitHub 最新仍为 v2.3.4／2.3.4+102，本次没有提交或推送 Git、发布应用、启动 Studio 或调用真实模型／NAI。

## 本批结果

- 安装版本由 **2.3.3+101 升到 2.3.4+103**，pubspec、Windows EXE 的 ProductVersion／构建号和包信息一致；不是只修改界面显示文本。公开版同为 2.3.4，本机额外包含本轮改动。
- 设置页及共用更新弹窗只显示更新内容，完整发布页入口保留；更新图标常态无底板、悬停显色，键盘焦点和操作保持。[实现与实绘](update-release-notes-2026-11-14.md)
- 新固定词库来源与检查逻辑已编入桌面，保留中文底座并增补547条的资源继续生效。Tag 309,441条、Wiki 298,922篇、中文资料54,407条与个人补充保持。[数据更新](dictionary-data-update-2026-11-14.md)
- 固定快照尚未随Git公开；当前本机已安装的数据可直接使用，不将本次桌面交付说成公开镜像已发布。

## 构建与保护

有效源码 `E:/A.I/NovelAI/.devin/wt/ui-integration`，基于 `5cb759b3d5349de6305847f93e9b361c78ed1950` 及34个未提交文件；冻结2,165个生产输入，相对旧收据改变24项。使用登记 Flutter 3.47.7／Dart 3.13.5，以 `--release --no-pub --no-tree-shake-icons --build-name=2.3.4 --build-number=103` 构建成功，构建阶段约102秒。

安装前核对全部旧程序文件，并把此前已获授权的数据资源补丁纳入实际基线：只对中文语义库和对应manifest两项更新收据摘要，原始收据另行保存，没有把已更新数据换回旧版。新的单步回退因此保留该数据补丁。

差量替换6个文件：AOT、EXE、CHANGELOG、两份包清单及 `tools/nai-agent/lib/studio-tools.mjs`；该Agent模块只有尾部空行差异，逻辑及依赖未变。无新增／退役程序文件。全部 **15,557个程序文件**摘要与新清单一致，原生库代码／依赖列表、存储身份及Pi 1.5.0保持；资源与现有数据补丁一致，无额外资源替换。

桌面快捷方式、用户数据入口／旧路径联接、图库数据库和3个RAG索引的文件状态保持；另外逐项对比9个词库／个人资料文件摘要，完全一致。程序未启动，真实窗口由用户自行验收。

## 验证与恢复

本批全仓分析0问题、3项打包检查通过；安装器的替换失败恢复、正常安装后回退及私有状态保护在隔离夹具核验。沿用已通过的84项词库相关Flutter、68项更新UI相关Flutter和9项语义Python检查，保存原日志摘要，不重复宣称重跑。已安装Agent模块语法检查通过；实际EXE版本为2.3.4+103，存储身份仍 `com.example/nai_launcher`。

证据在 `.dart_tool/local-2.3.4-build103-20261114/`：`final-verification.json`、`dictionary-preservation.json`、`baseline-reconciliation.json`、构建／分析／安装日志、`package-verification.json`、`installer-checks.json`及`rollback/`。AOT SHA-256：`b49dedbb30066a71f3f38491b2abec19aca8b7d04af6df6d133e005336b90138`。

正式运行目录与桌面快捷方式保持，当前收据仍是 `E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。完全退出Studio后可回退到2.3.3+101（包含今天已安装的数据补丁）：

```powershell
python .dart_tool/local-2.3.4-build103-20261114/update.py rollback
```

本批及此前回退材料保留，没有进行已暂停的安装暂存清理。

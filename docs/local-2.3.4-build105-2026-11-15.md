# 本机更新 2.3.4+105

2026-11-15，按用户要求将轻量翻译修复和居中拖入提示一起构建并安装到桌面，从2.3.4+104更新至**2.3.4+105**。原运行目录和快捷方式保持，没有自动启动Studio，交由用户实测；未提交／推送Git或发布公开包。

## 本次交付

- [轻量翻译布局修正](inline-reading-layout-fix-2026-11-15.md)：长译文随实际原文行展开，修正所有行被整段译文撑高、选区覆盖大片空白、译文跑到原文上方的问题；译文距原文字形底边2px，原样结果不重复显示。原文、换行及既有块翻译链路保持。
- [全窗口居中拖入提示](image-drop-centered-2026-11-15.md)：拖入与读取共用40%黑色遮罩及400×180最小高度居中卡片，复用现有组件；根Overlay覆盖窗口，两态不跳位，窄窗适配。原生接收范围、读取／防重入及逐张导入流程保持。
- +104此前累计功能继续保留；各专项中的实绘属于组件验证，未冒称运行中用户窗口验收。

## 构建、安装与保护

有效源码为`E:/A.I/NovelAI/.devin/wt/ui-integration`，基于`5cb759b3d5349de6305847f93e9b361c78ed1950`及未提交改动。冻结2,169个生产输入，相对+104仅改变7项（5个生产Dart文件、CHANGELOG及版本），无输入退役；299项既有工作区文件改动和删除状态保持。生成文件未改变，无额外代码生成或依赖更新。

登记Flutter3.47.7／Dart3.13.5，Release使用`--no-pub --no-tree-shake-icons --build-name=2.3.4 --build-number=105`构建成功，构建命令约102.05秒。CMake CMP0175开发警告仍在，未阻止构建。EXE ProductVersion为2.3.4+105，FilePrivatePart为105，存储身份保持`com.example/nai_launcher`。

差量替换5项：`data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、`app_files_manifest.json`、`package-info.json`。15,557个登记程序文件全部核对，无新增／退役。原生库代码、依赖表、全部资源、15,280项Agent文件及RAG模块保持，沿用原生Glass包，不用标准Release整目录覆盖。

AOT SHA-256：`af9e2836dbeaecfddcee8e3b95e3fdca8b895d1cccde90e1b37384f5135359fe`。

- 本批519项相关Flutter回归全部通过，全仓分析0问题；覆盖轻量／块翻译、原生编辑、复制／撤销、存储及拖入各入口。两项功能的前后实绘、12态居中提示几何／遮罩证据复用并保留摘要。
- 本批安装器4项隔离检查通过，包含失败恢复、安装后回退和私有状态保护；真实桌面未降级演练，已核对本次+104完整回退备份。未改变的Node、RAG和组包器复用+104验证，不重复运行无关套件，不把旧PNG差异写成通过。
- 安装约40.52秒。覆盖前后14项关键用户文件状态保持；用户数据入口、图库文件、当前3个索引文件和快捷方式保持。没有移动素材、修改草稿或重建索引，没有请求真实模型或NAI。

本批材料位于`.dart_tool/local-2.3.4-build105-20261115/`：`final-verification.json`、`package-verification.json`、`user-data-preservation.json`、`documentation-verification.json`、冻结输入、构建／测试／安装日志及`rollback/`。交付文档在安装后更新，编译输入与其他改动复验保持，原编译收据保留于`compiled-installed-delivery.json`。

## 回退

完全退出Studio及托盘后，从有效源码执行以下命令，恢复本次更新前的**2.3.4+104**程序与收据：

```powershell
python .dart_tool/local-2.3.4-build105-20261115/update.py rollback
```

当前收据仍为`E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。本批及更早回退、已暂停清理的暂存材料均保留。公开版本登记仍为2.3.4+102，真实拖图及轻量翻译效果由用户实测。

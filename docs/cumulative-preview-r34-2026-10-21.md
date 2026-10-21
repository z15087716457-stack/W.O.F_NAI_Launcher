# 2.0 Preview r34 · 交互与生成占位修正

用户 2026-10-21 说“ok，暂时是这些推送一下更新”，按本地交付约定，将四项修正累计安装到原桌面入口。内部版本 `2.0.0-preview+38`，编译提交 `7fba63c95acec7b433e7126d7da584afefa29833`；后续文档提交不代表重新编译。

## 本次内容

- 积木拖拽预览在根浮层绘制，进入积木浮窗时保持可见，验证松手收纳成功。[实现与组件验证](palette-drag-overlay-fix-2026-10-21.md)。
- 块库分组瀑布流改用并排懒加载列，修正跨组向下滚动回跳，保留自然卡片高度和标题吸顶交替。[实现与复现](blocks-folder-scroll-fix-2026-10-21.md)。
- 历史栏生成占位跟随点击生成时捕获的批次尺寸，横图、竖图和方图均按对应比例显示。[数据接线与布局验证](history-pending-aspect-fix-2026-10-21.md)。
- 本地放大三款 INT8 型号补齐易读名称和量化版本说明，五语言同步，沿用原型号 ID。[文案与界面验证](upscale-int8-labels-2026-10-21.md)。

## 验证范围

- 登记 Flutter 3.47.7 / Dart 3.13.5，`flutter analyze --no-pub lib test` 无问题。
- 本批受影响路径合并回归 **610 通过／0 失败／0 跳过**：块库 UI／后端／接线、积木拖拽、生成 UI／历史占位／视图映射／数据及页面接线、生成编辑器／后端、放大型号卡／设置后端和繁中资源。具体路径见审计目录 `regression-paths.json`；此数字与各专题验证有重叠，不相加。
- 未重跑 r33 的扩大范围整套回归；r33 的 4948 通过／31 项既有失败仅作为历史基线，不宣称本次重新验证了该失败集合。
- 12 项安装／回退夹具全部通过；Windows Release 构建通过；4 个打包 SQLite 资源 quick_check、19 个字体文件、原生版本和依赖核验通过。
- 打包后的 Node 24.18.0 / Pi 1.3.0 与内置 Skill、Agent／CodeMode／会话恢复合成冒烟、RAG 宿主启动 ready／shutdown 通过。探针使用隔离测试状态，未调用真实生成或服务商接口，未读取或重建正式索引。

## 本机安装

安装时间 `2026-10-21T14:32:38.521364+08:00`。正式运行目录为 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/`，原 `W.O.F NAI Studio.lnk` 及其指向保持不变。收据 `nai-launcher-src/.dart_tool/glass-rollout-delivery.json` 与本次 `installed-delivery.json` 一致，`installed=true`、`ready_to_install=false`、`installation_hold=false`。

固定 1999 项生产输入，核对完整 15287 个程序文件、226 个资源和 15025 个 Agent 运行时文件；实际只替换 `data/app.so`、`nai_launcher.exe`、`app_files_manifest.json` 三个文件，无新增或删除。重链接 DLL 仅 PE 时间戳不同，保留已装原件。原生身份仍为 `com.example/nai_launcher`。

AOT SHA-256：`0959c6b129cc08ef6eb2e2795d9c9fd553db23566e54867378839481d02ff825`。

安装后逐文件哈希、清单、正式收据和回退备份全部核对通过。`user-data`、`agent-data`、WebView2 与迁移锁等受保护路径身份／时间戳保持；3 个正式索引文件的大小／时间戳／身份保持，未打开正式 SQLite 或 ANN。旧 AppData 兼容联接保持。用户原有 `pubspec.lock` 未提交改动及 `.runs/` 留存。

审计目录 `.dart_tool/cumulative-r34-20261021/` 保存构建、测试、打包及最终核验材料；其中 `rollback/` 保存被替换的 r33 三个程序文件、原收据和完整程序 data。备份完整性已验证，未实际回退。

本次没有自动启动／重启／热重载 Studio，没有生图、建库、安装模型、制作便携包或推送 GitHub。界面行为已用合成数据组件验证，用户启动新版后的实际窗口体验尚待确认。

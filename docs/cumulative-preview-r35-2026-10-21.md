# 2.0 Preview r35 · 历史栏与本地画廊页头对齐

用户 2026-10-21 说“暂时是这些推送更新吧”，按本地交付约定，将两处对齐修正累计安装到原桌面入口。内部版本 `2.0.0-preview+39`，编译提交 `1ae45c241f7dc4a2f63381fd5d4c9e3605397735`；后续文档提交不代表重新编译。

## 本次内容

- Agent 展开后，历史栏标题、收起按钮和多选图标在 40px 标题行内垂直居中；保留空白拖窗与按钮点击。[实现与实绘](history-header-center-2026-10-21.md)。
- 本地画廊左侧标题和加号使用完整 62px 行高，对齐右侧“全部图片”行；分类树及页脚保持原位置。[实现与实绘](gallery-header-center-2026-10-21.md)。

## 验证

- 登记 Flutter 3.47.7 / Dart 3.13.5，`flutter analyze --no-pub lib test` 无问题。
- 本批受影响路径合并回归 **310 通过／0 失败／0 跳过**，包含两项对齐、生图原 PNG 基准与交互、多语言布局、原生标题／拖窗、Agent 实际宿主、历史栏、本地画廊三栏与工具栏。具体路径见审计目录 `regression-paths.json`；专题验证数字有重叠，不相加。没有重录基准。
- 本次未重跑 r33 的扩大范围整套回归，31 项既有失败仍按 r33 的历史验证记录，不宣称本次重新验证了全套失败集合。
- Windows Release、12 项安装／回退夹具、4 个 SQLite 资源 quick_check、19 个字体文件、原生身份／版本／依赖检查通过。
- 打包 Node 24.18.0 / Pi 1.3.0、内置 Skill、Agent／CodeMode／会话恢复合成冒烟，以及 RAG 原生宿主 ready／shutdown 检查通过。探针使用隔离状态，没有调用真实服务商或生成接口，没有加载正式语料或模型。

## 本机安装

安装时间 `2026-10-21T23:50:41.307325+08:00`。原桌面入口及正式运行目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` 保持。正式收据与本次 `installed-delivery.json` 一致，`installed=true`、`ready_to_install=false`、`installation_hold=false`。

固定 1999 项生产输入，核对完整 15287 个程序文件与 226 个资源；实际替换 3 个文件：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`，无新增或删除。重链接插件 DLL 仅 PE 时间戳不同，保留已装原件。原生身份仍为 `com.example/nai_launcher`。

AOT SHA-256：`95af1895a1838d201f00e3c5d385eec2dec4eac153ebb7327bcba90fe933f85f`。

安装后逐文件哈希、清单、收据与回退备份全部通过。受保护数据路径的身份／时间戳、旧 AppData 兼容联接和桌面快捷方式保持；3 个正式索引文件的大小／时间戳／身份保持，没有打开正式 SQLite 或 ANN。原有未提交 `pubspec.lock` 及 `.runs/` 保留。

审计目录 `.dart_tool/cumulative-r35-20261021/` 保存完整构建、回归、打包与最终核验材料；`rollback/` 保存被替换的 r34 程序文件、原收据和完整程序 data。备份完整性已验证，未实际回退。

未自动启动／重启／热重载 Studio，未生图或建库，未制作便携包或推送 GitHub。用户启动新版后的实际窗口体验尚待确认。

# 2.0 Preview r37 · Agent 图库批量整理与分隔条拖动

用户 2026-10-22 说“按照A来吧，然后开工，搞完就推送更新”，按本地交付约定，将 Agent 图库批量移动／批量删空文件夹与分隔条拖动预览线两项累计安装到原桌面入口。内部版本 `2.0.0-preview+41`，编译提交 `8050be0dfb9a312053918c2dbc8a2e2a5b78b2d5`；后续文档提交不代表重新编译。

## 本次内容

- Agent `gallery_manage`：`move_file`／`copy_file` 支持 `image_ids`（1..50），`folder_delete_empty` 支持 `folder_ids`（1..50，父子目录可一起删）。预检通过后每次调用最多确认一次，失败即停并返回部分结果，批量移动可整批撤销；工具说明和 nai-studio Skill 要求批量调用。[实现与边界](agent-gallery-batch-2026-10-22.md)。
- 分隔条拖动：Agent 侧栏、生图左栏／历史栏、画风探索编辑列拖动时只移动预览线，内容保持原宽，松手后一次性应用并持久化。隔离探针 `panel_drag` 的引擎 total P95 从 147.9 降到 62.4 ms。[实现与测量](resize-drag-preview-2026-10-22.md)。

## 验证

- Flutter 3.47.7 / Dart 3.13.5，`flutter analyze --no-pub lib test` 无问题。
- 发布版本受影响路径合并回归 **779 通过／0 失败／0 跳过**；范围在审计目录 `regression-paths.json`，含 Agent 图库管理与卡片、Agent 核心、繁中资源、Agent 侧栏、生图 UI、探索编辑列拖动、探索接线、宿主及画布接线、历史栏交互。Node `tool/nai_agent` 84 项另行通过。没有重录旧基准。
- 未重跑 r33 的扩大范围整套回归；31 项既有失败沿用历史记录。
- Windows Release、12 项安装／回退夹具、4 个 SQLite 资源 quick_check、19 个字体文件、原生身份／版本／依赖核验通过。
- 打包 Node 24.18.0 / Pi 1.3.0、两项内置 Skill、Agent／CodeMode／会话恢复合成冒烟及 RAG 原生宿主 ready／shutdown 通过；使用隔离状态与本地替身。

## 本机安装

安装时间 `2026-10-22T11:12:59.049033+08:00`。原桌面入口与正式运行目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/` 保持。正式收据与本次 `installed-delivery.json` 一致，`installed=true`、`ready_to_install=false`、`installation_hold=false`。

固定 2002 项生产输入，核对完整 15287 个程序文件与 226 个资源；实际替换 7 个程序文件（AOT、exe、清单和 4 个 Agent 运行文件），退役 0 个。原生身份仍为 `com.example/nai_launcher`。

AOT SHA-256：`780b12f8afd107e333819f24994a5bad58e92ea5426b509c6e5b8cb22000083f`。

安装后逐文件哈希、清单、收据和单步回退备份通过。用户数据目录、旧 AppData 兼容联接和桌面快捷方式保持；3 个正式索引文件的大小／时间戳／身份保持，没有打开正式 SQLite 或 ANN。原有未提交 `pubspec.lock` 及 `.runs/` 保留。

审计材料位于 `.dart_tool/cumulative-r37-20261022/`；`rollback/` 保存被替换的 r36 文件、原收据与完整程序 data，备份已核验，未实际回退。

未自动启动／重启／热重载 Studio，未生图或建库，未制作便携包或推送 GitHub。实际窗口体验由用户启动新版后确认。

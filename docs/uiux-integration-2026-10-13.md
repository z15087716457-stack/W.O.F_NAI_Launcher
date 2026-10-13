# UIUX 九页后端与现有正式源码整合（2026-10-13）

状态：候选源码整合与串行工程验收收口，等待前端收尾及桌面构建／实机验收；并发偶发回归另记。未构建、安装或替换运行包。

## 工作位置与来源

整合工作树：`E:/A.I/NovelAI/.devin/wt/ui-integration`，分支 `codex/uiux-integration`，基线 `ui-tools / 3e9c1c35`。逐文件观察九模块后端差异并处理共同接口；没有 merge 或 cherry-pick 分支，也没有复制各分支中较旧的锁定前端。

| 来源 | 分支 | 核对的提交 |
|---|---|---|
| nai-launcher-src | devin/gallery-redesign | `c6c1e48c34bbd81147d7932d4587a0368af3e6d0` |
| ui-shell | devin/ui-shell | `1f9e1bee62a892bc2431fb48d9ede06436687f85` |
| ui-online | devin/ui-online | `60bb82b4278b77ddc4ae8c3e01ccdea5cb7bfc41` |
| ui-refs | devin/ui-refs | `4ad2ece256aad0b72ed138fbf16617d810aeb1c8` |
| ui-blocks | devin/ui-blocks | `2058ac788033f818fdf3f0698ad8c23c5281f984` |
| ui-viewer | devin/ui-viewer | `50b16b6c92c72f840428d122d6465ae673827e69` |
| ui-style | devin/ui-style | `d90801e6a95f350eaef1a9f55716173204086bee` |
| ui-gen | devin/ui-gen | `4239282106c66dda52b58d0c9b0c3a13fd0ea27e` |
| ui-tools | devin/ui-tools | `3e9c1c358b5980aeef39e63ad4a25795399e3a7c` |

登记正式源码 `nai-launcher-src` 的 240 份相关已修改／未跟踪文件先按原字节备份，再按生产运行、修正与回归范围转入本候选；旧 checkpoint、独立 SDK 探针与旧 UI 捕捉脚本不转入。用户已授权同时保留 NAI Agent。正式源码还包括图库、桥接、存储与生成安全修正，不只 Agent；共同文件保留双方行为，不能用分支旧文件覆盖这些改动。生成输出使用登记 SDK 的受限入口重新生成。

## 共同接口处理

- 路由连接统计、导航、在线画廊、Vibe／精准参考、块库、大图、生图、画风探索与画布工具后端。保活切页关闭本地大图会话；生图／探索全屏保留各自窗口行为。
- 块库编辑、弹出面板、查看来源块统一走当前 BlocksActions／Wiring；来源块请求与最新选择保护保持。正式源码原有标签映射与存储写入准入继续生效。
- WindowChromePage 同时支持各后端的标题高度、全屏隐藏及主题接口。生图转场不重复绘制页宿主的窗口按钮，查看器无有效请求时也复用单一宿主；实际路由回归核对首页／生图／回退。实际主应用启用 Agent 集成作用域，生图页外部宿主复用已有 Agent 按钮、Dock、窗口扩展／精确恢复、锁定窗口覆盖行为。独立接线测试不初始化个人 Agent 存储。
- 生图保留 workflowOverride、重试快照与 Agent 冻结参数；导演工具统一 native admission，同时保留手动页面 canApply、取消及关闭等待；迟到结果不回写新页面或刷新计费。
- 画风探索同时保留正常化存取、取消完成等待及正式 beforeWrite／beforeGenerate 准入。桥接草稿签名保留 pill／img2img 身份与完整冻结工作流。
- 旧页面测试迁到当前接线与控件；补齐独立页 Material 宿主，替身隔离 palette、参考库目录等存储。保留无溢出、窗口拖动、主题对比与真实字体断言。
- 清理 230 个无生产引用的退役翻译键及孤立元数据，保留 Agent／探索实际使用的共享键；繁体资源与 l10n 输出由工具生成。没有依靠恢复退役页面来让测试通过。

## 保护与验收

421 份 `lib/presentation/ui`、`test/presentation/ui`（含契约／假数据／截图）、`tool/ui_shell` 文件逐项 SHA-256 核对；九个原来源工作树的 HEAD 和原修改／未跟踪文件字节核对。原工作树与正式运行包均未改动。

依赖使用登记 Flutter 3.47.7／Dart 3.13.5。`pub get --offline` 后与正式源码锁相比，intl 0.20.3、matcher 0.12.20、meta 1.19.0、test_api 0.7.12、vector_math 2.4.3 采用该 SDK 约束下的离线解析结果（matcher／test_api 为 SDK 精确固定，其余满足新 SDK 的最低约束）；没有执行 pub upgrade 或任意改依赖版本。原正式源码及各来源锁文件未动。Node 宿主仍使用原 package-lock、Pi 1.1.0 与 TypeBox 1.3.27；本机安装了固定依赖供合成回归使用，忽略 node_modules 与 `.runs`。

本机审计目录为 `.dart_tool/uiux-integration-20261013/`，保存来源清单、原字节、867 次文件组合记录、58 次／43 个路径冲突的双方版本、接口决策、生成／分析／测试日志。此目录不提交。

| 本候选验证 | 实际结果与边界 |
|---|---|
| Flutter 全目录 analyze | 最终无诊断；日志 `analyze-delivery-final.log` |
| Dart 格式 | 334 份变化／新增手写 Dart 分批检查，0 文件待格式化 |
| 受限代码生成与本地化 | 131 个声明输入；最终增量 build_runner 2 输出／6 actions，成功；此前完整范围复生成 129 输出／285 actions 同样成功。旧 analyzer 对新版 SDK 的提示保留，不升级生成工具。繁体资源 4 项通过，gen-l10n 完成 |
| Pi／Node 宿主 | 固定原 package-lock；43 项合成 HTTP／SSE、工具、MCP、会话测试通过 |
| 完整串行 Flutter 测试 | **5797 通过／5 跳过／20 失败**，日志 `full-serial-final.jsonl`；保留原失败断言，没有剔除用例 |
| 最终路由／Agent 外框／根主题复验 | **84 项通过**，日志 `final-route-host.jsonl`，覆盖完整 generation_wiring、5 项 Agent 宿主、studio_theme 与 app_test；上述全仓的 2 个新增实际路由失败在本最终独立进程中均通过 |
| 原源码与锁定前端 | 421 文件逐项原字节 SHA-256 不变；九个来源 HEAD、原修改／未跟踪文件不变 |

全仓数字如实保留，**不把局部复验折算成另一份全仓结果**。20 个失败中，18 个属于已有 FE-01／03／04：2 个英文精准参考 26px、6 个生图 352px 左栏 32px、10 个画布 390px 顶栏溢出。另 2 个为全仓执行期间新增的实际路由外框测试；生图转场和查看器回退的重复 WindowChromePage 已修正，最终新进程 84 项复验通过。FE-02 小图读取提示继续按既有纯前端证据登记，没有借本轮测试宣称修好。各模块旧通过数不作为本候选的验证。

混跑诊断保留：全仓并发 3 的一轮曾发生 CodeMode 模拟服务未收到请求；后续并发 2 的未完成混跑曾发生 pending backup 10 秒超时。核心套件并发 3 连跑 5 轮，每轮 65 项全通过，CodeMode 单项连续 5 次也通过。没有降低断言、延长超时或修改生产宿主；测试加入完成状态／message_end 诊断和“运行提前结束、尚未进入备份”的检查。串行验收可降低本机混跑负载，但不能据此声称偶发问题根因已确定。初次并发混跑的启动扩展 UI 10 秒超时亦保留在日志中，后续相关回归通过。

## 保留的前端任务

工作区 UIUX README 的 FE-01 英文精准参考 26px、FE-02 小图读取提示、FE-03 生图 352px 左栏 32px、FE-04 画布 390px 顶栏溢出保持登记。前端原断言、基准图与最小宽度未修改；英文／日韩定稿与窄窗布局另行处理。

本轮不调用真实生成、增强、云放大、付费编码或模型；Agent 测试使用本地合成 HTTP／SSE 与临时目录。没有启动、重启、热重载或操作 Studio，没有推送或替换桌面入口。下一交付边界为前端收尾及用户授权后的桌面构建／实机验收。

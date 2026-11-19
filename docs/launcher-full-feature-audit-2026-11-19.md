# Windows 启动器全模块审查 · 2026-11-18 至 19 日

Windows Release 使用独立访客资料。此次实际打开了全部 10 个主导航和 17 个设置页，用临时图片复测新图库，并单独启动真实检索和放大引擎。生图按本次约定只验本地链路。Windows 桥接客户端连接 Studio 的实际服务，由隔离的测试提供方回图，消耗 0 Anlas。安装版仍是 2.4.5+123。

## 本轮修复和复查

| 入口 | 复现与处理 | 验证 |
|---|---|---|
| 首次保存 → 图库 | 全新资料下，把图放入设置显示的默认保存目录，图库一直显示 0 张，手动刷新才出现。旧版迁移在没有遗留图片时也创建旧目录，图库监听因而选错位置。现在先准备当前保存目录，有旧图时才执行迁移。 | 全新 Release 第二次启动，在图库已打开时写入两张图，自动出现 2 张，「仅 NAI」为 1 张，关掉筛选又回到 2 张。[目录迁移回归](../test/presentation/wiring/settings_asset_paths_test.dart) · [自动同步实拍](../.dart_tool/full-feature-audit-20261118/44-gallery-both.png) |
| 设置 → 网络诊断 | 实际直连时仍显示「经过代理」，第三方账户可能测到官方图片域名，端点同域时还会产生重复组件键。现在诊断使用当前服务地址，按这次探测实际使用的代理显示结果，切换配置后丢弃已过期的结果。 | [端点与代理回归](../test/presentation/wiring/settings_backend_test.dart) |
| 设置 → 存储 | 全新资料未使用的内置目录（如 RAG 索引、放大模型）会使整个统计显示不完整，阻止快照保存。现在计为 0 B 并保存完整快照。缺失的用户自选库、读盘错误仍标为不完整。 | [空目录与离线参考库回归](../test/presentation/wiring/settings_storage_inventory_test.dart) |
| 图库 → 幻灯片与双图对比 | 路由收到的已选图片未传给两页。幻灯片自动翻过第一张就会停，空列表也可能触发下标异常。两页现在接收实际选图，空状态可以退出。自动播放能连续翻页，手动切换会暂停，图片数量变化时会校正位置。 | [路由回归](../test/presentation/router/gallery_view_routes_test.dart) · [播放与列表变化](../test/presentation/screens/slideshow_screen_test.dart) |
| 快捷键帮助与多语言 | 修正五种语言里失效的导航键位和可编辑范围说明，补齐别名提示的翻译参数。核查运行时、资源、工具和测试后，移除了 786 个废弃文案键。逐种语言核对保留下来的 5,885 个条目及其元数据、顺序。 | [多语言回归](../test/l10n/) |
| 生图与画风探索 → 块库侧栏 | 两个页面原先使用独立实现，本地语义查询和折叠记忆只在另一套通过测试的侧栏中生效。两个页面现共用块库检索与偏好接线，继续使用各自的草稿备份与插入逻辑。兼容旧版按使用次数记录的最近使用块。 | 在生图工作台的生成中状态点击侧栏块，验证备份、下一张正负提示词与最近使用。画风探索另检验备份、当前目标变更及双向块，拖到积木面板覆盖两种导航层级。[工作台点击](../test/presentation/wiring/generation_wiring_test.dart) · [语义检索、目录和折叠](../test/presentation/wiring/blocks_wiring_test.dart) · [拖入](../test/presentation/wiring/generation_palette_drag_test.dart) |
| 画风探索 → 分组及进化线 | 两个改名动作有后端接线，但用户右键菜单缺少入口。现在右键可以原地改名，支持回车提交和 Esc 取消。 | [分组及进化线控件回归](../test/presentation/ui/explore/explore_page_test.dart) |
| 设置 → 导入 NCNN 模型 | 文件选择只返回一份、返回同类文件或没有本地路径时，旧入口抛出通用错误。两个设置入口现在共用文件配对与本地化错误提示，反向选取 .param 和 .bin 也能导入。 | [文件选择与导入回归](../test/data/services/local_upscale_service_test.dart) |
| Studio 桥接命令行 | 客户端收到最后一条响应后暂停读流，关闭握手要等约 5 秒才结束。修正读取方式后，六次原生客户端调用从启动到退出均为 28–48 毫秒。 | 在相同隔离服务验证状态、草稿、报价、缺少授权拒绝、授权回图和复用报价拒绝。另用隔离进程固定退出回归。[原生客户端实测](../.dart_tool/full-feature-audit-20261118/bridge-updated.log) · [关闭回归](../test/core/krita/agent_bridge_integration_test.dart) |
| 测试维护 | 旧路径检查改为扫描当前界面文件，图像增强交互测试的尺寸断言对齐实际请求的 64 像素步长。 | [文案检查](../test/i18n/hardcoded_chinese_regression_test.dart) · [图像增强控件](../test/presentation/screens/generation/widgets/generation_controls/generation_controls_test.dart) |

## 验证范围

| 模块 | 验证内容与边界 |
|---|---|
| 启动、账户、导航、快捷键 | 实机走过首次启动、登录入口、跳过登录和主界面导航。对 57 个可改快捷键逐个执行改键、序列化、重读、禁用、恢复，并检查帮助中 35 项固定键和标识唯一性。窗口退出、冲突和分发另有组件回归。用两组虚构凭据（含非 ASCII 字符）交叉比对登录派生算法，线上身份认证不在本轮范围。 |
| 生图、编辑与画布 | 实机进入工作台。编辑器、补全与翻译、权重、选区、生图参数、批次取消与重试、参考图、历史和落盘走控件及服务测试。上一轮的逐张元数据、部分批次保留和 Vibe 回包归属一起纳入全量回归。实际桥接协议经测试提供方完成本地取图与落盘，拒绝未授权和重复请求；本轮未调用线上付费服务。 |
| 画风探索、块库、Vibe、精准参考 | 逐页打开实机界面。用控件或服务测试检查资源编辑、筛选、选择、导入、复用、模型配置与生成接线。 |
| 本地图库、查看器、统计、资源小窗 | 实机检查空库、自动发现图片、详情与筛选。样图详情显示 512 × 320 和种子 730105。收藏菜单已打开，实机未核实本次点击收藏后的持久化。时间线、收藏、删除池、搜索分页、详情、幻灯片、对比和统计另有自动化覆盖。四个 Windows 原生测试源也已编译，窗口几何静态断言及三个可执行测试通过，涵盖主窗与小窗的层级、窗口展开以及渲染表面尺寸。 |
| 在线图库 | 实机进入页面。独立联网读取 AI TAG 公开配置、作品和图片，检查原图和缩略图 HTTP 200、WebP 解码为 832 × 1216、写入并读回临时收藏库。 |
| 标签百科、补全、RAG | 实机进入已装词库的标签百科及语义检索设置。用本机 EmbeddingGemma 2 和 CUDA 在隔离目录建标签、Wiki、块、图库四种索引。两个独立 worker 进程均查回同一组目标，图库分别走图片和参数检索。随后只清理测试标签库并检查其他库。另跑 169 项 Python 测试，包括 5 项固定版 DanbooruSearch 差分。 |
| 设置、账号、端点、模型服务商 | 逐页打开概览、账号、外观、画布、快捷键、生成、存储、词库、模型与接口、Agent、语义检索、本地放大、桥接、网络、隐私、备份、关于。网络探测实际运行。编辑保存与撤销、服务商模型、缓存、备份迁移、重启状态与更新下载生命周期有临时目录或替身测试。 |
| Agent、工具、宿主集成 | 核查 24 个 Studio 业务工具、13 种 RAG worker 操作。另在临时工作区用安装的 Pi SDK 实际执行 read、write、edit、bash 四个内置工具，并核对编辑后的文件内容。Pi / Node 160 项、Krita 插件 139 项、桥接脚本 8 项、语料配置 9 项、Windows 打包 3 项通过。在本机独立启动 ComfyUI 验证实例，用 Studio 自己的 HTTP 和 WebSocket 客户端上传图片、入队缩放、接收进度并通过历史记录取回 120 × 80 PNG。实例已退出。Krita 插件在隔离配置中完成打包、安装和启用检查。实测范围到本地桥接与隔离的插件配置，正式 Krita 宿主内的画布和图层往返未验。[Krita 验收明细](../.dart_tool/full-feature-audit-20261118/krita-preflight.md) |
| 本地放大 | Vulkan 实机验证透明通道、非整数倍率及取消子进程。取得并校验官方可选模型包后，在临时目录完成安装与实际放大。SeedVR2 3B FP8 使用本机已有权重和 CUDA 完成实际推理，解码结果为 512 × 512。INT8 检查 7 项通过，含 CUDA 内核。RTX 用产品下载器在无缓存的临时目录完成官网下载、校验、安装和硬件探测。另用已核对摘要的包经完整服务执行 1.75 倍放大，输出 448 × 336，透明度检查通过。最初自写下载脚本指定额外请求头收到 HTTP 401，产品下载器实测成功。 |
| 多语言、主题和平台 | 对照深浅色及窄窗的已批准截图，逐图保留当前、基准与差分。静态分析和 Windows Release 构建通过。本机没有 macOS Finder，未做该平台的系统集成验证。 |

## 可复核的记录

- [入口清单](../.dart_tool/full-feature-audit-20261118/feature-inventory.tsv) 包含 16 条路由声明、10 个主分支、17 个设置页面、66 个标量设置键、635 个 UI 回调、57 个可改快捷键、35 个固定快捷键、24 个 Studio 业务工具和 13 种 worker 操作，共 873 项，类别有交集。Pi 自带的四个工具另见[隔离实测](../.dart_tool/full-feature-audit-20261118/pi-four-local.log)。
- [生产接线表](../.dart_tool/full-feature-audit-20261118/callback-wiring.tsv) 登记各回调的后端绑定。[界面使用位置](../.dart_tool/full-feature-audit-20261118/ui-action-reads.tsv) 通过 Dart 类型解析核对界面侧对同名回调的真实引用，区分函数调用和传递。审查前 636 项中有两项改名缺界面入口、一项旧弹窗回调只存在于停用实现。修复后重扫 387 个 Dart 单元。22 类动作契约的 635 项都有生产绑定和界面引用，共 1,203 个使用位置。每个回调的直接调用和传递位置、相应行的执行采样可在[逐项对照](../.dart_tool/full-feature-audit-20261118/ui-action-coverage.tsv)中复核。全量测试在 553 项回调的界面使用位置采到执行行，307 项采到直接调用所在行。传递回调、执行所在行与手工逐项点击是不同口径。
- [逐项 Flutter 测试](../.dart_tool/full-feature-audit-20261118/test-results-current.tsv) 与[分区覆盖](../.dart_tool/full-feature-audit-20261118/coverage-area-current.tsv)记录本次最终全量自动化。10,878 项通过，16 项截图比对失败，6 项默认跳过。覆盖运行在 1,416 个文件中记录 181,410 / 235,939 行，约 76.89%，含生成代码。默认跳过的 6 项中，在线图库、两个 Vulkan 测试、可选模型安装及 RTX 服务 5 项另行实测通过。macOS Finder 集成需要对应平台。
- 16 项截图与已批准基准存在差异，涉及通道弹层 3 项、生图显示菜单 1 项、设置布局和状态 12 项。已检查裁剪对照，差异包括画布适应文字、显卡状态、来源开关、搜索和存储设置等。[截图对照](../.dart_tool/full-feature-audit-20261118/goldens/)
- 原先失败的旧语言键检查已通过。跨资源[引用审查](../.dart_tool/full-feature-audit-20261118/l10n-consumers.tsv)、[五语种保留条目校验](../.dart_tool/full-feature-audit-20261118/l10n-unchanged.json)与[RAG 设置及语言回归](../.dart_tool/full-feature-audit-20261118/l10n-clean-check.log)可分别复核。
- [实际 GPU 建库与重启查询](../.dart_tool/full-feature-audit-20261118/rag-four.log)、[ComfyUI 上传至回图](../.dart_tool/full-feature-audit-20261118/comfy-live.log)、[RTX 全新安装](../.dart_tool/full-feature-audit-20261118/rtx-clean-install.log)、[RTX 放大](../.dart_tool/full-feature-audit-20261118/optional-rtx.log)、[SeedVR2 出图](../.dart_tool/full-feature-audit-20261118/seed-live.log)、[Windows 原生窗口](../.dart_tool/full-feature-audit-20261118/native-cpp.log)及[快捷键核对](../.dart_tool/full-feature-audit-20261118/shortcuts-all.log)均已落盘。最终 [Windows Release 构建](../.dart_tool/full-feature-audit-20261118/build-final-local.log)与[静态分析](../.dart_tool/full-feature-audit-20261118/analyze-final-local.log)通过。
- 原始日志、截图和临时索引在本机忽略目录 [.dart_tool/full-feature-audit-20261118](../.dart_tool/full-feature-audit-20261118/)。[前一轮系统审查](launcher-system-audit-2026-11-18.md)另记批量落盘、取消、更新、资源小窗和显卡探测等修复。

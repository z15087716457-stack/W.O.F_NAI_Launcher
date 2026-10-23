# 窗口外边框缩放优化 · 2026-10-23

> 已废弃：2026-10-23 用户实机反馈切换页面后再次拖动仍卡顿，要求停止这波修复并回到 +44。下文仅作实验历史；当前状态见[撤回记录](native-window-resize-abandoned-2026-10-23.md)。

> +45 历史记录：用户反馈拖动时整页变形，已由[正常比例实时布局](native-window-live-resize-2026-10-23.md)替代。后续实验见[+46 历史交付](cumulative-2.1.1-live-resize-2026-10-23.md)。

用户要求修复整个窗口外边框拖动卡顿，不加防御性兜底；修好先安装桌面，由用户检查后再发布 2.1.1。此前内部四条分隔条的修复继续保留。

## 实现

主应用 Navigator 外新增 `WindowResizeViewport`，直接使用现有 window_manager 的原生 `resize`／`resized` 事件：

- 第一次 `WM_SIZING` 后保留已布局的逻辑尺寸及 MediaQuery.size；拖动中的后续尺寸仅改变合成变换，不反复重排页面。
- 内容放在 RepaintBoundary 内，通过矩阵图像过滤缩放绘制层，暂停该子树动画；窗口新区域铺满当前内容。拖动时内容会临时随窗口拉伸，松手后恢复按实际尺寸排版。
- `WM_EXITSIZEMOVE` 后按最终窗口尺寸布局一次并恢复动画。整个过程保留 Navigator、编辑器、滚动位置和业务状态；后台任务继续运行。
- 非拖动的窗口尺寸变化仍即时布局，包括最大化、还原和 Agent 原生展开。只监听现有原生事件，没有轮询、超时、失败重扫或降级开关。
- 本次不修改原生 runner、SDK、依赖、用户设置和内部拖动预览线。版本为 `2.1.1+45`，公众版本仍是待发布的 2.1.1。

Windows 的尺寸变更消息及拖动结束事件见 [WM_SIZE](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-size)、[WM_EXITSIZEMOVE](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-exitsizemove)。Flutter 的 Windows 渲染尺寸同步见 [引擎实现](https://api.flutter.dev/windows-embedder/flutter__windows__view_8cc_source.html)。

## 原生对照

使用登记 SDK 的隔离 Profile 窗口，真实页面组件、合成图片和内存设置，200 张合成历史、通道与侧栏背景保留。单个编译包通过运行参数切换是否挂载该视口，原生定时器逐步发送 WM_SIZING、SetWindowPos 和 WM_EXITSIZEMOVE，每边 120 步。没有操控用户 Studio 或鼠标。

三轮 before→after 交替，显示器 144Hz，初始渲染尺寸 1584×961。下表为三轮各自 P95 的中位数，测量窗口线程完成一个缩放步骤的耗时，不是屏幕 FPS：

| 外边框 | 原版 P95 | 修正后 P95 | 减少 |
|---|---:|---:|---:|
| 右边 | 35.49ms | 20.97ms | 40.9% |
| 左边 | 35.96ms | 20.64ms | 42.6% |
| 底边 | 36.81ms | 20.34ms | 44.7% |
| 右下角 | 37.68ms | 20.77ms | 44.9% |

拖动期间构建中位数约 4.7–5.2ms → 0.11ms。缩放仍有合成和渲染表面的成本，不宣称零耗时或稳定 144fps。用户原应用和其他 GPU 活动未停止，负载记录随每次样本保存，因此绝对数值仅代表本次条件。

12 项新增组件测试通过：五种方向／尺寸多步拖动时 build／layout 不增加，松手只布局一次；草稿及编辑器实例保持，非拖动尺寸变化实时生效，取消／再次拖动、明暗内容无空边、动画恢复、DPI 变化和订阅释放。

证据位于 `.dart_tool/native-resize-20261023/`：`paired-*-summary.json`、原始帧及步骤样本、`paired-comparison.json`、`paired-load.json`、`viewport-tests.log`。源码与交付的后续全量验证、安装结果另记本机交付报告。

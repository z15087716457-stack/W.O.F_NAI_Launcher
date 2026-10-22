# 分隔条拖动改为预览线 · 2026-10-22

用户反馈：拖动 Agent 侧栏分隔条时整个启动器很卡，松手后恢复。用户选择方案 A 并说“开工，搞完就推送更新”。勘察由 DeepSeek v4.1 Flash（max）完成，后端由 GPT 6.1 Sol（xhigh）实现，主窗口复核。源码提交 `c8724266a`，随 r37 安装。

## 根因

每次指针移动都 `setState` 新宽度，导致生图页（或画风探索页）整行按新宽度重建和重排：画布通道背景整幅重绘（`ChannelViewData` 没有相等比较，`shouldRepaint` 总是返回 true），两侧 sigma 10 预模糊重新栅格化，三条玻璃工具条的 `BackdropFilter` 重新采样，左栏和历史栏重建，Agent 缩略图跨尺寸分档时重新解码。松手后不再变宽，所以恢复流畅。

## 最终行为

- 四个分隔条共用 `lib/presentation/widgets/common/drag_preview_divider.dart`：Agent 侧栏（`nai-agent-resize`，生图页和画风探索页）、生图左栏（`gen-left-resize`）、生图历史栏（`gen-history-resize`）、画风探索编辑列（`explore-editor-resize`）。
- 拖动中只有一条全高 2px 强调色预览线（0.8 透明度）跟随指针，放在独立的 `RepaintBoundary` 里。页面、画布、背景、工具条和 Agent 内容都保持原宽度，不重建也不重排。鼠标离开 8px 手柄后，光标仍保持列宽调整样式。
- 预览线按松手后的真实位置夹取：Agent 用 `AgentPanelLayout.resolve`，生图页复用原响应式压缩规则（抽成预览与布局共用的纯函数），探索页计入舞台最小宽度。
- 松手后一次性应用新宽度，然后走原持久化入口；预览线与新布局在同一帧切换。取消、Esc、零位移拖动都不改宽度、不写设置。生图页仍保存用户期望宽度，窄窗口的临时压缩不写回偏好。
- 命中区域、key、悬停高亮、Agent 展开动画和原生窗口路径都不变；块库侧栏的另一个 `ResizeHandle` 调用保持实时拖动。

## 验证

- 新增 25 项测试，覆盖四个手柄的多步拖动：拖动中内容的 build／layout 计数不增加，松手只提交一次，预览线与最终位置一致；取消、Esc、零位移、深浅主题实绘和光标也已覆盖。
- GPT 运行 Agent／wiring／生图／探索／生成页范围回归，1700 项通过，2 项失败为已登记的 `tools_wiring` 既有超时。主窗口复跑相关 562 项，全部通过；探索页“0.3 秒内双击”测试依赖真实时钟，并发时偶发超时，单独运行 36 项全部通过。`flutter analyze --no-pub lib test` 无问题。
- 隔离 Profile 探针（144Hz、1584×961，200 张历史，通道和侧栏背景全开）新增 `panel_drag` 用例，用真实指针拖动历史栏分隔条。三轮中位数：引擎 total P95 **147.9 → 62.4 ms**，raster P95 76.6 → 38.3 ms，build P95 16.0 → 10.0 ms。原有拖画布、滚轮、缩放的 total／raster 没有变差。数据在 `.dart_tool/canvas-frames-20261016/drag-*`。
- 测量时本机 GPU 正被其他游戏占用（约 99%），绝对数值整体偏高，只适合同条件前后对比。这些是引擎 FrameTiming，不是屏幕实际 FPS；松手那一帧仍需要一次完整布局。

# 确认费用卡视觉修正

仅源码完成，未构建／安装；桌面仍为 **2.3.4+103**。

- 移除标题前的生成图标，释放 22px，使标题沿卡片原有左边距对齐。
- 费用图标复用已有 `assets/icons/nai-icon-anlas.svg`，替换独立手画的水滴；保留 14px 尺寸与主题前景色。
- 132 项相关检查通过（Agent 面板布局／交互、UI 分层与 2 项本地实绘），两份改动源码静态分析 0 问题。没有改费用计算、授权、倒计时或生成回调，没有调用生图接口。
- 深浅色改前／改后批量测量：扣除标题左移 22px 的有意变化后，卡片、费用数字、确认和取消按钮的几何残差最大 0px；标题与费用图标范围外的变化像素为 0。248 个其他已有路径内容保持，原基准 PNG 未改。

本机证据：`.dart_tool/agent-cost-card-20261115/` 下的 `verified-tests.log`、`analyze.log`、`measurement.json` 和改前备份。已查看[深色实绘](../.dart_tool/agent-cost-card-20261115/after-captures/gate-dark.png)，另保留[浅色实绘](../.dart_tool/agent-cost-card-20261115/after-captures/gate-light.png)。本次是局部组件改动，测量以同场景改前实绘为基准，不宣称整页 HTML 原型叠对。

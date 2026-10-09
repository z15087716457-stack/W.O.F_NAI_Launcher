# 浅色字体字缘补偿独立试验

2026-10-10，Asia/Taipei。用户授权先尝试、效果不好可退回。本轮只制作独立字体样例与本地审查材料，没有安装、启动、热重载或修改生产 Studio，没有修改字体、主题字号或 Flutter 引擎。

## 结果

- Flutter 3.47.7 / Dart 3.13.5 的独立 Windows Release 构建成功，实际原生进程确认 shader filter 可用；同一工程显式切到 Skia 时该能力为 false，并自动停用滤镜。
- 同字体文件、字号、字重、行高和间距下，浅色补偿 0.90 / 0.80 / 0.70 的中性文字区域归一化对比度总量约增加 4.30% / 9.15% / 14.38%。该指标来自无损图片，辅助观察浓度，不是字重、真实 glyph alpha 或与原型的吻合度。
- 深色不执行额外滤镜；三个强度的中性文字区域与原始列逐像素相同。Skia 的对应文字区域也逐像素相同。此结果只说明试验的回退保留原始字体，不能解释为已经与浏览器 ClearType 完全一致。
- 强度为 1 的额外滤镜仍会改变部分字缘像素，归一化对比度总量约 -0.049%；因此不把恒等滤镜当成逐像素无影响的路径。真正关闭效果使用 `ImageFiltered.enabled=false`，控件祖先结构保持稳定。
- Windows 输入框现场确认键盘事件与当前输入法候选能到达控件，Enter 提交后能写入。批量 Unicode 注入未成功，未计为输入法全量验证；本轮也未宣称输入选区、其他系统 DPI 与生产性能通过。
- 独立 Dart 分析无诊断，构建与浏览器对照页检查通过。未运行与独立实验无关的主工程全量回归。

## 实现与范围

通过应用层 `ImageFilter.shader` 对独立的透明文字图层执行 `a' = pow(a, exponent)`，按新 alpha 重新预乘同一个文字颜色。端点 0 / 1 与实心文字颜色保持；字号、字重和排版输入没有变化。外层 `Opacity` 在补偿后合成，不能把文字内部的所有透明度都当成字形覆盖率。

当前 Windows 实测路径无需手动翻转 shader 输入的 Y 轴。照搬通用 OpenGLES 示例的翻转会使各文字层上下颠倒，已在本机修正。这里只验证 Windows，不推定其他平台适用。

此方法仍使用灰阶字缘，不能创造 ClearType 的 RGB 子像素覆盖率。不能给整个应用套用该滤镜；选择高亮、光标、混合透明 spans、图片和半透明背景需要分别处理，大量文字层的重绘与 GPU 成本尚需实测。

官方 API 依据：[ImageFilter.shader](https://api.flutter.dev/flutter/dart-ui/ImageFilter/ImageFilter.shader.html)、[自定义 shader](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)。未维护自定义 Flutter 引擎。

## 审查材料与回退

- 工作区材料：`04_工具/字体覆盖率试验/2026-10-10/index.html`，本地服务 `http://127.0.0.1:8783/index.html`。
- 左列是按原型字体配置实时绘制的浏览器字体样例，不是完整原型页面；中、右列是原生进程 RepaintBoundary 的无损快照。默认浅色、0.80、1:1，可选其他强度与“关闭 / 退回原始”。
- `verification.json` 记录字体 SHA256、原生 PID / DPR / viewport / 后端能力、指标与回退检查。桌面窗口证据由 computer-use 采集，实际格式为 JPEG，不用于精确像素比较。
- 独立工程与原始结果：有效源码 `.dart_tool/typography-coverage-2026-10-10/`。可复用代码仅在 `tool/typography_coverage_probe/`，未进入生产 `lib/` 或主工程资源清单。

全局接入尚未开始；UIUX 检查点五继续等待原有审查，不推进下一段。

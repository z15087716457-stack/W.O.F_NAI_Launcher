# 浅色字体字缘覆盖率试验

独立 Windows 字体样例，尚未接入生产界面。目标是保留原型的字体文件、字号、字重和间距，只检查浅色字缘的浓度补偿。用户授权“尝试一下，不行再退回”。

- `main.dart`：HarmonyOS Sans SC、Geist、Geist Mono 的 400–700 字重、灰字、彩色文字、富文本、外层透明度与独立编辑框。
- `text_coverage.dart`：仅包裹文字层。保持控件祖先结构，通过 `ImageFiltered.enabled` 停用效果；深色与不支持 shader filter 的后端不进行额外滤镜绘制。
- `shaders/text_coverage.frag`：`a' = pow(a, exponent)`，取 1 / 0.9 / 0.8 / 0.7；保留未预乘的文字颜色。不要包裹整页、图片、背景、混合透明 span 或选区背景。
- `build_review.py`：从原生进程的无损快照生成本地对照页，保留透明圆角，复制相同字体文件，计算固定文字区域的对比度指标与回退检查。

本机独立工程位于 `.dart_tool/typography-coverage-2026-10-10/probe/`，Windows runner 显式选择 `flutter::ImpellerSwitch::Enabled`，传 `--renderer=skia` 时选择 Disabled。工程的字体声明从已经验证的字体探针继承，字体文件从当前 `assets/fonts/` 原样复制。不能从此工程安装或更新 Studio。

登记 SDK 为工作区 `.devin/sdk/flutter-3.47.7`，用 `scripts/flutter_studio.ps1 -SdkRoot ...` 校验版本后执行。编译时传 `--dart-define=PROBE_OUTPUT=<独立结果目录>`。运行参数包括 `--case=light`、`--dark`、`--identity`、`--renderer=skia`；窗口也提供明暗与恒等滤镜开关。

若从新的 Windows template 重建，应把本目录两个 Dart 文件复制到工程 `lib/`，shader 复制到 `shaders/` 并在 pubspec 的 `flutter.shaders` 中登记；字体声明和实际文件必须与当前主工程一致，并给 Windows runner 加上上述明确的后端选择。仅升级 SDK 的默认 runner 不代表启用了 Windows Impeller。

结果说明见 [实验记录](../../docs/typography-coverage-experiment-2026-10-10.md)。正式接入仍需确认原型观感、其他系统 DPI、输入法与选择高亮、混合透明文字和性能。

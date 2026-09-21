# W.O.F NAI Studio · 品牌素材

## 字体

| 用途 | 字体 |
|---|---|
| 标题栏 NAI Studio | 旧版普通文字，13px / w500，黄色双下划线，左边距 12px，Logo 与文字间距 8px |
| 正文与控件 | Geist Sans + HarmonyOS Sans SC fallback，400 / 500 / 600 / 700 |
| 参数、尺寸、快捷键、代码 | Geist Mono + HarmonyOS Sans SC fallback，400 / 500 |

`StudioTypography` 负责正文、控件与等宽数据字体，应用统一使用 Geist 深浅两套主题，共用离线 Geist / HarmonyOS 字体。显式系统 / Google 字体选择仍有效，旧默认键 `system`、空键使用应用默认组合。只有标题栏 NAI Studio 使用旧版普通字体和黄色双下划线，不采用像素体；黄线是显式样式，不依赖上层 Material 缺省样式。字体许可在 `assets/licenses/` 和应用「关于 → 界面字体与许可」。

界面图标已全部恢复原有 Material `Icon` 和已有专用符号。不要重新引入被撤回的 Geist SVG 注册表。

## Logo 与 Windows 图标

- `assets/images/wof_logo_full.png`：原品牌完整 Logo，只移除外围透明留白，保留 W.O.F 与 NAI STUDIO 的原始比例和字形。源文件来自工作区品牌资产 `wof_logo_full.png`，取原图 `(0, 328, 1111, 547)` 区域。
- `assets/images/wof_logo_block.png`：旧版完整蓝色 W.O.F 长块，用于标题栏，显示高度 20px、宽度按原图比例，旁边搭配普通文字 NAI Studio。
- Windows ICO 分两个角色：运行 `node tool/branding/generate_windows_icons.cjs`（依赖 sharp）。桌面 / Explorer 用 `app_icon.ico`（完整长方形 Logo 等比置于透明方框，资源 ID 101）；窗口 / 任务栏和托盘用 `window_icon.ico`（`assets/icons/wof_icon.svg` 方形 W，资源 ID 102）。两套各十档 16–256px，同时导出原生资源与 Flutter assets；可用 `--brand-dir <目录>` 导出独立完整 Logo 尺寸库。
- ICO 改动必须重编原生 Windows runner，并检查 EXE 中两套 RT_GROUP_ICON / RT_ICON 与各自源 ICO 一致。窗口通过 WM_SETICON 分别设置大小图标，并按 DPI 加载合适尺寸，避免 Explorer 与运行中任务栏共用一份图。

## 登录与载入

`BrandEntryScene` 提供完整 Logo、留白、边缘几何细节和明暗切换；`GeistTheme` 提供与工作区一致的黑白灰配色与有边界的表单控件。登录方式用紧凑页签，已有账号用紧凑账号卡。载入进度直接读取 WarmupState，显示真实进度、任务和错误信息，不制造假进度或无休止的装饰动画。

明暗选择由 `themeNotifierProvider` 持久化到 `studio_theme_mode`，载入、登录、标题栏、工作区与弹窗共同继承；入口按钮、设置和快捷键切换同一状态。登录验证、账号保存、第三方地址、游客状态和预热调度仍由现有 provider 负责。

## 验证

- `test/presentation/screens/brand_entry_test.dart`：真实登录 / 载入 widget，深浅色、三种语言、390px 窄屏和 125% 字号、登录方式切换、明暗切换保留输入、游客入口、已保存账号、真实进度。
- `studio_visual_system_test.dart`：离线字体、CJK 回退和显式字体选择兼容。
- `integrated_title_bar_test.dart`：完整 Logo、标题、原图标与原生标题栏命中区。

设置 `CAPTURE_STUDIO_UI=1` 运行入口测试，会把实际字体 / Logo 的渲染保存到 `.dart_tool/brand-entry-captures/`。这些是 widget 渲染，不应冒充运行中的用户窗口截图。

## Geist 色彩与层级

依据 [官方色彩](https://vercel.com/geist/colors)、[材质](https://vercel.com/geist/materials) 与 [字体规范](https://vercel.com/geist/typography)，使用纯黑 / 纯白页面、低对比灰阶面板、细边框和蓝色操作强调。`GeistTheme` 显式设置所有 Material surface/container 槽及透明 surfaceTint，避免种子色或弹层海拔把大面积背景染蓝。

- 深色：背景 `#000000`，分区 `#0A0A0A`，浮层 `#111111`，控件 `#1A1A1A`；正文 `#EDEDED`，次级文字 `#A0A0A0`。
- 浅色：背景 `#FFFFFF`，分区 `#FAFAFA`，控件 `#F2F2F2`；正文 `#171717`，次级文字 `#666666`。
- 主要按钮沿用品牌蓝 `#005DFF` 配白字；可交互文字 / 焦点使用深色 `#50A8FF`、浅色 `#0064E2`。大容器选中底色仍用中性灰。
- 常规控件 6px 圆角，菜单 / 对话框 12px。正文 / 标签 14px，辅助文字 12–13px；保留已验收的生图侧栏紧凑层级。
- `test/presentation/themes/studio_theme_test.dart` 覆盖磁盘恢复、根路由与保活页面、弹窗和快捷键切换；`studio_workspace_theme_test.dart` 实绘图库、块库与主题选择器，注入测试数据，不读取用户库。

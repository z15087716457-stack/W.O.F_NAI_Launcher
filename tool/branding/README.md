# W.O.F NAI Studio · 品牌素材

## 字体

| 用途 | 字体 |
|---|---|
| 标题栏 NAI Studio | Geist Pixel Line，20px |
| 正文与控件 | Geist Sans + HarmonyOS Sans SC fallback，400 / 500 / 600 / 700 |
| 参数、尺寸、快捷键、代码 | Geist Mono + HarmonyOS Sans SC fallback，400 / 500 |

`StudioTypography` 定义角色，16 套工作区主题保留原有配色，共用离线字体。HarmonyOS 原始 TTF 完整打包，不裁切、不改写。显式选择的系统 / Google 字体仍有效；旧默认键 `system`、空键映射到应用默认组合。许可在 `assets/licenses/` 和应用「关于 → 界面字体与许可」。

界面图标已全部恢复原有 Material `Icon` 和已有专用符号。不要重新引入被撤回的 Geist SVG 注册表。

## Logo 与 Windows 图标

- `assets/images/wof_logo_full.png`：原品牌完整 Logo，只移除外围透明留白，保留 W.O.F 与 NAI STUDIO 的原始比例和字形。源文件来自工作区品牌资产 `wof_logo_full.png`，取原图 `(0, 328, 1111, 547)` 区域。
- `assets/images/wof_logo_block.png`：完整蓝色 W.O.F 长块，用于标题栏，旁边搭配 Pixel Line 的 NAI Studio。
- Windows ICO：运行 `node tool/branding/generate_windows_icons.cjs`（依赖 sharp）。完整长方形 Logo 等比置于透明方框，十档 16–256px，不裁成单个 W。程序资源和托盘 ICO 同步输出；可用 `--brand-dir <目录>` 导出独立完整 Logo 尺寸库。
- ICO 改动必须重编原生 Windows runner，并检查 EXE 中 RT_GROUP_ICON / RT_ICON 与源 ICO 一致。

## 登录与载入

`BrandEntryScene` 提供完整 Logo、留白、边缘几何细节和明暗切换；`BrandEntryTheme` 提供蓝黑 / 蓝白配色与有边界的表单控件。登录方式用紧凑页签，已有账号用紧凑账号卡。载入进度直接读取 WarmupState，显示真实进度、任务和错误信息，不制造假进度或无休止的装饰动画。

明暗选择只存在当前会话，由载入页延续到登录页；工作区配色独立。路由切换时标题栏同步入口主题，进入工作区恢复已选主题。登录验证、账号保存、第三方地址、游客状态和预热调度仍由现有 provider 负责。

## 验证

- `test/presentation/screens/brand_entry_test.dart`：真实登录 / 载入 widget，深浅色、三种语言、390px 窄屏和 125% 字号、登录方式切换、明暗切换保留输入、游客入口、已保存账号、真实进度。
- `studio_visual_system_test.dart`：离线字体、CJK 回退和旧字体选择兼容。
- `integrated_title_bar_test.dart`：完整 Logo、标题、原图标与原生标题栏命中区。

设置 `CAPTURE_STUDIO_UI=1` 运行入口测试，会把实际字体 / Logo 的渲染保存到 `.dart_tool/brand-entry-captures/`。这些是 widget 渲染，不应冒充运行中的用户窗口截图。

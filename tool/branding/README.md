# W.O.F NAI Studio · 品牌素材

## 字体

| 用途 | 字体 |
|---|---|
| 标题栏 NAI Studio | 旧版普通文字，13px / w500，黄色双下划线，左边距 12px，Logo 与文字间距 8px |
| 正文与控件 | Geist Sans + HarmonyOS Sans SC fallback，400 / 500 / 600 / 700 |
| 参数、尺寸、快捷键、代码 | Geist Mono + HarmonyOS Sans SC fallback，400 / 500 |

`StudioTypography` 负责正文、控件与等宽数据字体，应用统一使用 Geist 深浅两套主题，共用离线 Geist / HarmonyOS 字体。显式系统 / Google 字体选择仍有效，旧默认键 `system`、空键使用应用默认组合。只有标题栏 NAI Studio 使用旧版普通字体和黄色双下划线，不采用像素体；黄线是显式样式，不依赖上层 Material 缺省样式。字体许可在 `assets/licenses/` 和应用「关于 → 界面字体与许可」。

功能图标统一使用 `lib/presentation/widgets/common/studio_icons.dart` 的 `StudioIcons`：画风探索为遗传分支，块内遗传动作为双螺旋，在线画廊为图片＋地球，提示词块为模块网格，精准参考为人物叠卡，Vibe 为图片到笔触的传递。本地画廊沿用原在线画廊的 Material 叠图符号。侧栏、标题、块默认图标、菜单和参考面板复用同一造型；网格布局、通用文件夹、保存动作与用户自选块图标保持各自语义。

SVG 母版在 `tool/branding/studio_icons/`；`generate_studio_icons.py` 将描边转轮廓生成 `assets/fonts/StudioIcons.ttf`，并同步精准参考 / Vibe 两份已有 SVG 资源。Flutter 原生 `IconData` 与 SVG 消费者因此保持一致，无额外运行时依赖。复建命令见脚本开头，码位只追加、不重排；母版修改后必须重新生成字体和两份 SVG。矢量图标按主题继承颜色与尺寸，不能把预览图切成位图用于控件。

左侧主导航按用途分三组：生图 / 画风探索；本地图库 / 在线画廊 / 提示词块 / Vibe 库 / 精准参考库；统计。组间使用中性细线与留白，收起和展开状态共用分组顺序；设置与账户等底部操作保持固定。导航显示顺序独立于路由分支和快捷键映射。

## Logo 与 Windows 图标

- `assets/images/wof_logo_full.png`：原品牌完整 Logo，只移除外围透明留白，保留 W.O.F 与 NAI STUDIO 的原始比例和字形。源文件来自工作区品牌资产 `wof_logo_full.png`，取原图 `(0, 328, 1111, 547)` 区域。
- `assets/images/wof_logo_block.png`：旧版完整蓝色 W.O.F 长块，用于标题栏，显示高度 20px、宽度按原图比例，旁边搭配普通文字 NAI Studio。标题栏高 36px，Logo 与文字垂直居中，Logo 上下各留 8px；不缩放 Logo 或标题字体。
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

参考 [官方色彩](https://vercel.com/geist/colors)、[材质](https://vercel.com/geist/materials) 与 [字体规范](https://vercel.com/geist/typography)，使用柔和炭灰 / 纯白页面、分层灰阶面板、细边框和蓝色操作强调。深色采用适合长期创作的中性炭灰，不使用纯黑铺底。`GeistTheme` 显式设置所有 Material surface/container 槽及透明 surfaceTint，避免种子色或弹层海拔把大面积背景染蓝。

- 深色：背景 `#181818`，分区 `#202020`，卡片 / 浮层 `#262626`，控件 `#303030`，悬停 `#363636`，选中 `#3D3D3D`；正文 `#E4E4E4`，次级文字 `#A8A8A8`，边框 `#3B3B3B`。
- 浅色：背景 `#FFFFFF`，分区 `#FAFAFA`，控件 `#F2F2F2`；正文 `#171717`，次级文字 `#666666`。
- 主要按钮沿用品牌蓝 `#005DFF` 配白字；可交互文字 / 焦点使用深色 `#50A8FF`、浅色 `#0064E2`。大容器选中底色仍用中性灰。
- 常规控件 6px 圆角，菜单 / 对话框 12px。正文 / 标签 14px，辅助文字 12–13px；保留已验收的生图侧栏紧凑层级。
- `test/presentation/themes/studio_theme_test.dart` 覆盖磁盘恢复、根路由与保活页面、弹窗和快捷键切换；`studio_workspace_theme_test.dart` 实绘图库、块库与主题选择器，注入测试数据，不读取用户库。

## 磨砂材质

标题栏、角色提示词分区的总栏，以及图生图 / 风格迁移 / 精准参考共用 `StudioGlassSurface` 的烟灰 / 乳白渐变、静态细颗粒及边缘高光。浅色卡片使用更明确的中性灰渐变底部。添加角色后的独立编辑卡保持原有不透明表面、头部底色、选中边框、焦点与编辑器，不使用磨砂。文字、图标和按钮保持清晰，画布与其他页面保持不透明。

三个参考面板收起且有图时使用原图背景与轻磨砂（2.4px 模糊、暗遮罩与微弱高光），展开后恢复纯材质表面，不对整窗或文字做实时模糊。背景 `DecodedMemoryImage` 显式启用 `decodeForCover`，由原图宽高与控件物理尺寸计算覆盖裁切需要的解码尺寸，保留比例且不放大低分辨率原图，最长边上限 4096px；其余使用处的解码行为不变。Vibe 优先原图，仅在无原图时回退既有缩略图，不能凭缩略图恢复丢失的细节。

浅色原生标题栏使用 48–58% 乳白遮罩；深色使用 42–50% 近黑遮罩，让原生模糊后的背景颜色更明显地透出。原生标题不再额外绘制颗粒，边缘高光也更弱，避免在系统材质上重复叠出厚重雾感；应用内卡片仍保留自己的材质。这里的百分比是 Flutter 染色层不透明度，实际透景仍叠加 Windows 原生材质；当前 DWM 接口只选择系统材质，没有单独调整模糊半径。非原生表面始终不透明，高对比度模式使用实色表面。

Windows 标题栏通过 `WindowMaterialService` 与 `window_material.cpp` 接入 [DWM desktop acrylic](https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/ne-dwmapi-dwm_systembackdrop_type)（Windows 11 22H2 起）。仅原生接口确认可用后允许标题栏半透明；系统关闭透明、启用高对比度或系统不支持时，使用不透明表面。系统设置改变时重新检测；应用明暗选择决定材质明暗，不更改 Windows 设置。避免向 `window_manager` 设置实色原生背景，否则它会覆盖 DWM 材质。

窗口拖拽 / 双击、按钮命中区及原有图标资源沿用现有实现；标题栏不裁剪向下延伸的按钮提示。`studio_glass_test.dart` 检查主题 / 高对比度 / 不支持回退、卡片上传 / 展开和图片模糊与前景隔离；`decoded_memory_image_test.dart` 实际解码竖图 / 横图 / 小原图 / 高分屏，并核对不同尺寸的缓存键隔离。widget 截图只能检查 Flutter 表面，原生桌面透景需在运行包中核验。

# W.O.F NAI Studio · 品牌素材

## 设置导航与服务商标识

设置页按使用偏好、创作与资源、服务与连接分组，隐私与分享、关于与诊断位于导航底部。九个入口使用 `studio_icons/settings_*.svg` 自绘线性图标，追加至 StudioIcons 字体的 e90e–e916，已有码位保持稳定；字体和 `studio_icon_paths.dart` 由 `generate_studio_icons.py` 同步生成。

服务商标识根据用户选择的 `ProviderPreset` 显示，兼容协议不推断厂商。OpenAI、Anthropic、Gemini、DeepSeek、LM Studio、Ollama、Pollinations 标识离线随包提供，来自 Lobe Icons 1.95.1 的 SVG 资源；固定来源与 SHA-256 见 `provider_logos.json`，MIT 许可见 `assets/licenses/LobeIcons-LICENSE.txt`，应用许可页同步登记。品牌标识仍归各厂商所有。单色标识随深浅主题调整，彩色标识保留原色；自定义兼容服务显示 Studio 自绘模型图标。

`CAPTURE_SETTINGS_REDESIGN=1` 运行设置页测试可导出实际字体的九页、深浅色、1280 / 740 / 360px 宽度及窄窗口 130% 字号实绘；同变量运行 AppToast 测试导出通知卡片。测试只使用临时存储与模拟服务，不读取用户账号或调用模型。

## 字体

| 用途 | 字体 |
|---|---|
| 正文与控件 | Geist Sans + HarmonyOS Sans SC fallback，400 / 500 / 600 / 700 |
| 参数、尺寸、快捷键、代码 | Geist Mono + HarmonyOS Sans SC fallback，400 / 500 |

`StudioTypography` 负责正文、控件与等宽数据字体，应用统一使用 Geist 深浅两套主题，共用离线 Geist / HarmonyOS 字体。显式系统 / Google 字体选择仍有效，旧默认键 `system`、空键使用应用默认组合。独立标题栏已移除，品牌展示位于登录 / 载入页和生图空画布。字体许可在 `assets/licenses/` 和应用「关于 → 界面字体与许可」。

功能图标统一使用 `lib/presentation/widgets/common/studio_icons.dart` 的 `StudioIcons`：画风探索为遗传分支，块内遗传动作为双螺旋，在线画廊为图片＋地球，提示词块为模块网格，积木悬浮窗为双凸点轻量砖块，精准参考为人物叠卡，Vibe 为方形叠卡与弯箭头；生图为画布与画笔，本地画廊为图片文件夹，统计为三级圆角柱，设置为六齿圆角齿轮。侧栏、标题、块默认图标和菜单复用对应造型；参考卡片使用下述独立功能图标。网格布局、通用文件夹、保存动作与用户自选块图标保持各自语义。

SVG 母版在 `tool/branding/studio_icons/`；`generate_studio_icons.py` 将描边转轮廓生成 `assets/fonts/StudioIcons.ttf`，并同步图生图 / 风格迁移 / 精准参考三份面板 SVG 资源及原生动画路径 `studio_icon_paths.dart`。Flutter 原生 `IconData` 与 SVG 消费者因此保持一致，无额外运行时依赖。复建命令见脚本开头，码位只追加、不重排；母版修改后必须重新生成字体、三份 SVG 和 Dart 路径，再运行 Dart 格式化。矢量图标按主题继承颜色与尺寸，不能把预览图切成位图用于控件。

`StudioAnimatedIcon` 复用同源矢量路径，十四种语义分别设计一次性点击动作（500–600ms），主导航、积木与块库面板按钮、遗传按钮和参考面板展开共用。积木点击时两个凸点依次轻抬、落回砖身，主体轻微回弹。点击立即执行原操作；连续点击不重启或排队，悬停不自动播放，空闲返回普通 `Icon`。系统减少动画或页面 TickerMode 关闭时停止并回到静态。非操作性标题和块标记只显示图标。`studio_animated_icon_test.dart` 覆盖生命周期、连续触发、减少动画、隐藏页、首尾轮廓和画布边界；`CAPTURE_STUDIO_ICON_MOTION=1` 可输出实际字体与动画关键帧的深浅色对照。

参考卡片单独使用 `StudioIcons.imageToImage` / `styleTransfer` / `referenceFocus`（追加码位 `0xe90b`–`0xe90d`）：图生图为圆环与星芒的回环转换，风格迁移为开放双框之间的流动传递，精准参考为四角定位包围圆形与三角形，适用于角色、物体和风格等通用视觉特征。三枚采用 2.1 描边及少量实心形状，以 24px 标题图标尺寸与粗体标题配对；侧栏和库内原有细线图标保持独立。SVG 母版中的 `stroke="none"` 部件同时生成字体填充轮廓和动画填充路径。

点击参考卡片标题时立即执行原展开 / 收起，并播放 520–580ms 动效：图生图弧线轻转、源圆环收缩后星芒回应；风格迁移的连接线从左向右显现、目标星芒轻弹；精准参考四角向内聚焦后回位、内部几何形依次回应。悬停、导入按钮等独立操作不触发该动效。相关测试另覆盖图生图实际标题点击、字体与动画轮廓（含实心部件）一致性。`CAPTURE_REFERENCE_FEATURES=1` 运行 `reference_feature_icons_test.dart` 可输出参考卡片深浅色及动效关键帧，截图使用测试数据。

左侧主导航按用途分三组：生图 / 画风探索；本地图库 / 在线画廊 / 提示词块 / Vibe 库 / 精准参考库；统计。组间使用中性细线与留白，收起和展开状态共用分组顺序；账户头像固定在侧栏顶部，下接分隔线与功能导航；收起钮和设置固定在底部。账号菜单从顶部头像右侧展开，展开侧栏时仍显示账号名称。导航显示顺序独立于路由分支和快捷键映射。

## Logo 与 Windows 图标

- `assets/images/wof_logo_full.png`：原品牌完整 Logo，只移除外围透明留白，保留 W.O.F 与 NAI STUDIO 的原始比例和字形。源文件来自工作区品牌资产 `wof_logo_full.png`，取原图 `(0, 328, 1111, 547)` 区域。
- `assets/images/wof_logo_block.png`：保留的横版 Logo 资源；窗口顶部不再展示。
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

角色提示词分区的总栏，以及图生图 / 风格迁移 / 精准参考共用 `StudioGlassSurface` 的烟灰 / 乳白渐变、静态细颗粒及边缘高光。浅色卡片使用更明确的中性灰渐变底部。添加角色后的独立编辑卡保持原有不透明表面、头部底色、选中边框、焦点与编辑器，不使用磨砂。文字、图标和按钮保持清晰，画布与其他页面保持不透明。

三个参考面板收起且有图时使用原图背景与轻磨砂（2.4px 模糊、暗遮罩与微弱高光），展开后恢复纯材质表面，不对整窗或文字做实时模糊。背景 `DecodedMemoryImage` 显式启用 `decodeForCover`，由原图宽高与控件物理尺寸计算覆盖裁切需要的解码尺寸，保留比例且不放大低分辨率原图，最长边上限 4096px；其余使用处的解码行为不变。Vibe 优先原图，仅在无原图时回退既有缩略图，不能凭缩略图恢复丢失的细节。

## 窗口与空画布

Windows 的 `IntegratedTitleBarShell` 不再占用一整行：各页背景延伸到窗口顶边，右上角固定 138×36 的最小化 / 最大化 / 关闭按钮簇，以页面色保证覆盖深色图片详情时仍可辨认；登录 / 载入页另有明暗切换。窗口关闭仍走原托盘策略。

窗口配置由 `MaterialApp.builder` 内的 `IntegratedTitleBarShell(deferToRoute: true)` 下发，按钮与更新胶囊通过 `WindowChromePage` 在各路由页面内绘制；根 Navigator 和分支 Navigator 的提示、菜单、对话框均在按钮上方，关闭浮层后窗口按钮恢复命中。登录 / 载入、子页面和路由错误页使用相同页面层。

`WindowChromeScope` 在 shell 内保持稳定层级，路由、主题改变不重建 Navigator 或丢失输入。现有主页面工具栏通过 `WindowHeader` 为按钮和 64px 拖动空白留位置，较窄时分行；最右 dock 使用 `WindowPaneInset` 留顶部操作空间，生图画布直接延伸至顶边，不套整栏 WindowPaneInset；右侧历史栏顶部保留拖动区。浮动画布工具条随画布上移，WindowSafeTopToolbar 仅在与窗口按钮重叠时左移，窄画布不足时仅工具条下移避让，图片视口始终全高。历史 / 块详情面板收起时仍保留窗口操作位置；全屏图片详情的自身工具栏避让窗口按钮。

画风探索的候选画廊使用 `WindowPanelHeader`：面板直达顶边，36px 标题行与右上窗口按钮同高、同中心线，底边紧贴按钮下沿；标题旁的向右收起按钮仅收起画廊，原画廊开关重新展开。空白区域可拖动窗口；极窄栏才局部分行，仍按可见宽度避让窗口按钮。

`UpdateAwareWindowShell` 在发现新版本时，在最小化左边增加 88px 橙色「↑ 更新」胶囊；`WindowChromeScope.extraWidth` 同步各页避让，消失时恢复原宽度，不重建输入或 Navigator。桌面端不再显示顶部大幅更新通知，移动端保留既有通知。更新对话框保留 Markdown 日志、下载进度和失败重试；关闭或取消不隐藏已发现的更新，安装并重启后按当前版本比较自动消失。安装按钮在主生图 / 探索任务进行时禁用，并在点击边界重新检查；使用已有校验下载与安装服务，不改变更新仓库。UI 和状态测试使用模拟版本 / 安装服务，不执行线上升级。

本地画廊、在线画廊、块管理、Vibe 库和精准参考库统一使用 62px 窗口按钮高度；块管理的工具栏 / 分类栏同步 62px，避免依次切页时按钮上下跳动；其余路由维持 36px。`WindowChromeScope.captionHeight` 同步拖动区和窄栏避让。五页共用 `LibraryWindowHeader` 绘制背景与底边，分隔线覆盖窗口按钮预留区；内部工具栏 / 多选栏不再重复绘制。块管理右侧详情栏的竖线延伸至顶边，并在窗口按钮下接续横线，展开和收起均保留。独立复用工具栏时仍默认保留原外观。更新胶囊自身维持 26px 高，随窗口按钮行垂直居中。

主工作区向原生 runner 报 `barHeight=0`，关闭旧的整行 HTCAPTION，避免抢走模型、搜索和工具点击；仅明确定义的空白区调用 window_manager 原生拖动，双击切换最大化。登录 / 载入页顶部 36px 仍用原生命中区（扣除按钮簇）。窗口尺寸调整沿用原生窗口边缘；原生 Acrylic 当前禁用，页面顶部直接使用不透明的应用表面，参考卡片的应用内磨砂保持。

生图空画布使用 `GenerationWelcome`：原完整 Logo（最多 300px 宽，窄画布按可用宽度缩放）和一条 Tip（正文 14px、TIP 标签 11px） 在画布中心略偏上，随左右面板宽度重新居中。中英日 Tip 覆盖块复用、顺序 / 随机与锁定；进入空状态选一条，不轮播，参数刷新与面板切换不换提示。开始生成或出现图片时使用原生成 / 画布组件，不在图片上保留 Logo。

窗口测试覆盖内容从 y=0 起、按钮调用、搜索输入、拖动与双击最大化、登录切换命中区；页面测试覆盖主生图区域、历史展开/收起、深浅色以及各库/探索/设置页面。`CAPTURE_BORDERLESS=1` 运行 `sidebar_official_layout_test.dart` 可输出实际部件组成的生图布局截图；这些是 widget 实绘，不是用户运行窗口截图。Windows 实际拖动吸附和交互手感仍以用户运行包验收为准。

## NAI LAB 探索空画廊

`assets/images/wof_nai_lab.svg` 是用户选定 C 款的矢量定稿：W.O.F 主体顶边与基线对齐，像素由左下沿字形向右上破碎；下方为轮廓化的 NAI LAB，不依赖系统字体。品牌蓝固定为 #005DFF，透明背景适配深浅主题；SVG 是独立品牌资源，主页 NAI STUDIO 标识沿用原稿。

`ExploreGalleryWelcome` 在未选任务或任务没有候选时显示，最大 Logo 宽度 340px，字母主体的视觉高度对齐主生图 300px 的 STUDIO 标识；NAI LAB 副标等比增大 20%，字高约 18px。TIP 与主生图空画布保持同款字号、间距和略偏上的居中方式。提示为“选择喜欢的候选，让画风逐代进化。”，提供中英日文本；有候选但筛选结果为空时仍走原筛选提示。无轮播和新增动效。

`CAPTURE_LAB_WELCOME=1` 运行 `explore_gallery_welcome_test.dart` 可保存真实 SVG、字体的明暗主题截图至 `.dart_tool/lab-welcome-*.png`；另覆盖窄短栏和 150% 字号。

LAB SVG 的编辑源为 `tool/branding/wof_nai_lab_source.svg`，通过 `generate_lab_logo.py` 做布尔并集后输出正式资源。相接的像素块必须合为同一填充轮廓，避免分开抗锯齿让内部接缝透出背景；不通过描边或扩大形状掩盖。测试对明暗底色、340 / 214.4px 宽度及 100% / 125% / 150% / 200% 缩放检查内部接点纯蓝。

## 设置体验精修

设置的九个工作流继续使用固定字位的专用 SVG / StudioIcons 字体。入口改为柔和的叶片、圆角键盘、滑杆、文件夹和连接图形，1.6px 圆端描边；先前其他功能图标的字位与轮廓保持。正文最大宽度 850px，模型管理 1400px，在右侧可用区域居中。顶部空白整行可拖动、双击最大化，搜索和窗口按钮单独命中。侧栏、标题区和正文共用背景；局部 settingsUiTheme 把表单值和下拉菜单统一为 13px 常规字重，辅助文字 11px。

NovelAI 账号页以当前账号、订阅与资料、已保存账号、登录偏好组织。默认账号优先使用显式选择，未设置时回退最近账号；自动登录复用现有 auto_login 偏好。默认头像在设置中使用低饱和底色，用户自选头像照常显示。

顶部搜索支持 Ctrl/Cmd+F，定位分类、模型接口、预设及集成子页，并保留未保存编辑的离开保护。“关于与诊断”提供公开偏好的导入、导出、按范围恢复默认及上次恢复；仅允许白名单中的界面、输入与保护项，每次写入前生成回退副本，拒绝过时确认，失败时回滚已写项并保留后续修改。账号、密钥、模型配置、草稿、图片和本地路径不纳入偏好包。

CAPTURE_SETTINGS_REDESIGN=1 SETTINGS_CAPTURE_DIR=.dart_tool/settings-polish-captures 运行 settings_screen_test.dart 可实绘九页、深浅色、1280/2400/740/360px 和窄窗 130% 字号，另有模型表单与账号菜单；所有数据为夹具，不读取用户账户、不调用在线接口。原生拖动手感仍由运行包验收。

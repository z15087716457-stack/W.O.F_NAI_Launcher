# W.O.F NAI Studio · 品牌与界面约定

本文件描述当前源码的字体、图标、窗口和材质，使用现有母版与组件；当前安装 / 验收版本见工作区接手说明。界面改动先按用户指定流程展示方案，得到实施指令后施工；已接受的结果不做推测性改动。

## 字体与缩放

| 角色 | 当前默认 |
|---|---|
| 正文与控件 | HarmonyOS Sans SC，由 FontConfig.defaultFont 选择；显式系统 / Google 字体仍有效 |
| 参数、尺寸、快捷键与代码 | Geist Mono，CJK 回退 HarmonyOS Sans SC |
| 本地画廊 | 按原型使用 Geist → HarmonyOS Sans SC；查看器恢复 HOS |
| 标签百科 | Segoe UI → Microsoft YaHei UI → Microsoft YaHei；文章标题 Cascadia Code → Consolas |
| 韩文 | Pretendard 1.3.9 静态 OTF，四档字重，OFL-1.1 |
| 登录 / 载入背景字符场 | Geist Pixel Square / Circle |

字体角色由 `StudioTypography` 处理，多数原型正文13px / 1.45、字距与词距0。Geist Mono 500–700按原型共用Medium字形，原生600 / 700元数据文件由 `tool/fonts/build_prototype_weights.py` 生成，字形与度量不变。旧默认键自然落到当前默认，显式字体选择保留。主工作区固定100%，设置页、菜单与嵌套弹窗也以1.0为基准，相对字号不叠乘。字体许可在 `assets/licenses/` 与应用「关于与诊断」中。详细依据见 [原型字体核对](../../docs/uiux-typography-2026-10-09.md)。

## StudioIcons 与厂商标识

功能图标母版在 `studio_icons/`，`generate_studio_icons.py` 同时生成 `assets/fonts/StudioIcons.ttf`、参考面板 SVG 和 `studio_icon_paths.dart`；码位不重排，不复用仍有调用者的字位。修改母版后完整生成并检查旧字形 / 度量，不把生成参考图切成控件位图。

- Agent 桥接专用母版为 `agent_bridge_link.svg`，由 `BridgeLinkIcon` 原生绘制运动分段，不加入字体码位或改变设置集成字形。24 网格、2.7 描边，实际 16px / 1.8px；只在执行时微动，遵守减少动态效果与 TickerMode。绿色代表内容确认，灰色等待 / 内容变化，橙色失败；固定 24px 槽无背景、阴影或点击水波。
- 导航、块库、积木、遗传与参考卡片使用现有 StudioIcons 和 Flutter 点击动效。积木为双凸点轻量砖块，开关弹窗与关闭动效保留；常规按钮继续用 Material 图标。
- 本地画廊使用 `gallery_*.svg` 细线图标（`0xe919`–`0xe944`），24 网格、1.7 描边、圆端；选择圈勾加粗、收藏心形实心。网格 / 瀑布流视图为 `galleryViewGrid` / `galleryViewMasonry`；火车流单独保留 Material `view_day_outlined`。末尾未使用的 rows 字形已删除，不重新添加。
- 参考卡片继续使用图生图、风格迁移与精准参考字形（`0xe90b`–`0xe90d`）；点击时立即展开 / 收起，随后播放既有分阶段动效，Reduced Motion 降为静态。
- 设置共十个入口，分使用偏好、创作与资源、服务与连接；常规与外观采用明暗圆图标，词库与缓存有自己的入口。不要按旧九入口说明恢复分类。
- 40 个服务 / 自定义入口与 30 枚离线 SVG 标识由当前目录配置驱动；兼容协议不推断厂商。当前来源、版本、hash 和许可分别见 `provider_logos.json`、`assets/licenses/LobeIcons-LICENSE.txt` 和应用许可页；不在文档固定旧 19 枚标识名单。
- 服务选择器当前按接口服务 / 本地服务组织，预置与手动 ID、官方来源和地区限制见 `provider_catalog_sources.json`。正文 ID 跟随当前无衬线字族与 CJK 回退；模型能力记录不能宣称 Agent 已可执行。

## 色彩、层级与材质

颜色以 `lib/presentation/themes/presets/geist_theme.dart` 与实际 ColorScheme 为准：深色为炭灰、浅色为中性浅色，面板 / 卡片 / 控件分层，蓝色用于动作和焦点；不把过时的 #181818 / #3B3B3B 色表当当前常量。圆角、字重和行高由场景组件定义，设置控件、账号面板和画廊不强套同一尺寸。

主生图左栏与画风探索编辑列使用统一模块卡片，角色卡及三个参考图行并入模块；参考图行带图收起时保留原图 cover 解码、2.4px 模糊和深色遮罩，文字与按钮保持清晰。窄窗 `ParameterPanel` 的三个参考面板仍使用 `StudioGlassSurface`。画布三条浮动工具条使用其专用局部模糊路径。画廊版本标签与悬停动作只在悬停时构建 6px BackdropFilter 和半透明底，不常驻在整墙卡片上。

图标、材质的最近改动不覆盖已有用户验收；没有新需求时保持接受的形态。

## Logo、导航与 Windows 图标

`assets/images/wof_logo_full.png` 是保留原字形比例的完整 Logo，品牌展示在登录 / 载入和空生图画布；NAI LAB 使用 `assets/images/wof_nai_lab.svg`。旧蓝块只留工具侧素材，不在标题栏或运行资源恢复。

主导航依次为生图 / 画风探索，本地图库 / 在线画廊 / 块库 / Vibe / 精准参考，统计；中性分隔，头像置顶，收起与设置在底部。收起宽度 48px、展开 196px，头像 40px。账号面板显示当前账号概要，其他账号独立切换，动作复用已有认证与保存流程。

`generate_windows_icons.cjs`（Node + sharp）生成两套 ICO：桌面 / Explorer 的完整长方形 Logo 对应资源 ID 101，窗口 / 任务栏 / 托盘的方形 W 对应 ID 102。ICO 改动需重编原生 runner 并检查 DPI 图标与资源；字体 / SVG 改动须随 Flutter 资源交付。`CompanyName=com.example`、`ProductName=nai_launcher` 和单实例标识保持，品牌名通过 FileDescription / 窗口标题展示。

## 窗口与浮层

独立品牌标题栏已经移除，页面延伸至 y=0。`IntegratedTitleBarShell(deferToRoute: true)` 下发 WindowChrome 配置，各路由的 WindowChromePage 绘制按钮与更新胶囊；Navigator 提示 / 菜单 / 弹窗在其上，改变路由 / 主题不能重建输入和 Navigator。

右上按钮簇宽 138px，通常高 36px；本地 / 在线画廊、块管理、Vibe 和精准参考库为 62px，更新胶囊自身 26px 高并在有更新时预留 88px。窄窗局部换行避让，不能给满高画布恢复整行留白。关闭按钮沿用托盘行为，窗口隐藏不代表进程退出。

主工作区向原生报 `barHeight=0`，由明确空白的 WindowDragArea 拖窗 / 双击最大化，模型、搜索、图标与窗口按钮独立命中；登录 / 载入顶部仍有原生命中和明暗按钮。原生 Acrylic 当前禁用。画廊搜索最大宽 880px，标题与工具之间伸缩；侧栏标题、顶栏空白和按钮下保留区可拖动，`LibraryWindowHeader(dragBelowCaptions: true)` 处理后者。

浮层定位先把全局坐标转到 overlay 局部，再用 overlay 的尺寸做避让；不可直接用 MediaQuery 或屏幕坐标定位内部菜单。

## 欢迎页、小贴士与模型工作台

GenerationWelcome 固定 Logo 尺寸 / 位置，长段落在下方，短窗口滚动；ExploreGalleryWelcome 使用当前 LAB 标识和同款小贴士。小贴士分 guide / trick / wolf，五种界面语言各自成文，按洗牌顺序使用；具体文案和轮换边界见 [DEVELOPMENT.md](../../DEVELOPMENT.md)，不再把旧的固定三语单条提示作为需求。

设置标题、侧栏和正文共用背景，普通内容最大宽 850px、模型页 1400px，在右侧可用区居中。模型工作台保留顶部 / 左侧服务和右侧目录 / 已选双栏；当前固定高度边界、操作条、高级参数、目录缓存和草稿保护由现行组件实现，不从早期布局稿恢复旧动作。

## 验证与实绘

根据实际修改选择下列现有路径，使用 `test/helpers/studio_capture_fonts.dart` 和合成数据：

- `test/presentation/widgets/common/studio_visual_system_test.dart`：字体与视觉角色。
- `test/presentation/widgets/navigation/integrated_title_bar_test.dart`：窗口和页面命中。
- `test/presentation/screens/settings/settings_screen_test.dart`：设置入口及布局。
- `test/presentation/widgets/gallery/local_gallery_toolbar_test.dart`：视图图标、搜索与拖动。
- `test/presentation/screens/local_gallery/local_gallery_screen_layout_test.dart`：三栏实际部件实绘。
- `test/presentation/tips/tip_layout_test.dart`：小贴士五语布局。

采集变量与输出目录从对应测试源码读取，不复用旧文档中的页数 / 文件名。实绘是带真实字体的测试部件，不是用户运行窗口；Windows 原生拖动手感与最新交付仍由实机反馈验收。纯文档维护不需要重生成图标、字体或运行包。

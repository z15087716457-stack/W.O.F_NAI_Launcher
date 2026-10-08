# 生图04 · 角色模块交付（2026-10-08）

角色总栏和卡片合进 GenerationModuleCard，主生图与探索编辑列同步。说明文字改为标题 Tooltip；数量徽标随角色数变化；添加菜单28×28、透明底。定位使用 dense SidebarSegmentTrack，画布入口在轨道外。标题、徽标、定位标签与分段文字通过真实字体 TextPainter 和当前 TextScaler 测量，空间不足时定位整组换到第二行。

CharacterModuleScope 只在模块内容启用：每张角色卡自己画顶部1px线，无独立边框、圆角或底色；编辑中整卡为 onSurface 3%浅色/4%深色淡底；停用48%。Classic的独立卡和原定位控件默认样式保留。嵌入状态的 pin、上/下、勾、删除、更多和定位画布图标采用完整 HTML 原型路径；动作及编辑器、焦点、TapRegion 逻辑未改。

## 验证与证据

- README 的 character 目录、sidebar_official_layout_test、interaction_polish_test、studio_glass_test：35项通过，0失败，`.dart_tool/uiux-task04/test.log`。
- 新增 character_module_test：徽标随增加变化、标题悬停说明、英文352定位第二行和560单行、V5从7个增加到8个、V3隐藏模块、编辑淡底和停用透明度。
- `flutter analyze --no-pub lib/presentation/widgets/character lib/presentation/screens/generation test/presentation/widgets/character/character_module_test.dart`：No issues found。
- `CAPTURE_UIUX_CHARACTER=1 flutter test --no-pub test/presentation/widgets/character/character_module_test.dart --reporter expanded`：3通过，72张原字体widget实绘。0/1/3角色 ×352/420/560×zh/en/ja/ko×浅/深；3角色场景含停用、编辑中和真实缩略图。测试使用内存设置/仓库和临时Hive，无真实草稿或库读写。缩略图先在真实async区预解码，实绘前检查 RawImage 已有像素。
- `.dart_tool/uiux-task04/comparison/index.html`：同一完整角色文本的浅/深两组原尺寸并排及叠加；capture-measurements.json记录换行状态与模块边界，prototype-states.json记录四个HTML状态。原型PNG复用任务02相同原始全页截图，区域在浏览器重新验证。

## 与 HTML 的有依据差异

- 任务01明确标题w600/圆角6，HTML为w700/8；添加和画布按钮按任务04为28px，HTML ib为24px。
- 任务04明确保留28px头部、角色编辑器和其内边距/标签页/高亮/token条。HTML角色头部另有上内边距8，编辑器13px，而现有编辑器字体/行高不属于本任务修改范围，因此同文本实际换行和总高度有差异（见原尺寸对照）。名称的现有灰色和可编辑状态也保留。
- 无角色、多角色、停用、编辑中、带缩略图、其他语言与窄宽度没有完整HTML实例，按任务文字验证其状态和操作。

未构建、安装、启动、重启或热重载Studio，未调用NovelAI。施工验证不替代检查点②审查或用户实机验收。

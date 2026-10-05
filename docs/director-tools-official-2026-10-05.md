# 导演工具官网排版与图标核验 · 2026-10-05

本轮只改导演工具界面、官方表情选项和发送入口名称。此前用户已确认 3D 图层工作完成，保留该验收版本。FEAT-39 的三种结果含义/顺序产品核验仍暂缓；本轮保留现有结果切换、复制、保存和复用，不据此宣称完成 FEAT-39。

## 现场依据

使用 Codex 内置浏览器登录后的当前官网 `https://novelai.net/image`，从菜单进入 Director Tools。实际打开 Remove BG、Line Art、Sketch、Colorize、Emotion、Declutter、Pixel Snap，读取控件 DOM、尺寸和当前生效 CSS，再核对公开组件 `/_next/static/chunks/266-454cf0cf8df83dd3.js`。网页内容仅作为 UI/实现证据。

- 比较区域：两个等宽面板，20px 间距；图片 `object-fit:contain`；官网内容边距 `20px 20px 70px`，底部动作单独定位。
- 底部操作区：最大宽度 1100px，15px 外边距、3px 圆角；工具按钮在一行内排列，宽度不足的工具进 More 菜单。
- 上色：Defry 0–5 和可选提示词横向排布，Defry 为 200px。
- 表情：24 个官方枚举值；选择框和加减键并排，可选提示词占剩余宽度。Defry 增大对应 Normal、Slightly Weak、Weak、Even Weaker、Very Weak、Weakest，而不是增强表情。
- Pixel Snap：调色板、避免过度细化、放大三个组；默认 auto/64、两个开关关闭。当前官网未给 Declutter 展示额外选项。

自制非私密 832×1216 几何测试图已实测官网：Line Art 20 Anlas、Remove BG 65 Anlas（3 个可切换结果）、Pixel Snap 0 Anlas（返回 155×227）。总计 85 Anlas，现场余额 29196→29111。线稿测试返回白色结果，只能证明请求、结果和历史链完成，不据此评价线稿质量。没有调用 Studio 的真实 API，也没有更改 Studio 草稿、账户或图库。官网测试结果保留于官网历史；未清空用户历史。

## 实现

- 修复来源侧/结果侧底栏由 Wrap/默认 PopupMenu 尺寸引起的不同高度；两侧固定 50px，同样的预览内边距。变体条在两侧保留相同空间，同尺寸图片的初始 fitted bounds 严格对齐。
- 无结果时右侧为空，不复制原图制造假结果。结果动作只在结果存在时显示。历史选择继续恢复对应的源图，处理期间锁定输入/工具设置。
- 输入队列改为单上传入口及方形缩略图；移除嵌套长框。Ctrl+V 保留导入图片，提示词框正常粘贴文本。
- 底部固定单行操作，工具溢出进入官网 More 形式的菜单，当前溢出工具以其图标显示。参数区域独立滚动，转换按钮保持可见。窄窗口调整比较方向/参数高度；低预览高度的运行遮罩只显示进度圈，避免文字撑破布局。
- 表情选择从 14 项补齐为官网 24 项，保留 `emotion;;extra prompt` 与 Defry 的原请求结构和各工具设置。加减边界为 0–5，清楚标注减弱/增强。
- 七种工具、历史来源徽标、导入/复制/保存、箭头、加减、下拉和更多均用官网实际 SVG。保留 Studio 已验收的中性明暗色、品牌蓝和字体；不硬编码官网紫色背景。
- 五语言入口统一为“发送至导演工具” / “Send to Director Tools”，可选提示词与新表情同步本地化，台湾正体通过原生成流程更新。

## 官方素材

新增 `assets/icons/director_{remove_bg,line_art,sketch,colorize,emotion,declutter,pixel_snap,plus,minus,small_arrow,more,chevron}.svg`。

七种工具来自官网当前 DOM 的 mask-image：

| 本地后缀 | 官网 `/_next/static/media/` 文件 |
|---|---|
| remove_bg | image_tool_remove_bg.be09ccf1.svg |
| line_art | image_tool_line_art.99b08a4e.svg |
| sketch | image_tool_sketch.8bd2cc8b.svg |
| colorize | image_tool_colorize.6baf2425.svg |
| emotion | image_tool_emotion.bca3218f.svg |
| declutter | image_tool_declutter.7848744c.svg |
| pixel_snap | image_tool_pixel_snap.b8d9365a.svg |
| plus | plus.dc778eb7.svg |
| minus | minus.3db8267d.svg |
| small_arrow | small_arrow.1099f431.svg |

more 和 chevron 为当前按钮/React Select 控件的内联 SVG；箭头以槽内旋转保留官方原比例。导入、复制、保存、超分和关闭复用此前已登记的官网素材。

## 验证与交付范围

- 126 项针对性测试通过：导演状态/请求、七工具、24 个表情请求值、费用、图片增强接口、Pixel Snap 离线与官网 CPU 参考、结果来源、工具条及台湾正体资源。
- 40 个生产主题布局场景：五语言、明暗、1672×1340 / 1180×760 / 640×640 / 380×820；验证初始空结果、3 变体、七种工具参数、实际下拉/More 操作、运行/失败状态、双图 bounds 和底栏位置。160 张真实字体/SVG 控件截图保存于本机 `.dart_tool/director-official-20261005/captures/`。
- 修复过程中真实截图发现并纠正了窄窗口运行提示溢出、预览过小、日文下拉字体丢失和箭头方向错误。
- 控件渲染和官网实测不冒充安装后 Windows 实机验收。Release/Glass、安装预检、逐文件 SHA-256 和完整回退状态以本批交付单为准。

安装/回退使用独立 `install_director_official.ps1` / `restore_director_official.ps1` 和 `glass-before-director-official/`。覆盖运行文件前现场核对进程路径并等待完全托盘退出，不自动启动/重启/热重载，不修改已冻结的前批交付物。

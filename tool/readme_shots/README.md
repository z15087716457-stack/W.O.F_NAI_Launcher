# README 截图采集工具

本目录以真实 Flutter 页面／组件 + 隔离示范数据采集文档插图，**不是正在运行的用户窗口截图，也不证明联网功能已执行**。不读取正式账号、图库或草稿，不调用模型、生成、下载或收费接口；勿将示范余额、索引状态、工具执行结果当作实测数据。

## 运行

在源码根目录用登记 SDK（Flutter 3.47.7 / Dart 3.13.5）：

```bash
export PATH="<Flutter 3.47.7 SDK>/bin:$PATH"
flutter test --no-pub tool/readme_shots/
flutter analyze --no-pub tool/readme_shots
python tool/readme_shots/export.py
# 需要把总览送到别处时：
python tool/readme_shots/export.py --contact-dir /path/to/report-folder
```

Python 导出需要 Pillow；工具不自动安装依赖。测试不需要 `pub get`、代码生成或构建，不修改 `lib/`、`test/` 或已有视觉基准，也不触发热重载。

### 私有素材（不进仓库）

将已获使用授权、已去元数据的作品放在 `.dart_tool/readme-shots/images/`：`s01.jpg`～`s24.jpg`，另附 `index.json`。每项为 `{"file":"s07.jpg","w":832,"h":1216,"orientation":"portrait"}`，方向为 `portrait`／`landscape`／`square`。当前素材是 14 横、7 竖、3 方；`canvas_scene.dart` 和 `readme_data.dart` 有明确的文件分配，替换素材时须保留这些文件名及方向，尺寸以索引为准。

素材索引不存在或为空时，截图及图片断言测试会 **skip 并说明原因**，隐私扫描器测试仍执行。索引存在但列出的文件缺失则报错，不回落到渐变占位。

### 输出

- `.dart_tool/readme-shots/out/{zh,en}/`：2 倍 PNG，每个场景附 `.text.json`（隐私扫描内容）、`.images.json`（按 key 分配的映射）；需要精确取景的另附 `.frame.json`（渲染对象边界）。明确文件名选图不经过 key 分配表，不会列入 `.images.json`，对应关系见源码。
- `docs/images/readme/{zh,en}/*.webp`：每语言 34 张，共 68 张。
- `docs/images/readme/manifest.json`：名称、语言、尺寸和字节数。
- 默认总览 `.dart_tool/readme-shots/contact-{zh,en}.jpg`，总宽精确为 **2000px**；`--contact-dir` 仅改变总览目录。
- 只覆盖本轮产出，不删除旧文件。主题拼图只消费明确列出的六种主题，忽略旧 `theme-*` 中间图。

导出使用有中文字符覆盖的工作区字体；最终图移除 EXIF／ICC／XMP／comment。hero／hero-dark 保持宽 2400px，主题拼图宽 2400px，普通整窗宽 1920px，积木实例和独立 Agent 宽 1600px；有体积压力时普通图最低宽 1600px。小面板会重采样到该输出宽度，**不代表原生控件有更多细节**。

WebP 初始 quality 82（method 6），必要时逐级降低质量；硬检查 hero 每张 ≤700,000 字节，其余 ≤400,000 字节，整个目录（含 manifest、保留旧文件）≤10,000,000 字节。达不到限制则报错，不静默压到低于最小宽度。

## 文件

| 文件 | 作用 |
|---|---|
| `readme_capture_test.dart` | 场景入口、导航外壳、本地化、真实字体、图片预热、交互、截图及断言 |
| `readme_data.dart` | 中英示范 ViewData，虚构 `sample_*` 画师、账号、路径、积木、历史、Agent 对话与设置 |
| `images.dart` | 读取私有索引，按方向记忆化分配 `MemoryImage`，支持指定文件 |
| `canvas_scene.dart` | 文档专用四图混合横竖排布，复用真实 `ChannelBackdrop`／`ChannelOverlay` |
| `gallery_scene.dart` | 真实 `LocalGalleryScreen` + FakeGalleryServiceNotifier、缩略缓存、原生拖放替身和隔离存储 |
| `semantic_scenes.dart` | 真实标签扩展／Wiki 页面，自建本地语义搜索、词库、Wiki、翻译控制器替身及标签扩展宿主 |
| `safety.dart` | 从现有 fixture 补齐真实名称黑名单，扫描 Text／RichText／EditableText；另含路径、用户名等禁词 |
| `export.py` | 内容边界裁切、双侧主题细节拼图、中英主题标签、压缩／去元数据、清单及 2000px 总览 |
| `README.md` | 使用、来源、场景及限制说明 |

## 场景与取景

| 输出名称 | 实现／状态 |
|---|---|
| `hero`、`hero-dark` | `GenerationPage` + `NavShell` + 自建提示词槽 + `ReadmeCanvas`；四张不同作品（2 横 2 竖），四组历史封面不重复，与画布不同 |
| `gen-agent` | 同上，旁置 460 逻辑像素 `AgentPanel`；图片附件使用另一张素材 |
| `blocks-library` | `BlocksLibraryPage` + 自建积木库，复用 `RecordingBlocks` 的空操作 |
| `blocks-dock` | 生成页 + 真实 `BlocksDock`，画布仍使用四张不同作品 |
| `blocks-random`、`blocks-sequential`、`blocks-locked` | `BlockInstanceCard` 的随机、顺序、锁定状态；裁掉空白 |
| `blocks-rules` | 同一实例组件打开规则页及高级分布；按 `block-rules` 实绘边界裁切，不压小英文；只保留规则面板，含标题中的实例药丸 |
| `explore-main`、`explore-evolution`、`explore-compare` | `StyleExplorePage`，自建安全编辑器槽与候选数据；点击进化／比较入口 |
| `channel`、`channel-dark` | 生成页的真实画布显示弹层，四作品混合画布 |
| `channel-themes` | 独立 `ChannelFixtureCanvas` 近景实绘星图、像素电路、深海、地铁、乐谱、月相；每格不同素材，裁取两侧装饰，舍弃作品中段；中间细缝明确表示拼接，下标各自语言主题名 |
| `gallery` | 真实三栏 `LocalGalleryScreen` + FakeGalleryServiceNotifier，点击图片展示详情；临时样例路径映射到本地素材 |
| `viewer` | `ImageViewerPage` + 自建 ViewData，复用 `RecordingViewerActions` |
| `online` | `OnlineGalleryPage` + 虚构标题／作者／通用标签，不联网 |
| `refs-vibe`、`refs-precise` | `RefsLibraryPage` + 自建两类参考图数据 |
| `tools-upscale` | 生成页 `ToolsUpscaleSheet`，展开高级选项；背景同四图画布，不实际放大 |
| `tools-director` | `ToolsDirectorPage` + 安全化 `ToolsFixture` 图片与结果名称，不实际运行 |
| `tools-inpaint` | `ToolsEditorPage` + `ToolsFixtureStage.builder`，安全图层名称及底图，不实际重绘 |
| `settings-rag`、`settings-agent`、`settings-models`、`settings-dictionaries` | 复用 `SettingsHost`／`SettingsRecorder`，替换路径和资料；Agent 定位技能页，models 提供合成服务商工作台 |
| `agent-chat`、`agent-approval`、`agent-run` | 真实 `AgentPanel`，自建完成对话、审批及运行状态；按面板实绘边界裁切，导出另留 24px 边距，不以白色阈值误删内容 |
| `translation` | 自建宿主 + 真实 `BlockPill`／`TranslationPillView`；中英标题有独立断言 |
| `tag-expansion` | 自建 `ExpansionHost` + 真实 `TagExpansionWrapper`，Ctrl+单击打开后查询；中英标题有断言 |
| `wiki` | 真实 `TagWikiScreen`，搜索并打开安全词条，断言语义徽标 |
| `stats` | `StatisticsPage` + 安全化统计数据，Top10 仅 `sample_*` |

采集关闭动画、预热所有已分配及已挂载图片，开启真实阴影并在 finally 恢复。每张图执行隐私文本扫描与渲染异常检查；另断言四图方向混合、画布与历史互不重复、所有历史图片不重复。

## 限制／目检

- 本工具只验证合成数据下的组件实绘；生成、真实搜索命中、下载／索引、工具耗时、审批后执行和费用等均未实测。
- 主题拼图是两侧细节的编辑性拼接，不是完整画布的连续截屏；同一主题两侧原样保留，不人工增强装饰。
- 积木规则是组件自身切换到规则页，不把两个互斥状态伪装为同时打开。
- 少数大网格素材数超过某一方向的素材池，仍会循环；四图生成页／其历史／六种主题图已避免可见作品复用。
- 英文普通实例卡为适配现有固定宽度沿用 0.86 text scale；**高级规则图不缩小文字**。真实 UI 中的固定高度、截断及按钮名称不在本任务修改。
- 私有素材不随工具提交，克隆后需自行提供；不对图像内容做 OCR 或权利认定，文本扫描只覆盖挂载的 Flutter 文本。
- 目检先在 `.dart_tool/readme-shots/peek/` 生成宽 ≤1200px 缩略图，一次只读一张；不要把多张大 PNG 直接载入对话。规则图另在 600px 宽下核对文字。

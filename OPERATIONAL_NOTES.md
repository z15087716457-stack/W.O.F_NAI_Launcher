# 启动器自研当前约束

> 本文只在修改启动器桥接、生成参数、计费或图库代码时按需读取。
> 通用 Flutter/Dart 规范、测试命令和安全要求以同目录 `AGENTS.md` 为准；用户可见功能以源码为准。

## 画风探索多池遗传

- 探索页基础轮和手动登记统一使用 `N×1` 逐张生成；每个候选槽位保存自己的生成前 `ExploreRollSnapshot`，不能把一个多图请求的同一快照复制给多个候选。
- `PillInstance.locked` 是用户持久化的实例级锁，只冻结随机实例的内容，不改变触发概率；固定模式没有可锁定的 roll。
- 深度轮的自动保护只使用 runner/provider 运行态 guard：非 override 的遗传随机实例按锁空语义参与投影，用户原有锁状态和 `currentRoll` 不被覆盖；guard 不写入 Hive、Recipe 或 `PillDocument`，完成、暂停、取消、异常和恢复时必须清理并恢复原状态。
- 深度轮的注入池仍读取配方快照中所有遗传实例引用的块内容，不因 guard 的临时投影而丢弃任一 lane 的原子。
- `exploreParentStringFor` 按 `ExploreRollSnapshot.instanceRolls` 的既有顺序合并全部非空 `rolledText`，使用顶层原子分隔保护权重内部逗号；全部为空时回退正向全文。`createFamily` 与 `createBranch` 消费该父本串，旧父本串不重算。
- 多池是一个合并基因组，不拆成双轨谱系；演化子代仍写入单一目标遗传位，父本串中的多池内容整体参与后续变异和交叉。

## 登录与游客会话

- 登录页提供“跳过登录，以游客身份进入”入口；无保存账号和已有账号快速登录两条路径都接入同一游客会话 provider。`LoginFormContainer.showGuestEntry` 默认 false——已登录的添加账号等复用场景不显示游客入口，仅登录页语境显式传 true。
- 游客状态只存在于当前运行时，不写入持久化存储；路由会在游客状态变化时刷新，游客可进入主应用及本地功能。
- Token、第三方 Token、credentials/access token、credentials 登录和 `tryAddAccount` 成功后清除游客状态；`logout()` 同样清除游客状态，避免退出登录后继续放行。
- 完全重启应用不会恢复游客身份。代理运行时热切换不属于 Q4 登录页逃生门范围。

## 桥接与参数

- 魔改版可执行文件：`build/windows/x64/runner/Release/nai_launcher.exe`。
- Krita 桥接：`ws://127.0.0.1:<port>/krita`；端口和 secret 从 `%APPDATA%/nai-launcher/krita-bridge.json` 发现，每次启动会重生成。
- 常用客户端入口：`get`、`set k=v`、`set-json <JSON 或文件>`、`ui-gen`、`gen`、`cancel`。`gen` 强制单张；批量由客户端循环，失败间隔至少 2 秒。
- `/user/*` 与生图请求都走 `image.novelai.net`，不要把用户接口改回 `api.novelai.net`。
- `get`/`set` 参数应保持对称。可写项包括 prompt、negative_prompt、尺寸、seed/seed_lock、steps、CFG、sampler、质量词档、UC 预设、SMEA、模型、透明背景和 characters 等。`seed_lock` 是协议兼容派生值：无独立锁标志，`seed != -1` 即视为锁定；`set seed_lock=false` 等价于 `set seed=-1`，`seed_lock=true` 在随机态下钉一个新随机种子。
- `set` 是部分更新；`characters` 传数组表示整表替换，空数组表示清空。角色框必须同时维护 UI 的 `characterPromptNotifier` 和桥接使用的 `ImageParams.characters`，不能只改其中一套。
- `prompt`/`negative_prompt` 的读数是应用 fixedTags 后的生效版。vibe、precise reference、img2img 目前可读但不可由桥接写入；UI 中设定后，后续 generate 会继承。
- `uc_preset` 的权威源是 UI 下拉值，桥接读数只是副本，不能根据返回的 `0` 反推 UI 状态；桥接设置该项时会同步 UI。
- set 后立即 get 可能碰到 token 沉淀竞态，隔一拍再读。写参数前最后几秒必须重新 get，并与最近一次落盘备份核对；每次 get 都落盘到 `nai-workspace/backups/`，禁止凭旧读数拼 payload。
- `autoFormatPrompt` 只规范逗号/空白并保护 NAI 权重结构，不再把提示词中的空格自动改成下划线；数据库和搜索层的 canonical 下划线规则不变。
- `sdSyntaxAutoConvert` 在失焦和实际生成/桥接请求副本阶段均按设置门控；SD 转换在格式化之前执行，两个开关都关闭时请求副本保留原文。

## 模型与计费

- Token 是两根独立预算：正向为全局段加所有角色框正向，UC 为全局段加所有角色框 UC。V4/V4.5 上限 512，V5 上限 1471；以桥接 `prompt_tokens`/`uc_tokens` 为准。
- V5 能力由 `core/constants/model_spec.dart` 控制：没有 noise schedule 和 Variety+，有 Opus 额度、透明背景和 Max Enhance 能力位。
- V5 质量词档：Standard=`very aesthetic, masterpiece, no text`，Light=`very aesthetic, amazing quality, no text`，None 不追加；桥接优先接受 `quality_preset=standard|light|none`，`quality_toggle` 仅作旧兼容别名。
- V5 透明背景开关会把 `transparent background` 拼到有效 prompt，并发送透明背景相关请求 hint；V5 Max Enhance 在源图面积低于约 2.5MP 时保持源尺寸并交给服务端端到端放大。非 Max 增强仍使用防糊追加词。
- Opus 免费资格只看三条：单张请求、steps≤28、面积≤1MP；不再额外排除角色参考。满足条件时每请求免 1 张。PR 参考图另加每张 5 Anlas；img2img/infill 满足条件同样可免费。
- V5 家族在 V4 系数结果上整体乘 1.5，乘在 SMEA 后、img2img 强度前；官网 bundle 是 V5 单价的权威来源，SDK 旧版本不含 V5 定价。
- 账户每日消耗统计是账户差额口径（前后余额相减），与界面显示单价无关。
- Opus 额度芯片（V5）直接显示服务端共享池：进度条数值刷新时平滑过渡，回充中（`timeUntilNextPercent > 0`）有扫光动画；低额度（<5% 或超支）整芯片转红。

## 本地与在线图库

- 本地图库支持多个根目录；发现根目录下 `_索引/index.jsonl` 时可幂等导入 tag 和元数据，扫描期间拒绝导入。**外部源图片级移动/复制已放开（QoL-L5，2026-09-09）**：右键菜单「移动到…/复制到…」与批量栏同款，目标是分类树（`CategoryPickerDialog`，含外部分类）；源或目标任一为外部源时移动弹专用强制确认（不受保护模式开关影响，移出/写入/双向三情形文案），复制只走普通保护确认；分类树的外部分类只读保留范围=重命名/删除/加子分类/分类排序，图片拖入已双向放开。移动底层 `moveFileCrossVolume`（rename 优先，跨卷回退 copy+字节校验+保 mtime+删源，校验失败不删源），复制强制新 mtime 防扫描器签名撞车；移动成功当场按旧路径查 id 直更 DB（不等扫描）。目录计数递归聚合。
- 本地图库默认瀑布流，可切网格；列宽、视图、排序和 NAI-only 偏好持久化。删除采用删除池：先软删并从当前 state 摘除，DB 的 `is_deleted` 是权威；同一会话不得因重扫复活，恢复和彻底删除走删除池面板。
- 本地画廊固定网格、分组和瀑布流的 `LocalImageCard3D` 均沿用 `DraggableImageCard` wrapper；选择模式禁用外拖，拖出格式继续由脱敏设置和可用文件路径决定。
- **卡片手势响应（2026-09-10 修）**：① 卡片右上角三个悬浮按钮（心形/复制/发送）从双击手势子树移出，改为同一 `Stack` 的兄弟节点——此前它们作为卡片 `GestureDetector` 的子节点，双击识别器在首次抬手后会 hold 整个手势竞技场直到双击窗口（约 300ms）结束，导致按钮点下去要等约 300ms 才响应、窗口内连点被判成双击而整体丢失（含心形按钮打开收藏菜单）。② 非多选态不再给卡片挂 `onDoubleTap`（那时双击与单击同义，都开大图）；多选态保留双击开大图。启用选择=「双击语义与单击不同」时才挂双击。
- **收藏菜单即时反馈（2026-09-10 修）**：菜单首行「收藏」与收藏集勾选改为乐观更新——点击当帧先就地翻转勾选/红心，落库结果回来再以服务端口径校准；收藏切换按请求序号回写，连点时只认最后一次结果。旧实现等 `toggleFavorite` 整个链路（落库 + 取消收藏时的集合刷新 + 过滤视图重载）返回才 `setState`，点一下要愣一拍才见变化。
- 本地 NAI-only 判定为三通道任一命中：`gallery_metadata` 的 software/source 含 NovelAI 指纹、model 为 `nai-diffusion-*`，或 raw_json 含 NAI 参数特征键。版本筛选按 model 精确匹配；历史空 model 由启动迁移按元数据指纹回填。数据库位于 `%APPDATA%/com.example/nai_launcher/databases/danbooru.db`。
- 收藏是根-子集关系：心形根集包含全部收藏；加入子集自动加入根集，取消根集会清掉所有子集关系，从子集移出不影响根集。
- 收藏集支持文件夹无限嵌套（`gallery_collections.parent_id` + `is_folder`）：文件夹是纯组织节点不参与成员关系，只有文件夹可拥有子节点；老数据 parent_id=NULL 留在收藏根级平铺。选中文件夹浏览=全部子孙收藏集成员的去重并集（`getCollectionImageIds` 递归语义，按各图最早加入时间排序）；文件夹计数同为递归并集去重（一图多集不重复计）。`moveCollection` 拒绝非文件夹目标与成环移动（UI 层和 DB 层双校验）；非空文件夹禁止删除；`reorderCollections` 按同父级分组重排并写回 parent_id。收藏操作只动链接表（image_id 锚定），不触碰文件路径；磁盘文件移动=前端移动当场 `updateFilePath` 直更 DB + 扫描器 size+mtime 签名匹配兜底（签名命中还要求原路径文件已不存在才判移动，同签名副本按新文件入库不抢 id）；签名失配则旧行软删、收藏跟丢。分类树展开状态持久化于 `gallery_category_tree_expanded_ids`（重启恢复）；「移动到…」对话框展开状态为会话级（重启重置）。
- 在线 AItag 列表走 `/api/ai_works_search`，详情走 `/api/work/{id}`；列表图使用 pximg 缩略图并带 Pixiv Referer。详情元数据优先读取 `images[].ai_json`，顶层 `model` 可作为 Source 兜底。作者搜索有一级返回快照，晚到请求不得覆盖原页面。
- 元数据解析按文件签名和统一读取链执行，细节见 `.kimi-code/skills/nai/refs/metadata.md`；不要按扩展名判断 PNG/WebP/JPEG 或 NAI 版本。

## 本地画廊缩略图

- 本地画廊缩略图质量由 `GalleryThumbnailQuality` 控制，默认 `hd`；`hd` 保持既有 `pickThumbnailSize(columnWidth, DPR)` 和显示端 1.5 倍过采样，`sd` 固定使用 `ThumbnailSize.small` 且显示端过采样为 1.0。
- 质量偏好保存在 SharedPreferences 的 `local_gallery_thumbnail_quality`，非法或缺失值回退 `hd`；本地画廊分页条的完整和 compact 布局都提供质量控制。
- 质量切换会立即更新画廊状态，并主动预取当前页、上一页和下一页；分页预取与卡片统一使用 `resolveThumbnailTier`。
- 缩略图生成的去重身份必须是「原图路径 + `ThumbnailSize`」；CacheService 的生成集合/Completer/队列和 ThumbnailService 的活跃任务都不能只按路径去重，否则切换质量或列宽换档会串档。
- 该设置只影响本地画廊卡片缩略图；详情大图、详情轮播、复制、发送、打包和拖拽仍使用原图路径。`.thumbs` 磁盘缓存已接入 LRU 清档（P7）：启动后台按「最久未使用」淘汰超限缓存，设置页「清理缩略图缓存」提供手动入口；默认上限 2048MB / 50000 个文件（每个图库源独立，`setCacheLimits` 可调），只删除 `.thumbs` 目录内的 `.thumb.jpg`，不触碰原图。
- 缩略图生成失败或 30s 超时**不再回退解码原图**（原实现会让卡片永久顶着数 MB 原图跑）：卡片保持灰块占位图标，并在 30s 后自动重试一次（每次挂载至多一次，翻页重新挂载会再走完整加载）。失败的**重试入队时间被安排到缓存层 10s 失败冷却截止之后**，不再出现「冷却期内被弹回、3 次重试毫秒级烧完判 failed」的失效路径；重试执行前先走 `getThumbnailPath` 快速路径，首次任务超时后晚到落盘的缩略图会被直接吃掉。冷却时长与重试延迟均为可覆写常量（`setFailureRetryCooldownForTesting` / `thumbnailFailureRetryDelayForTesting`），生产值 10s / 30s 不变。

## Q5：AI TAG 图片请求

- AI TAG 详情资产 CDN 请求必须使用 `Referer: https://aitag.win/`、浏览器 User-Agent 和图像 Accept；统一由 `onlineGalleryImageHeadersForUrl()` 分发。
- `asset_base_url` 来自 AI TAG 配置；新配置、有效配置缓存命中和 AI TAG 收藏快照还原都会注册合法的 HTTP/HTTPS 资产 host，注册按小写 host 幂等处理；当前 `ai-img.10118899.xyz` 保留静态兜底。
- `image_path` 优先于旧的 `image_type/author_id/file_name` 拼接字段；详情、缩略图、预取、下载、反向提示词和收藏图片都继续使用统一 headers、cache manager 和 URL 默认 cache key。下载命名语义不变。

## Q6：提示词格式化与权重

- `NaiPromptFormatter` 保留词间空格，不再把空格自动改成下划线；只规范顶层逗号/空白并保护 NAI 数值权重、别名、括号、`||`、XML 和药丸标记。已有下划线不反向转换。
- `NaiWeightSyntax` 是所有自产生器的数值权重闭合入口；权重正文以数字或句号结尾时，在闭合 `::` 前隔开，避免被服务端误读为新权重。已覆盖 SD 转换、PromptTag、权重工具、pill、探索变异和 Enhance 固定串。
- 提示词补全展示/插入使用空格形态；搜索、数据库、别名和词库 canonical 仍保留下划线。实际生成和 Krita 桥接在请求副本阶段按 `autoFormatPrompt` / `sdSyntaxAutoConvert` 设置执行，SD 转换先于格式化，不改用户草稿。旧 `autocomplete_replace_underscores` 设置已随统一空格形态退役（键留置无读取，无迁移必要）。

## 画布架构

生图页中央预览区是对标 NAI5 官网的自由画布。逆向参考在 `../04_工具/开发计划/素材/nai5-生图页前端逆向.md`（含第八、九节勘误）；其中模型整理的结论需要结合代码核验，明确的用户交互要求优先。

**文件分工**（`lib/presentation/screens/generation/widgets/canvas/`）：

| 文件 | 职责 |
|---|---|
| `generation_canvas_view.dart` | 装配层：指针/键盘、焦点与屏幕空间工具条 |
| `canvas_world_viewport.dart` | 世界图块布局；绘制、点击、右键使用同一相机矩阵，支持负世界坐标 |
| `generation_canvas_controller.dart` | `CanvasCamera`(offset/scale 物理) + `GenerationCanvasController`(点击/拖拽/hover/焦点) |
| `canvas_feed_layout.dart` | 纯函数：`groupCanvasImages` 按任务分组、`layoutCanvasFeed` 竖排布局 |
| `canvas_tile_toolbar.dart` | 视口固定的主工具条（顶中/底左/底右） |
| `../history_panel.dart` / `../history_batch.dart` | 右侧历史栏按请求合并：第一张封面 + 数量，整批多选、拖拽封面到角色框、底栏锁/全存/删；底层图片历史仍有 50 张上限 |
| `canvas_utils.dart` | `rrectFromSize`/`parseAspect`/`hexToColor` |
| `models.dart` | `CanvasImageData`/`CanvasImageGroup`/`CanvasTileVisual` |

**Provider**：`canvas_settings_provider.dart`（锁/减弱动态/填充缩放/固定图片持久化）；`preview_selection_provider.dart`（焦点组=共享选中，喂参数面板和 emotion）；`image_generation_provider.dart` 的 `mergedPanelImages` 是输出历史的数据源——**生成中 currentImages + 历史 take(50)**，；独立固定图片区由 `CanvasPinRepository` 提供。子图态零 API，纯粹前端焦点（`generationPreviewSubFocusProvider`）。

**当前相机与输入约定**：裸滚轮平移（Shift 转横向）、Ctrl+滚轮缩放；仅中键或 Shift+鼠标左键拖动相机；触控板平移/缩放按事件增量处理。锁相机阻止手动平移、缩放及复位，程序化对焦仍可用；WASD 松键始终清理按键状态。相机停稳 120ms 可选最近组，Ctrl+0 主动总览时暂不自动选中。远跳先移近起点再抵达准确终点，连续离散缩放累积未完成目标，平滑模式直接更新。scale 夹在 [0.1, 8]；非焦点图 scale(0.98)，悬停回 1。相机逐帧变换不重建重图子树，仅挂载可见范围及缓冲区。

**固定图片**：`canvas_pins/` 保存字节副本，`canvas_pin_records` manifest 保存身份及未嵌入图片的元数据；载入只计健康图片，旧 UUID 列表保留但不计幽灵数量。原输出组仍正常选择；独立固定图区使用 `pin:<id>` 分组，点击历史栏 Pins 计数跳转，历史被淘汰后仍可访问。内部缓存路径不能冒充已保存到图库的路径。完整便签/箭头/自由布局编辑器未实现。

**动作数据与保存**：工具条种子以图片 PNG 元数据为准，缺失才取对象缓存；变体价签仅在所选图片参数已知时给出估算，超分设置入口不标固定价。生成中的变体和编辑动作禁用；变体入口在修改参数前检查生成/桥接/冷却，解析后复查，生成 provider 再拒绝重入。保存/详情/打开目录共用保存服务，保留原 PNG 元数据，缺少参数不采用当前草稿补写；重复保存去重并回写状态路径。流式局部重绘沿用共享源图、裁片与蒙版合成。

**画布外围留白**：自由画布预览区四周保留 4px 内边距，侧栏拖拽分隔条独立保留；经典查看器仍为 16px。

**主工具条定位（用户确认，2026-09-21）**：三个主工具条常驻中央生图视口的顶部居中、左下角和右下角，距边缘 12px；位置与大小独立于相机平移/缩放，操作对象仍随当前焦点图更新。无可操作图片时沿用空态。此要求覆盖旧逆向文档中“edge bars 贴 tile”的定位结论；图片下方不再显示选中或悬停迷你条，避免与常驻工具条重复。

**左下齿轮**：按缓存 chunk 5285 的 `display.settings` 与 5468 模块 80341，使用按钮上方的小浮层。放大填充开关即时重新适配当前焦点；透明底选项仅在当前模型的 `ModelSpec.transparency` 为 true 时显示，提供默认/浅/深棋盘格、无底色、六种纯色和自定义 HSV/HEX 取色。源码中的吸管形图标是自定义颜色选择器入口，不是屏幕取色。偏好持久化，底色仅在图片下方绘制，不合成进保存字节、不改生成参数。平滑缩放不属于此菜单。主工具条提示走三语国际化，导演工具图标向右、信息图标为圆圈 i。

**历史批次**：同一 `generationRunId` 只显示一条，按 `batchIndex` 选择首图封面，右下角标实际张数；生成中数量含待完成槽位。无 runId 的旧图保持独立，不能仅凭时间/尺寸合并。并行返回晚到的首图在同一行接管占位；取消后按留存图片计数。画布中任一子图被选中，历史栏均定位并高亮该批封面；点历史封面发起显式整组对焦。多选按整批展开到真实图片 ID，后来完成的同批图片继续纳入选中，保存/打包/删除均使用这些 ID。

**当前布局常量（参考保存的 chunk 5285）**：组间 `kCanvasGroupSpacing=340`、组内默认 `ceil(sqrt(N))` 列 row-major 近方阵 48px 间隙、N=3 走 `floor(4*FNV(id+':tri'))` 哈希四式三角（上1下2/上2下1/左1右2/左2右1）、gridXLength>0 列紧凑 24px、组水平居中 `x=-width/2`（`0*o` 错动是死代码）、`bounds.height=cursorY-340` 含尾随距。归组 `run:<generationRunId>`；无 runId 兜底按同尺寸+createdAt≤120s 相邻合并（外部登记/桥接漏打 runId 的图不致散组）。生成中 inflight 组置顶 = `totalImages` 槽（尺寸=batchW×H）。

**生成占位与焦点（用户要求）**：点击生成后，在参数准备和网络等待之前同步发布 runId、数量和尺寸，立即出现加载占位并飞向最新组。已有组保留世界位置，新组排在它们上方。占位、流式帧和最终图统一使用 `run:<generationRunId>`，成图替换对应槽位，不再二次飞行；多图按 `batchIndex` 对槽，准备失败/取消结束加载。首帧到达前显示加载动画与文案，随后在同一位置渐进显示图片。用户等待期间切到历史图时，预览帧和成图不抢回焦点。此要求覆盖旧 `deferFocus` 等待完成才飞的实现。

**历史栏多选（自研，官网无）**：多选入口固定在“历史记录”标题行最右侧，底栏不再放多选钮；点击进显式态（平点也勾选）；操作条 = 打包/保存/✕退出；栏宽不足时打包与保存上下排列，宽栏并排，退出按钮在右侧；按钮使用紧凑内边距，标签单行省略；`_selectedIds` 清空即自动退出（含「仅剩 1 张再 Ctrl+点击」）。

**有意不做 / 待核验**：完整项目状态见 `../04_工具/开发计划/画布修复验收.md`。Shift 按住出边栏（显隐条件已知、内容未核，未实现）；无限滚动（`history` 硬上限 50，要做先得给历史加持久层）。键位补全（WASD 平移/f 飞回/Esc 退子图态/±缩放/1 复位）+ 双击空处重飞 + 视口全空 2s 自动飞回是 2026-04 收尾加的。

## 生图工具工作区

- 左栏使用 `GenSidebarStyle` 统一层级：分组标签 13/400、模块标题 15/600、页签 13；中文紧凑字号保留官网实测 14/16 两级差。角色常用动作直接显示，入库和独立位置画布收在更多菜单。模型栏可换行，参数摘要的采样器占剩余宽度。
- 主提示词与角色提示词使用单一深色卡片，卡内输入不再叠加凹陷阴影；Token 细条仅在悬浮时显示用量，角色条另显示本框贡献及对应正/负总用量，上限随模型读取。透明通道保留棋盘格与开关状态，名称/说明放在悬浮提示。角色区空态只显示细框标题与添加入口；选择角色类型后显示定位分段和角色卡，清空全部收在添加菜单。尺寸预设下拉保持紧凑并与横/竖/方等宽按钮组垂直居中；右上宽高小框可直接编辑，回车或移出焦点提交，手动改动后保持自定义，选择预设时退出自定义，不额外展开输入行。生成数量 1–4 共用细框，选中项使用内嵌的中性圆角底色。参考图模块图标统一为 22px，与双行文字居中。
- 图生图空态只在标题保留上传按钮，下方左侧为精准参考库导入、右侧为绘制草图。精准参考添加菜单以按钮在 Navigator overlay 内的实际位置为锚，右缘对齐按钮、靠近窗口边缘时自动避让。
- 增强与超分放在中央视口底部的 `GenerationToolPanel`，使用有细边框和独立底色的浮层。增强使用工具自身的源图与设置，不写入或启用左侧图生图，打开、调参及关闭均不改草稿图片字段；`generationRequestParamsProvider` 为实际生成和费用预估提供请求副本，左栏继续显示原图生图/重绘状态，探索页计价继续读取其草稿。超分保留暂存/恢复自己接管的图片字段逻辑，已有更新的底图不被旧快照覆盖。编辑器取消不提前改底图和蒙版。
- 增强的五档强度/噪声为 `(0.2,0)、(0.4,0)、(0.5,0)、(0.6,0)、(0.7,0.1)`；高级设置可独立调节。倍率按源尺寸/模型筛选，832×1216 及横版保留 1.5 倍例外，V5 Max 沿用模型能力门控。左栏生成按钮随增强模式切换文案。
- 编辑/局部重绘使用全屏画布，左上工具设置，右上下载/保存退出，底部主工具栏，右下图层缩略图。详细设置、聚焦重绘、扩图、压缩、项目及 3D 图层沿用已有引擎，低频入口收在浮层/更多菜单。
- 导演工具共用输入队列、原图/结果双栏、底部七工具及参数、右侧历史。队列和历史用细框及底色区分，底部参数与工具切换/操作共用一个面板并以细线分隔；预览内部用较深底色，尺寸显示为小标签。背景移除 ZIP 的全部结果分别保留，同次处理共用 runId，历史首图封面+数量；可选结果变体、复制、保存、加入输入队列或应用为图生图。运行中锁定本次源图与选项，失败保留输入；仅实际在线处理后刷新余额。
- Pixel Snap 是本地 Dart isolate 算法，不调用生成接口；保留关闭/自动/自定义调色板、避免过度细化、最近邻放大。离线参考说明在 `test/fixtures/pixel_snap/README.md`。样本 CPU 一致不代表所有浏览器 GPU/半透明解码均逐位一致。
- `GeneratedImage.operation` 在请求时记录来源，历史左上显示对应图标和本地化提示，固定图片清单也保存来源；未知旧记录不按当前参数猜测。工具结果保留原图字节，外部超分只继承源图已有 PNG 元数据，不补入无关草稿；普通生成的元数据补齐链保持独立。

## 构建与更新

- 正常覆盖构建需目标文件未被运行实例锁定；用户要求自行核验时，不自动关闭程序，可使用独立 CMake 产物目录。Flutter 位于 `C:/flutter`，NuGet 位于 `C:/tools/nuget`，下载和 git 使用本机代理 `http://127.0.0.1:7897`。NSIS 3.12 已装于默认位置（makensis 在 PATH/Program Files (x86)），安装器打包与 `scripts/validate_windows_installer_process_handling.ps1` 依赖它。
- 安装器（`installer/windows/nai_launcher.nsi`）进程检测自 2026-09-09 起为「软化 fail-closed」语义：进程枚举/查询失败时不再直接阻断，改为以 `CreateFileW(GENERIC_WRITE, share=0)` 探 `$INSTDIR\nai_launcher.exe` 文件锁——文件可写打开或不存在（全新安装）则放行，共享冲突/拒绝访问（文件真被占用）或其他未知错误仍阻断（静默退出码 3 不变）。每次检查失败会把失败阶段、GetLastError、疑似 PID、探锁结果追加写入 `$INSTDIR\install_diagnostics.log`（UTF-16，随卸载删除）。验证脚本已覆盖四场景：目标在跑阻断 / 他目录实例放行 / 查询失败+无锁放行+落诊断 / 全新目录放行。
- 远程布局（2026-09-11 整理）：origin=本分叉仓库（z15087716457-stack/W.O.F_NAI_Launcher）；上游 Aaalice233 不再常驻远程——需要观察上游改动时临时 `git remote add upstream https://github.com/Aaalice233/Aaalice_NAI_Launcher.git` 并 fetch，看完 `git remote remove upstream`。自行实现有价值的改动，不直接 merge 或 cherry-pick 上游提交。
- build_runner 绑定的 analyzer 不接受 Dart 3.9 null-aware collection element；使用 collection-if。窗口隐藏后恢复要保留现有 `refreshWindowFrame()` 刷新非客户区的调用。

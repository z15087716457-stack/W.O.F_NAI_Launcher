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
- `get`/`set` 参数应保持对称。可写项包括 prompt、negative_prompt、尺寸、seed/seed_lock、steps、CFG、sampler、质量词档、UC 预设、SMEA、模型、透明背景和 characters 等。
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

- 本地图库支持多个根目录；发现根目录下 `_索引/index.jsonl` 时可幂等导入 tag 和元数据，扫描期间拒绝导入。移动/拖拽仍只读，目录计数递归聚合。
- 本地图库默认瀑布流，可切网格；列宽、视图、排序和 NAI-only 偏好持久化。删除采用删除池：先软删并从当前 state 摘除，DB 的 `is_deleted` 是权威；同一会话不得因重扫复活，恢复和彻底删除走删除池面板。
- 本地画廊固定网格、分组和瀑布流的 `LocalImageCard3D` 均沿用 `DraggableImageCard` wrapper；选择模式禁用外拖，拖出格式继续由脱敏设置和可用文件路径决定。
- 本地 NAI-only 判定为三通道任一命中：`gallery_metadata` 的 software/source 含 NovelAI 指纹、model 为 `nai-diffusion-*`，或 raw_json 含 NAI 参数特征键。版本筛选按 model 精确匹配；历史空 model 由启动迁移按元数据指纹回填。数据库位于 `%APPDATA%/com.example/nai_launcher/databases/danbooru.db`。
- 收藏是根-子集关系：心形根集包含全部收藏；加入子集自动加入根集，取消根集会清掉所有子集关系，从子集移出不影响根集。
- 收藏集支持文件夹无限嵌套（`gallery_collections.parent_id` + `is_folder`）：文件夹是纯组织节点不参与成员关系，只有文件夹可拥有子节点；老数据 parent_id=NULL 留在收藏根级平铺。选中文件夹浏览=全部子孙收藏集成员的去重并集（`getCollectionImageIds` 递归语义，按各图最早加入时间排序）；文件夹计数同为递归并集去重（一图多集不重复计）。`moveCollection` 拒绝非文件夹目标与成环移动（UI 层和 DB 层双校验）；非空文件夹禁止删除；`reorderCollections` 按同父级分组重排并写回 parent_id。收藏操作只动链接表（image_id 锚定），不触碰文件路径；磁盘文件移动靠扫描器 size+mtime 签名匹配保 image_id 改路径，签名失配则旧行软删、收藏跟丢。
- 在线 AItag 列表走 `/api/ai_works_search`，详情走 `/api/work/{id}`；列表图使用 pximg 缩略图并带 Pixiv Referer。详情元数据优先读取 `images[].ai_json`，顶层 `model` 可作为 Source 兜底。作者搜索有一级返回快照，晚到请求不得覆盖原页面。
- 元数据解析按文件签名和统一读取链执行，细节见 `.kimi-code/skills/nai/refs/metadata.md`；不要按扩展名判断 PNG/WebP/JPEG 或 NAI 版本。

## 本地画廊缩略图

- 本地画廊缩略图质量由 `GalleryThumbnailQuality` 控制，默认 `hd`；`hd` 保持既有 `pickThumbnailSize(columnWidth, DPR)` 和显示端 1.5 倍过采样，`sd` 固定使用 `ThumbnailSize.small` 且显示端过采样为 1.0。
- 质量偏好保存在 SharedPreferences 的 `local_gallery_thumbnail_quality`，非法或缺失值回退 `hd`；本地画廊分页条的完整和 compact 布局都提供质量控制。
- 质量切换会立即更新画廊状态，并主动预取当前页、上一页和下一页；分页预取与卡片统一使用 `resolveThumbnailTier`。
- 缩略图生成的去重身份必须是「原图路径 + `ThumbnailSize`」；CacheService 的生成集合/Completer/队列和 ThumbnailService 的活跃任务都不能只按路径去重，否则切换质量或列宽换档会串档。
- 该设置只影响本地画廊卡片缩略图；详情大图、详情轮播、复制、发送、打包和拖拽仍使用原图路径。旧 `.thumbs` 文件暂留，不把 `evictLRU()` 描述为已接入的自动清档机制。

## Q5：AI TAG 图片请求

- AI TAG 详情资产 CDN 请求必须使用 `Referer: https://aitag.win/`、浏览器 User-Agent 和图像 Accept；统一由 `onlineGalleryImageHeadersForUrl()` 分发。
- `asset_base_url` 来自 AI TAG 配置；新配置、有效配置缓存命中和 AI TAG 收藏快照还原都会注册合法的 HTTP/HTTPS 资产 host，注册按小写 host 幂等处理；当前 `ai-img.10118899.xyz` 保留静态兜底。
- `image_path` 优先于旧的 `image_type/author_id/file_name` 拼接字段；详情、缩略图、预取、下载、反向提示词和收藏图片都继续使用统一 headers、cache manager 和 URL 默认 cache key。下载命名语义不变。

## Q6：提示词格式化与权重

- `NaiPromptFormatter` 保留词间空格，不再把空格自动改成下划线；只规范顶层逗号/空白并保护 NAI 数值权重、别名、括号、`||`、XML 和药丸标记。已有下划线不反向转换。
- `NaiWeightSyntax` 是所有自产生器的数值权重闭合入口；权重正文以数字或句号结尾时，在闭合 `::` 前隔开，避免被服务端误读为新权重。已覆盖 SD 转换、PromptTag、权重工具、pill、探索变异和 Enhance 固定串。
- 提示词补全展示/插入使用空格形态；搜索、数据库、别名和词库 canonical 仍保留下划线。实际生成和 Krita 桥接在请求副本阶段按 `autoFormatPrompt` / `sdSyntaxAutoConvert` 设置执行，SD 转换先于格式化，不改用户草稿。旧 `autocomplete_replace_underscores` 设置已随统一空格形态退役（键留置无读取，无迁移必要）。

## 构建与更新

- 工作区构建前关闭正在运行的启动器，避免 release 文件锁。Flutter 位于 `C:/flutter`，NuGet 位于 `C:/tools/nuget`，下载和 git 使用本机代理 `http://127.0.0.1:7897`。
- 上游仓库只用于观察：先 fetch，再查看 `git log HEAD..origin/main` 和 diff，自行实现有价值的改动，不直接 merge 或 cherry-pick 上游提交。
- build_runner 绑定的 analyzer 不接受 Dart 3.9 null-aware collection element；使用 collection-if。窗口隐藏后恢复要保留现有 `refreshWindowFrame()` 刷新非客户区的调用。
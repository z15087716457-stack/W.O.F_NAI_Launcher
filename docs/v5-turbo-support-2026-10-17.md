# V5 Full Turbo／Medium Effort 支持

> 当前交付：已随 [r24 本机更新](cumulative-preview-r24-2026-10-17.md) 安装到原桌面入口，内部 `2.0.0-preview+28`。以下保留开发验证时的状态与边界。

> 后续修正：紧凑胶囊已限定为 V5，右侧 A／F 改为按内容宽度收紧；旧模型保持原样。这两项源码完成、尚未安装，见 [范围与宽度修正](v5-turbo-capsule-scope-fix-2026-10-17.md)。

日期：2026-10-17。源码及 Windows Release 验证完成，尚未安装；桌面仍为 r23，本次未调用真实生成接口。

## 官方契约与实现

官方 [Full Effort Toggle 公告](https://blognew.novelai.net/novelai-diffusion-v5-full-effort-toggle/)及公开前端 `b50892a` 为本次核对依据。缓存和资源 SHA-256 在 `.dart_tool/v5-turbo-investigation-20261017/production/resources.json`，不含账号凭据。

- 文生图／图生图：`nai-diffusion-5-full-medium`；局部重绘：`nai-diffusion-5-full-medium-inpainting`。仍属 V5 Full 家族，使用 V5 参数结构及 1471 Token 预算。
- 固定 14 步、Euler Ancestral、Heavy UC；忽略自定义全局及角色 UC、CFG Rescale。Guidance、透明背景、Max Enhance 等按 V5 能力继续门控。
- `ImageParams.constrainedForModel` 生成不可变的请求副本；不把固定值写回存储。Full 的步数、采样器、UC、CFG Rescale 和负面草稿在 Turbo 中保留，切回 Full 立即恢复，重启时也不将保留的采样器降为固定采样器。
- 请求 builder、普通／流式 API、工作流和原生 Agent 统一应用约束。报价使用固定 14 步，步数项乘官方 `1 / 1.06521739`，取整顺序、V5 ×1.5、强度、价格上限和服务端 Opus 耗尽标志保持原语义。
- 元数据解析支持明确的 Medium 模型字段及 Source 名称；通用 V5 Source 不抹掉明确 Medium ID，其他模型族的明确 Source 仍优先。导入将 Medium 重绘 ID 转回对应基础模型。图库保留 V5 分组并显示 Turbo 名称，不根据 14 步猜测模型。
- 桥接读取的生效参数、原生 Agent 报价及上下文返回 `model_constraints`；可编辑草稿仍是原始值，备份、版本冲突和生图授权流程保留。Agent 内置 V5 手册同步说明两种读数的用途。

## 界面

`Model [V5 Full ▾] [⚡] [A／F]`：独立 22px 闪电按钮加 3px 间距，Full 家族可切换，其他模型显示不可用提示。启用使用警示黄色及完整闪电，关闭使用划线闪电。保留原模式图标，Anime／Furry 缩为 A／F；原胶囊实测宽度分别为 217.172／212.024px，顶栏仍高 37px。

Turbo 时固定采样摘要不可编辑，抽屉不展示固定参数和 CFG Rescale；主／角色负面页签禁用，已有选择与内容保留，回 Full 恢复。五种语言同步提示。本次没有修改中央画布、三条悬浮工具条、原图或侧栏材质。

## 验证与边界

本地证据目录：`.dart_tool/v5-turbo-implementation-20261017/`。

- 最终同批 880 项不同检查全部通过，0 跳过，包含 57 张既有生图／工具页视觉基准；48 个改动 Dart 文件的范围分析无诊断。中途失败的旧模型列表、测试路径、精确视觉变动区域及多语言资源检查均已处理，不累计失败尝试或重复测试数量。
- 登记 SDK 的 Windows Release 构建成功，1938 项生产输入构建前后哈希一致；原生 `com.example/nai_launcher` 数据身份及 Studio 品牌检查通过。构建的 AOT SHA-256 为 `3ad93ec67690b550a407439439608f8561d4fc8b2a427624ee06f5728bafa849`。标准 Release 仅用于本次验证，不直接覆盖 Glass 桌面目录。

- `pricing-reference.cjs` 仅在隔离 Node VM 执行缓存的官网价格函数，生成 72 项离线对照：Full／Medium／Medium 重绘，四种面积、三种强度、单张／三张；包括超限价格。Dart 结果逐项相同，没有访问生成接口。
- 真实字体下五语言 × 明暗 × 1100／1600px 共 20 个布局组合；每个组合检查 A／F 以及开启／关闭／不可用状态，测量原胶囊宽度和高度。另测角色负面页签 Full→Turbo→Full 的状态恢复、固定抽屉及 Guidance。
- 核对六种实际请求结构（文生图、图生图、重绘 × 流式／非流式），使用合成 PNG／mask，不允许 Vibe 编码或真实网络生成。原生 Agent 测试只返回合成图片流，并通过原生报价、确认、历史链路；桥接只读测试不生图。
- 完整代码生成后依次完成繁体资源同步和 gen-l10n。扩大多语言检查时发现基线已存在的四项未使用文案与 `set_rgRestoring` 占位符说明缺失，一并清理／同步；不放宽测试。
- 生图／工具页旧视觉基准保留原 PNG，仅为本次获准新增的 Turbo／A-F 窄区域设置准确遮罩，其余既有区域和历史排除保持。原 269 张 PNG、桌面 AOT／收据、未归属 `DEVELOPMENT.md` 均以前后哈希核对。

未进行真实付费／免费生成，因此不把离线请求验证称为服务端实出图验收。未安装、启动、重启或热重载应用；未改用户参数、角色、账号或 RAG 索引。后续本机更新仍需使用登记的 Glass 交付流程。

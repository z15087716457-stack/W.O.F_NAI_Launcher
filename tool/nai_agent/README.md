[English](README.en-US.md)

# NAI Agent 运行宿主

直接使用官方 Pi 1.3.0。此目录是生产业务宿主；阶段 A 的模拟验证保留在相邻 nai_agent_sdk_probe。固定的 npm lockfile 和 PI-LICENSE 随源码保留，不能直接换成其他版本的示例。

在本目录运行 npm ci --ignore-scripts --no-audit --no-fund 和 npm test。Node 需要 >=22.19.0。本机 E8 交付将 Node 24.18.0、固定依赖、许可与内置 Skill（skills/nai-studio、skills/nai-prompt，取代原 manuals/）放在 Studio 的 tools/nai-agent；调用方只使用包内 Node 和 host.mjs，不依赖用户安装 Node 或 Pi。

Flutter 入口为 lib/presentation/providers/nai_agent/：工作区控制器持久化目录、聊天元数据、输入与原始附件；starter 按需解析既有模型服务/安全存储并创建私有 stdio 子进程。读取 provider 不启动进程。聊天历史只由官方 Pi 保存；切工作区不自动改生图页。D 已接可见对话和设置。E9 已接官方 MCP／CodeMode，Windows 系统输入专项仍待后续。当前安装仍是 E8；本轮源码／新包尚未安装。

默认声明 read/write/edit/bash、studio_context、model-only 的 ask_user 和官方 codemode 七个入口。十九个 Studio 业务工具经官方进程内 MCP 通道进入 nai_studio 组，默认 codemode 暴露，通过 searchTools／describeTool／describeNamespace 按需发现。调用方提供 NAI 系统提示词，宿主只追加简短路由，完整业务路线在 MCP namespace 内按需读取；显式 loader 不读取全局 Pi 配置、环境密钥、AGENTS、自动发现的扩展或网络模型目录。Pi 管理流式循环、工具执行、重试、压缩、排队/引导与会话文件。

E7 使用官方 DefaultResourceLoader 加载内置 nai-interaction（studio_context／model-only 的 ask_user）及 extensionPaths 明确选定的本地 Pi 扩展文件／包目录。设置可启停、移除；当前任务结束后下次发送按新配置恢复会话。工具、斜杠命令与 session_start／session_shutdown 由 Pi 管理。标准 select／confirm／input／editor 转原生问题卡，通知／状态／字符串 widget 转面板；停止取消启动及运行中的 UI 等待。终端自定义组件和其他桌面产品专有插件协议不支持。扩展运行本地代码，工作目录绑定不提供系统权限沙盒。

JSONL 协议版本为 1。init 的私有 config／mcp 只通过 stdin 传输，其他命令附带 workspaceId/sessionId；支持 prompt（followUp/steer）、state、session_list、rename、system_prompt、queue_edit、navigate、compact、abort、shutdown、mcp_command（status／reconnect／login／logout）。tool_request/tool_result/tool_cancel 通过 toolCallId 配对；request_permit/permit_result/request_cancel/request_release 共享 Studio 并发额度。迟到结果丢弃，工具错误抛回 Pi。stdout 是结构化消息，stderr 不转发。costKnown=false 表示服务实际计费未知，不能把内部占位 0 展示为免费。

模型支持 Studio 的 Chat Completions、Responses、Anthropic Messages、Gemini GenerateContent 与 Ollama 兼容协议。所有协议使用官方 Pi 网络适配器。保存的 stream=false 仅属于原非流式调用，在 Agent 中强制流式；模型/对话/工具字段禁止覆盖。Gemini REST generationConfig 映射到官方 Google SDK config，采样限制和版本路径显式处理，重试与请求超时使用当前服务设置。未登记上下文/输出上限时暂用 32768/4096；公开配置仍标为未知。图像需要已确认支持和服务允许图片；未知工具能力保持 null，显式 false 拒绝启动。

模型密钥/headers 不进入提示词、会话或参数命令行；提供者错误若回显凭据，在进入 Pi 持久化前脱敏。自定义 header/model body 从现有安全存储读取。Pi 的请求许可交给 Flutter，与翻译请求共用服务商并发额度；等待可取消，不占网络超时。每次显式运行默认最多 32 个模型请求（可设 1–200），达到上限保存进度并等待明确继续。

持久数据默认在 Studio 程序旁的 agent-data/，避开 Flutter data/。工作区稳定 ID 与显示名分离；chat 元数据只是 Pi JSONL 的引用，空聊天不会伪造 Pi 历史。附件原始文件留在工作区，上传按已有图像优化规则处理。中断任务和待发送输入只恢复到可查看状态，不自动重发；编辑消息使用 Pi navigateTree 保留旧分支。正在运行的聊天切换到后台可继续；闲置子进程退出以避免积累内存。生图配置快照已可保存，完整草稿/积木载入随域工具接入。

测试使用临时工作区、合成图片/草稿和本地 HTTP/SSE，覆盖五协议的实际序列化与工具回合、超时、图像能力拒绝、错误脱敏及覆盖限制。Flutter 另测真实生产 writer/备份/版本冲突/取消，以及 Dart → Node → HTTP → 三个工具闭环。CPA 的独立授权实测记录在项目阶段 B 文档，npm test 不调用真实账户。

MCP 设置统一管理内置组和用户服务器。支持 stdio／Streamable HTTP、启停、重连、官方 OAuth 登录／登出以及 codemode／deferred／direct／hidden 暴露。完整外部配置存在既有加密存储，普通设置只保存元数据引用；OAuth 凭据沿用官方实现，存于当前工作区 .agent/mcp-auth.json，不读取 Pi 用户全局配置。仅配置明确选择的服务器会连接；stdio 子进程和环境变量属于用户选择的本机能力，不是系统权限沙盒。经典 SSE 不支持。

CodeMode 使用官方 QuickJS，没有另造执行器。MCP 调用继续走原 Studio 的备份、版本校验、确认及取消；原生图片结果元数据通过 Pi 的 tool_result 扩展保存在官方会话 details，CodeMode 聚合图片路径，恢复聊天仍显示结果。内置 MCP 等待期限为 24 小时，避免把用户确认／长时间超分按外部服务器默认 60 秒超时处理；CodeMode 的显式 timeout_ms 仍是整个脚本的截止时间。

Pi 1.1.0 适配读取官方会话中已声明的 MCP 工具名，在重连注册时恢复仍可用的工具；隐藏／禁用与后续卸载保持有效。agent_settled 的 aborted 和工具 durationMs 经原 JSONL 直接传递，无新增历史或执行层。1.3.0 升级沿用同一适配：内部 MCP 辅助路径、会话恢复与旧 1.1.0 记录兼容已核对，不改宿主协议。

Skill（2026-10-18）：宿主启用 Pi 原生 Skill，来源由 Studio 决定——内置 `skills/`（只读，随版本更新）、全局 `agent-data/skills/`、当前工作区 `skills/`，同名时工作区 > 全局 > 内置；不读取工作区内 `.agents/skills` 或 `.pi`。`lib/skills.mjs` 用 Pi 的加载器解析并应用开关／“仅手动”，Pi 负责目录格式与 `/skill:` 展开；`list-skills.mjs` 供设置页列出同一结果。系统提示词只留入口地图，业务工具用法在 `nai-studio`。

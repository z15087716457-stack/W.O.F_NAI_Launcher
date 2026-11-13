# 外部 Agent 的 Skill、业务工具与原生会话

本批按 `.devin/mockups/external-agent-session/` 的批准样板接线，仍使用现有侧栏、工具步骤、确认卡、提示词组卡和产物页。收起提示后续改为画布底部两条工具条之间，已完成[补齐与流程优化](external-agent-canvas-notice-2026-11-13.md)。源码已实现，尚未安装桌面或发布；当前桌面仍为 2.3.3+100。

## 使用方式

先在 Studio 设置开启本机 Krita／Agent 共享桥接，并保持 NAI Agent 的 Studio 业务工具组开启。无需连接 Krita，也无需给内置 Agent 选择模型。外部宿主负责自己的模型配置和推理。

MCP 宿主使用 stdio 启动随应用提供的 Node 和 `external-mcp.mjs`。下例 `<应用目录>` 应替换为实际安装目录；Mac 使用应用包内相同工具目录下的 `node`，无需 `.exe`。

```json
{
  "mcpServers": {
    "nai-studio": {
      "command": "<应用目录>/tools/nai-agent/node.exe",
      "args": ["<应用目录>/tools/nai-agent/external-mcp.mjs", "--client", "Codex"]
    }
  }
}
```

开发态可用登记的 Node 24.18.0 启动源码 `tool/nai_agent/external-mcp.mjs`。可选 `--workspace <Studio工作区UUID>` 固定工作区，省略时在创建逻辑会话时采用当前 Studio 工作区。`--discovery <FILE>` 仅用于显式指定本地发现文件／隔离测试，不接受远程服务地址。

推荐每个逻辑任务先调用 `studio_session(action=open, summary=用户请求)`；会话 ID 由 Studio 返回。`action=resume` 携带原 `session_id` 和 `workspace_id` 继续，`action=end` 结束连接归属并取消未完成工具，产物保留。并发调用同一会话返回 `busy`，不自动排队或重放写操作。一个适配器进程同时使用一个逻辑会话。

`studio_skills()` 列出当前工作区解析后的已启用 Skill（包括 auto/manual 标志）；`studio_skills(key=..., path=...)` 读取正文或相对引用。MCP `resources/list` / `resources/read` 提供同一内容，资源 URI 形如 `nai-skill:///builtin%2Fnai-studio?path=references/blocks.md`。Skill 的优先级、禁用项及包解析复用原有清单；读取引用不能越出该 Skill 目录。外部宿主决定何时采用 Skill，Studio 不假定所有宿主会自动加载。

不使用 MCP 的外部 Agent 可使用同一入口的命令行模式：

```text
node external-mcp.mjs --client Codex --session-file task.json --summary "整理分镜卡" --call prompt_set --args card-arguments.json
```

`--args` 是工具参数 JSON 文件；`--session-file` 保存会话 ID，下一次同名客户端复用该会话。每次命令结束断开，记录与产物保留。文件不含发现密钥。旧 `studio-bridge` 命令保持兼容，原有调用方式无需迁移。

## 交互与权限

- 顶栏、会话列表和请求行明确标注外部及客户端名称；底部显示已连接／已结束，提供停止和断开。客户端名称是通过本机密钥鉴权后的自报标签，不是厂商身份认证。
- 只读查询不抢焦点。首次写入、创建卡片或需要确认时可展开侧栏；当前内部会话正在运行、输入文字或附图时保留它，显示外部提示及「查看」。点击查看会保存未发送草稿。
- 同一逻辑会话手动收起后，不反复自动展开；画布底部提示显示约五秒，可点击「查看」，按钮角标及打开侧栏后的查看入口继续提示未读活动。新逻辑任务重新获得一次自动揭示机会。
- 复用 24 个原生 Studio 工具，包含 `ask_user`、提示词组、积木、图库、参考、设置、查询与生成准备／运行／取消。定义直接由内部 `studioTools` 共享，不维护另一份参数 schema。
- 外部入口不代跑宿主的 `read/write/edit/bash`、自管理工具或第三方 MCP；外部 Agent 使用自身文件工具。工作区 Skill 引用可以通过上述资源读取。
- 权限从 Studio 当前设置读取：只读拦截写入及付费运行；询问模式和自动模式下的危险操作使用原生确认卡，拒绝即不执行。付费业务仍必须经过既有原生报价和确认，不接受一个外部 `authorized` 布尔值代替。待确认期间改变权限会使该调用失效。
- 工具直接调用既有业务 binding，沿用草稿备份、字段版本、库版本、实际生成忙碌检查、取消及原有产物操作；没有启动第二个内置推理循环。冷初始化暂缓 MCP 宿主；打开内部会话仍主动加载，普通控制器的自动连接默认行为保留。

## 数据与实现

会话元数据增加可空 `externalClient`，旧会话文件格式兼容。外部操作记录保存于对应工作区 `.W.O.F/ui/external/<chatId>.json`，不写入官方 Pi JSONL。运行时只将真实请求摘要、工具调用和结果投影给现有 UI mapper，不伪造外部完整对话／思考。未完成操作恢复为 interrupted，不重放；会话回收与撤销覆盖新增记录。

沿用 `ws://127.0.0.1:<port>/krita`、现有发现文件和每次启动的密钥鉴权；新增 `agent_request` / `agent_result` 及 `agent_tools_v1` 能力。通用工具调用不占用经典桥接的生成标记，避免自己的生成忙碌检查阻塞自己。结果仍只返回请求所属连接；断开取消该外部连接的待处理工具。

MCP 适配器 stdout 只输出换行 JSON-RPC，stderr 用于错误；连接建立有超时，工具等待原生确认时不额外加入固定超时，不自动重试业务写入。协议依据 [MCP stdio 传输](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports) 和 [MCP resources](https://modelcontextprotocol.io/specification/2025-11-25/server/resources)。

## 验证

完整 **1533 项 Flutter** 和 **154 项 Node** 回归通过；Windows 跳过 1 项 Finder 启动环境测试。最终全仓 `dart analyze` 为 0 问题；末轮外部桥接 16 项（含 Provider 销毁后的连接释放）、角标 87 项及外部 UI 13 项定向复查通过，计数不重复累加。繁体资源生成的 4 项检查通过；现有五语言键值未被改写。

结果与截图保存于 `.dart_tool/external-agent-20261113/`：真实 MCP 子进程连接隔离桥接，调用真实提示词组存储并经原生 mapper 形成卡片；覆盖权限／拒绝／变更、停止与 MCP 取消、断线、Skill 引用、恢复及删除撤销。既有业务工具的备份、付费确认和产物按钮由相关原生回归继续覆盖。

五语言、明暗主题、320／360／460／520px 均做布局检查，保存 10 张原生实绘；截图使用现有卡片测试数据，不是实际生图。没有启动桌面 Studio、请求真实模型或 NAI、生图、安装、打包或提交 Git。完整测试计数和最终分析结果见本次验证记录及接手入口。

打包仍按既有 tracked-source 流程；本轮新增适配器和共享 `lib/studio-tools.mjs` 必须随源码一起纳入后续构建清单，不能只替换 Flutter 文件。Windows 与 Mac 均需要这两个文件及 `lib/external-bridge.mjs`，没有新增 npm 依赖。

# Pi 1.5.0 升级

本项已随 [2.2.4+79](local-2.2.4-build79-2026-11-02.md) 本机安装完成；下文保留源码验证当时的状态与证据。

源码完成并验证，尚未安装或推 Git。桌面仍为 2.2.4+78／Pi 1.3.0。

## 范围

`tool/nai_agent` 的 `pi-ai`、`pi-coding-agent`、`pi-mcp` 从 1.3.0 固定升级到 1.5.0，lockfile 中全部 Pi 内部组件同步为 1.5.0，新增的 pi-schema 也由上游固定版本。npm 共新增 3 个包、更新 9 个；直接依赖 typebox 保持 1.3.27。Node 要求仍为 >=22.19.0，现有 24.18.0 满足，未替换 Node。

现有宿主、JSONL 协议版本 1、MCP、缓存保温、工具声明和 UI 继续复用。MCP 内部辅助入口仍存在，缓存保温的官方延迟公式未变；仅同步相关版本注释。README 中英文更新版本说明，并移除“当前仍为 E8”的过时安装状态。PI-LICENSE 与 v1.5.0 官方原件逐字节一致，无需改动。

上游收益包括大工具调用增量解析、压缩输出额度修复、CodeMode 工作线程忙时排队及部分 Claude/MCP 兼容修复，见 [coding-agent 变更](https://github.com/earendil-works/pi/blob/v1.5.0/packages/coding-agent/CHANGELOG.md)和 [pi-ai 变更](https://github.com/earendil-works/pi/blob/v1.5.0/packages/ai/CHANGELOG.md)。终端渲染优化不直接作为 Flutter 性能收益；本轮未测整机性能。

## 验证

| 范围 | 结果 |
|---|---|
| 升级前 Node 宿主测试，1.3.0 | 127／127 |
| 升级后既有 Node 测试，1.5.0 | 127／127 |
| 新增实际 pi-schema 边界回归 | 4／4 |
| Dart → 真实 Node 宿主及 MCP 设置 | 63／63，13 个文件 |
| 1.3.0 合成会话 → 1.5.0 恢复与续聊 | 通过 |
| 改动的 MJS 语法及 npm 依赖树 | 通过 |

4 项新增回归覆盖 TypeBox／普通 MCP JSON Schema 的一致转换、原参数不被修改、枚举／范围／必填／额外字段拒绝、提示词与角色原始值保留，以及真实宿主在调用 Studio 前把错误参数反馈给模型。继续使用 typebox 编写声明，由 Pi 负责实际验证与转换，不增加第二套验证层。

旧会话在升级前由真实 1.3.0 写入，包含一次 CodeMode/MCP 调用、图片、store 数据、压缩记录和保留的旧分支。1.5.0 打开时请求／工具调用均为零，JSONL 字节不变；续聊能读取旧 store 并完成一次 MCP 调用，原文件前缀保持。所有模型请求指向本地合成 HTTP/SSE，无真实服务商、NAI 或扣额请求，未读取用户聊天。

接手时记录 3,007 个现有源码／测试文件哈希。除 2 个依赖文件、2 个 README 和 2 处注释外原有文件保持，新增 1 个 schema 回归文件；Dart、UI、Skill、已完成的其他批次及安装目录未改。本轮无 Flutter 依赖或生成输入变动，不运行 pub get 或代码生成。

证据位于 `.dart_tool/pi-1.5.0-upgrade-20261102/`：`verification.json`、`node-before.log`、`node-after.log`、`schema-tests.log`、`flutter-host.jsonl`、`legacy/`、`license-check.json`、`npm-tree.json`。旧会话探针曾修正合成图片的 data URI 格式与 vision 能力配置，未因此改生产代码。

下次桌面交付需同步完整 `tools/nai-agent` 运行资源和依赖，按当前交付收据核验；本轮没有制作分发包或升级正在运行的实例。

本轮空测试暂存目录清理被自动审批以 `blocked by policy` 拦截，未返回具体原因；目录无文件，原样保留，路径已记入 `verification.json`，未改用其他方式删除。

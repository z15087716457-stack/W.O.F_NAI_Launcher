# Pi 1.3.0 升级适配（历史实现报告；已随 r26 安装）

> 状态补注（2026-10-28）：本项已随 r26 安装，累计包含于本机 2.2.0+58；[r26 安装](cumulative-preview-r26-2026-10-18.md)。下文保留实现当时的验证与交付计划，原“尚未安装／下次累计更新”只代表该历史阶段；当前恢复入口见 [接手说明](../../../../04_工具/启动器接手说明.md)。

2026-10-18，Asia/Taipei。用户授权「升级到 Pi 1.3」。

## 改动

- `tool/nai_agent` 三个直接依赖 `pi-coding-agent`／`pi-ai`／`pi-mcp` 固定 1.1.0 → 1.3.0；lockfile 同步 pi-agent-core、pi-codemode、pi-tui 等组件。1.2.0 起上游移除 `@earendil-works/chord`，其 esbuild 依赖随之退出（-28 个包）。`typebox` 1.3.27 不变，Node 要求仍 >=22.19.0，内置 Node 24.18.0 满足。PI-LICENSE 与 v1.3.0 原件字节相同。
- 宿主代码无需改动：未使用 1.2.0 不兼容改动涉及的 `before_agent_start`、`sendMessage/sendUserMessage`、MCP resources 计数；`mcp.mjs` 引用的 SDK 内部路径（`core/mcp-servers.js`、`extensions/mcp/runtime.js`、`core/auth-storage.js`）与 `pi-mcp/testing` 均保留且签名一致。
- 只更新 README／手册中的固定版本引用和注释。

## 验证（均为本地合成服务，无真实模型、NAI、Anlas 请求）

| 范围 | 结果 |
|---|---|
| 升级前基线（1.1.0，Node 24.18.0） | Node 43／43 |
| 升级后 Node 宿主组 | 43／43 |
| 1.1.0 → 1.3.0 旧会话兼容 | 13 项通过：已安装 1.1.0 运行时创建会话，1.3.0 恢复不请求模型、不重放工具，图片产物、CodeMode store、7 入口／19 业务工具、续聊 MCP 调用、旧记录前缀与密钥不落盘 |
| Flutter 真实宿主组（Dart → Node → CodeMode → MCP） | 131 项通过，Flutter 3.47.7 |

证据：`.dart_tool/pi-1.3.0-upgrade-20261018/`（before／after 日志、`legacy-compat.mjs`／`.json`）。

## 可获得的上游改进（摘要）

切换模型时丢弃旧模型思考块、CodeMode 声明显示参数约束并修复多 `text()` 的二次方卡顿、Anthropic 严格工具集回退、"upstream provider returned an error" 可重试、MCP 非对象 structuredContent、Windows `auth.json` EPERM 重试等。

## 状态

源码已提交，尚未安装到桌面运行目录。下次累计更新时随 `tools/nai-agent` 一并同步（含 node_modules、手册与宿主文件），先确认 Studio／Agent 已从托盘完全退出。

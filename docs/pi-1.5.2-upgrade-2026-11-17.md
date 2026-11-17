# Pi 1.5.2 升级 · 2026-11-17

**交付状态更新（2026-11-17）**：已随本机2.4.2+120安装，未自动启动，待实测。[安装与恢复核验](local-2.4.2-build120-2026-11-17.md)。以下保留源码阶段的验证及当时状态。

## 源码阶段记录

源码完成，尚未更新桌面或公开发布。本机仍为 **2.4.2+119／Pi 1.5.0**；旧标签升级、ANN 去冗余、关联标签类别圆点及 RAG 建库重试源码继续保留。备份和核验材料位于 `.dart_tool/pi-1.5.2-upgrade-20261117/`。

## 依赖与适配

- `tool/nai_agent` 直接依赖 `pi-ai`、`pi-coding-agent`、`pi-mcp` 从 1.5.0 固定升级到 **1.5.2**，锁文件中全部 8 个 Pi 组件版本一致。npm 更新 9 个包，其中包含上游要求的 Mermaid 依赖更新。typebox 仍为 1.3.27。
- Node 要求仍为 >=22.19.0，现有固定 Node 24.18.0 满足；未更换 Node。宿主 JSONL 协议、用户工具权限和模型配置继续沿用。
- 缓存保温的延时使用公开的 `pi-ai.getCacheWarmingDelayMs`，移除手写公式。Studio 已明确传入保存的模式，缺省仍为 streaming，不采用上游改为 idle 的默认值。
- 1.5.2 中运行中从关闭启用保温、未知计费状态投影仍需现有适配；已对照实际 SDK 保留。原请求时钟、已结束任务不唤醒、30 分钟／一小时边界及真实停止原因继续由既有流程保证。
- MCP 的公开校验器仅处理通用传输字段，完整 SDK 校验还负责 exposure／toolExposure、旧别名和 Pi 的 OAuth 回调要求。继续调用官方 SDK 完整校验，不复制这些规则；新增无效模式、逐工具模式、CIMD 回调及旧别名检查。连接和 OAuth 生命周期仍由 Pi 持有。
- 中英文宿主 README 同步。`PI-LICENSE` 与 v1.5.2 官方原件逐字节一致，无需改动。

上游收益见 [coding-agent](https://github.com/earendil-works/pi/blob/v1.5.2/packages/coding-agent/CHANGELOG.md)、[pi-ai](https://github.com/earendil-works/pi/blob/v1.5.2/packages/ai/CHANGELOG.md) 和 [MCP](https://github.com/earendil-works/pi/blob/v1.5.2/packages/mcp/CHANGELOG.md) 变更；终端专用界面变化不作为 Flutter 新功能。本批未扩大支持的认证方式或新增默认工具。

## 验证

| 项目 | 结果 |
|---|---|
| 升级前现有宿主测试，1.5.0 | 160／160 |
| 升级后最终宿主测试，1.5.2 | 160／160 |
| Flutter 真实宿主、工具／权限、MCP 设置与保温状态 | 250 项通过，1 项非 Windows 环境测试按平台跳过 |
| 分发入口检查 | 3／3 |
| 1.5.0 合成会话恢复及续聊 | 通过 |
| npm 依赖树与许可证 | 通过 |

完整宿主回归覆盖五协议序列化、MCP／CodeMode、停止与重连、OAuth、工具参数和权限、保温模式切换及图像历史。公开 MCP 基础校验不足以覆盖 SDK 字段的问题已由新增断言复现，保留完整 SDK 入口后通过。

旧会话由备份的真实 1.5.0 宿主创建，含 CodeMode store、图片、压缩和旧分支。1.5.2 打开时模型／工具请求为 0、JSONL 字节不变；续聊读取旧 store、调用合成 MCP 工具，保留原文件前缀及旧分支。所有请求均指向本地合成 HTTP/SSE，不读取用户聊天或密钥，不调用真实模型或 NAI 接口。

较大 npm 包首次下载不完整，改用可续传下载后核对官方 npm 的 SHA-1 与 SHA-512，再通过 npm 缓存安装；包与锁文件仍使用官方来源，安装脚本未执行。材料包括 `pi-coding-agent-1.5.2.verified.json`、`npm-install-cached.log` 和 `npm-tree.json`。

源码保留核对见 `verification.json`：Dart、国际化、生成文件、RAG 修复、补全圆点及此前 Agent 业务修改保持，安装收据未变。未操作应用实例、用户工作区或正式索引。后续桌面交付须按现行流程同步完整 `tools/nai-agent` 与依赖，并清理退役包文件；不能只替换 AOT。

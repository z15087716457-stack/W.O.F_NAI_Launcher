# 图生图暂停与 Agent 提示词卡调查

2026-11-01，桌面 **2.2.4+76**。用户报告暂停图生图后，主生成按钮／Ctrl+Enter 偶尔仍像局部重绘；未打开增强或超分面板，随后恢复正常，并提出可能与 Agent 提示词卡导入有关。本轮按“先查”执行，未修改业务代码或桌面安装。

## 已确认

- 普通生成从 `generationRequestParamsProvider` 读取请求副本。暂停时切回 generate、还原基础模型并清空请求中的 source/mask/focus；草稿原图和蒙版保留。
- 提示词组卡的“导入”只写提示词、负向及角色字段。隔离复现表明，导入后图生图 enabled 仍为 false（保持暂停），接着读普通生成参数仍是 generate，无底图、蒙版。
- **卡片上的“生图”和 Agent 生图有独立漏洞**：共用 `bindNaiAgentGeneration`，直接读取保留原图／蒙版的 `generationParamsNotifierProvider`。同样的暂停状态下，普通生成投影为 generate，这个入口却仍返回 infill 和源图／蒙版。卡片“生图”先调用导入，再使用该入口。

入口：[普通请求投影](../lib/presentation/providers/generation/image_workflow_controller.dart#L516)、[卡片导入](../lib/presentation/wiring/nai_agent/agent_prompt_set_actions.dart#L63)、[Agent 共用生成绑定](../lib/presentation/providers/nai_agent/nai_agent_generation_binding.dart#L55)。

## 证据与边界

普通按钮后端 1 项、真实生成管线单张／连续批次 2 项、纯卡片导入 1 项通过；卡片生成暂停约束的 1 项检查失败，实际为 infill，精确暴露上述漏洞。所有接收器为替身，没有真实模型／NovelAI 请求。批次探针最初错误假定 API 尝试次数等于批次数，已改为检查所有尝试的暂停参数，并保留原日志。

运行进程路径和版本符合登记，2,117 个生产输入与本机交付收据一致；本机桥接未开启，未取得实际草稿快照。因此，**尚不能把卡片生成漏洞直接判定为用户原先普通按钮偶发异常的唯一原因**。

详细日志、隔离探针及结构化结论见 `.dart_tool/img2img-disabled-investigation-20261101/verification.json`。

## 建议修法

让 Agent 的共用生成绑定复用现有 `generationRequestParamsProvider`，使卡片“生图”、Agent 生图与普通按钮采用同一份生效参数；保留草稿、暂停恢复和现有界面，不另加开关或补丁分支。实施时覆盖卡片导入后生成、暂停再开启、模型／底图／蒙版与计价的一致性；显式源图工具继续使用自己的独立请求。

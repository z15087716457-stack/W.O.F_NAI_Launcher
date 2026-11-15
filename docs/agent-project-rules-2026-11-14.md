# Agent 指令查看范围与项目规则收敛 · 2026-11-14

按用户确认方案，在有效源码 `codex/uiux-integration` 完成实现。**仅源码完成，尚未构建／安装，桌面仍为 2.3.4+103。** 原有界面缩放、图库、推荐上下文等未提交改动保留。

## 当前行为

- 复用 `SettingsAsideCard`、`SettingsSelect`、`SettingsCodeView` 和复制按钮；「查看范围」固定在常驻上下文下方。
- 全局范围显示原全局指令和前置内容编辑器；选择具体工作区时沿用现有工作区切换入口，显示该项目根 `AGENTS.md` 的完整路径及只读正文，支持复制和内部滚动。正文固定高 328px；缺失、空内容、加载中与读取失败分别显示状态，查看不会创建空文件。
- 切回全局保留未保存的全局草稿。基础提示词继续沿用原有保存／丢弃与作用范围逻辑；切换前若有未保存的基础提示词，使用既有确认提示。
- 隐藏全局编辑器只改变查看范围，实际提示词仍包含全局前缀、会话前置指令、基础提示词、全局指令与项目 `AGENTS.md`。工作区选择及读取不主动初始化 Agent 或请求模型；已有会话复用现有切换行为。
- 删除独立「本工作区规则」设置行、文件编辑／创建回调、管理工具返回字段和提示词拼接来源。Agent 侧栏改为显示同一个 `AGENTS.md`，原编辑入口改为查看并跳到对应区域。

## 旧文件处理

旧界面曾打开根目录 `instructions.md`，实际提示词读取 `.W.O.F/instructions.md`，形成两份不一致来源。现在仅保留项目根 `AGENTS.md`。

旧 schema 1 工作区首次读取时，在既有布局迁移后执行一次收敛：

1. 读取这两份旧文件及当前 `AGENTS.md`，将原文保存到 `.W.O.F/prompt-history/<uuid>-retired-rules.json`。
2. 将旧文件中非空、尚未被现有正文包含的内容按顺序追加到 `AGENTS.md`；写前再次核对当前项目规则，避免覆盖新修改。
3. 核对旧文件未变化后删除，元数据改为 schema 2。只有空旧文件时不新建 `AGENTS.md`。

新工作区不创建独立规则文件；schema 2 下同名旧文件也不再作为提示词来源。旧布局清单保留文件名仅为兼容历史搬迁，Node 的缺失旧路径回查已移除该文件名。

本轮未运行用户 Studio，真实 PD 工作区三份规则文件的长度及 SHA-256 与施工前一致；迁移只在隔离测试资料中执行。施工前已有的无关源码／生成文件也通过哈希核对保持。[最终边界核验](../.dart_tool/agent-project-rules-20261114/final-verification.json)

## 验证与实绘

登记 SDK 为 Flutter 3.47.7／Dart 3.13.5。

- **258 项相关 Flutter 回归通过**：规则迁移、工作区存储／布局、提示词刷新、管理工具、实际 Pi 会话恢复与跨工作区切换、设置保存／弹窗／分页、Agent 侧栏及 UI 分层边界。[完整日志](../.dart_tool/agent-project-rules-20261114/regression.log)
- **36 项 UI／语言回归通过**，含上述已计数的 12 项新界面测试；覆盖五语言、深浅色、900px 窗口与 150% 缩放，验证内部滚动、只读缺失状态及全局草稿保留。[日志](../.dart_tool/agent-project-rules-20261114/ui-final.log)
- 繁中资源生成检查 **4 项通过**，随后重新生成五语言本地化。额外清理上一轮图库遗留的两条未使用文案，完整 ARB 对齐检查通过。[繁中检查](../.dart_tool/agent-project-rules-20261114/l10n-zh-tw-final.log)
- 随文案退役调整旧图库测试断言，补跑 **2 项缓存／图库界面检查通过**。[日志](../.dart_tool/agent-project-rules-20261114/gallery-l10n-final.log)
- Node 路径与实际 Pi 工作区检查 **5 项通过**；无模型请求。
- 代码生成成功（301 个输出）；全仓 `dart analyze` **No issues found**。[生成](../.dart_tool/agent-project-rules-20261114/codegen.log)／[分析](../.dart_tool/agent-project-rules-20261114/analyze-final.log)
- 已查看真实字体 Flutter 实绘：[工作区](../.dart_tool/agent-project-rules-20261114/captures/workspace-dark.png)／[全局](../.dart_tool/agent-project-rules-20261114/captures/global-dark.png)。原中文 PNG 基准没有修改。

本次使用已确认的 Codex 可视化原型，任务局部测量脚本对照 DOM 与 Flutter 实际组件几何。旧整页 `settings_measure.py` 指向已移除的 `ui-settings` 工作树，未恢复该旧目录；新界面用上述回归中的实绘导出完成同类测量。[测量脚本](../.dart_tool/agent-project-rules-20261114/settings_measure.py)／[原始数据与偏差表](../.dart_tool/agent-project-rules-20261114/measurements.json)

| 对照项 | 确认原型 | Flutter 实绘 | 残差 |
|---|---:|---:|---:|
| 常驻上下文卡宽 | 292px | 292px | 0px |
| 查看范围卡宽 | 292px | 292px | 0px |
| 两张卡片间距 | 14px | 14px | 0px |
| 规则正文框高度 | 328px | 328px | 0px |

扣除场景差异后，上述关键尺寸最大残差 **0px**。场景差异为：Flutter 保留现有设置导航与顶栏、主栏响应宽度、上下文卡原有行高，以及实际工作区路径换行带来的卡片高度；这些没有用原型另造一套组件替换。

施工前差异、文件备份与哈希在 `.dart_tool/agent-project-rules-20261114/`。未安装、启动 Studio、提交／发布 Git 或调用模型／NAI；后续桌面交付时再执行真实用户工作区的首次迁移。

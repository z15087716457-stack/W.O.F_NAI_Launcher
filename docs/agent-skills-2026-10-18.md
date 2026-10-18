# NAI Agent Skill 管理与精简系统提示词（源码，未安装）

2026-10-18，Asia/Taipei。用户确认原型（`.devin/mockups/agent-skills/`）后实施，决定见 D27。源码提交 `d451fa27c`（基于 Pi 1.3.0 提交 `df4348913`）。

## 改动

- **Pi 原生 Skill**：宿主不再 `noSkills`，改由 `lib/skills.mjs` 用 Pi 加载器读三处来源并传 `skillsOverride`：内置 `tools/nai-agent/skills/`（只读）、全局 `agent-data/skills/`、当前工作区 `skills/`。同名优先级为工作区 > 全局 > 内置，被覆盖的项标为 shadowed。不读工作区里的 `.agents/skills`、`.pi`。用户 Skill 可以开关，也可以设成“仅手动”（`disable-model-invocation`，用 `/skill:名称` 调用）。缺 description、名称不合规、文件缺失或解析失败时，不加载并给出错误码。
- **内置 Skill**：原 `manuals/` 并入两个 Skill，`manuals/` 已删除。
  - `nai-studio`：19 个业务工具的共同规则和索引，另有 9 份 references。
  - `nai-prompt`：V4/V4.5、V5 提示词规则。
  - `domain-tools.mjs` 去掉 `route:`，MCP 说明改为指向 nai-studio。
- **系统提示词**：默认提示词换成 4 行（版本 `2026-10-18.1`，约 600 字节，原约 1.1KB）。宿主工具地图只留 4 个入口。旧的 `naiAgentToolMap`（约 4.3KB）和设置页“查看最终提示词”的假回退已删除；没有会话时，这里明确提示“开始对话后由宿主组装”。实际发给模型的系统提示词见 `prompt-probe2.txt`：Studio 提示词、工具地图、`<available_skills>`、cwd 和 MCP。
- **设置页**：
  - 指令顺序最后一环由“工具地图”改为“Skill 目录”。
  - 新增 Skill 分区：
    - 内置项只能查看，或“复制为我的 Skill”。
    - 用户项可开关、切换自动／仅手动、打开文件夹、移除（移到 `agent-data/skill-trash/`）。
    - 可添加文件夹（复制进数据目录，不覆盖同名）或新建模板。
    - 有可信来源提示；出错项显示红字。
  - 右栏新增“常驻上下文”估算和“Skill 位置”卡片。
  - Skill 文件变化后会重启宿主，下一条消息生效。
- **数据**：`AgentSettings` 增加 `disabledSkills`、`skillModes`，计入 `extensionSignature`；新工作区自动建 `skills/`。
- 文案已补全中、英、日、韩，繁中按生成流程更新；删除不再使用的 `set_agOrderTools`。

## 验证（本地合成，无真实模型、NAI 或 Anlas 请求）

| 范围 | 结果 |
|---|---|
| Node 宿主 | 47／47（新增 Skill 解析、优先级、开关、手动、错误、`list-skills.mjs`） |
| Flutter Agent／设置／接线／l10n 与全部真实宿主组 | 1431 通过，5 失败。失败均为既有问题：`dictionaries`、`models`、`models-dark` 三张金图和 `tools_wiring` 两项，在 HEAD `df4348913` 原样复现 |
| 新增 Dart 测试 | 存储 3 项、设置页 Skill 6 项（含 en/ja/ko/zh_TW 不溢出） |
| Agent 设置金图 | 只排除 D27 改动区域：说明行、Skill 分区及以下、右栏；模型区和指令区仍逐像素比对 |
| `flutter analyze`（lib 与相关测试） | 无问题 |

证据：`.dart_tool/agent-skills-20261018/`（`node-test.log`、`flutter-final2.log`、`prompt-probe2.txt`、`capture/` 实绘截图）。

注意：本工作树如果运行 `flutter pub get`，会把未提交的 `pubspec.lock` 改回 HEAD，并把 `package_config` 切到登记的 SDK。本次只用 `--offline` 修正了 `package_config`，`pubspec.lock` 已恢复为原来的未提交内容。

## 状态

尚未构建、安装或启动。下次累计更新与 Pi 1.3.0 一起同步完整的 `tools/nai-agent`：node_modules、`skills/`、宿主文件和 `list-skills.mjs`，并删除运行目录中的旧 `manuals/`。整树打包器会自动带上 `skills/`；本机累计更新的回执需要逐个列出 `skills/**` 文件。

后续：已有工作流（画风复刻、画师登记、ui-mockup）待用户确认后再迁成 Skill；聊天框的 `/skill:` 由 Pi 展开，可在实机上核验。

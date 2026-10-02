# 本地模型参数目录

`assets/data/model_catalog.json` 是随启动器打包的只读模型事实快照。断网时可以补齐已保存、手动添加或 API 返回的模型参数。它不会创建服务、选中模型或填充服务商的远程模型列表。

数据来自 [models.dev](https://github.com/anomalyco/models.dev)，许可副本为 `assets/data/model_catalog.LICENSE`。Pi-Desktop 也使用此来源，其仓库公开了 `apps/desktop/resources/models.dev/api.json`。本目录直接读取 models.dev 的 Git 对象，不复制或执行 Pi-Desktop 的应用代码。

快照分为通用模型事实和服务商模型事实。服务商精确模型 ID 优先，保留该平台的上下文、输出限制、思考档位／预算、温度、图片／PDF 等模态、工具调用、结构化输出、日期和公开价格元数据。别名与通用事实用于兜底；未知信息留空。原生搜索能力单独维护，不把工具调用能力等同于原生搜索。手动覆盖和显式留空均优先于本地事实。

刷新时使用 Python 3.11+。获取公开数据仓库后可不检出工作树（Windows 下部分模型 ID 含 `:`），固定完整提交并生成：

```bash
git clone --no-checkout https://github.com/anomalyco/models.dev.git model-catalog-source
python tool/model_catalog/build_model_catalog.py model-catalog-source --ref <完整提交SHA> --date YYYY-MM-DD
flutter test --no-pub test/presentation/prompt_assistant/local_model_catalog_test.dart
```

脚本根据上游的数据规则递归合并 `base_model`，处理 `base_model_omit` 和符号链接，保留平台级覆盖。无法解析的文件记在 `omittedFiles`，不猜参数；以 0 表示的未知／不适用容量留空，避免自动填入非法请求参数。仅收入可输出文本且非专用类型的模型，所有来源／日期／提交写入快照，便于复核。刷新不会调用任何模型生成接口，也不会读取个人凭据。

服务商页左侧列表只由用户点击“获取列表”后的真实响应填充；空响应和失败均不以预设模型兜底。连接地址、协议或凭据草稿变化后清空旧列表，重新进入服务时也需主动获取；右侧已保存模型独立保留。Pollinations 使用公开的 `/v1/models` 接口主动发现模型，不再返回硬编码列表。

`ModelConfig` 保存用户的覆盖值和 `customFields`。目录重新加载时保留这些字段，包括显式清空的继承值。
`catalogEntry` 是运行时只读信息，不进入用户配置 JSON。
添加或读取模型时自动填入目录记录的上下文与最大输出；之后手动修改的值由 `customFields` 保留。
右栏显示这些实际配置的容量，未标注项显示 `—`。上下文仍仅用于记录容量；最大输出由各协议发送。
模型顺序按用户保存的列表顺序恢复，功能接口只覆盖模型声明支持的思考档位。

模型高级设置支持自定义请求头与请求体。请求头名称不区分大小写，模型值覆盖连接值和协议默认值。
请求体使用字段名与 JSON 值，保留字符串、数字、布尔、数组、对象和 null 的类型；对象递归合并，其他值替换。
模型 ID 由模型列表决定，当前执行器使用非流式请求；这些字段的冲突在编辑处提示。
配置按模型保存在现有安全存储的独立命名空间，普通设置与复制配置不包含请求头／请求体的值。
运行请求、连接测试和请求记录共用映射；认证数据在进入请求记录及响应文本前脱敏。
删除模型或服务时清除对应设置，复制服务不会沿用模型请求凭据。

思考参数按连接协议发送，别名始终不替换请求模型 ID：

- [OpenAI](https://developers.openai.com/api/docs/guides/reasoning)：Chat 的 `reasoning_effort`，Responses 的 `reasoning.effort`。
- [DeepSeek](https://api-docs.deepseek.com/guides/thinking_mode/)：直接 Chat 连接使用 `thinking.type` 和 `reasoning_effort`。
- [Gemini GenerateContent](https://ai.google.dev/gemini-api/docs/generate-content/thinking)：Gemini 3 使用 `thinkingLevel`，预算型模型使用 `thinkingBudget`。
- [Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)：自适应使用 `thinking.type=adaptive` 和 `output_config.effort`；旧预算模型发送 `budget_tokens`。

预算型模型没有原生的 low/medium/high 名称。客户端将它们映射为 1024/8192/目录预算上限，并限制在模型允许范围；Anthropic 还限制在最大输出以内。未选档位时不发送预算。
已知不接受采样的模型省略旧配置中的 Temperature/Top P；旧值仍保留在配置中。

原生网络搜索表示厂商托管的搜索能力，和通用工具调用不同。
自动标注仅覆盖核实的模型；未知情况允许用户手动标注。
当前翻译连接尚未接入这些搜索工具，勾选能力不会自动发起搜索：
[Google](https://ai.google.dev/gemini-api/docs/google-search)、[OpenAI](https://developers.openai.com/api/docs/guides/tools-web-search)、[Anthropic](https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool)。

更新后验证本地事实、模型发现 UI 与相关适配器，重新打包 Flutter assets。

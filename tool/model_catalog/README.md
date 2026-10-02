# 离线模型目录

运行时只读取 `assets/data/model_catalog.json`，不依赖联网，也不读取用户密钥。
快照来自 [models.dev](https://github.com/anomalyco/models.dev)，保留其 MIT 授权。
快照中的 `revision` 固定数据版本，`omittedFiles` 记录上游断开的符号链接。

`models` 保存目录容量、别名、输入模态和支持的思考选项；`bindings` 将服务商 ID 映射到基础模型。
匹配顺序是服务商精确绑定、基础模型精确 ID、唯一的完整 ID 后缀。
不通过模糊名称、版本猜测或用户的 token 配置生成目录事实。
左侧服务列表来自已选模型、内置服务默认 ID 或实际 `/models` 返回值；离线目录只补充元数据。

`ModelConfig` 保存用户的覆盖值和 `customFields`。目录重新加载时保留这些字段，包括显式清空的继承值。
`catalogEntry` 是运行时只读信息，不进入用户配置 JSON。
上下文和最大输出不自动写入请求；留空表示由服务决定，避免一次请求意外使用目录最大输出。
模型顺序按用户保存的列表顺序恢复，功能接口只覆盖模型声明支持的思考档位。

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

更新数据时先检查上游差异，再运行：

```bash
PYTHONIOENCODING=utf-8 python tool/model_catalog/build_model_catalog.py /path/to/models.dev
```

脚本只解析固定提交的 Git 对象与 TOML，不执行上游代码，兼容 Windows 无法检出的冒号文件名。
更新后运行 `local_model_catalog_test.dart`、`model_foundation_ui_test.dart` 和相关适配器回归，再重新打包 Flutter assets。

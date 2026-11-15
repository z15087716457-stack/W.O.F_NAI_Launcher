# Agent 标签工具选择指引

2026-11-15。按用户确认的[效率调查分工](tag-search-efficiency-2026-11-15.md)修改现有指引，仅源码完成，尚未构建／安装。没有新增工具、参数、检索策略或运行分支。

## 当前规则

- `tag_query`：已知英文标签名／别名；只有名称片段时用`contains=true`。
- `studio_search(source=tags)`：动作、构图、气氛等描述，不知道标签名，或字面搜索未解决；仅在该来源ready/partial时使用，partial只覆盖已索引内容。
- `tag_related`：围绕已知标签补充搭配／变体；选少量具体种子，exclude已有提示词，不把整段通用标签都当种子。
- 查到足够结果就停止，不默认串行跑三种搜索；陌生含义仍用`wiki_query`核对。

## 接线

`nai_agent_studio_provider.dart`继续在`studio_context`的summary／draft投影中提供`search_hint`。只替换原有两段文本，ready/partial条件及所有状态投影保持；读取上下文仍不会创建RAG设置或自动启动控制器。

`nai-prompt`已经要求遵循`search_hint`，继续复用这一入口，不在系统提示或创作Skill再复制整套分工。`nai-studio/references/lookup.md`承接详细选择说明，`search.md`改为链接它；`domain-tools.mjs`的两个既有标签工具描述同步，字段、名称和schema保持。

就绪时的完整hint约58个英文词；两个标签工具描述合计从456字符减至414字符。长度统计只作文本规模核对，不当作具体模型token实测。RAG算法、模型、索引和查询预算均未改。

## 验证

本地材料：`.dart_tool/tag-tool-guidance-20261115/`。

- 63项Flutter通过：`context_search_status_test`、`search_binding_test`、`tag_related_test`、`studio_host_integration_test`。覆盖summary／draft、未初始化／disabled／busy／partial／ready、只读工具及实际Pi发现和调度；全部使用隔离数据和合成服务。
- 34项Node工具目录／schema／Skill／MCP专项通过。保留默认工具集、按需发现及真实schema校验。
- 改动Dart与对应测试分析0问题，formatter无额外变更。
- 施工前保存2551项源码哈希，最终仅5个预期源码／测试／按需说明文件改变，其余保留。`change.diff`与`source-audit.json`记录施工范围。
- 首次测试命令误写不存在的`studio_search_test.dart`，日志保留在`flutter-tests-first-invalid-command.log`；更正为实际`search_binding_test.dart`后完整命令63项通过，不计错误命令为通过。
- 未检测到符合路径的开发热重载会话，未另起Studio、请求真实模型或生图；未修改用户指令、草稿或数据库。桌面仍为2.3.4+103，实际模型工具选择改善尚待后续会话核验。

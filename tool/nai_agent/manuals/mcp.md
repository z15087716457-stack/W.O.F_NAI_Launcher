# MCP 与 CodeMode

默认入口是 read、write、edit、bash、studio_context、ask_user、codemode。NAI Studio 业务在 mcp__nai_studio，详细工具不默认声明；发现函数均为异步，必须 await；在 CodeMode 中用 searchTools(query, {namespace:"mcp__nai_studio"})、describeTool(name) 和 describeNamespace(name) 读取需要的说明。

```javascript
const state = JSON.parse(await tools.studio_context({scope:"draft"}));
const result = await tools.mcp__nai_studio__prompt_update({
  changes: {prompt: "blue eyes"},
  expected: {prompt: state.draft.field_versions.prompt}
});
if (result.isError) throw new Error(result.content.map(c => c.text ?? "").join("\n"));
text(result.structuredContent);
```

MCP 结果为 content／structuredContent／isError。用 image(result.content[i]) 显示图片，不要打印 Base64。独立读取可用 Promise.allSettled；写入、依赖操作和确认流程依序 await。脚本结束会取消尚未结束的工具，已发生的更改不回滚。

ask_user 为模型直接提问工具，不能从 CodeMode 嵌套调用。用户确认生图的原生卡片由生成工具等待，不可用模型文字或参数跳过。内置 Studio MCP 可以等待长时间任务；不要给含确认或超分的脚本设置短 timeout_ms。

MCP 服务器在设置内添加与管理；支持 stdio 和 Streamable HTTP。外部服务器默认 codemode，deferred 通过 tool_search 后直调，direct 常驻，hidden 不可调用。设置变更于下一次空闲操作恢复同一会话。工作目录使用当前工作区；Pi 四个基础工具和用户服务器具有用户选择的本机权限，工作区绑定不是系统沙盒。

参考固定版本的 [官方 MCP 文档](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/mcp.md) 与 [CodeMode 文档](https://github.com/earendil-works/pi/blob/v1.3.0/packages/coding-agent/docs/codemode.md)。

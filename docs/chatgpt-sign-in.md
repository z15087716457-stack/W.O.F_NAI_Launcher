# ChatGPT 登录（开发版）

Studio 的「设置 → 模型与接口」新增 ChatGPT 服务商。它使用 OpenAI 的 Sign in with ChatGPT 授权流程，不需要 API Key，也不读取其他程序的登录文件。

## 使用

1. 添加服务商，选择 **ChatGPT**，点击 **添加并前往登录**。服务商会立即保存，无需填写 Key；已有 ChatGPT 服务商可直接选中。
2. 点击 **Continue with ChatGPT**。在系统浏览器中登录并授权，回到 Studio 查看账号与套餐状态。
3. 登录成功后会获取这个账号可以使用的模型。在服务商目录中选择需要的模型并添加。
4. 在「功能分配」或 NAI Agent 的模型选择中使用该服务。

只有身份登录成功还不够；账号还需要服务端授予 ChatGPT 套餐使用权限。可用套餐、模型和额度以授权页、模型列表及 ChatGPT 的实际用量限制为准。点击「管理用量」可查看相关设置。

连接第二个账号或工作区时，新增一个 ChatGPT 服务商并分别命名。每个服务商保留自己的授权注册；重新授权已有服务时不会静默换成另一账号。退出登录会清除本地令牌并尝试撤销服务端授权；若撤销失败，界面会提示到 ChatGPT 设置中断开应用。

## 数据和请求

- 登录凭据写入系统安全存储；普通服务商配置和导出文件不含令牌。沙箱运行只在内存保留凭据。
- 使用官方 `https://api.openai.com/v1`，不支持自定义地址或认证头。请求走 Responses 流式接口，并强制 `store: false`。
- 套餐请求不发送 `max_output_tokens`、采样参数等预览接口不支持的字段，模型目录中的输出上限仍可显示。Agent 的本地工具通过 `additional_tools` 声明，系统指令使用 developer 消息。
- Agent 启动时采用 Studio「网络与代理」的当前设置；修改代理后重启 Studio 生效。本机回环服务不经过代理。
- 「请求记录」包含模型连接测试，HTTP 错误的正文经过脱敏后可在详情中查看；记录仅保留在当前运行会话中。
- Agent 在每次请求前获取有效凭据。并发续期合并为一次；更新后的凭据同样参与日志脱敏。
- 只有收到 `response.completed` 才算成功；失败、未完成和连接中断均报告错误，不把部分回复当成成功结果。
- ChatGPT 历史对话不会导入 Studio。Studio 的会话、模型配置和工具权限仍由 Studio 管理。
- 登录和获取模型列表不会生成 NovelAI 图片。生图仍需原有的 NovelAI 账号和明确授权。

## 开发验证

自动测试使用合成账号、签名令牌和模拟模型服务，覆盖 PKCE、回调 state、ID token 验证、注册复用、续期、账号隔离、退出登录、流式完成状态和凭据脱敏。界面测试使用真实字体，覆盖简中、繁中、英语、日语、韩语的窄屏布局。

实际账号的授权可用性仍需用户在浏览器中完成验证；自动测试不代表真实登录成功。

新版服务商工作台另有完整设置页回归：简中、英文的添加入口、未登录状态、授权回调、模型目录与添加、退出登录，以及授权失败和取消。页面投影只读取账号状态，不尝试获取未登录账号的访问令牌。

实现依据：OpenAI [登录流程](https://developers.openai.com/siwc/token-sharing-open-source/sign-in)、[模型与推理](https://developers.openai.com/siwc/token-sharing-open-source/models-and-inference)、[预览限制](https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations)、[账号与会话](https://developers.openai.com/siwc/token-sharing-open-source/profiles-and-sessions)。

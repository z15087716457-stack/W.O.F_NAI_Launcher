# NAI Agent E8 本机交付

2026-10-08，Asia/Taipei。用户明确授权安装当前已完成版本。Windows Release／Glass 构建通过，保留原生 Glass 与存储身份；完整包随带 Node 24.18.0、官方 Pi 1.0.4、固定依赖、许可和六份按需操作手册。工作区与指令数据位于不受更新清单管理的 agent-data。

打包后的独立运行时使用隔离工作区／本地 SSE 完成启动、工具回合、提示词、恢复与退出五项检查；没有真实模型或 NAI 请求。原 E8 定向验证为 106 项，不能冒充全量回归。安装后 208 资源、15069 宿主文件、31 原生文件、15312 托管文件与 1486 编译输入通过；65 个私有状态文件保持，超分权重／环境不在写入或哈希复验范围。

本机运行包仍为 E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release。11:12（UTC+8）安装完成，AOT ff2754a511c48a38e916480ce1636e5009734eb80fdce22eeb55fd2461b2cab2；原安装根 .dart_tool/nai-agent-e8-delivery.json 与当前收据一致，单步备份及恢复只读预检通过。未自动启动／重启／热重载，未提交、推送或发布 Release。

源码 HEAD af54e9ac，Agent 改动仍未提交，以交付收据逐项 SHA-256 固定，不宣称功能工作树干净。MCP／CodeMode 仍待接入，当前工具直接注册。完整说明与证据见工作区 04_工具/NAI_Agent_开发/28_E8运行时打包与本机安装.md 和有效源码 .dart_tool/nai-agent-install/。

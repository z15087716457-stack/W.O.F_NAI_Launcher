# 本机 2.2.4+77 安装核验

2026-11-01（Asia/Taipei），按用户“把这几项更新一起推送到桌面安装”完成。本批为本机交付，未提交 Git、发布新标签或自动启动应用；公开仍为 2.2.4+75。

## 本批内容

- [会话前置指令](agent-chat-prefix-2026-11-01.md)：指令页增加同款卡片，各聊天独立保存并放在内置提示词前，支持首次发送前保存、清空、切换与重启恢复。
- [MCP 自动连接及中文显示名](mcp-startup-display-name-2026-11-01.md)：进入 Agent／MCP 页复用原 Pi 初始化与连接；显示名和内部工具标识分开保存。
- 保留原 +76 的 Portable 更新、PR 组合请求与错误提示修复及全部已有功能。历史侧栏优化和图生图暂停调查继续按用户决定搁置。

## 真实安装

原桌面 `W.O.F NAI Studio.lnk` 仍指向登记运行目录 `nai-launcher-src/build/windows-glass-preview/runner/Release/nai_launcher.exe`。用户已确认从托盘完全退出，安装过程中再次检查进程为空。

共 15,312 个程序文件逐项核验；仅更新 `data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、`app_files_manifest.json`、`package-info.json` 五个文件，新增／移除为零。快捷方式、相邻用户／Agent 数据、旧路径入口及三个正式索引文件的元数据均保持；没有读取或写入正式索引内容。

包基于 `49e8ed3100fbfa5896fb8467a8b9f72dae522956` 和本轮未提交改动，冻结 2,117 个生产输入；相对 +76 有 21 个输入变化（20 个功能／语言文件和本机构建号）。AOT SHA-256：`dc2ecaa035390a9d1035fe7f92c83e136eb2b1db23d47b172b0e4ceca417ef1a`。主机版本与清单均为 **2.2.4+77**。

## 验证与耗时

- 按源码哈希复用 209 项已覆盖回归（首轮旧目录夹具修正后专项复测通过）、12 文件定向分析和既有真实字体实绘；新增 5 项版本检查、12 项安装／回退夹具通过。
- Windows Release 构建通过，完整资源、原生依赖、PE 导入及 Agent／RAG 输入与原包一致；差量组包没有复制完整程序目录。
- 构建 95.2s，组包 3.6s，安装 36.9s。未请求真实模型、外部 MCP 或 NovelAI。

## 恢复与材料

本批材料在有效源码 `.dart_tool/agent-session-install-20261101/`，本机收据为根 `nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。完全退出 Studio 后，运行本批 `update.py rollback` 可恢复安装前 **2.2.4+76**；全部回退文件和完整 `data/` 备份已核验，旧 +74 回退也保留。

自动审批拒绝删除本批五个安装暂存文件及空目录，原因为 `blocked by policy`，清理未执行；约 43.9 MiB 暂存保留，程序安装已完成。当前状态见 `CLEANUP-HELD-20261101.json`，不要将其写成已清理。

最终证据：`final-verification.json`、`package-verification.json`、`installer-fixtures.json`、`completion.json`。

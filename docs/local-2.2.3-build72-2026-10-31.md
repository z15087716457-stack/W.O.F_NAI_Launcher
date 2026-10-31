# 本机交付 2.2.3+72

2026-10-31，按用户“ok，安装吧”完成。运行目录仍为 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release/`，原桌面快捷方式保持。未自动启动 Studio，未推送 Git 或制作公开发布包。

## 内容与来源

包含 [Agent 输入与 Pi 自管理](agent-input-self-management-2026-10-31.md)的全部 9 项改动：多图拖入、附件放大、输入区拖放、MCP 状态／表单，以及统一的 Skill／扩展与 Pi 包／MCP／自身设置和指令管理。默认七入口保持。

有效源码分支 `codex/uiux-integration`，基于 `1ae54c978252aba2b42218dd2b3f27c045b0d539` 的未提交改动；冻结并核对 2,114 个生产输入，新增原生扩展、包适配器、管理实用程序与参考文档均已组包。版本升为 `2.2.3+72`，公开版本仍是 `2.2.3+71`。

本次交付以实际安装文件建立基线，不沿用旧 +70 收据。先前 +71 Portable 更新留下的 26 项旧字节属于历史状态；新包已整体核对。现有 Portable 迁移代码问题仍独立待修，本次直接安装不经过该路径。

## 验证

- Windows Release 构建通过，Flutter 3.47.7／Dart 3.13.5；EXE 的 ProductVersion、FileVersion 均为 `2.2.3+72`，原生数据身份保持 `com.example/nai_launcher`。
- 新跑 59 项版本／更新检查、12 项安装及回退夹具；沿用本轮已完成的 1,439 项相关 Flutter 回归、127 项 Node 测试及静态分析证据。
- 打包后的 Node 24.18.0／Pi 1.3.0 通过 Agent／CodeMode／会话恢复冒烟；直接调用原生自管理入口，管理实用程序完成隔离本地包的安装、解析、禁用和卸载，保留源码且未在项目根建立 `.pi/`。
- 4 个 SQLite 素材库、19 份字体、226 个资源文件检查通过；打包后的 RAG 宿主／worker 启停及 7 项 checkpoint 回归通过，未加载模型或扫描正式图库。
- 安装后逐项核对 **15,312 个程序文件**，本次修改 35 个、新增 4 个、移除 0 个；包含 18 个与本机编译结果不同的原生插件，一同交付以匹配新 AOT，其余 Glass 包组件保留。
- 快捷方式、数据根目录、兼容联接和 3 个正式索引文件元数据保持；未打开正式索引，未操作草稿或调用真实模型／生成接口。

安装 AOT SHA-256：`b9bb4897ce5da3a257b4294b84af5e1d3d3dc1608cd705372115ef731bc59d63`。包声明、清单与实际文件一致。

## 收据与恢复

- 当前收据：`E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。
- 交付核验：`.dart_tool/agent-management-install-20261031/final-verification.json`；编译输入、组包核验、测试日志及旧收据保存在同目录。
- 验证后已清理本批重复的 `program/`、`payload/` 和运行目录内的空暂存，仅保留收据、日志、脚本及回退材料；清单见同目录 `CLEANUP-20261031.json`。
- 回退备份：`.dart_tool/agent-management-install-20261031/rollback/`，已校验。完全退出 Studio 后，使用该目录同级的 `update.py rollback` 恢复本次安装前的实际 +71 状态，包含当时的混合载荷；不会变成完整官方 +71。

真实跨窗 OLE、OAuth 浏览器往返、第三方 npm／git 网络安装按实机反馈验收。中文输入法偶发失效继续暂缓。

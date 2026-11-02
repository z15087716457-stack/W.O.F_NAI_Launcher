# 本机 2.2.4+78 安装核验

2026-11-02（Asia/Taipei），按用户“先把这批更新安装到桌面”完成。仅本机交付，未推 Git、发布标签或自动启动；公开仍为 2.2.4+75。

## 本批内容

- 关闭分组后的历史／画布批次顺序一致。
- 图片级多选联动蓝框，主图区移除数量角标；单张与分组使用相同选择状态。
- 手动保存按路径增量更新图库，相同路径不重复更新。
- 本地放大滑条可准确选中 2.00 倍，点击倍率可输入原有 1–4 倍范围。
- WebP 拖入／粘贴回到统一 NovelAI 元数据检测。
- 更新状态区分未检查、已忽略、失败和确认最新，避免错误绿标。
- Windows 单实例按安装目录区分，旧目录实例不再阻止新目录启动。
- 退出先隐藏主窗口，独立任务并行收尾，接入 Agent 保存和关闭；普通关窗不等待小窗清理才隐藏。

保留 +77 的会话前置指令、MCP 自动连接／中文显示名，以及 +76 的 Portable、PR 与错误提示修复。**Setup 写入失败修复已在源码，需下次重新打包 Setup 才会进入分发安装器；本次没有制作分发包。**

## 真实安装

- 桌面原 `W.O.F NAI Studio.lnk` 保持，仍指向 `nai-launcher-src/build/windows-glass-preview/runner/Release/nai_launcher.exe`。
- 安装前、覆盖过程中和最终核验均检查 Studio／自带宿主已退出。没有结束用户进程或启动新应用。
- **15,312 个程序文件逐项核验通过**，只替换 `data/app.so`、`nai_launcher.exe`、`CHANGELOG.md`、`app_files_manifest.json`、`package-info.json` 五个文件，新增／移除为零。
- 用户／Agent 数据根、旧路径入口、快捷方式和三个正式索引文件的元数据均保持；未读取或写入正式索引内容。
- 冻结 **2,119 个生产输入**，相对 +77 改变 49 个；Git HEAD 仍为 `49e8ed3100fbfa5896fb8467a8b9f72dae522956`，另包含本轮未提交源码。AOT SHA-256：`42c85f27bce7ee670174232c5de218638d504a5219106091e1b81481a7f1607b`。
- EXE 版本、完整清单及包信息均为 **2.2.4+78**。原生单实例目录标记已进入真实 Release EXE；原生依赖、资源、Agent 和 RAG 工具输入与原包一致。

## 验证与耗时

- 按冻结源码哈希复用各专项证据：生图／选择／保存 401 项、本地放大 64 项、导入／更新状态 115 项、退出与生命周期 214 项；这些范围可能重叠，不加总为新的不同用例数。原生实例 12 个场景及 5 项隔离存储验证保持。
- 本批新增 5 项版本检查、12 项安装／失败恢复／回退夹具通过；Windows Release 完整构建、PE 版本／身份／导入以及资源和原生库核验通过。
- 构建 111.3s、组包 3.6s、安装 38.6s。没有复制完整 `program/` 或下载模型；未请求真实模型／NovelAI。真实窗口操作与本次退出速度由用户打开新版后验收。

## 恢复与材料

收据：根 `nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。

本批材料：有效源码 `.dart_tool/desktop-polish-install-20261102/`。完全退出 Studio 后，运行本批 `update.py rollback` 可恢复安装前 **2.2.4+77** 程序和收据；已核验改变文件及完整 `data/` 回退备份。此前 +76／+74 等回退材料保持。

自动审批拒绝了本批五个安装暂存文件及空目录的清理，仅返回 `blocked by policy`，没有更具体原因；命令未执行，当前 `payload/` 保留，不改道重试。原 +77 批次此前被拦截的暂存也未操作。见 `CLEANUP-HELD-20261102.json`。

最终证据：`final-verification.json`、`package-verification.json`、`installer-fixtures.json`、`completion.json`。

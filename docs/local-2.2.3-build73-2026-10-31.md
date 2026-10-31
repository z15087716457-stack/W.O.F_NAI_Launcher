# 本机安装 2.2.3+73

2026-10-31（Asia/Taipei）。按用户“ok，把这几项更新一起推送到桌面安装吧”，四项更新已交付原桌面入口。公开版本仍为 **2.2.3+71 / v2.2.3**；未推送 Git、制作分发包或自动启动应用。

## 本次范围

- 偏好与 Windows 加密凭据直接使用相邻 `user-data`；新装不建旧 AppData 联接，已有联接的归属或断开不再阻止当前启动。保留一次性旧资料迁入，当前文件不覆盖。[实现](app-data-location-review-2026-10-31.md)
- 补全取代上方占位提示、去掉左侧图标，在原输入区底部沿用正常输入排版，保留 Tab 提示与采纳。[验证](../.dart_tool/agent-suggestion-layout.json)
- 回车或按钮发送时平滑回到底部并恢复跟随；编辑、粘贴、换行与输入法候选确认保持阅读位置。[验证](../.dart_tool/agent-composer-follow.json)
- 删除会话后保留列表和搜索条件，支持连续删除当前会话直至最后一条，沿用确认与撤销。[验证](../.dart_tool/agent-chat-delete.json)

## 安装与核验

- 基于当前 `codex/uiux-integration` 的 `1ae54c978252aba2b42218dd2b3f27c045b0d539` 及既有未提交改动，冻结 **2,116 个生产输入**。本次只将构建号 +72 提升为 +73，四份功能证据与实际源码逐项核对。
- 安装前原 +72 的 **15,312 个受管程序文件**、收据、清单与 AOT 核对一致，无需重建基线。+73 安装后同样逐项通过；修改 **5** 个文件，新增 **0**、移除 **0**：`CHANGELOG.md`、`package-info.json`、`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`。
- 安装 AOT SHA-256：`46b460131558ddf08c98bd1510e38b3a55f80b573da6742847c4917f231b2f97`。EXE／包信息为 +73，清单与收据一致；原生插件保持，Agent 运行文件仍为已核验的 Pi 1.3.0／Node 24.18.0。
- 既有存储 908 项、Agent 245 项及更早连续删除范围 366 项验证按原记录复用，不把重叠用例相加；最后沙箱入口另复验 5 项。全仓分析、原生 Windows 合成加密读写与本次 Windows Release 编译通过。
- 本次新跑 **59 项版本／更新检查、12 项安装回退夹具**。完整包的 4 个 SQLite 资源、19 个字体、内置 Skill、Agent／CodeMode／会话恢复、自管理本地包安装／解析／禁用／卸载、RAG 原生宿主启停及 7 项 checkpoint 回归均通过；无真实模型或生图请求。
- 原桌面快捷方式及目标保持。`user-data`、`agent-data`、WebView 状态、既有旧路径入口和 **3 个正式索引文件元数据**均保持；没有打开正式索引或改写账号、草稿、会话。路径标记升级由用户下次启动执行。
- 删除本次重复 `program`／`payload` 共 15,317 个暂存文件（约 0.83 GiB）及运行目录内空暂存目录；回退备份与收据保留。[清理记录](../.dart_tool/agent-polish-install-20261031/CLEANUP-20261031.json)

## 证据与回退

[安装后核验](../.dart_tool/agent-polish-install-20261031/final-verification.json)、[包核验](../.dart_tool/agent-polish-install-20261031/package-verification.json)。正式收据仍为 `nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。

需要回退时先从托盘完全退出 Studio，再执行 `.dart_tool/agent-polish-install-20261031/update.py rollback`；恢复本次安装前的完整 +72 程序状态，不改用户数据。当前暂存已清理，旧 `prepare/install` 不能当作现成包重跑。Portable 更新清单分隔符问题仍独立待修，本次没有修改更新器。

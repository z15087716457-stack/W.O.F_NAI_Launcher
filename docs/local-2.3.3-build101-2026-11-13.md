# 本机安装 2.3.3+101

2026-11-13：按用户「推送到桌面更新」指令完成 Windows 本机交付。未启动 Studio、请求真实模型／NAI、提交 Git 或发布公开版本。Windows／Mac 公开包仍为此前 2.3.3+99。

## 本批内容

- 块多图、每图独立裁切、缩略图直达／横向滚动、悬停箭头、默认显示范围和缩放百分比；悬浮卡词条最多五行。[实现](block-preview-gallery-2026-11-13.md)
- 外部 Agent 经 MCP／命令行使用已启用 Skill 和 24 个原生 Studio 业务工具，复用卡片／产物、独立会话、权限及取消恢复。[接入](external-agent-session-2026-11-13.md)
- 外部操作收起通知位于画布底部两条工具条之间，五秒淡出，窄画布避让，查看保留草稿。[通知](external-agent-canvas-notice-2026-11-13.md)
- Agent 图片首看优先高清，已看历史用压缩副本，原图和会话保留。[图片与空回](agent-image-history-timeout-2026-11-13.md)
- 缓存保温支持运行中开启，显示实际停止原因。[保温](cache-warming-live-mode-2026-11-13.md)
- 按非流式反馈撤去新增 120 秒无进展计时器，保留空回报错、手动停止和上游错误处理。[计时移除](agent-no-timeout-2026-11-13.md)

此前 +100 功能继续保留。历史图误认仅留排查／回归，没有新增附件归属提示。[排查](agent-image-attribution-2026-11-13.md)

## 构建、安装与验证

有效源码为 `E:/A.I/NovelAI/.devin/wt/ui-integration`，基于 `eeca563f198763085e0f593dba2bd53b60213590` 及 121 个未提交文件；冻结 2,158 个生产输入，其中相对 +100 改变 72 个、移除 0 个。登记 Flutter 3.47.7／Dart 3.13.5，使用 `--build-name=2.3.3 --build-number=101 --no-pub --no-tree-shake-icons` 构建成功。存储身份仍为 `com.example/nai_launcher`。

全仓 Dart 分析 0 问题，3 项打包检查通过。对沿用安装器进行了新模块添加、模拟替换失败恢复及正常安装后回退的隔离验证。复用此前已通过的功能回归，不重复累加重叠测试；最近一轮为完整 160 项 Node 与 74 项 Flutter，来源摘要保存在 `test-summary.json`，覆盖图片、协议、保温、空回、取消及会话路径。外部 Agent、通知和块多图的较大范围回归及实绘见上述专项记录。

安装前现场检查 Studio 和捆绑进程退出，逐项核对 +100 安装基线。差量更新 13 个程序文件：AOT、EXE、日志、两份包清单，以及 8 个 Agent 文件；其中新增 `external-mcp.mjs`、`lib/external-bridge.mjs`、`lib/image-context.mjs`、`lib/studio-tools.mjs`。全部 15,557 个程序文件核验通过，无文件退役；原生库、Flutter 资源及 Node／Pi 依赖复用原载荷，Pi 仍为 1.5.0。

安装后的 Agent 模块语法检查通过，额外超时标记和已撤回的零新附件提示均不存在。原始 `data/` 完整备份、+100 程序／收据回退已核验。桌面快捷方式、用户数据入口、旧数据联接、图库数据库和 3 个 RAG 索引文件元数据保持；121 个已有源码改动及构建输入哈希保持。没有执行已暂停的暂存清理。

运行目录保持 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`。未自动启动，实际窗口与使用效果由用户自行验收。

## 证据与恢复

证据在 `.dart_tool/local-2.3.3-build101-20261113/`：`final-verification.json`、`package-verification.json`、`installed-agent-checks.json`、`test-summary.json`、构建／分析日志、安装记录及 `rollback/`。当前收据为 `E:/A.I/NovelAI/nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。

新 AOT SHA-256：`c44127c272135c22da8352612e328c9139996240a3af5524588961d24ed73318`。

完全退出 Studio 后，可从有效源码回退到 +100：

```powershell
python .dart_tool/local-2.3.3-build101-20261113/update.py rollback
```

该入口恢复程序与收据，不改用户数据；更早回退材料继续保留。

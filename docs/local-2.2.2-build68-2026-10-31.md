# 本机桌面更新 2.2.2+68 · 2026-10-31

用户明确要求“ok，安装吧”，已于 **2026-10-31 10:36（Asia/Taipei）** 从 **2.2.2+67** 原位安装 **2.2.2+68**。本次只更新本机，未自动启动、重启或操作 Studio；公开版仍为 2.2.2+64。

## 已安装范围

- 压缩摘要模型投影末尾的一句原文回查提示，查询工具的现有放大镜动画，卡片外独立居中的压缩节点。[实现与界面验证](agent-history-hint-icons-2026-10-31.md)。
- 共用共现词频降权，覆盖 Agent、Ctrl+左键及完整单标签框选；手动 tags 视觉召回的 800/目标 1000 候选提前返回；outline 合法附件信封清理。[实现、质量与限制](tag-query-followup-2026-10-31.md)。

默认七入口、持久化摘要原件、完整原文回查、分页与脱敏保持。多标签／部分短语继续走现有搜索。未增加模型、索引格式或自动重建；69 条只读查询的质量对照及共现高频压力查询限制沿用上述报告，不重复冒充安装后的端到端测量。

## 构建与安装核验

| 项目 | 结果 |
|---|---|
| 编译提交 | `7f999488ecf383c0d42360a0f2f65c5945c65736` |
| AOT SHA-256 | `b515ef3a9e83cdc214935de8b54b99be90f98ef2e37b71b4c9ad3d5d2e8a71e0` |
| 程序文件／替换／删除 | 15295／6／0 |
| 资源／生产输入 | 226／2106 |
| 原生身份 | `com.example/nai_launcher`，EXE 2.2.2+68 |
| 正式收据 | `nai-launcher-src/.dart_tool/glass-rollout-delivery.json` |
| 本批材料 | `.dart_tool/cumulative-2.2.2-r4-20261031/` |

固定生产输入后新跑 **1003 项合并范围、59 项版本／更新、119 项 Node、124 项 Python（另 3 项既有宿主用例跳过）、12 个安装／回退夹具**，均通过；完整静态分析无问题。不是全仓测试声明。

Windows Release、全部程序文件、4 个 SQLite 资源库、字体和原生依赖检查通过。整包合成 Agent 冒烟覆盖默认七入口、deferred session_history、tag_related、CodeMode 与会话恢复，网络仅限本地假服务；包内 RAG 宿主与工作进程使用隔离开发环境启停，不发送 configure/query/build 或加载真实模型。

覆盖前复核程序完全退出、备份完整程序 data/、被替换程序文件及上一收据；安装后逐项复验全部登记文件与回退备份。用户数据根、旧 AppData 兼容联接、原桌面入口及 3 个正式索引文件元数据保持，安装阶段没有打开正式索引或自动启动应用。

## 本次替换文件

- `app_files_manifest.json`
- `data/app.so`
- `data/flutter_assets/tool/rag/engine.py`
- `data/flutter_assets/tool/rag/pool.py`
- `nai_launcher.exe`
- `tools/nai-agent/lib/extensions/session-history.mjs`

其余程序文件与 +67 保持一致；用户数据不在程序载荷中。

## 单步回退

仅在用户要求回退且从托盘完全退出 Studio／内置 Agent 后，在有效源码目录运行：

```text
python .dart_tool/cumulative-2.2.2-r4-20261031/update.py rollback
```

恢复到 **2.2.2+67**，还原程序及上一收据，保留用户数据。本次没有推送 GitHub 或制作分发 ZIP。

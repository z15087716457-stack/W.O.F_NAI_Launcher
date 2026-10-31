# 本机桌面更新 2.2.2+67 · 2026-10-31

用户明确要求“ok，推送安装一下”，已于 **2026-10-31 08:57（Asia/Taipei）** 从 **2.2.2+66** 原位安装到 **2.2.2+67**。安装后完整核验通过，未自动启动、重启或操作 Studio。公开版仍为 2.2.2+64；本次仅本机更新。

## 已安装范围

- 资源小窗最近浏览／删除池、共用图库筛选条、文字居中、切换与统计查询优化；服务商请求体／头两行输入及值最多 6 行。[实现](resource-window-polish-2026-10-30.md)。
- `studio_context` 四来源极简检索状态，只读已有内存，不启动 RAG。[实现](agent-context-search-status-2026-10-30.md)。
- 标签 RAG 初始化与空索引区分、补充库 WAL／锁降级、分类 ANN 扩取、宽召回和常用度排序；共用共现及按需 `tag_related`；压缩前完整当前分支、空白气泡修复与原生 `session_history`。[实现、质量及限制](rag-related-history-2026-10-31.md)。

默认七入口、现有 UI 风格与模型上下文压缩保持；无摘要索引或系统提示注入。最大 20 高频词共现查询约 1.1 秒的已知限制保留，不将单机小样本写成所有查询的性能保证。

## 安装与验证

| 项目 | 结果 |
|---|---|
| 编译提交 | `1e0f078ead15e10ab540a09ae02cafe952213453` |
| AOT SHA-256 | `bbf41e00de41e372f3885d6b75d114ad3d9449052f3890ee2bec85bfc75b8c75` |
| 程序文件／替换／删除 | 15295／13／0 |
| 资源／生产输入 | 226／2106 |
| 原生身份 | `com.example/nai_launcher`，EXE 2.2.2+67 |
| 正式收据 | `nai-launcher-src/.dart_tool/glass-rollout-delivery.json` |
| 本批材料 | `.dart_tool/cumulative-2.2.2-r3-20261031/` |

本次固定生产输入后新跑 **1175 项合并范围检查、59 项版本／更新、117 项 Node、122 项 Python（另 3 项原生宿主用例跳过）、12 个安装回退夹具**，全部通过；完整静态分析无问题。每个阶段前后复验 2106 个生产输入，未把先前回归冒充新跑全仓测试。

Windows Release 和完整包核验通过。4 个 SQLite 资源库、全部字体、原生依赖、Node 24.18.0／Pi 1.3.0／内置 Skill 均验证；整包冒烟确认默认七入口、22 个 Studio 业务工具、新 `tag_related` 与 deferred `session_history`、CodeMode 和会话恢复。RAG 使用包内原生宿主与脚本，在隔离开发 venv 启停工作进程；没有 configure／query／建库请求、真实模型或生图。

安装前完整备份程序 `data/`、被替换程序文件和上一收据。安装后逐项校验 15295 个程序文件；`user-data/`、`agent-data/`、桌面入口、旧 AppData 兼容联接和 3 个正式索引文件的元数据保持。没有打开用户的正式索引数据库或自动重建。

## 实际替换文件

- `app_files_manifest.json`
- `data/app.so`
- `data/flutter_assets/tool/rag/engine.py`
- `data/flutter_assets/tool/rag/pool.py`
- `data/flutter_assets/tool/rag/worker.py`
- `nai_launcher.exe`
- `tools/nai-agent/lib/domain-tools.mjs`
- `tools/nai-agent/lib/extensions/interaction.mjs`
- `tools/nai-agent/lib/extensions/permissions.mjs`
- `tools/nai-agent/lib/extensions/session-history.mjs`
- `tools/nai-agent/lib/session.mjs`
- `tools/nai-agent/skills/nai-studio/SKILL.md`
- `tools/nai-agent/skills/nai-studio/references/lookup.md`

其余登记程序文件与 +66 相同。新增文件只属于 Agent 工具代码，不触及用户数据；上一批回退材料继续保留。

## 单步回退

本批回退到 **2.2.2+66**。仅在用户要求且完全退出 Studio／内置 Agent 后，在有效源码运行：

```text
python .dart_tool/cumulative-2.2.2-r3-20261031/update.py rollback
```

回退恢复程序文件及上一收据，不覆盖用户数据。桌面入口仍为原 `W.O.F NAI Studio.lnk`，本次没有推送 GitHub、生成分发 ZIP 或自动启动程序。

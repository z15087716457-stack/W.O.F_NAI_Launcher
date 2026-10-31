# 本机桌面更新 2.2.2+69 · 2026-10-31

用户明确要求“ok，推送到桌面安装”，已于 **2026-10-31 12:22（Asia/Taipei）** 从 +68 原位安装 **2.2.2+69**。原桌面入口保留；未自动启动、重启或操作 Studio，公开版仍为 2.2.2+64。

## 已安装范围

- [标签扫描稳定性](rag-scan-stability-2026-10-31.md)：忽略空 WAL 对来源签名的扰动，保留真实主库／非空 WAL 变更检测；资料和旧 digest 按批读取，修正合并名称查询对已有索引的匹配。保留向量及现有扩取策略，未保留 ×2 试验。
- [Agent 工作区收纳](agent-workspace-layout-2026-10-31.md)：全部启动器工作区资料进入 `.W.O.F/`，cwd 仍为项目根目录，根目录 `AGENTS.md` 可正常加载。旧布局先备份校验再迁移，Pi JSONL 不改写，保留草稿、附件、旧路径读取和现存项目文件优先。其他 UI 保持。

安装过程不迁移正式工作区；用户下次打开应用时才由新版本按上述契约处理。来源旧签名可能需要一次对齐核对，内容未变则复用向量；没有在交付时启动正式扫描或重建。

## 构建与核验

| 项目 | 结果 |
|---|---|
| 编译提交 | `a6c97e5d9fb65b36b22f61d76883a1e38bfc1c5e` |
| AOT SHA-256 | `f331b56874cec3b1fd728f9941091c764babfc9496a416ddd1a503e0a0619135` |
| 程序文件／替换／删除 | 15296／10／0 |
| 资源／生产输入 | 226／2109 |
| 原生身份 | `com.example/nai_launcher`，EXE 2.2.2+69 |
| 本批材料 | `.dart_tool/cumulative-2.2.2-r5-20261031/` |

源码与测试哈希匹配后，复用本轮 **734 项 Flutter Agent、122 项 Node（模板收尾另跑 6 项）、129 项 Python 通过／3 项跳过及全仓静态分析**。69 条质量查询及 4096 条资料一致性证据沿用源码报告，不冒充安装后重新测量。版本号调整后新跑 **59 项版本／更新检查与 12 个安装回退夹具**，全部通过；没有声明本次新跑全仓测试。

Windows Release、完整程序清单、4 个 SQLite 资源库、字体、Node/Pi 版本和原生依赖检查通过。整包 Agent 合成冒烟覆盖默认七入口、CodeMode、按需工具及原生会话恢复；包内 RAG 宿主／worker 使用隔离开发环境启停，不加载真实模型或访问用户语料。

覆盖前复核程序完全退出，备份完整程序 data/、被替换程序文件及上一收据；安装后全部 15296 个登记文件与回退备份核验一致。用户数据根、旧 AppData 联接、桌面入口及 3 个正式索引文件元数据保持。未搬迁正式工作区、打开正式索引、调用真实模型或生图接口。

## 本次程序变更

- `app_files_manifest.json`
- `data/app.so`
- `data/flutter_assets/tool/rag/engine.py`
- `nai_launcher.exe`
- `tools/nai-agent/lib/domain-tools.mjs`
- `tools/nai-agent/lib/extensions/permissions.mjs`
- `tools/nai-agent/lib/prompt-templates.mjs`
- `tools/nai-agent/lib/session.mjs`
- `tools/nai-agent/lib/workspace-paths.mjs`
- `tools/nai-agent/skills/nai-studio/references/workspace.md`

其余登记程序文件与 +68 保持一致，用户资料不属于程序载荷。

## 回退

仅在用户要求、Studio／内置 Agent 完全退出后，程序回退入口为：

```text
python .dart_tool/cumulative-2.2.2-r5-20261031/update.py rollback
```

恢复到 **2.2.2+68** 的程序及收据，保留用户数据。若新版本已经在后续启动时迁移工作区，旧程序不认识新布局，需要同时按 `.W.O.F/migration-backup/manifest.json` 反向搬迁当前资料并核对冲突，不能覆盖旧快照而丢失新对话；详见工作区报告。安装结束时尚未发生数据迁移。

本次未发布 GitHub 或制作分发 ZIP。

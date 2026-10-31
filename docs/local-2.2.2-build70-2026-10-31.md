# 本机桌面更新 2.2.2+70 · 2026-10-31

按用户“ok，把这次修复和Skill精简一起推送到桌面安装吧”，已于 **2026-10-31 14:47（Asia/Taipei）** 从 +69 原位安装 **2.2.2+70**。原桌面入口保留，未自动启动或重启 Studio；公开版仍为 2.2.2+64。

## 已安装范围

- [标签 checkpoint 签名修复](rag-checkpoint-signature-2026-10-31.md)：来源身份使用缓存的 SQLite 可见快照摘要，checkpoint／最后连接关闭保持稳定；完成记录绑定同一份已校验状态，最后阶段真实变化继续待同步。未变资料复用原向量。
- [内置 Skill 与工具说明精简](agent-skill-declaration-polish-2026-10-31.md)：通用规则集中在主 Skill，V4/V5 只留模型差异；块、图库和组卡说明缩短，详细流程按需读取，校正 `.W.O.F/outputs/` 路径。三份长描述合计缩短约 56%，本轮 Skill 文档减少约 20%；参数、执行逻辑、UI 和默认七入口保持。

旧签名首次升级仍可触发一次对齐核对，资料 digest 未变时复用向量。安装阶段没有打开正式索引、启动核对或建库；后续由用户自行启动应用。

## 核验

| 项目 | 结果 |
|---|---|
| 编译提交 | `058b46fee9b3b2ccf4c576ef0da07fc73152a69a` |
| AOT SHA-256 | `f331b56874cec3b1fd728f9941091c764babfc9496a416ddd1a503e0a0619135` |
| 程序文件／替换／删除 | 15296／12／0 |
| 资源／生产输入 | 226／2109 |
| 原生身份 | `com.example/nai_launcher`，EXE 2.2.2+70 |
| 审计目录 | `.dart_tool/cumulative-2.2.2-r6-20261031/` |

逐项匹配两批源码／测试哈希后，复用 **136 项 Python（133 通过／3 跳过）**，以及 Node 的 **121 项初跑通过和保温文件 6 项原样复跑通过**。初跑的一项响应等待超时日志保留，不声称一次无失败的 Node 全套。参数 schema 比对、文档链接和缓存测量证据沿用源码报告。

Dart、资源源文件和原生源码与 +69 保持，仅构建版本及已核验的 Python／Agent 文件变化，沿用匹配的静态分析结果。本批新跑 **59 项版本／更新、12 个安装回退夹具**，Windows Release 与完整包核验通过。没有声明新跑全仓测试。

包内 Agent 合成冒烟覆盖默认七入口、CodeMode、按需查询工具与原生会话恢复；包内 RAG 原生宿主／worker 在隔离开发环境启停。另直接加载打包后的 `engine.py` 运行 **7 项签名／checkpoint 回归，全部通过**。网络只用于本机合成服务，未请求真实模型或生图。

安装前复核完全退出，备份程序 data/、被替换文件与上一收据；安装后全部 15296 个登记程序文件、回退备份、桌面入口、旧 AppData 联接与数据根核验一致，3 个正式索引文件元数据保持。未搬迁工作区或操作用户草稿。

## 程序变更

- `app_files_manifest.json`
- `data/flutter_assets/tool/rag/engine.py`
- `nai_launcher.exe`
- `tools/nai-agent/lib/domain-tools.mjs`
- `tools/nai-agent/skills/nai-prompt/SKILL.md`
- `tools/nai-agent/skills/nai-prompt/references/models-v4.md`
- `tools/nai-agent/skills/nai-prompt/references/models-v5.md`
- `tools/nai-agent/skills/nai-studio/SKILL.md`
- `tools/nai-agent/skills/nai-studio/references/blocks.md`
- `tools/nai-agent/skills/nai-studio/references/gallery.md`
- `tools/nai-agent/skills/nai-studio/references/image-tools.md`
- `tools/nai-agent/skills/nai-studio/references/prompt-sets.md`

其余登记程序文件与 +69 保持一致，用户数据不属于程序载荷。

## 程序回退

仅在用户要求并完全退出 Studio／内置 Agent 后，在有效源码目录运行：

```text
python .dart_tool/cumulative-2.2.2-r6-20261031/update.py rollback
```

恢复 +69 程序及上一收据，保留用户数据。若后续已用 +70 更新索引签名，回退后可再进行一次旧格式核对，未变资料继续复用向量。本次没有推送 GitHub 或制作分发 ZIP。

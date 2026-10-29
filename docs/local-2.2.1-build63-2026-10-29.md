# 本机 2.2.1+63 · 2026-10-29

**已安装**至桌面 `W.O.F NAI Studio.lnk` 登记运行包，按用户“ok，开工吧，搞定直接推送桌面更新”的明确要求执行。编译 `4bb17a1a2b89e361623e162e03f5c5e61843ecd5`；从 +62 原位升级，单步回退到 +62。公开版仍为 2.2.1+61，本次未推 GitHub 或制作 ZIP。

本轮交付四项：

- [Agent 流式性能与平滑思考](agent-streaming-performance-2026-10-29.md)：合并 UI 发布、旧卡片与差异计算复用，字数与展开正文局部平滑过渡；原 Agent UI 静态像素一致。
- [外部桥接角色元数据](external-agent-character-metadata-2026-10-29.md)：保留响应原始角色提示词／坐标等信息，仅对齐尺寸；缺失元数据时补齐本次请求角色。旧图库不会自动恢复缺失字段。
- [外部 Agent 桥接依赖提示](external-agent-bridge-dependency-2026-10-29.md)：共享 Krita 桥接关闭时灰显／禁用并显示小字，开启后恢复，不要求插件连接。
- [保存提示条对齐](settings-toast-alignment-2026-10-29.md)：保留勾号占位、补齐右侧留白，按内容伸缩并保持居中。

## 交付核验

- 新跑 1389 项相关回归与 59 项版本／更新回归通过；3 项渲染复验为子集。业务目录静态分析无问题，4 轮原生展开长文对照和静态逐像素比较通过。Node 112 项回归按源码匹配复用，没有声称新跑全仓完整回归。
- Windows Release、12 个安装回退夹具、四个 SQLite 资源、19 份字体、Node／Pi 版本、内置 Skill、Agent／CodeMode／会话恢复及隔离 RAG 启停核验通过。
- 安装后 15294 个程序文件核验一致，来源输入 2101 项；仅替换 3 个文件，无新增或退役文件：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`。
- 桌面入口、数据根／兼容联接和正式索引文件元数据保持，未打开正式索引或启动重建。没有自动启动 Studio、改写用户草稿、调用真实模型或生图接口。

已安装 AOT SHA-256：`41420b1df18661db2939a5b172b3b2086bf61a9e8b18b85fe7cbea289733da89`。

交付批次 `.dart_tool/cumulative-2.2.1-r2-20261029/`：`installed-delivery.json`、`final-verification.json`、`release-validation.json`、`package-verification.json`、`installer-fixtures.json`。初次组包在候选元数据缺少 `feature_evidence` 时停止，未改安装目录；补齐后通过 `resume_prepare.py` 重新验证全部已暂存字节，原记录保留。

## 回退

仅在用户要求回退时，完全退出 Studio／Agent 后，在有效源码目录执行：

```powershell
python .dart_tool/cumulative-2.2.1-r2-20261029/update.py rollback
```

此操作恢复本次备份的 +62 程序和收据；用户数据不参与程序回退。后续交付文档的普通提交不改变本次编译产物或版本标签。

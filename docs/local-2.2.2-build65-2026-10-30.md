# 本机 2.2.2+65 · 2026-10-30

**已安装**至桌面 `W.O.F NAI Studio.lnk` 登记运行包，按用户“推送到桌面吧”的明确要求于 **2026-10-30 08:57（Asia/Taipei）** 从 +63 原位升级。编译 `2d1453213d4648b3c26a814440d5e5d564a52ac6`；单步回退到 +63。公开版仍为 2.2.2+64，本次只更新本机。

本轮交付[图库首次 Ctrl/Cmd 多选修复](gallery-ctrl-preview-selection-investigation-2026-10-30.md)：首次仅选点击图，预览图不再带入多选或删除候选；已有多选累加／取消、Esc、完整 Shift 范围及其余 UI 保持。前轮全部增量累计保留。

## 交付核验

- 按源码匹配复用本轮已通过的 43 项图库相关检查；本次新跑 59 项版本／更新与 12 个安装回退夹具通过，`lib / test / tool` 完整业务目录静态分析无问题。没有声称新跑全仓全量测试。
- 与 +63 的 2101 个生产输入核对，实际差异仅版本、图库首次 Ctrl 分支及 focused 注释，其余仅已记录的生成文件行尾；Node 源码一致后复用 112 项回归。
- Windows Release、四个 SQLite 资源、19 份字体、Node 24.18.0／Pi 1.3.0、内置 Skill、Agent／CodeMode／会话恢复与隔离 RAG 启停通过。
- 安装后 15294 个程序文件逐项核验，仅替换 3 个：`data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`。没有新增或退役程序文件，原生插件保留。
- 桌面入口、用户数据根／兼容联接与 3 个正式索引文件的元数据保持。覆盖前及覆盖时均核对完全退出，完整程序 data 与旧收据备份已核验。

已安装 AOT SHA-256：`cb6690716ebf97a90b59481de2d1d97833e8a19f57cb1c235705b57f0f42b19e`。证据在 `.dart_tool/cumulative-2.2.2-r1-20261030/` 的 `installed-delivery.json`、`final-verification.json`、`release-validation.json`、`package-verification.json` 与 `installer-fixtures.json`。

## 回退

仅在用户要求回退时，完全退出 Studio／Agent 后，在有效源码目录执行：

```powershell
python .dart_tool/cumulative-2.2.2-r1-20261030/update.py rollback
```

恢复本次备份的 +63 程序与收据，用户数据不参与程序回退。安装后未自动启动／操作 Studio，未调用真实模型／生图、改写草稿或正式索引、发布 GitHub 或制作 ZIP。后续交付文档普通提交不改变本次编译产物。

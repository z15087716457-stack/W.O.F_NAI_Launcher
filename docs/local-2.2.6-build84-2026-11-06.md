# 本机 2.2.6+84 桌面更新

2026-11-06（Asia/Taipei）。原桌面运行目录已更新为 **2.2.6+84**，包含 `main` 中 #19 的 18 项 PR 取舍、两项画布默认值，以及开发工作树中六组已验证的改动。六组改动覆盖 Vibe 和精准参考、模型管理窄窗布局、Windows 可见安装进度、Agent 压缩状态、Agent 检索指引与上下文读取、提示词权重。公开版本为 [v2.2.6](https://github.com/z15087716457-stack/W.O.F_NAI_Launcher/releases/tag/v2.2.6)。

- 从与 `main` 的 `d754612dd` 具有相同提交树的 `06c8bc59a`，加开发工作树改动构建。冻结 2,138 个输入，使用 Flutter 3.47.7、Dart 3.13.5 和 Windows `--build-number=84`，安装后再次核对输入及载荷。
- 997 项 Flutter 定向回归、132 项 Agent Node 测试、RAG 144 项通过且 3 项条件跳过。全仓静态分析、四份随包数据库校验、Windows Release 编译和安装器隔离测试通过。
- 19 个文件进入差量，16 个替换、3 个新增。安装后 15,553 个程序文件逐项核验。随包 RAG 代码与 Agent 资源已同步，原生库及 Pi 1.5.0 复用。
- 快捷方式、用户与 Agent 数据目录、旧路径入口和正式 RAG 索引文件元数据核验通过。界面由用户打开原快捷方式验收。

完全退出 Studio 后，在有效源码目录运行以下命令可回退到 **2.2.6+83**。回退所需的原程序文件、完整 `data/` 和收据已核验。

```powershell
python .dart_tool/local-2.2.6-build84-20261106/update.py rollback
```

本批证据在 [final-verification.json](../.dart_tool/local-2.2.6-build84-20261106/final-verification.json)，当前直装收据位于 `nai-launcher-src/.dart_tool/glass-rollout-delivery.json`。

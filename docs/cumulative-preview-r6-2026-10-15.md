# 2.0 Preview r6 · RAG 累计本机更新

2026-10-15（Asia/Taipei）。用户要求累计更新，现场检查 Studio 已完全退出后安装到原入口。用户随后明确仅本地开发，GitHub 暂不需要：**未推送、未创建 Release，未自动启动／重启／热重载 Studio**。

## 交付与入口

- 内部版本 `2.0.0-preview+10`，编译提交 `ce5921c465491492fb7d6788203c33f45a1beef8`；后续文档提交不代表重新编译。
- 合入标签双 120-token 上下文推荐、Wiki／提示词块混合搜索、图库文字／参考图／图文组合检索及独立 RAG 设置／模型／索引管理；保留 r5 及此前修复。
- 正式运行目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`，原桌面入口和数据身份 `com.example/nai_launcher` 保持。
- AOT SHA-256：`3a99906716843639dac9c9ed8ff5287b88eef871219d3f92d5935ccacda33dbf`。
- [r6 Windows x64 Portable](E:/A.I/NovelAI/04_工具/UIUX重做/测试包/WOF_NAI_Studio_2.0_Preview_20261015_r6_Windows_x64_Portable.zip)：317666685 字节，15371 个文件；旁附 `.sha256`。
- ZIP SHA-256：`4b16cbd82a71070cd2101a464e073661a43f8394f20e9fc8754cbfc04c40519e`。

RAG 各来源默认关闭。在「设置 → RAG 向量系统」配置独立 Python 环境和本地模型，再启用所需来源、预览范围并点击开始。工作区已下载模型位于 `04_工具/models/embeddinggemma-2/` 与 `04_工具/models/Qwen3-Reranker-0.6B/`，不随便携包分发。没有自动安装 Python 依赖、修改用户 RAG 设置或为用户整库计算向量。用户首次完整建库的速度与真实召回质量仍需按实际资料验收。

文字采用 Gemma 召回＋Qwen 重排；图片只用 Gemma，音频关闭。NAI 缓存参数另建文字索引，普通图不自动解析其他软件参数，原图不改写。工作区向量索引和 Agent 检索工具／动态卡片按用户要求暂放。

## 核验与恢复

- 本轮重新构建 Windows Release，1866 份生产输入一致，原有 DEVELOPMENT 修改保持；与图库功能提交相比只有版本和 CHANGELOG 发生生产相关变化。
- 功能完成时的回归沿用：标签 657、Wiki／块库 348、图库 511 项 Flutter 检查，范围有重叠；图库含 3 项既有可选 GPU 超分跳过。Python／ANN／原生宿主 52 项、静态分析无诊断、实际权重 CUDA 图文检索与跨进程恢复通过。没有把这些数字相加，也没有声称本轮重跑全量。详见 [标签](rag-tag-context-2026-10-15.md)、[Wiki／块库](rag-wiki-blocks-2026-10-15.md)、[图库](rag-gallery-2026-10-15.md)。
- 本轮安装器 9 项隔离检查通过，覆盖新增文件失败回退、完整回退、运行占用、基线变化、同名未登记文件、损坏备份和安装 hold；没有用测试夹具替代真实安装核验。
- 保留 Glass 原生插件、完整内置 Node／Pi 和用户数据。共 15353 份登记程序文件、222 份 Flutter 资源；实际替换／新增 12 项，其中新增 8 项 RAG 资源。
- 安装前保存 r5 被替换文件、完整登记程序 data 和旧收据；安装后全部程序哈希、当前收据与备份核验通过。回退材料 `E:/A.I/NovelAI/.devin/wt/ui-integration/.dart_tool/cumulative-r6-20261015/rollback`，只读核验 `update.py verify-backup`，明确恢复用 `update.py rollback`，须先完全退出 Studio。没有实际回退。
- ZIP CRC、逐文件哈希、实际完整解压、SQLite quick_check、字体、原生依赖／数据身份、内置 Node 24.18.0／Pi 1.1.0 及隔离 Agent／CodeMode／会话恢复通过。RAG 的 6 份 Python 源码、requirements 和 Windows Job 宿主逐份匹配构建源；不分发模型、虚拟环境、用户账号、密钥、聊天、图库或内部收据。
- 原有 160px 极窄画布提示条前端溢出仍是已知问题；本轮未修改该组件。用户运行窗口的手感与真实资料召回由用户验收。

本轮材料 `.dart_tool/cumulative-r6-20261015/`：`build-inputs-start.json`、`windows-build.log`、`installer-fixtures.json`、`build-verification.json`、`package-verification.json`、`final-verification.json`、`preflight.json`、`installed-delivery.json`、`install-result.json`。构建产物、日志和私有材料不提交。

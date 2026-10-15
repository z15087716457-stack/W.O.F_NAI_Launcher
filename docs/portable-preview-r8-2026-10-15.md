# 2.0 Preview r8 · 最新便携版与旧包清理

2026-10-15（Asia/Taipei）。用户明确要求打包最新便携版并删除旧包。使用已安装 r8 的同一份编译程序，不重建或覆盖桌面程序；没有自动启动 Studio 或发布 GitHub。

## 便携包

- [Windows x64 ZIP](../../../../04_工具/UIUX重做/测试包/WOF_NAI_Studio_2.0_Preview_20261015_r8_Windows_x64_Portable.zip)；317730840 字节，15374 文件，旁附 `.zip.sha256`。
- SHA-256：`ff7b69ed033c8c01d12cf264b8e339e7406601e1ed2260875bc959f71ba3c385`。
- 程序 `2.0.0-preview+12`，编译提交 `2d2e652b399a078e259428301b7039a3cb67ebf4`；AOT 与桌面一致：`ca71b104a77af76e262d2ccbe57fa5cbf5a107f8b810fa8515335b585e63265d`。
- 包含本轮 F07–F13 与此前累计功能、完整 Node 24.18.0／Pi 1.1.0、字体／图标和签名有效的 Microsoft x64 CRT。中文／英文说明互相链接，保留原项目归属及许可，附本版 CHANGELOG。
- 按登记程序文件白名单打包；不含账号、密钥、会话、浏览器资料、个人图库、模型权重、Python 环境或内部安装收据。仍按现行设计使用 `%APPDATA%/com.example/nai_launcher`。

## 验证与清理

- ZIP CRC、全部文件大小与 SHA-256、压缩包路径／清单及原生依赖核验通过。
- 实际完整解压 15374 个文件后逐一比对，SQLite quick_check、完整字体、原生数据身份／版本、Node／Pi 与隔离 Agent／CodeMode／会话恢复通过；RAG 原生宿主／worker 仅启动与退出，未加载模型或索引用户资料。
- 1872 生产输入及桌面安装文件／收据不变，已有 DEVELOPMENT 修改保留。没有调用真实生成或远程模型。
- 验证通过后删除 6 份旧便携 ZIP：r2／r3／r5／r6、r4 候选及旧 `NAI_Launcher_Windows_1.6.0+27_Portable.zip`，同时删除 5 份配套校验文件，清理 1841205232 字节（约 1.84 GB）。删除前逐项核对绝对路径、目录边界及哈希。
- 本次验证生成的完整解压副本也已清理（834654928 字节），不保留额外程序副本。桌面运行包、安装回退材料和完整验收检查点均保留。

证据 `.dart_tool/portable-r8-20261015/`：`package-verification.json`、`distribution-files.json`、`native-dependencies.json`、`crt-signatures.json`、`final-verification.json`、`old-portable-inventory.json`、`cleanup-plan.json` 与 `cleanup-result.json`。旧包链接只保留在历史记录中；当前入口指向本版。

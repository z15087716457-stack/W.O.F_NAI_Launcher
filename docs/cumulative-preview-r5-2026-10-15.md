# 2.0 Preview r5 · 本机累计更新

2026-10-15（Asia/Taipei）。用户明确要求更新并确认保存、从托盘退出后，已安装到原运行目录；**未自动启动、重启或热重载 Studio，未推送或发布 GitHub Release**。

## 交付

- 内部版本 `2.0.0-preview+9`，编译提交 `bf3106cfe68a4305335601e7d05d11f9315f709a`；后续文档提交不代表重新编译。
- 累计 Agent 默认 520px 可拖动侧栏、历史保留、预绘制向右展开和贯穿分隔；变体费用胶囊稳定性；画布视觉通道前端与后端接线。此前 r3 的动效、翻译、Logo / Tip、入口和原图附件保持。
- 正式运行目录 `E:/A.I/NovelAI/nai-launcher-src/build/windows-glass-preview/runner/Release`；原桌面快捷方式继续使用，数据身份保持 `com.example/nai_launcher`。
- AOT SHA-256：`2f023c9eda7ae87e2cd90459894b57e5da1e4d0c24a76b3745048a03f9d13b40`。
- 便携包：[r5 Windows x64 Portable](E:/A.I/NovelAI/04_工具/UIUX重做/测试包/WOF_NAI_Studio_2.0_Preview_20261015_r5_Windows_x64_Portable.zip)，317486248 字节、15363 文件；旁有 `.sha256`。
- ZIP SHA-256：`f3dc34a9f20c48e8920aae1ae773e3b422f96675517ce386bc3f09915f5ce0c8`。

## 核验

- Windows Release 构建通过；1837 生产输入逐份匹配，原有 `DEVELOPMENT.md` 与前端锁定 40 项未变。
- 各功能完成时的范围回归：视觉通道 1688、边界 39、繁中 4；侧栏 1118 / 极窄 279、费用胶囊 519。范围有重叠，未相加或重新声称全量。其后仅版本和 CHANGELOG 改动；全仓分析沿用这些功能提交的无诊断结果。
- 本轮重新执行安装 / 回退保护 7 项并通过；已备份旧程序、完整登记的程序 data 文件和旧收据。安装后全部 15345 程序文件、收据及回退备份核对通过，实际只替换 `data/app.so`、`nai_launcher.exe`、`app_files_manifest.json`。
- ZIP CRC、所有文件哈希、实际完整解压、SQLite quick_check、全套字体、原生依赖、版本 / 数据路径、内置 Node 24.18.0 / Pi 1.1.0 及隔离 Agent / CodeMode / 会话恢复检查通过；无真实模型或 NAI 请求。
- 安装器不写账号、草稿、提示词、角色框和桥接参数。程序保持关闭，实际展开手感及 Ctrl+V / 跨窗口 OLE 仍由用户验收。

## 已知问题与恢复

- 保留原 Opus 前端，160px 极窄画布的进入提示条仍会溢出；后端与独立前端均复现。见工作区 `04_工具/UIUX重做/10_画布视觉通道/前端反馈-极窄画布.md`。用户在知悉该问题后要求更新，本次未越过“只做后端”的边界修改组件。
- GitHub CLI 未登录，禁止交互的推送预检报告缺少凭据，已终止等待；没有远端推送或 Release。
- 回退材料 `E:/A.I/NovelAI/.devin/wt/ui-integration/.dart_tool/cumulative-r5-20261015/rollback`；`update.py verify-backup` 为只读核验，`update.py rollback` 为显式恢复入口，必须先退出 Studio。未实际回退。
- r4 待更新候选保留作历史材料，已被本次累计 r5 取代，不再作为待安装版本。
- 本轮证据 `E:/A.I/NovelAI/.devin/wt/ui-integration/.dart_tool/cumulative-r5-20261015`：`windows-build.log`、`installer-fixtures.json`、`build-verification.json`、`package-verification.json`、`final-verification.json`、`preflight.json`、`installed-delivery.json`、`install-result.json`。

# F14 · 角色添加菜单文案精简

2026-10-15，用户要求去掉角色提示词“＋”菜单四项末尾重复的“角色”。本地完成，待后续累计更新。

- 简中菜单改为“添加女性／添加男性／添加其他／清空全部”；英、日、韩同步精简，台湾正体按现行 OpenCC 流程重新生成，再运行 `flutter gen-l10n`。
- 只改 `gen_addAs`、`gen_clearCharacters` 两个资源键及对应生成代码。主生图和画风探索复用同一个 `GenCharacterModule`，没有改组件、事件、可用条件或清空确认弹窗。

验证：

- 105 项菜单实绘／原生图页面行为／国际化回归通过；另生成台湾正体的 4 项检查通过。
- 20 个真实字体菜单场景覆盖五语言、浅深主题、352px 常规字号与 560px 的 1.4 倍字号；菜单文字完整显示，清空仍先确认再回调。已检查中文浅色常规、深色放大实绘。
- `flutter analyze --no-pub lib/l10n` 无诊断。原 UI 源文件、原基准 PNG、现有 `DEVELOPMENT.md` 修改、桌面 AOT／安装收据及 r8 便携 ZIP 的哈希保持不变。

审计与可复现实绘脚本：`.dart_tool/character-menu-copy-20261015/`，含 `menu_probe_test.dart`、`tests.log`、`analyze.log`、`scope-verification.json` 和 `captures/`。原反馈截图保存在工作区 `04_工具/开发计划/反馈截图/2026-10-15-r8/14-character-menu-redundant-role.png`。

未构建或安装程序、重打便携包、操作运行中 Studio 或推送 GitHub。本次菜单调整不在已交付的 r8 程序／便携包内。

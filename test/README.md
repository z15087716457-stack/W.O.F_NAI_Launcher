# 测试与实绘入口

测试使用 flutter_test / mocktail，与 lib 按层级对应。按实际影响选择回归；历史 TEST_REPORT、交付记录和用户验收各有范围，不把旧失败或旧通过数当本次结果。纯文档 / 注释修改无需 Flutter 测试与构建。

## 按范围运行

在有效源码根用 Bash 执行：

```bash
flutter test test/core/utils/justified_layout_test.dart
flutter test test/presentation/widgets/gallery/timeline/gallery_timeline_layout_test.dart
flutter test test/presentation/widgets/gallery/local_gallery_toolbar_test.dart
flutter test test/core/wiki/tag_translation_glossary_test.dart
flutter test test/core/wiki/auto_tag_translation_controller_test.dart
```

需要全量时用 `flutter test --reporter=failures-only`，analyze 按实际受影响文件 / 模块选范围。修改生成输入时先完成 build_runner；界面文案先生成繁体资源和 gen-l10n，详见 [DEVELOPMENT.md](../DEVELOPMENT.md)。

## 真实字体与临时数据

界面测试使用 `helpers/studio_capture_fonts.dart`；根据修改覆盖简中 / 台湾正体 / 英 / 日 / 韩、深浅色和宽窄 / 短窗口。图库实绘见 `presentation/screens/local_gallery/local_gallery_screen_layout_test.dart`，设置见 `presentation/screens/settings/settings_screen_test.dart`，小贴士见 `presentation/tips/tip_layout_test.dart`。截图变量与输出位置从对应测试代码读取。

合成数据和临时 SQLite / Hive / SharedPreferences 不读写用户账号、图库与草稿；请求替身不发真实翻译、认证或生图。截图注明为 widget 实绘，不写成运行中的用户窗口。

日志相关套件使用 `helpers/app_logger_test_isolation.dart` 的隔离目录和清理。失败先定位具体路径与当前代码，不恢复已删除的旧编辑器、分页或旧国际化键来迁就历史报告。当前安装包完整验证与通过数量见本机交付记录，不在此复制易过期的全量数字。

## Agent 双环反馈

`bridge_agent_feedback_test.dart` 检查 600ms 快速反馈、持续确认、内容变化 / 撤销失效、晚到与并行任务、失败与重启；`bridge_draft_version_test.dart` 检查真实参数、角色、文档、预设与参考变化；`bridge_link_icon_test.dart` 检查 16px 度量、运动、Reduced Motion 与 TickerMode。`prompt_input_test.dart` 五语言深浅色 / 窄窗检查真实绿色和即时灰色，`CAPTURE_AGENT_BRIDGE=1 CAPTURE_BRIDGE_MOTION=1` 采集控件实绘，不代表运行中用户窗口。

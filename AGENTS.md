# W.O.F_NAI_Launcher · 开发约定

NovelAI Flutter 桌面客户端。业务按 `lib/core/`、`lib/data/`、`lib/presentation/` 分层；修改优先复用现有 service、provider 和 widget。

## 按任务查阅

- `04_工具/开发计划/` 中的计划与逆向整理是参考线索，可能含模型误判；用户明确需求决定目标，关键结论结合源码和可复现证据独立核验，不因标注“真值/已核验”就直接采信，发现错误应纠正。
- 开发运行、热重载、代码生成：查 [DEVELOPMENT.md](DEVELOPMENT.md)「构建、测试与开发命令」。
- 准备发布、更新 README 或提交 PR：查 [DEVELOPMENT.md](DEVELOPMENT.md) 对应节。
- 桥接/参数、模型/计费、登录、图库、画布或更新实现：定向查 [OPERATIONAL_NOTES.md](OPERATIONAL_NOTES.md) 对应章节；普通文案或格式修正不需要通读。
- 依赖、资源和 lint 以 `pubspec.yaml`、`analysis_options.yaml` 为准；国际化源文件在 `lib/l10n/`。`app_zh_TW.arb` 与 `zh_tw_labels.dart` 由 `tool/l10n` 生成，不手改，重新生成方法见 [DEVELOPMENT.md](DEVELOPMENT.md)「资源、生成文件与发布注意事项」。

## 修改与验证

- 依赖变化后 `flutter pub get`；修改 Riverpod、Freezed、JSON、Hive 或路由的生成输入后运行 `dart run build_runner build --delete-conflicting-outputs`。
- 界面文案统一写进 `lib/l10n/` 的 ARB，各语言同步补齐，改后运行 `flutter gen-l10n`；有 BuildContext 用 `context.l10n`，模型、服务等无 context 的代码用 `currentL10n`。不要在代码里内联 `zh/en/ja` 三元或只写中文；英日等布局回归用真实字体（`test/helpers/studio_capture_fonts.dart`）。
- 代码按 Dart formatter 与现有分层风格编写。逻辑修复验证受影响路径；UI 行为变更验证实际界面，需要稳定回归覆盖时补对应测试。
- 测试放在 `test/` 对应功能目录，使用 `flutter_test` / `mocktail`。按影响选择测试和分析范围；仅文档修改不运行 Flutter 全量测试或构建。
- 已有开发会话时，代码修改完成必要验证后运行 `scripts/trigger_hot_reload.ps1`；需要重置状态用 `-Restart`，不要再启动第二个 attach。
- 用户指定自行核验界面时，只构建并交付产物，不自动热重载、重启或操控应用。
- 修改用户提示词、草稿、角色框或桥接状态须先备份并核对最新值。实际生图需用户明确授权，执行前报告单价和余额。

## 仓库边界

- 本工作区只运行此目录的自研启动器，源码保持 ASCII 路径。`临时存图/` 不移动、不改名、不合并。
- 不直接 merge 或 cherry-pick 上游提交；先观察差异，再实现所需功能。应用内更新源为 `z15087716457-stack/W.O.F_NAI_Launcher`，保留原项目归属说明。
- 不提交 API token、账号数据、本地日志、构建产物或个人工作流文件；认证调试只记录类型、长度或脱敏前缀。
- 涉及 README 时同步修改 `README.md` 与 `README.en-US.md`，保留互相切换链接；仓库约定以中文版为准。
- 发布前检查 LFS 数据库、版本、CHANGELOG、release notes 和 Windows release build，具体要求见 [DEVELOPMENT.md](DEVELOPMENT.md)。

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

## 默认回归与手动实机审计

普通 Windows 全量回归有五项有意跳过的实机 / 联网测试，不是已知失败。没有明确要求实机审计时，不启用它们，也不为减少跳过数恢复已退役功能：

| 测试 | 数量 | 启用条件 |
|---|---:|---|
| `data/services/local_upscale_service_test.dart` 的可选模型、原生尺寸 / 透明度和子进程取消 | 3 | Windows、可用 Vulkan GPU，`RUN_LOCAL_UPSCALE_AUDIT=1`；可选模型测试还需要 `.dart_tool/local-upscale-20261005/official-models.zip` |
| `data/services/advanced_upscale_component_manager_test.dart` 的真实 RTX 服务链 | 1 | Windows、可用 RTX GPU，`RUN_ADVANCED_UPSCALE_AUDIT=1`，以及 `.dart_tool/advanced-upscale-20261005/rtx-video-sdk-1.1.0.zip` |
| `tool/online_gallery_ai_tag_live_test.dart` 的生产站配置 / 详情 / 图片 / 临时收藏库 | 1 | `--dart-define=LIVE_AI_TAG=true`；会联网读取公开内容，不能当作离线单测 |

RAG 进程通信测试（`core/rag/rag_client_test.dart`、`presentation/providers/rag_collections_test.dart`、`rag_startup_state_test.dart`，共 32 项）默认使用 `RAG_TEST_PYTHON`，未设置时用登记的开发环境 `.dart_tool/rag-runtime/venv`；两者都没有才跳过。它们只启动合成夹具脚本，不加载模型、不读写用户索引。`presentation/ui/agent/agent_panel_test.dart` 的 `capture` 组默认做全部场景的深浅色／360／460 宽实绘冒烟，设 `CAPTURE_AGENT=1` 才导出 PNG。

截图基准图（`expectOutsideApprovedRegions`）在用户确认以当前画面为准时，用 `UPDATE_APPROVED_BASELINES=1 flutter test --no-pub <测试文件>` 只覆盖不一致的 PNG，再不带变量复跑确认。2026-10-22 已按用户决定，以当前画面更新通道 24 张、设置 3 张基准图。

非 Windows 还可能跳过平台专属路径分隔符回归。实际通过 / 跳过 / 失败以当次输出为准；原生缓存或设备缺失应明确报错，不伪造 GPU 通过。

三个旧悬浮按钮测试现在检查现行行为：悬浮不显示按钮，右键动作仍可用、回调只执行一次且菜单关闭。PNG 参数导入测试在内存中构造带 NovelAI `Software` / `Source` / `Comment` 的完整图片，不依赖私人图片或某台电脑的绝对路径；真实 PNG / WebP 夹具回归继续由 `data/services/metadata/unified_metadata_parser_test.dart` 覆盖。

`manual/efficient_vit_sam_smoke_test.dart` 默认只运行两项普通编辑 / 局部重绘工具退役保护，确认旧 SAM 魔棒不可用、旧工具 ID 回退到画笔。历史 ONNX 冒烟不再属于当前产品的默认回归，仅在显式设置 `EFFICIENT_VIT_SAM_SMOKE=1` 时登记；模型位置可用 `EFFICIENT_VIT_SAM_MODEL_DIR` 指定，仅使用已有缓存模型、禁止模型下载。它未执行时不报告为已通过，也不代表当前编辑器需要这些模型。

## 真实字体与临时数据

界面测试使用 `helpers/studio_capture_fonts.dart`；根据修改覆盖简中 / 台湾正体 / 英 / 日 / 韩、深浅色和宽窄 / 短窗口。图库实绘见 `presentation/screens/local_gallery/local_gallery_screen_layout_test.dart`，设置见 `presentation/screens/settings/settings_screen_test.dart`，小贴士见 `presentation/tips/tip_layout_test.dart`。截图变量与输出位置从对应测试代码读取。

合成数据和临时 SQLite / Hive / SharedPreferences 不读写用户账号、图库与草稿；请求替身不发真实翻译、认证或生图。截图注明为 widget 实绘，不写成运行中的用户窗口。

日志相关套件使用 `helpers/app_logger_test_isolation.dart` 的隔离目录和清理。失败先定位具体路径与当前代码，不恢复已删除的旧编辑器、分页或旧国际化键来迁就历史报告。当前安装包完整验证与通过数量见本机交付记录，不在此复制易过期的全量数字。

## 右键菜单与详情时序

`ImageActionMenu.show` 等待弹出路由的 `completed` 后才返回选择，详情打开器再通过 microtask 推入查看器。交互测试在关闭菜单后需推进下一帧，再检查菜单已移除、查看器的图片序列与初始索引；不要用旧的“查看详情 / View details”文案断言当前“详情 / Details”入口。

国际化回归同时检查五语言消息 / 元数据键一致、元数据所属消息存在和生产引用；移除旧消息时一并清理其占位参数元数据，再按现行繁体资源及 `gen-l10n` 流程重新生成。普通测试不得回写手工维护的 ARB 源文件。

## Wiki、标签扩展与组件安装反馈

- `core/wiki/auto_tag_translation_controller_test.dart` 覆盖共享队列的排队 / 执行、名称与正文错误隔离、跨展示面去重、关闭自动后手动重试、旧路由结果失效及名称重译保留正文缓存。
- `presentation/widgets/common/translation_icon_test.dart` 覆盖五语言 / 明暗主题的行内状态、失败色 / 提示与重试、固定布局槽；原有 Reduced Motion / TickerMode 和旋转箭头回归保留。
- `presentation/widgets/tag_expansion/tag_wiki_browsing_test.dart` 覆盖 Wiki 列表 / 文章标题和搜索 / 关联 / 小百科的状态显示、不误跳转或插入，以及长目录标题在 1 / 1.5 / 2 倍字号下换行、无裁切和锚点跳转。`CAPTURE_TAG_WIKI=1` 配合 `--name "inline activity|inline translation|long outline headings"` 采集 `.dart_tool/tag-wiki-captures/inline-*.png`；`STUDIO_APPEARANCE=dark` 采集深色，均为真实字体、合成数据的 widget 实绘。
- `data/services/advanced_upscale_component_manager_test.dart` 的 SeedVR2 回归使用微型来源 / uv / 权重归档和进程替身，覆盖成功 receipt、运行环境失败 / 清理与诊断脱敏。provider 测试检查阶段保留及锁释放，管理页五语言窄窗检查错误与可复制诊断。安装 probe 和推理都检查启动前 CUDA 配置 / 离线环境，子进程与展示诊断保留受限首尾；旧 RTX receipt 兼容仍要求所有文件哈希匹配。默认不会安装 Python / CUDA 或下载真实权重；不把这些夹具测试描述为真实安装成功。仅在用户授权运行环境下载后，`RUN_SEEDVR2_RUNTIME_AUDIT=1` 登记独立目录的真实环境审计：复用已缓存的固定组件归档 / 依赖，执行 Python / CUDA 安装与 GPU 可用性 probe，在权重阶段取消且拒绝任何模型下载请求；结果保存在 `.dart_tool/seedvr2-runtime-audit-20261006/result.json`。它会下载缺少的运行环境依赖，不得默认启用，也不代表完整模型安装 / 推理通过。
- 二级图片菜单的悬停右侧对齐、右下角向左避边及移入选择由生图卡片和 `gallery/local_image_context_menu_test.dart` 的回归覆盖，动作仍只执行一次且菜单先关闭。

## Agent 双环反馈

`bridge_agent_feedback_test.dart` 检查 600ms 快速反馈、持续确认、内容变化 / 撤销失效、晚到与并行任务、失败与重启；`bridge_draft_version_test.dart` 检查真实参数、角色、文档、预设与参考变化；`bridge_link_icon_test.dart` 检查 16px 度量、运动、Reduced Motion 与 TickerMode。`prompt_input_test.dart` 五语言深浅色 / 窄窗检查真实绿色和即时灰色，`CAPTURE_AGENT_BRIDGE=1 CAPTURE_BRIDGE_MOTION=1` 采集控件实绘，不代表运行中用户窗口。

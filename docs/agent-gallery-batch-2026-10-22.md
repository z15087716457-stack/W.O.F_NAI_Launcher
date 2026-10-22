# Agent 图库批量移动／批量删空文件夹 · 2026-10-22

用户反馈：Agent 整理图库时每移动一张图片都弹一次确认，删除图库文件夹也逐个确认，要求合并。用户说“开工”后实施；勘察派给 DeepSeek v4.1 Flash（max），后端派给 GPT 6.1 Sol（xhigh），主窗口补 l10n 并复核。有效源码提交 `02745d1d6`，已随 [r37 累计更新](cumulative-preview-r37-2026-10-22.md) 安装到原桌面入口。

## 根因

- `gallery_manage(move_file/copy_file)` 只接受单个 `image_id`，`folder_delete_empty` 只接受单个 `folder_id`。每次调用都经过 Studio 的 `_confirmFileChange`；设置“危险资产操作二次确认”默认开启，外部图库移动不论该设置都要确认。
- 工具说明本身无法消除弹窗：没有批量参数时模型只能逐张调用。手动界面的批量移动早已一次确认，Agent 工具未对齐。
- 用户 Agent 权限模式为 bypass，弹窗不来自 Node 权限层。

## 最终行为

- `move_file`／`copy_file`：保留旧单图形式；新增 `image_ids`（1..50）＋`expected_image_versions`（每个 ID 对应 read 返回的版本）。两种形式不能混用。
- 提问前统一预检全部版本、原图与目标；任何一项不通过则直接报错，不弹窗、不改动。已在目标目录的项目跳过（`unchanged_ids`），全部已在目标时不提问。
- **每次调用最多一次 Studio 确认**，计数为实际待移动张数；外部双向／外部源／外部目标／内部保护文案的优先级同单图路径。确认框最多列 5 条“文件名 → 目标目录”，超出部分显示“另有 N 项”，并附目标绝对路径。
- 逐项执行：备份原图 → 复核版本 → 原生转移（沿用哈希校验和索引记账）；首个失败即停止，返回 `ok:false`、`completed`、`failed_image_id`、`remaining_image_ids` 及全部备份。结束时只刷新一次图库。
- `folder_delete_empty`：保留 `folder_id`；新增 `folder_ids`（1..50）。可同时选中父子目录，按子先父后删除；目录里只要有文件、隐藏文件或未选中的子目录，整批在预检阶段拒绝。一次确认、一份备份、一次保存目录表；部分失败时也会保存已删除部分。不支持删除非空目录，Skill 改为建议“先按目标目录批量移出，再一次删空目录”。
- 撤销：批量移动的卡片可整批撤销，先校验所有图片版本与原位置，任一不符则不改动；然后按原目录分组反向移动。复制仍不可撤销。
- 工具说明与 nai-studio Skill（`SKILL.md`、`references/gallery.md`）写明批量用法，要求不再循环单图调用。`collection_add/remove` 仍限 1..20。
- 新增 l10n：`naiAgent_galleryDeleteEmptyFoldersConfirm`、`naiAgent_galleryMoreItems`，五语言（繁中由工具生成）。

## 验证

- `flutter test --no-pub test/presentation/providers/nai_agent test/presentation/wiring/nai_agent test/core/nai_agent test/l10n/zh_tw_resources_test.dart`：**578 项全部通过**（新增批量移动／复制／撤销／目录删除等 18 项提供器用例，卡片 mapper 4 项、wiring 2 项，均使用真实临时文件与 SQLite）。
- Node `tool/nai_agent` 全部 **84 项通过**。
- `flutter analyze --no-pub lib test tool/nai_agent`：无问题。全仓 analyze 另有 1 个既有问题，位于 `tool/ui_shell/model_providers_preview.dart:122`（r33 移除采样字段后遗留的预览脚本），与本批无关，未改。
- 已随 r37 构建安装；未启动程序，未操作真实图库。

## 边界

- 批量为顺序执行，首个失败即停，不是跨文件原子事务，不自动回滚已完成项。
- 扫描锁仍按单图持有；每张图仍单独备份原图，大批量有磁盘与 IO 成本。
- 多原目录撤销会按组多次调用，开启保护时可能每组确认一次。
- 证据：`.devin/runs/gallery-batch-1022/`（勘察与后端报告、日志）。

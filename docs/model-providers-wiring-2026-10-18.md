# 模型服务商工作台接线记录 · 2026-10-18

## 状态

**实现与新增回归完成，但按“全部通过后再提交”的门槛，当前验收阻塞、尚未提交。** 分支 `devin/model-providers-wiring`，起点 `35f2ab943`。没有 push、merge、checkout、rebase、stash，也没有操作其他 worktree / 运行实例、调用真实模型或 NovelAI 生成接口。

阻塞不涉及契约缺字段：干净 `35f2ab943` 的同环境复跑也有 11 张服务商 golden、2 项工具页测试和 2 项旧设置测试失败。任务书只明确豁免 settings golden；未将其他失败擅自视为通过，也未修改黄金图、比较器、跳过条件或容差。需要负责人处理这些基线问题，或明确接受已核验的既有失败后，才能越过提交门槛。

## 修改文件

- 新增 `lib/presentation/wiring/settings/providers_projection.dart`：共用存储投影、草稿合并、请求头 / JSON overrides 校验、价格与分组适配。
- 新增 `lib/presentation/wiring/settings/providers_workbench.dart`：wiring 层 Notifier，存服务商 / 模型测试、目录、异步安全存储投影及 Key 掩码；实现全部 11 个回调。
- `lib/presentation/wiring/settings/settings_models.dart`：组装 `workbench`，继续组装概览 / 搜索 / 分配使用的 `providers`；删除旧服务商操作方法及 `AiServiceEditor` 设置页接线入口。
- `lib/presentation/wiring/settings/settings_wiring.dart`：通过现有 `_run` / toast 接入 `SettingsActions.providers`，撤掉旧服务商回调接线。
- `lib/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart`：新增批量添加、专用排序；`saveServiceDraft` 新增默认保持旧行为的 `enrichModels` 参数，工作台传 false，避免保存时二次 enrich 改写契约未暴露的隐藏字段。
- `lib/presentation/ui/settings/settings_models.dart`：仅移除旧服务商列表 / 详情 fallback；工作台本身不改。
- `lib/presentation/ui/settings/settings_contract.dart`：仅清除已退役旧回调、字段枚举及私有空实现；新工作台契约不变。
- `lib/presentation/ui/settings/settings_page.dart`：删除添加按钮的旧编辑器 fallback，沿既有页内弹窗通道执行。
- `lib/l10n/app_{en,zh,ja,ko}.arb`：新增 10 个错误 / 校验短句，清除 12 个无生产引用旧键。按流程生成 `app_zh_TW.arb`、`app_localizations.dart` 及 en / ja / ko / zh 本地化输出。
- 新增 `test/presentation/wiring/providers_workbench_test.dart`：44 项离线单元 / widget 回归。
- `test/presentation/wiring/settings_provider_logos_test.dart`：改为验证实际新工作台的 logo / mark。
- `test/presentation/ui/settings/settings_test_harness.dart`、`tool/ui_shell/settings_preview.dart`：删除旧回调参数引用。
- 本报告 `docs/model-providers-wiring-2026-10-18.md`；同文追加到工作区接线说明 §7。

`lib/presentation/ui/model_providers/` 及其现有测试、所有 golden 均未修改。`pubspec.lock`、三个 `windows/flutter/generated_*` 最终 SHA-256 与施工前逐字节一致，保持原改动且不纳入提交。没有新增依赖。

## 11 个回调

| 回调 | 实现 |
|---|---|
| `onCreate` | 按 preset.name 查预设，移植名称归一化 / defaultId / `_2` 去重，`createConfig` 后即时写入；失败返回 null 并走 toast。 |
| `onEnabled` | 对最新 provider `copyWith(enabled:)` 即时保存，刷新投影；异步异常交现有 `_run`。 |
| `onTest` | 使用 edited 地址 / 协议 / 请求头、临时 Key（null 读已存 Key）及首模型草稿；无模型则 discovery。只写内存测试事实，不保存草稿。连接指纹与已存相同时同步 health。 |
| `onTestModel` | 同上，使用指定模型的草稿参数 / overrides；写 `(providerId, modelId)` 的 testing / lastTest；删模型或连接变化后的迟到结果不能复活。 |
| `onSave` | 重新读取最新配置、provider headers 和各模型安全 overrides，共用投影与 base 作 `==`；不符返回 conflict、不写入。逐字段把 edited 合并到最新 ModelConfig，保留隐藏字段与未修改的 null / 能力 / 遗留 reasoningEfforts。校验后调用已有事务保存 provider、模型、headers、overrides、Key；失败回滚并返回 failed。Key null 不改、空串清除、其他写入。Future 返回前等待串行投影刷新。 |
| `onRevealApiKey` | 按需读取并返回 Key，不在 wiring 状态缓存明文；失败返回 null 并提示。 |
| `onFetchCatalog` | 仅用已保存连接，loading / ready / failed 保存在同一 Notifier；查目录事实、格式化 input / output 价格、写既有缓存；连接指纹重验，失败保留旧条目。有启动缓存时 ready、fetchedAt=null。 |
| `onAddModels` | 批量方法加载目录并 lookup / enrich，按输入顺序追加，跳过已有 / 重复 ID，api / manual 来源按契约设置，最后只 `_save()` 一次。 |
| `onRemoveModel` | 复用 deleteModel 及现有功能槽回落；通过既有 Agent checked setter / store patch 把对应选择置空，不创建工作区、不启动宿主。 |
| `onReorderModels` | 仅调整该服务商非占位模型的相对顺序；其他服务商、占位位置、模型对象与安全 overrides 不动，最后 `_save()`。 |
| `onDelete` | 复用已有删除事务清 provider / 模型 / Key / headers / overrides、功能槽；同步清对应 Agent 选择，刷新投影。 |

补充口径：local 使用 preset.isLocal，否则 type==ollama；能力显示取 model ?? catalog；遗留档位沿用 availableReasoningEfforts；模型 usedFor 只含 4 个 SettingsModelTask；价格缺 input 或 output 时 null；Key 足够长时前 3 + 4 个圆点 + 后 4，短 Key 只给圆点；并发刷新串行化，状态只存内存，不改缓存 / 配置格式。

## 删除范围

- 现行设置页旧服务商列表与详情、旧内联字段即时编辑、旧模型添加 / 测试 / 刷新 / 高级编辑回调，以及 `SettingsProviderField`。
- `SettingsModelActions` 的旧服务商方法、busy / latency providers，及 AiServiceEditor / provider picker imports。
- ARB 旧键：`set_mdAddModel`、`set_mdAdvanced`、`set_mdApiKeyEmpty`、`set_mdCapReasoning`、`set_mdCapTools`、`set_mdCapVision`、`set_mdLatency`、`set_mdLocal`、`set_mdModels`、`set_mdName`、`set_mdRefreshModels`、`set_mdRemoveModel`。删除前 rg 核对，删除后 ARB parity 通过。
- **保留共享旧编辑器文件**：`ModelManagementSection` / `AiServiceEditor` 仍被提示词药丸原位配置、旧兼容 SettingsScreen 和大量旧组件回归引用；不是无引用文件，未连带删除。实际应用 `/settings` 路由已经是 `SettingsWiring`，其中不再引用旧服务商编辑器。

## 验证命令与结果

所有有效验收使用 Flutter 3.47.7 / Dart 3.13.5。Git Bash 正确 PATH 写法是 `/e/A.I/NovelAI/.devin/sdk/flutter-3.47.7/bin`；`E:/...` 放进 PATH 会被冒号分开。初始 `.dart_tool/package_config.json` 还指向 C:/flutter 的 3.44.2 framework，已经修正当前工作树本地映射，混合 SDK 的中间结果不作为最终证据。精确的 analyze 命令会自动 pub get；其触及的锁文件已恢复施工前字节并用 SHA-256 复核，未提交依赖变更。

1. `UPDATE_ZH_TW=1 flutter test --no-pub test/l10n/zh_tw_resources_test.dart`，随后 `flutter gen-l10n`：通过。
2. `flutter analyze lib test tool`：通过；最后代码改动后再跑 `flutter analyze --no-pub lib test tool`：**No issues found**。
3. `flutter test --no-pub test/presentation/wiring/providers_workbench_test.dart`：**44 通过**。覆盖成功 / 冲突 / 失败及回滚、Key 三态、headers / overrides 读写与重复键 / JSON / 参数范围拒绝、目录预填与批量单次保存、排序保留占位和 overrides、功能槽与 Agent 删除回落、草稿测试不保存、临时 Key、health 指纹、目录缓存与迟到结果、隐藏字段及 null 保留、UI 草稿与即时操作合并、新界面真实投影。
4. `flutter test --no-pub test/presentation/ui/model_providers test/presentation/ui/ui_shell_boundary_test.dart test/l10n test/presentation/wiring`：**759 通过，13 失败**；干净 `35f2ab943` 同环境为 **715 通过，13 失败**，失败集合完全相同，没有新增失败。
5. `flutter test --no-pub test/presentation/prompt_assistant test/presentation/screens/settings test/app_test.dart test/presentation/ui/settings/settings_model_reasoning_test.dart test/presentation/ui/settings/settings_request_details_test.dart`：**461 通过，2 失败**；干净前端壳也是 **461 通过，2 失败**，覆盖勘察 §10 整个目录，失败集合相同。
6. `flutter test --no-pub test/presentation/ui/settings/settings_golden_test.dart`：**24 通过，3 失败**；干净前端壳复跑也是 **24 通过，3 失败**，集合始终为 `dictionaries`、`models`、`models-dark`。任务书所载 `0052a9d0a` 历史 27 张失败保留为历史口径，本次实际环境是 **3 → 3，新增 0**，不是声称 27 张已修好。
7. 聚焦绿色回归（prompt_assistant 全目录、app_test、全部 settings wiring、新增接线、l10n、UI 边界、服务商交互、任务 / 请求 UI）：**364 通过，0 失败**。命令：

```bash
flutter test --no-pub test/presentation/prompt_assistant test/app_test.dart \
  test/presentation/wiring/providers_workbench_test.dart \
  test/presentation/wiring/settings_*test.dart test/l10n \
  test/presentation/ui/ui_shell_boundary_test.dart \
  test/presentation/ui/model_providers/model_providers_test.dart \
  test/presentation/ui/settings/settings_model_reasoning_test.dart \
  test/presentation/ui/settings/settings_request_details_test.dart
```

8. `git diff --check` 通过；4 个受保护文件 SHA-256 全部与施工前一致；新工作台 UI / 既有测试 / golden 的受控文件 diff 为空。没有运行 --update-goldens，没有构建安装包、热重载或重启应用。

### 未通过项目（干净基线同样失败）

- 服务商 11 张 golden：`ready`、`ready-dark`、`pro`、`catalog`、`catalog-dark`、`error`、`headers`、`unsaved`、`add`、`add-dark`、`narrow`。例如 ready 差 2807 像素 / 0.16%，已查看局部对比，主要是细小绘制差；具体根因尚未定位，不能声称已通过。
- `test/presentation/wiring/tools_wiring_test.dart`：`enhance uses locked sheet, backups and request projection; draft source stays intact`、`upscale arrow opens settings; method and SeedVR2 options persist without taking draft image`，均 pumpAndSettle 超时。
- `test/presentation/screens/settings/settings_hover_feedback_test.dart`：`all four task hints and hover/tap reasoning advice leave configured effort untouched`，旧提示文案未找到。
- `test/presentation/screens/settings/model_menu_activity_test.dart`：`test marker returns after failure`，pumpAndSettle 超时。
- 上述 settings golden 3 项为任务书明确允许核对集合的既有失败；其他项目尚未获得豁免。

基线通过在**本工作树**逐文件备份、临时放回 HEAD 内容、运行相同命令、finally 恢复施工文件取得；没有切分支、stash 或操作其他工作树。完整本地证据在 `.dart_tool/mp-wiring/`（`clean-main` / `main-final`、`clean-related` / `related-final`、`clean-settings-golden` / `golden-final` JSONL；不入库）。

## 遗留 / 前端需求

- 契约字段：**无需新增字段**。
- 提交：**未提交**，因为要求的整组测试不是全绿；没有用“基线也失败”冒充任务书未豁免项目已通过。
- 前端需核验现有 11 张服务商 golden 在登记 SDK 下的基线问题；接线侧未改受保护界面或基准。另 4 项旧工具 / 设置失败需相应维护者处理，或由负责人明确接受既有失败再提交。
- 目录时间戳、测试耗时、临时草稿结果按既定口径只留内存；这是约定，不是遗漏。

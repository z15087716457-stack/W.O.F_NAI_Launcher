# 生图页后端接线收口（2026-10-13）

本批在 `.devin/wt/ui-gen`／`devin/ui-gen` 接续前端基线 `eb5415d7`，完成生图页后端的分支内收口。各页面分支尚未整合，未构建或安装桌面包，未启动、重启、热重载或操控 Studio，未更新 UIUX Preview，未调用真实生成或付费编码接口，未推送。

## 提交范围

- `GenerationRoute`／`GenerationWiring` 接入真实首页与生图路由；91 个契约回调全部绑定，编辑器、块库侧栏、参考投放和历史拖出四个槽位接入既有实现，画布使用锁定界面自带舞台。
- 16 份 `generation_*.dart` 转接层提供模型能力、额度、token、提示词／角色／参考／参数、生成占位、流式帧、历史和画布数据。`GenImageData.repeat` 对应 `ImageParams.nSamples`，`count` 对应 `imagesPerRequestProvider`。
- 草稿写入先完整备份，写前复核参数、药丸文档、账号、工作流和任务世代；角色按稳定 ID 绑定。清空撤销、ComfyUI 导入、参考编码／导入与参数复用保留旧结果保护，读取存档不初始化未打开的负向 lane。
- 重试使用上次请求快照、张数、工作流和账号，不使用当前新草稿或重抽药丸；重新报价并校验确认期间状态。
- 文件／库参考支持追加、替换及稳定实例 ID，重复追加库来源保留用户已调整的参数；无效旧 Vibe 来源索引在导入链路回退为 `rawImage`，保留编码及编码模型。
- 历史焦点、删除／清空、保存／打包、收藏、复制、种子、图生图和工具入口接入既有业务。增强继续使用 `GenerationToolPanel`；新的画布工具壳接线属于后续独立批次。
- 生图结果接入新查看器，原图不降采样到 4096；全屏／最大化跨实例串行恢复，直接离开路由也恢复宿主状态。查看器翻译有忙态和逐段请求票据，取消后旧结果不会恢复，不写生图草稿。
- 生图与查看器快捷键读取用户配置，支持禁用及全局关闭；参数抽屉定位不依赖编辑器焦点。
- 同一提交删除用户已批准的六份旧生图界面和两份专用测试，共八份；有效历史、复制、共享删除确认和小贴士回归迁移或保留，截图公共数据迁入 `test/helpers/generation_history_fixture.dart`。没有扩大删除范围。
- 五语言仅删除同一批 30 个零引用旧键，保留共享 `generation_history` 与 `generation_deleteSelectedImagesConfirm`；繁中资源和本地化成员沿现有生成流程更新。旧国际化测试引用迁到现存接口。

## 最终验证

使用登记的 Flutter 3.47.7／Dart 3.13.5。接手时已结束的综合日志已现场核实；本次最终审查仅调整拖入接线文件的一处 formatter 排版，没有新增行为修改或重跑大批测试。下列计数不相加，也不代表全仓测试或真实桌面整合验收通过。

| 检查 | 结果 |
|---|---|
| 综合专项，`--exclude-tags locked-ui-defect` | 1356 项通过，日志结尾 `+1356: All tests passed!`；含本树全部锁定 UI／截图、接线、提示词／药丸、桥接、生成 provider、工作流、计费、模拟 API、快捷键、迁移和国际化 |
| 单独 `--tags locked-ui-defect` | 6 项失败，全部为 352px 左栏尺寸行横向溢出 32px；V3／V4.5／V5 × 明／暗各一项 |
| 最终修改范围分析 | 60 个现存修改／新增 Dart 目标，退出 0，`No issues found!`，覆盖其余 provider、服务、路由、共享编辑器和生成成员 |
| 最终格式检查 | 60 个文件，0 个需要格式化，退出 0 |
| 保护清单 | 374 份保护文件／4 个原有改动内容保持；可读 JSON 副本与原清单逐字节一致 |
| 差异与引用 | `git diff --check` 通过；活动 Dart 无八份退役路径引用；91 个必需契约回调无缺项；五语言删除键一致，既有键值无额外修改 |

本机核验材料保存在 `.dart_tool/ui-gen-final-20261013/`：`comprehensive.log`、`locked-ui-defect.log`、`analyze.log`、`format.log`、`dart-scope.txt`。综合与窄栏日志从用户接手材料给出的两个已结束任务日志复制，原件未改。保护原件 `.dart_tool/ui_gen_guard.py`、`.dart_tool/ui-gen-protected.json` 和 `.dart_tool/ui-gen-originals/` 保留；`tool/` 下两份临时可读核验副本不进入提交。

## 留给前端与整合的边界

- **FE-03：352px 左栏尺寸行溢出 32px。** 定位 `lib/presentation/ui/gen/gen_image.dart` 的尺寸 `Row`（约第 86 行），不接后端的原 `GenFixture` 也已复现。用户选择保持界面锁定：不改 UI、契约、fixtures、goldens、布局最小宽度或失败断言，不使用 `--update-goldens`。六项独立失败保留为 `locked-ui-defect`；420／560px 正常宽度矩阵通过。临时纯前端探针已删除。
- 多语言定稿和其他前端布局收尾继续按 UIUX 入口清单处理；本批不将 `gen_*` 草稿语言记为已定稿。
- 独立页面分支、画布工具壳、桌面构建／安装和用户实机验收另行处理；本地分支完成不代表这些工作完成。
- `analysis_options.yaml` 与三份 `windows/flutter/generated_plugin*` 原有文件保持未提交。根工作区 UIUX 入口与更新日志仅更新本批记录，既有根仓库改动不纳入此源码提交。

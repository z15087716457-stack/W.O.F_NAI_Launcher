# 设置未保存蓝点与画布文案 · 2026-11-14

按用户确认在有效源码 `codex/uiux-integration` 完成。**仅源码更新，尚未构建／安装；桌面仍为 2.3.4+103。** 此前 Agent 项目规则、图库、界面缩放与推荐上下文等未提交改动保留。

## 最终行为

- 蓝点统一表示未保存草稿。即时保存的标量设置、自定义快捷键及隐私卡片不因偏离默认值常亮；各类控件沿用原保存、撤销和恢复默认流程。
- `SettingsRow.modified` 继续控制单项恢复默认；未保存提示由独立的 `unsaved` 状态控制，避免把默认值差异当成未保存。Agent 全局指令、前置内容及基础提示词显示对应蓝点，标签提示为「有未保存的修改」。
- 保存成功、放弃或改回已保存值后清除；失败保留草稿与错误提示；保存期间再编辑的内容仍是下一次待保存草稿。服务商／模型编辑器原本按真实草稿显示的蓝点继续保留，连接状态点及选择控件保持原有语义。
- 设置、画布菜单与提示中的名称统一为「放大适应画布」，五语言及画布教程同步。说明聚焦图片时允许超过100%放大，并按比例完整显示；关闭时自动适配最高100%。设置默认值仍为开启，已保存的关闭偏好继续生效；本轮未修改缩放算法或用户配置。

## 验证

登记 SDK：Flutter 3.47.7／Dart 3.13.5。没有改动代码生成输入，仅按既有流程生成繁中及本地化。

- **525 项行为与布局回归全部通过**：设置各页（含搜索、恢复默认、Agent 草稿、失败／重试／保存期间再编辑）、模型服务商编辑器、画布界面与实际设置接线。包括五语言、宽窄窗、深浅主题与150%缩放。[最终日志](../.dart_tool/settings-unsaved-dots-20261114/functional-final.log)
- 首轮 **127 项专项通过**，与上述回归存在重复；额外覆盖画布显示偏好持久化、服务商保存生命周期、UI分层边界及语言资源完整性。[专项日志](../.dart_tool/settings-unsaved-dots-20261114/target-tests.log)
- 繁中生成检查 **4 项通过**，随后 `flutter gen-l10n` 成功。[繁中](../.dart_tool/settings-unsaved-dots-20261114/l10n-zh-tw.log)／[生成](../.dart_tool/settings-unsaved-dots-20261114/l10n-generate.log)
- 全仓 `dart analyze`：**No issues found**。[日志](../.dart_tool/settings-unsaved-dots-20261114/analyze-final.log)
- 已查看真实字体Flutter实绘：[保存设置](../.dart_tool/settings-unsaved-dots-20261114/captures/storage-zh-1600.png)、[失败草稿与蓝点](../.dart_tool/settings-unsaved-dots-20261114/captures/failure-zh.png)、[画布宽屏](../.dart_tool/settings-unsaved-dots-20261114/captures/canvas-zh-1600.png)、[900窗口／150%深色](../.dart_tool/settings-unsaved-dots-20261114/captures/canvas-zh-900.png)。这些是隔离部件实绘，不是用户运行窗口。

几何与原有组件定义对照：蓝点宽／高6px、与标签间距7px、垂直中心残差0px，最大尺寸残差 **0px**。删除已保存标记和改变画布文案是有意变化；标题左边界、说明对齐与恢复默认回调另由宽窄测试验证。[测量脚本](../.dart_tool/settings-unsaved-dots-20261114/settings_measure.py)／[偏差表](../.dart_tool/settings-unsaved-dots-20261114/measurements.json)

## 旧截图检查的明确限制

完整设置截图检查结果为 **20项通过、7项失败**。剩余不一致页面：`appearance`、`appearance-dark`、`storage`、`dictionaries`、`rag`、`upscale`、`upscale-dark`。

使用施工前备份的23份文件复跑，确认这7项在本轮修改前已经失败；复跑后逐字恢复本轮文件。另修正上一轮 Agent 改名遗留的一条顺序断言。本轮新增的画布文案及蓝点差异已用对应的小区域和行为实绘承接，未改原PNG基准、未扩大其他页面豁免；截图检查仍保留这7项既有失败，不能称为全套通过。[改前复现](../.dart_tool/settings-unsaved-dots-20261114/before-goldens.log)／[最终截图检查](../.dart_tool/settings-unsaved-dots-20261114/goldens-final.log)／[复现脚本](../.dart_tool/settings-unsaved-dots-20261114/probe_before.py)

备份、完整改前差异与边界核验在 `.dart_tool/settings-unsaved-dots-20261114/`。已有无关源码和生成文件哈希保持，锁定PNG未变；未启动Studio、请求模型／生图、修改真实用户偏好或提交Git。[边界核验](../.dart_tool/settings-unsaved-dots-20261114/final-verification.json)

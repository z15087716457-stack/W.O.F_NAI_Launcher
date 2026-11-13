# 精准参考导入弹窗

2026-11-12：按用户批准的[HTML样板](../../../mockups/pr-reference-type/README.md)接入Flutter。仅源码交付，桌面与公开版本仍为2.3.3+99；未打包安装、启动Studio或提交Git。

## 实现

共用组件`lib/presentation/widgets/common/precise_reference_type_dialog.dart`改为368×370px紧凑弹窗，增加用途说明、关闭按钮与Esc提示。大图、图库和Agent入口继续复用此组件，无需修改调用方。三种`PreciseRefType`及取消返回`null`的契约保持，点击选项立即返回，不增加确认步骤。

复用现有UiColors、UiText、UiKeycap和图标，支持深浅色、原生键盘焦点循环与关闭后焦点恢复。短窗口中间内容可滚动，关闭和取消仍可见。新增文案覆盖简中、繁中、英、日、韩；繁中通过既有OpenCC测试生成。现有类型译文保留，因此中文组合类型仍为`角色+风格`，与样板全角加号存在文字差异。原生Esc键帽和文字栅格化沿用应用组件。

## 验证

- 弹窗专项39项：三种选择、四种取消、键盘循环／Enter、短窗滚动，以及五语言×深浅色×常规／窄窗／150%字号的30种布局。
- 相关回归共115项通过，0失败、0跳过：覆盖Agent图片动作、生成页导入／选择器、图片目标选择、UI边界及繁中资源。
- 对组件、对应测试和`lib/l10n`执行Dart分析，0问题；两个修改的Dart文件格式检查无需调整。
- 使用真实应用字体生成30张Flutter实绘截图。深浅色与批准样板并排自查；常规中文的弹窗、标题区、底栏及三行选项共24个几何读数最大差0px。字号扩大时允许文案换行与中间滚动，不强制370px高度。
- 本轮浏览器连接恢复超时，未重新采集DOM；使用已批准、源文件哈希核验通过的浏览器截图，独立扫描边框像素，再与本轮Flutter布局及实绘比对。未把旧浏览器证据标成新采集。

证据目录：`.dart_tool/pr-reference-type-20261112/`，包含`final-tests.log`、`analyze.log`、`captures/`、`visual/compare-dark.png`、`visual/compare-light.png`、`geometry-comparison.json`及`verification.json`。预期尺寸来自批准样板栅格边框测量，原样板App/CSS和截图未修改。

本次未写用户图片、参考配置或草稿，未调用生成接口。此前在线大图拖窗、普通增强尺寸及质量词命名改动保留；应用实窗与真实图片导入待后续桌面交付验收。

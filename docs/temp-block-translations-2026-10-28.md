# 临时块内翻译与底部快捷操作

2026-10-28（Asia/Taipei）。本轮已随本机 **2.2.0+59** 安装（编译 `1283c03e0`，2026-10-28 20:35 Asia/Taipei），正式收据及程序文件核验通过。有效源码与安装范围见[当前接手说明](../../../../04_工具/启动器接手说明.md)。

## 用户确定的范围

- 主要用法是 Agent 把原始提示词模块化拆解为多个临时块，每块内部通常只有一段完整翻译，也允许保存多个翻译块。
- 内部翻译块只需左键／中键切换原文与译文；编辑继续用外层“继续编辑”。
- 左下角增加 A“还原为原文”和垃圾桶。前者去掉临时块及内部翻译外壳、保留当前原文，后者连块带内容删除，均沿用原有撤销链路。
- 用户明确要求：示例仅作功能预览，不将示例的布局／配色搬入程序；原卡片的标题、说明、内容框和现有按钮样式保持。

## 实现

- `PillTempContent` 增加可选的 `translations`／`negativeTranslations`，复用已有 `TranslationPill`；旧草稿缺字段时为空。生成投影始终读取原 `content`／`negativeContent`，不读取译文。
- 内部显示复用 `TranslationPillView`，仅在临时块中启用左键切换；中键保持原有切换语义。局部显示状态不写生图草稿，不发起模型请求，不打开子编辑浮窗。内部不显示标签注释交互，已有注释数据仍保留。
- 继续编辑仍是现有原文输入框。内容变化只保留完整原文仍匹配的译文，避免显示已失配译文；展开可使用输入框里尚未点“应用”的最新原文，并作为一次撤销操作。
- Agent 的 `instance_create`／`instance_convert`／`instance_update` 可携带 `instance.translations:[{source,zh,language_code?}]`，最多 64 段，按内容顺序匹配；普通场景使用一个覆盖整段内容的翻译。已有完整翻译块也可按生成原文锚点转换为一个临时块，译文、普通文字和分隔符保留，投影逐字一致，一次撤销。
- 提升到块库时将分段阅读文本合成现有块库阅读字段，保留原文、语言及待核对标记；不引入块库数据结构迁移。工具声明仍为扁平对象，描述长度保持原检查上限。
- 新按钮在当前临时块页脚内接原生展开／移除。无库临时块放在原页脚左侧；原本带“还原为原块”的卡片保留原按钮行，在其下方追加两个快捷入口。英文／日文空间不足时只在页脚内换行，保留按钮文字与样式。

## 验证与证据

证据目录：有效源码 `.dart_tool/temp-nested-translation-20261028/`。修改前备份和实绘位于 `before/`、`before-captures/`，原有文档备份位于 `docs-before/`；截图基准与原型 PNG 未覆盖。

- 针对性 Flutter 回归：118 通过，覆盖创建／更新／存块、旧草稿兼容、真实 Hive 草稿重开、正负面配对、转换已有多段翻译、原文投影、展开／删除与撤销，以及整段／多段内容的五语言明暗主题 UI、左键／中键切换及未应用原文展开。
- Node：112 通过。最初一次运行记录了旧长度上限超出 2 字符及保温计时超时；精简工具描述后，在无 Flutter 重负载时同命令完整复核通过，未修改计时断言。日志 `node.log` 与 `node-recheck.log` 均保留。
- 全仓 `flutter analyze --no-pub`：无问题，见 `analyze-final.log`。
- 最终业务源码完整 Flutter（`--concurrency=4`）**9775 通过／0 失败／5 项既有跳过**，见 `full-regression.jsonl`、`full-result.json`。最终 A 按钮及截图补帧检查见 `ui-final.log` 和 `ui-analysis-final.log`；只是采图时多等一帧，避免截图遗漏尚未刷新的静态绘制。
- 修改前后非翻译样例逐像素对照：标题、说明与内容区域保持，差异位于新增页脚入口及其阴影／高度影响范围；见 `pixel-comparison.json`。新增译文样例为真实 Flutter 部件实绘，不是 HTML 示例或用户运行窗口；最终实绘在 `verified-captures/`，主场景 `temp-nested-single-light.png`。

## 本机交付

用户随后明确要求“ok，安装吧”。版本已提交为 2.2.0+59，编译 `1283c03e09e6747fef7fbf3bfe0c3c66887d337f`；Windows Release 成功，2101 个生产输入冻结并核验。完整功能回归 9775／0／5 与 Node 112 按生产源码一致性复用，新增版本／更新检查 56 通过、安装／回退夹具 12 通过；完整程序包、四份 SQLite 资源、19 个字体文件、Agent／CodeMode 与隔离 RAG 冒烟通过。

在 Studio／Agent 完全退出后原位安装，仅替换 AOT、exe、清单、Agent 工具声明与块用法 5 个文件；完整程序树 15294 个文件及 226 个资源核验通过。桌面入口、用户数据根、旧 AppData 兼容联接及正式索引元数据保持，备份可单步回退到 +58。AOT SHA-256：`dd649a14dcec95e2a1cbe4f3f494efe24efd6e3de43e2523a351ad1364fe553e`。

交付材料 `.dart_tool/cumulative-2.2.0-r3-20261028/`；[已安装收据](../.dart_tool/cumulative-2.2.0-r3-20261028/installed-delivery.json)、[最终核验](../.dart_tool/cumulative-2.2.0-r3-20261028/final-verification.json)。需要回退时，完全退出 Studio／Agent 后在该目录运行 `python update.py rollback`。

本次没有自动启动／重启／热重载 Studio，没有写用户草稿或桥接、真实模型调用、生图、正式建库、制作 ZIP 或发布 GitHub。程序包与安装验证不代替用户实机体验验收。

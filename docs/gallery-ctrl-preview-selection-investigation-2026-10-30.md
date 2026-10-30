# 本地图库首次 Ctrl 多选带入预览图 · 调查

**当前状态：已按用户确认完成源码修复，43 项相关检查与定向静态分析通过；尚未编译、安装或推送。** 首次 Ctrl/Cmd 只选点击图，Shift 范围和其余 UI 保持。下文调查部分保留修复前现状，实施与验证见文末。

2026-10-30（Asia/Taipei），按用户“先调查一下”执行。调查源码 `dee38ab6b928b0fe8dc3a8ca15d1e5f2d87e5ee6`，该调查阶段未修改运行代码、现有测试和安装包。

## 结论

普通单击 A 仅改变侧栏查看对象，尚未加入多选。随后首次 Ctrl+点击 B 时，时间线主动把 A 加入多选，再切换 B 的选中状态，因此集合变成 `{A, B}`。这是现有交互规则造成的真实多选，不是边框误绘或删除接口临时多加一张。

用户要求的新规则是：普通预览与多选独立；首次 Ctrl+点击只选本次点击的 B，进入多选后继续按既有规则累加／取消，Shift 保留范围选择。

## 代码路径

- 查看对象存放于 `localGalleryFocusNotifierProvider`，右侧详情面板读它；多选另存于 `localGallerySelectionNotifierProvider.selectedIds`，数据结构已经分开。
- `GalleryTimelineView._handleTap` 的 `selection.isActive || isCtrl` 分支在首次进入多选时读取 focused，调用 `selectionNotifier.select(focused)`，再 `toggle(path)`。问题就在这次主动补选。
- `LocalImageCard` 的描边使用 `isSelected || isFocused`；勾选圆圈只看 `isSelected`。所以预览时仅有强调边框，首次 Ctrl 后两张都会出现实心勾，与用户截图一致。
- `_deleteSelectedImages` 将 `selectedIds.toList()` 交给 `service.getRecordsByPaths`，确认后对返回记录批量删除。Delete 键在多选非空时同样调用该方法；误带入的 A 会进入真实删除名单。复制、移动、打包等批量操作也使用同一集合。
- 现有 `gallery_timeline_view_test.dart` 的测试明确要求 Ctrl+点击把 focused 图一起选上；`OPERATIONAL_NOTES.md` 也记录了该旧规则。后续修复时必须同步改掉对应预期，不能为保住旧测试而恢复用户不希望的行为。

## 隔离复现

使用真实 `GalleryTimelineView`、`LocalImageCard`、多选 provider 与 `GalleryFloatingBulkBar`；图库由 `FakeLocalGalleryService` 提供 40 条合成记录。删除按钮／Delete 键回调只记录路径，记录查询使用同一个内存服务，未执行实际删除。

| 场景 | 当前源码实测 |
|---|---|
| 网格：普通预览 A，再 Ctrl+点击 B | `{A, B}`；两张真实勾选，按钮与 Delete 回调均得到两条候选 |
| 瀑布流：相同操作 | 同上 |
| 火车流：相同操作 | 同上 |
| 尚无预览图，直接 Ctrl+点击 B | 只有 `{B}` |
| 预览 A，再 Ctrl+点击 A | 只有 `{A}`，不重复 |
| 预览 A，调用 B 的选择圈回调 | 只有 `{B}`，不会带入 A |
| 预览 A，再 Shift+点击 D | 正常选择 A 至 D 的范围 |
| 多选后继续 Ctrl，Esc 退出，再 Ctrl 新图 | 当前集合正常累加；Esc 保留查看对象，下次首次 Ctrl 又会带入该对象 |

最终 **8 项调查断言全部通过**，表示上述现状已被复现，不代表问题已修复。不是全仓回归，也不是对真实图库执行删除的验收。Meta/Cmd 与 Ctrl 在源码共用同一判断，本次仅实测 Ctrl。

初次临时探针因回调引用局部函数的声明顺序编译失败，修正探针后 8 项全部通过，原始日志保留；生产文件未改。

证据位于 `.dart_tool/gallery-ctrl-selection-20261030/`：`investigation_test.dart`、`probe.log`、`probe-initial-fixture.log`、`before.json`、`verification.json`。

## 建议修复边界

1. 仅修改首次 Ctrl／Meta 进入多选的分支：进入后只切换本次点击的图片，移除把 focused 自动加入集合的步骤。
2. 保留已有多选中的累加／取消、Shift 范围、选择圈、分组全选与 Esc 规则，不新增状态结构或改 UI 布局。
3. 同步 focused provider 注释、旧交互文档和旧 Ctrl 测试。补上预览 A → Ctrl B 仅选 B、删除候选仅有 B，以及三种布局的回归。

上述为调查阶段记录：当时尚未实施、构建、安装或推送，未启动／操作用户 Studio、访问真实图片内容、改写图库／索引／草稿或请求模型与生图。

## 修复与验证（2026-10-30）

用户确认“首次 Ctrl 只选点击的图，Shift 范围选择保持，其他 UI 别动”后，仅移除首次进入多选分支中主动读取并选中 focused 的四行代码；已有 toggle、focus 更新及完整 Shift 分支保持。同步 focused provider 注释、交互说明与 Unreleased。

先将原 Ctrl 测试改为新要求，三种布局均按预期失败；保留 `before-fix-tests.log`。实现修复后，新跑以下五个套件 **43 通过／0 失败**：

- 时间线交互：三种布局先预览 A 再 Ctrl B 时仅 B 选中、A 取消预览强调，Delete 回调与内存服务查询只得到 B；保留已有 Ctrl／普通点击累加取消、Esc 后重新起选；覆盖无预览、同图、选择圈和 Ctrl 后 Shift 范围。
- 多选 provider：既有范围及反向范围检查。
- 卡片手势：既有即时点击、悬停按钮、选择圈与焦点／选中描边检查。
- 浮动批量操作条：既有选择与操作检查。
- 本地图库页面布局：既有搜索、布局、筛选、导航与状态恢复检查。

三个变更 Dart 文件定向 analyze 无问题。未修改卡片、详情面板、浮动批量条、选择 provider、页面及版本文件，修复前后对应六个文件 SHA-256 保持；Shift 分支与修复前完全一致。没有改控件、配色、间距、图标、菜单或窗口布局。

证据：`.dart_tool/gallery-ctrl-selection-fix-20261030/` 的 `before/`、`before-fix-tests.log`、`tests.log`、`analyze.log` 与 `verification.json`。全部使用合成图库和回调记录，未执行实际图片删除。

源码修复已完成，本机仍使用登记的 +63；本轮未构建／安装／推送、操作用户 Studio、请求模型或生图，也未改写真实图库、索引和草稿。

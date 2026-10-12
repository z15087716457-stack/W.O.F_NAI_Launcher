import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'gen_canvas.dart';
import 'gen_character.dart';
import 'gen_contract.dart';
import 'gen_generate.dart';
import 'gen_header.dart';
import 'gen_history.dart';
import 'gen_image.dart';
import 'gen_params.dart';
import 'gen_parts.dart';
import 'gen_prompt.dart';
import 'gen_refs.dart';

/// 页面级的界面状态和命令：菜单、弹层、弹窗、参数抽屉，各部件通过 [GenScope] 拿到。
abstract class GenController {
  /// 弹一个菜单；[tag] 用来让触发按钮显示“打开中”。
  void openMenu(
    UiPopoverAnchor anchor,
    List<UiMenuItem> items, {
    Object? tag,
    double width = 210,
  });

  /// 弹任意内容（外观由 [builder] 自己画）。
  void openPopover(
    UiPopoverAnchor anchor,
    WidgetBuilder builder, {
    Object? tag,
  });
  void closePopover();
  Object? get popoverTag;

  void openDialog(WidgetBuilder builder);
  void closeDialog();

  /// 参数抽屉。
  bool get drawerOpen;
  void setDrawer(bool open);

  /// 全屏编辑提示词。
  void openFullscreen(GenEditorTarget target);
}

class GenScope extends InheritedWidget {
  const GenScope({
    super.key,
    required this.data,
    required this.actions,
    required this.slots,
    required this.controller,
    required super.child,
  });

  final GenViewData data;
  final GenActions actions;
  final GenSlots slots;
  final GenController controller;

  static GenScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenScope>()!;

  @override
  bool updateShouldNotify(GenScope old) => true;
}

/// 组件在屏幕上的矩形（接线方自己弹现有面板时定位用）。
Rect genRectOf(BuildContext context) {
  final box = context.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// 贴在组件下方（[dy] 间距）；[right] 时右边对齐。
UiPopoverAnchor genBelow(
  BuildContext context, {
  double dy = 6,
  bool right = false,
}) {
  final r = genRectOf(context);
  return UiPopoverAnchor(
    right ? r.bottomRight + Offset(0, dy) : r.bottomLeft + Offset(0, dy),
    alignRight: right,
  );
}

/// 贴在组件上方（底边对齐组件顶边 - [dy]）。
UiPopoverAnchor genAbove(
  BuildContext context, {
  double dy = 6,
  bool right = false,
}) {
  final r = genRectOf(context);
  return UiPopoverAnchor(
    right ? r.topRight - Offset(0, dy) : r.topLeft - Offset(0, dy),
    alignBottom: true,
    alignRight: right,
  );
}

/// 生图页的界面宿主：菜单、弹层、弹窗、参数抽屉都挂在这里，[child] 里的部件通过 [GenScope] 拿到。
/// 画风探索页的编辑列也用它包 [GenEditorColumn]。
class GenHost extends StatefulWidget {
  const GenHost({
    super.key,
    required this.data,
    required this.actions,
    required this.slots,
    required this.child,
  });

  final GenViewData data;
  final GenActions actions;
  final GenSlots slots;
  final Widget child;

  @override
  State<GenHost> createState() => _GenHostState();
}

class _GenHostState extends State<GenHost> implements GenController {
  UiPopoverAnchor? _anchor;
  WidgetBuilder? _popover;
  Object? _tag;
  WidgetBuilder? _dialog;
  var _drawer = false;

  @override
  void openMenu(
    UiPopoverAnchor anchor,
    List<UiMenuItem> items, {
    Object? tag,
    double width = 210,
  }) => openPopover(
    anchor,
    (_) => UiMenu(items: items, onClose: closePopover, width: width),
    tag: tag,
  );

  @override
  void openPopover(
    UiPopoverAnchor anchor,
    WidgetBuilder builder, {
    Object? tag,
  }) => setState(() {
    _anchor = anchor;
    _popover = builder;
    _tag = tag;
  });

  @override
  void closePopover() {
    if (_anchor == null) return;
    setState(() {
      _anchor = null;
      _popover = null;
      _tag = null;
    });
  }

  @override
  Object? get popoverTag => _tag;

  @override
  void openDialog(WidgetBuilder builder) => setState(() => _dialog = builder);

  @override
  void closeDialog() => setState(() => _dialog = null);

  @override
  bool get drawerOpen => _drawer;

  @override
  void setDrawer(bool open) => setState(() => _drawer = open);

  @override
  void openFullscreen(GenEditorTarget target) =>
      openDialog((_) => GenFullscreenEditor(target: target));

  GenScope _scope(Widget child) => GenScope(
    data: widget.data,
    actions: widget.actions,
    slots: widget.slots,
    controller: this,
    child: child,
  );

  @override
  Widget build(BuildContext context) => _scope(
    UiModal(
      dialog: _dialog == null ? null : (ctx) => _scope(_dialog!(ctx)),
      onDismiss: closeDialog,
      child: UiPopover(
        anchor: _anchor,
        onDismiss: closePopover,
        builder: (ctx) => _popover == null
            ? const SizedBox.shrink()
            : _scope(Builder(builder: _popover!)),
        child: widget.child,
      ),
    ),
  );
}

/// 生图页：主导航右边的全部（左栏 │ 块库侧栏 │ 画布 │ 历史栏）。
/// 画布放不下 [minCanvas] 时先把历史栏临时收成竖条，再压左栏到最窄（都不回调，不改用户设置）。
class GenerationPage extends StatelessWidget {
  const GenerationPage({
    super.key,
    required this.data,
    required this.actions,
    required this.slots,
  });

  final GenViewData data;
  final GenActions actions;
  final GenSlots slots;

  static const minCanvas = 360.0;
  static const strip = 40.0;
  static const dockWidth = 300.0;

  @override
  Widget build(BuildContext context) => GenHost(
    data: data,
    actions: actions,
    slots: slots,
    child: ColoredBox(color: context.ui.bg, child: const _GenLayoutRow()),
  );
}

class _GenLayoutRow extends StatefulWidget {
  const _GenLayoutRow();

  @override
  State<_GenLayoutRow> createState() => _GenLayoutRowState();
}

class _GenLayoutRowState extends State<_GenLayoutRow> {
  double? _dragLeft;
  double? _dragHistory;

  void _commit(GenScope scope, GenLayout next) {
    setState(() {
      _dragLeft = null;
      _dragHistory = null;
    });
    if (next != scope.data.layout) scope.actions.onLayoutChanged(next);
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, box) => _row(context, box.maxWidth));

  Widget _row(BuildContext context, double w) {
    final scope = GenScope.of(context);
    final layout = scope.data.layout;
    final actions = scope.actions;
    final dock = layout.dockOpen && scope.slots.dock != null
        ? GenerationPage.dockWidth
        : 0.0;
    var left = layout.leftOpen
        ? (_dragLeft ?? layout.leftWidth).clamp(
            GenLayout.minLeft,
            GenLayout.maxLeft,
          )
        : GenerationPage.strip;
    var historyOpen = layout.historyOpen;
    var history = historyOpen
        ? (_dragHistory ?? layout.historyWidth).clamp(
            GenLayout.minHistory,
            GenLayout.maxHistory,
          )
        : GenerationPage.strip;
    // 画布放不下：先收历史栏，再压左栏。
    if (w - left - dock - history < GenerationPage.minCanvas && historyOpen) {
      historyOpen = false;
      history = GenerationPage.strip;
    }
    if (w - left - dock - history < GenerationPage.minCanvas &&
        layout.leftOpen) {
      left = math.max(
        GenLayout.minLeft,
        w - dock - history - GenerationPage.minCanvas,
      );
    }
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (layout.leftOpen)
              GenLeftPanel(width: left)
            else
              _Strip(
                key: const Key('gen-left-strip'),
                glyph: GenGlyphs.editNote,
                label: context.l10n.gen_params,
                expandGlyph: UiGlyphs.chevronRight,
                onExpand: () =>
                    actions.onLayoutChanged(layout.copyWith(leftOpen: true)),
                side: _StripSide.left,
              ),
            if (dock > 0)
              Container(
                key: const Key('gen-dock'),
                width: dock,
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: context.ui.line)),
                ),
                child: scope.slots.dock,
              ),
            const Expanded(child: GenCanvas()),
            if (historyOpen)
              GenHistoryPanel(width: history)
            else
              _Strip(
                key: const Key('gen-history-strip'),
                glyph: GenGlyphs.history,
                label: context.l10n.gen_history,
                count: scope.data.history.total,
                expandGlyph: UiGlyphs.chevronLeft,
                onExpand: () =>
                    actions.onLayoutChanged(layout.copyWith(historyOpen: true)),
                side: _StripSide.right,
              ),
          ],
        ),
        if (layout.leftOpen)
          Positioned(
            left: left - 4,
            top: 0,
            bottom: 0,
            width: 8,
            child: _ResizeHandle(
              key: const Key('gen-left-resize'),
              onDrag: (dx) => setState(
                () => _dragLeft = ((_dragLeft ?? left) + dx).clamp(
                  GenLayout.minLeft,
                  GenLayout.maxLeft,
                ),
              ),
              onEnd: () =>
                  _commit(scope, layout.copyWith(leftWidth: _dragLeft ?? left)),
            ),
          ),
        if (historyOpen)
          Positioned(
            right: history - 4,
            top: 0,
            bottom: 0,
            width: 8,
            child: _ResizeHandle(
              key: const Key('gen-history-resize'),
              onDrag: (dx) => setState(
                () => _dragHistory = ((_dragHistory ?? history) - dx).clamp(
                  GenLayout.minHistory,
                  GenLayout.maxHistory,
                ),
              ),
              onEnd: () => _commit(
                scope,
                layout.copyWith(historyWidth: _dragHistory ?? history),
              ),
            ),
          ),
      ],
    );
  }
}

/// 左栏：顶栏胶囊 + 模块滚动区（参数抽屉盖在上面）+ 参数条 + 生成条。
class GenLeftPanel extends StatelessWidget {
  const GenLeftPanel({super.key, required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('gen-left'),
      width: width,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: const GenEditorColumn(),
    );
  }
}

/// 编辑列本体（画风探索页也用：中间插“随机变量”，底部换成它自己的生成条）。
class GenEditorColumn extends StatelessWidget {
  const GenEditorColumn({
    super.key,
    this.afterPrompt,
    this.bottom,
    this.showCount = true,
    this.collapsible = true,
  });

  /// 插在提示词模块下面（画风探索的“随机变量”）。
  final Widget? afterPrompt;

  /// 代替生成条（画风探索的“抽 N 张候选”）。
  final Widget? bottom;

  /// 图像模块里显示张数 / 重复（画风探索把张数挪到了生成条）。
  final bool showCount;

  /// 顶栏显示收起按钮。
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context);
    final data = scope.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GenHeader(collapsible: collapsible),
        Expanded(
          child: GenParamDrawerHost(
            child: ClipRect(
              child: SingleChildScrollView(
                key: const Key('gen-left-scroll'),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    const GenPromptModule(),
                    ?afterPrompt,
                    if (data.characters != null) const GenCharacterModule(),
                    const GenRefsModule(),
                    GenImageModule(showCount: showCount),
                  ],
                ),
              ),
            ),
          ),
        ),
        const GenParamStrip(),
        bottom ?? const GenGenerateBar(),
      ],
    );
  }
}

enum _StripSide { left, right }

/// 收起后的竖条：40 宽；展开钮 + 图标 + 竖排标题（+ 数量）。整条可点。
class _Strip extends StatelessWidget {
  const _Strip({
    super.key,
    required this.glyph,
    required this.label,
    required this.expandGlyph,
    required this.onExpand,
    required this.side,
    this.count,
  });

  final String glyph;
  final String label;
  final String expandGlyph;
  final VoidCallback onExpand;
  final _StripSide side;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final top = side == _StripSide.right && WindowChromeScope.activeOf(context)
        ? WindowChromeScope.heightOf(context)
        : 0.0;
    return Container(
      width: GenerationPage.strip,
      decoration: BoxDecoration(
        color: c.bg,
        border: side == _StripSide.left
            ? Border(right: BorderSide(color: c.line))
            : Border(left: BorderSide(color: c.line)),
      ),
      padding: EdgeInsets.only(top: top + 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onExpand,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            spacing: 10,
            children: [
              GenIb(
                glyph: expandGlyph,
                glyphSize: 14,
                onTap: onExpand,
                tooltip: context.l10n.gen_expand,
              ),
              UiGlyph(glyph, size: 16, color: c.muted),
              RotatedBox(
                quarterTurns: 1,
                child: Text(
                  label,
                  style: UiText.sans(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.muted,
                  ),
                ),
              ),
              if (count != null && count! > 0) GenCount('$count'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 栏边拖动条：8 宽，悬停 / 拖动时显示 2px 强调色线。
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({super.key, required this.onDrag, required this.onEnd});
  final ValueChanged<double> onDrag;
  final VoidCallback onEnd;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  var _hover = false;
  var _drag = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _drag = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _drag = false);
          widget.onEnd();
        },
        child: Center(
          child: Container(
            width: 2,
            color: _hover || _drag
                ? c.accent.withValues(alpha: .6)
                : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

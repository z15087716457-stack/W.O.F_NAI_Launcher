import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../gen/gen_parts.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_editor_options.dart';
import 'tools_editor_side.dart';
import 'tools_format.dart';
import 'tools_parts.dart';

/// 编辑器页面级的弹层 / 弹窗 / 右栏抽屉，各部件通过 [ToolsEditorScope] 拿到。
abstract class ToolsEditorController {
  void openPopover(
    UiPopoverAnchor anchor,
    WidgetBuilder builder, {
    Object? tag,
  });
  void closePopover();
  Object? get popoverTag;
  void openDialog(WidgetBuilder builder);
  void closeDialog();

  /// 窄窗时右栏是盖在画布上的抽屉。
  bool get sideOpen;
  void setSide(bool open);
}

class ToolsEditorScope extends InheritedWidget {
  const ToolsEditorScope({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
    required this.narrow,
    required super.child,
  });

  final ToolsEditorData data;
  final ToolsEditorActions actions;
  final ToolsEditorController controller;

  /// 放不下右栏（< [ToolsEditorPage.narrowWidth]）。
  final bool narrow;

  static ToolsEditorScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolsEditorScope>()!;

  @override
  bool updateShouldNotify(ToolsEditorScope old) => true;
}

/// 画布编辑器（编辑图像 / 局部重绘）：顶栏（返回、标题 + 结果去向、缩放、撤销重做下载、取消 + 主按钮）│
/// 工具选项条 │ 左工具栏 │ 画布 │ 右栏（图层、调色、画布尺寸 / 重绘设置）│ 状态栏。
/// 放在主导航右边；窄于 [narrowWidth] 时右栏收成抽屉（顶栏多一个开关）。
class ToolsEditorPage extends StatefulWidget {
  const ToolsEditorPage({
    super.key,
    required this.data,
    required this.actions,
    this.slots = const ToolsEditorSlots(),
  });

  final ToolsEditorData data;
  final ToolsEditorActions actions;
  final ToolsEditorSlots slots;

  static const topHeight = 61.0;
  static const optionsHeight = 44.0;
  static const statusHeight = 28.0;
  static const railWidth = 56.0;
  static const sideWidth = 280.0;
  static const narrowWidth = 1000.0;

  @override
  State<ToolsEditorPage> createState() => _ToolsEditorPageState();
}

class _ToolsEditorPageState extends State<ToolsEditorPage>
    implements ToolsEditorController {
  UiPopoverAnchor? _anchor;
  WidgetBuilder? _popover;
  Object? _tag;
  WidgetBuilder? _dialog;
  var _side = false;
  final _focus = FocusNode(debugLabel: 'tools-editor');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

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
  bool get sideOpen => _side;

  @override
  void setSide(bool open) => setState(() => _side = open);

  /// 返回 / 取消：有修改先确认。
  void _leave(ToolsEditorScope scope) {
    if (!scope.data.dirty) {
      scope.actions.onBack();
      return;
    }
    final l = context.l10n;
    openDialog(
      (_) => GenConfirmDialog(
        key: const Key('tools-discard'),
        title: l.tools_discardTitle,
        body: l.tools_discardBody,
        confirm: l.tools_discard,
        cancel: l.tools_keepEditing,
        onCancel: closeDialog,
        onConfirm: () {
          closeDialog();
          scope.actions.onBack();
        },
      ),
    );
  }

  KeyEventResult _key(ToolsEditorScope scope, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final d = scope.data;
    final a = scope.actions;
    final k = e.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (k == LogicalKeyboardKey.escape) {
      if (d.expanding) {
        a.onExpanding(false);
      } else if (d.inpainting &&
          d.tool == ToolsTool.focus &&
          d.inpaint.hasFocus) {
        a.onClearFocus();
      } else {
        _leave(scope);
      }
      return KeyEventResult.handled;
    }
    if (ctrl && k == LogicalKeyboardKey.enter) {
      a.onApply();
      return KeyEventResult.handled;
    }
    if (!d.shellShortcuts || ctrl) return KeyEventResult.ignored;
    final label = k.keyLabel.toUpperCase();
    final tools = d.inpainting
        ? ToolsEditorData.inpaintTools
        : ToolsEditorData.editTools;
    for (final t in tools) {
      if (d.shortcuts[t] == label) {
        if (t != d.tool) a.onTool(t);
        return KeyEventResult.handled;
      }
    }
    final o = d.options;
    if (o.size != null &&
        (k == LogicalKeyboardKey.bracketLeft ||
            k == LogicalKeyboardKey.bracketRight)) {
      final step = o.size! < 10 ? 1.0 : (o.size! < 50 ? 2.0 : 5.0);
      final next =
          (o.size! + (k == LogicalKeyboardKey.bracketLeft ? -step : step))
              .clamp(o.minSize, o.maxSize);
      a.onOptions(o.copyWith(size: next));
      return KeyEventResult.handled;
    }
    if (!d.inpainting && k == LogicalKeyboardKey.keyX) {
      a.onSwapColors();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < ToolsEditorPage.narrowWidth;
        Widget scoped(Widget child) => ToolsEditorScope(
          data: widget.data,
          actions: widget.actions,
          controller: this,
          narrow: narrow,
          child: child,
        );
        return scoped(
          Builder(
            builder: (context) {
              final scope = ToolsEditorScope.of(context);
              return UiModal(
                dialog: _dialog == null ? null : (ctx) => scoped(_dialog!(ctx)),
                onDismiss: closeDialog,
                child: UiPopover(
                  anchor: _anchor,
                  onDismiss: closePopover,
                  builder: (ctx) => _popover == null
                      ? const SizedBox.shrink()
                      : scoped(Builder(builder: _popover!)),
                  child: Focus(
                    focusNode: _focus,
                    autofocus: true,
                    onKeyEvent: (_, e) => _key(scope, e),
                    child: ColoredBox(
                      key: const Key('tools-editor'),
                      color: c.bg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBar(onLeave: () => _leave(scope)),
                          const ToolsOptionsBar(),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _Rail(),
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      _Work(slots: widget.slots),
                                      if (narrow && _side)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          bottom: 0,
                                          width: ToolsEditorPage.sideWidth,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: .18),
                                                  blurRadius: 24,
                                                ),
                                              ],
                                            ),
                                            child: const ToolsEditorSide(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!narrow) const ToolsEditorSide(),
                              ],
                            ),
                          ),
                          const _Status(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 顶栏（原型 `.ed-top`）：61 高（和各页顶栏同高）、底分隔线，右边让出窗口按钮。
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLeave});
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final chrome = WindowChromeScope.activeOf(context);
    return WindowHeader(
      key: const Key('tools-editor-top'),
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Container(
        height: ToolsEditorPage.topHeight - 1,
        padding: EdgeInsets.only(left: 10, right: chrome ? 0 : 12),
        child: Row(
          spacing: 8,
          children: [
            ToolsIb(
              key: const Key('tools-editor-back'),
              glyph: ToolsGlyphs.back,
              glyphSize: 18,
              tooltip: l.tools_backEsc,
              onTap: onLeave,
            ),
            Expanded(
              child: Column(
                key: const Key('tools-editor-title'),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.inpainting ? l.tools_inpaint : l.tools_edit,
                    maxLines: 1,
                    style: UiText.sans(
                      14.5,
                      weight: FontWeight.w600,
                      color: c.ink,
                      height: 1.25,
                    ),
                  ),
                  Text(
                    '${d.inpainting ? l.tools_inpaintSub : l.tools_editSub} · '
                    '${ToolsFormat.size(d.width, d.height)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(11, color: c.faint, height: 1.25),
                  ),
                ],
              ),
            ),
            if (scope.narrow)
              ToolsIb(
                key: const Key('tools-editor-side-toggle'),
                glyph: ToolsGlyphs.panel,
                on: scope.controller.sideOpen,
                tooltip: l.tools_panel,
                onTap: () =>
                    scope.controller.setSide(!scope.controller.sideOpen),
              ),
            const _Zoom(),
            const ToolsVDiv(),
            ToolsIb(
              key: const Key('tools-editor-undo'),
              glyph: ToolsGlyphs.undo,
              tooltip: l.tools_undo,
              onTap: d.canUndo ? a.onUndo : null,
            ),
            ToolsIb(
              key: const Key('tools-editor-redo'),
              glyph: ToolsGlyphs.redo,
              tooltip: l.tools_redo,
              onTap: d.canRedo ? a.onRedo : null,
            ),
            ToolsIb(
              key: const Key('tools-editor-download'),
              glyph: ToolsGlyphs.download,
              tooltip: l.tools_download,
              onTap: a.onDownload,
            ),
            const ToolsVDiv(),
            ToolsButton(
              key: const Key('tools-editor-cancel'),
              tone: ToolsButtonTone.ghost,
              onTap: onLeave,
              children: [Text(l.tools_cancel)],
            ),
            if (d.inpainting)
              const _ApplySplit()
            else
              ToolsButton(
                key: const Key('tools-editor-apply'),
                tone: ToolsButtonTone.primary,
                onTap: a.onApply,
                children: [Text(l.tools_useAsInit)],
              ),
          ],
        ),
      ),
    );
  }
}

/// 缩放组（控件底、圆角 8、内边距 2）：− 比例 + │ 适应。
class _Zoom extends StatelessWidget {
  const _Zoom();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final a = scope.actions;
    final l = context.l10n;
    return Container(
      key: const Key('tools-editor-zoom'),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          ToolsIb(
            key: const Key('tools-zoom-out'),
            glyph: UiGlyphs.minus,
            size: 28,
            glyphSize: 14,
            tooltip: l.tools_zoomOut,
            onTap: a.onZoomOut,
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${(scope.data.zoom * 100).round()}%',
              key: const Key('tools-zoom-value'),
              textAlign: TextAlign.center,
              style: UiText.mono(12, color: c.ink),
            ),
          ),
          ToolsIb(
            key: const Key('tools-zoom-in'),
            glyph: UiGlyphs.plus,
            size: 28,
            glyphSize: 14,
            tooltip: l.tools_zoomIn,
            onTap: a.onZoomIn,
          ),
          const ToolsVDiv(height: 16, margin: 2),
          ToolsIb(
            key: const Key('tools-zoom-fit'),
            glyph: ToolsGlyphs.fit,
            size: 28,
            glyphSize: 14,
            tooltip: l.tools_zoomFit,
            onTap: a.onZoomFit,
          ),
        ],
      ),
    );
  }
}

/// 局部重绘的主按钮：“应用蒙版”+ 下拉（应用蒙版 / 应用并生成 · 价格）。
class _ApplySplit extends StatelessWidget {
  const _ApplySplit();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final open = scope.controller.popoverTag == #apply;
    return Row(
      key: const Key('tools-editor-apply'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolsButton(
          key: const Key('tools-editor-apply-main'),
          tone: ToolsButtonTone.primary,
          radius: const BorderRadius.horizontal(left: Radius.circular(8)),
          onTap: a.onApply,
          children: [Text(l.tools_applyMask)],
        ),
        // 两段之间一道 30% 白线（原型 border-left）。
        Container(
          width: 1,
          height: 32,
          color: Color.alphaBlend(Colors.white.withValues(alpha: .3), c.brand),
        ),
        Builder(
          builder: (ctx) => ToolsButton(
            key: const Key('tools-editor-apply-menu'),
            tone: ToolsButtonTone.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            radius: const BorderRadius.horizontal(right: Radius.circular(8)),
            onTap: () {
              if (open) {
                scope.controller.closePopover();
                return;
              }
              final box = ctx.findRenderObject()! as RenderBox;
              scope.controller.openPopover(
                UiPopoverAnchor(
                  box.localToGlobal(
                    Offset(box.size.width, box.size.height + 6),
                  ),
                  alignRight: true,
                ),
                (_) =>
                    _ApplyMenu(cost: d.applyCost, insufficient: d.insufficient),
                tag: #apply,
              );
            },
            children: [
              UiGlyph(UiGlyphs.chevronDown, size: 14, color: c.onBrand),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApplyMenu extends StatelessWidget {
  const _ApplyMenu({required this.cost, required this.insufficient});
  final int? cost;
  final bool insufficient;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final a = scope.actions;
    final l = context.l10n;
    Widget row({
      required Key key,
      required String glyph,
      required String title,
      required String sub,
      required Widget trailing,
      required VoidCallback onTap,
    }) => UiPressable(
      key: key,
      onTap: () {
        scope.controller.closePopover();
        onTap();
      },
      builder: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: hover ? c.control : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          spacing: 10,
          children: [
            UiGlyph(glyph, size: 15, color: c.ink),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  Text(sub, style: UiText.sans(11, color: c.muted)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
    return UiPopoverSurface(
      key: const Key('tools-apply-menu'),
      width: 260,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            key: const Key('tools-apply-only'),
            glyph: UiGlyphs.check,
            title: l.tools_applyMask,
            sub: l.tools_applyMaskSub,
            trailing: const UiKeycaps(['Ctrl', '↵']),
            onTap: a.onApply,
          ),
          row(
            key: const Key('tools-apply-generate'),
            glyph: ToolsGlyphs.sparkle,
            title: l.tools_applyGenerate,
            sub: l.tools_applyGenerateSub,
            trailing: ToolsPrice(
              cost: cost,
              size: 12,
              color: insufficient ? c.error : c.ink,
            ),
            onTap: a.onApplyAndGenerate,
          ),
        ],
      ),
    );
  }
}

/// 左工具栏（原型 `.ed-rail`）：56 宽；工具 40 方、圆角 9、图标 19，右下角快捷键字母。
class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    Widget tool(ToolsTool t) => _RailTool(
      key: Key('tools-tool-${t.name}'),
      icon: _toolIcon(t),
      label: ToolsFormat.toolLabel(l, t, inpaint: d.inpainting),
      shortcut: d.shortcuts[t],
      on: d.tool == t && !d.expanding,
      onTap: () {
        if (d.expanding) a.onExpanding(false);
        if (d.tool != t) a.onTool(t);
      },
    );
    Widget sep() => Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: c.line,
    );
    return Container(
      key: const Key('tools-editor-rail'),
      width: ToolsEditorPage.railWidth,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        child: Column(
          spacing: 2,
          children: d.inpainting
              ? [
                  for (final t in ToolsEditorData.inpaintTools) tool(t),
                  sep(),
                  _RailTool(
                    key: const Key('tools-tool-clear'),
                    icon: 'inpaint_clear',
                    label: l.tools_clearMask,
                    onTap: a.onClearMask,
                  ),
                  _RailTool(
                    key: const Key('tools-tool-expand'),
                    icon: 'inpaint_shift',
                    label: l.tools_expand,
                    on: d.expanding,
                    onTap: () => a.onExpanding(!d.expanding),
                  ),
                ]
              : [
                  for (final t in ToolsEditorData.editTools.take(5)) tool(t),
                  sep(),
                  for (final t in ToolsEditorData.editTools.skip(5)) tool(t),
                  sep(),
                  _RailTool(
                    key: const Key('tools-tool-adjust'),
                    glyph: ToolsGlyphs.sun,
                    label: l.tools_adjust,
                    onTap: () {
                      if (scope.narrow) scope.controller.setSide(true);
                    },
                  ),
                  _RailTool(
                    key: const Key('tools-tool-resize'),
                    glyph: ToolsGlyphs.crop,
                    label: l.tools_resize,
                    onTap: a.onResizeCanvas,
                  ),
                ],
        ),
      ),
    );
  }

  static String _toolIcon(ToolsTool t) => switch (t) {
    ToolsTool.brush => 'inpaint_brush',
    ToolsTool.eraser => 'inpaint_eraser',
    ToolsTool.fill => 'inpaint_fill',
    ToolsTool.focus => 'inpaint_inpaint_focus',
    ToolsTool.blur => 'g:${ToolsGlyphs.blur}',
    ToolsTool.stamp => 'g:${ToolsGlyphs.stamp}',
    ToolsTool.select => 'g:${ToolsGlyphs.rect}',
    ToolsTool.lasso => 'g:${ToolsGlyphs.lasso}',
    ToolsTool.picker => 'g:${ToolsGlyphs.drop}',
  };
}

class _RailTool extends StatelessWidget {
  const _RailTool({
    super.key,
    this.icon,
    this.glyph,
    required this.label,
    this.shortcut,
    this.on = false,
    required this.onTap,
  });

  /// svg 图标名；以 `g:` 开头时后面是路径。
  final String? icon;
  final String? glyph;
  final String label;
  final String? shortcut;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final path = glyph ?? (icon!.startsWith('g:') ? icon!.substring(2) : null);
    return Tooltip(
      message: shortcut == null ? label : '$label  $shortcut',
      waitDuration: const Duration(milliseconds: 400),
      child: UiPressable(
        onTap: onTap,
        builder: (context, hover) {
          final ink = on
              ? c.accent
              : (hover ? c.ink : c.ink.withValues(alpha: .78));
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: on
                  ? c.accent.withValues(alpha: .13)
                  : (hover ? c.control : null),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (path != null)
                  UiGlyph(path, size: 19, color: ink)
                else
                  ToolsIcon(icon!, size: 19, color: ink),
                if (shortcut != null)
                  Positioned(
                    right: 2,
                    bottom: 1,
                    child: Text(
                      shortcut!,
                      style: UiText.mono(
                        9,
                        weight: FontWeight.w600,
                        color: on ? c.accent : c.faint,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 画布区（原型 `.work`）：浅色 #ececec / 深色 #0b0b0b；接了画布引擎就画引擎，否则居中摆底图。
class _Work extends StatelessWidget {
  const _Work({required this.slots});
  final ToolsEditorSlots slots;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    return ClipRect(
      key: const Key('tools-editor-work'),
      child: ColoredBox(
        color: toolsWorkColor(c),
        child:
            slots.canvas?.call(context) ??
            Center(
              child: Container(
                key: const Key('tools-editor-image'),
                width: d.width * d.zoom,
                height: d.height * d.zoom,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .25),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: d.image == null
                    ? ColoredBox(color: c.raised)
                    : Image(image: d.image!, fit: BoxFit.fill),
              ),
            ),
      ),
    );
  }
}

/// 编辑器画布区的底色。
Color toolsWorkColor(UiColors c) =>
    c.dark ? const Color(0xFF0B0B0B) : const Color(0xFFECECEC);

/// 状态栏（原型 `.ed-stat`）：28 高、上分隔线、11.5 弱色；坐标 │ 操作提示 │ 右侧当前图层 / 网格说明。
class _Status extends StatelessWidget {
  const _Status();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final style = UiText.sans(11.5, color: c.faint);
    final right = d.inpainting
        ? (d.options.square ?? false ? l.tools_statusGrid : l.tools_statusMask)
        : (d.activeLayer?.name ?? '');
    return Container(
      key: const Key('tools-editor-status'),
      height: ToolsEditorPage.statusHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 16,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              d.cursor == null
                  ? '—'
                  : 'x ${d.cursor!.dx.round()} · y ${d.cursor!.dy.round()}',
              key: const Key('tools-editor-cursor'),
              maxLines: 1,
              style: UiText.mono(11.5, color: c.faint),
            ),
          ),
          Expanded(
            child: Text(
              l.tools_statusHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Text(right, maxLines: 1, style: style),
        ],
      ),
    );
  }
}

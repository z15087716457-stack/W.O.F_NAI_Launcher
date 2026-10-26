import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'agent_composer.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_header.dart';
import 'agent_history.dart';
import 'agent_thread_navigation.dart';
import 'agent_pages.dart';
import 'agent_parts.dart';
import 'agent_scope.dart';
import 'agent_thread.dart';

/// NAI Agent 侧栏（方案 B · 任务指挥台）。只认 [AgentViewData] + [AgentActions]；
/// 宽度、拖拽、展开动画由宿主负责。
class AgentPanel extends StatefulWidget {
  const AgentPanel({
    super.key,
    required this.data,
    required this.actions,
    this.slots = const AgentSlots(),
    this.initialTab = AgentTab.chat,
  });

  final AgentViewData data;
  final AgentActions actions;
  final AgentSlots slots;
  final AgentTab initialTab;

  @override
  State<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends State<AgentPanel> {
  late var _tab = widget.initialTab;
  final _composer = GlobalKey<AgentComposerState>();
  WidgetBuilder? _dialog;

  /// 确认 / 改名弹窗只盖侧栏；看大图仍盖整个窗口。
  var _dialogContained = true;
  String? _toast;
  Timer? _toastTimer;
  (String, Future<bool> Function())? _undo;
  Timer? _undoTimer;
  var _dropping = false;
  final _historyAnchor = GlobalKey();
  final _navigation = AgentThreadNavigation();
  OverlayEntry? _history;

  void _closeHistory() {
    _history?.remove();
    _history?.dispose();
    _history = null;
    if (mounted) setState(() {});
  }

  Future<void> _jumpHistory(AgentHistoryEntry entry) async {
    if (_tab != AgentTab.chat) {
      setState(() => _tab = AgentTab.chat);
      await WidgetsBinding.instance.endOfFrame;
    }
    await _navigation.jump?.call(entry);
    if (mounted && entry.beforeCompaction) {
      _showToast(context.l10n.ag_historyBeforeCompaction);
    }
  }

  void _toggleHistory() {
    if (_history != null) {
      _closeHistory();
      return;
    }
    final overlay = Overlay.of(context, rootOverlay: true);
    _history = OverlayEntry(
      builder: (context) {
        final box =
            _historyAnchor.currentContext!.findRenderObject()! as RenderBox;
        final root = overlay.context.findRenderObject()! as RenderBox;
        final origin = box.localToGlobal(Offset.zero, ancestor: root);
        final width = root.size.width < 348 ? root.size.width : 348.0;
        final left = origin.dx >= width
            ? origin.dx - width
            : root.size.width - origin.dx - box.size.width >= width
            ? origin.dx + box.size.width
            : origin.dx.clamp(0.0, root.size.width - width);
        return Positioned(
          left: left,
          top: origin.dy,
          width: width,
          height: box.size.height,
          child: AgentHistory(
            entries: widget.data.history,
            navigation: _navigation,
            onClose: _closeHistory,
            onJump: (entry) => unawaited(_jumpHistory(entry)),
          ),
        );
      },
    );
    overlay.insert(_history!);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant AgentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.chat.id != widget.data.chat.id) {
      _closeHistory();
      _navigation.turns.clear();
      _navigation.users.clear();
      _navigation.blocks.clear();
    } else {
      _history?.markNeedsBuild();
    }
    final blocks = {
      for (final t in widget.data.thread)
        for (final (i, _) in (t.reply?.blocks ?? <AgentBlock>[]).indexed)
          (t.id, i),
    };
    _navigation.blocks.removeWhere((key, _) => !blocks.contains(key));
    final turns = widget.data.thread.map((t) => t.id).toSet();
    _navigation.turns.removeWhere((key, _) => !turns.contains(key));
    _navigation.users.removeWhere((key, _) => !turns.contains(key));
    if (_tab == AgentTab.memory && widget.data.memory == null) {
      _tab = AgentTab.chat;
    }
    // 新聊天 / 切聊天：回到对话页。
    if (oldWidget.data.chat.id != widget.data.chat.id) _tab = AgentTab.chat;
  }

  @override
  void dispose() {
    _history?.remove();
    _history?.dispose();
    _navigation.dispose();
    _toastTimer?.cancel();
    _undoTimer?.cancel();
    _dismissConfirm?.call(rebuild: false);
    super.dispose();
  }

  void _showToast(String text) {
    if (!mounted) return;
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _showUndo(String text, Future<bool> Function() onUndo) {
    if (!mounted) return;
    _undoTimer?.cancel();
    setState(() => _undo = (text, onUndo));
    _undoTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _undo = null);
    });
  }

  Future<void> _takeUndo() async {
    final undo = _undo;
    if (undo == null) return;
    _undoTimer?.cancel();
    setState(() => _undo = null);
    await _run(undo.$2);
  }

  Future<(bool,)?> _confirm({
    required String title,
    required String message,
    required String confirm,
    bool danger = false,
    String? optOut,
  }) {
    final done = Completer<(bool,)?>();
    void finish((bool,)? v, {bool rebuild = true}) {
      _dismissConfirm = null;
      if (!done.isCompleted) done.complete(v);
      if (mounted && rebuild) setState(() => _dialog = null);
    }

    _openDialog(
      (_) => _ConfirmDialog(
        title: title,
        message: message,
        confirm: confirm,
        danger: danger,
        optOut: optOut,
        onDone: finish,
      ),
    );
    _dismissConfirm = ({bool rebuild = true}) => finish(null, rebuild: rebuild);
    return done.future;
  }

  void Function({bool rebuild})? _dismissConfirm;

  void _openDialog(WidgetBuilder builder, {bool contained = true}) {
    _dismissConfirm?.call(rebuild: false);
    setState(() {
      _dialogContained = contained;
      _dialog = builder;
    });
  }

  Future<void> _run(Future<bool> Function() action) async {
    var ok = false;
    try {
      ok = await action();
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) _showToast(context.l10n.ag_failed);
  }

  void _rename({
    required String title,
    required String value,
    required Future<bool> Function(String value) save,
  }) {
    _openDialog(
      (_) => _NameDialog(
        title: title,
        value: value,
        onCancel: () => setState(() => _dialog = null),
        onSave: (v) async {
          setState(() => _dialog = null);
          await _run(() => save(v));
        },
      ),
    );
  }

  void _zoom(AgentImage image, {List<AgentImage>? group}) {
    _openDialog(
      (_) => _Zoom(
        image: image,
        group: group,
        onClose: () => setState(() => _dialog = null),
      ),
      contained: false,
    );
  }

  void _insert(String text, {bool replace = false}) {
    if (_tab == AgentTab.chat) {
      _composer.currentState?.insert(text, replace: replace);
      return;
    }
    setState(() => _tab = AgentTab.chat);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _composer.currentState?.insert(text, replace: replace),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final c = context.ui;
    Widget body;
    if (d.initError != null) {
      body = _InitError(
        message: d.initError!,
        onRetry: widget.actions.onRetryInit,
      );
    } else if (d.loading) {
      body = const Center(child: AgentStepDot(kind: AgentDotKind.running));
    } else {
      body = Column(
        children: [
          AgentHeader(
            tab: _tab,
            onTab: (t) => setState(() => _tab = t),
            historyOpen: _history != null,
            onHistory: _toggleHistory,
            onClose: () {
              _closeHistory();
              widget.actions.onClose();
            },
          ),
          if (d.status == AgentRunStatus.starting ||
              d.status == AgentRunStatus.working ||
              d.status == AgentRunStatus.waitingSlot)
            LinearProgressIndicator(
              key: const Key('agent-progress'),
              minHeight: 2,
              backgroundColor: Colors.transparent,
              color: d.status == AgentRunStatus.waitingSlot ? c.warn : c.accent,
            )
          else
            const SizedBox(height: 2),
          Expanded(
            child: switch (_tab) {
              AgentTab.chat =>
                d.thread.isEmpty &&
                        d.composer.pending.isEmpty &&
                        d.error == null
                    ? const AgentWelcome()
                    : const AgentThread(),
              AgentTab.shelf => const AgentShelf(),
              AgentTab.memory =>
                d.memory == null
                    ? const SizedBox.shrink()
                    : const AgentMemory(),
            },
          ),
          AgentComposer(key: _composer, chatId: d.chat.id),
        ],
      );
    }
    Widget panel = AgentNavigationScope(
      navigation: _navigation,
      child: AgentScope(
        data: d,
        actions: widget.actions,
        slots: widget.slots,
        run: _run,
        rename: _rename,
        zoom: _zoom,
        insert: _insert,
        toast: _showToast,
        confirm: _confirm,
        undoToast: _showUndo,
        child: UiModal(
          dialog: _dialog,
          contained: _dialogContained,
          onDismiss: () {
            final dismiss = _dismissConfirm;
            _dismissConfirm = null;
            if (dismiss != null) {
              dismiss();
            } else {
              setState(() => _dialog = null);
            }
          },
          child: Stack(
            children: [
              Positioned.fill(child: body),
              if (_dropping) const Positioned.fill(child: _DropOverlay()),
              if (_toast != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 132,
                  child: IgnorePointer(child: Center(child: _Toast(_toast!))),
                ),
              if (_undo != null && _toast == null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 132,
                  child: Center(
                    child: _UndoToast(text: _undo!.$1, onUndo: _takeUndo),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final drop = widget.slots.dropTarget;
    if (drop != null && d.initError == null) {
      panel = drop(context, (v) {
        if (v != _dropping && mounted) setState(() => _dropping = v);
      }, panel);
    }
    return ColoredBox(
      key: const Key('agent-panel'),
      color: c.page,
      child: DefaultTextStyle.merge(
        style: UiText.sans(13, color: c.ink),
        child: SizedBox(key: _historyAnchor, child: panel),
      ),
    );
  }
}

class _InitError extends StatelessWidget {
  const _InitError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Center(
      key: const Key('agent-init-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.ink,
                borderRadius: BorderRadius.circular(10),
              ),
              child: AgentMark(size: 22, color: c.bg, stroke: 1.8),
            ),
            Text(
              l.ag_initFailed,
              style: UiText.sans(14, weight: FontWeight.w600, color: c.ink),
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: UiText.sans(12, color: c.muted, height: 1.5),
            ),
            const SizedBox(height: 4),
            AgentButton(
              key: const Key('agent-retry'),
              label: l.ag_retry,
              glyph: AgentGlyphs.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return IgnorePointer(
      child: Container(
        key: const Key('agent-drop'),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.accent.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            AgentIcon(AgentGlyphs.image, size: 22, color: c.accent),
            Text(
              context.l10n.ag_dropHint,
              style: UiText.sans(13, weight: FontWeight.w500, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('agent-toast'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: UiText.sans(12, color: c.tipInk, height: 1.3)),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.value,
    required this.onCancel,
    required this.onSave,
  });
  final String title, value;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _text = TextEditingController(text: widget.value)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.value.length,
    );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final v = _text.text.trim();
    if (v.isNotEmpty) widget.onSave(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final multi = widget.value.contains('\n') || widget.value.length > 60;
    return Container(
      key: const Key('agent-name-dialog'),
      constraints: const BoxConstraints(maxWidth: 380),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiDialogHeader(children: [Expanded(child: Text(widget.title))]),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.accent),
                ),
                child: TextField(
                  key: const Key('agent-name-input'),
                  controller: _text,
                  autofocus: true,
                  minLines: multi ? 3 : 1,
                  maxLines: multi ? 8 : 1,
                  onSubmitted: multi ? null : (_) => _save(),
                  style: UiText.sans(13, color: c.ink, height: 1.5),
                  cursorColor: c.accent,
                  decoration: agentBareInput(
                    hint: l.ag_name,
                    hintStyle: UiText.sans(13, color: c.faint),
                  ),
                ),
              ),
            ),
            UiDialogFooter(
              children: [
                const Spacer(),
                AgentButton(label: l.ag_cancel, onPressed: widget.onCancel),
                ListenableBuilder(
                  listenable: _text,
                  builder: (_, _) => AgentButton(
                    key: const Key('agent-name-save'),
                    label: l.ag_save,
                    style: AgentButtonStyle.primary,
                    onPressed: _text.text.trim().isEmpty ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Zoom extends StatefulWidget {
  const _Zoom({required this.image, required this.onClose, this.group});
  final AgentImage image;
  final VoidCallback onClose;

  /// 同一组的图（查看图片合并组、产物）：左右键 / 两侧箭头切换。
  final List<AgentImage>? group;

  @override
  State<_Zoom> createState() => _ZoomState();
}

class _ZoomState extends State<_Zoom> {
  late final _images = widget.group == null || widget.group!.length < 2
      ? [widget.image]
      : widget.group!;
  late var _index = _images
      .indexWhere((i) => i.id == widget.image.id)
      .clamp(0, _images.length - 1);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _go(int delta) {
    if (_images.length < 2) return;
    setState(() => _index = (_index + delta) % _images.length);
  }

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final l = context.l10n;
    final image = _images[_index];
    final many = _images.length > 1;
    Widget arrow(int delta) => Material(
      key: Key(delta < 0 ? 'agent-zoom-prev' : 'agent-zoom-next'),
      color: const Color(0x99000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _go(delta),
        child: SizedBox.square(
          dimension: 36,
          child: Center(
            child: Transform.rotate(
              angle: delta < 0 ? 3.14159 : 0,
              child: const AgentIcon(
                AgentGlyphs.chevronRight,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(-1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onClose,
        // 占满弹层：图还没加载、或图很小时，两侧箭头和右上按钮也在可点范围里。
        child: Stack(
          key: const Key('agent-zoom'),
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              key: ValueKey(image.id),
              maxScale: 6,
              child: Image(image: image.image, fit: BoxFit.contain),
            ),
            if (many) ...[
              Positioned(left: 8, child: arrow(-1)),
              Positioned(right: 8, child: arrow(1)),
              Positioned(
                bottom: 8,
                child: Container(
                  key: const Key('agent-zoom-index'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_index + 1} / ${_images.length}',
                    style: UiText.mono(11, color: Colors.white, height: 1.2),
                  ),
                ),
              ),
            ],
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                spacing: 6,
                children: [
                  if (image.historyId != null)
                    AgentButton(
                      label: l.ag_imageReveal,
                      glyph: AgentGlyphs.clock,
                      onPressed: () {
                        widget.onClose();
                        s.actions.onRevealImage(image.id);
                      },
                    ),
                  AgentButton(
                    label: l.ag_imageAttach,
                    glyph: AgentGlyphs.clip,
                    onPressed: () {
                      widget.onClose();
                      s.run(() => s.actions.onAttachImage(image.id));
                    },
                  ),
                  AgentButton(
                    key: const Key('agent-zoom-close'),
                    label: l.ag_zoomClose,
                    glyph: AgentGlyphs.close,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirm,
    required this.danger,
    required this.optOut,
    required this.onDone,
  });
  final String title, message, confirm;
  final bool danger;
  final String? optOut;
  final ValueChanged<(bool,)?> onDone;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  var _silence = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('agent-confirm-dialog'),
      constraints: const BoxConstraints(maxWidth: 380),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiDialogHeader(
              children: [
                if (widget.danger)
                  AgentIcon(AgentGlyphs.alert, size: 16, color: c.error),
                Expanded(child: Text(widget.title)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  Text(
                    widget.message,
                    style: UiText.sans(12.5, color: c.muted, height: 1.6),
                  ),
                  if (widget.optOut != null)
                    GestureDetector(
                      key: const Key('agent-confirm-optout'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _silence = !_silence),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Row(
                          spacing: 8,
                          children: [
                            UiCheckBox(value: _silence),
                            Text(
                              widget.optOut!,
                              style: UiText.sans(12, color: c.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            UiDialogFooter(
              children: [
                const Spacer(),
                AgentButton(
                  key: const Key('agent-confirm-cancel'),
                  label: l.ag_cancel,
                  onPressed: () => widget.onDone(null),
                ),
                AgentButton(
                  key: const Key('agent-confirm-ok'),
                  label: widget.confirm,
                  style: widget.danger
                      ? AgentButtonStyle.danger
                      : AgentButtonStyle.primary,
                  onPressed: () => widget.onDone((_silence,)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoToast extends StatelessWidget {
  const _UndoToast({required this.text, required this.onUndo});
  final String text;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('agent-undo-toast'),
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.tipInk, height: 1.3),
            ),
          ),
          TextButton(
            key: const Key('agent-undo-toast-undo'),
            onPressed: onUndo,
            style: TextButton.styleFrom(
              foregroundColor: c.tipInk,
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle: UiText.sans(12, weight: FontWeight.w600),
            ),
            child: Text(context.l10n.ag_diffUndo),
          ),
        ],
      ),
    );
  }
}

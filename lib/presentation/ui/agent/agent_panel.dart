import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_text.dart';
import 'agent_composer.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_header.dart';
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
  String? _toast;
  Timer? _toastTimer;
  var _dropping = false;

  @override
  void didUpdateWidget(covariant AgentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tab == AgentTab.memory && widget.data.memory == null) {
      _tab = AgentTab.chat;
    }
    // 新聊天 / 切聊天：回到对话页。
    if (oldWidget.data.chat.id != widget.data.chat.id) _tab = AgentTab.chat;
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _toast = null);
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
    setState(
      () => _dialog = (_) => _NameDialog(
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

  void _zoom(AgentImage image) {
    setState(
      () => _dialog = (_) =>
          _Zoom(image: image, onClose: () => setState(() => _dialog = null)),
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
          AgentHeader(tab: _tab, onTab: (t) => setState(() => _tab = t)),
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
    Widget panel = AgentScope(
      data: d,
      actions: widget.actions,
      slots: widget.slots,
      run: _run,
      rename: _rename,
      zoom: _zoom,
      insert: _insert,
      toast: _showToast,
      child: UiModal(
        dialog: _dialog,
        onDismiss: () => setState(() => _dialog = null),
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
          ],
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
        child: panel,
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
      width: 380,
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

class _Zoom extends StatelessWidget {
  const _Zoom({required this.image, required this.onClose});
  final AgentImage image;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AgentScope.of(context);
    final l = context.l10n;
    return GestureDetector(
      onTap: onClose,
      child: Stack(
        key: const Key('agent-zoom'),
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            maxScale: 6,
            child: Image(image: image.image, fit: BoxFit.contain),
          ),
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
                      onClose();
                      s.actions.onRevealImage(image.id);
                    },
                  ),
                AgentButton(
                  label: l.ag_imageAttach,
                  glyph: AgentGlyphs.clip,
                  onPressed: () {
                    onClose();
                    s.run(() => s.actions.onAttachImage(image.id));
                  },
                ),
                AgentButton(
                  key: const Key('agent-zoom-close'),
                  label: l.ag_zoomClose,
                  glyph: AgentGlyphs.close,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

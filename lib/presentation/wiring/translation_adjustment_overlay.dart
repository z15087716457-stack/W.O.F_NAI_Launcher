import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/localization_extension.dart';
import '../../l10n/app_localizations.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_translation_provider.dart';
import '../providers/translation_adjustment_provider.dart';
import '../ui/gen/translation_adjust_window.dart';

/// Root overlay, deliberately without a barrier. The page owns this handle.
class TranslationAdjustmentOverlay {
  OverlayEntry? _entry;
  ProviderContainer? _container;
  void toggle(BuildContext context, Rect anchor, bool negative) {
    if (_entry != null) {
      close();
      return;
    }
    final container = ProviderScope.containerOf(context);
    _container = container;
    container.read(translationReferencesProvider.notifier).state =
        TranslationReferences(negative: negative);
    _entry = OverlayEntry(
      builder: (_) => TranslationAdjustmentWiring(
        anchor: anchor,
        negative: negative,
        onClose: close,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void close() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    final container = _container;
    _container = null;
    if (container != null) {
      container.read(translationReferencesProvider.notifier).state =
          const TranslationReferences();
      container.invalidate(translationAdjustmentProvider);
    }
  }
}

class TranslationAdjustmentWiring extends ConsumerStatefulWidget {
  const TranslationAdjustmentWiring({
    super.key,
    required this.anchor,
    required this.negative,
    required this.onClose,
  });
  final Rect anchor;
  final bool negative;
  final VoidCallback onClose;
  @override
  ConsumerState<TranslationAdjustmentWiring> createState() => _WiringState();
}

/// Appended to the prompt so the model receives the selected markers.
const _referencesPrefix = '\nReferences: ';

class _WiringState extends ConsumerState<TranslationAdjustmentWiring> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(translationAdjustmentProvider(widget.negative)).start(),
        );
      }
    });
  }

  void _send(String text) {
    final controller = ref.read(translationAdjustmentProvider(widget.negative));
    final selected = ref.read(translationReferencesProvider).selected;
    unawaited(
      controller.send(
        selected.isEmpty
            ? text
            : '$text$_referencesPrefix${selected.join(', ')}',
      ),
    );
  }

  String _quick(AppLocalizations l, TranslationAdjustQuick kind) {
    final selected = ref.read(translationReferencesProvider).selected;
    final template = switch (kind) {
      TranslationAdjustQuick.split => l.gen_translateAdjustSplitTemplate,
      TranslationAdjustQuick.retranslate =>
        l.gen_translateAdjustRetranslateTemplate,
      TranslationAdjustQuick.merge => l.gen_translateAdjustMergeTemplate,
    };
    return '$template\n${selected.isEmpty ? l.gen_translateAdjustMarkers : selected.join(', ')}';
  }

  void _clearSelected() {
    final state = ref.read(translationReferencesProvider);
    ref.read(translationReferencesProvider.notifier).state =
        TranslationReferences(negative: state.negative, changed: state.changed);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      translationAdjustmentProvider(widget.negative),
    );
    final references = ref.watch(translationReferencesProvider);
    ref.watch(promptTranslationBusyProvider);
    // This revision updates the count after manual editor changes too.
    ref.watch(pillWorkspaceRevisionProvider);
    final coordinator = ref.read(promptTranslationCoordinatorProvider);
    final blocks =
        coordinator.readAdjustment(widget.negative)['blocks'] as List;
    final l = context.l10n;
    return TranslationAdjustWindow(
      anchor: widget.anchor,
      view: TranslationAdjustView(
        blockCount: blocks.length,
        entries: translationAdjustEntries(l, controller),
        selected: references.selected.length,
        modelLabel: controller.modelLabel,
        busy: controller.busy,
        canUndo: coordinator.canUndoAdjustment(widget.negative),
        error: controller.error,
      ),
      actions: TranslationAdjustActions(
        onSend: _send,
        onStop: () => unawaited(controller.stop()),
        onUndo: controller.undo,
        onClose: widget.onClose,
        onClearSelected: _clearSelected,
        quickText: (kind) => _quick(l, kind),
        onOpenLink: (href) {
          final uri = Uri.tryParse(href);
          if (uri != null) unawaited(launchUrl(uri));
        },
      ),
    );
  }
}

String _userText(Object? content) {
  final text = content is String
      ? content
      : content is List
      ? content
            .whereType<Map>()
            .where((p) => p['type'] == 'text')
            .map((p) => p['text'] as String? ?? '')
            .join('\n')
      : '';
  final cut = text.lastIndexOf(_referencesPrefix);
  return cut < 0 ? text : text.substring(0, cut);
}

/// Host transcript → view entries. Each edit operation is one step row;
/// consecutive tool calls share one step card. Completed reads are omitted.
@visibleForTesting
List<TranslationAdjustEntry> translationAdjustEntries(
  AppLocalizations l,
  TranslationAdjustmentController controller,
) {
  final messages = controller.messages;
  final results = <String, bool>{
    for (final m in messages)
      if (m['role'] == 'toolResult' && m['toolCallId'] is String)
        m['toolCallId'] as String: m['isError'] == true,
  };
  final out = <TranslationAdjustEntry>[];
  var steps = <TranslationAdjustStep>[];
  void flush() {
    if (steps.isEmpty) return;
    out.add(TranslationAdjustSteps(steps));
    steps = [];
  }

  for (final m in messages) {
    if (m['role'] == 'user') {
      flush();
      out.add(TranslationAdjustUser(_userText(m['content'])));
    }
    if (m['role'] != 'assistant') continue;
    final live = controller.busy && identical(m, messages.last);
    for (final part in (m['content'] as List? ?? const []).whereType<Map>()) {
      switch (part['type']) {
        case 'thinking':
          final text = part['thinking'] as String? ?? '';
          if (text.trim().isEmpty && !live) break;
          flush();
          out.add(TranslationAdjustThinking(text, live: live));
        case 'text':
          final text = part['text'] as String? ?? '';
          if (text.trim().isEmpty) break;
          flush();
          out.add(TranslationAdjustReply(text));
        case 'toolCall':
          final id = part['id'] as String;
          final failed = results[id];
          final status = failed == null
              ? (controller.busy
                    ? TranslationAdjustStepStatus.running
                    : TranslationAdjustStepStatus.failed)
              : failed
              ? TranslationAdjustStepStatus.failed
              : TranslationAdjustStepStatus.done;
          final name = part['name'] as String? ?? '';
          final args = part['arguments'];
          final ops =
              name == 'translation_blocks_edit' &&
                  args is Map &&
                  args['operations'] is List
              ? (args['operations'] as List).whereType<Map>().toList()
              : const <Map>[];
          if (ops.isEmpty) {
            // A completed read is noise; the edits that follow carry the change.
            if (name == 'translation_blocks_read' &&
                status == TranslationAdjustStepStatus.done) {
              break;
            }
            steps.add(TranslationAdjustStep(id: id, op: name, status: status));
            break;
          }
          for (final (i, op) in ops.indexed) {
            steps.add(
              TranslationAdjustStep(
                id: '$id-$i',
                op: _opName(op['op']),
                subject: _opSubject(l, op),
                status: status,
              ),
            );
          }
      }
    }
  }
  flush();
  return out;
}

String _opName(Object? op) => switch (op) {
  'split' => 'split_block',
  'merge' => 'merge_blocks',
  'retranslate' => 'retranslate',
  'rejoin' => 'rejoin',
  _ => '$op',
};

String? _opSubject(AppLocalizations l, Map op) {
  String? text(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;
  switch (op['op']) {
    case 'split':
      final parts = (op['parts'] as List? ?? const [])
          .whereType<Map>()
          .toList();
      final source = parts
          .map((p) => p['source'] as String? ?? '')
          .join()
          .trim();
      return parts.isEmpty
          ? null
          : l.gen_translateAdjustSplitInto(source, parts.length);
    case 'merge':
      return text(op['translation']) ?? text(op['source']);
    case 'retranslate':
      return text(op['translation']);
  }
  return null;
}

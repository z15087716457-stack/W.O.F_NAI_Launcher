import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/prompt_translation_provider.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/translation_adjustment_provider.dart';
import '../agent/agent_contract.dart';
import '../agent/agent_thread.dart';
import '../kit/ui_colors.dart';

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
      builder: (_) => TranslationAdjustmentWindow(
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

class TranslationAdjustmentWindow extends ConsumerStatefulWidget {
  const TranslationAdjustmentWindow({
    super.key,
    required this.anchor,
    required this.negative,
    required this.onClose,
  });
  final Rect anchor;
  final bool negative;
  final VoidCallback onClose;
  @override
  ConsumerState<TranslationAdjustmentWindow> createState() => _WindowState();
}

class _WindowState extends ConsumerState<TranslationAdjustmentWindow> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  Offset? _position;
  bool _collapsed = false;
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

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final controller = ref.read(translationAdjustmentProvider(widget.negative));
    if (controller.busy || _text.text.trim().isEmpty) return;
    final selected = ref.read(translationReferencesProvider).selected;
    final text =
        '${_text.text}${selected.isEmpty ? '' : '\nReferences: ${selected.join(', ')}'}';
    _text.clear();
    unawaited(controller.send(text));
  }

  AgentStepStatus _toolStatus(
    TranslationAdjustmentController controller,
    String id,
  ) {
    final result = controller.messages
        .where(
          (message) =>
              message['role'] == 'toolResult' && message['toolCallId'] == id,
        )
        .firstOrNull;
    if (result != null) {
      return result['isError'] == true
          ? AgentStepStatus.failed
          : AgentStepStatus.done;
    }
    return controller.busy ? AgentStepStatus.running : AgentStepStatus.failed;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      translationAdjustmentProvider(widget.negative),
    );
    final references = ref.watch(translationReferencesProvider);
    ref.watch(promptTranslationBusyProvider);
    ref.watch(pillWorkspaceRevisionProvider);
    // This revision updates the count after manual editor changes too.
    final blocks =
        ref
                .read(promptTranslationCoordinatorProvider)
                .readAdjustment(widget.negative)['blocks']
            as List;
    final l = context.l10n;
    final c = context.ui;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(392.0, size.width - 16);
    final height = _collapsed ? 62.0 : math.min(600.0, size.height - 16);
    final position =
        _position ?? Offset(widget.anchor.right + 12, widget.anchor.top);
    return Positioned(
      left: position.dx.clamp(8.0, math.max(8.0, size.width - width - 8)),
      top: position.dy.clamp(8.0, math.max(8.0, size.height - height - 8)),
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          key: const Key('translation-adjustment-window'),
          color: c.panel,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                key: const Key('translation-adjustment-drag'),
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (event) => setState(
                  () => _position = (_position ?? position) + event.delta,
                ),
                child: SizedBox(
                  height: 62,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.translate, size: 18, color: c.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.gen_translateAdjustTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                            Text(
                              '● ${l.gen_translateAdjustContext(blocks.length)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('translation-adjustment-collapse'),
                        tooltip: l.gen_translateAdjustCollapse,
                        onPressed: () =>
                            setState(() => _collapsed = !_collapsed),
                        icon: Icon(
                          _collapsed ? Icons.expand_more : Icons.expand_less,
                          size: 18,
                        ),
                      ),
                      IconButton(
                        key: const Key('translation-adjustment-close'),
                        tooltip: l.common_close,
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              if (!_collapsed) ...[
                Divider(height: 1, color: c.line),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (controller.messages.isEmpty)
                        Text(
                          l.gen_translateAdjustIntro,
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      for (final message in controller.messages) ...[
                        if (message['role'] == 'user')
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.control,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              message['content'] is String
                                  ? message['content'] as String
                                  : '',
                              style: TextStyle(fontSize: 12, color: c.ink),
                            ),
                          ),
                        if (message['role'] == 'assistant') ...[
                          for (final part
                              in message['content'] as List? ?? const []) ...[
                            if (part['type'] == 'thinking')
                              AgentThinking(
                                block: AgentThinkingBlock(
                                  part['thinking'] as String? ?? '',
                                  live:
                                      controller.busy &&
                                      identical(
                                        message,
                                        controller.messages.last,
                                      ),
                                ),
                              ),
                            if (part['type'] == 'text')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AgentMarkdown(
                                  part['text'] as String? ?? '',
                                  onOpenLink: (_) {},
                                ),
                              ),
                            if (part['type'] == 'toolCall')
                              AgentStepRow(
                                step: AgentStep(
                                  id: part['id'] as String,
                                  tool: part['name'] as String,
                                  status: _toolStatus(
                                    controller,
                                    part['id'] as String,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ],
                      if (controller.error != null)
                        Text(
                          controller.error!,
                          style: TextStyle(color: c.error, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final item in [
                        (
                          l.gen_translateAdjustSplit,
                          l.gen_translateAdjustSplitTemplate,
                        ),
                        (
                          l.gen_translateAdjustRetranslate,
                          l.gen_translateAdjustRetranslateTemplate,
                        ),
                        (
                          l.gen_translateAdjustMerge,
                          l.gen_translateAdjustMergeTemplate,
                        ),
                      ])
                        ActionChip(
                          label: Text(
                            item.$1,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            _text.text =
                                '${item.$2}\n${references.selected.isEmpty ? l.gen_translateAdjustMarkers : references.selected.join(', ')}';
                            _focus.requestFocus();
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.gen_translateAdjustSelected(
                            references.selected.length,
                          ),
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            ref
                                .read(promptTranslationCoordinatorProvider)
                                .canUndoAdjustment(widget.negative)
                            ? controller.undo
                            : null,
                        child: Text(l.common_undo),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                  child: Focus(
                    onKeyEvent: (_, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        if (HardwareKeyboard.instance.isShiftPressed) {
                          final value = _text.value;
                          final selection = value.selection;
                          final start = selection.isValid
                              ? selection.start
                              : value.text.length;
                          final end = selection.isValid
                              ? selection.end
                              : value.text.length;
                          _text.value = TextEditingValue(
                            text: value.text.replaceRange(start, end, '\n'),
                            selection: TextSelection.collapsed(
                              offset: start + 1,
                            ),
                          );
                        } else {
                          _send();
                        }
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('translation-adjustment-input'),
                            controller: _text,
                            focusNode: _focus,
                            minLines: 2,
                            maxLines: 4,
                            style: TextStyle(fontSize: 12, color: c.ink),
                            decoration: InputDecoration(
                              hintText: l.gen_translateAdjustHint,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('translation-adjustment-send'),
                          tooltip: controller.busy ? l.ag_stop : l.ag_send,
                          onPressed: controller.busy
                              ? () => unawaited(controller.stop())
                              : _send,
                          icon: Icon(
                            controller.busy ? Icons.stop : Icons.arrow_upward,
                            color: c.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Text(
                    controller.modelLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: c.faint),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

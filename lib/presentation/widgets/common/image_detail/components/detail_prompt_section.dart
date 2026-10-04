import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../../data/models/prompt_block/pill_document.dart';
import '../../../../providers/generation/generation_settings_notifiers.dart';
import '../../../../utils/translation_palette_drop.dart';
import '../../../prompt/blocks/prompt_block_drag_data.dart';
import '../../../prompt/pills/translation_pill_view.dart';
import '../../../prompt/unified/unified_prompt_config.dart';
import '../../../prompt/unified/unified_prompt_input.dart';
import '../../app_toast.dart';
import '../../image_action_menu.dart';
import '../../translation_icon.dart';
import '../../studio_icons.dart';
import 'detail_prompt_translation.dart';

/// Read-only reuse of the prompt editor, with an isolated translation document.
class PromptSection extends ConsumerStatefulWidget {
  const PromptSection({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    this.initiallyExpanded = false,
    this.contentColor,
    this.borderColor,
    this.customContent,
    this.inspectorStyle = false,
    this.contentStyle,
    this.previewLines,
    this.onCopy,
  });

  final String title;
  final IconData icon;
  final String content;
  final bool initiallyExpanded;
  final Color? contentColor;
  final Color? borderColor;
  final Widget? customContent;
  final bool inspectorStyle;
  final TextStyle? contentStyle;
  final int? previewLines;
  final VoidCallback? onCopy;

  @override
  ConsumerState<PromptSection> createState() => _PromptSectionState();
}

class _PromptSectionState extends ConsumerState<PromptSection> {
  late bool _expanded;
  late PillDocument _document;
  late final TextEditingController _controller;
  bool _busy = false;
  bool _hovered = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _document = PillDocument(text: widget.content, instances: const {});
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(covariant PromptSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _request++;
      _busy = false;
      _document = PillDocument(text: widget.content, instances: const {});
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _request++;
    _controller.dispose();
    super.dispose();
  }

  bool get _translated =>
      _document.instances.values.any((item) => item.translation != null);

  Future<void> _translate() async {
    if (_busy) return;
    if (_translated) {
      setState(() {
        _document = PillDocument(text: widget.content, instances: const {});
        _controller.text = widget.content;
      });
      return;
    }
    final snapshot = _document;
    final request = ++_request;
    setState(() {
      _busy = true;
      _expanded = true;
    });
    try {
      final result = await ref.read(detailPromptTranslatorProvider)(
        snapshot,
        'image-detail-${identityHashCode(this)}-$request',
      );
      if (!mounted || request != _request || !identical(_document, snapshot)) {
        return;
      }
      setState(() {
        _document = result;
        _controller.text = result.text;
      });
    } catch (error) {
      if (mounted && request == _request) {
        AppToast.error(context, error.toString());
      }
    } finally {
      if (mounted && request == _request) setState(() => _busy = false);
    }
  }

  Future<void> _store(TranslationPill pill, Offset position) async {
    final store = await ImageActionMenu.show<bool>(
      context,
      position: position,
      width: null,
      actions: [
        ImageMenuAction(
          value: true,
          label: context.l10n.imageMenu_saveToBlock,
          icon: StudioIcons.promptBlockPalette,
        ),
      ],
    );
    if (!mounted || store != true) return;
    try {
      await saveTranslationToBlockLibrary(ref, pill);
      if (mounted) AppToast.success(context, context.l10n.saveBlock_saved);
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    }
  }

  InlineSpan? _span(BuildContext context, String marker, int occurrence) {
    final instance = _document.instances[marker];
    final pill = instance?.translation;
    if (pill == null) return null;
    final highlight = ref.read(highlightEmphasisSettingsProvider);
    Widget view({bool feedback = false}) => TranslationPillView(
      key: ValueKey(
        'detail-translation-$marker-$occurrence-${feedback ? 'drag' : 'body'}',
      ),
      pill: pill,
      autoFormat: false,
      highlightEnabled: highlight,
      onToggle: feedback
          ? () {}
          : () => setState(() {
              _document = _document.copyWith(
                instances: {
                  ..._document.instances,
                  marker: instance!.copyWith(
                    translation: pill.copyWith(
                      showOriginal: !pill.showOriginal,
                    ),
                  ),
                },
              );
            }),
      onEdit: feedback ? (_) {} : (position) => _store(pill, position),
    );
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 3, bottom: 3),
        child: Draggable<PromptBlockDragData>(
          data: PromptBlockDragData(blockId: '', translation: pill),
          rootOverlay: true,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: view(feedback: true),
            ),
          ),
          childWhenDragging: Opacity(opacity: .4, child: view()),
          child: view(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasContent = widget.content.isNotEmpty;
    if (widget.inspectorStyle) return _buildInspector(context);
    final buttonStyle = IconButton.styleFrom(
      padding: const EdgeInsets.all(4),
      minimumSize: const Size(28, 28),
      overlayColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: widget.contentColor ?? colors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasContent && widget.customContent == null)
              IconButton(
                key: const Key('detail-prompt-translate'),
                tooltip: _translated
                    ? context.l10n.promptTranslation_restoreAll
                    : context.l10n.promptTranslation_translateNew,
                onPressed: _busy ? null : _translate,
                style: buttonStyle,
                icon: TranslationIcon(
                  size: 17,
                  busy: _busy,
                  color: _translated ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            if (hasContent) ...[
              IconButton(
                tooltip: _expanded
                    ? context.l10n.common_collapse
                    : context.l10n.common_expand,
                style: buttonStyle,
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: context.l10n.detail_copyLabel(widget.title),
                style: buttonStyle,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.content));
                  AppToast.success(
                    context,
                    context.l10n.toast_copiedTitle(widget.title),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
              ),
            ],
          ],
        ),
        if (_expanded && hasContent) ...[
          const SizedBox(height: 8),
          widget.customContent ??
              UnifiedPromptInput(
                key: const Key('detail-prompt-original-input'),
                controller: _controller,
                showCursor: false,
                fitContent: true,
                minLines: 1,
                maxLines: null,
                config: UnifiedPromptConfig(
                  readOnly: true,
                  embedded: true,
                  compact: true,
                  enableAutoFormat: false,
                  enableSdSyntaxAutoConvert: false,
                  enableSyntaxHighlight: ref.watch(
                    highlightEmphasisSettingsProvider,
                  ),
                  pillBuilder: _span,
                  pillVisualsSignature: identityHashCode(_document),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildInspector(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final buttonStyle = IconButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(24, 24),
      maximumSize: const Size(24, 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
    );
    final textStyle = widget.contentStyle?.copyWith(fontSize: 12, height: 1.6);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _hovered,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: IconButton(
                      key: const Key('detail-prompt-translate'),
                      style: buttonStyle,
                      tooltip: _translated
                          ? context.l10n.promptTranslation_restoreAll
                          : context.l10n.promptTranslation_translateNew,
                      onPressed: _busy ? null : _translate,
                      icon: TranslationIcon(
                        size: 15,
                        busy: _busy,
                        color: _translated
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    style: buttonStyle,
                    tooltip: context.l10n.common_copy,
                    icon: const Icon(StudioIcons.galleryCopy, size: 14),
                    onPressed:
                        widget.onCopy ??
                        () => Clipboard.setData(
                          ClipboardData(text: widget.content),
                        ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _translated
                ? UnifiedPromptInput(
                    key: const Key('detail-prompt-original-input'),
                    controller: _controller,
                    showCursor: false,
                    fitContent: true,
                    minLines: 1,
                    maxLines: null,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                    ),
                    config: UnifiedPromptConfig(
                      readOnly: true,
                      embedded: true,
                      compact: true,
                      enableAutoFormat: false,
                      enableSdSyntaxAutoConvert: false,
                      enableSyntaxHighlight: ref.watch(
                        highlightEmphasisSettingsProvider,
                      ),
                      pillBuilder: _span,
                      pillVisualsSignature: identityHashCode(_document),
                    ),
                  )
                : widget.previewLines == null
                ? SelectableText(widget.content, style: textStyle)
                : Text(
                    widget.content,
                    style: textStyle,
                    maxLines: widget.previewLines,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}

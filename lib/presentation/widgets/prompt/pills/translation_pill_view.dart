import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/prompt_block/pill_document.dart';

class TranslationPillView extends StatefulWidget {
  const TranslationPillView({
    super.key,
    required this.pill,
    required this.onToggle,
    required this.onEdit,
  });

  final TranslationPill pill;
  final VoidCallback onToggle;
  final ValueChanged<Offset> onEdit;

  @override
  State<TranslationPillView> createState() => _TranslationPillViewState();
}

class _TranslationPillViewState extends State<TranslationPillView> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = widget.pill;
    final original = pill.showOriginal || pill.needsReview;
    final accent = scheme.primary.withValues(alpha: original ? .62 : .70);
    final fill = scheme.primary.withValues(alpha: original ? .035 : .065);
    final text = original ? pill.source : pill.zh;
    return Semantics(
      button: true,
      label: original ? '翻译块，显示原文' : '翻译块，显示译文',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 300.0;
          final content = Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(6),
              border: original ? null : Border.all(color: accent, width: 1),
            ),
            foregroundDecoration: original
                ? ShapeDecoration(
                    shape: _DashedRoundedBorder(color: accent, radius: 6),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (original) ...[
                  Icon(Icons.translate_outlined, size: 13, color: accent),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    text,
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                ),
                if (pill.needsReview) ...[
                  const SizedBox(width: 5),
                  Tooltip(
                    message: '原文已修改 · 译文待更新',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          widget.onEdit(details.globalPosition),
                      child: Icon(
                        Icons.build_outlined,
                        size: 13,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
          return GestureDetector(
            onTapUp: (details) => widget.onEdit(details.globalPosition),
            onTertiaryTapUp: (_) => widget.onToggle(),
            child: content,
          );
        },
      ),
    );
  }
}

class _DashedRoundedBorder extends ShapeBorder {
  const _DashedRoundedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = getOuterPath(rect.deflate(.5));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 4).clamp(0, metric.length)),
          paint,
        );
        distance += 7;
      }
    }
  }

  @override
  ShapeBorder scale(double t) =>
      _DashedRoundedBorder(color: color, radius: radius * t);
}

class TranslationPillEditHandle {
  const TranslationPillEditHandle({
    required this.result,
    required this.dismiss,
  });

  final Future<Object?> result;
  final VoidCallback dismiss;
}

/// Open a compact editor at the click position, without dimming the canvas.
TranslationPillEditHandle showTranslationPillEditor({
  required BuildContext context,
  required TranslationPill initial,
  required Offset globalPosition,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<Object?>();
  late final OverlayEntry entry;

  void finish(Object? value) {
    if (completer.isCompleted) return;
    entry.remove();
    entry.dispose();
    completer.complete(value);
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      final overlayBox = overlay.context.findRenderObject()! as RenderBox;
      final localPosition = overlayBox.globalToLocal(globalPosition);
      final screen = overlayBox.size;
      final cardWidth = math.min(380.0, math.max(0.0, screen.width - 16));
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => finish(null),
            ),
          ),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _TranslationPopoverLayout(localPosition),
              child: SizedBox(
                width: cardWidth,
                child: _TranslationPillEditPopover(
                  initial: initial,
                  onComplete: finish,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  overlay.insert(entry);
  return TranslationPillEditHandle(
    result: completer.future,
    dismiss: () => finish(null),
  );
}

class _TranslationPopoverLayout extends SingleChildLayoutDelegate {
  const _TranslationPopoverLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.max(0, constraints.maxWidth - 16),
        maxHeight: math.max(0, constraints.maxHeight - 16),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final left = anchor.dx
        .clamp(8.0, math.max(8.0, size.width - childSize.width - 8))
        .toDouble();
    final below = anchor.dy + 10;
    final top = below + childSize.height <= size.height - 8
        ? below
        : (anchor.dy - childSize.height - 10)
              .clamp(8.0, math.max(8.0, size.height - childSize.height - 8))
              .toDouble();
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_TranslationPopoverLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}

class _TranslationPillEditPopover extends StatefulWidget {
  const _TranslationPillEditPopover({
    required this.initial,
    required this.onComplete,
  });

  final TranslationPill initial;
  final ValueChanged<Object?> onComplete;

  @override
  State<_TranslationPillEditPopover> createState() =>
      _TranslationPillEditPopoverState();
}

class _TranslationPillEditPopoverState
    extends State<_TranslationPillEditPopover> {
  late final TextEditingController _source = TextEditingController(
    text: widget.initial.source,
  );
  late final TextEditingController _zh = TextEditingController(
    text: widget.initial.zh,
  );

  @override
  void dispose() {
    _source.dispose();
    _zh.dispose();
    super.dispose();
  }

  void _save() {
    final sourceChanged = _source.text != widget.initial.source;
    final readingChanged = _zh.text.trim() != widget.initial.zh;
    widget.onComplete(
      TranslationPill(
        source: _source.text,
        zh: _zh.text.trim(),
        showOriginal: sourceChanged || widget.initial.showOriginal,
        needsReview: readingChanged
            ? false
            : sourceChanged || widget.initial.needsReview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      key: const Key('translation-pill-editor-popover'),
      elevation: 5,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.translate_outlined, size: 17, color: scheme.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '翻译块',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => widget.onComplete(null),
                  icon: const Icon(Icons.close),
                  iconSize: 17,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel(context, '原文', '生图使用'),
                    const SizedBox(height: 4),
                    _field(_source),
                    const SizedBox(height: 12),
                    _fieldLabel(context, '中文', '仅供阅读'),
                    const SizedBox(height: 4),
                    _field(_zh),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 7),
            Row(
              children: [
                IconButton(
                  key: const Key('translation-pill-delete'),
                  tooltip: '删除整块',
                  onPressed: () => widget.onComplete('delete'),
                  icon: const Icon(Icons.delete_outline),
                  color: scheme.error,
                  iconSize: 19,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('translation-pill-retranslate'),
                  tooltip: '重新翻译',
                  onPressed: () => widget.onComplete('retranslate'),
                  icon: SizedBox(
                    width: 22,
                    height: 22,
                    child: Stack(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(Icons.description_outlined, size: 19),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.refresh, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  iconSize: 19,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const Key('translation-pill-save'),
                  onPressed: _source.text.isEmpty || _zh.text.trim().isEmpty
                      ? null
                      : _save,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('保存'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(72, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String title, String hint) => Row(
    children: [
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 5),
      Text(
        '· $hint',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _field(TextEditingController controller) => TextField(
    controller: controller,
    minLines: 1,
    maxLines: null,
    onChanged: (_) => setState(() {}),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.3),
    decoration: InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

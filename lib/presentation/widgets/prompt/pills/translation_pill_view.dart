import 'package:flutter/material.dart';

import '../../../../data/models/prompt_block/pill_document.dart';
import '../blocks/prompt_block_appearance.dart';

class TranslationPillView extends StatefulWidget {
  const TranslationPillView({
    super.key,
    required this.pill,
    required this.onToggle,
    required this.onEdit,
  });

  final TranslationPill pill;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  State<TranslationPillView> createState() => _TranslationPillViewState();
}

class _TranslationPillViewState extends State<TranslationPillView> {
  DateTime? _lastTap;

  void _handleTap(TapUpDetails _) {
    final now = DateTime.now();
    final previous = _lastTap;
    if (previous != null &&
        now.difference(previous) < const Duration(milliseconds: 360)) {
      _lastTap = null;
      widget.onToggle(); // restore the display state changed by the first tap
      widget.onEdit();
      return;
    }
    _lastTap = now;
    widget.onToggle();
  }

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
              border: original ? Border.all(color: accent, width: 1) : null,
            ),
            foregroundDecoration: original
                ? null
                : ShapeDecoration(
                    shape: _DashedRoundedBorder(color: accent, radius: 6),
                  ),
            child: CustomPaint(
              painter: PromptBlockPatternPainter(
                appearance: original
                    ? PromptBlockAppearance.classic
                    : PromptBlockAppearance.translation,
                color: accent,
              ),
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
                  if (original) ...[
                    const SizedBox(width: 5),
                    Tooltip(
                      message: pill.needsReview ? '编辑双语内容 · 译文待更新' : '编辑原文与译文',
                      child: InkWell(
                        onTap: widget.onEdit,
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
            ),
          );
          return GestureDetector(onTapUp: _handleTap, child: content);
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

class TranslationPillEditDialog extends StatefulWidget {
  const TranslationPillEditDialog({super.key, required this.initial});
  final TranslationPill initial;

  @override
  State<TranslationPillEditDialog> createState() =>
      _TranslationPillEditDialogState();
}

class _TranslationPillEditDialogState extends State<TranslationPillEditDialog> {
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

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('编辑翻译块'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _source,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: '原文 · 生图使用'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _zh,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: '中文 · 仅供阅读'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop('delete'),
        child: const Text('删除整块'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop('retranslate'),
        child: const Text('重新翻译'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _source.text.isEmpty || _zh.text.trim().isEmpty
            ? null
            : () {
                final sourceChanged = _source.text != widget.initial.source;
                Navigator.of(context).pop(
                  TranslationPill(
                    source: _source.text,
                    zh: _zh.text.trim(),
                    showOriginal: sourceChanged || widget.initial.showOriginal,
                    needsReview: sourceChanged && _zh.text == widget.initial.zh,
                  ),
                );
              },
        child: const Text('保存'),
      ),
    ],
  );
}

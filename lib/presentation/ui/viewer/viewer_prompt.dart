import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'viewer_format.dart';

final _weight = RegExp(r'(-?\d+(?:\.\d+)?)::([\s\S]*?)::');
final _artist = RegExp(r'artist:[^,<:\[\]\n]+');

/// 提示词高亮：`1.2::…::` 权重组按大于 1 / 小于 1 / 负数分色（底色 + 权重数字），画师串强调色。
/// [highlight] 关掉时原样显示。空行合并成一行。
List<InlineSpan> viewerPromptSpans(
  String text, {
  required UiColors c,
  required bool highlight,
}) {
  final t = text.trim().replaceAll(RegExp(r'\n{2,}'), '\n');
  if (!highlight) return [TextSpan(text: t)];
  List<InlineSpan> artists(String s) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in _artist.allMatches(s)) {
      if (m.start > at) out.add(TextSpan(text: s.substring(at, m.start)));
      out.add(
        TextSpan(
          text: m.group(0),
          style: TextStyle(color: c.accent),
        ),
      );
      at = m.end;
    }
    if (at < s.length) out.add(TextSpan(text: s.substring(at)));
    return out;
  }

  final spans = <InlineSpan>[];
  var at = 0;
  for (final m in _weight.allMatches(t)) {
    if (m.start > at) spans.addAll(artists(t.substring(at, m.start)));
    final w = double.tryParse(m.group(1)!) ?? 1;
    final (bg, ink) = w < 0
        ? (c.weightNeg, c.weightNegInk)
        : w > 1
        ? (c.weightUp, c.weightUpInk)
        : (c.weightDown, c.weightDownInk);
    spans.add(
      TextSpan(
        style: TextStyle(background: Paint()..color = bg),
        children: [
          TextSpan(
            text: '${m.group(1)} ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: ink.withValues(alpha: .85),
            ),
          ),
          ...artists(m.group(2)!),
        ],
      ),
    );
    at = m.end;
  }
  if (at < t.length) spans.addAll(artists(t.substring(at)));
  return spans;
}

/// 提示词框：抬起底、描边、圆角 8、内边距 8 × 10，等宽 12 / 1.65。
/// [maxLines] 折叠；折叠后放不下时 [onOverflow] 报告（父级决定显示“展开”）。
class ViewerPromptBox extends StatelessWidget {
  const ViewerPromptBox({
    super.key,
    required this.spans,
    this.maxLines,
    this.muted = false,
    this.prefix,
    this.onOverflow,
  });

  final List<InlineSpan> spans;
  final int? maxLines;
  final bool muted;

  /// 开头的小标签（“角色负面 · ”）。
  final String? prefix;
  final ValueChanged<bool>? onOverflow;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final style = UiText.mono(12, color: muted ? c.muted : c.ink, height: 1.65);
    final span = TextSpan(
      style: style,
      children: [
        if (prefix != null)
          TextSpan(
            text: prefix,
            style: UiText.sans(11, color: c.faint, height: 1.65),
          ),
        ...spans,
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          if (onOverflow != null && maxLines != null) {
            final p = TextPainter(
              text: span,
              maxLines: maxLines,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: box.maxWidth);
            final over = p.didExceedMaxLines;
            p.dispose();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onOverflow!(over),
            );
          }
          return Text.rich(
            span,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}

/// 角色位置：5 × 5 小格（每格 5、间距 2、内边距 3、控件底），当前格强调色。
class ViewerPositionGrid extends StatelessWidget {
  const ViewerPositionGrid({super.key, this.x, this.y});
  final double? x;
  final double? y;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final (cx, cy) = viewerCell(x, y);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (var r = 0; r < 5; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                for (var col = 0; col < 5; col++)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: col == cx && r == cy
                          ? c.accent
                          : c.ink.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

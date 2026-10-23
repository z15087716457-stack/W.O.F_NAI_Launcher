import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_parts.dart';

/// 迷你定位板：按画面比例，最长边 150（7 人以上 180）；人越多圆点越小，
/// 挨得太近的圆点互相推开一点，保证编号看得清。
class AgentPositionBoard extends StatelessWidget {
  const AgentPositionBoard({super.key, required this.block, this.height});
  final AgentPositionBlock block;

  /// Prompt-set previews use a compact fixed height; diff cards keep their size.
  final double? height;

  static const palette = [
    Color(0xFFE5484D),
    Color(0xFF0090FF),
    Color(0xFF30A46C),
    Color(0xFFF76B15),
    Color(0xFF8E4EC6),
    Color(0xFF12A594),
    Color(0xFFD6409F),
    Color(0xFFAD7F58),
  ];
  static Color colorOf(int index) => palette[index % palette.length];

  static double dotFor(int count) => count <= 6
      ? 18
      : count <= 12
      ? 15
      : 13;

  /// 把落点互相推开到至少 [gap]（几轮简单松弛，夹在板内）。
  static List<Offset> spread(List<Offset> points, Size size, double gap) {
    final p = [...points];
    final half = gap / 2;
    for (var round = 0; round < 8; round++) {
      var moved = false;
      for (var i = 0; i < p.length; i++) {
        for (var j = i + 1; j < p.length; j++) {
          final d = p[j] - p[i];
          final dist = d.distance;
          if (dist >= gap) continue;
          final u = dist < .01
              ? Offset(1, (i + j).isEven ? .3 : -.3)
              : d / dist;
          final push = u * ((gap - dist) / 2 + .1);
          p[i] -= push;
          p[j] += push;
          moved = true;
        }
      }
      for (var i = 0; i < p.length; i++) {
        p[i] = Offset(
          p[i].dx.clamp(half, size.width - half),
          p[i].dy.clamp(half, size.height - half),
        );
      }
      if (!moved) break;
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final aspect = (block.aspect ?? 2 / 3).clamp(.5, 2.0);
    final placed = block.marks.where((m) => m.after != null).toList();
    final long = placed.length > 6 ? 180.0 : 150.0;
    final size = height != null
        ? Size(height! * aspect, height!)
        : aspect >= 1
        ? Size(long, long / aspect)
        : Size(long * aspect, long);
    final dot = dotFor(placed.length);
    final centers = spread(
      [
        for (final m in placed)
          Offset(m.after!.dx * size.width, m.after!.dy * size.height),
      ],
      size,
      dot + 1,
    );
    return Container(
      key: Key('agent-position-board-${block.id}'),
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: agentSunk(c),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PositionBoardPainter(line: c.line, marks: block.marks),
            ),
          ),
          // 没动的先画、动过的后画，动过的在上面。
          for (final (i, m) in placed.indexed.where((e) => !e.$2.moved))
            _place(m, centers[i], dot),
          for (final (i, m) in placed.indexed.where((e) => e.$2.moved))
            _place(m, centers[i], dot),
        ],
      ),
    );
  }

  Widget _place(AgentPositionMark m, Offset center, double dot) => Positioned(
    left: center.dx - dot / 2,
    top: center.dy - dot / 2,
    child: AgentPositionDot(
      key: Key('agent-position-dot-${m.index}'),
      index: m.index,
      size: dot,
      dim: !m.moved,
    ),
  );
}

class AgentPositionDot extends StatelessWidget {
  const AgentPositionDot({
    super.key,
    required this.index,
    required this.size,
    this.dim = false,
  });
  final int index;
  final double size;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final color = AgentPositionBoard.colorOf(index);
    final label = '${index + 1}';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dim ? Color.lerp(color, Colors.white, .5) : color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: dim
            ? null
            : const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Text(
        label,
        style: UiText.mono(
          size * (label.length > 1 ? .48 : .55),
          weight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// 板上只画淡淡的中线作参照（无极定位不分格），以及动过的角色的原位置虚线圈和箭头。
class _PositionBoardPainter extends CustomPainter {
  _PositionBoardPainter({required this.line, required this.marks});
  final Color line;
  final List<AgentPositionMark> marks;

  static const _pi = 3.141592653589793;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = line.withValues(alpha: .7)
      ..strokeWidth = 1;
    void dashed(Offset a, Offset b) {
      final d = b - a, len = d.distance, u = d / len;
      for (var t = 0.0; t < len; t += 7) {
        canvas.drawLine(a + u * t, a + u * (t + 3.5).clamp(0, len), guide);
      }
    }

    dashed(Offset(size.width / 2, 0), Offset(size.width / 2, size.height));
    dashed(Offset(0, size.height / 2), Offset(size.width, size.height / 2));
    for (final m in marks) {
      final from = m.before, to = m.after;
      if (!m.moved || from == null) continue;
      final color = AgentPositionBoard.colorOf(m.index);
      final a = Offset(from.dx * size.width, from.dy * size.height);
      // 原位置：虚线圈。
      final ring = Paint()
        ..color = color.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      const r = 7.0;
      for (var k = 0; k < 12; k += 2) {
        canvas.drawArc(
          Rect.fromCircle(center: a, radius: r),
          k * _pi / 6,
          _pi / 6,
          false,
          ring,
        );
      }
      if (to == null) continue;
      final b = Offset(to.dx * size.width, to.dy * size.height);
      final d = b - a;
      final len = d.distance;
      if (len < 22) continue;
      final u = d / len;
      final start = a + u * (r + 2), end = b - u * 10;
      final paint = Paint()
        ..color = color.withValues(alpha: .85)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
      final n = Offset(-u.dy, u.dx);
      final tip = end + u;
      final back = end - u * 5;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(back.dx + n.dx * 3.5, back.dy + n.dy * 3.5)
          ..lineTo(back.dx - n.dx * 3.5, back.dy - n.dy * 3.5)
          ..close(),
        Paint()..color = color.withValues(alpha: .85),
      );
    }
  }

  @override
  bool shouldRepaint(_PositionBoardPainter old) =>
      old.line != line || old.marks != marks;
}

import 'package:flutter/material.dart';

class PromptTranslationGuide extends StatelessWidget {
  const PromptTranslationGuide({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          IconButton(
            key: const Key('translation-guide-back'),
            tooltip: '返回操作',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 15),
            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 5),
          Text(
            '操作教程',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _GuideRow(
                icon: MouseGestureIcon(middle: true),
                title: '中键点块',
                text: '切换原文与译文',
              ),
              _GuideRow(
                icon: MouseGestureIcon(),
                title: '左键点原文',
                text: '定位光标，直接修改',
              ),
              _GuideRow(
                icon: MouseGestureIcon(),
                title: '左键点译文',
                text: '打开块编辑窗',
              ),
              _GuideRow(
                icon: Icon(Icons.keyboard, size: 20),
                title: 'Ctrl + 点击 / 拖选',
                text: '编辑窗内搜索标签 / 查关联',
              ),
              _GuideRow(
                icon: Icon(Icons.swap_vert, size: 21),
                title: '↑ 中文转原文',
                text: '↓ 原文转中文，检查后保存',
              ),
              _GuideRow(
                icon: Icon(Icons.undo, size: 20),
                title: 'A / 恢复',
                text: '整组还原原文 / 恢复翻译块',
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.title,
    required this.text,
  });
  final Widget icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTheme(
            data: IconThemeData(color: theme.colorScheme.primary),
            child: SizedBox(width: 23, child: icon),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    height: 1.35,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A vector mouse drawing with the pressed button highlighted.
class MouseGestureIcon extends StatelessWidget {
  const MouseGestureIcon({super.key, this.middle = false});
  final bool middle;
  @override
  Widget build(BuildContext context) => Semantics(
    label: middle ? '鼠标中键' : '鼠标左键',
    child: CustomPaint(
      size: const Size(20, 25),
      painter: _MousePainter(
        middle,
        Theme.of(context).colorScheme.onSurfaceVariant,
        Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _MousePainter extends CustomPainter {
  const _MousePainter(this.middle, this.outline, this.accent);
  final bool middle;
  final Color outline;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final shape = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2.5, 1.5, 15, 22),
      const Radius.circular(7),
    );
    canvas.save();
    canvas.clipRRect(shape);
    if (!middle) {
      canvas.drawRect(
        const Rect.fromLTWH(2.5, 1.5, 7.5, 9),
        Paint()..color = accent.withValues(alpha: .8),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      shape,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawLine(
      const Offset(2.5, 10.5),
      const Offset(17.5, 10.5),
      Paint()
        ..color = outline
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      const Offset(10, 2),
      const Offset(10, 10.5),
      Paint()
        ..color = outline
        ..strokeWidth = 1.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8.6, 4, 2.8, 5.2),
        const Radius.circular(1.4),
      ),
      Paint()..color = middle ? accent : outline,
    );
  }

  @override
  bool shouldRepaint(_MousePainter oldDelegate) =>
      oldDelegate.middle != middle ||
      oldDelegate.outline != outline ||
      oldDelegate.accent != accent;
}

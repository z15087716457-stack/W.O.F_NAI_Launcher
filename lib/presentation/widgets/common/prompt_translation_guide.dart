import 'package:flutter/material.dart';
import '../../../core/utils/localization_extension.dart';

class PromptTranslationGuide extends StatelessWidget {
  const PromptTranslationGuide({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          IconButton(
            key: const Key('translation-guide-back'),
            tooltip: context.l10n.promptTranslation_guideBack,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 15),
            constraints: const BoxConstraints.tightFor(width: 26, height: 26),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 5),
          Text(
            context.l10n.promptTranslation_tutorial,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Flexible(
        fit: FlexFit.loose,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _GuideRow(
                icon: const MouseGestureIcon(middle: true),
                title: context.l10n.promptTranslation_guideMiddleTitle,
                text: context.l10n.promptTranslation_guideMiddleText,
              ),
              _GuideRow(
                icon: const MouseGestureIcon(),
                title: context.l10n.promptTranslation_guideSourceTitle,
                text: context.l10n.promptTranslation_guideSourceText,
              ),
              _GuideRow(
                icon: const MouseGestureIcon(),
                title: context.l10n.promptTranslation_guideReadingTitle,
                text: context.l10n.promptTranslation_guideReadingText,
              ),
              _GuideRow(
                icon: const Icon(Icons.keyboard, size: 20),
                title: context.l10n.promptTranslation_guideCtrlTitle,
                text: context.l10n.promptTranslation_guideCtrlText,
              ),
              _GuideRow(
                icon: const Icon(Icons.swap_vert, size: 21),
                title: context.l10n.promptTranslation_guideConvertTitle,
                text: context.l10n.promptTranslation_guideConvertText,
              ),
              _GuideRow(
                icon: const Icon(Icons.undo, size: 20),
                title: context.l10n.promptTranslation_guideRestoreTitle,
                text: context.l10n.promptTranslation_guideRestoreText,
                bottomGap: 0,
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
    this.bottomGap = 13,
  });
  final Widget icon;
  final String title;
  final String text;
  final double bottomGap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
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
    label: middle
        ? context.l10n.promptTranslation_middleButton
        : context.l10n.promptTranslation_leftButton,
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

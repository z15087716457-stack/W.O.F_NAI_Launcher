import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_text.dart';

/// 卡片：卡片底、1px 描边、圆角 12、无阴影。
class UiCard extends StatelessWidget {
  const UiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// 卡片标题行：标题 13.5 / w600，旁边一句说明，右侧可放控件。下方留 14。
class UiCardHeader extends StatelessWidget {
  const UiCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 22),
        child: Row(
          children: [
            Text(
              title,
              style: UiText.sans(13.5, weight: FontWeight.w600, color: c.ink),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12, color: c.faint),
              ),
            ),
            if (trailing.isNotEmpty) ...[const SizedBox(width: 8), ...trailing],
          ],
        ),
      ),
    );
  }
}

/// 小节标题：11.5 / w500 弱色，下方 7。
class UiSectionLabel extends StatelessWidget {
  const UiSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.sans(
        11.5,
        weight: FontWeight.w500,
        color: context.ui.faint,
      ),
    ),
  );
}

/// 结论胶囊：高 26、圆角 7、控件底，后半句加粗。
class UiFactPill extends StatelessWidget {
  const UiFactPill({
    super.key,
    required this.label,
    required this.value,
    this.background,
  });

  final String label;
  final String value;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background ?? c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        widthFactor: 1,
        child: Text.rich(
          TextSpan(
            children: [
              if (label.isNotEmpty) ...[
                TextSpan(text: label),
                const WidgetSpan(child: SizedBox(width: 5)),
              ],
              TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          maxLines: 1,
          style: UiText.sans(12.5, color: c.ink),
        ),
      ),
    );
  }
}

/// 普通胶囊：高 26、圆角 7。
class UiPill extends StatelessWidget {
  const UiPill(this.text, {super.key, this.background});
  final String text;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background ?? c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(text, maxLines: 1, style: UiText.sans(12.5, color: c.ink)),
      ),
    );
  }
}

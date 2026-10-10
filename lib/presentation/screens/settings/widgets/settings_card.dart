import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// A quiet settings group; retained name keeps feature panels compatible.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.showDivider = true,
    this.bottomSpacing = 26,
  });
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final bool showDivider;
  final double bottomSpacing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomSpacing),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        child,
      ],
    ),
  );
}

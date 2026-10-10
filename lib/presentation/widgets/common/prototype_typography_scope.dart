import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../themes/studio_typography.dart';

/// Most prototypes use HOS; local gallery uses Geist with the same HOS fallback.
/// Explicit custom fonts remain usable. Viewers restore their own HOS role.
class PrototypeTypographyScope extends StatelessWidget {
  const PrototypeTypographyScope({
    super.key,
    required this.family,
    this.fallback = StudioTypography.fallback,
    this.height,
    required this.child,
  });

  final String family;
  final List<String> fallback;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = theme.textTheme.bodyMedium?.fontFamily;
    if (theme.extension<StudioFontProfile>()?.usePrototypeFamilies == false ||
        (current == family && height == null) ||
        (theme.extension<StudioFontProfile>() == null &&
            current != StudioTypography.cjk &&
            current != StudioTypography.sans)) {
      return child;
    }
    return Theme(
      data: StudioTypography.applyFamily(
        theme,
        family,
        familyFallback: fallback,
        height: height,
      ),
      child: child,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/update_provider.dart';
import '../navigation/integrated_title_bar.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';

/// Quiet, persistent entry next to the window captions. It sits on the
/// page surface; its owner supplies the dialog callback.
class UpdateCapsule extends StatelessWidget {
  const UpdateCapsule({super.key, required this.onPressed});

  static const width = 88.0;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFFFB45C) : const Color(0xFF995000);
    return ColoredBox(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: SizedBox(
            height: 26,
            child: Material(
              color: dark ? const Color(0xFF392B1A) : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                key: const Key('window-update-capsule'),
                borderRadius: BorderRadius.circular(20),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: foreground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.updateCapsuleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps update discovery outside the router while passing the exact occupied
/// caption width down to page headers. Snoozing a notice never hides this entry.
class UpdateAwareWindowShell extends ConsumerWidget {
  const UpdateAwareWindowShell({
    super.key,
    required this.child,
    required this.onShowUpdate,
    this.immersive = false,
    this.onToggleTheme,
    this.captionHeight = IntegratedTitleBarShell.barHeight,
    this.deferToRoute = false,
  });
  final Widget child;
  final VoidCallback onShowUpdate;
  final bool immersive;
  final VoidCallback? onToggleTheme;
  final double captionHeight;
  final bool deferToRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(
      updateStateProvider.select((s) => s.hasNewVersion),
    );
    return IntegratedTitleBarShell(
      immersive: immersive,
      deferToRoute: deferToRoute,
      captionHeight: captionHeight,
      onToggleTheme: onToggleTheme,
      accessoryWidth: available ? UpdateCapsule.width : 0,
      accessory: available ? UpdateCapsule(onPressed: onShowUpdate) : null,
      child: child,
    );
  }
}

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/canvas_settings_provider.dart';

class SettingsMotionScope extends ConsumerWidget {
  const SettingsMotionScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced =
        ref.watch(canvasReducedMotionNotifierProvider) ||
        MediaQuery.disableAnimationsOf(context);
    return _SettingsMotionTheme(
      reducedMotion: reduced,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child,
      ),
    );
  }
}

/// Captures settings' reduced-motion preference for dialogs and menus.
/// Interface scaling belongs to the complete Navigator.
class _SettingsMotionTheme extends InheritedTheme {
  const _SettingsMotionTheme({
    required this.reducedMotion,
    required super.child,
  });
  final bool reducedMotion;

  @override
  Widget wrap(BuildContext context, Widget child) => _SettingsMotionTheme(
    reducedMotion: reducedMotion,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: child,
    ),
  );

  @override
  bool updateShouldNotify(_SettingsMotionTheme oldWidget) =>
      reducedMotion != oldWidget.reducedMotion;
}

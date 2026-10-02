import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_font_scale_provider.dart';
import '../../../providers/canvas_settings_provider.dart';

class SettingsTypographyScope extends ConsumerWidget {
  const SettingsTypographyScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaler = TextScaler.linear(
      SettingsFontScaleNotifier.effectiveScale(
        ref.watch(settingsFontScaleProvider),
      ),
    );
    final reduced =
        ref.watch(canvasReducedMotionNotifierProvider) ||
        MediaQuery.disableAnimationsOf(context);
    return _SettingsTypographyTheme(
      scaler: scaler,
      reducedMotion: reduced,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: scaler, disableAnimations: reduced),
        child: child,
      ),
    );
  }
}

/// InheritedTheme capture carries scale and reduced motion into dialogs/menus.
/// Assigning the captured scale avoids multiplying nested overlays twice.
class _SettingsTypographyTheme extends InheritedTheme {
  const _SettingsTypographyTheme({
    required this.scaler,
    required this.reducedMotion,
    required super.child,
  });
  final TextScaler scaler;
  final bool reducedMotion;

  @override
  Widget wrap(BuildContext context, Widget child) => _SettingsTypographyTheme(
    scaler: scaler,
    reducedMotion: reducedMotion,
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: scaler, disableAnimations: reducedMotion),
      child: child,
    ),
  );

  @override
  bool updateShouldNotify(_SettingsTypographyTheme oldWidget) =>
      scaler != oldWidget.scaler || reducedMotion != oldWidget.reducedMotion;
}

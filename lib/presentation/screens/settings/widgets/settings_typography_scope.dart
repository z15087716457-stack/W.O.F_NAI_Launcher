import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_font_scale_provider.dart';

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
    return _SettingsTypographyTheme(
      scaler: scaler,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: child,
      ),
    );
  }
}

/// InheritedTheme capture carries the same scale into dialogs and menus.
/// Assigning the captured scale avoids multiplying nested overlays twice.
class _SettingsTypographyTheme extends InheritedTheme {
  const _SettingsTypographyTheme({required this.scaler, required super.child});
  final TextScaler scaler;

  @override
  Widget wrap(BuildContext context, Widget child) => _SettingsTypographyTheme(
    scaler: scaler,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: child,
    ),
  );

  @override
  bool updateShouldNotify(_SettingsTypographyTheme oldWidget) =>
      scaler != oldWidget.scaler;
}

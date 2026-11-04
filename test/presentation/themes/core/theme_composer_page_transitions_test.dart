import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/social_theme.dart';

void main() {
  test('macOS 和 Windows 用同一套页面切换动画', () {
    final builders = SocialTheme.light.pageTransitionsTheme.builders;
    final windows = builders[TargetPlatform.windows];
    final macOS = builders[TargetPlatform.macOS];
    expect(windows, isNotNull);
    expect(macOS, isNotNull);
    expect(macOS.runtimeType, windows.runtimeType);
  });
}

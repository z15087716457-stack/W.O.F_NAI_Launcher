import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_toggle.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_ui_theme.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'contained switch supports keyboard and selected emphasis in ${brightness.name}',
      (tester) async {
        var value = false;
        final theme = settingsUiTheme(
          AppTheme.getTheme(AppStyle.geist, brightness),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, update) => SettingsToggle(
                    value: value,
                    onChanged: (next) => update(() => value = next),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.getSize(find.byType(SettingsToggle)), const Size(42, 24));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(value, true);
        final style = theme.segmentedButtonTheme.style!;
        expect(
          style.foregroundColor!.resolve({WidgetState.selected}),
          theme.colorScheme.primary,
        );
        expect(
          style.backgroundColor!.resolve({WidgetState.selected}),
          isNot(style.backgroundColor!.resolve({})),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

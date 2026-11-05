import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_help_dialog.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_shortcuts.dart';

class _Config extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

void main() {
  testWidgets('settings help action opens the shortcut dialog', (t) async {
    t.view.physicalSize = const Size(1600, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ProviderScope(
        overrides: [shortcutConfigNotifierProvider.overrideWith(_Config.new)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => SettingsShortcutActions(context, ref).help(),
                child: const Text('Open shortcut help'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ShortcutHelpDialog), findsNothing);
    await t.tap(find.text('Open shortcut help'));
    await t.pumpAndSettle();
    expect(find.byType(ShortcutHelpDialog), findsOneWidget);
  });
}

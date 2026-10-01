import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/settings_font_scale_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/settings_typography_scope.dart';

class _Storage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

void main() {
  testWidgets(
    'settings scale follows dialogs and menus without enlarging workspace or nested dialogs twice',
    (tester) async {
      final storage = _Storage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageServiceProvider.overrideWithValue(storage)],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1)),
              child: child!,
            ),
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Workspace', key: Key('workspace')),
                  SettingsTypographyScope(
                    child: Builder(
                      builder: (context) => Column(
                        children: [
                          const Text('Settings', key: Key('settings')),
                          TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                content: TextButton(
                                  key: const Key('first-dialog'),
                                  onPressed: () => showDialog<void>(
                                    context: dialogContext,
                                    builder: (_) => const AlertDialog(
                                      content: Text(
                                        'Nested',
                                        key: Key('nested-dialog'),
                                      ),
                                    ),
                                  ),
                                  child: const Text('Nested dialog'),
                                ),
                              ),
                            ),
                            child: const Text('Open'),
                          ),
                          DropdownButton<String>(
                            value: 'a',
                            items: const [
                              DropdownMenuItem(
                                value: 'a',
                                child: Text('Option A'),
                              ),
                              DropdownMenuItem(
                                value: 'b',
                                child: Text('Option B'),
                              ),
                            ],
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      double scale(Key key) =>
          MediaQuery.textScalerOf(tester.element(find.byKey(key))).scale(10) /
          10;
      expect(scale(const Key('workspace')), 1);
      expect(scale(const Key('settings')), 1.1);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(scale(const Key('first-dialog')), 1.1);
      await tester.tap(find.text('Nested dialog'));
      await tester.pumpAndSettle();
      expect(scale(const Key('nested-dialog')), 1.1);
      Navigator.of(
        tester.element(find.byKey(const Key('nested-dialog'))),
      ).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byKey(const Key('first-dialog')))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.text('Option B').last),
        ).scale(10),
        closeTo(11, .001),
      );
      Navigator.of(tester.element(find.text('Option B').last)).pop();
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('workspace'))),
      );
      await container
          .read(settingsFontScaleProvider.notifier)
          .setFontScale(1.3);
      await tester.pumpAndSettle();
      expect(scale(const Key('settings')), closeTo(1.43, .001));
      expect(scale(const Key('workspace')), 1);
      expect(tester.takeException(), isNull);
    },
  );
}

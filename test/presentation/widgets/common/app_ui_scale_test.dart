import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/ui_scale_provider.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_scale.dart';
import 'package:nai_launcher/presentation/widgets/common/app_ui_scale.dart';

import '../../../core/settings/settings_preferences_service_test.dart'
    show MemoryStorage;

void main() {
  for (final dpr in [1.0, 2.0]) {
    for (final scale in [.8, 1.0, 1.3, 1.5]) {
      testWidgets(
        'whole viewport and pointer targets scale once at $scale / DPR $dpr',
        (t) async {
          t.view.devicePixelRatio = dpr;
          t.view.physicalSize = Size(1000 * dpr, 800 * dpr);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetPhysicalSize);
          var taps = 0;
          await t.pumpWidget(
            MaterialApp(
              builder: (_, child) => UiScale(scale: scale, child: child!),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 100,
                    height: 40,
                    child: GestureDetector(
                      key: const Key('target'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => taps++,
                      child: const Text('Scaled'),
                    ),
                  ),
                ),
              ),
            ),
          );
          final target = find.byKey(const Key('target'));
          final rect = t.getRect(target);
          final media = MediaQuery.of(t.element(target));
          expect(rect.width, closeTo(100 * scale, .001));
          expect(rect.height, closeTo(40 * scale, .001));
          expect(rect.right, closeTo(1000, .001));
          expect(rect.bottom, closeTo(800, .001));
          expect(media.size.width, closeTo(1000 / scale, .001));
          expect(media.devicePixelRatio, dpr);
          expect(media.textScaler.scale(10), 10);
          await t.tapAt(rect.center);
          expect(taps, 1);
          expect(t.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'changing scale retains a live dialog, draft and nested overlay',
    (t) async {
      final storage = MemoryStorage();
      final container = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      final draft = TextEditingController(text: 'unsaved draft');
      addTearDown(draft.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (_, child) => AppUiScale(child: child!),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      content: TextField(controller: draft),
                      actions: [
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: dialog,
                            builder: (_) => const AlertDialog(
                              content: Align(
                                widthFactor: 1,
                                heightFactor: 1,
                                child: SizedBox(
                                  key: Key('nested'),
                                  width: 100,
                                  height: 40,
                                ),
                              ),
                            ),
                          ),
                          child: const Text('Nested'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      final field = t.element(find.byType(TextField));
      await container.read(uiScaleProvider.notifier).setScale(1.3);
      await t.pumpAndSettle();
      expect(t.element(find.byType(TextField)), same(field));
      expect(draft.text, 'unsaved draft');
      expect(MediaQuery.textScalerOf(field).scale(10), 10);
      await t.tap(find.text('Nested'));
      await t.pumpAndSettle();
      expect(
        t.getRect(find.byKey(const Key('nested'))).width,
        closeTo(130, .001),
      );
      expect(t.takeException(), isNull);
    },
  );
}

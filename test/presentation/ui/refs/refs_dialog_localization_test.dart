import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'refs_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final width in [900.0, 1600.0]) {
        for (final scene in [
          'detail',
          'precise-detail',
          'bundle',
          'import',
          'export',
          'delete',
          'picker',
          'precise-picker',
        ]) {
          testWidgets('refs dialog $scene $locale $dark $width', (t) async {
            if (scene.endsWith('picker')) {
              final data = scene == 'picker'
                  ? RefsFixture.vibePicker()
                  : RefsFixture.precisePicker();
              t.view.devicePixelRatio = 1;
              t.view.physicalSize = Size(width - 48, 1000);
              addTearDown(t.view.reset);
              await t.pumpWidget(
                refsApp(
                  Center(
                    child: RefsPicker(
                      data: data,
                      actions: RefsPickerActions(
                        onConfirm: (_, {required replace}) {},
                        onClose: () {},
                        onOpenLibrary: () {},
                      ),
                    ),
                  ),
                  locale: locale,
                  dark: dark,
                ),
              );
              await precacheRefs(t, [for (final e in data.entries) ?e.thumb]);
              await tapKey(t, 'refs-picker-card-${data.entries[1].key}');
            } else {
              final data = scene == 'precise-detail'
                  ? RefsFixture.preciseView()
                  : RefsFixture.vibe(
                      selectedKey: scene == 'bundle' ? 'c14' : 'c11',
                      importDraft: scene == 'import'
                          ? RefsFixture.importDraft()
                          : null,
                    );
              await pumpRefs(
                t,
                data: data,
                locale: locale,
                dark: dark,
                window: width,
              );
              if (scene == 'detail' ||
                  scene == 'precise-detail' ||
                  scene == 'bundle') {
                await t.sendKeyEvent(LogicalKeyboardKey.space);
                await t.pumpAndSettle();
                expect(
                  find.byKey(
                    Key(scene == 'bundle' ? 'refs-bundle' : 'refs-detail'),
                  ),
                  findsOneWidget,
                );
              } else if (scene == 'export' || scene == 'delete') {
                await tapKey(t, 'refs-multi');
                await tapKey(t, 'refs-card-c03');
                await tapKey(t, 'refs-card-c15');
                await tapKey(t, 'refs-sel-$scene');
              }
            }
            if (scene == 'import') {
              expect(
                find.byKey(const Key('refs-import-dialog')),
                findsOneWidget,
              );
              for (final key in [
                'refs-import-summary',
                'refs-import-confirm',
              ]) {
                final rect = t.getRect(find.byKey(Key(key)));
                expect(rect.left, greaterThanOrEqualTo(0));
                expect(rect.right, lessThanOrEqualTo(width - 48));
                expect(rect.bottom, lessThanOrEqualTo(1000));
              }
            }
            expect(t.takeException(), isNull, reason: uiuxOverflowDetails(t));
            if (!dark &&
                width == 900 &&
                ['en', 'ja'].contains(locale) &&
                ['import', 'picker'].contains(scene)) {
              await captureUiuxRegion(
                t,
                find.byKey(const Key('refs-capture')),
                'refs-$scene-$locale',
                Rect.fromLTWH(0, 0, width - 48, 1000),
              );
            }
            await t.pumpWidget(const SizedBox());
            expect(t.takeException(), isNull);
          });
        }
      }
    }
  }
}

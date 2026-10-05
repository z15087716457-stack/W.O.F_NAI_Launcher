import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/edit_color_picker.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/edit_hsv_panel.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/edit_image_controls.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/edit_resize_dialog.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final width in [1440.0, 720.0, 390.0]) {
        testWidgets(
          'official edit controls ${locale.toLanguageTag()} $brightness $width',
          (tester) async {
            final size = Size(width, 900);
            await tester.binding.setSurfaceSize(size);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(() => tester.binding.setSurfaceSize(null));
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final input = await tester.runAsync(
              () => File('test/fixtures/edit_image_sample.png').readAsBytes(),
            );
            final boundary = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: RepaintBoundary(
                  key: boundary,
                  child: ImageEditorScreen(
                    initialImage: input,
                    debugDisableDropRegion: true,
                  ),
                ),
              ),
            );
            for (
              var i = 0;
              i < 100 && find.byType(EditToolSettings).evaluate().isEmpty;
              i++
            ) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 20)),
              );
              await tester.pump(const Duration(milliseconds: 30));
            }
            expect(find.byType(EditToolSettings), findsOneWidget);
            expect(tester.takeException(), isNull);
            final canvas = tester.widget<EditorCanvas>(
                  find.byType(EditorCanvas),
                ),
                state = canvas.state;
            expect(state.layerManager.layerCount, 1);
            expect(state.tools.map((t) => t.id), officialEditToolIds);
            Future<void> capture(String name) async {
              await tester.pump();
              expect(tester.takeException(), isNull);
              for (final glyph in find.byType(EditGlyph).evaluate()) {
                final r = tester.getRect(find.byWidget(glyph.widget));
                expect(r.left, greaterThanOrEqualTo(0));
                expect(r.right, lessThanOrEqualTo(width));
              }
              final root =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await root.toImage(pixelRatio: 1);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '.dart_tool/edit-image-official-20261005/captures/${locale.toLanguageTag()}_${brightness.name}_${width.round()}_$name.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }

            for (final tool in state.tools) {
              state.setTool(tool);
              await tester.pump();
              await capture(tool.id);
            }
            state.setToolById('brush');
            await tester.pump();
            await tester.tap(find.byType(EditColorControl));
            await tester.pump();
            expect(find.byType(EditColorPicker), findsOneWidget);
            final swatch = tester.getRect(
              find.byKey(const Key('edit_color_swatch')),
            );
            final popupIcon = tester.getRect(
              find.byKey(const Key('edit_color_popup_icon')),
            );
            expect(swatch.size, const Size(104, 40));
            expect(popupIcon.size, const Size(34, 34));
            expect(popupIcon.center.dy, swatch.center.dy);
            expect(swatch.right - popupIcon.right, 3);
            await capture('color');
            await tester.tapAt(Offset(width - 8, 250));
            await tester.pump();
            final hsv = find.byWidgetPredicate(
              (w) => w is EditButton && w.glyph == 'hsv',
            );
            await tester.tap(hsv);
            await tester.pump();
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)),
            );
            await tester.pump();
            expect(find.byType(EditHsvPanel), findsOneWidget);
            await capture('hsv');
            await tester.tapAt(Offset(width - 8, 250));
            await tester.pump();
            await capture('layers');
            await tester.tap(find.byKey(const Key('inpaint_layers')));
            await tester.pump();
            await tester.tap(find.byKey(const Key('inpaint_layers')));
            await tester.pump();
            final resize = find.byWidgetPredicate(
              (w) => w is EditButton && w.glyph == 'shift',
            );
            await tester.tap(resize);
            await tester.pump();
            expect(find.byType(EditResizeDialog), findsOneWidget);
            await capture('resize');
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 1));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

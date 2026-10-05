import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/layers/model3d_layer_data.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/inpaint_controls.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/model3d_editor/model3d_library_service.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'model3d_editor_screen_test.dart' show autoReplyBridge;

void main() {
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
          '3D official layout ${locale.toLanguageTag()} $brightness $width',
          (tester) async {
            final size = Size(width, 900);
            await tester.binding.setSurfaceSize(size);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(() => tester.binding.setSurfaceSize(null));
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final boundary = GlobalKey();
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: RepaintBoundary(
                  key: boundary,
                  child: Model3dEditorScreen(
                    renderWidth: 832,
                    renderHeight: 1216,
                    markReadyForTest: true,
                    libraryService: Model3dLibraryService(
                      libraryDir: Directory.systemTemp,
                    ),
                    existing: const Model3dLayerData(
                      modelRef: 'builtin:mannequin',
                      sceneState: {'version': 1},
                    ),
                    bridgeOverride: autoReplyBridge(),
                    viewportBuilder: (_) => const ColoredBox(
                      key: ValueKey('test-viewport'),
                      color: Color(0xff121316),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final l = AppLocalizations.of(
              tester.element(find.byType(Model3dEditorScreen)),
            )!;
            Future<void> capture(String name) async {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 50)),
              );
              await tester.pump();
              expect(tester.takeException(), isNull);
              for (final item in find.byType(InpaintPanel).evaluate()) {
                final rect = tester.getRect(find.byWidget(item.widget));
                expect(rect.left, greaterThanOrEqualTo(0));
                expect(rect.right, lessThanOrEqualTo(width + .01));
                expect(rect.bottom, lessThanOrEqualTo(900));
              }
              if (Platform.environment['CAPTURE_STUDIO_UI'] != '1') return;
              await tester.runAsync(() async {
                final box =
                    boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary;
                final image = await box.toImage(pixelRatio: 1);
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File(
                  '.dart_tool/model3d-official-20261005/captures/${locale.toLanguageTag()}_${brightness.name}_${width.round()}_$name.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }

            final top = tester.getRect(
              find.byKey(const ValueKey('model3d-top-settings')),
            );
            if (width >= 720) expect(top.height, 48);
            final canvas = tester.getRect(
              find.byKey(const ValueKey('test-viewport')),
            );
            expect(canvas.width / canvas.height, closeTo(832 / 1216, .001));
            expect(canvas.top, greaterThanOrEqualTo(top.bottom));
            await capture('transform');
            await tester.tap(find.byTooltip(l.model3d_modePose));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip(l.model3d_bones));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip(l.model3d_morphs));
            await tester.pumpAndSettle();
            expect(find.text('Hip'), findsOneWidget);
            expect(find.text('Smile'), findsOneWidget);
            await capture('pose-panels');
            await tester.tap(find.byTooltip(l.model3d_settings));
            await tester.pumpAndSettle();
            await capture('settings');
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}

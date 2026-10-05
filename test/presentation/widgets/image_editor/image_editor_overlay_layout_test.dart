import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/editor_quick_settings.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/toolbar/editor_overlay_toolbar.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/panels/inpaint_controls.dart';
import '../../../helpers/official_ui_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOfficialUiCaptureFonts);
  for (final size in [const Size(1440, 900), const Size(960, 600)]) {
    for (final mode in ImageEditorMode.values) {
      testWidgets(
        'editor overlays fit $size in $mode without reducing canvas area',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final input = img.Image(width: 192, height: 288);
          for (var y = 0; y < input.height; y++) {
            for (var x = 0; x < input.width; x++) {
              input.setPixelRgb(
                x,
                y,
                (x * 255 / input.width).round(),
                70,
                (y * 255 / input.height).round(),
              );
            }
          }
          final boundary = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                fontFamily: 'OfficialUiCapture',
              ),
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(
                key: boundary,
                child: ImageEditorScreen(
                  mode: mode,
                  debugDisableDropRegion: true,
                  initialImage: Uint8List.fromList(img.encodePng(input)),
                ),
              ),
            ),
          );
          for (var i = 0; i < 15; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)),
            );
            await tester.pump(const Duration(milliseconds: 60));
            if (find
                .byType(
                  mode == ImageEditorMode.inpaint
                      ? InpaintToolSettings
                      : EditorQuickSettings,
                )
                .evaluate()
                .isNotEmpty) {
              break;
            }
          }
          expect(find.byType(EditorCanvas), findsOneWidget);
          await tester.pump();
          expect(
            find.byType(
              mode == ImageEditorMode.inpaint
                  ? InpaintToolSettings
                  : EditorQuickSettings,
            ),
            findsOneWidget,
          );
          expect(tester.getSize(find.byType(EditorCanvas)), size);
          expect(
            tester
                .getSize(
                  find.byType(
                    mode == ImageEditorMode.inpaint
                        ? InpaintToolSettings
                        : EditorQuickSettings,
                  ),
                )
                .height,
            lessThan(140),
          );
          expect(
            find.byType(
              mode == ImageEditorMode.inpaint
                  ? InpaintToolbar
                  : EditorFloatingToolbar,
            ),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_OFFICIAL_UI'] == '1' &&
              size.width == 1440) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '.dart_tool/official-ui-captures/editor-${mode.name}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        },
      );
    }
  }
}

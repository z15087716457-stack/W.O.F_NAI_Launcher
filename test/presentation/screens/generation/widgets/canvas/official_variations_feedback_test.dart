import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_display_settings.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import '../../../../../helpers/studio_capture_fonts.dart';

class _Storage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] ?? defaultValue) as T?;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }

  @override
  bool getCanvasReducedMotion() => true;
  @override
  Set<String> getCanvasPinnedImages() => {};
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(model: 'nai-diffusion-5-full');
}

class _Generation extends ImageGenerationNotifier {
  _Generation(this.images);
  final List<GeneratedImage> images;
  @override
  ImageGenerationState build() => ImageGenerationState(history: images);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CAPTURE_OFFICIAL_FEEDBACK'] != '1') return;
  await tester.pump(const Duration(milliseconds: 16));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '.dart_tool/official-variations-feedback-20261006/captures/$name.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in [const Locale('zh'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'compact settings and original group fit very large images: $locale $brightness',
        (tester) async {
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = true);
          tester.view.physicalSize = const Size(920, 560);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final images = [
            for (var index = 0; index < 4; index++)
              GeneratedImage(
                id: 'image-$index',
                bytes: Uint8List.fromList(
                  img.encodePng(
                    img.fill(
                      img.Image(width: 64, height: 96),
                      color: [
                        img.ColorRgb8(176, 208, 224),
                        img.ColorRgb8(227, 181, 107),
                        img.ColorRgb8(156, 201, 164),
                        img.ColorRgb8(196, 179, 221),
                      ][index],
                    ),
                  ),
                ),
                width: 8320,
                height: 12160,
                generationRunId: 1,
                batchIndex: index - 1,
                isVariationOriginal: index == 0,
              ),
          ];
          final container = ProviderContainer(
            overrides: [
              localStorageServiceProvider.overrideWith((_) => _Storage()),
              generationParamsNotifierProvider.overrideWith(_Params.new),
              imageGenerationNotifierProvider.overrideWith(
                () => _Generation(images),
              ),
            ],
          );
          addTearDown(container.dispose);
          final key = GlobalKey();
          Widget app(Widget body) => UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: AppTheme.getTheme(AppStyle.geist, brightness),
              builder: (_, child) => RepaintBoundary(key: key, child: child!),
              home: Scaffold(body: body),
            ),
          );
          final id = '${locale.languageCode}-${brightness.name}';
          await tester.pumpWidget(
            app(
              const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CanvasDisplaySettingsButton(),
                ),
              ),
            ),
          );
          final l = lookupAppLocalizations(locale);
          await tester.tap(find.byTooltip(l.generation_canvasDisplaySettings));
          await tester.pumpAndSettle();
          final fill = find.byTooltip(l.generation_canvasZoomToFill);
          final background = find.byTooltip(l.generation_canvasBackground);
          final controls = find
              .ancestor(of: fill, matching: find.byType(Row))
              .first;
          final panel = tester.getRect(
            find.ancestor(of: controls, matching: find.byType(Material)).first,
          );
          final leftGap = tester.getRect(fill).left - panel.left;
          final rightGap = panel.right - tester.getRect(background).right;
          expect(rightGap, closeTo(leftGap, .5));
          expect(rightGap, lessThanOrEqualTo(8.5));
          await _capture(tester, key, '$id-settings');
          await tester.pumpWidget(
            app(
              GenerationCanvasView(
                generationState: container.read(
                  imageGenerationNotifierProvider,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future.wait([
              for (final element in find.byType(Image).evaluate())
                precacheImage((element.widget as Image).image, element),
            ]),
          );
          await tester.pumpAndSettle();
          expect(find.text(l.generation_variationOriginal), findsOneWidget);
          await _capture(tester, key, '$id-group');
          await tester.tap(find.byKey(const ValueKey('canvas-tile:run:1:0')));
          await tester.pumpAndSettle();
          final tile = tester.getRect(
            find.byKey(const ValueKey('canvas-tile:run:1:0')),
          );
          for (final zone in CanvasToolbarZone.values) {
            final bar = tester.getRect(
              find.byWidgetPredicate(
                (w) => w is CanvasEdgeToolbar && w.zone == zone,
              ),
            );
            if (zone == CanvasToolbarZone.top) {
              expect(tile.top, greaterThanOrEqualTo(bar.bottom + 7.5));
            } else {
              expect(tile.bottom, lessThanOrEqualTo(bar.top - 7.5));
            }
          }
          await _capture(tester, key, '$id-focus');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          debugDisableShadows = true;
        },
      );
    }
  }
}

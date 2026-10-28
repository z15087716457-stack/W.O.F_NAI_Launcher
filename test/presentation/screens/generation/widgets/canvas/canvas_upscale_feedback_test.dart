import '../../../../../helpers/grouped_canvas_batches.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_upscale_button.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_tool_panel.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/hinted_scroll_view.dart';
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
  bool getCanvasLockCamera() => false;
  @override
  Set<String> getCanvasPinnedImages() => {};
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    model: ImageModels.animeDiffusionV5Curated,
    prompt: 'draft',
    width: 832,
    height: 1216,
  );
}

class _Generation extends ImageGenerationNotifier {
  _Generation(this.image);
  final GeneratedImage image;
  @override
  ImageGenerationState build() => ImageGenerationState(history: [image]);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (Platform.environment['CAPTURE_CANVAS_FEEDBACK'] != '1') return;
  await tester.pump(const Duration(milliseconds: 16));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '.dart_tool/canvas-upscale-feedback-20261006/captures/$name.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Uint8List png;
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final fixture = img.Image(width: 1664, height: 2432);
    img.fill(fixture, color: img.ColorRgb8(176, 208, 224));
    for (final y in [0, 2292]) {
      for (final x in [0, 1524]) {
        img.fillRect(
          fixture,
          x1: x,
          y1: y,
          x2: x + 139,
          y2: y + 139,
          color: img.ColorRgb8(227, 181, 107),
        );
      }
    }
    png = Uint8List.fromList(img.encodePng(fixture));
  });

  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final width in [420.0, 1000.0]) {
        final id = '${locale.toString()}-${brightness.name}-${width.toInt()}';
        testWidgets(
          'focus bounds, advanced hints, enhance choices and stop layout: $id',
          (tester) async {
            debugDisableShadows = false;
            addTearDown(() => debugDisableShadows = true);
            tester.view.physicalSize = Size(width, 760);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final image = GeneratedImage(
              id: 'fixture',
              bytes: png,
              width: 1664,
              height: 2432,
              generationRunId: 1,
              batchIndex: 0,
              createdAt: DateTime(2026, 10, 6),
            );
            final container = ProviderContainer(
              overrides: [
                groupedCanvasBatchesOverride,
                localStorageServiceProvider.overrideWith((_) => _Storage()),
                generationParamsNotifierProvider.overrideWith(_Params.new),
                imageGenerationNotifierProvider.overrideWith(
                  () => _Generation(image),
                ),
                estimatedCostProvider.overrideWithValue(0),
                localUpscaleModelsProvider.overrideWith(
                  (_) async => [
                    for (final model in localUpscaleCatalog)
                      model.withInstalled(true),
                    for (final model in advancedUpscaleCatalog)
                      model.withInstalled(model.id == 'seedvr2-3b'),
                  ],
                ),
              ],
            );
            addTearDown(container.dispose);
            final capture = GlobalKey();
            var scale = 1.0;
            Widget app(Widget body) => UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                builder: (context, child) => RepaintBoundary(
                  key: capture,
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                ),
                home: Scaffold(body: body),
              ),
            );
            Widget canvas() => GenerationCanvasView(
              generationState: container.read(imageGenerationNotifierProvider),
            );
            void checkBounds() {
              final tile = tester.getRect(
                find.byKey(const ValueKey('canvas-tile:run:1:0')),
              );
              final top = tester.getRect(
                find.byWidgetPredicate(
                  (w) =>
                      w is CanvasEdgeToolbar && w.zone == CanvasToolbarZone.top,
                ),
              );
              final bottomStart = tester.getRect(
                find.byWidgetPredicate(
                  (w) =>
                      w is CanvasEdgeToolbar &&
                      w.zone == CanvasToolbarZone.bottomStart,
                ),
              );
              final bottomEnd = tester.getRect(
                find.byWidgetPredicate(
                  (w) =>
                      w is CanvasEdgeToolbar &&
                      w.zone == CanvasToolbarZone.bottomEnd,
                ),
              );
              expect(tile.top, greaterThanOrEqualTo(top.bottom + 7.5));
              expect(tile.bottom, lessThanOrEqualTo(bottomStart.top - 7.5));
              expect(tile.bottom, lessThanOrEqualTo(bottomEnd.top - 7.5));
              final viewport = tester.getRect(
                find.byType(GenerationCanvasView),
              );
              expect(tile.left, greaterThanOrEqualTo(viewport.left));
              expect(tile.right, lessThanOrEqualTo(viewport.right));
              expect(tile.center.dx, closeTo(viewport.center.dx, .5));
            }

            await tester.pumpWidget(app(canvas()));
            await tester.pumpAndSettle();
            checkBounds();
            await tester.tap(find.byKey(const ValueKey('canvas-tile:run:1:0')));
            await tester.pumpAndSettle();
            checkBounds();
            await _capture(tester, capture, '$id-focus');
            tester.view.physicalSize = Size(width, 560);
            scale = 1.5;
            await tester.pumpWidget(app(canvas()));
            await tester.pumpAndSettle();
            checkBounds();
            expect(tester.takeException(), isNull);
            await _capture(tester, capture, '$id-focus-resized');

            // Exercise the actual toolbar entry, whose source has already doubled.
            tester.view.physicalSize = Size(width, 760);
            scale = 1;
            await tester.pumpWidget(app(canvas()));
            await tester.pumpAndSettle();
            final l = lookupAppLocalizations(locale);
            await tester.tap(find.byTooltip(l.img2img_enhance));
            await tester.pumpAndSettle();
            final draft = container.read(generationParamsNotifierProvider);
            await tester.pumpWidget(app(const GenerationToolPanel()));
            await tester.pumpAndSettle();
            expect(find.text('1x'), findsOneWidget);
            expect(find.text('1.5x'), findsOneWidget);
            expect(find.text(l.img2img_enhanceMax), findsOneWidget);
            expect(
              container.read(generationParamsNotifierProvider),
              same(draft),
            );
            await _capture(tester, capture, '$id-enhance');
            final workflow = container.read(
              imageWorkflowControllerProvider.notifier,
            );
            workflow.closeTemporaryTool();
            workflow.updateLocalUpscaleModel('seedvr2-3b');
            await tester.pumpWidget(
              app(
                Align(
                  alignment: Alignment.topCenter,
                  child: CanvasUpscaleButton(image: image),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const Key('canvas-upscale-settings')));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('settings-scroll-down')),
              findsNothing,
            );
            await tester.tap(
              find.byKey(const ValueKey('seedvr2-advanced-toggle')),
            );
            await tester.pumpAndSettle();
            final arrow = find.byKey(const ValueKey('settings-scroll-down'));
            expect(arrow, findsOneWidget);
            final arrowRect = tester.getRect(arrow);
            final popoverRect = tester.getRect(
              find.byKey(const Key('canvas-upscale-popover')),
            );
            expect(arrowRect.top, greaterThanOrEqualTo(popoverRect.top));
            expect(arrowRect.bottom, lessThanOrEqualTo(popoverRect.bottom));
            await _capture(tester, capture, '$id-scroll-top');
            await tester.tap(arrow);
            await tester.pumpAndSettle();
            final vertical = tester
                .widgetList<SingleChildScrollView>(
                  find.descendant(
                    of: find.byType(HintedScrollView),
                    matching: find.byType(SingleChildScrollView),
                  ),
                )
                .firstWhere((w) => w.scrollDirection == Axis.vertical);
            expect(vertical.controller!.offset, greaterThan(0));
            vertical.controller!.jumpTo(
              vertical.controller!.position.maxScrollExtent,
            );
            await tester.pumpAndSettle();
            expect(arrow, findsNothing);
            await _capture(tester, capture, '$id-scroll-bottom');
            expect(tester.takeException(), isNull);
            workflow.openTemporaryTool(
              png,
              ImageWorkflowMode.enhance,
              enhanceUsesGenerationSize: true,
            );
            workflow.setEnhanceLocalUpscale();
            tester.view.physicalSize = Size(width, 560);
            await tester.pumpWidget(app(const GenerationToolPanel()));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('seedvr2-advanced-toggle')),
            );
            await tester.pumpAndSettle();
            expect(arrow, findsOneWidget);
            await _capture(tester, capture, '$id-enhance-local-scroll');
            final enhanceScroll = tester
                .widget<SingleChildScrollView>(
                  find
                      .descendant(
                        of: find.byType(HintedScrollView),
                        matching: find.byType(SingleChildScrollView),
                      )
                      .first,
                )
                .controller!;
            enhanceScroll.jumpTo(enhanceScroll.position.maxScrollExtent);
            await tester.pumpAndSettle();
            expect(arrow, findsNothing);
            workflow.closeTemporaryTool();
            tester.view.physicalSize = Size(width, 760);
            await tester.pumpWidget(
              app(
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GenerationCancelButton(
                      isUpscaling: true,
                      onCancel: () {},
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text(l.localUpscale_stop), findsOneWidget);
            await _capture(tester, capture, '$id-stop');
            await tester.pumpWidget(const SizedBox());
            debugDisableShadows = true;
          },
        );
      }
    }
  }
}

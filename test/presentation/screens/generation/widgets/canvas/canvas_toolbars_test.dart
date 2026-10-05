import 'package:flutter/gestures.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import '../../../../../helpers/studio_capture_fonts.dart';

GeneratedImage _img({required String id, int width = 832, int height = 1216}) {
  return GeneratedImage(
    id: id,
    bytes: Uint8List(0),
    width: width,
    height: height,
    createdAt: DateTime(2025, 1, 1),
    kind: GeneratedImageKind.completed,
    generationRunId: 1,
  );
}

CanvasFeedGroup _group(GeneratedImage img) => CanvasFeedGroup(
  key: 'run:1',
  runId: 1,
  tiles: [CanvasTileSpec.image(img)],
  requestedCount: 1,
);

Widget _wrap(Widget child, {Brightness? brightness, GlobalKey? captureKey}) {
  return ProviderScope(
    overrides: [
      localStorageServiceProvider.overrideWith((ref) => _FakeCanvasStorage()),
      generationParamsNotifierProvider.overrideWith(_ToolbarParams.new),
      localUpscaleModelsProvider.overrideWith((ref) async => []),
      estimatedCostProvider.overrideWithValue(7),
      imageUpscaleCostProvider.overrideWith((ref, image) => 7),
    ],
    child: MaterialApp(
      theme: brightness == null
          ? null
          : AppTheme.getTheme(AppStyle.geist, brightness),
      builder: captureKey == null
          ? null
          : (_, child) => RepaintBoundary(key: captureKey, child: child!),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (Platform.environment['GALLERY_FEEDBACK_CAPTURE'] == '1' ||
      Platform.environment['GALLERY_FOLLOWUP_CAPTURE'] == '1') {
    testWidgets(
      'real-font toolbar surfaces preserve controls with uniform tint in all zones',
      (tester) async {
        await tester.runAsync(loadStudioCaptureFonts);
        await tester.binding.setSurfaceSize(const Size(760, 420));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final folder = Directory(
          Platform.environment['GALLERY_FOLLOWUP_CAPTURE'] == '1'
              ? '.dart_tool/gallery-followup-captures'
              : '.dart_tool/gallery-feedback-captures',
        )..createSync(recursive: true);
        final oldShadows = debugDisableShadows;
        debugDisableShadows = false;
        addTearDown(() => debugDisableShadows = oldShadows);
        for (final brightness in Brightness.values) {
          final image = _img(id: 'capture');
          final key = GlobalKey();
          await tester.pumpWidget(
            _wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final zone in CanvasToolbarZone.values)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CanvasEdgeToolbar(
                        zone: zone,
                        image: image,
                        group: _group(image),
                        focus: null,
                      ),
                    ),
                ],
              ),
              brightness: brightness,
              captureKey: key,
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final rendered = await boundary.toImage(pixelRatio: 2);
            final bytes = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File(
              '${folder.path}/canvas-toolbars-${brightness.name}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            rendered.dispose();
          });
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        }
        debugDisableShadows = oldShadows;
      },
    );
  }

  group('CanvasEdgeToolbar', () {
    testWidgets('variation price remains and local upscale shows zero Anlas', (
      tester,
    ) async {
      final image = _img(id: 'quoted');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWith(
              (ref) => _FakeCanvasStorage(),
            ),
            generationParamsNotifierProvider.overrideWith(_ToolbarParams.new),
            localUpscaleModelsProvider.overrideWith((ref) async => []),
            imageVariationCostProvider(image).overrideWithValue(63),
            imageUpscaleCostProvider(image).overrideWithValue(1),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Center(
                child: CanvasEdgeToolbar(
                  zone: CanvasToolbarZone.top,
                  image: image,
                  group: _group(image),
                  focus: null,
                ),
              ),
            ),
          ),
        ),
      );
      for (final entry in {'variations': '63', 'upscale': '0'}.entries) {
        final pill = find.byKey(
          ValueKey('canvas-cost-nai-icon-${entry.key}.svg'),
        );
        final number = find.descendant(
          of: pill,
          matching: find.text(entry.value),
        );
        final icon = find.descendant(
          of: pill,
          matching: find.byType(SvgPicture),
        );
        expect(number, findsOneWidget);
        expect(icon, findsOneWidget);
        expect(
          tester.getRect(number).right,
          lessThan(tester.getRect(icon).left),
        );
        final picture = tester.widget<SvgPicture>(icon);
        expect(
          (picture.bytesLoader as SvgAssetLoader).assetName,
          'assets/icons/nai-icon-anlas.svg',
        );
        expect(tester.getSize(pill).height, lessThanOrEqualTo(26));
      }
      expect(
        find.byKey(const Key('canvas-upscale-local-cost')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('canvas-upscale-settings')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('canvas-cost-nai-icon-upscale.svg')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('top zone renders 8 icons + divider', (tester) async {
      final img = _img(id: 'a');
      await tester.pumpWidget(
        _wrap(
          CanvasEdgeToolbar(
            zone: CanvasToolbarZone.top,
            image: img,
            group: _group(img),
            focus: null,
          ),
        ),
      );
      expect(find.byType(SvgPicture), findsNWidgets(8));
      // Unknown variation metadata stays unquoted; local upscale costs zero.
      expect(
        find.byKey(const ValueKey('canvas-cost-nai-icon-variations.svg')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('canvas-cost-nai-icon-upscale.svg')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('canvas-upscale-local-cost')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('canvas-upscale-settings')), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('bottomStart renders WxH + settings + seed', (tester) async {
      final img = _img(id: 'a', width: 832, height: 1216);
      await tester.pumpWidget(
        _wrap(
          CanvasEdgeToolbar(
            zone: CanvasToolbarZone.bottomStart,
            image: img,
            group: _group(img),
            focus: null,
          ),
        ),
      );
      expect(find.text('832 × 1216'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets(
      'bottomEnd renders pin|copy|download|info without fake upload',
      (tester) async {
        final img = _img(id: 'a');
        await tester.pumpWidget(
          _wrap(
            CanvasEdgeToolbar(
              zone: CanvasToolbarZone.bottomEnd,
              image: img,
              group: _group(img),
              focus: null,
            ),
          ),
        );
        expect(find.byType(SvgPicture), findsNWidgets(4));
        expect(find.byTooltip('Upload to explore'), findsNothing);
      },
    );
  });

  testWidgets(
    'main toolbars stay on viewport edges through pan, zoom and resize',
    (tester) async {
      final windowCalls = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          windowCalls.add(call.method);
          if (call.method == 'isFullScreen') return false;
          return null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        ),
      );
      final image = GeneratedImage(
        id: 'viewport-toolbar-image',
        bytes: Uint8List.fromList(
          img.encodePng(img.Image(width: 1, height: 1)),
        ),
        width: 832,
        height: 1216,
        createdAt: DateTime(2025, 1, 1),
        kind: GeneratedImageKind.completed,
        generationRunId: 1,
      );
      final group = _group(image);
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _FakeCanvasStorage(),
          ),
          estimatedCostProvider.overrideWithValue(7),
          canvasFeedLayoutProvider.overrideWith(
            () => _FixedCanvasLayout(group),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(1200, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WindowChromeScope(
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.fromLTRB(200, 40, 150, 30),
                  child: GenerationCanvasView(
                    generationState: ImageGenerationState(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Rect barRect(CanvasToolbarZone zone) => tester.getRect(
        find.byWidgetPredicate((w) => w is CanvasEdgeToolbar && w.zone == zone),
      );
      void expectViewportAnchors() {
        final viewport = tester.getRect(find.byType(GenerationCanvasView));
        final top = barRect(CanvasToolbarZone.top);
        final left = barRect(CanvasToolbarZone.bottomStart);
        final right = barRect(CanvasToolbarZone.bottomEnd);
        expect(top.top, closeTo(viewport.top + 12, 0.01));
        expect(top.center.dx, closeTo(viewport.center.dx, 0.01));
        expect(left.left, closeTo(viewport.left + 12, 0.01));
        expect(left.bottom, closeTo(viewport.bottom - 12, 0.01));
        expect(right.right, closeTo(viewport.right - 12, 0.01));
        expect(right.bottom, closeTo(viewport.bottom - 12, 0.01));
        expect(left.right, lessThan(right.left));
        expect(tester.takeException(), isNull);
      }

      expectViewportAnchors();
      final viewport = tester.getRect(find.byType(GenerationCanvasView));
      final cameraBeforeDrag = container
          .read(generationCanvasCameraProvider)
          .offset;
      final windowDrag = await tester.startGesture(
        Offset(viewport.left + 20, viewport.top + 12),
        kind: PointerDeviceKind.touch,
      );
      await windowDrag.moveBy(const Offset(40, 24));
      await windowDrag.up();
      await tester.pump();
      expect(windowCalls, contains('startDragging'));
      expect(
        container.read(generationCanvasCameraProvider).offset,
        cameraBeforeDrag,
      );
      final initial = {
        for (final zone in CanvasToolbarZone.values) zone: barRect(zone),
      };
      final camera = container.read(generationCanvasCameraProvider.notifier);
      // Change real camera state far enough to move the selected tile off screen.
      camera.panBy(const Offset(600, -500));
      await tester.pump();
      for (final scale in [0.1, 0.5, 2.0, 8.0]) {
        camera.flyTo(CanvasCamera(offset: const Offset(180, 90), scale: scale));
        await tester.pump();
        expect(container.read(generationCanvasCameraProvider).scale, scale);
        for (final zone in CanvasToolbarZone.values) {
          expect(barRect(zone), initial[zone]);
        }
      }
      // The overlay must leave blank space available for canvas panning.
      final before = container.read(generationCanvasCameraProvider).offset;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byType(GenerationCanvasView)),
          scrollDelta: const Offset(0, 70),
        ),
      );
      await tester.pump();
      expect(
        container.read(generationCanvasCameraProvider).offset,
        before - const Offset(0, 70),
      );
      expectViewportAnchors();

      await tester.binding.setSurfaceSize(const Size(900, 650));
      await tester.pump();
      expectViewportAnchors();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

class _ToolbarParams extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();
}

class _FakeCanvasStorage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}

  @override
  bool getCanvasLockCamera() => false;

  @override
  bool getCanvasReducedMotion() => true;

  @override
  Set<String> getCanvasPinnedImages() => {};
}

class _FixedCanvasLayout extends CanvasFeedLayoutNotifier {
  _FixedCanvasLayout(this.group);
  final CanvasFeedGroup group;

  @override
  CanvasFeedLayoutResult build() {
    final layout = layoutCanvasFeed([group]);
    return CanvasFeedLayoutResult(
      items: layout.items,
      groups: [group],
      bounds: layout.bounds,
    );
  }
}

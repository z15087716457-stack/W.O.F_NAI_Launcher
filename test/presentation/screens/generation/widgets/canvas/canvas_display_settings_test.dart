import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_display_settings.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_image_background.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/widgets/color_picker.dart';

class _Storage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }

  @override
  bool getCanvasReducedMotion() => true;
}

class _Params extends GenerationParamsNotifier {
  _Params(this.model);
  final String model;
  @override
  ImageParams build() =>
      ImageParams(model: model, seed: 12345, prompt: 'keep draft');
}

Widget _app(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('gear anchors above button and V4 only exposes fit control', (
    tester,
  ) async {
    final storage = _Storage();
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith((ref) => storage),
        generationParamsNotifierProvider.overrideWith(
          () => _Params(ImageModels.animeDiffusionV4Curated),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _app(
        container,
        const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CanvasDisplaySettingsButton(),
          ),
        ),
      ),
    );
    final gear = find.byTooltip('画布显示');
    final anchor = tester.getRect(gear);
    await tester.tap(gear);
    await tester.pumpAndSettle();
    final fill = find.byTooltip('放大填充（允许 >100%）');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byTooltip('透明区域底色'), findsNothing);
    expect(find.text('平滑缩放（Ctrl+滚轮）'), findsNothing);
    expect(tester.getRect(fill).bottom, lessThan(anchor.top));
    await tester.tap(fill);
    await tester.pumpAndSettle();
    expect(container.read(canvasZoomToFillNotifierProvider), isTrue);
    expect(storage.values[StorageKeys.canvasZoomToFill], isTrue);
    await tester.tapAt(const Offset(400, 100));
    await tester.pumpAndSettle();
    expect(fill, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'V5 backdrop presets and custom picker preserve draft and persist',
    (tester) async {
      final storage = _Storage();
      ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          generationParamsNotifierProvider.overrideWith(
            () => _Params(ImageModels.animeDiffusionV5Full),
          ),
        ],
      );
      final container = makeContainer();
      final initialParams = container.read(generationParamsNotifierProvider);
      await tester.pumpWidget(
        _app(
          container,
          const Align(
            alignment: Alignment.bottomLeft,
            child: CanvasDisplaySettingsButton(),
          ),
        ),
      );
      await tester.tap(find.byTooltip('画布显示'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('透明区域底色'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('红色'));
      await tester.pumpAndSettle();
      expect(container.read(canvasImageBackgroundNotifierProvider), 'red');
      await tester.tap(find.byTooltip('自定义颜色'));
      await tester.pumpAndSettle();
      final picker = tester.widget<HSVColorPicker>(find.byType(HSVColorPicker));
      picker.onColorChanged(const Color(0xFF123456));
      await tester.pumpAndSettle();
      expect(container.read(canvasImageBackgroundNotifierProvider), '#123456');
      expect(container.read(generationParamsNotifierProvider), initialParams);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      final restored = makeContainer();
      addTearDown(restored.dispose);
      expect(restored.read(canvasImageBackgroundNotifierProvider), '#123456');
      storage.values[StorageKeys.canvasImageBackground] = 'invalid';
      restored.invalidate(canvasImageBackgroundNotifierProvider);
      expect(restored.read(canvasImageBackgroundNotifierProvider), 'checker');
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets(
    'background changes rendered transparent pixels, not image bytes',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => _Storage()),
        ],
      );
      addTearDown(container.dispose);
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 1, height: 1, numChannels: 4)),
      );
      final original = Uint8List.fromList(bytes);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        _app(
          container,
          Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 24,
                height: 24,
                child: ColoredBox(
                  color: Colors.yellow,
                  child: CanvasImageBackground(
                    child: Image.memory(bytes, fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<List<int>> pixel() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        return (await tester.runAsync(() async {
          final snapshot = await boundary.toImage(pixelRatio: 1);
          final data = await snapshot.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          snapshot.dispose();
          return data!.buffer.asUint8List().sublist(
            (12 * 24 + 12) * 4,
            (12 * 24 + 12) * 4 + 4,
          );
        }))!;
      }

      container.read(canvasImageBackgroundNotifierProvider.notifier).set('red');
      await tester.pump();
      expect(await pixel(), [255, 0, 0, 255]);
      container
          .read(canvasImageBackgroundNotifierProvider.notifier)
          .set('none');
      await tester.pump();
      expect(await pixel(), [255, 235, 59, 255]);
      expect(bytes, original);
    },
  );

  testWidgets(
    'fit toggle immediately refits current canvas without changing selection',
    (tester) async {
      final image = GeneratedImage(
        id: 'small',
        bytes: Uint8List.fromList(
          img.encodePng(img.Image(width: 32, height: 32)),
        ),
        width: 32,
        height: 32,
        generationRunId: 1,
      );
      final state = ImageGenerationState(history: [image]);
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => _Storage()),
          imageGenerationNotifierProvider.overrideWith(
            () => _Generation(state),
          ),
          estimatedCostProvider.overrideWithValue(0),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _app(container, GenerationCanvasView(generationState: state)),
      );
      await tester.pumpAndSettle();
      expect(container.read(generationCanvasCameraProvider).scale, 1);
      await tester.tap(find.byTooltip('画布显示'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('放大填充（允许 >100%）'));
      await tester.pumpAndSettle();
      expect(
        container.read(generationCanvasCameraProvider).scale,
        greaterThan(1),
      );
      await tester.tap(find.byTooltip('放大填充（允许 >100%）'));
      await tester.pumpAndSettle();
      expect(container.read(generationCanvasCameraProvider).scale, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

class _Generation extends ImageGenerationNotifier {
  _Generation(this.initial);
  final ImageGenerationState initial;
  @override
  ImageGenerationState build() => initial;
}

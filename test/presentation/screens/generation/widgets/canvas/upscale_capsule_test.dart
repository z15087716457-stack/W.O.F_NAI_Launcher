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
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_upscale_button.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_tool_panel.dart';
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
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    model: ImageModels.animeDiffusionV5Curated,
    prompt: 'current draft',
    width: 832,
    height: 1216,
  );
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Task extends LocalUpscaleTask {
  GeneratedImage? requested;
  int calls = 0;
  @override
  LocalUpscaleTaskState build() => const LocalUpscaleTaskState();
  @override
  Future<void> start({GeneratedImage? image}) async {
    requested = image;
    calls++;
  }
}

class _CloudTask extends CloudUpscaleTask {
  int calls = 0;
  @override
  CloudUpscaleState build() => const CloudUpscaleState();
  @override
  Future<void> start({GeneratedImage? image}) async {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final locale in const [
    Locale('zh'),
    Locale('zh', 'TW'),
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 920.0]) {
        final id = '${locale.toString()}-${brightness.name}-${width.toInt()}';
        testWidgets('split upscale and local enhance layout $id', (
          tester,
        ) async {
          final oldShadows = debugDisableShadows;
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = oldShadows);
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final task = _Task();
          final cloudTask = _CloudTask();
          final storage = _Storage();
          final container = ProviderContainer(
            overrides: [
              localStorageServiceProvider.overrideWithValue(storage),
              generationParamsNotifierProvider.overrideWith(_Params.new),
              imageGenerationNotifierProvider.overrideWith(_Generation.new),
              localUpscaleTaskProvider.overrideWith(() => task),
              cloudUpscaleTaskProvider.overrideWith(() => cloudTask),
              localUpscaleModelsProvider.overrideWith(
                (ref) async => [localUpscaleCatalog.first.withInstalled(true)],
              ),
            ],
          );
          addTearDown(container.dispose);
          final image = GeneratedImage.create(
            Uint8List.fromList(
              img.encodePng(img.Image(width: 1248, height: 1824)),
            ),
            width: 1248,
            height: 1824,
          );
          final draft = container.read(generationParamsNotifierProvider);
          final workflow = container.read(
            imageWorkflowControllerProvider.notifier,
          );
          final capture = GlobalKey();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (_, child) =>
                    RepaintBoundary(key: capture, child: child!),
                home: Scaffold(
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      const GenerationToolPanel(),
                      Positioned(
                        top: 24,
                        left: (width - 72) / 2,
                        child: CanvasUpscaleButton(image: image),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(CanvasUpscaleButton)),
          )!;
          await tester.tap(find.byKey(const Key('canvas-upscale-settings')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('canvas-upscale-popover')),
            findsOneWidget,
          );
          expect(
            tester.getRect(find.byKey(const Key('canvas-upscale-popover'))).top,
            greaterThanOrEqualTo(
              tester
                  .getRect(find.byKey(const Key('canvas-upscale-settings')))
                  .bottom,
            ),
          );
          expect(
            find.byKey(const Key('generation-tool-surface')),
            findsNothing,
          );
          expect(find.text(l.img2img_startUpscale), findsNothing);
          expect(task.calls, 0);
          final inset = find.byKey(const ValueKey('canvas-upscale-inset'));
          expect(inset, findsOneWidget);
          expect(tester.getSize(inset).height, lessThanOrEqualTo(26));
          final dropdown = tester.widget<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          );
          expect(dropdown.style!.fontSize, 12);
          expect(
            tester
                .renderObject<RenderParagraph>(
                  find.text(l.img2img_upscaleRegularModel),
                )
                .didExceedMaxLines,
            isFalse,
          );
          expect(container.read(generationParamsNotifierProvider), same(draft));
          if (Platform.environment['CAPTURE_UPSCALE_CONTROLS'] == '1') {
            await _capture(tester, capture, '$id-upscale');
          }
          await tester.tap(find.text('NovelAI'));
          await tester.pumpAndSettle();
          expect(find.text(l.upscale_cloudCost(3)), findsOneWidget);
          final cloudBadge = find.byKey(
            const ValueKey('canvas-cost-nai-icon-upscale.svg'),
          );
          expect(cloudBadge, findsOneWidget);
          expect(
            find.descendant(of: cloudBadge, matching: find.text('3')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: cloudBadge, matching: find.byType(SvgPicture)),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('canvas-upscale-infinity')),
            findsNothing,
          );
          expect(cloudTask.calls, 0);
          if (Platform.environment['CAPTURE_UPSCALE_CONTROLS'] == '1') {
            await _capture(tester, capture, '$id-cloud');
          }
          expect(task.calls, 0);
          await tester.tap(find.text(l.localUpscale_local));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('canvas-upscale-infinity')),
            findsOneWidget,
          );
          expect(cloudBadge, findsNothing);
          await tester.tapAt(const Offset(4, 790));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('canvas-upscale-popover')), findsNothing);
          await tester.tap(find.byKey(const Key('canvas-upscale-execute')));
          await tester.pumpAndSettle();
          expect(task.calls, 1);
          expect(task.requested, same(image));
          expect(container.read(generationParamsNotifierProvider), same(draft));
          expect(
            container.read(imageWorkflowControllerProvider).isUpscale,
            isFalse,
          );
          workflow.openTemporaryTool(
            Uint8List.fromList(
              img.encodePng(img.Image(width: 832, height: 1216)),
            ),
            ImageWorkflowMode.enhance,
          );
          await tester.pumpAndSettle();
          expect(find.text(l.img2img_enhanceMax), findsOneWidget);
          expect(find.text('1.5x'), findsOneWidget);
          expect(
            tester.getTopLeft(find.text('1.5x')).dy,
            closeTo(tester.getTopLeft(find.text(l.localUpscale_local)).dy, 1),
          );
          await tester.tap(find.text(l.localUpscale_local));
          await tester.pumpAndSettle();
          expect(find.text(l.enhance_localAfterGeneration), findsOneWidget);
          expect(find.text(l.img2img_showAdvanced), findsNothing);
          expect(
            container.read(generationRequestParamsProvider).width,
            draft.width,
          );
          expect(
            container.read(generationRequestParamsProvider).sourceImage,
            isNull,
          );
          expect(container.read(generationParamsNotifierProvider), same(draft));
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_UPSCALE_CONTROLS'] == '1') {
            await _capture(tester, capture, '$id-enhance');
          }
          await tester.tap(find.text('SeedVR2'));
          await tester.pumpAndSettle();
          expect(
            container.read(imageWorkflowControllerProvider).upscale.localModel,
            'seedvr2-3b',
          );
          expect(
            task.calls,
            1,
            reason: 'Changing the scheme never starts inference or a download',
          );
          await tester.tap(find.byTooltip(l.common_close));
          await tester.pumpAndSettle();
          expect(
            container.read(imageWorkflowControllerProvider).isEnhance,
            isFalse,
          );
          expect(container.read(generationParamsNotifierProvider), same(draft));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          debugDisableShadows = oldShadows;
        });
      }
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String id) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final pixels = await boundary.toImage();
    final bytes = await pixels.toByteData(format: ui.ImageByteFormat.png);
    final directory =
        Platform.environment['UPSCALE_CAPTURE_DIRECTORY'] ??
        '.dart_tool/upscale-controls-20261005/captures';
    final file = File('$directory/$id.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    pixels.dispose();
  });
}

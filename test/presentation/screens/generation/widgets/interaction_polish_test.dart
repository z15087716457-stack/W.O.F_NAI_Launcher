import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_position_canvas_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_param_sections.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/image_preview.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_sidebar_style.dart';
import 'package:nai_launcher/presentation/widgets/character/character_position_canvas.dart';
import '../../../../helpers/light_theme_contrast.dart';
import '../../../../helpers/official_ui_capture_fonts.dart';

class _Storage extends InMemoryLocalStorageService {
  @override
  String getDefaultModel() => 'nai-diffusion-5-full';
}

class _Repository extends CharacterPromptRepository {
  CharacterPromptConfig config = const CharacterPromptConfig().addCharacter(
    gender: CharacterGender.male,
    prompt: 'boy, blue hair',
  );
  @override
  CharacterPromptConfig load() => config;
  @override
  Future<bool> save(CharacterPromptConfig next) async {
    config = next;
    return true;
  }
}

final _image = GeneratedImage(
  id: 'existing-history',
  bytes: img.encodePng(
    img.fill(
      img.Image(width: 4, height: 4),
      color: img.ColorRgb8(240, 200, 120),
    ),
  ),
  width: 1216,
  height: 832,
);

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => ImageGenerationState(history: [_image]);
  void replace(ImageGenerationState next) => state = next;
}

class _Viewer extends SimpleOutputViewerNotifier {
  _Viewer(this.simple);
  final bool simple;
  @override
  bool build() => simple;
}

Widget _app(
  ProviderContainer container,
  Widget body, {
  Locale locale = const Locale('zh'),
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: officialUiCaptureTheme(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: body),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey boundary) async {
  return (await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (Platform.environment['CAPTURE_OFFICIAL_UI'] != '1') return;
  final bytes = await _pixels(tester, boundary);
  await tester.runAsync(() async {
    final file = File('.dart_tool/interaction-polish-captures/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadOfficialUiCaptureFonts);

  for (final simple in [false, true]) {
    testWidgets(
      'position editor opens over existing output, drags and finishes (simple=$simple)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1100, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = _Repository();
        final container = createStorageFreeContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(_Storage()),
            characterPromptRepositoryProvider.overrideWithValue(repository),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            simpleOutputViewerNotifierProvider.overrideWith(
              () => _Viewer(simple),
            ),
            imageUpscaleCostProvider(_image).overrideWithValue(7),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(generationPreviewSelectionProvider.notifier)
            .select(_image.id);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          _app(
            container,
            RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: officialUiCaptureTheme().colorScheme.surface,
                child: const Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CharacterPositionModeSegments(expanded: true),
                      ),
                    ),
                    Expanded(child: ImagePreviewWidget()),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!simple) expect(find.byType(GenerationCanvasView), findsOneWidget);
        final customGroup = find.byKey(
          const ValueKey('character-position-custom-group'),
        );
        final iconEntry = find.byKey(
          const ValueKey('character-position-toggle'),
        );
        expect(tester.widget<Material>(customGroup).color, Colors.transparent);
        expect(
          tester.widget<SidebarSegmentButton>(iconEntry).selected,
          isFalse,
        );
        await tester.tap(
          find.byKey(const ValueKey('character-position-custom')),
        );
        await tester.pumpAndSettle();
        expect(container.read(characterPositionCanvasProvider), isFalse);
        expect(
          tester.widget<Material>(customGroup).color,
          isNot(Colors.transparent),
        );
        expect(
          tester.widget<SidebarSegmentButton>(iconEntry).selected,
          isFalse,
        );
        await tester.tap(iconEntry);
        await tester.pumpAndSettle();
        expect(find.byType(CharacterPositionCanvasView), findsOneWidget);
        expect(find.byType(GenerationCanvasView), findsNothing);
        expect(
          container.read(characterPromptNotifierProvider).globalAiChoice,
          isFalse,
        );
        final character = container
            .read(characterPromptNotifierProvider)
            .characters
            .single;
        final before = character.customPosition!;
        final anchor = find.byKey(ValueKey('canvas-anchor-${character.id}'));
        expect(tester.widget<SidebarSegmentButton>(iconEntry).selected, isTrue);
        expect(
          find.byKey(const ValueKey('character-position-dim')),
          findsOneWidget,
        );
        expect(find.text('blue hair'), findsNothing);
        expect(find.text('Character 1'), findsNothing);
        expect(find.byIcon(Icons.male), findsOneWidget);
        // Verify rendered contrast: the image dims but the white marker does not.
        final backgroundWidget = find.descendant(
          of: find.byKey(const ValueKey('character-position-surface')),
          matching: find.byType(Image),
        );
        await tester.runAsync(
          () => precacheImage(
            tester.widget<Image>(backgroundWidget).image,
            tester.element(backgroundWidget),
          ),
        );
        await tester.pumpAndSettle();
        final rendered = img.decodePng(await _pixels(tester, boundary))!;
        final surface = tester.getRect(
          find.byKey(const ValueKey('character-position-surface')),
        );
        final background = rendered.getPixel(
          surface.left.toInt() + 30,
          surface.top.toInt() + 30,
        );
        expect(background.r, closeTo(84, 3));
        expect(background.g, closeTo(70, 3));
        final anchorCenter = tester.getCenter(anchor);
        final marker = rendered.getPixel(
          anchorCenter.dx.toInt() + 7,
          anchorCenter.dy.toInt(),
        );
        expect(marker.r, greaterThan(235));
        final drag = await tester.startGesture(tester.getCenter(anchor));
        await drag.moveBy(const Offset(90, -45));
        await tester.pump();
        await drag.moveBy(const Offset(30, -15));
        await tester.pump();
        container
            .read(characterPromptNotifierProvider.notifier)
            .updateCharacter(
              character.copyWith(prompt: 'boy, updated prompt during drag'),
            );
        await tester.pump();
        await drag.up();
        await tester.pumpAndSettle();
        final moved = container
            .read(characterPromptNotifierProvider)
            .characters
            .single;
        expect(moved.customPosition!.column, greaterThan(before.column));
        expect(moved.customPosition!.row, lessThan(before.row));
        expect(moved.prompt, 'boy, updated prompt during drag');
        expect(
          repository.config.characters.single.customPosition,
          moved.customPosition,
        );
        await _capture(tester, boundary, 'character-positions');
        await tester.tap(
          find.byKey(const ValueKey('finish-character-positions')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CharacterPositionCanvasView), findsNothing);
        expect(container.read(characterPositionCanvasProvider), isFalse);
        expect(
          find.byKey(const ValueKey('character-position-dim')),
          findsNothing,
        );
        expect(
          tester.widget<SidebarSegmentButton>(iconEntry).selected,
          isFalse,
        );
        expect(
          tester.widget<Material>(customGroup).color,
          isNot(Colors.transparent),
        );
        if (!simple) expect(find.byType(GenerationCanvasView), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('character-position-toggle')),
        );
        await tester.pumpAndSettle();
        expect(
          container
              .read(characterPromptNotifierProvider)
              .characters
              .single
              .customPosition,
          moved.customPosition,
        );
        await tester.tap(find.byKey(const ValueKey('character-position-ai')));
        await tester.pumpAndSettle();
        expect(find.byType(CharacterPositionCanvasView), findsNothing);
        expect(tester.widget<Material>(customGroup).color, Colors.transparent);
        expect(
          tester.widget<SidebarSegmentButton>(iconEntry).selected,
          isFalse,
        );
        await tester.tap(iconEntry);
        await tester.pumpAndSettle();
        expect(
          container.read(characterPromptNotifierProvider).globalAiChoice,
          isFalse,
        );
        // Generation still takes precedence and disables the position entry.
        (container.read(imageGenerationNotifierProvider.notifier)
                as _Generation)
            .replace(
              ImageGenerationState(
                status: GenerationStatus.generating,
                history: [_image],
                totalImages: 1,
                currentImage: 1,
                batchWidth: 512,
                batchHeight: 768,
              ),
            );
        await tester.pump();
        expect(container.read(characterPositionCanvasProvider), isFalse);
        expect(find.byType(CharacterPositionCanvasView), findsNothing);
        await tester.tap(
          find.byKey(const ValueKey('character-position-toggle')),
        );
        await tester.pump();
        expect(container.read(characterPositionCanvasProvider), isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  for (final width in [280.0, 400.0]) {
    testWidgets(
      'segments visibly hover without selecting, stop fills slot at $width',
      (tester) async {
        final container = createStorageFreeContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(_Storage()),
            characterPromptRepositoryProvider.overrideWithValue(_Repository()),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            imageVariationCostProvider(_image).overrideWithValue(63),
            imageUpscaleCostProvider(_image).overrideWithValue(7),
          ],
        );
        addTearDown(container.dispose);
        final boundary = GlobalKey();
        final group = CanvasFeedGroup(
          key: 'test',
          runId: 1,
          tiles: [CanvasTileSpec.image(_image)],
          requestedCount: 1,
        );
        var cancelled = 0;
        await tester.pumpWidget(
          _app(
            container,
            Center(
              child: SizedBox(
                width: width,
                child: RepaintBoundary(
                  key: boundary,
                  child: ColoredBox(
                    color: officialUiCaptureTheme().colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CharacterPositionModeSegments(expanded: true),
                          const SizedBox(height: 16),
                          const ImageCountSection(),
                          const SizedBox(height: 16),
                          GenerationCancelButton(onCancel: () => cancelled++),
                          const SizedBox(height: 16),
                          CanvasEdgeToolbar(
                            zone: CanvasToolbarZone.top,
                            image: _image,
                            group: group,
                            focus: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        for (final key in ['character-position-custom', 'image-count-3']) {
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle();
          final before = await _pixels(tester, boundary);
          await mouse.moveTo(tester.getCenter(find.byKey(ValueKey(key))));
          await tester.pumpAndSettle();
          final hover = await _pixels(tester, boundary);
          expect(
            hover,
            isNot(equals(before)),
            reason: '$key must visibly respond to hover',
          );
          expect(
            container.read(characterPromptNotifierProvider).globalAiChoice,
            isTrue,
          );
          expect(container.read(imagesPerRequestProvider), 1);
        }
        await tester.tap(
          find.byKey(const ValueKey('character-position-custom')),
        );
        await tester.tap(find.byKey(const ValueKey('image-count-3')));
        await tester.pumpAndSettle();
        expect(
          container.read(characterPromptNotifierProvider).globalAiChoice,
          isFalse,
        );
        expect(container.read(imagesPerRequestProvider), 3);
        final stop = find.byKey(const ValueKey('stop-generation'));
        expect(tester.getSize(stop), Size(width - 16, 48));
        final bounds = tester.getRect(stop);
        await tester.tapAt(Offset(bounds.left + 4, bounds.center.dy));
        await tester.tapAt(Offset(bounds.right - 4, bounds.center.dy));
        expect(cancelled, 2);
        expect(find.byIcon(Icons.skip_next), findsNothing);
        await mouse.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        await _capture(tester, boundary, 'controls-$width');
        expect(tester.takeException(), isNull);
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_module_card.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/img2img_panel.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/unified_reference_panel.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/precise_reference_panel.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/collapsible_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_glass_surface.dart';
import '../../../../helpers/studio_capture_fonts.dart';
import '../../../../helpers/light_theme_contrast.dart';

class _Params extends GenerationParamsNotifier {
  _Params(this.initial);
  final ImageParams initial;
  @override
  ImageParams build() {
    super.build();
    return initial;
  }

  @override
  Future<void> restoreGenerationState() async {}
}

class _EmptyLibrary extends VibeLibraryStorageService {
  @override
  Future<List<VibeLibraryEntry>> getRecentDisplayEntries({
    int limit = 20,
  }) async => [];
}

ProviderContainer referenceContainer(ImageParams initial) =>
    createStorageFreeContainer(
      overrides: [
        generationParamsNotifierProvider.overrideWith(() => _Params(initial)),
        vibeLibraryStorageServiceProvider.overrideWithValue(_EmptyLibrary()),
      ],
    );
Widget referenceShell(
  ProviderContainer container, {
  double width = 420,
  String language = 'zh',
  bool dark = false,
  bool highContrast = false,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    key: ValueKey('$language-$dark-$width-$highContrast'),
    theme: dark ? GeistTheme.dark : GeistTheme.light,
    themeAnimationDuration: Duration.zero,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: RepaintBoundary(
        key: const Key('capture'),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(highContrast: highContrast),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: GenerationModuleCard(
                      key: const Key('module'),
                      title: AppLocalizations.of(context)!.gen_refs,
                      children: const [
                        ReferenceModuleScope(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Img2ImgPanel(),
                              UnifiedReferencePanel(),
                              PreciseReferencePanel(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
void prepareGenerationDropTestPlatform() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final drag = MockMessageChannelContext()
    ..registerMockMethodCallHandler('DropManager', (_) async => null)
    ..registerMockMethodCallHandler('DragManager', (_) async => null);
  setContextOverride(drag);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
}

void main() {
  prepareGenerationDropTestPlatform();
  setUpAll(loadStudioCaptureFonts);
  testWidgets('switching models removes whole rows and their dividers', (
    tester,
  ) async {
    final container = referenceContainer(
      const ImageParams(model: 'nai-diffusion-5-full'),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(referenceShell(container));
    await tester.pumpAndSettle();
    for (final entry in [
      ('nai-diffusion-5-full', 1),
      ('nai-diffusion-4-5-full', 3),
      ('nai-diffusion-4-full', 2),
      ('nai-diffusion-3', 2),
      ('nai-diffusion-5-curated', 1),
    ]) {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(entry.$1, persist: false);
      await tester.pumpAndSettle();
      expect(find.byType(GenerationModuleRow), findsNWidgets(entry.$2));
      expect(
        tester.getSize(find.byKey(const Key('module'))).height,
        40 + 46 * entry.$2,
      );
      expect(find.byType(Card), findsNothing);
      expect(find.byType(StudioGlassSurface), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'embedded header actions do not expand; loaded background ends on expansion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final bytes = File(
        '../../mockups/generation/assets/g07.jpg',
      ).readAsBytesSync();
      final container = referenceContainer(
        ImageParams(model: 'nai-diffusion-4-5-full', sourceImage: bytes),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(referenceShell(container, width: 352));
      await tester.pumpAndSettle();
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('图生图'),
          matching: find.byType(ImageFiltered),
        ),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('precise-ref-panel-add-menu')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CollapsibleImagePanel>(
              find.byType(CollapsibleImagePanel).last,
            )
            .isExpanded,
        isFalse,
      );
      await tester.tapAt(const Offset(700, 550));
      await tester.pumpAndSettle();
      await tester.tap(find.text('图生图'));
      await tester.pumpAndSettle();
      expect(
        container.read(draftImageWorkflowProvider).isPanelExpanded,
        isTrue,
      );
      expect(find.byType(ImageFiltered), findsNothing);
      await tester.tap(find.text('图生图'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        referenceShell(container, width: 352, highContrast: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ImageFiltered), findsNothing);
      await tester.tap(find.byKey(const Key('img2img-action-clear')));
      await tester.pumpAndSettle();
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        isNull,
      );
      expect(
        container.read(draftImageWorkflowProvider).isPanelExpanded,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
  if (Platform.environment['CAPTURE_UIUX_REFERENCE'] == '1') {
    testWidgets(
      'capture real reference rows across languages, widths, models and expansion',
      (tester) async {
        final root = Directory('.dart_tool/uiux-task03/captures')
          ..createSync(recursive: true);
        final measurements = <Map<String, Object?>>[];
        final images = ['g07', 'g46']
            .map(
              (name) => File(
                '../../mockups/generation/assets/$name.jpg',
              ).readAsBytesSync(),
            )
            .toList();
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final language in ['zh', 'en', 'ja', 'ko']) {
          for (final dark in [false, true]) {
            for (final width in [352.0, 420.0]) {
              for (final model in [
                'nai-diffusion-5-full',
                'nai-diffusion-4-5-full',
              ]) {
                for (final mode in ['empty', 'vibe', 'expanded']) {
                  if (model.startsWith('nai-diffusion-5') && mode == 'vibe') {
                    continue;
                  }
                  tester.view.physicalSize = Size(width, 1000);
                  final container = referenceContainer(
                    ImageParams(
                      model: model,
                      vibeReferencesV4: mode == 'vibe'
                          ? [
                              for (var i = 0; i < 2; i++)
                                VibeReference(
                                  displayName: 'prototype-$i',
                                  vibeEncoding: '',
                                  rawImageData: images[i],
                                  thumbnail: images[i],
                                ),
                            ]
                          : [],
                    ),
                  );
                  if (mode == 'expanded') {
                    container
                        .read(imageWorkflowControllerProvider.notifier)
                        .setPanelExpanded(true);
                  }
                  await tester.pumpWidget(
                    referenceShell(
                      container,
                      width: width,
                      language: language,
                      dark: dark,
                    ),
                  );
                  await tester.pumpAndSettle();
                  for (final image in tester.widgetList<Image>(
                    find.byType(Image),
                  )) {
                    await tester.runAsync(
                      () => precacheImage(
                        image.image,
                        tester.element(find.byWidget(image)),
                      ),
                    );
                  }
                  await tester.pump();
                  expect(tester.takeException(), isNull);
                  final rect = tester.getRect(find.byKey(const Key('module')));
                  final name =
                      'reference-${model.startsWith('nai-diffusion-5') ? 'v5' : 'v45'}-$mode-$language-${dark ? 'dark' : 'light'}-${width.toInt()}';
                  measurements.add({
                    'name': name,
                    'model': model,
                    'mode': mode,
                    'locale': language,
                    'dark': dark,
                    'module': {
                      'x': rect.left,
                      'y': rect.top,
                      'width': rect.width,
                      'height': rect.height,
                    },
                  });
                  await tester.runAsync(() async {
                    final image = await tester
                        .renderObject<RenderRepaintBoundary>(
                          find.byKey(const Key('capture')),
                        )
                        .toImage(pixelRatio: 1);
                    try {
                      final data = await image.toByteData(
                        format: ui.ImageByteFormat.png,
                      );
                      File(
                        '${root.path}/$name.png',
                      ).writeAsBytesSync(data!.buffer.asUint8List());
                    } finally {
                      image.dispose();
                    }
                  });
                  await tester.pumpWidget(const SizedBox());
                  await tester.pumpAndSettle();
                  container.dispose();
                }
              }
            }
          }
        }
        File(
          '.dart_tool/uiux-task03/capture-measurements.json',
        ).writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(measurements),
        );
      },
    );
  }
}

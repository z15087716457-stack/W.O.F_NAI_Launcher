import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// Existing drag/drop dependencies expose this test transport.
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/image/image_params.dart'
    hide CharacterPrompt;
import 'package:nai_launcher/data/models/prompt/prompt_preset_mode.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/generation_screen.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_module_card.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_param_sections.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/prompt_input.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/web_left_panel.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/parameter_panel.dart';
import 'package:nai_launcher/presentation/screens/style_explore/style_explore_screen.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/character/inline_character_section.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_glass_surface.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import '../../../../helpers/light_theme_contrast.dart';
import '../../../../helpers/studio_capture_fonts.dart';
import '../../../widgets/character/character_module_test.dart'
    show prototypeCharacterPrompt;
import 'history_panel_capture_test.dart'
    show
        HistoryCaptureStorage,
        historyCaptureImages,
        prepareHistoryCaptureImages;

const _basePrompt =
    'scenery,panorama,from behind,green theme, blue theme, plant,\n'
    'detailed background,(extremely vibrant colors), magical atmosphere, dynamic composition,sitting,wide shot, white dress,blue flower,frilled dress,giant,0.8::artist:sincos::\n\n'
    'artist:asteroid_ill,candid,,year 2025, very aesthetic, masterpiece,sketch,lineart,solo, very aesthetic, masterpiece, no text';

class _Storage extends HistoryCaptureStorage {
  _Storage(this.model);
  final String model;
  @override
  String getDefaultModel() => model;
  @override
  String getLastPrompt() => _basePrompt;
  @override
  bool getEnableAutocomplete() => false;
  @override
  bool getEnableCooccurrenceRecommendation() => false;
  @override
  bool getCanvasReducedMotion() => true;
  @override
  int getQualityPresetMode() => PromptPresetMode.none.index;
}

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

class _Characters extends CharacterPromptRepository {
  @override
  CharacterPromptConfig load() => const CharacterPromptConfig(
    characters: [
      CharacterPrompt(
        id: 'prototype-character',
        name: '',
        prompt: prototypeCharacterPrompt,
      ),
    ],
  );
  @override
  Future<bool> save(CharacterPromptConfig config) async => true;
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

class _Vibes extends VibeLibraryStorageService {
  @override
  Future<List<VibeLibraryEntry>> getRecentDisplayEntries({
    int limit = 20,
  }) async => [];
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 2218),
      usage: OpusUsage(percent: 147),
    ),
  );
}

class _RunList extends ExploreRunListNotifier {
  @override
  Future<ExploreRunListState> build() async => ExploreRunListState(runs: []);
}

class _RunStorage extends StyleExploreRunStorage {
  @override
  Future<void> init() async {}
  @override
  Future<List<ExploreRun>> getRuns() async => [];
  @override
  Future<ExploreRun?> getRun(String id) async => null;
}

class _Tokens implements PromptTokenEncoder {
  @override
  Future<int> countTokens(String text) async =>
      text == prototypeCharacterPrompt ? 46 : 220;
}

ProviderContainer _container(String model) {
  final params = ImageParams(
    model: model,
    prompt: _basePrompt,
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5,
    seed: 3274348526,
    sampler: Samplers.kDpmpp2mSde,
    qualityTagPreset: QualityTagPreset.none,
    qualityToggle: false,
    vibeReferencesV4: model == 'nai-diffusion-4-5-full'
        ? [
            for (final file in ['g07', 'g46'])
              VibeReference(
                displayName: file,
                vibeEncoding: 'fixture',
                thumbnail: File(
                  '../../mockups/generation/assets/$file.jpg',
                ).readAsBytesSync(),
                sourceType: VibeSourceType.png,
              ),
          ]
        : [],
  );
  final container = createStorageFreeContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(_Storage(model)),
      generationParamsNotifierProvider.overrideWith(() => _Params(params)),
      characterPromptRepositoryProvider.overrideWithValue(_Characters()),
      promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
      vibeLibraryStorageServiceProvider.overrideWithValue(_Vibes()),
      subscriptionNotifierProvider.overrideWith(_Subscription.new),
      promptTokenCounterServiceProvider.overrideWith(
        (ref) async => PromptTokenCounterService(encoder: _Tokens()),
      ),
      naiAgentUiPreferencesProvider.overrideWith(
        (ref) => NaiAgentUiPreferences(),
      ),
      kritaBridgeNotifierProvider.overrideWith((ref) => KritaBridgeNotifier()),
      estimatedCostProvider.overrideWith((ref) => 0),
      isFreeGenerationProvider.overrideWith((ref) => true),
      exploreRunListNotifierProvider.overrideWith(_RunList.new),
      styleExploreRunStorageProvider.overrideWithValue(_RunStorage()),
      tipEpochProvider.overrideWith((ref) => Stream.value(0)),
      tipDeckProvider.overrideWithValue(TipDeck(seed: 1)),
      for (final target in PromptTokenCountTarget.values)
        promptTokenUsageProvider(target).overrideWith(
          (ref) async => PromptTokenUsage(
            usedTokens: target == PromptTokenCountTarget.positive ? 220 : 46,
            limit: 1471,
          ),
        ),
    ],
  );
  final images = historyCaptureImages();
  final notifier = container.read(imageGenerationNotifierProvider.notifier);
  notifier.state = notifier.state.copyWith(
    history: images,
    currentImages: [images.first],
    batchWidth: images.first.width,
    batchHeight: images.first.height,
  );
  container
      .read(generationPreviewSelectionProvider.notifier)
      .select(images.first.id);
  return container;
}

Widget _app(
  ProviderContainer container, {
  required bool dark,
  String language = 'zh',
  bool explore = false,
  bool mobile = false,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: dark ? GeistTheme.dark : GeistTheme.light,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepaintBoundary(
        key: const Key('capture'),
        child: IntegratedTitleBarShell(
          child: Scaffold(
            body: mobile
                ? const ParameterPanel()
                : explore
                ? const StyleExploreScreen()
                : const GenerationScreen(),
          ),
        ),
      ),
    ),
  );
}

void main() {
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
  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    await setUpTemporaryHive();
    await Hive.openBox(StorageKeys.settingsBox);
  });

  testWidgets(
    'V3 has one 12px gap and model switches preserve module ordering',
    (tester) async {
      final container = _container('nai-diffusion-3');
      addTearDown(container.dispose);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1552, 1120);
      addTearDown(tester.view.reset);
      await tester.runAsync(
        () => prepareHistoryCaptureImages(historyCaptureImages()),
      );
      await tester.pumpWidget(_app(container, dark: false));
      await tester.pumpAndSettle();
      final prompt = find.byType(PromptInputWidget);
      final cards = find.byType(GenerationModuleCard);
      expect(cards, findsNWidgets(2));
      expect(find.byType(InlineCharacterSection), findsNothing);
      expect(
        tester.getTopLeft(cards.first).dy - tester.getBottomLeft(prompt).dy,
        12,
      );
      for (final model in [
        'nai-diffusion-5-full',
        'nai-diffusion-4-5-full',
        'nai-diffusion-3',
      ]) {
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateModel(model, persist: false);
        await tester.pumpAndSettle();
        expect(
          find.byType(GenerationModuleCard),
          findsNWidgets(ImageModels.isV4Model(model) ? 3 : 2),
        );
        expect(
          find.byType(GenerationModuleRow),
          findsNWidgets(
            model == 'nai-diffusion-5-full'
                ? 1
                : model == 'nai-diffusion-3'
                ? 2
                : 3,
          ),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('production page remains bounded at desktop widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final model in [
      'nai-diffusion-5-full',
      'nai-diffusion-4-5-full',
      'nai-diffusion-3',
    ]) {
      for (final dark in [false, true]) {
        for (final size in [
          (window: 1280.0, left: 352.0),
          (window: 1600.0, left: 420.0),
          (window: 1920.0, left: 560.0),
        ]) {
          final container = _container(model);
          addTearDown(container.dispose);
          await container
              .read(layoutStateNotifierProvider.notifier)
              .setWebLeftPanelWidth(size.left);
          await container
              .read(layoutStateNotifierProvider.notifier)
              .setRightPanelWidth(210);
          await container
              .read(layoutStateNotifierProvider.notifier)
              .setRightPanelExpanded(true);
          await tester.runAsync(
            () => prepareHistoryCaptureImages(historyCaptureImages()),
          );
          // The navigation rail is outside this task; it occupies 48px.
          tester.view.physicalSize = Size(size.window - 48, 1120);
          await tester.pumpWidget(_app(container, dark: dark));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(WebLeftPanel)).width, size.left);
          expect(
            find.byType(GenerationModuleCard),
            findsNWidgets(ImageModels.isV4Model(model) ? 3 : 2),
          );
          await tester.pumpWidget(const SizedBox());
          container.dispose();
        }
      }
    }
  });

  if (Platform.environment['CAPTURE_UIUX_FINAL'] != '1') return;
  testWidgets(
    'capture full production page and drawer across models and languages',
    (tester) async {
      final root = Directory('.dart_tool/uiux-final/captures')
        ..createSync(recursive: true);
      final measurements = <Map<String, Object?>>[];
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cases = [
        for (final model in ['nai-diffusion-5-full', 'nai-diffusion-4-5-full'])
          for (final dark in [false, true])
            for (final language in ['zh', 'en', 'ja', 'ko'])
              for (final width in [352.0, 420.0])
                (
                  model: model,
                  dark: dark,
                  language: language,
                  width: width,
                  explore: false,
                  mobile: false,
                ),
        (
          model: 'nai-diffusion-3',
          dark: false,
          language: 'zh',
          width: 420.0,
          explore: false,
          mobile: false,
        ),
        (
          model: 'nai-diffusion-5-full',
          dark: false,
          language: 'zh',
          width: 420.0,
          explore: true,
          mobile: false,
        ),
        (
          model: 'nai-diffusion-5-full',
          dark: false,
          language: 'zh',
          width: 420.0,
          explore: false,
          mobile: true,
        ),
      ];
      for (final entry in cases) {
        final container = _container(entry.model);
        addTearDown(container.dispose);
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setWebLeftPanelWidth(entry.width);
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setRightPanelWidth(210);
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setRightPanelExpanded(true);
        await tester.runAsync(
          () => prepareHistoryCaptureImages(historyCaptureImages()),
        );
        tester.view.physicalSize = Size(entry.mobile ? 420 : 1552, 1120);
        await tester.pumpWidget(
          _app(
            container,
            dark: entry.dark,
            language: entry.language,
            explore: entry.explore,
            mobile: entry.mobile,
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 80)),
        );
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        if (entry.mobile) {
          expect(find.byType(GenerationModuleCard), findsNothing);
          expect(find.byType(StudioGlassSurface), findsWidgets);
        } else {
          expect(
            find.byType(GenerationModuleCard),
            findsNWidgets(ImageModels.isV4Model(entry.model) ? 3 : 2),
          );
          if (entry.explore) {
            expect(
              tester
                  .widget<ImageCountSection>(find.byType(ImageCountSection))
                  .showPerRequestSegments,
              isFalse,
            );
          }
        }
        final name =
            '${entry.mobile
                ? 'mobile'
                : entry.explore
                ? 'explore'
                : 'generation'}-${entry.model}-${entry.language}-${entry.dark ? 'dark' : 'light'}-${entry.width.toInt()}';
        Map<String, double> rect(Finder target) {
          final value = tester.getRect(target);
          return {
            'x': value.left,
            'y': value.top,
            'width': value.width,
            'height': value.height,
          };
        }

        measurements.add({
          'file': '$name.png',
          'model': entry.model,
          'locale': entry.language,
          'dark': entry.dark,
          'width': entry.width,
          'explore': entry.explore,
          'mobile': entry.mobile,
          'viewport': [entry.mobile ? 420 : 1552, 1120],
          if (!entry.explore && !entry.mobile)
            'left': rect(find.byType(WebLeftPanel)),
          'modules': tester.elementList(find.byType(GenerationModuleCard)).map((
            element,
          ) {
            final value = element.findRenderObject()! as RenderBox;
            final position = value.localToGlobal(Offset.zero);
            return {
              'x': position.dx,
              'y': position.dy,
              'width': value.size.width,
              'height': value.size.height,
            };
          }).toList(),
        });
        Future<void> capture(String suffix) => tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')),
          );
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${root.path}/$name$suffix.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await capture('');
        if (!entry.mobile) {
          await tester.tap(find.byKey(const Key('params-drawer-toggle')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capture('-drawer');
        }
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
      File('${root.parent.path}/measurements.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(measurements),
      );
    },
  );
}

// This tool runs under flutter test; these two native/storage hooks are test APIs.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_detail_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_preference_sort_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_start_evolution_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_adopt_block_dialog.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart'
    show wallFixture;
import '../../test/presentation/screens/style_explore/explore_random_variables_module_test.dart'
    show variableFixtureDocument, variableFixtureLibrary;
import 'explore_evolution_capture_test.dart' show evolutionCaptureFixture;
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import '../../test/helpers/studio_capture_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/style_explore_screen.dart';

/// 内存版 Run 存储（testWidgets 的 fakeAsync 区里 Hive 的异步写盘永不完成，
/// 因此 widget 测试不落盘，只验证 UI 与 provider 协作）。
class _MemoryRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async {
    final runs = _store.values.toList()
      ..sort((a, b) {
        final comparison = b.updatedAt.compareTo(a.updatedAt);
        if (comparison != 0) return comparison;
        return a.id.compareTo(b.id);
      });
    return runs;
  }

  @override
  Future<ExploreRun?> getRun(String id) async => _store[id];

  @override
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    _store[run.id] = run;
  }

  @override
  ExploreRun? currentRun(String id) => _store[id];

  @override
  Future<ExploreRun> transformRun(
    String id,
    ExploreRun Function(ExploreRun) update,
  ) async {
    final next = update(_store[id]!);
    _store[id] = next;
    return next;
  }

  @override
  Future<void> deleteRun(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

class _TestLocalStorageService extends LocalStorageService {
  _TestLocalStorageService({Map<String, Object?>? initial}) {
    if (initial != null) settings.addAll(initial);
  }

  /// 已写入的设置值（含布局 provider 落盘的 toggle 状态）。
  final Map<String, Object?> settings = {};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = settings[key];
    if (value is T) return value;
    return defaultValue;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    settings[key] = value;
  }

  @override
  bool getEnablePromptWeightScroll() => false;

  @override
  bool getEnableAutocomplete() => false;

  @override
  bool getAutoFormatPrompt() => false;

  @override
  bool getHighlightEmphasis() => false;

  @override
  bool getSdSyntaxAutoConvert() => false;

  @override
  String getLastPrompt() => '';

  @override
  String getLastNegativePrompt() => '';

  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';

  @override
  String getDefaultSampler() => 'k_euler_ancestral';

  @override
  int getDefaultSteps() => 28;

  @override
  double getDefaultScale() => 5.0;

  @override
  int getDefaultWidth() => 832;

  @override
  int getDefaultHeight() => 1216;

  @override
  bool getLastSmea() => false;

  @override
  bool getLastSmeaDyn() => false;

  @override
  double getLastCfgRescale() => 0.0;

  @override
  String getLastNoiseSchedule() => 'native';

  @override
  bool getLastVarietyPlus() => false;
}

class _TestVibeLibraryNotifier extends VibeLibraryNotifier {
  @override
  VibeLibraryState build() => const VibeLibraryState();
}

class _TestVibeStorageService extends VibeLibraryStorageService {
  @override
  Future<List<VibeLibraryEntry>> getRecentDisplayEntries({
    int limit = 20,
  }) async => const [];
}

class _FakeCooldownNotifier extends GenerationCooldownNotifier {
  @override
  GenerationCooldownState build() => const GenerationCooldownState();
}

class _TestCharacterPromptNotifier extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class _TestKritaBridgeNotifier extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.initial();
}

class _Runner extends ExploreRunRunner {
  int cancelCalls = 0, pauseCalls = 0;
  String? started;
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
  void set(ExploreRunRunnerState value) {
    state = value;
  }

  @override
  void pause() {
    pauseCalls++;
  }

  @override
  void cancel() {
    cancelCalls++;
  }

  @override
  Future<bool> start(
    String runId, {
    void Function(ImageParams)? beforeGenerate,
  }) async {
    started = runId;
    return true;
  }
}

class _Capture extends ExploreManualCaptureNotifier {
  @override
  ExploreManualCaptureState build() => const ExploreManualCaptureState();
  void set(ExploreManualCaptureState value) {
    state = value;
  }
}

class _Generation extends ImageGenerationNotifier {
  int cancelCalls = 0;
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void set(ImageGenerationState value) {
    state = value;
  }

  @override
  void cancel() {
    cancelCalls++;
  }
}

class _FinalLibrary extends PromptBlockLibraryNotifier {
  _FinalLibrary(this.dark);
  final bool dark;
  @override
  Future<PromptBlockLibraryState> build() async =>
      variableFixtureLibrary(dark: dark);
}

class _FinalWorkspace extends PillWorkspaceNotifier {
  @override
  PillWorkspaceState build(String scope) {
    final doc = scope == PillScopes.main
        ? variableFixtureDocument(2).copyWith(
            text:
                'scenery, panorama, from behind, green theme, blue theme, plant, detailed background, (extremely vibrant colors), magical atmosphere, dynamic composition, sitting, wide shot, white dress, blue flower, frilled dress, giant, 0.8::artist:sincos::, ${variableFixtureDocument(2).text}, artist:asteroid_ill, candid, year 2025, very aesthetic, masterpiece, sketch, lineart, solo, no text',
          )
        : PillDocument.empty();
    return PillWorkspaceState(document: doc, projection: doc.text);
  }
}

class _FinalParams extends GenerationParamsNotifier {
  _FinalParams(this.model);
  final String model;
  @override
  ImageParams build() => ImageParams(
    model: model,
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5,
    nSamples: 10,
    prompt: 'scenery',
    seed: -1,
  );
  @override
  Future<void> restoreGenerationState() async {}
  @override
  Future<void> saveGenerationState() async {}
}

ExploreRun finalCaptureRun(String scene, String model) {
  final cards =
      jsonDecode(
            File(
              '.dart_tool/uiux-explore-task03/prototype-cards.json',
            ).readAsStringSync(),
          )
          as List;
  final evolution = evolutionCaptureFixture();
  final base = scene == 'evolution' || scene == 'compare'
      ? evolution
      : wallFixture(count: scene == 'onboarding' ? 0 : 38);
  final candidates = [
    for (var i = 0; i < base.candidates.length; i++)
      base.candidates[i].copyWith(
        roundId: scene == 'evolution' || scene == 'compare'
            ? base.candidates[i].roundId
            : i < 16
            ? 'r1'
            : i < 26
            ? 'r2'
            : 'r3',
        generation: base.candidates[i].generation.copyWith(
          status: scene == 'running' && i >= 35
              ? ExploreCandidateGenerationStatus.pending
              : scene == 'failed' && i == 27
              ? ExploreCandidateGenerationStatus.failed
              : ExploreCandidateGenerationStatus.done,
          filePath:
              (scene == 'running' && i >= 35) || (scene == 'failed' && i == 27)
              ? null
              : 'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[(i < 26 ? i : i - 26) % cards.length]['image']}',
          seed: 3274348526 + i,
          error: scene == 'failed' && i == 27
              ? 'Synthetic failure, no API request'
              : null,
        ),
        rollSnapshot: ExploreRollSnapshot(
          positive:
              'scenery, ${(cards[(i < 26 ? i : i - 26) % cards.length]['atoms'] as List).join(', ')}, year 2025',
          negative: 'lowres, bad anatomy',
          instanceRolls: [
            const ExploreInstanceRoll(
              lane: 'pos',
              marker: '\uE000',
              blockId: 'pool',
              blockTitle: '400精选画师池',
              rolledText: '',
            ),
            ExploreInstanceRoll(
              lane: 'pos',
              marker: '\uE001',
              blockId: 'favorite',
              blockTitle: '收藏艺术家池',
              rolledText:
                  (cards[(i < 26 ? i : i - 26) % cards.length]['atoms'] as List)
                      .join(', '),
            ),
          ],
        ),
        review: ExploreCandidateReview(
          heart: [1, 15, 21, 26, 28, 30].contains(i),
        ),
        folderId: i == 26 || i == 30
            ? 'cold'
            : i == 33
            ? 'thick'
            : null,
      ),
  ];
  return base.copyWith(
    paramsSnapshot: base.paramsSnapshot.copyWith(model: model),
    status: scene == 'running'
        ? ExploreRunStatus.generating
        : ExploreRunStatus.generated,
    candidates: candidates,
    families: evolution.families,
    parentSets: evolution.parentSets,
    folders: [
      ExploreCandidateFolder(
        id: 'cold',
        name: '冷色调',
        createdAt: base.createdAt,
      ),
      ExploreCandidateFolder(
        id: 'thick',
        name: '厚涂',
        createdAt: base.createdAt,
      ),
    ],
    rounds: scene == 'evolution' || scene == 'compare'
        ? base.rounds
        : [
            for (var i = 1; i <= 3; i++)
              ExploreRound(
                id: 'r$i',
                number: i,
                phase: ExploreRoundPhase.manual,
                status: scene == 'running' && i == 3
                    ? ExploreRoundStatus.generating
                    : ExploreRoundStatus.generated,
                createdAt: base.createdAt.subtract(
                  Duration(minutes: (3 - i) * 94),
                ),
                targetCount: i == 1
                    ? 16
                    : i == 2
                    ? 10
                    : 12,
                candidateIds: [
                  for (final c in candidates)
                    if (c.roundId == 'r$i') c.id,
                ],
              ),
          ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
  final output = Directory('.dart_tool/uiux-explore-final/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets('final full-page production widget matrix, no generation API', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final profiles =
        <({String scene, int width, String locale, bool dark, String model})>[
          for (final scene in [
            'main',
            'running',
            'failed',
            'selection',
            'evolution',
            'viewer',
            'compare',
            'start-evolution',
            'save',
            'onboarding',
            'dropdown',
          ])
            for (final locale in ['zh', 'en', 'ja', 'ko'])
              for (final dark in [false, true])
                (
                  scene: scene,
                  width: 1600,
                  locale: locale,
                  dark: dark,
                  model: 'nai-diffusion-5-full',
                ),
          for (final scene in [
            'main',
            'running',
            'failed',
            'selection',
            'evolution',
            'viewer',
            'compare',
            'start-evolution',
            'save',
            'onboarding',
            'dropdown',
          ])
            for (final dark in [false, true])
              (
                scene: scene,
                width: 1280,
                locale: 'zh',
                dark: dark,
                model: 'nai-diffusion-5-full',
              ),
          for (final width in [1100, 1920])
            for (final locale in ['zh', 'en', 'ja', 'ko'])
              for (final dark in [false, true])
                (
                  scene: 'main',
                  width: width,
                  locale: locale,
                  dark: dark,
                  model: 'nai-diffusion-5-full',
                ),
          for (final model in ['nai-diffusion-4-5-full', 'nai-diffusion-3'])
            for (final dark in [false, true])
              (
                scene: 'main',
                width: 1600,
                locale: 'zh',
                dark: dark,
                model: model,
              ),
        ];
    final limit = int.tryParse(
      Platform.environment['EXPLORE_CAPTURE_LIMIT'] ?? '',
    );
    final geometry = <Object>[];
    for (final profile in limit == null ? profiles : profiles.take(limit)) {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.physicalSize = Size(profile.width.toDouble(), 1000);
      final run = finalCaptureRun(profile.scene, profile.model),
          storage = _MemoryRunStorage(),
          local = _TestLocalStorageService(),
          runner = _Runner(),
          capture = _Capture(),
          gen = _Generation(),
          boundary = GlobalKey();
      await storage.putRun(run);
      if (profile.scene == 'dropdown') {
        await storage.putRun(
          run.copyWith(
            id: 'old',
            name: '冷色厚涂对比',
            updatedAt: run.updatedAt.subtract(const Duration(days: 1)),
          ),
        );
        await storage.putRun(
          run.copyWith(
            id: 'older',
            name: '赛璐璐 × 水彩',
            updatedAt: run.updatedAt.subtract(const Duration(days: 8)),
          ),
        );
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWith((_) => local),
            styleExploreRunStorageProvider.overrideWithValue(storage),
            promptBlockLibraryNotifierProvider.overrideWith(
              () => _FinalLibrary(profile.dark),
            ),
            pillWorkspaceProvider.overrideWith(_FinalWorkspace.new),
            generationParamsNotifierProvider.overrideWith(
              () => _FinalParams(profile.model),
            ),
            vibeLibraryNotifierProvider.overrideWith(
              _TestVibeLibraryNotifier.new,
            ),
            vibeLibraryStorageServiceProvider.overrideWithValue(
              _TestVibeStorageService(),
            ),
            generationCooldownProvider.overrideWith(_FakeCooldownNotifier.new),
            exploreGenerateFnProvider.overrideWithValue((params) async => null),
            exploreRunRunnerProvider.overrideWith(() => runner),
            exploreManualCaptureProvider.overrideWith(() => capture),
            imageGenerationNotifierProvider.overrideWith(() => gen),
            characterPromptNotifierProvider.overrideWith(
              _TestCharacterPromptNotifier.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => _TestKritaBridgeNotifier(),
            ),
            subscriptionNotifierProvider.overrideWith(
              _TestSubscriptionNotifier.new,
            ),
            estimatedCostProvider.overrideWith((_) => 0),
            estimatedCostForBatchSizeProvider(1).overrideWith((_) => 0),
            isFreeGenerationProvider.overrideWith((_) => true),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: (profile.dark ? GeistTheme.dark : GeistTheme.light).copyWith(
              platform: TargetPlatform.windows,
            ),
            locale: Locale(profile.locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => RepaintBoundary(
              key: boundary,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
            ),
            home: IntegratedTitleBarShell(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 48,
                    child: Builder(
                      builder: (context) => ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  const Expanded(child: StyleExploreScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      container.read(exploreActiveRunIdProvider.notifier).state =
          profile.scene == 'onboarding' ? null : run.id;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      if (profile.scene == 'running') {
        runner.set(
          ExploreRunRunnerState(
            runId: run.id,
            isRunning: true,
            processedCount: 9,
            totalCount: 12,
          ),
        );
      }
      if (profile.scene != 'onboarding') {
        container
            .read(exploreFocusedCandidateIdProvider.notifier)
            .state = run.candidates.length > 26
            ? run.candidates[26].id
            : run.candidates.first.id;
      }
      if (['evolution', 'compare'].contains(profile.scene)) {
        container.read(exploreStageTabProvider.notifier).state =
            ExploreStageTab.evolution;
      }
      if (profile.scene == 'selection') {
        container.read(exploreSelectionModeProvider.notifier).state = true;
        container
            .read(exploreSelectionProvider.notifier)
            .selectAll(run.candidates.skip(26).take(3).map((c) => c.id));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final host = tester.element(find.byType(StyleExploreScreen));
      if (profile.scene == 'viewer') {
        unawaited(
          ExploreCandidateDetailDialog.show(
            host,
            runId: run.id,
            candidateIds: run.candidates.map((c) => c.id).toList(),
            initialIndex: 26,
          ),
        );
      }
      if (profile.scene == 'compare') {
        unawaited(
          ExplorePreferenceSortDialog.show(
            host,
            runId: run.id,
            parentSet: run.parentSets.last,
          ),
        );
      }
      if (profile.scene == 'start-evolution') {
        unawaited(
          ExploreStartEvolutionDialog.show(
            host,
            run: run,
            candidates: run.candidates.skip(26).take(3).toList(),
          ),
        );
      }
      if (profile.scene == 'save') {
        unawaited(
          ExploreAdoptBlockDialog.show(
            host,
            initialTitle: '${run.name} ×3',
            candidates: run.candidates.skip(26).take(3).toList(),
            sequenceNumber: 27,
          ),
        );
      }
      if (profile.scene == 'dropdown') {
        await tester.tap(find.byKey(const Key('explore-run-switcher-button')));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (tester
            .renderObjectList<RenderImage>(find.byType(RawImage))
            .every((r) => r.image != null)) {
          break;
        }
      }
      expect(tester.takeException(), isNull, reason: profile.toString());
      final stage = tester.getRect(
            find.byKey(const Key('style-explore-stage')),
          ),
          editor = tester.getRect(
            find.byKey(const Key('style-explore-main-editor')),
          );
      final inspector = find.byKey(const Key('style-explore-inspector'));
      expect(stage.width, greaterThanOrEqualTo(480));
      if (profile.width <= 1280) expect(inspector, findsNothing);
      final name =
          '${profile.scene}-${profile.locale}-${profile.dark ? 'dark' : 'light'}-${profile.width}-${profile.model}';
      geometry.add({
        'name': name,
        'stageWidth': stage.width,
        'editorWidth': editor.width,
        'inspector': inspector.evaluate().isNotEmpty,
      });
      await tester.runAsync(() async {
        final im =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = (await im.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        File('${output.path}/$name.png').writeAsBytesSync(bytes);
        im.dispose();
      });
      print('CAPTURE $name');
    }
    File(
      '.dart_tool/uiux-explore-final/geometry.json',
    ).writeAsStringSync(jsonEncode(geometry));
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 8)));
}

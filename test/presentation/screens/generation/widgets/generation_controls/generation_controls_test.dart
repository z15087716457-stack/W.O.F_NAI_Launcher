import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_dialog.dart';
import '../../../../wiring/generation_backend_test.dart' show SwitchingAuth;
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generation_controls.dart';
import 'package:nai_launcher/presentation/widgets/generation/auto_save_toggle_chip.dart';

void main() {
  testWidgets(
    'onboarding controller invokes the same guarded editor generation path',
    (tester) async {
      final controller = GenerationControlsController(),
          generation = _CaptureGeneration();
      var invoked = 0;
      Future<void> callback(GenerationBatchEvent event) async {}
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              _MemoryLocalStorageService({}),
            ),
            generationParamsNotifierProvider.overrideWith(_DraftParams.new),
            imageGenerationNotifierProvider.overrideWith(() => generation),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => _TestKritaBridgeNotifier(),
            ),
            subscriptionNotifierProvider.overrideWith(
              _TestSubscriptionNotifier.new,
            ),
            exploreRunRunnerProvider.overrideWith(_TestExploreRunner.new),
            estimatedCostForBatchSizeProvider(1).overrideWithValue(0),
            isFreeGenerationProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: GenerationControls(
                controller: controller,
                compact: true,
                exploreMode: true,
                showBalanceChips: false,
                showAutoSaveChip: false,
                onGenerateInvoked: () {
                  invoked++;
                },
                onBatchEvent: callback,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await controller.generate();
      await tester.pump();
      expect(generation.submitted!.prompt, 'city lights');
      expect(generation.batchSizeOverride, 1);
      // Each candidate has its own artist string: a 400 fails only that one.
      expect(generation.badRequestStops, isFalse);
      expect(generation.callback, same(callback));
      expect(invoked, 1);
      final button = tester.widget<GenerateButtonWithCost>(
        find.byType(GenerateButtonWithCost),
      );
      expect(button.labelOverride, '抽 1 张候选');
      button.onGenerate();
      await tester.pump();
      expect(invoked, 2);
      expect(generation.callback, same(callback));
      generation.setBusy();
      await tester.pump();
      await controller.generate();
      await tester.pump();
      expect(invoked, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.generate();
      expect(invoked, 2);
    },
  );
  for (final approving in [false, true]) {
    for (final change in [
      'account',
      'dimensions',
      'batch',
      if (!approving) 'double click',
    ]) {
      testWidgets(
        'direct generation stops if $change changes while waiting for ${approving ? "approval" : "quota"}',
        (tester) async {
          final controller = GenerationControlsController(),
              generation = _CaptureGeneration();
          final quota = _NearlyUsedQuota(
            const OpusUsage(isNegative: true),
            generation,
          );
          final container = ProviderContainer(
            overrides: [
              localStorageServiceProvider.overrideWithValue(
                _MemoryLocalStorageService({}),
              ),
              generationParamsNotifierProvider.overrideWith(_V5DraftParams.new),
              imageGenerationNotifierProvider.overrideWith(() => generation),
              authNotifierProvider.overrideWith(SwitchingAuth.new),
              kritaBridgeNotifierProvider.overrideWith(
                (_) => _TestKritaBridgeNotifier(),
              ),
              subscriptionNotifierProvider.overrideWith(() => quota),
              estimatedCostProvider.overrideWithValue(80),
              isFreeGenerationProvider.overrideWithValue(false),
            ],
          );
          addTearDown(container.dispose);
          container.read(authNotifierProvider);
          container.read(subscriptionNotifierProvider);
          final protection = container.read(
            shareImageSettingsProvider.notifier,
          );
          await protection.setWarnHighAnlasCost(approving);
          await protection.setHighAnlasCostThreshold(1);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                locale: const Locale('zh'),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: Scaffold(
                  body: GenerationControls(
                    controller: controller,
                    compact: true,
                    showBalanceChips: false,
                    showAutoSaveChip: false,
                  ),
                ),
              ),
            ),
          );
          if (!approving) quota.hold = Completer<void>();
          final pending = controller.generate();
          final repeat = change == 'double click'
              ? controller.generate()
              : null;
          await tester.pumpAndSettle();
          expect(quota.asksBeforeSending, 1);
          switch (change) {
            case 'account':
              (container.read(authNotifierProvider.notifier) as SwitchingAuth)
                  .changeAccount();
            case 'dimensions':
              container
                  .read(generationParamsNotifierProvider.notifier)
                  .updateSize(1216, 832, persist: false);
            case 'batch':
              container.read(imagesPerRequestProvider.notifier).set(2);
            case 'double click':
              break;
          }
          if (approving) {
            expect(find.byType(AnlasCostDialog), findsOneWidget);
            await tester.tap(find.text('继续生成'));
          } else {
            quota.hold!.complete();
          }
          await tester.pumpAndSettle();
          await pending;
          await repeat;
          expect(generation.submissions, change == 'double click' ? 1 : 0);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final (name, usage, asks) in [
    ('nearly used up', const OpusUsage(percent: 3), 1),
    ('with room', const OpusUsage(percent: 50), 0),
  ]) {
    testWidgets('an explore candidate free on an Opus quota $name asks '
        '$asks time(s) for the balance before it is sent', (tester) async {
      final controller = GenerationControlsController(),
          generation = _CaptureGeneration(),
          quota = _NearlyUsedQuota(usage, generation);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(
              _MemoryLocalStorageService({}),
            ),
            generationParamsNotifierProvider.overrideWith(_V5DraftParams.new),
            imageGenerationNotifierProvider.overrideWith(() => generation),
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => _TestKritaBridgeNotifier(),
            ),
            subscriptionNotifierProvider.overrideWith(() => quota),
            exploreRunRunnerProvider.overrideWith(_TestExploreRunner.new),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: GenerationControls(
                controller: controller,
                compact: true,
                exploreMode: true,
                showBalanceChips: false,
                showAutoSaveChip: false,
                onBatchEvent: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await controller.generate();
      await tester.pump();
      // Before: sent at once, priced free.
      expect(quota.asksBeforeSending, asks);
      expect(generation.submitted!.prompt, 'city lights');
    });
  }
  for (final automatic in [false, true]) {
    testWidgets(
      'stop upscale routes cancellation correctly; automatic=$automatic',
      (tester) async {
        final task = _RunningUpscale();
        final generation = _RunningGeneration(automatic);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              localStorageServiceProvider.overrideWithValue(
                _MemoryLocalStorageService({}),
              ),
              imageGenerationNotifierProvider.overrideWith(() => generation),
              localUpscaleTaskProvider.overrideWith(() => task),
              kritaBridgeNotifierProvider.overrideWith(
                (ref) => _TestKritaBridgeNotifier(),
              ),
              subscriptionNotifierProvider.overrideWith(
                _TestSubscriptionNotifier.new,
              ),
              estimatedCostProvider.overrideWithValue(0),
            ],
            child: const MaterialApp(
              locale: Locale('zh'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  height: 60,
                  child: GenerationControls(
                    compact: true,
                    showBalanceChips: false,
                    showAutoSaveChip: false,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('停止超分'), findsOneWidget);
        expect(find.text('停止生成'), findsNothing);
        final button = tester.getRect(
          find.byKey(const ValueKey('stop-upscale')),
        );
        final contents = find
            .ancestor(of: find.text('停止超分'), matching: find.byType(Row))
            .first;
        expect(
          tester.getRect(contents).center.dx,
          closeTo(button.center.dx, .5),
        );
        await tester.tap(find.text('停止超分'));
        expect(task.stops, automatic ? 0 : 1);
        expect(generation.stops, automatic ? 1 : 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('桥接生成使用现有停止按钮且不调用 UI 生成', (tester) async {
    final bridge = _ActiveBridgeNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            _MemoryLocalStorageService({}),
          ),
          imageGenerationNotifierProvider.overrideWith(_CaptureGeneration.new),
          kritaBridgeNotifierProvider.overrideWith((ref) => bridge),
          subscriptionNotifierProvider.overrideWith(
            _TestSubscriptionNotifier.new,
          ),
          estimatedCostProvider.overrideWithValue(0),
          isFreeGenerationProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 60,
              child: GenerationControls(
                compact: true,
                showBalanceChips: false,
                showAutoSaveChip: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('停止生成'), findsOneWidget);
    await tester.tap(find.text('停止生成'));
    await tester.pump();
    expect(bridge.stops, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'enhance button submits tool parameters while the img2img draft stays untouched',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(
            _MemoryLocalStorageService({}),
          ),
          generationParamsNotifierProvider.overrideWith(_DraftParams.new),
          imageGenerationNotifierProvider.overrideWith(_CaptureGeneration.new),
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => _TestKritaBridgeNotifier(),
          ),
          subscriptionNotifierProvider.overrideWith(
            _TestSubscriptionNotifier.new,
          ),
          estimatedCostProvider.overrideWithValue(0),
          isFreeGenerationProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);
      final source = Uint8List.fromList(
        img.encodePng(img.Image(width: 832, height: 1216)),
      );
      final before = container.read(generationParamsNotifierProvider);
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.openTemporaryTool(source, ImageWorkflowMode.enhance);
      controller.updateEnhanceUpscaleFactor(1.5);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: GenerationControls(
                compact: true,
                showBalanceChips: false,
                showAutoSaveChip: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      tester
          .widget<GenerateButtonWithCost>(find.byType(GenerateButtonWithCost))
          .onGenerate();
      await tester.pump();
      final sent =
          (container.read(imageGenerationNotifierProvider.notifier)
                  as _CaptureGeneration)
              .submitted!;
      expect(sent.sourceImage, same(source));
      expect(sent.enhanceWorkflow, isTrue);
      expect((sent.width, sent.height), (1248, 1824));
      expect(container.read(generationParamsNotifierProvider), same(before));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('compact web controls show only the full-width button', (
    tester,
  ) async {
    final storage = _MemoryLocalStorageService({
      StorageKeys.autoSaveImages: false,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => _TestKritaBridgeNotifier(),
          ),
          subscriptionNotifierProvider.overrideWith(
            _TestSubscriptionNotifier.new,
          ),
          estimatedCostProvider.overrideWith((ref) => 0),
          isFreeGenerationProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 60,
              child: GenerationControls(
                compact: true,
                showBalanceChips: false,
                showAutoSaveChip: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GenerateButtonWithCost), findsOneWidget);
    expect(find.byType(AutoSaveToggleChip), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explore controls keep the auto-save toggle visible', (
    tester,
  ) async {
    final storage = _MemoryLocalStorageService({
      StorageKeys.autoSaveImages: false,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => _TestKritaBridgeNotifier(),
          ),
          subscriptionNotifierProvider.overrideWith(
            _TestSubscriptionNotifier.new,
          ),
          // explore 分支会 watch runner：替身跳过恢复任务对真 Hive 的依赖。
          exploreRunRunnerProvider.overrideWith(() => _TestExploreRunner()),
          estimatedCostProvider.overrideWith((ref) => 0),
          isFreeGenerationProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 60,
              child: GenerationControls(compact: true, exploreMode: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GenerateButtonWithCost), findsOneWidget);
    expect(find.byType(AutoSaveToggleChip), findsOneWidget);
    expect(
      tester
          .widget<AutoSaveToggleChip>(find.byType(AutoSaveToggleChip))
          .compact,
      isTrue,
    );
    expect(find.text('自动保存'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('very narrow compact controls stay in a single row', (
    tester,
  ) async {
    final storage = _MemoryLocalStorageService({
      StorageKeys.autoSaveImages: false,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => _TestKritaBridgeNotifier(),
          ),
          subscriptionNotifierProvider.overrideWith(
            _TestSubscriptionNotifier.new,
          ),
          exploreRunRunnerProvider.overrideWith(() => _TestExploreRunner()),
          estimatedCostProvider.overrideWith((ref) => 0),
          isFreeGenerationProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 180,
              child: GenerationControls(compact: true, exploreMode: true),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GenerateButtonWithCost), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DraftParams extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(prompt: 'city lights');
}

class _RunningUpscale extends LocalUpscaleTask {
  int stops = 0;
  @override
  LocalUpscaleTaskState build() => const LocalUpscaleTaskState(running: true);
  @override
  void cancel() => stops++;
}

class _RunningGeneration extends ImageGenerationNotifier {
  _RunningGeneration(this.automatic);
  final bool automatic;
  int stops = 0;
  @override
  ImageGenerationState build() => ImageGenerationState(
    status: automatic ? GenerationStatus.generating : GenerationStatus.idle,
  );
  @override
  void cancel() => stops++;
}

class _CaptureGeneration extends ImageGenerationNotifier {
  int submissions = 0;
  ImageParams? submitted;
  int? batchSizeOverride;
  bool? badRequestStops;
  GenerationBatchCallback? callback;
  void setBusy() =>
      state = const ImageGenerationState(status: GenerationStatus.generating);
  @override
  ImageGenerationState build() => const ImageGenerationState();
  @override
  Future<void> generate(
    ImageParams params, {
    GenerationBatchCallback? onBatchEvent,
    int? imagesPerRequestOverride,
    ImageOperation? operation,
    bool badRequestStopsRun = true,
  }) async {
    submissions++;
    submitted = params;
    batchSizeOverride = imagesPerRequestOverride;
    badRequestStops = badRequestStopsRun;
    callback = onBatchEvent;
  }
}

class _MemoryLocalStorageService extends LocalStorageService {
  _MemoryLocalStorageService(this.values);

  final Map<String, Object?> values;

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    return values.containsKey(key) ? values[key] as T? : defaultValue;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class _TestKritaBridgeNotifier extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.initial();
}

/// An Opus account with [usage] cached; a balance request brings the quota
/// run out, as the server has meanwhile decided.
class _NearlyUsedQuota extends SubscriptionNotifier {
  _NearlyUsedQuota(this.usage, this.generation);
  final OpusUsage usage;
  final _CaptureGeneration generation;
  int asksBeforeSending = 0;
  Completer<void>? hold;

  static SubscriptionState _opus(OpusUsage usage) => SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: const TrainingStepsInfo(fixedTrainingStepsLeft: 1000),
      usage: usage,
    ),
  );

  @override
  SubscriptionState build() {
    // As the real notifier: kept for the session.
    ref.keepAlive();
    return _opus(usage);
  }

  @override
  Future<bool> recheckBalance() async {
    if (generation.submitted == null) asksBeforeSending++;
    await hold?.future;
    applyFetchedSubscription(
      _opus(const OpusUsage(isNegative: true)).subscription!,
    );
    return true;
  }
}

/// 832 x 1216, 28 steps on V5: one image is free on the Opus quota.
class _V5DraftParams extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    prompt: 'city lights',
    model: ImageModels.animeDiffusionV5Full,
  );
}

/// Runner 替身：build 不触发 _recoverInterruptedRuns（真 Hive 未初始化）。
class _TestExploreRunner extends ExploreRunRunner {
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
}

class _ActiveBridgeNotifier extends _TestKritaBridgeNotifier {
  _ActiveBridgeNotifier() {
    state = const KritaBridgeState(
      enabled: true,
      activeRequestId: 'offline-test',
    );
  }
  int stops = 0;
  @override
  void cancelActiveRequest() {
    stops++;
  }
}

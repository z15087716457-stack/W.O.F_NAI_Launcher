import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generation_controls.dart';
import 'package:nai_launcher/presentation/widgets/generation/auto_save_toggle_chip.dart';

void main() {
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

class _CaptureGeneration extends ImageGenerationNotifier {
  ImageParams? submitted;
  @override
  ImageGenerationState build() => const ImageGenerationState();
  @override
  Future<void> generate(
    ImageParams params, {
    GenerationBatchCallback? onBatchEvent,
    int? imagesPerRequestOverride,
    ImageOperation? operation,
  }) async {
    submitted = params;
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

/// Runner 替身：build 不触发 _recoverInterruptedRuns（真 Hive 未初始化）。
class _TestExploreRunner extends ExploreRunRunner {
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
}

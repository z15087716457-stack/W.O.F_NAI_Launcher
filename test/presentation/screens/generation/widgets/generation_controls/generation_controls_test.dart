import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

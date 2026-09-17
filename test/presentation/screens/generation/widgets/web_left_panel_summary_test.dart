import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/web_left_panel.dart';

void main() {
  Widget buildSubject({
    required _MemoryLocalStorageService storage,
    required VoidCallback onToggleDrawer,
  }) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWith((ref) => storage),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: GenerationParamsSummaryBar(
            onToggleDrawer: onToggleDrawer,
            arrow: const Icon(Icons.keyboard_arrow_up, size: 20),
          ),
        ),
      ),
    );
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(GenerationParamsSummaryBar)),
        listen: false,
      );

  testWidgets('shows steps/scale/seed/sampler values live', (tester) async {
    final storage = _MemoryLocalStorageService();
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () {}),
    );
    await tester.pump();

    final container = containerOf(tester);
    final params = container.read(generationParamsNotifierProvider);

    expect(find.text('步数'), findsOneWidget);
    expect(find.text('Guidance'), findsOneWidget);
    expect(find.text('种子'), findsOneWidget);
    expect(find.text('采样器'), findsOneWidget);
    expect(find.text(params.steps.toString()), findsOneWidget);
    expect(find.text(params.scale.toStringAsFixed(1)), findsOneWidget);
    expect(
      find.text(Samplers.samplerDisplayNames[params.sampler] ?? params.sampler),
      findsOneWidget,
    );
    // 默认随机种子：种子列显示循环图标而非数值
    expect(find.byIcon(Icons.autorenew), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping seed column toggles lock: value -> random -> value', (
    tester,
  ) async {
    final storage = _MemoryLocalStorageService();
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () {}),
    );
    await tester.pump();

    final container = containerOf(tester);
    final notifier = container.read(generationParamsNotifierProvider.notifier);

    // 随机态 → 锁定：实体化一个具体种子并显示
    await tester.tap(find.text('种子'));
    await tester.pump();
    final lockedSeed = container.read(generationParamsNotifierProvider).seed;
    expect(notifier.isSeedLocked, isTrue);
    expect(lockedSeed, isNot(-1));
    expect(find.text(lockedSeed.toString()), findsOneWidget);
    expect(find.byIcon(Icons.autorenew), findsNothing);

    // 锁定态 → 解锁：回到随机（seed = -1），图标恢复
    await tester.tap(find.text('种子'));
    await tester.pump();
    expect(notifier.isSeedLocked, isFalse);
    expect(container.read(generationParamsNotifierProvider).seed, -1);
    expect(find.byIcon(Icons.autorenew), findsOneWidget);

    // 再锁定：恢复之前记住的锁定值
    await tester.tap(find.text('种子'));
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).seed,
      lockedSeed,
    );
  });

  testWidgets('tapping sampler column opens menu and switches sampler', (
    tester,
  ) async {
    final storage = _MemoryLocalStorageService();
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () {}),
    );
    await tester.pump();

    final container = containerOf(tester);

    await tester.tap(find.text('采样器'));
    await tester.pumpAndSettle();

    // 菜单展开，选中另一采样器
    final target = Samplers.samplerDisplayNames[Samplers.kDpmpp2m]!;
    await tester.tap(find.text(target).last);
    await tester.pumpAndSettle();

    expect(
      container.read(generationParamsNotifierProvider).sampler,
      Samplers.kDpmpp2m,
    );
    expect(find.text(target), findsOneWidget);
  });

  testWidgets('tapping steps/guidance columns toggles the params drawer', (
    tester,
  ) async {
    final storage = _MemoryLocalStorageService();
    var toggleCount = 0;
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () => toggleCount++),
    );
    await tester.pump();

    await tester.tap(find.text('步数'));
    await tester.pump();
    expect(toggleCount, 1);

    await tester.tap(find.text('Guidance'));
    await tester.pump();
    expect(toggleCount, 2);
  });
}

class _MemoryLocalStorageService extends LocalStorageService {
  _MemoryLocalStorageService([Map<String, Object?>? initial])
      : values = initial ?? {};

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

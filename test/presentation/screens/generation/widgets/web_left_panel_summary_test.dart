import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_params_menu_host.dart';

void main() {
  Widget buildSubject({
    required _MemoryLocalStorageService storage,
    required VoidCallback onToggleDrawer,
    Widget arrow = const Icon(Icons.play_arrow),
  }) {
    return ProviderScope(
      overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: GenerationParamsSummaryBar(
            onToggleDrawer: onToggleDrawer,
            arrow: arrow,
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
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping seed column pins/unpins a random seed', (tester) async {
    final storage = _MemoryLocalStorageService();
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () {}),
    );
    await tester.pump();

    final container = containerOf(tester);

    // 随机态 → pin 一个具体种子并显示
    await tester.tap(find.text('种子'));
    await tester.pump();
    final pinnedSeed = container.read(generationParamsNotifierProvider).seed;
    expect(pinnedSeed, isNot(-1));
    expect(find.text(pinnedSeed.toString()), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);

    // 固定态 → 回到随机（seed = -1），图标恢复
    await tester.tap(find.text('种子'));
    await tester.pump();
    expect(container.read(generationParamsNotifierProvider).seed, -1);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('steps/guidance columns are non-interactive', (tester) async {
    final storage = _MemoryLocalStorageService();
    var toggleCount = 0;
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () => toggleCount++),
    );
    await tester.pump();

    await tester.tap(find.text('步数'));
    await tester.pump();
    expect(toggleCount, 0);

    await tester.tap(find.text('Guidance'));
    await tester.pump();
    expect(toggleCount, 0);
  });

  testWidgets('tapping arrow toggles the params drawer', (tester) async {
    final storage = _MemoryLocalStorageService();
    var toggleCount = 0;
    await tester.pumpWidget(
      buildSubject(storage: storage, onToggleDrawer: () => toggleCount++),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(toggleCount, 1);
  });

  testWidgets('sampler column opens grouped menu above and switches sampler', (
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

    // 分组头与可用采样器（默认模型族不含 DDIM）
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('其他'), findsOneWidget);
    expect(find.text('DDIM'), findsNothing);

    final target = Samplers.samplerDisplayNames[Samplers.kDpmpp2m]!;
    await tester.tap(find.text(target).last);
    await tester.pumpAndSettle();

    expect(
      container.read(generationParamsNotifierProvider).sampler,
      Samplers.kDpmpp2m,
    );
    expect(find.text(target), findsOneWidget);
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

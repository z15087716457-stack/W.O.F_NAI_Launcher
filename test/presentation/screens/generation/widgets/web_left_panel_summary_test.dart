import 'package:nai_launcher/presentation/widgets/common/uiux_prototype_icon.dart';
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
    Widget arrow = const Icon(Icons.keyboard_arrow_up),
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
    expect(find.text('引导'), findsOneWidget);
    expect(find.text('种子'), findsOneWidget);
    expect(find.text('采样器'), findsOneWidget);
    expect(find.text(params.steps.toString()), findsOneWidget);
    expect(find.text(params.scale.toStringAsFixed(1)), findsOneWidget);
    expect(
      find.text(Samplers.samplerDisplayNames[params.sampler] ?? params.sampler),
      findsOneWidget,
    );
    // 默认随机种子：种子列显示循环图标而非数值
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            w.bytesLoader is SvgAssetLoader &&
            (w.bytesLoader as SvgAssetLoader).assetName ==
                'assets/icons/nai-icon-seed.svg',
      ),
      findsOneWidget,
    );
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
    expect(find.text('种子 · 固定'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is UiuxPrototypeIcon && w.icon == Icons.lock_outline,
      ),
      findsOneWidget,
    );

    // 固定态 → 回到随机（seed = -1），图标恢复
    await tester.tap(find.text('种子 · 固定'));
    await tester.pump();
    expect(container.read(generationParamsNotifierProvider).seed, -1);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            w.bytesLoader is SvgAssetLoader &&
            (w.bytesLoader as SvgAssetLoader).assetName ==
                'assets/icons/nai-icon-seed.svg',
      ),
      findsOneWidget,
    );
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

    await tester.tap(find.text('引导'));
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

    await tester.tap(find.byKey(const Key('params-drawer-toggle')));
    await tester.pump();
    expect(toggleCount, 1);
  });

  testWidgets(
    'host rotates the up chevron half a turn and unmounts its drawer',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWith(
              (ref) => _MemoryLocalStorageService(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 352,
                height: 700,
                child: GenerationParamsMenuHost(child: SizedBox.expand()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder rotation() => find.descendant(
        of: find.byKey(const Key('params-drawer-toggle')),
        matching: find.byType(RotationTransition),
      );
      expect(tester.widget<RotationTransition>(rotation()).turns.value, 0);
      await tester.tap(find.byKey(const Key('params-drawer-toggle')));
      await tester.pumpAndSettle();
      expect(tester.widget<RotationTransition>(rotation()).turns.value, .5);
      expect(find.descendant(of: find.byType(GenerationParamsMenuHost), matching: find.byType(SlideTransition)), findsOneWidget);
      await tester.tap(find.byKey(const Key('params-drawer-toggle')));
      await tester.pumpAndSettle();
      expect(tester.widget<RotationTransition>(rotation()).turns.value, 0);
      expect(find.descendant(of: find.byType(GenerationParamsMenuHost), matching: find.byType(SlideTransition)), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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

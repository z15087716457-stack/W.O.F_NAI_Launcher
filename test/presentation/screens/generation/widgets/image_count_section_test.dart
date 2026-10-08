import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_param_sections.dart';
import 'package:nai_launcher/presentation/widgets/common/draggable_number_input.dart';

void main() {
  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    bool module = false,
    bool showPerRequest = true,
    double width = 395,
  }) async {
    final storage = _MemoryLocalStorageService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWith((ref) => storage)],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: ImageCountSection(
                showPerRequestSegments: showPerRequest,
                layout: module
                    ? ImageCountSectionLayout.moduleRow
                    : ImageCountSectionLayout.classic,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(ImageCountSection)),
    );
  }

  testWidgets(
    'module count track and repeat keep the same row and update totals',
    (tester) async {
      final container = await pumpSection(tester, module: true);
      expect(find.text('张数'), findsOneWidget);
      expect(find.text('重复'), findsOneWidget);
      final segments = find.byKey(const Key('image-count-segments'));
      expect(tester.getSize(segments).height, 32);
      expect(
        tester.getCenter(segments).dy,
        closeTo(tester.getCenter(find.byType(DraggableNumberInput)).dy, .01),
      );
      await tester.tap(find.byKey(const ValueKey('image-count-4')));
      await tester.tap(find.byType(DraggableNumberInput));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '999');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(container.read(generationParamsNotifierProvider).nSamples, 999);
      expect(find.text('999 次 × 4 张 = 共 3996 张'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('explore only shows repeat and preserves drag and scroll', (
    tester,
  ) async {
    final container = await pumpSection(
      tester,
      module: true,
      showPerRequest: false,
      width: 294,
    );
    expect(find.text('张数'), findsNothing);
    expect(find.byKey(const Key('image-count-segments')), findsNothing);
    final value = find.byType(DraggableNumberInput);
    await tester.drag(value, const Offset(90, 0));
    await tester.pump();
    final dragged = container.read(generationParamsNotifierProvider).nSamples;
    expect(dragged, greaterThan(1));
    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: tester.getCenter(value),
        scrollDelta: const Offset(0, 1),
      ),
    );
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).nSamples,
      dragged - 1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow count layout wraps repeat rather than overflow', (
    tester,
  ) async {
    await pumpSection(tester, module: true, width: 270);
    expect(
      tester.getTopLeft(find.byType(DraggableNumberInput)).dy,
      greaterThan(
        tester.getBottomLeft(find.byKey(const Key('image-count-segments'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('箭头步进请求次数并联动合计文案', (tester) async {
    final container = await pumpSection(tester);

    // 默认 1×1：不显示合计文案
    expect(find.textContaining('共 1 张'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(container.read(generationParamsNotifierProvider).nSamples, 2);
    expect(find.text('2 次 × 1 张 = 共 2 张'), findsOneWidget);

    // 递减回 1 后不能低于 1（左箭头禁用）
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(container.read(generationParamsNotifierProvider).nSamples, 1);
  });

  testWidgets('分段选择更新每次张数并联动合计', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('3'));
    await tester.pump();

    expect(find.text('1 次 × 3 张 = 共 3 张'), findsOneWidget);
  });
}

class _MemoryLocalStorageService extends LocalStorageService {
  final Map<String, Object?> values = {};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    return values.containsKey(key) ? values[key] as T? : defaultValue;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

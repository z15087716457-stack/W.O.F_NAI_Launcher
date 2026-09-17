import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_param_sections.dart';

void main() {
  Future<ProviderContainer> pumpSection(WidgetTester tester) async {
    final storage = _MemoryLocalStorageService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ImageCountSection()),
        ),
      ),
    );
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(ImageCountSection)),
    );
  }

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

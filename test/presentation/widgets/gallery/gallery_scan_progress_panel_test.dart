import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/gallery_scan_progress_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_scan_progress_panel.dart';

void main() {
  const stats = MetadataCacheStats(
    totalImages: 48422,
    processed: 7426,
    withMetadata: 4600,
    skipped: 7739,
    currentStage: 'completed',
    currentFile: r'C:\gallery\folder\a_very_long_image_file_name_2026.png',
  );
  const state = ScanProgressState(
    isScanning: true,
    cacheStats: stats,
    progress: 0.153,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    Brightness brightness = Brightness.dark,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: brightness == Brightness.dark
            ? GeistTheme.dark
            : GeistTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const SizedBox(
              width: 250,
              child: GalleryScanProgressCard(state: state),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('250px 侧栏内显示单次进度和累计统计，隐藏原始阶段名', (tester) async {
    await pumpCard(tester);

    expect(find.text('正在整理图库'), findsOneWidget);
    expect(find.text('15.3%'), findsOneWidget);
    expect(find.text('7,426 / 48,422'), findsOneWidget);
    expect(find.text('4,600'), findsOneWidget);
    expect(find.text('7,739'), findsOneWidget);
    expect(find.text('completed'), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0.153,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('较大字号下两种主题均不发生布局溢出', (tester) async {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      await pumpCard(tester, brightness: brightness, textScale: 1.3);
      expect(tester.takeException(), isNull);
    }
  });
}

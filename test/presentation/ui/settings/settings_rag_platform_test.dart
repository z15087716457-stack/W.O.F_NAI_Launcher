import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<(SettingsRecorder, AppLocalizations)> pumpRag(
    WidgetTester t,
    SettingsRagData rag, {
    String locale = 'zh',
    double window = 1280,
  }) async {
    final rec = await pumpSettings(
      t,
      locale: locale,
      window: window,
      data: SettingsFixture.view(page: SettingsPageId.rag).copyWith(rag: rag),
    );
    return (rec, AppLocalizations.of(t.element(find.byType(SettingsHost)))!);
  }

  Future<void> tap(WidgetTester t, String key) async {
    final target = find.byKey(Key(key));
    await t.ensureVisible(target);
    await t.pumpAndSettle();
    await t.tap(target);
    await t.pumpAndSettle();
  }

  Finder inside(String key, Finder matching) =>
      find.descendant(of: find.byKey(Key(key)), matching: matching);

  testWidgets('a Mac installs its one build and never offers CUDA', (t) async {
    for (final (locale, window) in [
      for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko'])
        for (final window in [900.0, 1280.0]) (locale, window),
    ]) {
      await t.pumpWidget(const SizedBox.shrink());
      final (rec, l) = await pumpRag(
        t,
        const SettingsRagData(platform: SettingsRagPlatform.macOS),
        locale: locale,
        window: window,
      );
      expect(inside('seg-ragDevice', find.text('CUDA')), findsNothing);
      expect(inside('seg-ragDevice', find.text(l.set_rgAuto)), findsOneWidget);
      expect(inside('seg-ragDevice', find.text('CPU')), findsOneWidget);
      expect(find.text(l.set_rgPythonSubMac), findsOneWidget);
      expect(find.text(l.set_rgPythonSub), findsNothing);
      await tap(t, 'rag-install');
      expect(find.byKey(const Key('rag-install-choice')), findsOneWidget);
      expect(find.text(l.set_rgInstallHintMac), findsOneWidget);
      expect(find.byKey(const Key('rag-install-cuda')), findsNothing);
      expect(inside('rag-install-cpu', find.text(l.set_rgInstall)), findsOne);
      expect(rec.calls, isEmpty);
      await tap(t, 'rag-install-cpu');
      expect(rec.calls, ['ragInstall:false']);
      expect(find.text(l.set_rgNeedsAppleSilicon), findsNothing);
      await tap(t, 'rag-download-btn-embedder');
      expect(rec.calls.last, 'ragDownload:embedder');
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('Windows keeps the CUDA and CPU choices', (t) async {
    final (rec, l) = await pumpRag(t, const SettingsRagData());
    expect(inside('seg-ragDevice', find.text('CUDA')), findsOneWidget);
    expect(find.text(l.set_rgPythonSub), findsOneWidget);
    expect(find.text(l.set_rgNeedsAppleSilicon), findsNothing);
    await tap(t, 'rag-install');
    expect(find.text(l.set_rgInstallHint), findsOneWidget);
    expect(inside('rag-install-cpu', find.text(l.set_rgInstallCpu)), findsOne);
    await tap(t, 'rag-install-cuda');
    expect(rec.calls, ['ragInstall:true']);
  });

  testWidgets('an Intel Mac shows the runtime as unsupported, greyed out', (
    t,
  ) async {
    for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
      await t.pumpWidget(const SizedBox.shrink());
      final (rec, l) = await pumpRag(
        t,
        const SettingsRagData(
          platform: SettingsRagPlatform.macOS,
          runtimeSupported: false,
        ),
        locale: locale,
        window: 900,
      );
      expect(
        inside('rag-runtime', find.text(l.set_rgEnvUnsupported)),
        findsOne,
      );
      expect(
        inside('rag-runtime', find.text(l.set_rgEnvMissing)),
        findsNothing,
      );
      expect(
        inside('rag-runtime', find.text(l.set_rgNeedsAppleSilicon)),
        findsOne,
      );
      await tap(t, 'rag-install');
      expect(find.byKey(const Key('rag-install-choice')), findsNothing);
      // The models cannot run there either: same reason, no download.
      for (final (row, model) in [
        ('setting-ragEmbedPath', 'embedder'),
        ('setting-ragRerankPath', 'reranker'),
      ]) {
        expect(inside(row, find.text(l.set_rgNeedsAppleSilicon)), findsOne);
        await tap(t, 'rag-download-btn-$model');
      }
      expect(rec.calls, isEmpty);
      expect(t.takeException(), isNull);
    }
  });

  testWidgets('an install refused as unsupported is explained', (t) async {
    final (_, l) = await pumpRag(
      t,
      const SettingsRagData(
        platform: SettingsRagPlatform.macOS,
        error: 'unsupported_platform',
      ),
    );
    expect(
      t.widget<Text>(find.byKey(const Key('rag-error'))).data,
      l.set_rgNeedsAppleSilicon,
    );
  });
}

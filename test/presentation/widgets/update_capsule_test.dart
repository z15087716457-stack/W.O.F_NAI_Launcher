import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/update_capsule.dart';
import 'package:nai_launcher/presentation/widgets/common/update_check_dialog.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import '../../helpers/studio_capture_fonts.dart';

class _Updates extends UpdateStateNotifier {
  int downloads = 0;
  int installs = 0;
  @override
  UpdateState build() => const UpdateState();
  void set(UpdateState value) => state = value;
  @override
  Future<void> downloadUpdate() async {
    downloads++;
    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: .42,
    );
  }

  @override
  Future<void> installDownloadedUpdate() async {
    installs++;
  }
}

void main() {
  const info = VersionInfo(
    version: '2.0.0',
    currentVersion: '1.0.0',
    isNewer: true,
    releaseNotes: '## 界面改进\n\n- 候选画廊顶部对齐\n- 更清晰的面板收起入口\n\n## 修复\n\n修复窗口按钮遮挡。',
    primaryAsset: ReleaseAssetInfo(
      type: ReleaseAssetType.windowsPortable,
      platform: 'windows',
      fileName: 'update.zip',
      downloadUrl: 'https://example.test/update.zip',
      sha256: 'abc',
    ),
  );
  const available = UpdateState(
    status: UpdateStatus.available,
    versionInfo: info,
  );
  final ready = UpdateState(
    status: UpdateStatus.downloaded,
    versionInfo: info,
    downloadedUpdate: DownloadedUpdate(
      file: File('test-only.zip'),
      asset: info.primaryAsset!,
      version: '2.0.0',
    ),
  );

  testWidgets(
    'capsule persists through snooze, cancel and failure; disappears when up to date',
    (tester) async {
      final notifier = _Updates();
      final container = ProviderContainer(
        overrides: [updateStateProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: nav,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => UpdateAwareWindowShell(
              deferToRoute: true,
              onShowUpdate: () => UpdateCheckDialog.show(nav.currentContext!),
              child: child!,
            ),
            home: const WindowChromePage(
              child: Scaffold(
                body: Column(
                  children: [
                    WindowHeader(child: TextField()),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(UpdateCapsule), findsNothing);
      await tester.enterText(find.byType(TextField), 'preserve draft');
      notifier.set(available);
      await tester.pumpAndSettle();
      final capsule = find.byKey(const Key('window-update-capsule'));
      expect(capsule, findsOneWidget);
      expect(tester.getRect(capsule).right, lessThanOrEqualTo(800 - 138));
      expect(
        tester
            .getRect(find.byType(TextField))
            .overlaps(tester.getRect(capsule)),
        isFalse,
      );
      await tester.tap(capsule);
      await tester.pumpAndSettle();
      expect(find.text('界面改进'), findsOneWidget);
      await tester.tap(find.text('下载更新'));
      await tester.pump();
      expect(notifier.downloads, 1);
      expect(find.text('界面改进'), findsOneWidget);
      expect(find.textContaining('42%'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(capsule, findsOneWidget);
      notifier.set(available.copyWith(notificationVisible: false));
      await tester.pump();
      expect(capsule, findsOneWidget);
      notifier.set(
        available.copyWith(status: UpdateStatus.error, errorMessage: 'offline'),
      );
      await tester.pump();
      expect(capsule, findsOneWidget);
      notifier.set(const UpdateState(status: UpdateStatus.upToDate));
      await tester.pump();
      expect(capsule, findsNothing);
      expect(find.text('preserve draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ready update waits for tasks; restart has no second dialog', (
    tester,
  ) async {
    final notifier = _Updates();
    final busy = StateProvider<bool>((ref) => true);
    final container = ProviderContainer(
      overrides: [
        updateStateProvider.overrideWith(() => notifier),
        updateTaskBusyProvider.overrideWith((ref) => ref.watch(busy)),
      ],
    );
    addTearDown(container.dispose);
    container.read(updateStateProvider);
    notifier.set(ready);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: UpdateCheckDialog()),
        ),
      ),
    );
    final restart = find.widgetWithText(FilledButton, '安装并重启');
    expect(tester.widget<FilledButton>(restart).onPressed, isNull);
    container.read(busy.notifier).state = false;
    await tester.pump();
    await tester.tap(restart);
    expect(notifier.installs, 1);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('release notes dialog renders in ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      final notifier = _Updates();
      final container = ProviderContainer(
        overrides: [updateStateProvider.overrideWith(() => notifier)],
      );
      addTearDown(container.dispose);
      container.read(updateStateProvider);
      notifier.set(available);
      final key = GlobalKey();
      if (Platform.environment['CAPTURE_EXPLORE_CHROME'] == '1') {
        await tester.runAsync(() async {
          await loadStudioCaptureFonts();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            theme: (dark ? GeistTheme.dark : GeistTheme.light).copyWith(
              textTheme: (dark ? GeistTheme.dark : GeistTheme.light).textTheme
                  .apply(fontFamily: 'HarmonyOS Sans SC'),
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RepaintBoundary(
              key: key,
              child: const Scaffold(body: UpdateCheckDialog()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_EXPLORE_CHROME'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          await File(
            '.dart_tool/update-dialog-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(data.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

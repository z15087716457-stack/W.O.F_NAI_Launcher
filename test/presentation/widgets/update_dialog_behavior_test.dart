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
import 'package:nai_launcher/presentation/widgets/common/update_check_dialog.dart';
import '../../helpers/studio_capture_fonts.dart';

class _Updates extends UpdateStateNotifier {
  int installs = 0;
  @override
  UpdateState build() => const UpdateState();
  void set(UpdateState value) => state = value;
  @override
  Future<void> installDownloadedUpdate() async {
    installs++;
  }
}

void main() {
  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final dark in [false, true]) {
      for (final compact in [false, true]) {
        testWidgets(
          'long update errors stay inside the dialog: $locale dark=$dark compact=$compact',
          (tester) async {
            await tester.binding.setSurfaceSize(
              compact ? const Size(420, 520) : const Size(1000, 800),
            );
            addTearDown(() => tester.binding.setSurfaceSize(null));
            await tester.runAsync(() async {
              await loadStudioCaptureFonts();
              await (FontLoader('MaterialIcons')..addFont(
                    rootBundle.load('fonts/MaterialIcons-Regular.otf'),
                  ))
                  .load();
            });
            final reason =
                'HTTP 403\n${List.filled(48, 'GitHub: API rate limit exceeded for this network. 请求已达上限。').join('\n')}';
            const details = 'Full original Dio diagnostics fixture';
            final notifier = _Updates();
            final copied = <String>[];
            tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.platform,
              (call) async {
                if (call.method == 'Clipboard.setData') {
                  copied.add((call.arguments as Map)['text'] as String);
                }
                return null;
              },
            );
            addTearDown(
              () => tester.binding.defaultBinaryMessenger
                  .setMockMethodCallHandler(SystemChannels.platform, null),
            );
            final container = ProviderContainer(
              overrides: [updateStateProvider.overrideWith(() => notifier)],
            );
            addTearDown(container.dispose);
            container.read(updateStateProvider);
            notifier.set(
              UpdateState(
                status: UpdateStatus.error,
                errorMessage: reason,
                errorDetails: details,
              ),
            );
            final key = GlobalKey();
            final theme = dark ? GeistTheme.dark : GeistTheme.light;
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: theme.copyWith(
                    textTheme: theme.textTheme.apply(
                      fontFamily: 'HarmonyOS Sans SC',
                    ),
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(compact ? 1.4 : 1),
                    ),
                    child: child!,
                  ),
                  home: RepaintBoundary(
                    key: key,
                    child: const Scaffold(body: UpdateCheckDialog()),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(UpdateCheckDialog));
            final l10n = AppLocalizations.of(context)!;
            final copy = find.widgetWithText(TextButton, l10n.gen_copyDetail);
            final retry = find.widgetWithText(FilledButton, l10n.common_retry);
            expect(copy.hitTestable(), findsOneWidget);
            expect(retry.hitTestable(), findsOneWidget);
            expect(find.text(details), findsNothing);
            final scroll = find.byType(SingleChildScrollView).first;
            final position = tester
                .state<ScrollableState>(
                  find
                      .descendant(of: scroll, matching: find.byType(Scrollable))
                      .first,
                )
                .position;
            expect(position.maxScrollExtent, greaterThan(0));
            expect(
              tester.getRect(scroll).bottom,
              lessThanOrEqualTo(tester.getRect(copy).top),
            );
            expect(tester.takeException(), isNull);
            final capture = Platform.environment['UPDATE_ERROR_CAPTURES'];
            if (capture != null) {
              await tester.runAsync(() async {
                final image =
                    await (key.currentContext!.findRenderObject()!
                            as RenderRepaintBoundary)
                        .toImage();
                final data = (await image.toByteData(
                  format: ui.ImageByteFormat.png,
                ))!;
                final file = File(
                  '$capture/${locale.toLanguageTag()}-${dark ? 'dark' : 'light'}-${compact ? 'compact' : 'wide'}.png',
                );
                await file.parent.create(recursive: true);
                await file.writeAsBytes(data.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.drag(scroll, const Offset(0, -300));
            await tester.pumpAndSettle();
            expect(position.pixels, greaterThan(0));
            await tester.tap(copy);
            await tester.pump();
            expect(copied, [details]);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }

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

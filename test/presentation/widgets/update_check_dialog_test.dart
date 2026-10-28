import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/update_check_dialog.dart';

class _DialogUpdateNotifier extends UpdateStateNotifier {
  _DialogUpdateNotifier(this.initialState);

  final UpdateState initialState;
  int downloads = 0;
  int installs = 0;

  @override
  UpdateState build() => initialState;

  @override
  Future<void> downloadUpdate() async {
    downloads++;
    state = state.copyWith(
      status: UpdateStatus.downloaded,
      downloadedUpdate: DownloadedUpdate(
        file: File('unused-update-file'),
        asset: state.versionInfo!.primaryAsset!,
        version: state.versionInfo!.version,
      ),
    );
  }

  @override
  Future<void> installDownloadedUpdate() async {
    installs++;
  }
}

void main() {
  for (final type in [
    ReleaseAssetType.windowsPortable,
    ReleaseAssetType.windowsInstaller,
  ]) {
    testWidgets('$type downloads inside the app then offers restart', (
      tester,
    ) async {
      final asset = ReleaseAssetInfo.fromGitHubAsset({
        'name': type == ReleaseAssetType.windowsPortable
            ? 'WOF_NAI_Studio_Windows_2.2.0_Portable.zip'
            : 'WOF_NAI_Studio_Windows_2.2.0_Setup.exe',
        'browser_download_url': 'https://example.com/package',
        'digest': 'sha256:${'a' * 64}',
      });
      final notifier = _DialogUpdateNotifier(
        UpdateState(
          status: UpdateStatus.available,
          versionInfo: VersionInfo(version: '2.2.0', primaryAsset: asset),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateStateNotifierProvider.overrideWith(() => notifier),
            updateTaskBusyProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: UpdateCheckDialog()),
          ),
        ),
      );
      await tester.pump();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(UpdateCheckDialog)),
      )!;
      expect(find.text(l10n.goToDownload), findsNothing);
      await tester.tap(find.text(l10n.updateDownload));
      await tester.pump();
      expect(notifier.downloads, 1);
      expect(notifier.installs, 0);
      await tester.tap(find.text(l10n.updateInstallAndRestart));
      await tester.pump();
      expect(notifier.installs, 1);
    });
  }

  testWidgets('manual fallback opens the release page instead of the raw ZIP', (
    tester,
  ) async {
    const releaseUrl = 'https://example.com/releases/v2.2.0';
    const zipUrl = 'https://example.com/update.zip';
    final launched = <String>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'canLaunch') return true;
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
        return true;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateStateNotifierProvider.overrideWith(
            () => _DialogUpdateNotifier(
              const UpdateState(
                status: UpdateStatus.available,
                versionInfo: VersionInfo(
                  version: '2.2.0',
                  htmlUrl: releaseUrl,
                  downloadUrl: zipUrl,
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: UpdateCheckDialog()),
        ),
      ),
    );
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(UpdateCheckDialog)),
    )!;
    await tester.tap(find.text(l10n.goToDownload));
    await tester.pump();
    expect(launched, [releaseUrl]);
  });

  testWidgets(
    'update dialog uses Preview labels and retains raw comparison versions',
    (tester) async {
      const info = VersionInfo(
        version: '2.0.0-preview',
        currentVersion: '2.0.0-preview+6',
        isNewer: true,
      );
      const state = UpdateState(
        status: UpdateStatus.available,
        versionInfo: info,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            updateStateNotifierProvider.overrideWith(
              () => _DialogUpdateNotifier(state),
            ),
            updateTaskBusyProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: UpdateCheckDialog()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('2.0 Preview'), findsNWidgets(2));
      expect(find.text('2.0.0-preview'), findsNothing);
      expect(find.text('2.0.0-preview+6'), findsNothing);
      expect(info.currentVersion, '2.0.0-preview+6');
      expect(info.version, '2.0.0-preview');
    },
  );

  testWidgets('renders GitHub Flavored Markdown release notes', (tester) async {
    const asset = ReleaseAssetInfo(
      type: ReleaseAssetType.windowsPortable,
      platform: 'windows',
      fileName: 'update.zip',
      downloadUrl: 'https://example.com/update.zip',
      sha256: 'abc',
    );
    const info = VersionInfo(
      version: '2.0.0',
      currentVersion: '1.0.0',
      primaryAsset: asset,
      assets: [asset],
      isNewer: true,
      releaseNotes: '''
# Major Update

- [x] Persistent notifications
- **Safe** rollback

| Feature | Status |
| --- | --- |
| Resume | Ready |

> Important note

```dart
print('updated');
```

[Release details](https://example.com/release)
''',
    );
    const state = UpdateState(
      status: UpdateStatus.available,
      versionInfo: info,
      notificationVisible: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateStateNotifierProvider.overrideWith(
            () => _DialogUpdateNotifier(state),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: UpdateCheckDialog()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Major Update'), findsOneWidget);
    expect(find.text('Persistent notifications'), findsOneWidget);
    expect(find.text('Feature'), findsOneWidget);
    expect(find.text('Important note'), findsOneWidget);
    expect(find.text("print('updated');"), findsOneWidget);
    expect(find.text('Release details'), findsOneWidget);
  });
}

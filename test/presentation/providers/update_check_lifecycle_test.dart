import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/services/app_installation_service.dart';
import 'package:nai_launcher/core/services/update_check_service.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:nai_launcher/presentation/providers/update_provider.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _Check extends Mock implements UpdateCheckService {}

class _Installer extends UpdateInstallerService {
  _Installer(this.result)
    : super(dio: Dio(), installationService: AppInstallationService());
  final DownloadedUpdate result;
  @override
  Future<DownloadedUpdate> downloadUpdate(
    VersionInfo versionInfo, {
    void Function(UpdateDownloadProgress progress)? onProgress,
    CancelToken? cancelToken,
  }) async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  const asset = ReleaseAssetInfo(
    type: ReleaseAssetType.windowsPortable,
    platform: 'windows',
    fileName: 'fixture.zip',
    downloadUrl: 'https://fixture.invalid/unused',
    sha256: 'unused',
    size: 7,
  );
  const info = VersionInfo(
    version: '99.0.0',
    primaryAsset: asset,
    assets: [asset],
    isNewer: true,
  );
  late Directory directory;
  late ProviderContainer container;
  late UpdateStateNotifier notifier;
  late _Check check;
  late DownloadedUpdate downloaded;
  late Completer<VersionInfo?> automatic;
  late Completer<VersionInfo?> manual;
  late Completer<void> automaticStarted;
  late Completer<void> manualStarted;
  late List<Future<void>> tasks;
  var disposed = false;
  var automaticCalls = 0;
  var manualCalls = 0;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'update_check_lifecycle_',
    );
    final file = await File(
      '${directory.path}/fixture.zip',
    ).writeAsString('fixture');
    downloaded = DownloadedUpdate(
      file: file,
      asset: asset,
      version: info.version,
    );
    automatic = Completer<VersionInfo?>();
    manual = Completer<VersionInfo?>();
    automaticStarted = Completer<void>();
    manualStarted = Completer<void>();
    tasks = [];
    disposed = false;
    automaticCalls = 0;
    manualCalls = 0;
    check = _Check();
    when(check.clearReminder).thenAnswer((_) async {});
    when(() => check.skipVersion(any())).thenAnswer((_) async {});
    when(() => check.checkForUpdates(ignoreSkipped: false)).thenAnswer((_) {
      automaticCalls++;
      if (!automaticStarted.isCompleted) automaticStarted.complete();
      return automatic.future;
    });
    when(() => check.checkForUpdates(ignoreSkipped: true)).thenAnswer((_) {
      manualCalls++;
      if (!manualStarted.isCompleted) manualStarted.complete();
      return manual.future;
    });
    container = ProviderContainer(
      overrides: [
        updateCheckServiceProvider.overrideWithValue(check),
        updateInstallerServiceProvider.overrideWithValue(
          _Installer(downloaded),
        ),
      ],
    );
    notifier = container.read(updateStateProvider.notifier);
  });
  tearDown(() async {
    if (!automatic.isCompleted) automatic.complete(null);
    if (!manual.isCompleted) manual.complete(null);
    await Future.wait(tasks.map((task) => task.catchError((_) {})));
    if (!disposed) container.dispose();
    await directory.delete(recursive: true);
  });
  Future<void> start({bool byHand = false}) {
    final task = notifier.checkForUpdates(manual: byHand);
    tasks.add(task);
    return task;
  }

  UpdateState current() => container.read(updateStateProvider);
  Future<void> manualResult() async {
    final task = start(byHand: true);
    await manualStarted.future;
    manual.complete(info);
    await task;
  }

  for (final result in ['version', 'none', 'error']) {
    test(
      'late automatic $result cannot overwrite a completed newer download',
      () async {
        final old = start();
        await automaticStarted.future;
        await manualResult();
        await notifier.downloadUpdate();
        expect(current().status, UpdateStatus.downloaded);
        if (result == 'error') {
          automatic.completeError(StateError('late automatic failure'));
        } else {
          automatic.complete(result == 'version' ? info : null);
        }
        await old;
        expect(current().status, UpdateStatus.downloaded);
        expect(current().downloadedUpdate, same(downloaded));
      },
    );
  }
  test('duplicate automatic checks share one request', () async {
    final first = start();
    final second = start();
    await automaticStarted.future;
    automatic.complete(info);
    await Future.wait([first, second]);
    expect(automaticCalls, 1);
    expect(current().status, UpdateStatus.available);
  });
  test('duplicate manual checks share their reminder and request', () async {
    final first = start(byHand: true);
    final second = start(byHand: true);
    await manualStarted.future;
    manual.complete(info);
    await Future.wait([first, second]);
    expect(manualCalls, 1);
    verify(check.clearReminder).called(1);
  });
  test('automatic check joins an active manual check', () async {
    final first = start(byHand: true);
    await manualStarted.future;
    final second = start();
    expect(automaticCalls, 0);
    manual.complete(info);
    await Future.wait([first, second]);
    expect(current().status, UpdateStatus.available);
  });
  test('manual check supersedes the skip-aware automatic result', () async {
    final first = start();
    await manualResult();
    automatic.complete(null);
    await first;
    expect(manualCalls, 1);
    expect(automaticCalls, 1);
    expect(current().versionInfo, same(info));
    expect(current().status, UpdateStatus.available);
  });
  test('reset invalidates a pending check', () async {
    final task = start(byHand: true);
    await manualStarted.future;
    notifier.reset();
    manual.complete(info);
    await task;
    expect(current().status, UpdateStatus.idle);
    expect(current().versionInfo, isNull);
  });
  test('skip invalidates a pending check', () async {
    final task = start();
    await notifier.skipVersion(info.version);
    automatic.complete(info);
    await task;
    expect(current().status, UpdateStatus.idle);
    expect(current().versionInfo, isNull);
  });
  test(
    'dispose ignores a pending check without publishing or reading providers',
    () async {
      final task = start(byHand: true);
      await manualStarted.future;
      container.dispose();
      disposed = true;
      manual.complete(info);
      await task;
    },
  );
  test('already downloaded package refuses new checks', () async {
    await manualResult();
    await notifier.downloadUpdate();
    await start(byHand: true);
    await start();
    expect(automaticCalls, 0);
    expect(manualCalls, 1);
    expect(current().downloadedUpdate, same(downloaded));
  });
}

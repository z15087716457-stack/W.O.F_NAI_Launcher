import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_installation_service.dart';
import 'package:nai_launcher/core/services/update_installer_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';
import 'package:nai_launcher/data/models/version/version_info.dart';
import 'package:path/path.dart' as p;

class _SupportedInstallationService extends AppInstallationService {
  @override
  bool get supportsInAppInstall => true;
}

void main() {
  group('UpdateInstallerService', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nai_update_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('calculates and compares SHA256 checksums', () async {
      final file = File('${tempDir.path}/update.exe');
      await file.writeAsString('installer bytes');

      final hash = await UpdateInstallerService.calculateSha256(file);

      expect(
        hash,
        'e34210a6de4f653edf588301431c3d69a633638cbf587345cc50a7fed9f38f4c',
      );
      expect(
        UpdateInstallerService.equalsSha256(hash, hash.toUpperCase()),
        isTrue,
      );
      expect(UpdateInstallerService.equalsSha256(hash, 'bad'), isFalse);
    });

    test('writes a UTF-8 BOM script and launches before shutdown', () async {
      final file = File('${tempDir.path}/update.zip');
      await file.writeAsString('synthetic verified package');
      final asset = ReleaseAssetInfo(
        type: ReleaseAssetType.windowsPortable,
        platform: 'windows',
        fileName: 'update.zip',
        downloadUrl: 'https://example.invalid/update.zip',
        sha256: await UpdateInstallerService.calculateSha256(file),
        size: await file.length(),
      );
      final events = <String>[];
      final service = UpdateInstallerService(
        dio: Dio(),
        installationService: _SupportedInstallationService(),
        updateDirectory: tempDir,
        scriptLauncher: (path) async {
          final bytes = await File(path).readAsBytes();
          expect(bytes.take(3), [0xef, 0xbb, 0xbf]);
          final script = utf8.decode(bytes.skip(3).toList());
          expect(script, contains('Wait-ApplicationExit'));
          expect(script, contains(file.path));
          events.add('launch');
        },
        shutdownHandler: (code) async {
          expect(code, 0);
          events.add('shutdown');
        },
      );
      await service.installAndRestart(
        DownloadedUpdate(file: file, asset: asset, version: '9.9.9'),
      );
      expect(events, ['launch', 'shutdown']);
    }, skip: !Platform.isWindows);

    test('a helper launch failure keeps the application open', () async {
      final file = File('${tempDir.path}/update.zip');
      await file.writeAsString('synthetic verified package');
      final asset = ReleaseAssetInfo(
        type: ReleaseAssetType.windowsPortable,
        platform: 'windows',
        fileName: 'update.zip',
        downloadUrl: 'https://example.invalid/update.zip',
        sha256: await UpdateInstallerService.calculateSha256(file),
        size: await file.length(),
      );
      var shutdown = false;
      final service = UpdateInstallerService(
        dio: Dio(),
        installationService: _SupportedInstallationService(),
        updateDirectory: tempDir,
        scriptLauncher: (_) async => throw const ProcessException(
          'powershell.exe',
          [],
          'Synthetic launch failure',
          1,
        ),
        shutdownHandler: (_) async {
          shutdown = true;
        },
      );
      await expectLater(
        service.installAndRestart(
          DownloadedUpdate(file: file, asset: asset, version: '9.9.9'),
        ),
        throwsA(isA<UpdateInstallException>()),
      );
      expect(shutdown, isFalse);
      expect(await file.exists(), isTrue);
    }, skip: !Platform.isWindows);

    test(
      'resumes a part file with Range and restores pending metadata',
      () async {
        final payload = List<int>.generate(128 * 1024, (index) => index % 251);
        final source = File('${tempDir.path}/source.bin');
        await source.writeAsBytes(payload);
        final hash = await UpdateInstallerService.calculateSha256(source);
        const fileName = 'resume-test.zip';
        final updateDir = Directory('${tempDir.path}/updates')..createSync();
        final partFile = File('${updateDir.path}/$fileName.part');
        const existingLength = 37 * 1024;
        await partFile.writeAsBytes(payload.take(existingLength).toList());

        final requests = <String?>[];
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          requests.add(request.headers.value(HttpHeaders.rangeHeader));
          final range = request.headers.value(HttpHeaders.rangeHeader);
          final start = range == null
              ? 0
              : int.parse(range.substring('bytes='.length).split('-').first);
          request.response.statusCode = range == null
              ? HttpStatus.ok
              : HttpStatus.partialContent;
          request.response.headers.contentLength = payload.length - start;
          if (range != null) {
            request.response.headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-${payload.length - 1}/${payload.length}',
            );
          }
          request.response.add(payload.sublist(start));
          await request.response.close();
        });

        try {
          final asset = ReleaseAssetInfo(
            type: ReleaseAssetType.windowsPortable,
            platform: 'windows',
            fileName: fileName,
            downloadUrl: 'http://127.0.0.1:${server.port}/update.zip',
            sha256: hash,
            size: payload.length,
          );
          final versionInfo = VersionInfo(
            version: '9.9.9',
            currentVersion: '1.0.0',
            releaseNotes: 'resume test',
            primaryAsset: asset,
            assets: [asset],
            isNewer: true,
          );
          final service = UpdateInstallerService(
            dio: Dio(),
            installationService: _SupportedInstallationService(),
            updateDirectory: updateDir,
          );

          final downloaded = await service.downloadUpdate(versionInfo);

          expect(requests, ['bytes=$existingLength-']);
          expect(await downloaded.file.readAsBytes(), payload);
          expect(await partFile.exists(), isFalse);
          final restored = await service.restorePendingUpdate();
          expect(restored, isNotNull);
          expect(restored!.versionInfo.version, '9.9.9');
          expect(restored.update.file.path, downloaded.file.path);
        } finally {
          await server.close(force: true);
        }
      },
    );

    test('cancelling during checksum keeps the resumable part file', () async {
      final payload = List<int>.generate(64 * 1024, (index) => index % 251);
      final source = File('${tempDir.path}/checksum-source.bin');
      await source.writeAsBytes(payload);
      final hash = await UpdateInstallerService.calculateSha256(source);
      const fileName = 'checksum-cancel.zip';
      final updateDir = Directory('${tempDir.path}/updates')..createSync();
      final hashStarted = Completer<void>();
      final releaseHash = Completer<void>();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });

      try {
        final asset = ReleaseAssetInfo(
          type: ReleaseAssetType.windowsPortable,
          platform: 'windows',
          fileName: fileName,
          downloadUrl: 'http://127.0.0.1:${server.port}/update.zip',
          sha256: hash,
          size: payload.length,
        );
        final versionInfo = VersionInfo(
          version: '9.9.9',
          currentVersion: '1.0.0',
          releaseNotes: 'checksum cancellation test',
          primaryAsset: asset,
          assets: [asset],
          isNewer: true,
        );
        final cancelToken = CancelToken();
        final service = UpdateInstallerService(
          dio: Dio(),
          installationService: _SupportedInstallationService(),
          updateDirectory: updateDir,
          sha256Calculator: (file) async {
            if (file.path.endsWith('.part')) {
              hashStarted.complete();
              await releaseHash.future;
            }
            return UpdateInstallerService.calculateSha256(file);
          },
        );

        final download = service.downloadUpdate(
          versionInfo,
          cancelToken: cancelToken,
        );
        await hashStarted.future;
        cancelToken.cancel('cancelled during checksum');
        releaseHash.complete();

        await expectLater(
          download,
          throwsA(isA<UpdateDownloadCancelledException>()),
        );
        expect(await File('${updateDir.path}/$fileName.part').exists(), isTrue);
        expect(await File('${updateDir.path}/$fileName').exists(), isFalse);
        expect(
          await File('${updateDir.path}/pending_update.json').exists(),
          isFalse,
        );
      } finally {
        await server.close(force: true);
      }
    });

    test('consumes updater result exactly once', () async {
      final updateDir = Directory('${tempDir.path}/updates')..createSync();
      final resultFile = File('${updateDir.path}/update_result.json');
      await resultFile.writeAsString('''
{"success":false,"version":"2.0.0","message":"access denied","logPath":"C:/update.log"}
''');
      final service = UpdateInstallerService(
        dio: Dio(),
        installationService: _SupportedInstallationService(),
        updateDirectory: updateDir,
      );

      final result = await service.consumeExecutionResult();

      expect(result, isNotNull);
      expect(result!.success, isFalse);
      expect(result.version, '2.0.0');
      expect(result.message, 'access denied');
      expect(await service.consumeExecutionResult(), isNull);
    });

    group('macOS app archive', () {
      const appName = 'W.O.F NAI Studio.app';
      late Directory updateDir;
      late File package;
      late ReleaseAssetInfo asset;
      late List<List<String>> calls;

      setUp(() async {
        updateDir = Directory(p.join(tempDir.path, 'updates'))..createSync();
        package = File(
          p.join(updateDir.path, 'WOF_NAI_Studio_macOS_2.1.0_Portable.zip'),
        );
        await package.writeAsString('app archive bytes');
        asset = ReleaseAssetInfo(
          type: ReleaseAssetType.macosPortable,
          platform: 'macos',
          fileName: p.basename(package.path),
          downloadUrl: 'https://example.com/macos.zip',
          sha256: await UpdateInstallerService.calculateSha256(package),
          size: await package.length(),
        );
        calls = [];
      });

      DownloadedUpdate update({String version = '2.1.0'}) =>
          DownloadedUpdate(file: package, asset: asset, version: version);

      /// 记下命令行；ditto 解压时照真实包的样子放一个应用包。
      UpdateProcessRunner runner({
        int dittoExit = 0,
        int openExit = 0,
        bool withApp = true,
      }) => (executable, arguments) async {
        calls.add([executable, ...arguments]);
        if (executable == '/usr/bin/ditto') {
          if (withApp) {
            Directory(
              p.join(arguments.last, appName, 'Contents', 'MacOS'),
            ).createSync(recursive: true);
          }
          return ProcessResult(1, dittoExit, '', 'ditto failed');
        }
        return ProcessResult(2, openExit, '', 'open failed');
      };

      UpdateInstallerService service(
        UpdateProcessRunner runProcess, {
        String? bundle,
      }) => UpdateInstallerService(
        dio: Dio(),
        installationService: _SupportedInstallationService(),
        updateDirectory: updateDir,
        runningMacBundle: bundle,
        runProcess: runProcess,
      );

      test(
        'unpacks the verified archive and selects the app in Finder',
        () async {
          final stale = Directory(p.join(updateDir.path, 'macos-2.0.9'))
            ..createSync();

          final app = await service(
            runner(),
          ).revealUpdateInFinder(update(version: '2.1.0+43'));

          final target = p.join(updateDir.path, 'macos-2.1.0_43');
          expect(app, p.join(target, appName));
          expect(calls, [
            ['/usr/bin/ditto', '-x', '-k', package.path, target],
            ['/usr/bin/open', '-R', app],
          ]);
          expect(stale.existsSync(), isFalse);
          expect(update().requiresManualReplace, isTrue);
        },
      );

      test('a failed unpack leaves no half-extracted app behind', () async {
        await expectLater(
          service(runner(dittoExit: 1)).revealUpdateInFinder(update()),
          throwsA(isA<UpdateInstallException>()),
        );

        expect(
          Directory(p.join(updateDir.path, 'macos-2.1.0')).existsSync(),
          isFalse,
        );
        expect(calls.single.first, '/usr/bin/ditto');
      });

      test('an archive without an app bundle is rejected', () async {
        await expectLater(
          service(runner(withApp: false)).revealUpdateInFinder(update()),
          throwsA(isA<UpdateInstallException>()),
        );

        expect(calls.map((call) => call.first), ['/usr/bin/ditto']);
      });

      test('reports where the app is when Finder cannot show it', () async {
        await expectLater(
          service(runner(openExit: 1)).revealUpdateInFinder(update()),
          throwsA(
            isA<UpdateInstallException>().having(
              (error) => error.message,
              'message',
              contains(p.join(updateDir.path, 'macos-2.1.0', appName)),
            ),
          ),
        );
      });

      test('a changed archive is not unpacked', () async {
        await package.writeAsString('tampered bytes!!!');

        await expectLater(
          service(runner()).revealUpdateInFinder(update()),
          throwsA(isA<UpdateInstallException>()),
        );
        expect(calls, isEmpty);
      });

      test('Windows packages never go through Finder', () async {
        final windows = DownloadedUpdate(
          file: package,
          asset: asset.copyWith(type: ReleaseAssetType.windowsPortable),
          version: '2.1.0',
        );

        await expectLater(
          service(runner()).revealUpdateInFinder(windows),
          throwsA(isA<UpdateInstallException>()),
        );
        expect(calls, isEmpty);
        expect(windows.requiresManualReplace, isFalse);
      });

      test(
        'a launch inside the extracted update preserves the archive, executable and pending record',
        () async {
          final app = await service(runner()).revealUpdateInFinder(update());
          final marker = await File(
            p.join(app, 'Contents', 'MacOS', 'runner'),
          ).writeAsString('running');
          final pending = await File(
            p.join(updateDir.path, 'pending_update.json'),
          ).writeAsString('pending');
          final alias = await Link(
            p.join(tempDir.path, 'update-alias'),
          ).create(updateDir.path);
          final bundle = p.join(
            alias.path,
            p.relative(app, from: updateDir.path),
          );
          final installer = service(runner(), bundle: bundle);
          expect(await installer.clearPendingUpdate(update()), false);
          expect(await package.readAsString(), 'app archive bytes');
          expect(await pending.readAsString(), 'pending');
          calls.clear();
          await installer.revealUpdateInFinder(update());
          expect(calls, [
            ['/usr/bin/open', '-R', bundle],
          ]);
          await installer.revealUpdateInFinder(update(version: '2.2.0'));
          expect(await marker.readAsString(), 'running');
        },
        skip: Platform.isWindows,
      );

      test(
        'clearing a replaced update removes the archive, app and record',
        () async {
          final installer = service(runner());
          final payload = await package.readAsBytes();
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          server.listen((request) async {
            request.response.headers.contentLength = payload.length;
            request.response.add(payload);
            await request.response.close();
          });
          try {
            await package.delete();
            final downloaded = await installer.downloadUpdate(
              VersionInfo(
                version: '2.1.0',
                currentVersion: '2.0.0',
                primaryAsset: asset.copyWith(
                  downloadUrl: 'http://127.0.0.1:${server.port}/macos.zip',
                ),
                isNewer: true,
              ),
            );
            final app = await installer.revealUpdateInFinder(downloaded);
            expect(await installer.restorePendingUpdate(), isNotNull);

            await installer.clearPendingUpdate(downloaded);

            expect(await installer.restorePendingUpdate(), isNull);
            expect(downloaded.file.existsSync(), isFalse);
            expect(Directory(app).existsSync(), isFalse);
            expect(
              File(p.join(updateDir.path, 'pending_update.json')).existsSync(),
              isFalse,
            );
          } finally {
            await server.close(force: true);
          }
        },
      );
    });

    test('DownloadedUpdate identifies portable zip packages', () {
      const portableAsset = ReleaseAssetInfo(
        type: ReleaseAssetType.windowsPortable,
        platform: 'windows',
        fileName: 'update.zip',
        downloadUrl: 'https://example.com/update.zip',
      );
      const installerAsset = ReleaseAssetInfo(
        type: ReleaseAssetType.windowsInstaller,
        platform: 'windows',
        fileName: 'setup.exe',
        downloadUrl: 'https://example.com/setup.exe',
      );

      expect(
        DownloadedUpdate(
          file: File('update.zip'),
          asset: portableAsset,
          version: '1.0.0',
        ).isPortableZip,
        isTrue,
      );
      expect(
        DownloadedUpdate(
          file: File('setup.exe'),
          asset: installerAsset,
          version: '1.0.0',
        ).isPortableZip,
        isFalse,
      );
    });
  });
}

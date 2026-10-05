import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/advanced_upscale_component_manager.dart';
import 'package:nai_launcher/data/services/local_upscale_model_manager.dart';
import 'package:nai_launcher/data/services/local_upscale_service.dart';

class _Process extends Mock implements Process {}

class _Input extends Mock implements IOSink {}

Uint8List _archive() {
  final dll = Uint8List.fromList([1, 2, 3, 4]);
  final license = utf8.encode('Test license');
  return Uint8List.fromList(
    ZipEncoder().encode(
      Archive()
        ..addFile(ArchiveFile('dll', dll.length, dll))
        ..addFile(ArchiveFile('license', license.length, license)),
    )!,
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final Future<ResponseBody> Function(RequestOptions) handler;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

Matcher error(LocalUpscaleError code) =>
    isA<LocalUpscaleException>().having((value) => value.code, 'code', code);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('studio-advanced-test-');
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  AdvancedUpscaleComponentManager fixture({
    required Future<ResponseBody> Function(RequestOptions) download,
    int probeExit = 0,
    bool available = true,
    void Function()? onProbe,
    bool badHash = false,
  }) {
    final dll = Uint8List.fromList([1, 2, 3, 4]);
    final license = utf8.encode('Test license');
    final zip = _archive();
    final worker = Uint8List.fromList([1, 3, 5]);
    final manifest = utf8.encode(
      jsonEncode({
        'worker': {
          'asset': 'windows/studio_upscale_worker.exe',
          'sha256': sha256.convert(worker).toString(),
        },
        'rtx': {
          'archive': {
            'url': 'https://component.test/sdk',
            'bytes': zip.length,
            'sha256': badHash ? '0' * 64 : sha256.convert(zip).toString(),
          },
          'files': [
            {
              'path': 'dll',
              'name': 'nvngx_vsr.dll',
              'bytes': dll.length,
              'sha256': sha256.convert(dll).toString(),
            },
            {
              'path': 'license',
              'name': 'LICENSE.pdf',
              'bytes': license.length,
              'sha256': sha256.convert(license).toString(),
            },
          ],
        },
      }),
    );
    final dio = Dio()
      ..httpClientAdapter = _Adapter((request) async {
        // The caller controls response faults. A full response uses this verified
        // tiny archive, never a real SDK or a network connection.
        final response = await download(request);
        if (response.statusCode == 299) return ResponseBody.fromBytes(zip, 200);
        return response;
      });
    return AdvancedUpscaleComponentManager(
      rootDirectory: () async =>
          Directory(p.join(temporary.path, 'components')),
      loadAsset: (name) async => Uint8List.fromList(
        name == 'advanced_manifest.json' ? manifest : worker,
      ),
      manifestDigest: sha256.convert(manifest).toString(),
      dio: dio,
      startProcess: (host, args, env) async {
        onProbe?.call();
        expect(args.take(3), ['--run', host, '--rtx-probe']);
        final process = _Process();
        final input = _Input();
        when(() => input.close()).thenAnswer((_) async {});
        when(() => process.stdin).thenReturn(input);
        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(
            Uint8List.fromList(
              utf8.encode(jsonEncode({'available': available})),
            ),
          ),
        );
        when(() => process.stderr).thenAnswer((_) => const Stream.empty());
        when(() => process.exitCode).thenAnswer((_) async => probeExit);
        return process;
      },
    );
  }

  test(
    'opening manager or resolving absent models never starts downloads',
    () async {
      var calls = 0;
      final manager = fixture(
        download: (_) async {
          calls++;
          throw StateError('unexpected download');
        },
      );
      addTearDown(manager.dispose);
      final models = await manager.models();
      expect(models.map((m) => m.id), ['seedvr2-3b', 'rtx-vsr']);
      expect(models.every((m) => !m.installed), isTrue);
      await expectLater(
        manager.command(
          'seedvr2-3b',
          'in',
          'out',
          512,
          512,
          LocalUpscaleCancellation(),
        ),
        throwsA(error(LocalUpscaleError.modelMissing)),
      );
      expect(calls, 0);
    },
  );

  test(
    'only a verified component and successful GPU probe become installed',
    () async {
      var probes = 0;
      final manager = fixture(
        download: (_) async => ResponseBody.fromBytes([], 299),
        onProbe: () => probes++,
      );
      addTearDown(manager.dispose);
      await manager.install(
        'rtx-vsr',
        cancellation: LocalUpscaleCancellation(),
      );
      expect(probes, 1);
      final models = await manager.models();
      expect(models.last.installed, isTrue);
      expect(models.last.diskBytes, greaterThan(0));
      final spec = await manager.command(
        'rtx-vsr',
        'input',
        'output',
        768,
        512,
        LocalUpscaleCancellation(),
      );
      expect(spec.arguments.last, '512');
      final receipt = jsonDecode(
        await File(p.join(manager.directory.path, 'rtx.json')).readAsString(),
      );
      final dll = File(
        p.join(
          manager.directory.path,
          'installs',
          receipt['installation'],
          'nvngx_vsr.dll',
        ),
      );
      await dll.writeAsBytes([9, 9, 9, 9]);
      await expectLater(
        manager.command(
          'rtx-vsr',
          'i',
          'o',
          32,
          32,
          LocalUpscaleCancellation(),
        ),
        throwsA(error(LocalUpscaleError.integrity)),
      );
      await manager.delete('rtx-vsr');
      expect((await manager.models()).last.installed, isFalse);
    },
  );

  test(
    'bad archive or unavailable GPU never exposes a partial installation',
    () async {
      for (final corrupt in [false, true]) {
        final manager = fixture(
          download: (_) async => ResponseBody.fromBytes([], 299),
          probeExit: 11,
          available: false,
          badHash: corrupt,
        );
        await expectLater(
          manager.install('rtx-vsr', cancellation: LocalUpscaleCancellation()),
          throwsA(
            error(
              corrupt ? LocalUpscaleError.integrity : LocalUpscaleError.noRtx,
            ),
          ),
        );
        expect((await manager.models()).last.installed, isFalse);
        expect(
          await Directory(
            p.join(manager.directory.path, 'installs'),
          ).list().toList(),
          isEmpty,
        );
        manager.dispose();
      }
    },
  );

  test(
    'partial responses resume at the correct byte and still verify the full archive',
    () async {
      final bytes = _archive();
      final offsets = <int>[];
      final manager = fixture(
        download: (request) async {
          final range = request.headers['Range'] as String?;
          final start = range == null
              ? 0
              : int.parse(range.substring(6, range.length - 1));
          offsets.add(start);
          final end = (start + 43).clamp(0, bytes.length);
          return ResponseBody.fromBytes(
            bytes.sublist(start, end),
            206,
            headers: {
              'content-range': ['bytes $start-${end - 1}/${bytes.length}'],
            },
          );
        },
      );
      addTearDown(manager.dispose);
      await manager.install(
        'rtx-vsr',
        cancellation: LocalUpscaleCancellation(),
      );
      expect(offsets.length, greaterThan(1));
      expect(offsets.take(3), [0, 43, 86]);
      expect((await manager.models()).last.installed, isTrue);
    },
  );

  test(
    'cancelled installation releases locks and keeps model downloads optional',
    () async {
      final cancellation = LocalUpscaleCancellation();
      final manager = fixture(
        download: (_) async {
          cancellation.cancel();
          return ResponseBody.fromBytes([], 299);
        },
      );
      addTearDown(manager.dispose);
      await expectLater(
        manager.install('rtx-vsr', cancellation: cancellation),
        throwsA(error(LocalUpscaleError.cancelled)),
      );
      manager.claimInference();
      await expectLater(
        manager.delete('rtx-vsr'),
        throwsA(error(LocalUpscaleError.busy)),
      );
      manager.releaseInference();
      expect((await manager.models()).last.installed, isFalse);
    },
  );

  test(
    'manifest identity and out-of-root markers cannot enable a component',
    () async {
      final manager = fixture(
        download: (_) async => throw StateError('no network'),
      );
      addTearDown(manager.dispose);
      await manager.initialize();
      final outside = Directory(p.join(temporary.path, 'outside'))
        ..createSync();
      final keep = File(p.join(outside.path, 'keep'))
        ..writeAsStringSync('keep');
      await File(p.join(manager.directory.path, 'rtx.json')).writeAsString(
        jsonEncode({
          'ready': true,
          'manifest': manager.manifestDigest,
          'installation': '../../outside',
          'files': [],
        }),
      );
      expect((await manager.models()).last.installed, isFalse);
      await manager.delete('rtx-vsr');
      expect(await keep.readAsString(), 'keep');
    },
  );

  test(
    'cached official RTX component runs through the service with exact size and alpha',
    () async {
      final dio = Dio()
        ..httpClientAdapter = _Adapter(
          (_) async => throw StateError('network forbidden'),
        );
      final manager = AdvancedUpscaleComponentManager(
        rootDirectory: () async =>
            Directory(p.join(temporary.path, 'real-components')),
        loadAsset: (name) =>
            File(p.join('assets/local_upscale', name)).readAsBytes(),
        dio: dio,
      );
      addTearDown(manager.dispose);
      await manager.initialize();
      final cache = Directory(p.join(manager.directory.path, 'downloads'));
      await cache.create();
      await File(
        '.dart_tool/advanced-upscale-20261005/rtx-video-sdk-1.1.0.zip',
      ).copy(
        p.join(
          cache.path,
          'abf4f34e2b5a618e355b0d5a0365d8ecc3db4396e756e4c850a867e1ae2ed69e',
        ),
      );
      await manager.install(
        'rtx-vsr',
        cancellation: LocalUpscaleCancellation(),
      );
      expect((await manager.models()).last.installed, isTrue);
      final base = LocalUpscaleModelManager(
        rootDirectory: () async => Directory(p.join(temporary.path, 'base')),
        loadAsset: (name) =>
            File(p.join('assets/local_upscale', name)).readAsBytes(),
      );
      addTearDown(base.dispose);
      final image = img.Image(width: 256, height: 192, numChannels: 4);
      for (final pixel in image) {
        pixel.setRgba(
          pixel.x % 255,
          pixel.y % 255,
          128,
          pixel.x < 128 ? 0 : 255,
        );
      }
      final phases = <LocalUpscalePhase>[];
      final output = await LocalUpscaleService(base, advanced: manager).upscale(
        Uint8List.fromList(img.encodePng(image)),
        modelId: 'rtx-vsr',
        scale: 1.75,
        cancellation: LocalUpscaleCancellation(),
        onProgress: (p) => phases.add(p.phase),
      );
      expect((output.width, output.height), (448, 336));
      final result = img.decodePng(output.bytes)!;
      expect(result.getPixel(0, 0).a, 0);
      expect(result.getPixel(400, 300).a, 255);
      expect(
        phases,
        containsAll([LocalUpscalePhase.inference, LocalUpscalePhase.complete]),
      );
      expect((await manager.models()).first.installed, isFalse);
    },
    skip:
        !Platform.isWindows ||
        Platform.environment['RUN_ADVANCED_UPSCALE_AUDIT'] != '1',
  );
}

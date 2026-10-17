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
import 'package:nai_launcher/data/services/owned_upscale_process.dart';

class _Process extends Mock implements Process {}

class _BaseModels extends Mock implements LocalUpscaleModelManager {}

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

  AdvancedUpscaleComponentManager seedFixture({
    int runtimeExit = 0,
    int inferenceExit = 0,
    int int8ProbeExit = 0,
    void Function()? onInt8Probe,
    String diagnostics = '',
    void Function(Map<String, String>)? onInferenceEnvironment,
    void Function(String)? onDownload,
    void Function()? onRuntime,
  }) {
    final worker = Uint8List.fromList([1, 3, 5]);
    final source = Uint8List.fromList(utf8.encode('source'));
    final uv = Uint8List.fromList(utf8.encode('uv'));
    final weights = Uint8List.fromList([4, 5, 6]);
    final sourceZip = Uint8List.fromList(
      ZipEncoder().encode(
        Archive()..addFile(ArchiveFile('pinned/cli.py', source.length, source)),
      )!,
    );
    final uvZip = Uint8List.fromList(
      ZipEncoder().encode(
        Archive()..addFile(ArchiveFile('uv.exe', uv.length, uv)),
      )!,
    );
    Map<String, Object> downloadSpec(Uint8List bytes, String name) => {
      'url': 'https://component.test/$name',
      'bytes': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
    };
    final manifest = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'worker': {
            'asset': 'worker',
            'sha256': sha256.convert(worker).toString(),
          },
          'seedvr2': {
            'python': '3.12.11',
            'source': {
              ...downloadSpec(sourceZip, 'source'),
              'prefix': 'pinned/',
              'files': [
                {
                  'path': 'cli.py',
                  'bytes': source.length,
                  'sha256': sha256.convert(source).toString(),
                },
              ],
            },
            'uv': {
              ...downloadSpec(uvZip, 'uv'),
              'executable_sha256': sha256.convert(uv).toString(),
            },
            for (final name in ['runner', 'requirements'])
              name: {
                'asset': name == 'runner' ? 'worker.py' : 'requirements.lock',
                'sha256': sha256.convert(worker).toString(),
              },
            'int8_files': [
              for (final name in ['worker_int8.py', 'native_int8.py'])
                {'asset': name, 'sha256': sha256.convert(worker).toString()},
            ],
            'models': [
              {
                ...downloadSpec(weights, 'weights'),
                'id': 'seedvr2-3b',
                'name': 'seedvr2_ema_3b_fp8_e4m3fn.safetensors',
              },
              {
                ...downloadSpec(Uint8List.fromList([7, 8, 9, 10]), 'weights7b'),
                'id': 'seedvr2-7b',
                'name': 'seedvr2_ema_7b_fp8_e4m3fn.safetensors',
              },
              {
                ...downloadSpec(
                  Uint8List.fromList([17, 18, 19]),
                  'weights7bSharp',
                ),
                'id': 'seedvr2-7b-sharp',
                'name': 'seedvr2_ema_7b_sharp_fp8_e4m3fn.safetensors',
              },
              {
                ...downloadSpec(Uint8List.fromList([31, 32]), 'weights3bInt8'),
                'id': 'seedvr2-3b-int8',
                'name': 'seedvr2_3b_int8_convrot.safetensors',
              },
              {
                ...downloadSpec(Uint8List.fromList([41, 42]), 'weights7bInt8'),
                'id': 'seedvr2-7b-int8',
                'name': 'seedvr2_7b_int8_convrot.safetensors',
              },
              {
                ...downloadSpec(
                  Uint8List.fromList([51, 52]),
                  'weights7bSharpInt8',
                ),
                'id': 'seedvr2-7b-sharp-int8',
                'name': 'seedvr2_7b_sharp_int8_convrot.safetensors',
              },
              {
                ...downloadSpec(Uint8List.fromList([10, 11]), 'vae'),
                'name': 'ema_vae_fp16.safetensors',
              },
            ],
          },
        }),
      ),
    );
    final dio = Dio()
      ..httpClientAdapter = _Adapter((request) async {
        onDownload?.call(request.uri.path);
        final bytes = switch (request.uri.path) {
          '/source' => sourceZip,
          '/uv' => uvZip,
          '/weights' => weights,
          '/weights7b' => Uint8List.fromList([7, 8, 9, 10]),
          '/weights7bSharp' => Uint8List.fromList([17, 18, 19]),
          '/weights3bInt8' => Uint8List.fromList([31, 32]),
          '/weights7bInt8' => Uint8List.fromList([41, 42]),
          '/weights7bSharpInt8' => Uint8List.fromList([51, 52]),
          '/vae' => Uint8List.fromList([10, 11]),
          _ => throw StateError('unexpected download'),
        };
        return ResponseBody.fromBytes(bytes, 200);
      });
    return AdvancedUpscaleComponentManager(
      rootDirectory: () async => Directory(p.join(temporary.path, 'seed')),
      loadAsset: (name) async =>
          name == 'advanced_manifest.json' ? manifest : worker,
      manifestDigest: sha256.convert(manifest).toString(),
      dio: dio,
      startProcess: (host, args, env) async {
        final venv = args[2] == 'venv';
        final sync = args[2] == 'pip';
        if (args.contains('--output')) {
          onInferenceEnvironment?.call(env);
          final output = args[args.indexOf('--output') + 1];
          final width = int.parse(args[args.indexOf('--max_resolution') + 1]);
          final height = int.parse(args[args.indexOf('--resolution') + 1]);
          await File(output).writeAsBytes(
            img.encodePng(img.Image(width: width, height: height)),
          );
        }
        final int8Probe =
            args.last == '--probe' &&
            args.any((value) => value.endsWith('worker_int8.py'));
        if (int8Probe) onInt8Probe?.call();
        if (args.last == '--probe') {
          expect(
            env['PYTORCH_CUDA_ALLOC_CONF'],
            AdvancedUpscaleComponentManager
                .seedRuntimeEnvironment['PYTORCH_CUDA_ALLOC_CONF'],
          );
          expect(env['PYTHONFAULTHANDLER'], '1');
          expect(env['HF_HUB_OFFLINE'], '1');
          expect(env['PYTHONIOENCODING'], 'utf-8');
        }
        if (venv) {
          onRuntime?.call();
          expect(args, contains('--managed-python'));
          final python = File(p.join(args.last, 'Scripts', 'python.exe'));
          await python.parent.create(recursive: true);
          await python.writeAsBytes(worker);
        }
        final process = _Process();
        final input = _Input();
        when(() => input.close()).thenAnswer((_) async {});
        when(() => process.stdin).thenReturn(input);
        when(() => process.stdout).thenAnswer(
          (_) => Stream.value(
            Uint8List.fromList(
              utf8.encode(venv || sync ? '' : '{"available":true}'),
            ),
          ),
        );
        when(() => process.stderr).thenAnswer(
          (_) => Stream.value(
            Uint8List.fromList(
              utf8.encode(sync || args.contains('--output') ? diagnostics : ''),
            ),
          ),
        );
        when(() => process.exitCode).thenAnswer(
          (_) async => sync
              ? runtimeExit
              : args.contains('--output')
              ? inferenceExit
              : int8Probe
              ? int8ProbeExit
              : 0,
        );
        return process;
      },
    );
  }

  test(
    'SeedVR2 offline fixture covers isolated runtime and model receipt',
    () async {
      final manager = seedFixture();
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      expect((await manager.models()).first.installed, isTrue);
    },
  );

  test(
    'all six SeedVR2 sizes exclude shared files and survive install/delete',
    () async {
      final manager = seedFixture();
      addTearDown(manager.dispose);
      final before = (await manager.models())
          .where((m) => m.method == LocalUpscaleMethod.seedvr2)
          .toList();
      expect(before.map((m) => m.modelBytes), [3, 4, 3, 2, 2, 2]);
      for (final model in before) {
        await manager.install(
          model.id,
          cancellation: LocalUpscaleCancellation(),
        );
        final installed = (await manager.models()).firstWhere(
          (m) => m.id == model.id,
        );
        expect(installed.installed, isTrue);
        expect(installed.modelBytes, model.modelBytes);
        expect(installed.diskBytes, model.modelBytes);
        await manager.delete(model.id);
        final removed = (await manager.models()).firstWhere(
          (m) => m.id == model.id,
        );
        expect(removed.installed, isFalse);
        expect(removed.modelBytes, model.modelBytes);
        expect(removed.diskBytes, 0);
      }
    },
  );

  test(
    'pinned model sizes are available offline without installing weights',
    () async {
      final manager = AdvancedUpscaleComponentManager(
        rootDirectory: () async => Directory(p.join(temporary.path, 'catalog')),
        loadAsset: (name) => File('assets/local_upscale/$name').readAsBytes(),
        dio: Dio()
          ..httpClientAdapter = _Adapter(
            (_) async => throw StateError('unexpected network'),
          ),
        startProcess: (_, __, ___) async =>
            throw StateError('unexpected process'),
      );
      addTearDown(manager.dispose);
      final models = await manager.models();
      expect(models.every((m) => !m.installed && m.diskBytes == 0), isTrue);
      expect(models.map((m) => m.modelBytes), [
        3391544696,
        8239729704,
        8239729704,
        3458259704,
        8334897976,
        8334897976,
        19276679,
      ]);
    },
  );

  test(
    'SeedVR2 inference inherits the same early allocator and offline environment as installation',
    () async {
      Map<String, String>? environment;
      final manager = seedFixture(
        onInferenceEnvironment: (value) => environment = value,
      );
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      final base = _BaseModels();
      final directory = Directory(p.join(temporary.path, 'base'))..createSync();
      when(() => base.directory).thenReturn(directory);
      when(() => base.initialize()).thenAnswer((_) async {});
      final result =
          await LocalUpscaleService(
            base,
            advanced: manager,
            supportedPlatform: true,
          ).upscale(
            Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 24))),
            modelId: 'seedvr2-3b',
            scale: 1.5,
            cancellation: LocalUpscaleCancellation(),
          );
      expect((result.width, result.height), (48, 36));
      expect(
        environment,
        containsPair(
          'PYTORCH_CUDA_ALLOC_CONF',
          AdvancedUpscaleComponentManager
              .seedRuntimeEnvironment['PYTORCH_CUDA_ALLOC_CONF'],
        ),
      );
      expect(environment, containsPair('PYTHONFAULTHANDLER', '1'));
      expect(environment, containsPair('HF_HUB_OFFLINE', '1'));
      verify(() => base.releaseInference()).called(1);
    },
  );

  test(
    'SeedVR2 runtime failure retains sanitized diagnostics and no receipt',
    () async {
      final manager = seedFixture(
        runtimeExit: 2,
        diagnostics:
            'download timed out https://user:private@example.test/wheel?token=private',
      );
      addTearDown(manager.dispose);
      await expectLater(
        manager.install('seedvr2-3b', cancellation: LocalUpscaleCancellation()),
        throwsA(
          isA<LocalUpscaleException>().having(
            (value) => value.details,
            'details',
            allOf(contains('download timed out'), isNot(contains('private'))),
          ),
        ),
      );
      expect((await manager.models()).first.installed, isFalse);
      expect(
        await Directory(
          p.join(manager.directory.path, 'installs'),
        ).list().isEmpty,
        isTrue,
      );
    },
  );

  test(
    'SeedVR2 variants share runtime and VAE without deleting each other',
    () async {
      var runtimes = 0;
      final downloads = <String>[];
      final manager = seedFixture(
        onRuntime: () => runtimes++,
        onDownload: downloads.add,
      );
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      final first = await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
      await manager.install(
        'seedvr2-7b',
        cancellation: LocalUpscaleCancellation(),
      );
      final second = await manager.command(
        'seedvr2-7b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
      expect(second.executable, first.executable);
      expect(
        second.arguments,
        contains('seedvr2_ema_7b_fp8_e4m3fn.safetensors'),
      );
      expect(runtimes, 1);
      expect(downloads, ['/source', '/uv', '/weights', '/vae', '/weights7b']);
      expect(
        (await manager.models()).take(2).every((m) => m.installed),
        isTrue,
      );
      await manager.delete('seedvr2-3b');
      expect((await manager.models()).take(2).map((m) => m.installed), [
        false,
        true,
      ]);
      await manager.command(
        'seedvr2-7b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      expect(runtimes, 1);
      expect(downloads.where((path) => path == '/vae').length, 1);
      await manager.delete('seedvr2-7b');
      expect((await manager.models()).first.installed, isTrue);
      await manager.delete('seedvr2-3b');
      expect(
        await File(p.join(manager.directory.path, 'seedvr2.json')).exists(),
        isFalse,
      );
    },
  );

  test(
    'Sharp reuses the verified older FP8 runtime and deletes only its own weights',
    () async {
      final downloads = <String>[];
      var runtimes = 0;
      final manager = seedFixture(
        onRuntime: () => runtimes++,
        onDownload: downloads.add,
      );
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      final before = await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
      final pointer = File(p.join(manager.directory.path, 'seedvr2.json'));
      final older =
          jsonDecode(await pointer.readAsString()) as Map<String, dynamic>;
      older['manifest'] =
          '0de0f816647899c778751c9f94a33dc259554eb6e37ba2330f80f74d36d2097c';
      await pointer.writeAsString(jsonEncode(older));
      expect((await manager.models()).first.installed, isTrue);
      await manager.install(
        'seedvr2-7b-sharp',
        cancellation: LocalUpscaleCancellation(),
      );
      final sharp = await manager.command(
        'seedvr2-7b-sharp',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
        seedvr2Options: const Seedvr2Options(blocksToSwap: 36),
      );
      expect(sharp.executable, before.executable);
      expect(
        sharp.arguments,
        contains('seedvr2_ema_7b_sharp_fp8_e4m3fn.safetensors'),
      );
      expect(
        sharp.arguments[sharp.arguments.indexOf('--blocks_to_swap') + 1],
        '36',
      );
      expect(runtimes, 1);
      expect(downloads, [
        '/source',
        '/uv',
        '/weights',
        '/vae',
        '/weights7bSharp',
      ]);
      expect((await manager.models()).take(3).map((m) => m.installed), [
        true,
        false,
        true,
      ]);
      await manager.delete('seedvr2-7b-sharp');
      expect((await manager.models()).take(3).map((m) => m.installed), [
        true,
        false,
        false,
      ]);
      await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
      expect(downloads.length, 5);
    },
  );

  test('INT8 adds only selected weights and reuses the FP8 runtime', () async {
    final calls = <String>[];
    var runtimes = 0;
    var probes = 0;
    final manager = seedFixture(
      onDownload: calls.add,
      onRuntime: () => runtimes++,
      onInt8Probe: () => probes++,
    );
    addTearDown(manager.dispose);
    await manager.install(
      'seedvr2-3b',
      cancellation: LocalUpscaleCancellation(),
    );
    final original = await manager.command(
      'seedvr2-3b',
      'in',
      'out',
      512,
      512,
      LocalUpscaleCancellation(),
    );
    calls.clear();
    await manager.models();
    expect(calls, isEmpty);
    await manager.install(
      'seedvr2-7b-sharp-int8',
      cancellation: LocalUpscaleCancellation(),
    );
    expect(calls, ['/weights7bSharpInt8']);
    expect(runtimes, 1);
    expect(probes, 1);
    final command = await manager.command(
      'seedvr2-7b-sharp-int8',
      'in',
      'out',
      512,
      512,
      LocalUpscaleCancellation(),
      seedvr2Options: const Seedvr2Options(blocksToSwap: 36),
    );
    expect(command.executable, original.executable);
    expect(command.arguments.first, endsWith('worker_int8.py'));
    expect(
      command.arguments,
      contains('seedvr2_7b_sharp_int8_convrot.safetensors'),
    );
    expect(
      command.arguments[command.arguments.indexOf('--blocks_to_swap') + 1],
      '36',
    );
    expect(
      (await manager.models())
          .where((model) => model.installed)
          .map((model) => model.id),
      ['seedvr2-3b', 'seedvr2-7b-sharp-int8'],
    );
    await manager.delete('seedvr2-7b-sharp-int8');
    expect(
      (await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        512,
        512,
        LocalUpscaleCancellation(),
      )).executable,
      original.executable,
    );
    await manager.delete('seedvr2-3b');
    expect((await manager.models()).every((model) => !model.installed), isTrue);
  });

  test('INT8 can install first without downloading any FP8 weights', () async {
    final calls = <String>[];
    final manager = seedFixture(onDownload: calls.add);
    addTearDown(manager.dispose);
    await manager.install(
      'seedvr2-3b-int8',
      cancellation: LocalUpscaleCancellation(),
    );
    expect(calls, ['/source', '/uv', '/weights3bInt8', '/vae']);
    expect(
      (await manager.models()).where((model) => model.installed).single.id,
      'seedvr2-3b-int8',
    );
    final command = await manager.command(
      'seedvr2-3b-int8',
      'in',
      'out',
      512,
      512,
      LocalUpscaleCancellation(),
    );
    calls.clear();
    await manager.install(
      'seedvr2-7b-int8',
      cancellation: LocalUpscaleCancellation(),
    );
    expect(calls, ['/weights7bInt8']);
    await manager.delete('seedvr2-3b-int8');
    expect(
      (await manager.command(
        'seedvr2-7b-int8',
        'in',
        'out',
        512,
        512,
        LocalUpscaleCancellation(),
      )).executable,
      command.executable,
    );
  });

  test('INT8 probe failure precedes weights and leaves FP8 intact', () async {
    final calls = <String>[];
    final manager = seedFixture(onDownload: calls.add, int8ProbeExit: 13);
    addTearDown(manager.dispose);
    await manager.install(
      'seedvr2-3b',
      cancellation: LocalUpscaleCancellation(),
    );
    final pointer = File(p.join(manager.directory.path, 'seedvr2.json'));
    final original = await pointer.readAsString();
    calls.clear();
    await expectLater(
      manager.install(
        'seedvr2-3b-int8',
        cancellation: LocalUpscaleCancellation(),
      ),
      throwsA(error(LocalUpscaleError.noInt8)),
    );
    expect(calls, isEmpty);
    expect(await pointer.readAsString(), original);
    await manager.command(
      'seedvr2-3b',
      'in',
      'out',
      512,
      512,
      LocalUpscaleCancellation(),
    );
  });

  test(
    'cancelled INT8 download removes new adapters without changing FP8',
    () async {
      final cancel = LocalUpscaleCancellation();
      final manager = seedFixture(
        onDownload: (path) {
          if (path == '/weights3bInt8') cancel.cancel();
        },
      );
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      final pointer = File(p.join(manager.directory.path, 'seedvr2.json'));
      final original = await pointer.readAsString();
      final receipt = jsonDecode(original) as Map;
      final root = p.join(
        manager.directory.path,
        'installs',
        receipt['installation'],
      );
      await expectLater(
        manager.install('seedvr2-3b-int8', cancellation: cancel),
        throwsA(error(LocalUpscaleError.cancelled)),
      );
      expect(await pointer.readAsString(), original);
      expect(await File(p.join(root, 'worker_int8.py')).exists(), isFalse);
      expect(await File(p.join(root, 'native_int8.py')).exists(), isFalse);
      await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        512,
        512,
        LocalUpscaleCancellation(),
      );
    },
  );

  test(
    'FP8 remains usable if an unrelated installed INT8 adapter is damaged',
    () async {
      final manager = seedFixture();
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      await manager.install(
        'seedvr2-3b-int8',
        cancellation: LocalUpscaleCancellation(),
      );
      final receipt =
          jsonDecode(
                await File(
                  p.join(manager.directory.path, 'seedvr2.json'),
                ).readAsString(),
              )
              as Map;
      await File(
        p.join(
          manager.directory.path,
          'installs',
          receipt['installation'],
          'native_int8.py',
        ),
      ).writeAsBytes([9, 9, 9]);
      await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        512,
        512,
        LocalUpscaleCancellation(),
      );
      await expectLater(
        manager.command(
          'seedvr2-3b-int8',
          'in',
          'out',
          512,
          512,
          LocalUpscaleCancellation(),
        ),
        throwsA(error(LocalUpscaleError.integrity)),
      );
    },
  );

  test('the previous FP8 receipt still requires exact file identity', () async {
    final manager = seedFixture();
    addTearDown(manager.dispose);
    await manager.install(
      'seedvr2-3b',
      cancellation: LocalUpscaleCancellation(),
    );
    final pointer = File(p.join(manager.directory.path, 'seedvr2.json'));
    final receipt =
        jsonDecode(await pointer.readAsString()) as Map<String, dynamic>;
    receipt['manifest'] =
        '0de0f816647899c778751c9f94a33dc259554eb6e37ba2330f80f74d36d2097c';
    (receipt['files'] as List).firstWhere(
      (file) => file['path'] == 'models/seedvr2_ema_3b_fp8_e4m3fn.safetensors',
    )['sha256'] = '0' * 64;
    await pointer.writeAsString(jsonEncode(receipt));
    expect((await manager.models()).first.installed, isFalse);
    await expectLater(
      manager.command(
        'seedvr2-3b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      ),
      throwsA(error(LocalUpscaleError.modelMissing)),
    );
  });

  test('7B can be installed first and 3B adds only its own weights', () async {
    final downloads = <String>[];
    var runtimes = 0;
    final manager = seedFixture(
      onDownload: downloads.add,
      onRuntime: () => runtimes++,
    );
    addTearDown(manager.dispose);
    await manager.install(
      'seedvr2-7b',
      cancellation: LocalUpscaleCancellation(),
    );
    expect((await manager.models()).take(2).map((model) => model.installed), [
      false,
      true,
    ]);
    await manager.install(
      'seedvr2-3b',
      cancellation: LocalUpscaleCancellation(),
    );
    expect(downloads, ['/source', '/uv', '/weights7b', '/vae', '/weights']);
    expect(runtimes, 1);
    await manager.delete('seedvr2-7b');
    await manager.command(
      'seedvr2-3b',
      'in',
      'out',
      64,
      64,
      LocalUpscaleCancellation(),
    );
  });

  test(
    'cancelled 7B addition leaves the existing 3B installation usable',
    () async {
      final cancellation = LocalUpscaleCancellation();
      final manager = seedFixture(
        onDownload: (path) {
          if (path == '/weights7b') cancellation.cancel();
        },
      );
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      await expectLater(
        manager.install('seedvr2-7b', cancellation: cancellation),
        throwsA(error(LocalUpscaleError.cancelled)),
      );
      expect((await manager.models()).take(2).map((m) => m.installed), [
        true,
        false,
      ]);
      await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
    },
  );

  test(
    'legacy 3B receipt survives only when current common and model hashes match',
    () async {
      final manager = seedFixture();
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-3b',
        cancellation: LocalUpscaleCancellation(),
      );
      final pointer = File(p.join(manager.directory.path, 'seedvr2.json'));
      final receipt =
          jsonDecode(await pointer.readAsString()) as Map<String, dynamic>;
      receipt['manifest'] =
          '7d72744fc08f883bfd754d48ab35c0349c77caa3d16af41c1add37649a4ce337';
      await pointer.writeAsString(jsonEncode(receipt));
      expect((await manager.models()).first.installed, isTrue);
      expect((await manager.models())[1].installed, isFalse);
      final requirements = (receipt['files'] as List).firstWhere(
        (item) => item['path'] == 'requirements.lock',
      );
      requirements['sha256'] = '0' * 64;
      await pointer.writeAsString(jsonEncode(receipt));
      expect((await manager.models()).first.installed, isFalse);
    },
  );

  test(
    'corrupt sibling weights do not prevent inference with verified 3B',
    () async {
      final manager = seedFixture();
      addTearDown(manager.dispose);
      for (final id in ['seedvr2-3b', 'seedvr2-7b']) {
        await manager.install(id, cancellation: LocalUpscaleCancellation());
      }
      final command = await manager.command(
        'seedvr2-7b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
      final modelDirectory =
          command.arguments[command.arguments.indexOf('--model_dir') + 1];
      await File(
        p.join(modelDirectory, 'seedvr2_ema_7b_fp8_e4m3fn.safetensors'),
      ).writeAsBytes([0, 0, 0, 0]);
      await expectLater(
        manager.command(
          'seedvr2-7b',
          'in',
          'out',
          64,
          64,
          LocalUpscaleCancellation(),
        ),
        throwsA(error(LocalUpscaleError.integrity)),
      );
      await manager.command(
        'seedvr2-3b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
      );
    },
  );

  test(
    'SeedVR2 options normalize malformed values without changing defaults',
    () {
      expect(
        const Seedvr2Options().toJson(),
        Seedvr2Options.fromJson(null, modelId: 'seedvr2-3b').toJson(),
      );
      final value = Seedvr2Options.fromJson({
        'seed': -3,
        'colorCorrection': '--unsafe',
        'blocksToSwap': 99,
        'vaeTileSize': 200,
        'vaeTileOverlap': 999,
        'inputNoise': double.nan,
        'latentNoise': 2,
        'vaeTiled': 'false',
      }, modelId: 'seedvr2-3b');
      expect(value.seed, 0);
      expect(value.colorCorrection, 'lab');
      expect(value.blocksToSwap, 32);
      expect(value.vaeTileSize, 192);
      expect(value.vaeTileOverlap, 128);
      expect(value.inputNoise, 0);
      expect(value.latentNoise, 1);
      expect(value.vaeTiled, isTrue);
      expect(
        Seedvr2Options.fromJson(value.toJson(), modelId: 'seedvr2-3b').toJson(),
        value.toJson(),
      );
      expect(
        const Seedvr2Options(
          blocksToSwap: 36,
        ).normalized('seedvr2-7b').blocksToSwap,
        36,
      );
    },
  );

  test(
    'SeedVR2 command uses selected advanced parameters and fixed safe backend',
    () async {
      final manager = seedFixture();
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-7b',
        cancellation: LocalUpscaleCancellation(),
      );
      final command = await manager.command(
        'seedvr2-7b',
        'in',
        'out',
        64,
        64,
        LocalUpscaleCancellation(),
        seedvr2Options: const Seedvr2Options(
          seed: 123,
          colorCorrection: 'wavelet',
          blocksToSwap: 36,
          vaeTiled: false,
          inputNoise: .1,
          latentNoise: .2,
        ),
      );
      String argument(String name) =>
          command.arguments[command.arguments.indexOf(name) + 1];
      expect(argument('--seed'), '123');
      expect(argument('--color_correction'), 'wavelet');
      expect(argument('--blocks_to_swap'), '36');
      expect(argument('--input_noise_scale'), '0.1');
      expect(argument('--latent_noise_scale'), '0.2');
      expect(argument('--attention_mode'), 'sdpa');
      expect(command.arguments, contains('--swap_io_components'));
      expect(command.arguments, isNot(contains('--vae_encode_tiled')));
      expect(command.arguments, isNot(contains('--vae_decode_tiled')));
      expect(
        command.arguments,
        contains('seedvr2_ema_7b_fp8_e4m3fn.safetensors'),
      );
      final defaults = const Seedvr2Options().arguments('seedvr2-3b');
      expect(
        defaults,
        containsAll([
          '--vae_encode_tiled',
          '--vae_decode_tiled',
          '1024',
          '128',
        ]),
      );
      expect(defaults, isNot(contains('--swap_io_components')));
    },
  );

  test(
    'bundled SeedVR2 variants have pinned weights and synchronized manifest hash',
    () async {
      final bytes = await File(
        'assets/local_upscale/advanced_manifest.json',
      ).readAsBytes();
      expect(
        sha256.convert(bytes).toString(),
        AdvancedUpscaleComponentManager.manifestSha256,
      );
      final manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final models = manifest['seedvr2']['models'] as List;
      expect(
        models.where((file) => file['id'] != null).map((file) => file['id']),
        [
          'seedvr2-3b',
          'seedvr2-7b',
          'seedvr2-7b-sharp',
          'seedvr2-3b-int8',
          'seedvr2-7b-int8',
          'seedvr2-7b-sharp-int8',
        ],
      );
      final seven = models.firstWhere((file) => file['id'] == 'seedvr2-7b');
      expect(seven['bytes'], 8239729704);
      expect(
        seven['sha256'],
        '1fdbf3877b7d1eb266038d3a165a977f17dbb4daa4a0f0d334d5461476963037',
      );
      final sharp = models.firstWhere(
        (file) => file['id'] == 'seedvr2-7b-sharp',
      );
      expect(sharp['bytes'], 8239729704);
      expect(sharp['name'], 'seedvr2_ema_7b_sharp_fp8_e4m3fn.safetensors');
      expect(
        sharp['sha256'],
        '4261d18fd9c331f4c8f14b475c9148bd8c3f1512240ace55fe31a179e0a960b0',
      );
      expect(
        sharp['url'],
        contains('/resolve/09ced71023636e9bc8cdf9cdecfb2625d1e691e8/'),
      );
      expect(Seedvr2Options.maxBlocks('seedvr2-7b-sharp'), 36);
      for (final model in advancedUpscaleCatalog.where(
        (model) => model.isSeedvr2Int8,
      )) {
        final weight = models.firstWhere((file) => file['id'] == model.id);
        expect(weight['bytes'], model.isSeedvr2Seven ? 8334897976 : 3458259704);
        expect(
          weight['url'],
          contains(
            '/resolve/df48879708206a403d2a61acd55578c2e80fd233/diffusion_models/',
          ),
        );
        expect(
          Seedvr2Options.maxBlocks(model.id),
          model.isSeedvr2Seven ? 36 : 32,
        );
      }
      for (final file in manifest['seedvr2']['int8_files'] as List) {
        final bytes = await File(
          'assets/local_upscale/${file['asset']}',
        ).readAsBytes();
        expect(sha256.convert(bytes).toString(), file['sha256']);
      }
      expect(manifest['seedvr2']['package_versions']['transformers'], '4.55.4');
      final lock = await File(
        'assets/local_upscale/seedvr2/requirements.lock',
      ).readAsBytes();
      expect(
        sha256.convert(lock).toString(),
        manifest['seedvr2']['requirements']['sha256'],
      );
    },
  );

  test(
    'SeedVR2 out-of-memory fails clearly without changing model or exposing secrets',
    () async {
      final manager = seedFixture(
        inferenceExit: 1,
        diagnostics:
            '{"error":"OutOfMemoryError","detail":"CUDA out of memory https://private.test/?token=private"}',
      );
      addTearDown(manager.dispose);
      await manager.install(
        'seedvr2-7b',
        cancellation: LocalUpscaleCancellation(),
      );
      final base = _BaseModels();
      when(
        () => base.directory,
      ).thenReturn(Directory(p.join(temporary.path, 'base'))..createSync());
      when(() => base.initialize()).thenAnswer((_) async {});
      final service = LocalUpscaleService(
        base,
        advanced: manager,
        supportedPlatform: true,
      );
      await expectLater(
        service.upscale(
          Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 24))),
          modelId: 'seedvr2-7b',
          scale: 2,
          cancellation: LocalUpscaleCancellation(),
        ),
        throwsA(
          isA<LocalUpscaleException>()
              .having(
                (error) => error.code,
                'code',
                LocalUpscaleError.outOfMemory,
              )
              .having(
                (error) => error.details,
                'details',
                allOf(
                  contains('CUDA out of memory'),
                  isNot(contains('private')),
                ),
              ),
        ),
      );
      expect((await manager.models()).take(2).map((model) => model.installed), [
        false,
        true,
      ]);
      expect(service.isRunning, isFalse);
      verify(() => base.releaseInference()).called(1);
    },
  );

  test(
    'bounded diagnostics preserve the first failure and the final result',
    () async {
      final process = _Process();
      final input = _Input();
      when(() => input.close()).thenAnswer((_) async {});
      when(() => process.stdin).thenReturn(input);
      when(() => process.stdout).thenAnswer(
        (_) => Stream.fromIterable([
          utf8.encode('fatal initialization frame\n'),
          for (var index = 0; index < 400; index++)
            utf8.encode('stack frame $index ${'x' * 60}\n'),
          utf8.encode('final error result\n'),
        ]),
      );
      when(() => process.stderr).thenAnswer((_) => const Stream.empty());
      when(() => process.exitCode).thenAnswer((_) async => 11);
      final result = await runOwnedUpscaleProcess(
        host: 'fake',
        executable: 'fake',
        arguments: [],
        cancellation: LocalUpscaleCancellation(),
        startProcess: (_, __, ___) async => process,
      );
      expect(result.diagnostics.length, lessThanOrEqualTo(16384));
      expect(
        result.diagnostics.trimLeft(),
        startsWith('fatal initialization frame'),
      );
      expect(result.diagnostics, endsWith('final error result'));
      final display = AdvancedUpscaleComponentManager.safeDiagnostics(
        result.diagnostics,
      );
      expect(display.length, lessThanOrEqualTo(4096));
      expect(display, startsWith('fatal initialization frame'));
      expect(display, endsWith('final error result'));
    },
  );

  test(
    'SeedVR2 manifest updates preserve only hash-matching legacy RTX receipts',
    () async {
      final manager = fixture(
        download: (_) async => ResponseBody.fromBytes([], 299),
      );
      addTearDown(manager.dispose);
      await manager.install(
        'rtx-vsr',
        cancellation: LocalUpscaleCancellation(),
      );
      final pointer = File(p.join(manager.directory.path, 'rtx.json'));
      final receipt =
          jsonDecode(await pointer.readAsString()) as Map<String, dynamic>;
      receipt['manifest'] =
          'c89c13dbf28b78b3a09ee8820715ac7c2850d84c4ec98742c56e46406cb7924b';
      await pointer.writeAsString(jsonEncode(receipt));
      expect((await manager.models()).last.installed, isTrue);
      final originalHash = receipt['files'][0]['sha256'];
      receipt['files'][0]['sha256'] = '0' * 64;
      await pointer.writeAsString(jsonEncode(receipt));
      expect((await manager.models()).last.installed, isFalse);
      receipt['files'][0]['sha256'] = originalHash;
      receipt['manifest'] = 'a' * 64;
      await pointer.writeAsString(jsonEncode(receipt));
      expect((await manager.models()).last.installed, isFalse);
    },
  );

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
      expect(models.map((m) => m.id), [
        'seedvr2-3b',
        'seedvr2-7b',
        'seedvr2-7b-sharp',
        'seedvr2-3b-int8',
        'seedvr2-7b-int8',
        'seedvr2-7b-sharp-int8',
        'rtx-vsr',
      ]);
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
      final beforeSize = (await manager.models()).last.modelBytes;
      expect(beforeSize, 16);
      await manager.install(
        'rtx-vsr',
        cancellation: LocalUpscaleCancellation(),
      );
      expect(probes, 1);
      final models = await manager.models();
      expect(models.last.installed, isTrue);
      expect(models.last.diskBytes, greaterThan(0));
      expect(models.last.modelBytes, beforeSize);
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

  if (Platform.environment['RUN_SEEDVR2_RUNTIME_AUDIT'] == '1') {
    test(
      'SeedVR2 isolated runtime audit stops before model downloads',
      () async {
        final root = Directory(
          '.dart_tool/seedvr2-runtime-audit-20261006',
        ).absolute;
        await root.create(recursive: true);
        final assets =
            jsonDecode(
                  await File(
                    'assets/local_upscale/advanced_manifest.json',
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        final seed = assets['seedvr2'] as Map<String, dynamic>;
        final cancellation = LocalUpscaleCancellation();
        var phase = '';
        var reachedWeights = false;
        final previous = Directory(
          '.dart_tool/advanced-upscale-20261005/uv-cache',
        );
        final cache = Directory(p.join(root.path, 'uv-cache'));
        await cache.create(recursive: true);
        if (await previous.exists()) {
          await for (final entry in previous.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entry is! File) continue;
            final target = File(
              p.join(cache.path, p.relative(entry.path, from: previous.path)),
            );
            if (await target.exists()) continue;
            await target.parent.create(recursive: true);
            await entry.copy(target.path);
          }
        }
        final dio = Dio()
          ..httpClientAdapter = _Adapter((request) async {
            final file = request.uri.toString() == seed['source']['url']
                ? File(
                    '.dart_tool/advanced-upscale-20261005/seedvr2-source.zip',
                  )
                : request.uri.toString() == seed['uv']['url']
                ? File('.dart_tool/advanced-upscale-20261005/uv-0.12.17.zip')
                : throw StateError(
                    'Model and other component downloads are forbidden in this audit',
                  );
            return ResponseBody.fromBytes(await file.readAsBytes(), 200);
          });
        final manager = AdvancedUpscaleComponentManager(
          rootDirectory: () async => root,
          loadAsset: (name) =>
              File(p.join('assets/local_upscale', name)).readAsBytes(),
          dio: dio,
          proxyAddress: () => '127.0.0.1:7897',
          startProcess: (host, args, env) async {
            if (args.last == '--probe') {
              final check = await runOwnedUpscaleProcess(
                host: host,
                executable: args[1],
                arguments: [
                  '-X',
                  'faulthandler',
                  '-c',
                  'import torch; print(torch.__version__, flush=True); print(torch.cuda.is_available(), flush=True); a = torch.randn(8, 8, dtype=torch.bfloat16, device="cuda:0"); print(torch.matmul(a, a).shape, flush=True)',
                ],
                cancellation: cancellation,
              );
              final result = {
                'exit': check.exitCode,
                'diagnostics': AdvancedUpscaleComponentManager.safeDiagnostics(
                  check.diagnostics,
                ),
              };
              await File(
                p.join(root.path, 'torch-probe.json'),
              ).writeAsString(jsonEncode(result));
              print('PyTorch probe: ${jsonEncode(result)}');
              expect(check.exitCode, 0);
              for (final early in [false, true]) {
                final configured = await runOwnedUpscaleProcess(
                  host: host,
                  executable: args[1],
                  arguments: [
                    '-X',
                    'faulthandler',
                    '-c',
                    'import os; os.environ.pop("PYTORCH_CUDA_ALLOC_CONF", None); '
                        '${early ? 'os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "backend:cudaMallocAsync"; ' : ''}'
                        'import torch; print(torch.cuda.is_available(), flush=True); '
                        '${early ? '' : 'os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "backend:cudaMallocAsync"; '}'
                        'a = torch.randn(8, 8, dtype=torch.bfloat16, device="cuda:0"); print(torch.matmul(a, a).shape, flush=True)',
                  ],
                  cancellation: cancellation,
                );
                final data = {
                  'early': early,
                  'exit': configured.exitCode,
                  'diagnostics':
                      AdvancedUpscaleComponentManager.safeDiagnostics(
                        configured.diagnostics,
                      ),
                };
                print('CUDA allocator probe: ${jsonEncode(data)}');
                expect(configured.exitCode == 0, early);
                await File(
                  p.join(root.path, 'allocator-$early.json'),
                ).writeAsString(jsonEncode(data));
              }
            }
            return Process.start(host, args, environment: env);
          },
        );
        addTearDown(manager.dispose);
        try {
          await manager.install(
            'seedvr2-3b',
            cancellation: cancellation,
            onProgress: (next, _) {
              if (phase != next) {
                phase = next;
                print('SeedVR2 runtime audit: $phase');
              }
              if (next == 'weights') {
                reachedWeights = true;
                cancellation.cancel();
              }
            },
          );
          fail('Audit must stop before weights');
        } on LocalUpscaleException catch (failure) {
          final result = {
            'phase': phase,
            'code': failure.code.name,
            'diagnostics': failure.details,
            'runtime_and_gpu_probe_passed': reachedWeights,
            'model_downloaded': false,
            'installation_committed': false,
          };
          await File(
            p.join(root.path, 'result.json'),
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(result));
          if (!reachedWeights || failure.code != LocalUpscaleError.cancelled) {
            fail(
              'SeedVR2 runtime failed at $phase: ${failure.code.name}\n${failure.details ?? ''}',
            );
          }
        }
        expect(reachedWeights, isTrue);
        expect((await manager.models()).first.installed, isFalse);
      },
      timeout: const Timeout(Duration(hours: 4)),
    );
  }

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
    skip: !Platform.isWindows
        ? 'Requires Windows and an RTX GPU; kept as an opt-in native audit'
        : Platform.environment['RUN_ADVANCED_UPSCALE_AUDIT'] != '1'
        ? 'Opt in with RUN_ADVANCED_UPSCALE_AUDIT=1; requires an RTX GPU and the cached SDK archive'
        : false,
  );
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/pica_lanczos_resizer.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/local_upscale_model_manager.dart';
import 'package:nai_launcher/data/services/local_upscale_service.dart';

class _Process extends Mock implements Process {}

Uint8List _source({bool alpha = false, int width = 48, int height = 32}) {
  final image = img.Image(
    width: width,
    height: height,
    numChannels: alpha ? 4 : 3,
  );
  for (final pixel in image) {
    pixel.setRgba(
      pixel.x * 255 ~/ width,
      pixel.y * 255 ~/ height,
      100,
      alpha
          ? (pixel.x < width ~/ 4
                ? 0
                : pixel.x < width ~/ 2
                ? 128
                : 255)
          : 255,
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

Matcher _error(LocalUpscaleError code) =>
    isA<LocalUpscaleException>().having((e) => e.code, 'code', code);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late LocalUpscaleModelManager manager;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('studio-upscale-test-');
    manager = LocalUpscaleModelManager(
      rootDirectory: () async => Directory(p.join(temporary.path, 'runtime')),
      loadAsset: (name) =>
          File(p.join('assets', 'local_upscale', name)).readAsBytes(),
    );
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  test(
    'real Flutter bundle extracts the pinned offline engine and default model',
    () async {
      final bundled = LocalUpscaleModelManager(
        rootDirectory: () async =>
            Directory(p.join(temporary.path, 'bundle-runtime')),
      );
      final (engine, modelPath, model) = await bundled.resolve('anime');
      expect(await File(engine).length(), 6161408);
      expect(
        await File(p.join(modelPath, '${model.engineName}.bin')).length(),
        8943500,
      );
      bundled.dispose();
    },
  );

  test(
    'bundled model is offline; resolve verifies engine and model hashes on every run',
    () async {
      final items = await manager.models();
      expect(items.first.installed, isTrue);
      expect(items.skip(1).every((m) => !m.installed), isTrue);
      final (engine, _, _) = await manager.resolve('anime');
      await File(engine).writeAsBytes([1, 2, 3]);
      await expectLater(
        manager.resolve('anime'),
        throwsA(_error(LocalUpscaleError.integrity)),
      );
    },
  );

  test(
    'catalog sizes remain available before install and after removal',
    () async {
      final before = await manager.models();
      expect(before.map((model) => model.modelBytes), [
        8973790,
        3751527,
        33540549,
      ]);
      for (final model in before.skip(1)) {
        final target = Directory(
          p.join(manager.directory.path, 'models', model.id),
        );
        await target.create();
        // Presence fixtures only: resolving/inference still requires real hashes.
        for (final scale in model.scales) {
          final stem = model.id == 'anime-fast'
              ? '${model.engineName}-x$scale'
              : model.engineName;
          for (final extension in ['bin', 'param']) {
            await File(
              p.join(target.path, '$stem.$extension'),
            ).writeAsBytes([1]);
          }
        }
        final installed = (await manager.models()).firstWhere(
          (m) => m.id == model.id,
        );
        expect(installed.installed, isTrue);
        expect(installed.modelBytes, model.modelBytes);
        await manager.delete(model.id);
        final removed = (await manager.models()).firstWhere(
          (m) => m.id == model.id,
        );
        expect(removed.installed, isFalse);
        expect(removed.modelBytes, model.modelBytes);
      }
    },
  );

  test(
    'model import uses actual engine blob names, verifies copies, and cannot mutate active models',
    () async {
      await manager.initialize();
      final param = File(
        'assets/local_upscale/models/realesrgan-x4plus-anime.param',
      );
      final weights = File(
        'assets/local_upscale/models/realesrgan-x4plus-anime.bin',
      );
      final id = await manager.importPair(param, weights);
      final imported = (await manager.resolve(id)).$3;
      expect(imported.custom, isTrue);
      expect(
        imported.modelBytes,
        await param.length() + await weights.length(),
      );
      manager.claimInference(id);
      await expectLater(
        manager.delete(id),
        throwsA(_error(LocalUpscaleError.busy)),
      );
      expect(
        () => manager.claimInference('anime'),
        throwsA(_error(LocalUpscaleError.busy)),
      );
      manager.releaseInference();
      await manager.delete(id);
      await expectLater(
        manager.resolve(id),
        throwsA(_error(LocalUpscaleError.modelMissing)),
      );
      await expectLater(
        manager.delete('../outside'),
        throwsA(_error(LocalUpscaleError.invalidModel)),
      );
    },
  );

  test('invalid pair is rejected without exposing a partial model', () async {
    final param = File(p.join(temporary.path, 'bad.param'));
    final bin = File(p.join(temporary.path, 'bad.bin'));
    await param.writeAsString(
      '7767517\nInput input 0 1 in0\nConvolution conv 1 1 in0 out0',
    );
    await bin.writeAsBytes([1, 2, 3]);
    await expectLater(
      manager.importPair(param, bin),
      throwsA(_error(LocalUpscaleError.invalidModel)),
    );
    expect((await manager.models()).where((m) => m.custom), isEmpty);
  });

  test(
    'official optional models install from the verified archive and run natively',
    () async {
      // The release archive is downloaded once for this audit, never in a unit run.
      await manager.initialize();
      await File(
        '.dart_tool/local-upscale-20261005/official-models.zip',
      ).copy(p.join(manager.directory.path, 'official-models.zip'));
      for (final id in ['anime-fast', 'general']) {
        await manager.download(id);
        final resolved = await manager.resolve(id);
        expect(resolved.$3.installed, isTrue);
        final result = await LocalUpscaleService(manager).upscale(
          _source(),
          modelId: id,
          scale: 2.75,
          cancellation: LocalUpscaleCancellation(),
        );
        expect((result.width, result.height), (132, 88));
        expect(img.decodePng(result.bytes), isNotNull);
        await manager.delete(id);
      }
    },
    skip: !Platform.isWindows
        ? 'Requires Windows and Vulkan; kept as an opt-in native audit'
        : Platform.environment['RUN_LOCAL_UPSCALE_AUDIT'] != '1'
        ? 'Opt in with RUN_LOCAL_UPSCALE_AUDIT=1; requires Vulkan and the cached official model archive'
        : false,
  );

  test(
    'failure, Vulkan diagnostic and timeout clean up jobs and release the lock',
    () async {
      for (final scenario in ['process', 'vulkan', 'timeout']) {
        final process = _Process();
        final exit = Completer<int>();
        when(() => process.stdout).thenAnswer((_) => const Stream.empty());
        when(() => process.stderr).thenAnswer(
          (_) => Stream.value(
            Uint8List.fromList(
              scenario == 'vulkan'
                  ? 'vkCreateInstance failed'.codeUnits
                  : 'broken model'.codeUnits,
            ),
          ),
        );
        when(() => process.exitCode).thenAnswer((_) => exit.future);
        when(() => process.kill()).thenAnswer((_) {
          if (!exit.isCompleted) exit.complete(-1);
          return true;
        });
        final service = LocalUpscaleService(
          manager,
          supportedPlatform: true,
          timeout: const Duration(milliseconds: 60),
          startProcess: (_, args) async {
            expect(args, containsAll(['-m', '-s', '4', '-t', '128']));
            if (scenario != 'timeout') exit.complete(1);
            return process;
          },
        );
        await expectLater(
          service.upscale(
            _source(),
            modelId: 'anime',
            scale: 1.5,
            cancellation: LocalUpscaleCancellation(),
          ),
          throwsA(
            _error(switch (scenario) {
              'vulkan' => LocalUpscaleError.noVulkan,
              'timeout' => LocalUpscaleError.timeout,
              _ => LocalUpscaleError.processFailed,
            }),
          ),
        );
        expect(service.isRunning, isFalse);
        expect(
          await Directory(
            p.join(manager.directory.path, 'jobs'),
          ).list().toList(),
          isEmpty,
        );
        manager.claimInference('anime');
        manager.releaseInference();
      }
    },
  );

  test(
    'size cap and undecodable images never start the native worker',
    () async {
      var starts = 0;
      final service = LocalUpscaleService(
        manager,
        supportedPlatform: true,
        startProcess: (_, __) async {
          starts++;
          throw StateError('unexpected process');
        },
      );
      await expectLater(
        service.upscale(
          Uint8List.fromList([1, 2, 3]),
          modelId: 'anime',
          scale: 2,
          cancellation: LocalUpscaleCancellation(),
        ),
        throwsA(_error(LocalUpscaleError.invalidImage)),
      );
      await expectLater(
        service.upscale(
          _source(width: 2100, height: 2100),
          modelId: 'anime',
          scale: 1.5,
          cancellation: LocalUpscaleCancellation(),
        ),
        throwsA(_error(LocalUpscaleError.sizeLimit)),
      );
      expect(starts, 0);
    },
  );

  test(
    'GPU arbitration completes before work and releases on failure or cancellation',
    () async {
      for (final cancelled in [false, true]) {
        final order = <String>[];
        final cancellation = LocalUpscaleCancellation();
        final gate = Completer<void>();
        final service = LocalUpscaleService(
          manager,
          supportedPlatform: true,
          beforeInference: () async {
            order.add('suspend');
            await gate.future;
          },
          afterInference: () async {
            order.add('release');
            throw StateError('retrieval restart');
          },
          startProcess: (_, __) async {
            order.add('inference');
            throw StateError('native failure');
          },
        );
        final pending = service.upscale(
          cancelled ? _source() : Uint8List.fromList([1, 2]),
          modelId: 'anime',
          scale: 2,
          cancellation: cancellation,
        );
        final checked = expectLater(
          pending,
          throwsA(
            _error(
              cancelled
                  ? LocalUpscaleError.cancelled
                  : LocalUpscaleError.invalidImage,
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(order, ['suspend']);
        if (cancelled) cancellation.cancel();
        gate.complete();
        await checked;
        expect(order, ['suspend', 'release']);
        expect(service.isRunning, isFalse);
        manager.claimInference('anime');
        manager.releaseInference();
      }
    },
  );

  test(
    'real bundled native worker produces exact fractional targets, keeps alpha, and exits',
    () async {
      final service = LocalUpscaleService(manager);
      final progress = <LocalUpscaleProgress>[];
      for (final alpha in [false, true]) {
        final source = _source(alpha: alpha);
        final result = await service.upscale(
          source,
          modelId: 'anime',
          scale: alpha ? 1.5 : 2,
          cancellation: LocalUpscaleCancellation(),
          onProgress: progress.add,
        );
        final decoded = img.decodePng(result.bytes)!;
        expect((decoded.width, decoded.height), alpha ? (72, 48) : (96, 64));
        expect(
          decoded.getPixel(decoded.width - 1, decoded.height - 1).r,
          greaterThan(0),
        );
        if (alpha) {
          final expected = PicaLanczosResizer.resizeImage(
            img.decodePng(source)!,
            width: 72,
            height: 48,
          );
          for (final pixel in decoded) {
            expect(pixel.a, expected.getPixel(pixel.x, pixel.y).a);
          }
          expect(decoded.getPixel(0, 0).a, 0);
          expect(decoded.getPixel(30, 10).a, 128);
        }
        expect(service.isRunning, isFalse);
        expect(
          await Directory(
            p.join(manager.directory.path, 'jobs'),
          ).list().toList(),
          isEmpty,
        );
      }
      expect(
        progress.any(
          (p) => p.phase == LocalUpscalePhase.inference && p.fraction != null,
        ),
        isTrue,
      );
      expect(progress.last.fraction, 1);
    },
    skip: !Platform.isWindows
        ? 'Requires Windows and Vulkan; kept as an opt-in native audit'
        : Platform.environment['RUN_LOCAL_UPSCALE_AUDIT'] != '1'
        ? 'Opt in with RUN_LOCAL_UPSCALE_AUDIT=1; requires a working Vulkan GPU'
        : false,
  );

  test(
    'cancellation kills a real child even when it races with process creation',
    () async {
      final cancellation = LocalUpscaleCancellation();
      Process? child;
      final service = LocalUpscaleService(
        manager,
        startProcess: (exe, args) async {
          child = await Process.start(exe, args);
          cancellation.cancel();
          return child!;
        },
      );
      await expectLater(
        service.upscale(
          _source(),
          modelId: 'anime',
          scale: 4,
          cancellation: cancellation,
        ),
        throwsA(_error(LocalUpscaleError.cancelled)),
      );
      expect(child, isNotNull);
      expect(await child!.exitCode, isNonZero);
      expect(service.isRunning, isFalse);
      expect(
        await Directory(p.join(manager.directory.path, 'jobs')).list().toList(),
        isEmpty,
      );
    },
    skip: !Platform.isWindows
        ? 'Requires Windows and Vulkan; kept as an opt-in native audit'
        : Platform.environment['RUN_LOCAL_UPSCALE_AUDIT'] != '1'
        ? 'Opt in with RUN_LOCAL_UPSCALE_AUDIT=1; requires a working Vulkan GPU'
        : false,
  );
}

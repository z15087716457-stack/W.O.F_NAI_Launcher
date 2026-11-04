import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/pica_lanczos_resizer.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/advanced_upscale_component_manager.dart';
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
      platform: LocalUpscalePlatform.windows,
      rootDirectory: () async => Directory(p.join(temporary.path, 'runtime')),
      loadAsset: (name) =>
          File(p.join('assets', 'local_upscale', name)).readAsBytes(),
    );
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  // Opt-in audits run the real engine: on Windows the copy released from the
  // asset bundle; on macOS the one scripts/build_macos.sh put into an app
  // bundle, given as LOCAL_UPSCALE_MAC_TOOLS=<App>.app/Contents/Resources/tools.
  final macTools = Platform.environment['LOCAL_UPSCALE_MAC_TOOLS'];
  Object nativeAudit(String needs) => !Platform.isWindows && !Platform.isMacOS
      ? 'Requires Windows or macOS and Vulkan; kept as an opt-in native audit'
      : Platform.environment['RUN_LOCAL_UPSCALE_AUDIT'] != '1'
      ? 'Opt in with RUN_LOCAL_UPSCALE_AUDIT=1; $needs'
      : Platform.isMacOS && macTools == null
      ? 'Set LOCAL_UPSCALE_MAC_TOOLS to the tools folder of an app bundle built by scripts/build_macos.sh'
      : false;
  LocalUpscaleModelManager native() {
    if (!Platform.isMacOS) return manager;
    final mac = LocalUpscaleModelManager(
      platform: LocalUpscalePlatform.macOS,
      toolsDirectory: () => macTools!,
      rootDirectory: () async =>
          Directory(p.join(temporary.path, 'native-runtime')),
      loadAsset: (name) =>
          File(p.join('assets', 'local_upscale', name)).readAsBytes(),
    );
    addTearDown(mac.dispose);
    return mac;
  }

  test(
    'real Flutter bundle extracts the pinned offline engine and default model',
    () async {
      final bundled = LocalUpscaleModelManager(
        platform: LocalUpscalePlatform.windows,
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

  test('only Real-ESRGAN runs on macOS; SeedVR2 and RTX need Windows', () {
    for (final method in LocalUpscaleMethod.values) {
      expect(LocalUpscalePlatform.windows.supports(method), isTrue);
      expect(
        LocalUpscalePlatform.macOS.supports(method),
        method == LocalUpscaleMethod.standard,
      );
      expect(LocalUpscalePlatform.unsupported.supports(method), isFalse);
    }
  });

  test(
    'Windows releases its own engine and never reads the app bundle',
    () async {
      final windows = LocalUpscaleModelManager(
        platform: LocalUpscalePlatform.windows,
        toolsDirectory: () => throw StateError('app bundle tools on Windows'),
        rootDirectory: () async => Directory(p.join(temporary.path, 'windows')),
        loadAsset: (name) =>
            File(p.join('assets', 'local_upscale', name)).readAsBytes(),
      );
      addTearDown(windows.dispose);
      final (engine, _, _) = await windows.resolve('anime');
      expect(
        engine,
        p.join(windows.directory.path, 'windows', 'realesrgan-ncnn-vulkan.exe'),
      );
      expect(await File(engine).length(), 6161408);
    },
  );

  group('macOS', () {
    late Directory tools;
    late File engine;
    late List<String> assets;
    late LocalUpscaleModelManager mac;
    setUp(() async {
      tools = Directory(
        p.join(temporary.path, 'Studio.app', 'Contents', 'Resources', 'tools'),
      );
      engine = File(
        p.join(tools.path, 'local-upscale', 'realesrgan-ncnn-vulkan'),
      );
      await engine.create(recursive: true);
      await engine.writeAsBytes([0xcf, 0xfa, 0xed, 0xfe]);
      assets = [];
      mac = LocalUpscaleModelManager(
        platform: LocalUpscalePlatform.macOS,
        toolsDirectory: () => tools.path,
        rootDirectory: () async => Directory(p.join(temporary.path, 'mac')),
        loadAsset: (name) {
          assets.add(name);
          return File(p.join('assets', 'local_upscale', name)).readAsBytes();
        },
      );
    });
    tearDown(() => mac.dispose());

    Process finished() {
      final process = _Process();
      when(() => process.stdout).thenAnswer((_) => const Stream.empty());
      when(() => process.stderr).thenAnswer(
        (_) => Stream.value(Uint8List.fromList('100.00%\n'.codeUnits)),
      );
      when(() => process.exitCode).thenAnswer((_) async => 0);
      return process;
    }

    test(
      'runs the bundled engine with the Windows arguments and models, never the Windows files',
      () async {
        // Earlier macOS builds released the Windows engine; it is cleaned up.
        final leftover = File(
          p.join(
            temporary.path,
            'mac',
            'windows',
            'realesrgan-ncnn-vulkan.exe',
          ),
        );
        await leftover.create(recursive: true);
        final (executable, modelPath, model) = await mac.resolve('anime');
        expect(executable, engine.path);
        expect(
          await File(p.join(modelPath, '${model.engineName}.bin')).length(),
          8943500,
        );
        expect(await leftover.parent.exists(), isFalse);

        final runs = <(String, List<String>)>[];
        final service = LocalUpscaleService(
          mac,
          platform: LocalUpscalePlatform.macOS,
          startProcess: (exe, args) async {
            runs.add((exe, args));
            final input = img.decodePng(
              await File(args[args.indexOf('-i') + 1]).readAsBytes(),
            )!;
            final scale = int.parse(args[args.indexOf('-s') + 1]);
            await File(args[args.indexOf('-o') + 1]).writeAsBytes(
              img.encodePng(
                img.copyResize(
                  input,
                  width: input.width * scale,
                  height: input.height * scale,
                ),
              ),
            );
            return finished();
          },
        );
        final progress = <LocalUpscaleProgress>[];
        final result = await service.upscale(
          _source(alpha: true),
          modelId: 'anime',
          scale: 1.5,
          cancellation: LocalUpscaleCancellation(),
          onProgress: progress.add,
        );
        expect((result.width, result.height), (72, 48));
        expect(img.decodePng(result.bytes)!.getPixel(0, 0).a, 0);
        final (exe, args) = runs.single;
        expect(exe, engine.path);
        String value(String flag) => args[args.indexOf(flag) + 1];
        expect(value('-m'), modelPath);
        expect(value('-n'), 'realesrgan-x4plus-anime');
        expect([value('-s'), value('-t'), value('-j')], ['4', '128', '1:1:1']);
        expect(
          progress.any(
            (item) =>
                item.phase == LocalUpscalePhase.inference && item.fraction == 1,
          ),
          isTrue,
        );
        expect(assets.where((name) => name.startsWith('windows/')), isEmpty);
        expect(service.isRunning, isFalse);
      },
    );

    test(
      'model paths are measured in UTF-8 bytes for the 256-byte engine buffer',
      () async {
        // 80 CJK characters: 80 UTF-16 units on Windows, 240 bytes on macOS.
        Future<Directory> deep() async =>
            Directory(p.join(temporary.path, '模' * 40, '型' * 40));
        final starts = <LocalUpscalePlatform>[];
        for (final platform in [
          LocalUpscalePlatform.windows,
          LocalUpscalePlatform.macOS,
        ]) {
          final models = LocalUpscaleModelManager(
            platform: platform,
            toolsDirectory: () => tools.path,
            rootDirectory: () async =>
                Directory(p.join((await deep()).path, platform.name)),
            loadAsset: (name) =>
                File(p.join('assets', 'local_upscale', name)).readAsBytes(),
          );
          addTearDown(models.dispose);
          final service = LocalUpscaleService(
            models,
            platform: platform,
            startProcess: (_, __) async {
              starts.add(platform);
              throw const ProcessException('engine', []);
            },
          );
          await expectLater(
            service.upscale(
              _source(),
              modelId: 'anime',
              scale: 2,
              cancellation: LocalUpscaleCancellation(),
            ),
            throwsA(
              _error(
                platform == LocalUpscalePlatform.macOS
                    ? LocalUpscaleError.modelMissing
                    : LocalUpscaleError.engineMissing,
              ),
            ),
          );
        }
        expect(starts, [LocalUpscalePlatform.windows]);
      },
    );

    test('a missing or linked engine is reported and never started', () async {
      var starts = 0;
      final service = LocalUpscaleService(
        mac,
        platform: LocalUpscalePlatform.macOS,
        startProcess: (_, __) async {
          starts++;
          throw StateError('unexpected process');
        },
      );
      await engine.delete();
      await expectLater(
        service.upscale(
          _source(),
          modelId: 'anime',
          scale: 2,
          cancellation: LocalUpscaleCancellation(),
        ),
        throwsA(_error(LocalUpscaleError.engineMissing)),
      );
      final elsewhere = File(p.join(temporary.path, 'elsewhere'));
      await elsewhere.writeAsBytes([1]);
      await Link(engine.path).create(elsewhere.path);
      await expectLater(
        mac.resolve('anime'),
        throwsA(_error(LocalUpscaleError.engineMissing)),
      );
      expect(starts, 0);
      expect(service.isRunning, isFalse);
      mac.claimInference('anime');
      mac.releaseInference();
    });

    test(
      'SeedVR2 and RTX are refused before any lock, asset or process',
      () async {
        var starts = 0;
        final advanced = AdvancedUpscaleComponentManager(
          platform: LocalUpscalePlatform.macOS,
          rootDirectory: () async =>
              Directory(p.join(temporary.path, 'advanced')),
          loadAsset: (name) async => throw StateError('asset $name'),
          startProcess: (_, __, ___) async => throw StateError('process'),
        );
        addTearDown(advanced.dispose);
        final service = LocalUpscaleService(
          mac,
          platform: LocalUpscalePlatform.macOS,
          advanced: advanced,
          startProcess: (_, __) async {
            starts++;
            throw StateError('unexpected process');
          },
        );
        for (final model in advancedUpscaleCatalog) {
          await expectLater(
            service.upscale(
              _source(),
              modelId: model.id,
              scale: 2,
              cancellation: LocalUpscaleCancellation(),
            ),
            throwsA(_error(LocalUpscaleError.unsupportedPlatform)),
          );
        }
        expect(starts, 0);
        expect(assets, isEmpty);
        mac.claimInference('anime');
        mac.releaseInference();
        advanced.claimInference();
        advanced.releaseInference();
      },
    );
  });

  test(
    'official optional models install from the verified archive and run natively',
    () async {
      // The release archive is downloaded once for this audit, never in a unit run.
      final models = native();
      await models.initialize();
      await File(
        '.dart_tool/local-upscale-20261005/official-models.zip',
      ).copy(p.join(models.directory.path, 'official-models.zip'));
      for (final id in ['anime-fast', 'general']) {
        await models.download(id);
        final resolved = await models.resolve(id);
        expect(resolved.$3.installed, isTrue);
        final result = await LocalUpscaleService(models).upscale(
          _source(),
          modelId: id,
          scale: 2.75,
          cancellation: LocalUpscaleCancellation(),
        );
        expect((result.width, result.height), (132, 88));
        expect(img.decodePng(result.bytes), isNotNull);
        await models.delete(id);
      }
    },
    skip: nativeAudit('requires Vulkan and the cached official model archive'),
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
          platform: LocalUpscalePlatform.windows,
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
        platform: LocalUpscalePlatform.windows,
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
          platform: LocalUpscalePlatform.windows,
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
      final models = native();
      final service = LocalUpscaleService(models);
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
            p.join(models.directory.path, 'jobs'),
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
    skip: nativeAudit('requires a working Vulkan GPU'),
  );

  test(
    'cancellation kills a real child even when it races with process creation',
    () async {
      final cancellation = LocalUpscaleCancellation();
      Process? child;
      final models = native();
      final service = LocalUpscaleService(
        models,
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
        await Directory(p.join(models.directory.path, 'jobs')).list().toList(),
        isEmpty,
      );
    },
    skip: nativeAudit('requires a working Vulkan GPU'),
  );
}

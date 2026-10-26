import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/core/utils/gallery_path_utils.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/isolate_metadata_service.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/file_image_detail_data.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

final class _NativeIO extends IOOverrides {}

class _Gate {
  final entered = Completer<void>();
  final release = Completer<bool>();
}

class _HeldFile extends Fake implements File {
  _HeldFile(this.real);
  final File real;
  final gates = List.generate(4, (_) => _Gate());
  int calls = 0;
  @override
  String get path => real.path;
  @override
  Future<bool> exists() {
    final gate = gates[calls++];
    gate.entered.complete();
    return gate.release.future;
  }

  @override
  bool existsSync() => real.existsSync();
  @override
  Future<Uint8List> readAsBytes() => real.readAsBytes();
  @override
  Uint8List readAsBytesSync() => real.readAsBytesSync();
  @override
  Future<int> length() => real.length();
  @override
  int lengthSync() => real.lengthSync();
  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) =>
      real.openSync(mode: mode);
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) =>
      real.open(mode: mode);
  @override
  FileStat statSync() => real.statSync();
  @override
  Future<FileStat> stat() => real.stat();
}

Future<void> _drainWorkers() async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < const Duration(seconds: 2)) {
    final stats = IsolateMetadataService.instance.getStatistics();
    if (stats['activeWorkers'] == 0 && stats['queuedTasks'] == 0) {
      await Future<void>.delayed(Duration.zero);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw StateError('Metadata fixture workers did not settle');
}

Future<void> _withGates(
  List<_HeldFile> files,
  Future<void> Function(List<Future<dynamic>> tasks) action,
) async {
  final native = IOOverrides.current ?? _NativeIO();
  final byPath = {
    for (final file in files) galleryFilePathKey(file.path): file,
  };
  final tasks = <Future<dynamic>>[];
  await IOOverrides.runZoned(
    () async {
      try {
        await action(tasks);
      } finally {
        for (final file in files) {
          for (final gate in file.gates) {
            if (!gate.release.isCompleted) gate.release.complete(true);
          }
        }
        await Future.wait(tasks);
        await _drainWorkers();
      }
    },
    createFile: (path) =>
        byPath[galleryFilePathKey(path)] ?? native.createFile(path),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = ImageMetadataService();
  late Directory directory;
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    await AppLogger.initialize(enableFileLogging: false);
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('metadata_task_');
    Hive.init(p.join(directory.path, 'hive'));
    await service.initialize();
    await service.clearCache();
    service.resetStatistics();
    await IsolateMetadataService.instance.initialize();
    IsolateMetadataService.instance.resetStatistics();
  });
  tearDown(() async {
    service.cancelAllParses();
    await _drainWorkers();
    IsolateMetadataService.instance.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<_HeldFile> held(String name) async {
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(
      img.encodePng(
        img.Image(
          width: 16,
          height: 16,
          textData: {
            'Comment': jsonEncode({'prompt': name, 'seed': 42}),
          },
        ),
      ),
    );
    return _HeldFile(file);
  }

  Future<void> entered(_Gate gate) =>
      gate.entered.future.timeout(const Duration(seconds: 1));

  for (final immediate in [false, true]) {
    test(
      'first and follower share the deadline (immediate=$immediate)',
      () async {
        final file = await held('deadline.png');
        await runZoned(
          () => _withGates([file], (tasks) async {
            var firstDone = false;
            final first =
                (immediate
                        ? service.getMetadataImmediate(file.path)
                        : service.getMetadata(
                            file.path,
                            timeout: const Duration(milliseconds: 20),
                          ))
                    .then((value) {
                      firstDone = true;
                      return value;
                    });
            tasks.add(first);
            await entered(file.gates.first);
            final follower = service.getMetadata(file.path);
            tasks.add(follower);
            expect(await follower.timeout(const Duration(seconds: 1)), isNull);
            expect(firstDone, isTrue);
            expect(await first, isNull);
          }),
          zoneSpecification: ZoneSpecification(
            createTimer: (self, parent, zone, duration, callback) =>
                parent.createTimer(
                  zone,
                  duration == const Duration(seconds: 3)
                      ? const Duration(milliseconds: 20)
                      : duration,
                  callback,
                ),
          ),
        );
      },
    );
  }
  test(
    'simultaneous normal and immediate requests deduplicate before waiting',
    () async {
      final file = await held('deduplicate.png');
      await _withGates([file], (tasks) async {
        final first = service.getMetadata(file.path),
            second = service.getMetadataImmediate(file.path);
        tasks.addAll([first, second]);
        await entered(file.gates.first);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(file.calls, 1);
        file.gates.first.release.complete(true);
        expect((await first)!.prompt, 'deduplicate.png');
        expect((await second)!.prompt, 'deduplicate.png');
      });
    },
  );
  test(
    'cancelled old completion does not remove the replacement task',
    () async {
      final file = await held('replacement.png');
      await _withGates([file], (tasks) async {
        final first = service.getMetadata(file.path);
        tasks.add(first);
        await entered(file.gates[0]);
        service.cancelParse(file.path);
        final second = service.getMetadata(file.path);
        tasks.add(second);
        await entered(file.gates[1]);
        file.gates[0].release.complete(false);
        await first;
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(service.getStats()['pendingTasks'], 1);
        expect(service.getStats()['activeTimeouts'], 1);
        file.gates[1].release.complete(true);
        expect((await second)!.prompt, 'replacement.png');
      });
    },
  );
  test('a timed-out late completion does not refill the path cache', () async {
    final file = await held('late.png');
    await _withGates([file], (tasks) async {
      final first = service.getMetadata(
        file.path,
        timeout: const Duration(milliseconds: 20),
      );
      tasks.add(first);
      await entered(file.gates.first);
      final follower = service.getMetadata(file.path);
      tasks.add(follower);
      await follower;
      file.gates.first.release.complete(true);
      await first;
      await _drainWorkers();
      expect(service.getCached(file.path), isNull);
      file.gates[1].release.complete(true);
      expect((await service.getMetadata(file.path))!.prompt, 'late.png');
    });
  });
  test(
    'cancellation token completes a pending caller before IO resumes',
    () async {
      final file = await held('cancel.png');
      final token = ParseCancelToken();
      await _withGates([file], (tasks) async {
        var done = false;
        final request = service.getMetadata(file.path, cancelToken: token).then(
          (value) {
            done = true;
            return value;
          },
        );
        tasks.add(request);
        await entered(file.gates.first);
        token.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(done, isTrue);
        expect(await request, isNull);
      });
    },
  );
  test('deadline includes waiting for an available parse slot', () async {
    final files = [for (var i = 0; i < 4; i++) await held('queue$i.png')];
    await _withGates(files, (tasks) async {
      for (final file in files.take(3)) {
        tasks.add(
          service.getMetadata(file.path, timeout: const Duration(seconds: 1)),
        );
      }
      await Future.wait([
        entered(files[0].gates.first),
        entered(files[1].gates.first),
      ]);
      final waiting = service.getMetadata(
        files.last.path,
        timeout: const Duration(milliseconds: 20),
      );
      tasks.add(waiting);
      expect(await waiting.timeout(const Duration(milliseconds: 200)), isNull);
      expect(files.last.calls, 0);
    });
  });
  test('already cancelled requests perform no file IO', () async {
    final file = await held('precancel.png');
    final token = ParseCancelToken()..cancel();
    await _withGates([file], (tasks) async {
      expect(await service.getMetadata(file.path, cancelToken: token), isNull);
      expect(
        await service.getMetadataImmediate(file.path, cancelToken: token),
        isNull,
      );
      expect(file.calls, 0);
    });
  });
  test('cold file parsing uses the existing isolate workers', () async {
    final file = await held('worker.png');
    final metadata = await service.getMetadata(file.path);
    expect(metadata!.prompt, 'worker.png');
    expect(IsolateMetadataService.instance.getStatistics()['totalTasks'], 1);
  });

  for (final format in ['jpg', 'webp']) {
    for (final immediate in [false, true]) {
      test(
        '$format cold file metadata is readable (immediate=$immediate)',
        () async {
          final file = File(p.join(directory.path, 'source.$format'));
          if (format == 'webp') {
            await file.writeAsBytes(
              await File(
                'test/fixtures/metadata/v4_webp_exif_stealth.webp',
              ).readAsBytes(),
            );
          } else {
            final image = img.Image(width: 16, height: 16);
            image.exif.exifIfd[0x9286] = img.IfdValueUndefined.list([
              ...ascii.encode('ASCII'),
              0,
              0,
              0,
              ...utf8.encode(
                jsonEncode({'prompt': 'JPEG fixture', 'seed': 123}),
              ),
            ]);
            await file.writeAsBytes(img.encodeJpg(image));
          }
          final NaiImageMetadata? result = immediate
              ? await service.getMetadataImmediate(file.path)
              : await service.getMetadata(file.path);
          expect(result, isNotNull);
          expect(
            result!.prompt,
            format == 'jpg' ? 'JPEG fixture' : contains('gawr gura'),
          );
          expect(service.getCached(file.path), isNotNull);
          await service.clearCache();
          final detail = await FileImageDetailData(
            filePath: file.path,
          ).getMetadataAsync();
          expect(detail!.prompt, result.prompt);
          expect(detail.seed, result.seed);
        },
      );
    }
  }
}

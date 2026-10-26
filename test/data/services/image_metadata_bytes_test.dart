import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/utils/isolate_pool.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/cache_manager.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final service = ImageMetadataService();
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    directory = await Directory.systemTemp.createTemp('metadata-bytes-');
    Hive.init(directory.path);
    await service.initialize();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });
  setUp(() async {
    await service.clearCache();
    service.resetStatistics();
    UnifiedMetadataParser.resetStatistics();
  });

  Uint8List png({bool metadata = false}) => Uint8List.fromList(
    img.encodePng(
      img.Image(
        width: 8,
        height: 8,
        numChannels: 4,
        textData: metadata
            ? {
                'Comment': jsonEncode({
                  'prompt': 'offline fixture',
                  'steps': 28,
                }),
              }
            : null,
      ),
    ),
  );

  test(
    'bytes parser runs outside the calling isolate for plain and text PNGs',
    () async {
      for (final metadata in [false, true]) {
        final bytes = png(metadata: metadata);
        final expected = UnifiedMetadataParser.parseFromImageBytes(bytes);
        UnifiedMetadataParser.resetStatistics();
        final actual = await service.getMetadataFromBytes(bytes);
        expect(actual?.toJson(), expected.metadata?.toJson());
        expect(
          UnifiedMetadataParser.statistics.totalAttempts,
          0,
          reason: 'synchronous parser state in the caller must stay untouched',
        );
      }
    },
  );

  test('hash and decode both wait for the compute gate', () async {
    final gate = ComputeGate.forTesting(maxConcurrentTasks: 1);
    final started = Completer<void>();
    final release = Completer<void>();
    final holding = gate.run(() async {
      started.complete();
      await release.future;
    });
    await started.future;
    final isolated = ImageMetadataService.forTesting(computeGate: gate);
    var completed = false;
    final parsing = isolated.getMetadataFromBytes(png(metadata: true)).then((
      value,
    ) {
      completed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(
      isolated.getStats()['pendingTasks'],
      0,
      reason: 'hash has not run, so no caller-isolate hash task can exist',
    );
    release.complete();
    await holding;
    expect((await parsing)?.prompt, 'offline fixture');
  });

  test(
    'content hash cache and in-flight content deduplication are retained',
    () async {
      final bytes = png(metadata: true);
      final results = await Future.wait([
        service.getMetadataFromBytes(bytes),
        service.getMetadataFromBytes(Uint8List.fromList(bytes)),
      ]);
      expect(results.first?.prompt, 'offline fixture');
      expect(service.parseStatistics.successfulParseCount, 1);
      final cached = await service.getMetadataFromBytes(
        Uint8List.fromList(bytes),
      );
      expect(cached?.prompt, 'offline fixture');
      expect(service.parseStatistics.successfulParseCount, 1);
      expect(
        MetadataCacheManager().getFromMemory(sha256.convert(bytes).toString()),
        isNotNull,
      );
    },
  );

  test('pre-existing persistent content cache wins over parsing', () async {
    final bytes = png();
    final hash = sha256.convert(bytes).toString();
    final cache = MetadataCacheManager();
    await cache.box!.put(
      hash,
      jsonEncode(const NaiImageMetadata(prompt: 'cached').toJson()),
    );
    final actual = await service.getMetadataFromBytes(bytes);
    expect(actual?.prompt, 'cached');
    expect(service.parseStatistics.totalParseCount, 0);
  });

  test(
    'small, invalid and absent metadata preserve null/error accounting',
    () async {
      for (final bytes in [Uint8List(3), Uint8List(12), png()]) {
        expect(await service.getMetadataFromBytes(bytes), isNull);
      }
      expect(service.parseStatistics.failedParseCount, 3);
      expect(service.getStats()['pendingTasks'], 0);
    },
  );

  test('compute gate really creates another isolate', () async {
    final caller = Isolate.current.hashCode;
    final worker = await ComputeGate().runIsolate(
      () => Isolate.current.hashCode,
    );
    expect(worker, isNot(caller));
  });
}

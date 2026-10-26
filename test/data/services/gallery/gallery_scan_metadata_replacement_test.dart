import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_stream_scanner.dart';
import 'package:nai_launcher/data/services/gallery/scan_state_manager.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/metadata/isolate_metadata_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory suiteDirectory, directory, images;
  late GalleryDataSource source;
  late GalleryStreamScanner scanner;
  final metadata = ImageMetadataService();
  late File file;
  late int imageId;
  late int oldSize;
  final oldTime = DateTime(2025);
  final newTime = DateTime(2026, 10, 25);

  List<int> png([String? prompt]) => img.encodePng(
    img.Image(
      width: 8,
      height: 8,
      numChannels: 3,
      textData: prompt == null
          ? null
          : {
              'Comment': jsonEncode({
                'prompt': prompt,
                'seed': 1,
                'model': 'nai-diffusion-4-5-full',
              }),
            },
    ),
  );
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    suiteDirectory = await Directory.systemTemp.createTemp(
      'scan_metadata_replacement_',
    );
    Hive.init(p.join(suiteDirectory.path, 'hive'));
    await metadata.initialize();
    await ScanStateManager.instance.initialize();
  });
  tearDownAll(() async {
    IsolateMetadataService.instance.dispose();
    await ScanStateManager.instance.dispose();
    await Hive.close();
    await suiteDirectory.delete(recursive: true);
    await AppLoggerTestIsolation.tearDown();
  });
  setUp(() async {
    directory = await suiteDirectory.createTemp('case_');
    images = await Directory(p.join(directory.path, 'images')).create();
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(directory.path, 'gallery.db'),
      maxConnections: 2,
    );
    source = GalleryDataSource();
    await source.initialize();
    await metadata.clearCache();
    GalleryStreamScanner.resetInstance();
    scanner = GalleryStreamScanner(dataSource: source);
    file = File(p.join(images.path, 'changed.png'));
    await file.writeAsBytes(png('oldneedle'));
    await file.setLastModified(oldTime);
    oldSize = await file.length();
    imageId = await source.upsertImage(
      filePath: file.path,
      fileName: 'changed.png',
      fileSize: oldSize,
      createdAt: oldTime,
      modifiedAt: oldTime,
      metadataStatus: MetadataStatus.success,
      lastScannedAt: oldTime,
    );
    await source.upsertMetadata(
      imageId,
      const NaiImageMetadata(
        prompt: 'oldneedle',
        seed: 1,
        model: 'nai-diffusion-4-5-full',
      ),
    );
  });
  tearDown(() async {
    GalleryStreamScanner.resetInstance();
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await directory.delete(recursive: true);
  });
  Future<void> replace(List<int> bytes) async {
    await file.writeAsBytes(bytes);
    await file.setLastModified(newTime);
  }

  Future<void> scan(bool event) async {
    if (event) {
      await scanner.indexChangedPaths([file.path]);
    } else {
      await scanner.startScanning([images]);
    }
  }

  Future<void> expectAbsent() async {
    expect(
      (await source.getMetadataByImageIds([imageId]))[imageId]!.prompt,
      isEmpty,
    );
    expect(await source.advancedSearch(textQuery: 'oldneedle'), isEmpty);
    final record = (await source.getImageById(imageId))!;
    expect(record.metadataStatus, MetadataStatus.none);
    expect(record.fileSize, await file.length());
    expect(record.lastScannedAt, isNotNull);
  }

  for (final event in [false, true]) {
    test(
      'event=$event retains external index metadata over repeated plain-image scans',
      () async {
        await source.upsertImage(
          filePath: file.path,
          fileName: 'changed.png',
          fileSize: oldSize,
          createdAt: oldTime,
          modifiedAt: oldTime,
          metadataStatus: MetadataStatus.imported,
          lastScannedAt: oldTime,
        );
        await replace(png());
        for (var i = 0; i < 2; i++) {
          await file.setLastModified(newTime.add(Duration(seconds: i)));
          await scan(event);
          expect(
            (await source.getMetadataByImageIds([imageId]))[imageId]!.prompt,
            'oldneedle',
          );
          expect(
            (await source.getImageById(imageId))!.metadataStatus,
            MetadataStatus.imported,
          );
          expect(await source.advancedSearch(textQuery: 'oldneedle'), [
            imageId,
          ]);
        }
      },
    );
    for (final warm in [false, true]) {
      test(
        'event=$event warm=$warm clears obsolete metadata and FTS for a plain replacement',
        () async {
          if (warm) {
            expect(
              (await metadata.getMetadataForScan(file.path))!.prompt,
              'oldneedle',
            );
          }
          await replace(png());
          await scan(event);
          await expectAbsent();
        },
      );
    }
    test(
      'event=$event reparses changed bytes instead of reusing the old path hash',
      () async {
        expect(
          (await metadata.getMetadataForScan(file.path))!.prompt,
          'oldneedle',
        );
        await replace(png('newneedle'));
        await scan(event);
        expect(
          (await source.getMetadataByImageIds([imageId]))[imageId]!.prompt,
          'newneedle',
        );
        expect(await source.advancedSearch(textQuery: 'oldneedle'), isEmpty);
        expect(await source.advancedSearch(textQuery: 'newneedle'), [imageId]);
        expect(
          (await source.getImageById(imageId))!.metadataStatus,
          MetadataStatus.success,
        );
      },
    );
    test(
      'event=$event keeps metadata on corrupt data and leaves a retry marker',
      () async {
        await replace([137, 80, 78, 71, 13, 10, 26, 10]);
        await scan(event);
        expect(
          (await source.getMetadataByImageIds([imageId]))[imageId]!.prompt,
          'oldneedle',
        );
        final failed = (await source.getImageById(imageId))!;
        expect(failed.metadataStatus, MetadataStatus.failed);
        expect(failed.lastScannedAt, isNull);
        await replace(png());
        await scan(event);
        await expectAbsent();
      },
    );
    test(
      'event=$event retains data on a real Windows read lock and retries after unlock',
      () async {
        await replace(png());
        final handle = await file.open(mode: FileMode.append);
        await handle.lock(FileLock.exclusive);
        try {
          await expectLater(
            file.readAsBytes(),
            throwsA(isA<FileSystemException>()),
          );
          if (event) {
            await expectLater(scan(event), throwsA(isA<FileSystemException>()));
          } else {
            await scan(event);
          }
          expect(
            (await source.getMetadataByImageIds([imageId]))[imageId]!.prompt,
            'oldneedle',
          );
          expect((await source.getImageById(imageId))!.fileSize, oldSize);
        } finally {
          await handle.unlock();
          await handle.close();
        }
        await scan(event);
        await expectAbsent();
      },
      skip: !Platform.isWindows,
    );
  }
}

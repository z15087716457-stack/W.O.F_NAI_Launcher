import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_sources.dart';

import '../../helpers/fake_local_gallery_service.dart';
import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;

void main() {
  late Directory temp, root;
  late GalleryDataSource source;
  late LocalGalleryServiceImpl service;
  late GalleryFilterService filter;
  late ProviderContainer container;
  late FloatingResourceWindows windows;
  final paths = <String>[];
  final ids = <int>[];
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppLogger.initialize(isTestEnvironment: true);
  });
  setUp(() async {
    paths.clear();
    ids.clear();
    temp = await Directory.systemTemp.createTemp('floating-gallery-search-');
    root = await Directory(p.join(temp.path, 'gallery')).create();
    Hive.init(p.join(temp.path, 'hive'));
    final settings = await Hive.openBox(StorageKeys.settingsBox);
    await settings.put(StorageKeys.imageSavePath, root.path);
    await ConnectionPoolHolder.initialize(
      dbPath: p.join(temp.path, 'gallery.db'),
      maxConnections: 2,
    );
    source = GalleryDataSource();
    await source.initialize();
    final bytes = img.encodePng(img.Image(width: 4, height: 4));
    for (var i = 0; i < 63; i++) {
      final file = File(p.join(root.path, 'item$i.png'));
      await file.writeAsBytes(bytes);
      final date = DateTime(2026, 1, 1).add(Duration(minutes: i));
      await file.setLastModified(date);
      ids.add(
        await source.upsertImage(
          filePath: file.path,
          fileName: p.basename(file.path),
          fileSize: bytes.length,
          width: 4,
          height: 4,
          createdAt: date,
          modifiedAt: date,
        ),
      );
      paths.add(file.path);
    }
    filter = GalleryFilterService(source);
    service = LocalGalleryServiceImpl(
      dataSource: source,
      filterService: filter,
    );
    await service.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    for (var i = 0; i < 63; i++) {
      await source.setImageTags(ids[i], [i < 61 ? 'aokumo_rin' : 'spring']);
      await source.upsertMetadata(
        ids[i],
        NaiImageMetadata(
          prompt: i == 62 ? 'soft sunset light' : 'spring scenery',
          negativePrompt: '',
          model: 'nai-diffusion-4-5-full',
        ),
      );
    }
    await service.setSort(
      const GallerySort(
        field: GallerySortField.fileName,
        direction: GallerySortDirection.ascending,
      ),
    );
    await service.setSearchQuery('main page selection');
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryWindowSettings()),
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
        floatingResourceWindowsProvider.overrideWith(
          FloatingResourceWindows.new,
        ),
      ],
    );
    windows = container.read(floatingResourceWindowsProvider.notifier);
  });
  tearDown(() async {
    await windows.saved;
    container.dispose();
    await service.dispose();
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });
  test(
    'floating gallery preserves B01 exact-tag/phrase semantics and main dataset across 60-item pages',
    () async {
      final visibleFilter = service.currentFilter;
      final visible = await service.getFilteredImagePaths();
      final id = windows.open(FloatingResourceKind.gallery)!;
      windows.setQuery(id, 'aokumo rin');
      final first = await container.read(
        floatingGalleryPageProvider((id: id, page: 0)).future,
      );
      expect(first.totalCount, 61);
      expect(first.records, hasLength(60));
      expect(first.nextOffset, 60);
      final second = await container.read(
        floatingGalleryPageProvider((id: id, page: 1)).future,
      );
      expect(second.records.single.path, paths.first);
      expect(second.nextOffset, isNull);
      expect(
        first.records.any(
          (record) => record.path == paths[61] || record.path == paths[62],
        ),
        isFalse,
      );
      windows.setQuery(id, 'sunset light');
      final phrase = await container.read(
        floatingGalleryPageProvider((id: id, page: 0)).future,
      );
      expect(phrase.records.single.path, paths[62]);
      expect(identical(service.currentFilter, visibleFilter), isTrue);
      expect(await service.getFilteredImagePaths(), visible);
      expect(filter.sort.field, GallerySortField.fileName);
    },
  );
}

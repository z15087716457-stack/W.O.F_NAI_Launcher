import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_gallery_binding.dart';
import '../../../helpers/fake_local_gallery_service.dart';

class _History extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() {
    GeneratedImage image(String id) => GeneratedImage(
      id: id,
      bytes: Uint8List.fromList(img.encodePng(img.Image(width: 7, height: 5))),
      width: 7,
      height: 5,
    );
    return ImageGenerationState(
      currentImages: [image('current')],
      history: [image('current'), image('old')],
      displayImages: [image('display-only')],
    );
  }
}

void main() {
  late Directory temp, root;
  late GalleryDataSource source;
  late LocalGalleryServiceImpl service;
  late ProviderContainer container;
  late NaiAgentGalleryBinding binding;
  late List<File> files;
  late List<int> ids;
  late bool alive;
  const token = NaiAgentCancellation.new;
  Matcher code(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppLogger.initialize(isTestEnvironment: true);
  });
  setUp(() async {
    alive = true;
    temp = await Directory.systemTemp.createTemp('nai-agent-gallery-');
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
    files = [];
    ids = [];
    for (var i = 0; i < 3; i++) {
      final file = File(p.join(root.path, '${['a', 'b', 'c'][i]}.png'));
      await file.writeAsBytes(
        img.encodePng(img.Image(width: 16 + i, height: 12)),
      );
      final date = DateTime(2026, 8, i + 1, 12);
      await file.setLastModified(date);
      await source.upsertImage(
        filePath: file.path,
        fileName: p.basename(file.path),
        fileSize: await file.length(),
        width: 16 + i,
        height: 12,
        createdAt: date,
        modifiedAt: date,
      );
      files.add(file);
      ids.add((await source.getImageIdByPath(file.path))!);
    }
    service = LocalGalleryServiceImpl(
      dataSource: source,
      filterService: GalleryFilterService(source),
    );
    await service.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await source.setImageTags(ids[0], ['blue_eyes', 'solo']);
    await source.setImageTags(ids[1], ['solo']);
    await service.toggleFavorite(files[0].path);
    final provider = Provider(
      (ref) => NaiAgentGalleryBinding(ref, () => alive),
    );
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
        naiAgentGalleryDataSourceProvider.overrideWithValue(source),
        imageGenerationNotifierProvider.overrideWith(_History.new),
      ],
    );
    binding = container.read(provider);
  });
  tearDown(() async {
    alive = false;
    container.dispose();
    await service.dispose();
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test(
    'library paging and filters preserve visible criteria/order/timeline',
    () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.ascending,
        ),
      );
      await service.setShowFavoritesOnly(true);
      final filter = service.currentFilter;
      final visible = await service.getFilteredImagePaths();
      final timeline = await service.getTimelineEntries();
      final first = (await binding.query({
        'scope': 'library',
        'limit': 1,
      }, token()))['details'];
      expect(first['total'], 3);
      expect(first['images'].single['image_id'], 'gallery:${ids[2]}');
      expect(first['images'].single['width'], 18);
      expect(first['next_offset'], 1);
      final second = (await binding.query({
        'scope': 'library',
        'offset': 1,
        'limit': 2,
      }, token()))['details'];
      expect(second['images'].map((r) => r['image_id']), [
        'gallery:${ids[1]}',
        'gallery:${ids[0]}',
      ]);
      expect(second['next_offset'], isNull);
      final tags = (await binding.query({
        'scope': 'library',
        'tags': ['blue_eyes'],
      }, token()))['details'];
      expect(tags['images'].single['image_id'], 'gallery:${ids[0]}');
      final favorites = (await binding.query({
        'scope': 'library',
        'favorites': true,
      }, token()))['details'];
      expect(favorites['images'].single['favorite'], true);
      final dates = (await binding.query({
        'scope': 'library',
        'date_start': '2026-08-02',
        'date_end': '2026-08-03',
      }, token()))['details'];
      expect(dates['total'], 2);
      expect(service.currentFilter, same(filter));
      expect(await service.getFilteredImagePaths(), visible);
      expect(
        (await service.getTimelineEntries()).map((r) => r.path),
        timeline.map((r) => r.path),
      );
    },
  );

  test(
    'history deduplicates and includes display-only selection without gallery init',
    () async {
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select('display-only');
      final result = (await binding.query({}, token()))['details'];
      expect(result['images'].map((r) => r['image_id']), [
        'current',
        'old',
        'display-only',
      ]);
      final selected = (await binding.query({
        'image_id': 'selected',
      }, token()))['details'];
      expect(selected['images'].single['image_id'], 'display-only');
      expect(selected['images'].single['metadata'], isNull);
      expect(selected['images'].single['width'], 7);
      final missing = (await binding.query({
        'image_id': 'missing',
      }, token()))['details'];
      expect(missing['total'], 0);
      expect(service.currentFilter.hasFilters, false);
    },
  );

  test('gallery ID supplies original bytes and actual vision pixels', () async {
    final original = await files[0].readAsBytes();
    final loaded = await binding.loadImage('gallery:${ids[0]}', token());
    expect(loaded!.bytes, original);
    final tools = NaiAgentStudioTools(
      workspaceDirectory: temp,
      readDraft: () => BridgeDraftSnapshot(fields: {}),
      readSummary: () => {},
      isGenerating: () => false,
      backupDraft: (_) async => '',
      writeDraft: (_) => [],
      readImage: (_) => null,
      loadImageById: binding.loadImage,
      allowsImages: true,
    );
    final read = await tools.execute('image_read', {
      'image_id': loaded.id,
    }, token());
    expect(read['details']['width'], 16);
    expect(read['details']['height'], 12);
    expect(read['content'][1]['type'], 'image');
    expect(read['details']['metadata'], isNull);
    original[0] = 0;
    expect(loaded.bytes[0], 137);
  });

  test(
    'deleted pool and stale off-root rows never resolve or enter queries',
    () async {
      await source.markAsDeleted(files[0].path);
      final outside = File(p.join(temp.path, 'outside.png'));
      await outside.writeAsBytes(await files[1].readAsBytes());
      await source.upsertImage(
        filePath: outside.path,
        fileName: 'outside.png',
        fileSize: await outside.length(),
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      final outsideId = (await source.getImageIdByPath(outside.path))!;
      final page = (await binding.query({
        'scope': 'library',
      }, token()))['details'];
      expect(page['total'], 2);
      expect(await binding.loadImage('gallery:${ids[0]}', token()), isNull);
      expect(await binding.loadImage('gallery:$outsideId', token()), isNull);
      final detail = (await binding.query({
        'scope': 'library',
        'image_id': 'gallery:$outsideId',
      }, token()))['details'];
      expect(detail['total'], 0);
      await files[1].delete();
      expect(await binding.loadImage('gallery:${ids[1]}', token()), isNull);
    },
  );

  test('changed configured roots exclude previously tracked files', () async {
    final newRoot = await Directory(p.join(temp.path, 'new-root')).create();
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.imageSavePath, newRoot.path);
    final page = (await binding.query({
      'scope': 'library',
    }, token()))['details'];
    expect(page['total'], 0);
    expect(await binding.loadImage('gallery:${ids[0]}', token()), isNull);
  });

  test(
    'missing files consume their page slot without repeating the cursor',
    () async {
      await files[2].delete();
      final result = (await binding.query({
        'scope': 'library',
        'limit': 1,
      }, token()))['details'];
      expect(result['images'], isEmpty);
      expect(result['next_offset'], 1);
      final next = (await binding.query({
        'scope': 'library',
        'limit': 1,
        'offset': 1,
      }, token()))['details'];
      expect(next['images'].single['image_id'], 'gallery:${ids[1]}');
    },
  );

  test(
    'history queries never read or initialize the gallery service',
    () async {
      final separate = ProviderContainer(
        overrides: [
          imageGenerationNotifierProvider.overrideWith(_History.new),
          galleryServiceProvider.overrideWith(
            () => throw StateError('Unexpected gallery initialization'),
          ),
        ],
      );
      try {
        final provider = Provider(
          (ref) => NaiAgentGalleryBinding(ref, () => true),
        );
        final result = (await separate
            .read(provider)
            .query({}, token()))['details'];
        expect(result['total'], 3);
        expect(separate.exists(galleryServiceProvider), false);
      } finally {
        separate.dispose();
      }
    },
  );

  test(
    'read-only original loader works when vision input is disabled',
    () async {
      final tools = NaiAgentStudioTools(
        workspaceDirectory: temp,
        readDraft: () => BridgeDraftSnapshot(fields: {}),
        readSummary: () => {},
        isGenerating: () => false,
        backupDraft: (_) async => '',
        writeDraft: (_) => [],
        readImage: (_) => null,
        loadImageById: binding.loadImage,
        allowsImages: false,
      );
      final original = await tools.loadImage({
        'image_id': 'gallery:${ids[0]}',
      }, token());
      expect(original.bytes, await files[0].readAsBytes());
      await expectLater(
        tools.execute('image_read', {'image_id': original.id}, token()),
        code('vision_unavailable'),
      );
    },
  );

  test(
    'validation/cancellation/closed binding refuse before ref access',
    () async {
      for (final params in [
        {'limit': 101},
        {'offset': -1},
        {'scope': 'bad'},
        {'invented_filter': true},
        {
          'tags': ['solo'],
        },
        {'scope': 'library', 'date_start': '2026-02-30'},
        {
          'scope': 'library',
          'date_start': '2026-08-03',
          'date_end': '2026-08-01',
        },
        {'scope': 'library', 'favorites': 1},
        {
          'scope': 'library',
          'tags': [4],
        },
      ]) {
        await expectLater(
          binding.query(params, token()),
          code('invalid_query'),
        );
      }
      await expectLater(
        binding.loadImage('gallery:0', token()),
        code('invalid_image'),
      );
      final cancelled = token()..cancel();
      await expectLater(binding.query({}, cancelled), code('cancelled'));
      alive = false;
      container.dispose();
      await expectLater(binding.query({}, token()), code('closed'));
    },
  );
}

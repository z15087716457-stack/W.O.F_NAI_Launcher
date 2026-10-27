import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/wiring/refs_entry_drop_target.dart';
import 'package:nai_launcher/presentation/wiring/refs_generation_target.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_drag.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_session.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/resource_window_host.dart';
import 'package:nai_launcher/core/services/resource_window_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:nai_launcher/presentation/wiring/resource_window_wiring.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/resources/floating_window_data.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_category.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode.dart';
import 'package:nai_launcher/data/services/gallery/gallery_view_mode_store.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_category_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';
import 'package:nai_launcher/presentation/wiring/refs_library_wiring.dart';
import 'package:nai_launcher/presentation/wiring/refs_mapping.dart';
import 'package:nai_launcher/presentation/wiring/resource_window_backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_local_gallery_service.dart';
import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;
import 'floating_resource_sources_test.dart'
    show Blocks, Vibes, Precise, Params, MainGallery;
import '../../core/resource_window/resource_window_host_test.dart' show code;

class Categories extends GalleryCategoryNotifier {
  @override
  GalleryCategoryState build() => GalleryCategoryState(
    categories: [
      GalleryCategory.create(name: 'Folder', folderPath: '/library'),
    ],
  );
}

class Collections extends CollectionNotifier {
  @override
  CollectionState build() => const CollectionState();
  @override
  Future<void> initialize() async {}
}

class VibeCategories extends VibeLibraryCategoryNotifier {
  @override
  VibeLibraryCategoryState build() => VibeLibraryCategoryState(
    categories: [
      VibeLibraryCategory(id: 'cat', name: 'Warm', createdAt: DateTime(2026)),
    ],
  );
}

class Gallery extends FakeLocalGalleryService {
  Gallery(super.records);
  FilterCriteria? criteria;
  final queries =
      <({FilterCriteria criteria, GallerySort sort, int offset, int limit})>[];
  GallerySort? querySort;
  int? offset, limit;
  @override
  Future<GalleryQueryPage> queryRecords(
    FilterCriteria criteria, {
    int offset = 0,
    int limit = 50,
    GallerySort sort = const GallerySort.modifiedAtDesc(),
  }) {
    queries.add((criteria: criteria, sort: sort, offset: offset, limit: limit));
    this.criteria = criteria;
    querySort = sort;
    this.offset = offset;
    this.limit = limit;
    return super.queryRecords(
      criteria,
      offset: offset,
      limit: limit,
      sort: sort,
    );
  }
}

class FavoriteBlocks extends Blocks {
  FavoriteBlocks(super.library);
  final favorites = <String>[];
  @override
  Future<PromptBlock> toggleFavorite(String id) async {
    favorites.add(id);
    final current = state.requireValue;
    final next = current
        .blockById(id)!
        .copyWith(isFavorite: !current.blockById(id)!.isFavorite);
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: [for (final b in current.blocks) b.id == id ? next : b],
        folders: current.folders,
      ),
    );
    return next;
  }
}

class FavoriteVibes extends Vibes {
  FavoriteVibes(super.entries);
  final favorites = <String>[];
  @override
  Future<VibeLibraryEntry?> toggleFavorite(String id) async {
    favorites.add(id);
    final entry = state.entries.firstWhere((e) => e.id == id);
    final next = entry.copyWith(isFavorite: !entry.isFavorite);
    state = state.copyWith(entries: [next]);
    return next;
  }
}

class FavoritePrecise extends Precise {
  FavoritePrecise(super.entries);
  final favorites = <String>[];
  @override
  Future<void> toggleFavorite(String id) async {
    favorites.add(id);
    state = state.copyWith(
      entries: [
        for (final e in state.entries)
          e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e,
      ],
    );
  }
}

class FavoriteGallery extends MainGallery {
  final favorites = <String>[];
  @override
  Future<bool> toggleFavorite(String id) async {
    favorites.add(id);
    return ref.read(galleryServiceProvider).toggleFavorite(id);
  }
}

class VibeStore extends VibeLibraryStorageService {
  @override
  Future<Uint8List?> getDisplayThumbnail(String id) async =>
      Uint8List.fromList([4]);
}

class PreciseStore extends PreciseRefLibraryStorageService {
  @override
  Future<Uint8List?> getDisplayThumbnail(String id) async =>
      Uint8List.fromList([5]);
}

class DropActions extends RefsEntryDropActions {
  DropActions(super.ref);
  final calls = <String>[];
  @override
  Future<RefsSendResult> drop(
    RefsKind kind,
    RefsEntryDragData data, {
    required bool Function() alive,
  }) async {
    calls.add('${kind.name}:${data.keys.single}:${alive()}');
    return const RefsSendResult(1);
  }
}

class NativeWindows extends ResourceWindowService {
  final opened = <FloatingResourceKind>[];
  @override
  Future<WindowController> openKind(
    FloatingResourceKind kind, {
    bool newWindow = false,
  }) async {
    opened.add(kind);
    return WindowController.fromWindowId('fake');
  }
}

class TempPaths extends PathProviderPlatform {
  TempPaths(this.path);
  final String path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

class ShareSettings extends ShareImageSettingsNotifier {
  void strip(bool value) =>
      state = state.copyWith(stripMetadataForCopyAndDrag: value);
  @override
  ShareImageSettings build() => const ShareImageSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late ResourceLibraryBackend backend;
  late Gallery gallery;
  late MemoryWindowSettings storage;
  late Directory temp;
  late File cover;
  late PathProviderPlatform originalPaths;
  late NativeWindows native;
  late GoRouter router;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('resource-backend-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TempPaths(temp.path);
    cover = await File('${temp.path}/cover.png').writeAsBytes([1, 2, 3]);
    storage = MemoryWindowSettings();
    native = NativeWindows();
    router = GoRouter(
      initialLocation: AppRoutes.generation,
      routes: [
        for (final path in [
          AppRoutes.generation,
          AppRoutes.vibeLibrary,
          AppRoutes.preciseRefLibrary,
        ])
          GoRoute(path: path, builder: (_, _) => const SizedBox()),
      ],
    );
    gallery = Gallery(
      List.generate(
        125,
        (i) => LocalImageRecord(
          path: '/library/$i.png',
          size: 1,
          modifiedAt: DateTime(2026),
        ),
      ),
    );
    container = ProviderContainer(
      overrides: [
        appRouterProvider.overrideWithValue(router),
        localStorageServiceProvider.overrideWithValue(storage),
        nativeResourceWindowsProvider.overrideWithValue(true),
        resourceWindowServiceProvider.overrideWithValue(native),
        refsEntryDropActionsProvider.overrideWith(DropActions.new),
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(gallery),
        ),
        galleryCategoryNotifierProvider.overrideWith(Categories.new),
        collectionNotifierProvider.overrideWith(Collections.new),
        localGalleryNotifierProvider.overrideWith(FavoriteGallery.new),
        generationParamsNotifierProvider.overrideWith(Params.new),
        shareImageSettingsProvider.overrideWith(ShareSettings.new),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => FavoriteBlocks(
            PromptBlockLibraryState(
              blocks: [
                PromptBlock.create(
                  id: 'a',
                  title: 'Alpha',
                  content: 'blue_eyes',
                  negativeContent: 'lowres',
                  folderId: 'child',
                  isFavorite: true,
                  thumbnail: cover.path,
                ),
                PromptBlock.create(id: 'b', title: 'Beta', content: 'red hair'),
              ],
              folders: [
                PromptBlockFolder.create(id: 'parent', name: 'Parent'),
                PromptBlockFolder.create(
                  id: 'child',
                  parentId: 'parent',
                  name: 'Child',
                ),
              ],
            ),
          ),
        ),
        vibeLibraryNotifierProvider.overrideWith(
          () => FavoriteVibes([
            VibeLibraryEntry.fromVibeReference(
              name: 'Warm',
              vibeData: const VibeReference(
                displayName: 'warm',
                vibeEncoding: 'data',
              ),
            ).copyWith(id: 'v', categoryId: 'cat', isFavorite: true),
          ]),
        ),
        preciseRefLibraryNotifierProvider.overrideWith(
          () => FavoritePrecise([
            PreciseRefLibraryEntry(
              id: 'p',
              name: 'Hero',
              imagePath: '/fake.png',
              createdAt: DateTime(2026),
            ),
          ]),
        ),
        vibeLibraryCategoryNotifierProvider.overrideWith(VibeCategories.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(VibeStore()),
        preciseRefLibraryStorageServiceProvider.overrideWithValue(
          PreciseStore(),
        ),
        refsVibeStatusesProvider.overrideWith(
          (ref) async => <String, RefsVibeStatus>{},
        ),
      ],
    );
    backend = container.read(resourceWindowBackendProvider);
  });
  tearDown(() async {
    await backend.dispose();
    PathProviderPlatform.instance = originalPaths;
    container.dispose();
    router.dispose();
    await temp.delete(recursive: true);
  });
  ResourceQuery request(
    String kind, {
    String group = 'all',
    List<String> chips = const [],
    String? sort,
    String search = '',
    int offset = 0,
  }) => ResourceQuery({
    'windowId': 'w',
    'requestId': 1,
    'kind': kind,
    'groupId': group,
    'query': search,
    'chips': chips,
    'sortId': sort,
    'offset': offset,
    'limit': 60,
  });

  testWidgets(
    'primary bridge forwards refs to protected drop actions, opens gallery viewer and requests editors',
    (tester) async {
      const channel = MethodChannel('window_manager');
      final nativeCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isMinimized') return false;
            nativeCalls.add(call.method);
            return null;
          });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (_, child) => ResourceWindowBridge(child: child!),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await backend.action(FloatingResourceKind.vibe, 'v', 'add');
      await backend.action(FloatingResourceKind.precise, 'p', 'add');
      expect(
        (container.read(refsEntryDropActionsProvider) as DropActions).calls,
        ['vibe:v:true', 'precise:p:true'],
      );
      await backend.open(FloatingResourceKind.gallery, '/library/0.png');
      expect(
        container.read(imageViewerSessionProvider)!.backend.currentKey,
        '/library/0.png',
      );
      await backend.open(FloatingResourceKind.vibe, 'v');
      expect(container.read(resourceRefsEditRequestProvider), (
        kind: FloatingResourceKind.vibe,
        id: 'v',
      ));
      expect(nativeCalls, [
        'show',
        'focus',
        'show',
        'focus',
        'show',
        'focus',
        'show',
        'focus',
      ]);
      await tester.pumpWidget(const SizedBox());
      expect(container.read(resourceMainActionsProvider).perform, isNull);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'Windows opener attaches the primary backend and forwards every kind to native windows',
    () async {
      final opener = container.read(resourceWindowOpenerProvider);
      for (final kind in FloatingResourceKind.values) {
        await opener.open(kind);
      }
      expect(native.opened, FloatingResourceKind.values);
      expect(native.host.backend, same(backend));
      final args = await native.argumentsFor!(FloatingResourceKind.blocks);
      expect(args.kind, FloatingResourceKind.blocks);
      expect(args.style, 'geist');
    },
  );

  test(
    'gallery forwards queryRecords page/filter/sort and all tab counts',
    () async {
      final page = await backend.query(
        request(
          'gallery',
          group: 'today',
          chips: ['favorite', 'nai'],
          sort: 'fileName:ascending',
          offset: 60,
        ),
      );
      expect(page['items'], isEmpty); // no fake favorite records
      final forwarded = gallery.queries.first;
      expect(forwarded.offset, 60);
      expect(forwarded.limit, 60);
      expect(forwarded.criteria.showFavoritesOnly, true);
      expect(forwarded.criteria.naiOnly, true);
      expect(forwarded.criteria.dateStart, isNotNull);
      expect(forwarded.criteria.dateEndExclusive, true);
      expect(forwarded.sort.field, GallerySortField.fileName);
      expect(forwarded.sort.direction, GallerySortDirection.ascending);
      expect(page['counts'], {
        'gallery': 125,
        'blocks': 2,
        'vibe': 1,
        'precise': 1,
      });
      expect(page['layouts'], ['grid', 'masonry', 'justified']);
      expect(page['layout'], 'justified');
      expect((page['sections'] as List).length, 3);
      final sorts = page['sorts'] as List;
      expect(sorts, hasLength(10));
      await expectLater(
        backend.query(request('gallery', group: 'trash')),
        throwsA(code('invalid_arguments')),
      );
    },
  );
  test(
    'blocks reuse tree and normalized search; positive/negative/favorites and sort',
    () async {
      final page = await backend.query(
        request(
          'blocks',
          group: 'folder:parent',
          search: 'blue eyes',
          chips: ['negative', 'positive', 'favorite'],
          sort: 'title',
        ),
      );
      expect((page['items'] as List).single, containsPair('id', 'a'));
      expect(page['total'], 1);
      final sections = page['sections'] as List;
      final folders = (sections[1] as Map)['groups'] as List;
      expect(folders.last, containsPair('parentId', 'folder:parent'));
      await expectLater(
        backend.detail(FloatingResourceKind.blocks, 'deleted'),
        throwsA(code('not_found')),
      );
    },
  );
  test(
    'refs reuse filters, categories and mapped summaries; thumbnails stay in host',
    () async {
      final vibe = await backend.query(
        request(
          'vibe',
          group: 'category:cat',
          chips: ['favorite', 'usable'],
          search: 'warm',
        ),
      );
      expect(vibe['total'], 1);
      final precise = await backend.query(request('precise', search: 'hero'));
      expect(precise['total'], 1);
      expect(
        (await backend.query(
          request('precise', group: 'type:character'),
        ))['total'],
        0,
      );
      expect(
        (await backend.query(request('precise', group: 'type:both')))['total'],
        1,
      );
      expect(await backend.thumbnail(FloatingResourceKind.blocks, 'a', 0), [
        1,
        2,
        3,
      ]);
      expect(await backend.thumbnail(FloatingResourceKind.vibe, 'v', 0), [4]);
      expect(await backend.thumbnail(FloatingResourceKind.precise, 'p', 0), [
        5,
      ]);
      await expectLater(
        backend.thumbnail(FloatingResourceKind.gallery, 'missing', 0),
        throwsA(code('not_found')),
      );
    },
  );
  test(
    'all detail actions/open forward IDs to primary protected action bridge',
    () async {
      final calls = <String>[];
      container.read(resourceMainActionsProvider).perform =
          (kind, id, action) async => calls.add('${kind.name}:$id:$action');
      for (final pair in [
        (FloatingResourceKind.gallery, '/library/0.png'),
        (FloatingResourceKind.blocks, 'a'),
        (FloatingResourceKind.vibe, 'v'),
        (FloatingResourceKind.precise, 'p'),
      ]) {
        final detail = await backend.detail(pair.$1, pair.$2);
        for (final a in detail['actions'] as List) {
          await backend.action(pair.$1, pair.$2, (a as Map)['id'] as String);
        }
        await backend.open(pair.$1, pair.$2);
      }
      expect(
        calls,
        containsAll([
          'gallery:/library/0.png:reuse',
          'gallery:/library/0.png:open',
          'blocks:a:positive',
          'blocks:a:negative',
          'blocks:a:edit',
          'vibe:v:add',
          'precise:p:add',
        ]),
      );
      await expectLater(
        backend.action(FloatingResourceKind.blocks, 'a', 'generate'),
        throwsA(code('invalid_arguments')),
      );
    },
  );
  test(
    'gallery export obeys current sanitization policy and deduplicates preparation',
    () async {
      final bytes = UnifiedMetadataParser.embedTextChunkOnly(
        Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 8))),
        'Comment',
        '{"prompt":"private-text"}',
      );
      final file = await File('${temp.path}/private.png').writeAsBytes(bytes);
      final source = Gallery([
        LocalImageRecord(
          path: file.path,
          size: bytes.length,
          modifiedAt: DateTime(2026),
        ),
      ]);
      final isolated = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => FakeGalleryServiceNotifier(source),
          ),
          shareImageSettingsProvider.overrideWith(ShareSettings.new),
        ],
      );
      final exports = isolated.read(resourceWindowBackendProvider);
      expect(await exports.exportGallery(file.path), file.uri);
      (isolated.read(shareImageSettingsProvider.notifier) as ShareSettings)
          .strip(true);
      final uris = await Future.wait([
        exports.exportGallery(file.path),
        exports.exportGallery(file.path),
      ]);
      expect(uris[0], uris[1]);
      expect(uris[0], isNot(file.uri));
      final sanitized = await File.fromUri(uris[0]).readAsBytes();
      expect(String.fromCharCodes(sanitized), isNot(contains('private-text')));
      expect(await file.readAsBytes(), bytes);
      await exports.dispose();
      expect(await File.fromUri(uris[0]).exists(), false);
      isolated.dispose();
    },
  );

  test(
    'favorite dispatch calls existing notifier methods for all four libraries',
    () async {
      await backend.favorite(FloatingResourceKind.gallery, '/library/0.png');
      await backend.favorite(FloatingResourceKind.blocks, 'a');
      await backend.favorite(FloatingResourceKind.vibe, 'v');
      await backend.favorite(FloatingResourceKind.precise, 'p');
      expect(
        (container.read(localGalleryNotifierProvider.notifier)
                as FavoriteGallery)
            .favorites,
        ['/library/0.png'],
      );
      expect(
        (container.read(promptBlockLibraryNotifierProvider.notifier)
                as FavoriteBlocks)
            .favorites,
        ['a'],
      );
      expect(
        (container.read(vibeLibraryNotifierProvider.notifier) as FavoriteVibes)
            .favorites,
        ['v'],
      );
      expect(
        (container.read(preciseRefLibraryNotifierProvider.notifier)
                as FavoritePrecise)
            .favorites,
        ['p'],
      );
      expect(
        (await backend.item(FloatingResourceKind.blocks, 'a'))['favorite'],
        false,
      );
      expect(
        (await backend.item(FloatingResourceKind.vibe, 'v'))['favorite'],
        false,
      );
      expect(
        (await backend.item(FloatingResourceKind.precise, 'p'))['favorite'],
        true,
      );
    },
  );

  test(
    'view modes share exact main application keys and independent cell-size keys',
    () async {
      await backend.preferences(FloatingResourceKind.gallery, {
        'layout': 'masonry',
        'cellSize': 150,
      });
      expect(
        await const GalleryViewModeStore().load(),
        GalleryViewMode.masonry,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          StorageKeys.localGalleryViewModeV2,
        ),
        'masonry',
      );
      await const GalleryViewModeStore().save(GalleryViewMode.grid);
      expect((await backend.query(request('gallery')))['layout'], 'grid');
      await backend.preferences(FloatingResourceKind.blocks, {
        'layout': 'list',
        'cellSize': 180,
      });
      expect(
        (await container.read(blocksPreferencesProvider.future)).view,
        BlocksView.list,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('blocks_view_v2'),
        'list',
      );
      expect(
        (await SharedPreferences.getInstance()).getDouble(
          'resource_window_gallery_cell_size',
        ),
        150,
      );
      expect(
        (await SharedPreferences.getInstance()).getDouble(
          'resource_window_blocks_cell_size',
        ),
        180,
      );
    },
  );
  test(
    'layout is per kind in screen logical coords and pin persists across containers',
    () async {
      await backend.query(request('blocks'));
      await backend.layout('w', {
        'rect': {
          'left': -1100.0,
          'top': 20.0,
          'width': 1040.0,
          'height': 680.0,
        },
        'alwaysOnTop': true,
      });
      expect(
        storage.values['resource_window_blocks_layout'],
        containsPair('alwaysOnTop', true),
      );
      await container
          .read(layoutStateNotifierProvider.notifier)
          .setResourceWindowsPinned(true);
      expect(
        container.read(layoutStateNotifierProvider).resourceWindowsPinned,
        true,
      );
      final second = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      expect(
        second.read(layoutStateNotifierProvider).resourceWindowsPinned,
        true,
      );
      second.dispose();
      await expectLater(
        backend.layout('w', {
          'rect': {'left': 0, 'top': 0, 'width': 100, 'height': 100},
          'alwaysOnTop': false,
        }),
        throwsA(code('invalid_arguments')),
      );
    },
  );
}

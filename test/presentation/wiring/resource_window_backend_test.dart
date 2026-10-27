import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:nai_launcher/data/services/gallery/gallery_sort_store.dart';
import 'package:nai_launcher/presentation/wiring/refs_preferences.dart';
import 'package:nai_launcher/presentation/providers/gallery_scan_progress_provider.dart';
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
import 'package:nai_launcher/presentation/wiring/image_viewer_gallery.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_translation.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/services/image_clipboard_service.dart';
import 'package:nai_launcher/core/services/resource_window_host.dart';
import 'package:nai_launcher/core/services/resource_window_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:nai_launcher/presentation/wiring/resource_window_wiring.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
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

class MutableParams extends Params {
  void model(String value) => state = state.copyWith(model: value);
  @override
  void addVibeReference(VibeReference vibe) => state = state.copyWith(
    vibeReferencesV4: [...state.vibeReferencesV4, vibe],
  );
}

class LoadingShortcuts extends ShortcutConfigNotifier {
  final loaded = Completer<ShortcutConfig>();
  @override
  Future<ShortcutConfig> build() => loaded.future;
  void publish(ShortcutConfig config) => state = AsyncData(config);
}

class ScanProgress extends GalleryScanProgressNotifier {
  void scanning(bool value) => state = state.copyWith(isScanning: value);
}

class Categories extends GalleryCategoryNotifier {
  void publish(List<GalleryCategory> categories) =>
      state = state.copyWith(categories: categories);
  @override
  GalleryCategoryState build() => GalleryCategoryState(
    categories: [
      GalleryCategory.create(name: 'Folder', folderPath: '/library'),
    ],
  );
}

class Collections extends CollectionNotifier {
  void publish(List<ImageCollection> collections) =>
      state = state.copyWith(collections: collections);
  @override
  CollectionState build() => const CollectionState();
  @override
  Future<void> initialize() async {}
  @override
  Future<ImageCollection?> createCollection(
    String name, {
    String? description,
    String? parentId,
    bool isFolder = false,
  }) async => ImageCollection(id: 'new', name: name, createdAt: DateTime(2026));
}

class ViewerGallery extends ImageViewerGallery {
  ViewerGallery(super.ref);
  final calls = <String>[];
  @override
  Future<List<ViewerCollection>> collections(String path) async => [
    const ViewerCollection(id: 'c', name: 'Collection', member: true),
  ];
  @override
  Future<void> setFavorite(String path, bool value) async =>
      calls.add('favorite:$path:$value');
  @override
  Future<void> setCollection(String path, String id, bool member) async =>
      calls.add('collection:$path:$id:$member');
  @override
  Future<bool> delete(String path) async {
    calls.add('delete:$path');
    return true;
  }

  @override
  Future<void> restore(String path) async => calls.add('restore:$path');
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
  void publish(LocalGalleryState next) => state = next;
  @override
  Future<void> setSort(
    GallerySortField field,
    GallerySortDirection direction,
  ) async {
    state = state.copyWith(sortField: field, sortDirection: direction);
  }

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
  final changes = <FloatingResourceKind>[];
  final views = <String>[];
  @override
  Future<void> changed(FloatingResourceKind kind) async {
    changes.add(kind);
  }

  @override
  Future<void> viewChanged(FloatingResourceKind kind, String layout) async {
    views.add('${kind.name}:$layout');
  }

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
  late LoadingShortcuts shortcuts;
  final clipboardWrites = <Uint8List>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('resource-backend-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TempPaths(temp.path);
    cover = await File('${temp.path}/cover.png').writeAsBytes([1, 2, 3]);
    storage = MemoryWindowSettings();
    native = NativeWindows();
    shortcuts = LoadingShortcuts();
    clipboardWrites.clear();
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
        imageViewerGalleryProvider.overrideWith(ViewerGallery.new),
        detailPromptTranslatorProvider.overrideWithValue(
          (document, session) async => document.copyWith(text: 'translated'),
        ),
        shortcutConfigNotifierProvider.overrideWith(() => shortcuts),
        imageClipboardServiceProvider.overrideWithValue(
          ImageClipboardService(
            stripMetadata: () => false,
            write: (bytes) async => clipboardWrites.add(bytes),
          ),
        ),
        appRouterProvider.overrideWithValue(router),
        galleryScanProgressProvider.overrideWith((ref) => ScanProgress()),
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
        generationParamsNotifierProvider.overrideWith(MutableParams.new),
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
    bool? descending,
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
    'descending': descending,
    'offset': offset,
    'limit': 60,
  });

  test(
    'child viewer reads canonical records/metadata and routes library mutations without a visual bridge',
    () async {
      gallery = Gallery([
        LocalImageRecord(
          path: cover.path,
          size: 3,
          modifiedAt: DateTime(2026),
          metadata: const NaiImageMetadata(
            prompt: 'source',
            width: 100,
            height: 150,
          ),
        ),
      ]);
      final records = resourceMap(
        await backend.galleryViewer({
          'operation': 'records',
          'ids': [cover.path, '/missing.png'],
        }),
      );
      expect((records['records'] as List).length, 1);
      expect(
        resourceMap((records['records'] as List).single)['path'],
        cover.path,
      );
      expect(container.read(resourceMainActionsProvider).perform, isNull);
      final metadata =
          jsonDecode(
                await backend.galleryViewer({
                      'operation': 'metadata',
                      'id': cover.path,
                    })
                    as String,
              )
              as Map;
      expect(metadata['prompt'], 'source');
      expect(
        await backend.galleryViewer({
          'operation': 'translate',
          'id': cover.path,
          'part': 'prompt',
          'session': 'test',
        }),
        'translated',
      );
      expect(
        (await backend.galleryViewer({
                  'operation': 'collections',
                  'id': cover.path,
                })
                as List)
            .single,
        containsPair('member', true),
      );
      await backend.galleryViewer({
        'operation': 'favorite',
        'id': cover.path,
        'value': true,
      });
      await backend.galleryViewer({
        'operation': 'setCollection',
        'id': cover.path,
        'collectionId': 'c',
        'member': false,
      });
      await backend.galleryViewer({
        'operation': 'createCollection',
        'id': cover.path,
        'name': 'New',
      });
      await expectLater(
        backend.galleryViewer({'operation': 'restore', 'id': cover.path}),
        throwsA(code('not_found')),
      );
      expect(
        await backend.galleryViewer({'operation': 'delete', 'id': cover.path}),
        true,
      );
      await backend.galleryViewer({'operation': 'restore', 'id': cover.path});
      expect(
        (container.read(imageViewerGalleryProvider) as ViewerGallery).calls,
        [
          'favorite:${cover.path}:true',
          'collection:${cover.path}:c:false',
          'collection:${cover.path}:new:true',
          'delete:${cover.path}',
          'restore:${cover.path}',
        ],
      );
      await expectLater(
        backend.galleryViewer({'operation': 'metadata', 'id': '/missing.png'}),
        throwsA(code('not_found')),
      );
      await expectLater(
        backend.galleryViewer({
          'operation': 'action',
          'id': cover.path,
          'action': 'invalid',
        }),
        throwsA(code('invalid_arguments')),
      );
      await expectLater(
        backend.galleryViewer({
          'operation': 'translate',
          'id': cover.path,
          'part': 'invalid',
        }),
        throwsA(code('invalid_arguments')),
      );
    },
  );

  test(
    'child viewer explicit workflow/copy actions use the protected main bridge with canonical ID',
    () async {
      final calls = <String>[];
      container.read(resourceMainActionsProvider).perform =
          (kind, id, action) async => calls.add('${kind.name}:$id:$action');
      for (final action in ViewerAction.values.where(
        (action) => action != ViewerAction.save,
      )) {
        await backend.galleryViewer({
          'operation': 'action',
          'id': '/library/0.png',
          'action': action.name,
        });
      }
      await backend.galleryViewer({
        'operation': 'saveVibe',
        'id': '/library/0.png',
        'index': 0,
      });
      expect(calls, [
        for (final action in ViewerAction.values.where(
          (action) => action != ViewerAction.save,
        ))
          'gallery:/library/0.png:viewer:${action.name}',
        'gallery:/library/0.png:saveVibe:0',
      ]);
      await expectLater(
        backend.galleryViewer({
          'operation': 'action',
          'id': '/library/0.png',
          'action': 'save',
        }),
        throwsA(code('unsupported')),
      );
    },
  );

  testWidgets(
    'global shortcut startup and settings rebuild keep resource actions registered',
    (tester) async {
      final pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      );
      await tester.runAsync(() => cover.writeAsBytes(pixels));
      gallery = Gallery([
        LocalImageRecord(
          path: cover.path,
          size: pixels.length,
          modifiedAt: DateTime(2026),
        ),
      ]);
      const channel = MethodChannel('window_manager');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'isMinimized' ? false : null,
          );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: GlobalShortcuts(
            shortcuts: {ShortcutIds.minimizeToTray: () {}},
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              builder: (_, child) => ResourceWindowBridge(child: child!),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(resourceMainActionsProvider).perform, isNotNull);
      shortcuts.publish(ShortcutConfig.createDefault());
      await tester.pumpAndSettle();
      expect(container.read(resourceMainActionsProvider).perform, isNotNull);

      for (final enabled in [true, false, true]) {
        shortcuts.publish(
          ShortcutConfig.createDefault().copyWith(enableShortcuts: enabled),
        );
        await tester.pumpAndSettle();
        expect(
          container.read(resourceMainActionsProvider).perform,
          isNotNull,
          reason: 'shortcuts enabled: $enabled',
        );
        await backend.action(FloatingResourceKind.vibe, 'v', 'add');
        await tester.runAsync(
          () =>
              backend.action(FloatingResourceKind.gallery, cover.path, 'copy'),
        );
        final opening = backend.open(FloatingResourceKind.gallery, cover.path);
        await tester.pumpAndSettle();
        await opening;
        expect(
          container.read(imageViewerSessionProvider)!.backend.currentKey,
          cover.path,
        );
      }
      expect(
        (container.read(refsEntryDropActionsProvider) as DropActions).calls,
        ['vibe:v:true', 'vibe:v:true', 'vibe:v:true'],
      );
      expect(clipboardWrites, [pixels, pixels, pixels]);
      await tester.pumpWidget(const SizedBox());
      expect(container.read(resourceMainActionsProvider).perform, isNull);
    },
  );

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
      final opening = backend.open(
        FloatingResourceKind.gallery,
        '/library/0.png',
      );
      await tester.pumpAndSettle();
      await opening;
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

  testWidgets(
    'foreground show/focus failure cannot abort gallery open or refs button',
    (tester) async {
      const channel = MethodChannel('window_manager');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            throw PlatformException(code: 'window_operation_failed');
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
      expect(
        router.routerDelegate.navigatorKey.currentState?.overlay,
        isNotNull,
      );
      final opening = backend.open(
        FloatingResourceKind.gallery,
        '/library/0.png',
      );
      await tester.pumpAndSettle();
      await opening;
      final session = container.read(imageViewerSessionProvider)!;
      expect(session.backend.currentKey, '/library/0.png');
      await backend.action(FloatingResourceKind.vibe, 'v', 'add');
      expect(
        (container.read(refsEntryDropActionsProvider) as DropActions).calls,
        ['vibe:v:true'],
      );
      await tester.pumpWidget(const SizedBox());
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  testWidgets(
    'pending branch cleanup completes before external viewer session is installed',
    (tester) async {
      const channel = MethodChannel('window_manager');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'isMinimized' ? false : null,
          );
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Equivalent to MainShell's cleanup during a pending branch rebuild.
        scheduleMicrotask(
          () =>
              container.read(imageViewerSessionProvider.notifier).state = null,
        );
      });
      final opening = backend.open(
        FloatingResourceKind.gallery,
        '/library/0.png',
      );
      await tester.pumpAndSettle();
      await opening;
      expect(
        container.read(imageViewerSessionProvider)!.backend.currentKey,
        '/library/0.png',
      );
      await tester.pumpWidget(const SizedBox());
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  testWidgets(
    'unsupported Vibe and negative actions fail explicitly before protected drop/draft mutation',
    (tester) async {
      const channel = MethodChannel('window_manager');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'isMinimized' ? false : null,
          );
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
      (container.read(generationParamsNotifierProvider.notifier)
              as MutableParams)
          .model(ImageModels.animeDiffusionV5FullMedium);
      await expectLater(
        backend.action(FloatingResourceKind.vibe, 'v', 'add'),
        throwsA(code('unsupported')),
      );
      await expectLater(
        backend.action(FloatingResourceKind.gallery, '/library/0.png', 'vibe'),
        throwsA(code('unsupported')),
      );
      await expectLater(
        backend.action(FloatingResourceKind.blocks, 'a', 'negative'),
        throwsA(code('unsupported')),
      );
      expect(
        (container.read(refsEntryDropActionsProvider) as DropActions).calls,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  test(
    'records and layout changes do not announce content; mutations and scan completion do',
    () async {
      await container
          .read(resourceWindowOpenerProvider)
          .open(FloatingResourceKind.gallery);
      await container.read(blocksPreferencesProvider.future);
      native.changes.clear();
      native.views.clear();
      final notifier =
          container.read(localGalleryNotifierProvider.notifier)
              as FavoriteGallery;
      notifier.publish(
        container
            .read(localGalleryNotifierProvider)
            .copyWith(recordsRevision: 1),
      );
      notifier.publish(
        container
            .read(localGalleryNotifierProvider)
            .copyWith(viewMode: GalleryViewMode.grid),
      );
      expect(native.changes, isEmpty);
      expect(native.views, ['gallery:grid']);
      notifier.publish(
        container
            .read(localGalleryNotifierProvider)
            .copyWith(contentRevision: 1),
      );
      expect(native.changes, [FloatingResourceKind.gallery]);
      native.changes.clear();
      container.read(refsSortChangedProvider(RefsKind.vibe).notifier).state = (
        sort: RefsSort.name,
        descending: false,
      );
      expect(native.changes, [FloatingResourceKind.vibe]);
      native.changes.clear();
      final scan =
          container.read(galleryScanProgressProvider.notifier) as ScanProgress;
      scan.scanning(true);
      expect(native.changes, isEmpty);
      scan.scanning(false);
      expect(native.changes, [FloatingResourceKind.gallery]);
    },
  );

  test(
    'shared sort stores round-trip direction independently for every kind',
    () async {
      var result = await backend.query(request('gallery', sort: 'fileName'));
      expect(result['sortId'], 'fileName');
      expect(result['descending'], false);
      expect(
        (await const GallerySortStore().load())!.direction,
        GallerySortDirection.ascending,
      );
      result = await backend.query(
        request('gallery', sort: 'fileName', descending: true),
      );
      expect(result['descending'], true);
      result = await backend.query(request('gallery', sort: 'fileSize'));
      expect(result['descending'], true);
      await backend.query(request('blocks', sort: 'title', descending: false));
      expect(
        (await container.read(blocksPreferencesProvider.future)).descending,
        false,
      );
      for (final kind in ['vibe', 'precise']) {
        result = await backend.query(
          request(kind, sort: 'name', descending: false),
        );
        final prefs = RefsPreferenceStore(
          storage,
          kind == 'vibe' ? RefsKind.vibe : RefsKind.precise,
        ).read();
        expect(prefs.filter.sort, RefsSort.name);
        expect(prefs.filter.descending, false);
        expect(result['descending'], false);
        expect(
          container.read(
            refsSortChangedProvider(
              kind == 'vibe' ? RefsKind.vibe : RefsKind.precise,
            ),
          ),
          (sort: RefsSort.name, descending: false),
        );
      }
      await expectLater(
        backend.query(request('gallery', sort: 'modifiedAt:descending')),
        throwsA(code('invalid_arguments')),
      );
    },
  );

  test(
    'tree DTO uses main mapping, recent and uncategorized; cards carry crop and metrics',
    () async {
      await container.read(blocksPreferencesProvider.future);
      await container
          .read(blocksPreferencesProvider.notifier)
          .change(
            (p) => p.copyWith(recentIds: ['b', 'a'], expanded: {'parent'}),
          );
      var result = await backend.query(request('blocks', group: 'recent'));
      expect((result['items'] as List).map((b) => (b as Map)['id']), [
        'b',
        'a',
      ]);
      result = await backend.query(request('blocks', group: 'uncategorized'));
      expect((result['items'] as List).single, containsPair('id', 'b'));
      final sections = result['sections'] as List;
      expect(sections.map((s) => (s as Map)['id']), [
        'library',
        'collections',
        'folders',
      ]);
      final folders = (sections.last as Map)['groups'] as List;
      expect((folders[1] as Map)['expanded'], true);
      expect((folders.first as Map)['icon'], 'uncategorized');
      final custom = (result['sorts'] as List).first as Map;
      expect(custom['directional'], false);
      final block = await backend.item(FloatingResourceKind.blocks, 'a');
      expect(block['hasThumb'], true);
      expect(block['crop'], {'offsetX': 0.0, 'offsetY': 0.0, 'scale': 1.0});
      expect(block['itemCount'], 1);
      expect(block['useCount'], 0);
      expect(block['hasParams'], false);
      expect(
        (await backend.item(FloatingResourceKind.blocks, 'b'))['hasThumb'],
        false,
      );
      result = await backend.query(request('vibe'));
      expect(
        ((result['sections'] as List).first as Map)['groups'],
        hasLength(3),
      );
      final vibe = (result['items'] as List).single as Map;
      expect(vibe['strength'], isA<double>());
      expect(vibe['secondary'], isA<double>());
      expect(vibe['inGeneration'], false);
      expect(vibe['bundleCount'], 0);
      expect(vibe['thumbVersion'], isNotNull);
      result = await backend.query(request('gallery'));
      expect(
        ((result['sections'] as List).first as Map)['groups'],
        hasLength(2),
      );
      expect(((result['items'] as List).first as Map)['badge'], isNull);
    },
  );

  test(
    'gallery trees follow sorted pre-order and shared expanded ids with localized uncategorized',
    () async {
      final now = DateTime(2026);
      GalleryCategory folder(
        String id,
        String name,
        int order, {
        String? parent,
        String? path,
      }) => GalleryCategory(
        id: id,
        name: name,
        folderPath: path ?? name,
        parentId: parent,
        sortOrder: order,
        imageCount: 3,
        createdAt: now,
        updatedAt: now,
      );
      (container.read(galleryCategoryNotifierProvider.notifier) as Categories)
          .publish([
            folder('child', 'Child', 0, parent: 'parent'),
            folder('other', '_Hidden', 2),
            folder('parent', 'Parent', 1),
            folder('u', 'Uncategorized', 0),
          ]);
      (container.read(collectionNotifierProvider.notifier) as Collections)
          .publish([
            ImageCollection(
              id: 'child',
              name: 'Child',
              parentId: 'parent',
              createdAt: now,
            ),
            ImageCollection(
              id: 'parent',
              name: 'Parent',
              isFolder: true,
              createdAt: now,
            ),
          ]);
      storage.values[StorageKeys.galleryCategoryTreeExpandedIds] = ['parent'];
      final page = await backend.query(request('gallery'));
      final sections = page['sections'] as List;
      final collections = (sections[1] as Map)['groups'] as List;
      expect(collections.map((g) => (g as Map)['id']), [
        'collection:parent',
        'collection:child',
      ]);
      expect((collections.first as Map)['icon'], 'collectionFolder');
      expect((collections.first as Map)['expanded'], true);
      final folders = (sections.last as Map)['groups'] as List;
      expect(folders.map((g) => (g as Map)['id']), [
        'folder:u',
        'folder:parent',
        'folder:child',
        'folder:other',
      ]);
      expect((folders.first as Map)['icon'], 'uncategorized');
      expect((folders.last as Map)['dim'], true);
      expect((folders[1] as Map)['expanded'], true);
      expect((folders[2] as Map)['parentId'], 'folder:parent');
      expect(
        ((sections.first as Map)['groups'] as List).first,
        containsPair('count', 125),
      );
    },
  );

  test(
    'refs in-generation filter uses shared tray identity and thumbnail versions survive metadata changes',
    () async {
      final target = container.read(refsGenerationTargetProvider);
      final entry = container.read(vibeLibraryNotifierProvider).entries.single;
      final reference = entry.toVibeReference();
      target.vibeOrigins[refsVibeFingerprint(reference)] = 'v';
      container
          .read(generationParamsNotifierProvider.notifier)
          .addVibeReference(reference);
      final page = await backend.query(request('vibe', group: 'inGeneration'));
      expect(
        (page['items'] as List).single,
        containsPair('inGeneration', true),
      );
      final precise = await backend.item(FloatingResourceKind.precise, 'p');
      await backend.favorite(FloatingResourceKind.precise, 'p');
      expect(
        (await backend.item(FloatingResourceKind.precise, 'p'))['thumbVersion'],
        precise['thumbVersion'],
      );
      final record = LocalImageRecord(
        path: '/library/sample.png',
        size: 12,
        modifiedAt: DateTime(2026),
        metadata: const NaiImageMetadata(
          model: ImageModels.animeDiffusionV45Full,
        ),
      );
      expect(backend.galleryItem(record)['badge'], 'V4.5');
      final thumbVersion = backend.galleryItem(record)['thumbVersion'];
      expect(
        backend.galleryItem(record.copyWith(isFavorite: true))['thumbVersion'],
        thumbVersion,
      );
      expect(
        backend.galleryItem(
          record.copyWith(modifiedAt: DateTime(2027)),
        )['thumbVersion'],
        isNot(thumbVersion),
      );
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
          chips: ['favorite', 'nai'],
          sort: 'fileName',
          offset: 60,
        ),
      );
      expect(page['items'], isEmpty); // no fake favorite records
      final forwarded = gallery.queries.firstWhere((q) => q.offset == 60);
      expect(forwarded.offset, 60);
      expect(forwarded.limit, 60);
      expect(forwarded.criteria.showFavoritesOnly, true);
      expect(forwarded.criteria.naiOnly, true);
      expect(forwarded.criteria.dateStart, isNull);
      expect(forwarded.criteria.dateEnd, isNull);
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
      expect(sorts, hasLength(5));
      expect(page['descending'], false);
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
      final folders =
          (sections.firstWhere((s) => (s as Map)['id'] == 'folders')
                  as Map)['groups']
              as List;
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

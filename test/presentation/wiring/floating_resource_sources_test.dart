import 'dart:async';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';

import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/wiring/gallery_search_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_sources.dart';
import 'package:nai_launcher/presentation/wiring/refs_library_wiring.dart';

import '../../helpers/fake_local_gallery_service.dart';
import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;

class MainGallery extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() => const LocalGalleryState(
    filterCriteria: FilterCriteria(
      searchQuery: 'main page',
      showFavoritesOnly: true,
    ),
  );
}

class QueryGallery extends FakeLocalGalleryService {
  QueryGallery()
    : super(
        List.generate(
          125,
          (i) => LocalImageRecord(
            path: '/library/item$i.png',
            size: 1,
            modifiedAt: DateTime(2026),
          ),
        ),
      );
  final queries = <({FilterCriteria criteria, int offset, int limit})>[];
  Completer<GalleryQueryPage>? pending;
  @override
  Future<GalleryQueryPage> queryRecords(
    FilterCriteria criteria, {
    int offset = 0,
    int limit = 50,
    GallerySort sort = const GallerySort.modifiedAtDesc(),
  }) {
    queries.add((criteria: criteria, offset: offset, limit: limit));
    return pending?.future ??
        super.queryRecords(criteria, offset: offset, limit: limit);
  }
}

class Blocks extends PromptBlockLibraryNotifier {
  Blocks(this.library);
  final PromptBlockLibraryState library;
  @override
  Future<PromptBlockLibraryState> build() async => library;
}

class Vibes extends VibeLibraryNotifier {
  Vibes(this.entries);
  final List<VibeLibraryEntry> entries;
  @override
  VibeLibraryState build() =>
      VibeLibraryState(entries: entries, searchQuery: 'main vibe query');
  @override
  Future<void> initialize() async {}
}

class Precise extends PreciseRefLibraryNotifier {
  Precise(this.entries);
  final List<PreciseRefLibraryEntry> entries;
  @override
  PreciseRefLibraryState build() => PreciseRefLibraryState(
    entries: entries,
    searchQuery: 'main precise query',
  );
  @override
  Future<void> initialize() async {}
}

class Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(model: ImageModels.animeDiffusionV45Full);
}

PromptBlock block(String id, {String? folderId, bool favorite = false}) =>
    PromptBlock(
      id: id,
      title: id,
      content: 'blue_eyes',
      negativeContent: 'lowres',
      folderId: folderId,
      isFavorite: favorite,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
void main() {
  late ProviderContainer container;
  late FloatingResourceWindows windows;
  late QueryGallery gallery;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    gallery = QueryGallery();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryWindowSettings()),
        floatingResourceWindowsProvider.overrideWith(
          FloatingResourceWindows.new,
        ),
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(gallery),
        ),
        localGalleryNotifierProvider.overrideWith(MainGallery.new),
        generationParamsNotifierProvider.overrideWith(Params.new),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => Blocks(
            PromptBlockLibraryState(
              blocks: [
                block('root'),
                block('child', folderId: 'child', favorite: true),
                block('other', folderId: 'other'),
              ],
              folders: [
                PromptBlockFolder(
                  id: 'parent',
                  name: 'parent',
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
                PromptBlockFolder(
                  id: 'child',
                  name: 'child',
                  parentId: 'parent',
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ],
              collections: [
                PromptBlockCollection(
                  id: 'collection-folder',
                  name: 'Folder',
                  isFolder: true,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
                PromptBlockCollection(
                  id: 'c',
                  name: 'collection',
                  parentId: 'collection-folder',
                  blockIds: ['child'],
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                ),
              ],
            ),
          ),
        ),
        vibeLibraryNotifierProvider.overrideWith(
          () => Vibes([
            VibeLibraryEntry.fromVibeReference(
              name: 'Sunset',
              vibeData: const VibeReference(
                displayName: 'sun',
                vibeEncoding: 'data',
              ),
            ).copyWith(
              id: 'sun',
              tags: ['warm'],
              categoryId: 'cat',
              isFavorite: true,
            ),
            VibeLibraryEntry.fromVibeReference(
              name: 'Moonlight',
              vibeData: const VibeReference(
                displayName: 'moon',
                vibeEncoding: 'data',
              ),
            ).copyWith(id: 'moon'),
          ]),
        ),
        preciseRefLibraryNotifierProvider.overrideWith(
          () => Precise([
            PreciseRefLibraryEntry(
              id: 'hero',
              name: 'Hero',
              imagePath: '/hero.png',
              createdAt: DateTime(2026),
              isFavorite: true,
            ),
            PreciseRefLibraryEntry(
              id: 'other',
              name: 'Other',
              imagePath: '/other.png',
              createdAt: DateTime(2026),
            ),
          ]),
        ),
        refsVibeStatusesProvider.overrideWith((ref) async => {}),
      ],
    );
    windows = container.read(floatingResourceWindowsProvider.notifier);
  });
  tearDown(() async {
    await windows.saved;
    container.dispose();
  });
  test(
    'two gallery windows page 60 independently without main-page filters',
    () async {
      final main = container.read(localGalleryNotifierProvider);
      final a = windows.open(FloatingResourceKind.gallery)!;
      final b = windows.open(FloatingResourceKind.gallery)!;
      final page = await container.read(
        floatingGalleryPageProvider((id: a, page: 0)).future,
      );
      expect(page.records, hasLength(60));
      expect(page.nextOffset, 60);
      expect(
        (await container.read(
          floatingGalleryPageProvider((id: a, page: 1)).future,
        )).records.first.path,
        '/library/item60.png',
      );
      expect(
        (await container.read(
          floatingGalleryPageProvider((id: a, page: 2)).future,
        )).records,
        hasLength(5),
      );
      windows.setQuery(b, 'item124');
      final filtered = await container.read(
        floatingGalleryPageProvider((id: b, page: 0)).future,
      );
      expect(filtered.records.single.path, '/library/item124.png');
      expect(
        identical(container.read(localGalleryNotifierProvider), main),
        isTrue,
      );
      expect(gallery.applyFilterCount, 0);
      expect(container.read(floatingResourceQueryProvider(a))!.query, isEmpty);
    },
  );
  test(
    'gallery scope is forwarded unchanged and motion does not requery',
    () async {
      final id = windows.open(
        FloatingResourceKind.gallery,
        scope: const FloatingResourceScope(
          folderPath: '/folder',
          categoryId: 'cat',
          collectionId: 'c',
          favoritesOnly: true,
        ),
      )!;
      final provider = floatingGalleryPageProvider((id: id, page: 0));
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      await container.read(provider.future);
      final criteria = gallery.queries.single.criteria;
      expect(criteria.categoryFolderPath, '/folder');
      expect(criteria.categoryId, 'cat');
      expect(criteria.collectionId, 'c');
      expect(criteria.showFavoritesOnly, isTrue);
      windows.move(id, const Rect.fromLTWH(80, 90, 400, 300));
      windows.setMinimized(id, true);
      await container.pump();
      expect(gallery.queries, hasLength(1));
    },
  );
  test(
    'outdated gallery query resolves without replacing newer window results',
    () async {
      final id = windows.open(FloatingResourceKind.gallery)!;
      gallery.pending = Completer<GalleryQueryPage>();
      final old = gallery.pending!;
      final provider = floatingGalleryPageProvider((id: id, page: 0));
      final sub = container.listen(provider, (_, __) {});
      addTearDown(sub.close);
      final oldFuture = container.read(provider.future);
      gallery.pending = null;
      windows.setQuery(id, 'item124');
      await container.pump();
      final current = await container.read(provider.future);
      old.complete(const GalleryQueryPage(records: [], totalCount: 0));
      await oldFuture;
      expect(current.records.single.path, '/library/item124.png');
      expect(
        container.read(provider).requireValue.records.single.path,
        '/library/item124.png',
      );
    },
  );
  test(
    'blocks reuse normalized title/body/negative filtering and scoped tree',
    () async {
      final id = windows.open(FloatingResourceKind.blocks)!;
      windows.setQuery(id, 'blue eyes lowres');
      expect(
        await container.read(floatingBlocksProvider(id).future),
        hasLength(3),
      );
      windows.setScope(
        id,
        const FloatingResourceScope(
          folderId: 'parent',
          favoritesOnly: true,
          collectionId: 'c',
        ),
      );
      expect(
        (await container.read(floatingBlocksProvider(id).future)).single.id,
        'child',
      );
      windows.setScope(
        id,
        const FloatingResourceScope(collectionId: 'collection-folder'),
      );
      expect(
        (await container.read(floatingBlocksProvider(id).future)).single.id,
        'child',
      );
      windows.setQuery(id, 'not found');
      expect(await container.read(floatingBlocksProvider(id).future), isEmpty);
    },
  );
  test(
    'vibe mapping filters name/tags/category/favorites without page state changes',
    () async {
      final id = windows.open(FloatingResourceKind.vibe)!;
      windows.setQuery(id, 'WARM');
      windows.setScope(
        id,
        const FloatingResourceScope(categoryId: 'cat', favoritesOnly: true),
      );
      final entries = await container.read(floatingRefsProvider(id).future);
      expect(entries.single.key, 'sun');
      expect(entries.single.name, 'Sunset');
      expect(entries.single.thumb, isNotNull);
      expect(
        container.read(vibeLibraryNotifierProvider).searchQuery,
        'main vibe query',
      );
      windows.setQuery(id, 'missing');
      expect(await container.read(floatingRefsProvider(id).future), isEmpty);
    },
  );
  test(
    'precise mapping filters name/favorites without page state changes',
    () async {
      final id = windows.open(FloatingResourceKind.precise)!;
      windows.setQuery(id, 'HERO');
      final entries = await container.read(floatingRefsProvider(id).future);
      expect(entries.single.key, 'hero');
      expect(entries.single.imageFormat, 'PNG');
      expect(
        container.read(preciseRefLibraryNotifierProvider).searchQuery,
        'main precise query',
      );
      windows.setQuery(id, 'other');
      windows.setScope(id, const FloatingResourceScope(favoritesOnly: true));
      expect(await container.read(floatingRefsProvider(id).future), isEmpty);
    },
  );
  test(
    'typing does not write history; explicit confirmation reuses gallery history',
    () async {
      final id = windows.open(FloatingResourceKind.gallery)!;
      windows.setQuery(id, 'typing');
      expect(
        await container.read(gallerySearchHistoryProvider.future),
        isEmpty,
      );
      await container
          .read(floatingGalleryQueryActionsProvider)
          .confirm(id, 'aokumo rin');
      expect(container.read(gallerySearchHistoryProvider).requireValue, [
        'aokumo rin',
      ]);
      expect(
        container.read(floatingResourceQueryProvider(id))!.query,
        'aokumo rin',
      );
    },
  );

  test('closed or wrong-kind window has no resource results', () async {
    final id = windows.open(FloatingResourceKind.blocks)!;
    expect(
      (await container.read(
        floatingGalleryPageProvider((id: id, page: 0)).future,
      )).records,
      isEmpty,
    );
    expect(await container.read(floatingRefsProvider(id).future), isEmpty);
    windows.close(id);
    expect(await container.read(floatingBlocksProvider(id).future), isEmpty);
  });
}

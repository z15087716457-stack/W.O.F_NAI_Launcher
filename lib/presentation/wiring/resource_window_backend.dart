import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/cache/thumbnail_cache_service.dart';
import '../../core/services/resource_window_host.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/image_share_sanitizer.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/gallery/local_image_record.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/gallery/gallery_category.dart';
import '../../data/services/gallery/gallery_sort_store.dart';
import '../../data/models/resources/floating_window_data.dart';
import '../../data/services/gallery/gallery_filter_service.dart';
import '../../data/services/gallery/gallery_sort.dart';
import '../../data/services/gallery/gallery_view_mode.dart';
import '../../data/services/gallery/gallery_view_mode_store.dart';
import '../../data/services/gallery/unified_gallery_service.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../../data/services/vibe_library_storage_service.dart';
import '../providers/collection_provider.dart';
import '../providers/gallery_category_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/share_image_settings_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../providers/vibe_library_category_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/refs/refs_contract.dart';
import '../widgets/prompt/blocks/prompt_block_colors.dart';
import '../widgets/gallery/gallery_nai_versions.dart';
import '../utils/gallery_category_label.dart';
import '../utils/local_gallery_metadata_resolver.dart';
import '../ui/viewer/viewer_contract.dart';
import '../widgets/common/image_detail/components/detail_prompt_translation.dart';
import 'refs_preferences.dart';
import 'refs_generation_target.dart';
import 'blocks_mapping.dart';
import 'blocks_preferences.dart';
import 'floating_resource_sources.dart';
import 'gallery_search_history.dart';
import 'image_viewer_gallery.dart';
import 'image_viewer_mapping.dart';
import 'refs_library_wiring.dart';
import 'refs_mapping.dart';

final resourceWindowBackendProvider = Provider(ResourceLibraryBackend.new);

/// Visual operations need the existing WidgetRef-based action hosts. The
/// primary app's non-visual bridge installs these callbacks, never the child.
class ResourceMainActions {
  Future<void> Function(FloatingResourceKind, String, String)? perform;
}

final resourceMainActionsProvider = Provider((ref) => ResourceMainActions());

class ResourceLibraryBackend implements ResourceWindowBackend {
  ResourceLibraryBackend(this.ref);
  final Ref ref;
  final _exports = <String, Future<File>>{};
  final _viewerDeleted = <String>{};
  Future<void>? _collectionsReady;
  final windowKinds = <String, FloatingResourceKind>{};
  LocalGalleryService get gallery => ref.read(galleryServiceProvider);

  Future<LocalImageRecord> galleryRecord(String id) async {
    if (!gallery.isInitialized) resourceError('not_ready');
    final records = await gallery.getLibraryRecordsForPaths([id]);
    if (records.isEmpty) resourceError('not_found');
    return records.single;
  }

  @override
  Future<Object?> galleryViewer(Map<String, Object?> arguments) async {
    final operation = resourceString(arguments, 'operation');
    if (operation == 'records') {
      final ids = (arguments['ids'] as List).cast<String>();
      if (ids.length > 60) resourceError('invalid_arguments', 'ids');
      if (!gallery.isInitialized) resourceError('not_ready');
      return {
        'records': [
          for (final record in await gallery.getLibraryRecordsForPaths(ids))
            {
              'path': record.path,
              'size': record.size,
              'modifiedAt': record.modifiedAt.millisecondsSinceEpoch,
              'favorite': record.isFavorite,
            },
        ],
        'confirmDangerousActions': ref
            .read(shareImageSettingsProvider)
            .effectiveConfirmDangerousActions,
        'highlight': ref.read(highlightEmphasisSettingsProvider),
        'kritaConnected':
            ref.exists(kritaBridgeNotifierProvider) &&
            ref.read(kritaBridgeNotifierProvider).status ==
                KritaBridgeStatus.connected,
        'shortcuts':
            ref.read(shortcutConfigNotifierProvider).valueOrNull == null
            ? null
            : jsonEncode(
                ref.read(shortcutConfigNotifierProvider).requireValue.toJson(),
              ),
      };
    }
    final id = resourceString(arguments, 'id');
    final viewer = ref.read(imageViewerGalleryProvider);
    if (operation == 'restore') {
      if (!_viewerDeleted.contains(id)) resourceError('not_found');
      await viewer.restore(id);
      _viewerDeleted.remove(id);
      return null;
    }
    final record = await galleryRecord(id);
    switch (operation) {
      case 'metadata':
        final metadata = await resolveLocalGalleryMetadata(record);
        return metadata == null ? null : jsonEncode(metadata.toJson());
      case 'collections':
        return [
          for (final collection in await viewer.collections(id))
            {
              'id': collection.id,
              'name': collection.name,
              'member': collection.member,
              'depth': collection.depth,
            },
        ];
      case 'favorite':
        await viewer.setFavorite(id, arguments['value'] as bool);
        return null;
      case 'setCollection':
        await viewer.setCollection(
          id,
          resourceString(arguments, 'collectionId'),
          arguments['member'] as bool,
        );
        return null;
      case 'createCollection':
        final collection = await ref
            .read(collectionNotifierProvider.notifier)
            .createCollection(resourceString(arguments, 'name'));
        if (collection == null) resourceError('failed');
        await viewer.setCollection(id, collection.id, true);
        return null;
      case 'delete':
        final deleted = await viewer.delete(id);
        if (deleted) _viewerDeleted.add(id);
        return deleted;
      case 'translate':
        final part = ViewerPartKind.values
            .asNameMap()[resourceString(arguments, 'part')];
        if (part == null) resourceError('invalid_arguments', 'part');
        final text = viewerPartText(
          await resolveLocalGalleryMetadata(record),
          part == ViewerPartKind.character
              ? ViewerPart.character(arguments['index'] as int)
              : switch (part) {
                  ViewerPartKind.prompt => ViewerPart.prompt,
                  ViewerPartKind.negative => ViewerPart.negative,
                  _ => ViewerPart.seed,
                },
        );
        if (text == null || text.isEmpty) return null;
        final translated = await ref.read(detailPromptTranslatorProvider)(
          PillDocument(text: text, instances: const {}),
          resourceString(arguments, 'session'),
        );
        return viewerTranslationText(translated);
      case 'action':
        final action = ViewerAction.values
            .asNameMap()[resourceString(arguments, 'action')];
        if (action == null) resourceError('invalid_arguments', 'action');
        if (action == ViewerAction.save) resourceError('unsupported');
        final perform = ref.read(resourceMainActionsProvider).perform;
        if (perform == null) resourceError('not_ready');
        await perform(
          FloatingResourceKind.gallery,
          id,
          'viewer:${action.name}',
        );
        return null;
      case 'saveVibe':
        final index = arguments['index'] as int;
        if (index < 0) resourceError('invalid_arguments', 'index');
        final perform = ref.read(resourceMainActionsProvider).perform;
        if (perform == null) resourceError('not_ready');
        await perform(FloatingResourceKind.gallery, id, 'saveVibe:$index');
        return null;
      default:
        resourceError('invalid_arguments', 'operation');
    }
  }

  Future<List<RefsEntry>> refs(FloatingResourceKind kind) async {
    await ref.read(floatingRefsReadyProvider(kind).future);
    if (kind == FloatingResourceKind.vibe) {
      final state = ref.read(vibeLibraryNotifierProvider);
      if (state.error != null) resourceError('not_ready', state.error);
      final statuses = await ref.read(refsVibeStatusesProvider.future);
      final model = ref.read(generationParamsNotifierProvider).model;
      final inUse = ref
          .read(refsGenerationTargetProvider)
          .tray(RefsKind.vibe, statuses: statuses)
          .items
          .map((e) => e.entryKey)
          .toSet();
      return [
        for (final e in state.entries)
          mapVibeEntry(
            e,
            model: model,
            status: statuses[e.id],
            inGeneration: inUse.contains(e.id),
          ),
      ];
    }
    final state = ref.read(preciseRefLibraryNotifierProvider);
    if (state.error != null) resourceError('not_ready', state.error);
    final inUse = ref
        .read(refsGenerationTargetProvider)
        .tray(RefsKind.precise)
        .items
        .map((e) => e.entryKey)
        .toSet();
    return [
      for (final e in state.entries)
        mapPreciseEntry(e, inGeneration: inUse.contains(e.id)),
    ];
  }

  Map<String, Object?> _group(
    String id,
    String label, {
    int? count,
    int? color,
    String? parentId,
    String? icon,
    bool expanded = false,
    bool dim = false,
  }) => {
    'id': id,
    'label': label,
    'count': count,
    'color': color,
    'parentId': parentId,
    'icon': icon,
    'expanded': expanded,
    'dim': dim,
  };
  Map<String, Object?> _section(
    String id,
    String title,
    List<Map<String, Object?>> groups,
  ) => {'id': id, 'title': title, 'groups': groups};
  Map<String, Object?> _option(String id, String label) => {
    'id': id,
    'label': label,
  };

  @override
  Future<Map<String, int>> counts() async {
    await ref.read(promptBlockLibraryNotifierProvider.future);
    await ref.read(floatingRefsReadyProvider(FloatingResourceKind.vibe).future);
    await ref.read(
      floatingRefsReadyProvider(FloatingResourceKind.precise).future,
    );
    final vibeError = ref.read(vibeLibraryNotifierProvider).error;
    final preciseError = ref.read(preciseRefLibraryNotifierProvider).error;
    if (vibeError != null || preciseError != null) {
      resourceError('not_ready', vibeError ?? preciseError);
    }
    return {
      if (gallery.isInitialized)
        'gallery': (await gallery.queryRecords(
          const FilterCriteria(),
          limit: 1,
        )).totalCount,
      if (ref.read(promptBlockLibraryNotifierProvider).valueOrNull
          case final library?)
        'blocks': library.blocks.length,
      if (ref.exists(vibeLibraryNotifierProvider))
        'vibe': ref.read(vibeLibraryNotifierProvider).entries.length,
      if (ref.exists(preciseRefLibraryNotifierProvider))
        'precise': ref.read(preciseRefLibraryNotifierProvider).entries.length,
    };
  }

  @override
  Future<Map<String, Object?>> query(ResourceQuery request) async {
    windowKinds[request.windowId] = request.kind;
    final l = currentL10n;
    final prefs = await SharedPreferences.getInstance();
    final sections = <Map<String, Object?>>[];
    final chips = <Map<String, Object?>>[
      _option('favorite', l.refs_viewFavorites),
    ];
    final sorts = <Map<String, Object?>>[];
    List<String> layouts;
    String layout, sortId;
    bool descending;
    int total;
    List<Map<String, Object?>> items;
    final group = request.groupId ?? 'all';
    final favorite = group == 'favorites' || request.chips.contains('favorite');
    if (request.kind == FloatingResourceKind.gallery) {
      if (!gallery.isInitialized) resourceError('not_ready');
      await (_collectionsReady ??= ref
          .read(collectionNotifierProvider.notifier)
          .initialize());
      final categories = ref.read(galleryCategoryNotifierProvider);
      final collections = ref.read(collectionNotifierProvider);
      if (categories.error != null || collections.error != null) {
        resourceError(
          'not_ready',
          (categories.error ?? collections.error).toString(),
        );
      }
      final expanded = ref
          .read(localStorageServiceProvider)
          .getGalleryCategoryTreeExpandedIds()
          .toSet();
      final folders = <Map<String, Object?>>[];
      void visitFolders(String? parent) {
        for (final c
            in categories.categories
                .where((c) => c.parentId == parent)
                .toList()
                .sortedByOrder()) {
          folders.add(
            _group(
              'folder:${c.id}',
              c.isUncategorizedFolder
                  ? l.localGallery_uncategorizedFolder
                  : c.displayName,
              count: c.imageCount,
              parentId: parent == null ? null : 'folder:$parent',
              icon: c.isUncategorizedFolder ? 'uncategorized' : 'folder',
              expanded: expanded.contains(c.id),
              dim: c.name.startsWith('_'),
            ),
          );
          visitFolders(c.id);
        }
      }

      visitFolders(null);
      final collectionGroups = <Map<String, Object?>>[];
      void visitCollections(String? parent) {
        for (final c in collections.collections.where(
          (c) => c.parentId == parent,
        )) {
          collectionGroups.add(
            _group(
              'collection:${c.id}',
              c.name,
              count: c.imageCount,
              parentId: parent == null ? null : 'collection:$parent',
              icon:
                  c.isFolder ||
                      collections.collections.any(
                        (child) => child.parentId == c.id,
                      )
                  ? 'collectionFolder'
                  : 'collection',
              expanded: expanded.contains(c.id),
            ),
          );
          visitCollections(c.id);
        }
      }

      visitCollections(null);
      sections.addAll([
        _section('library', l.localGallery_sectionLibrary, [
          _group(
            'all',
            l.localGallery_allImages,
            icon: 'all',
            count: (await gallery.queryRecords(
              const FilterCriteria(),
              limit: 1,
            )).totalCount,
          ),
          _group(
            'favorites',
            l.common_favorite,
            icon: 'favorite',
            count: await gallery.getFavoriteCount(),
          ),
        ]),
        _section(
          'collections',
          l.localGallery_sectionCollections,
          collectionGroups,
        ),
        _section('folders', l.localGallery_sectionFolders, folders),
      ]);
      chips.add(_option('nai', l.localGallery_naiOnlyChip));
      final labels = [
        l.imageViewer_sortModified,
        l.imageViewer_sortCreated,
        l.imageViewer_sortFileName,
        l.imageViewer_sortFileSize,
        l.imageViewer_sortDimensions,
      ];
      for (final field in GallerySortField.values) {
        sorts.add(_option(field.name, labels[field.index]));
      }
      final saved =
          await const GallerySortStore().load() ??
          const GallerySort.modifiedAtDesc();
      sortId = request.sortId ?? saved.field.name;
      _validate(request, sections, chips, sorts, sortId);
      final field = GallerySortField.values.byName(sortId);
      descending =
          request.descending ??
          (request.sortId != null && request.sortId != saved.field.name
              ? GallerySort.defaultDirectionFor(field) ==
                    GallerySortDirection.descending
              : saved.direction == GallerySortDirection.descending);
      final sort = GallerySort(
        field: field,
        direction: descending
            ? GallerySortDirection.descending
            : GallerySortDirection.ascending,
      );
      if (sort.field != saved.field || sort.direction != saved.direction) {
        await const GallerySortStore().save(sort);
        if (ref.exists(localGalleryNotifierProvider)) {
          await ref
              .read(localGalleryNotifierProvider.notifier)
              .setSort(sort.field, sort.direction);
        }
      }
      final category = group.startsWith('folder:')
          ? categories.categories
                .where((c) => c.id == group.substring(7))
                .firstOrNull
          : null;
      final page = await gallery.queryRecords(
        FilterCriteria(
          searchQuery: request.query,
          showFavoritesOnly: favorite,
          naiOnly: request.chips.contains('nai'),
          categoryId: category?.id,
          categoryFolderPath: category?.folderPath,
          collectionId: group.startsWith('collection:')
              ? group.substring(11)
              : null,
        ),
        offset: request.offset,
        limit: request.limit,
        sort: sort,
      );
      total = page.totalCount;
      items = [for (final r in page.records) galleryItem(r)];
      layouts = ['grid', 'masonry', 'justified'];
      layout = (await const GalleryViewModeStore().load()).name;
    } else if (request.kind == FloatingResourceKind.blocks) {
      final library = await ref.read(promptBlockLibraryNotifierProvider.future);
      final saved = await ref.read(blocksPreferencesProvider.future);
      final labels = [
        l.blocks_sortCustom,
        l.blocks_sortUpdated,
        l.blocks_sortTitle,
        l.blocks_sortColor,
        l.blocks_sortIcon,
      ];
      for (final sort in BlocksSort.values) {
        sorts.add({
          ..._option(sort.name, labels[sort.index]),
          'directional': sort != BlocksSort.custom,
        });
      }
      sortId = request.sortId ?? saved.sort.name;
      descending = request.descending ?? saved.descending;
      final scope = group.startsWith('folder:')
          ? BlocksScope.folder(group.substring(7))
          : group.startsWith('collection:')
          ? BlocksScope.collection(group.substring(11))
          : switch (group) {
              'recent' => const BlocksScope.recent(),
              'favorites' => const BlocksScope.favorites(),
              'uncategorized' => const BlocksScope.uncategorized(),
              _ => const BlocksScope.all(),
            };
      final base = mapBlocksLibrary(library, preferences: saved);
      sections.addAll([
        _section('library', l.localGallery_sectionLibrary, [
          _group(
            'all',
            l.blocks_allBlocks,
            count: base.counts.all,
            icon: 'all',
          ),
          _group(
            'recent',
            l.blocks_recent,
            count: base.counts.recent,
            icon: 'recent',
          ),
          _group(
            'favorites',
            l.refs_viewFavorites,
            count: base.counts.favorites,
            icon: 'favorite',
          ),
        ]),
        _section('collections', l.blocks_collections, [
          for (final c in base.collections)
            _group(
              'collection:${c.id}',
              c.name,
              count: c.count,
              parentId: c.parentId == null ? null : 'collection:${c.parentId}',
              icon: c.isFolder ? 'collectionFolder' : 'collection',
              // Main blocks navigation renders all collection descendants.
              expanded: true,
            ),
        ]),
        _section('folders', l.blocks_folders, [
          _group(
            'uncategorized',
            l.blocks_uncategorized,
            count: base.counts.uncategorized,
            icon: 'uncategorized',
          ),
          for (final f in base.folders)
            _group(
              'folder:${f.id}',
              f.name,
              count: f.count,
              parentId: f.parentId == null ? null : 'folder:${f.parentId}',
              icon: 'folder',
              expanded: f.expanded,
            ),
        ]),
      ]);
      chips.addAll([
        _option('positive', l.blocks_positive),
        _option('negative', l.blocks_negative),
      ]);
      _validate(request, sections, chips, sorts, sortId);
      if (sortId != saved.sort.name || descending != saved.descending) {
        await ref
            .read(blocksPreferencesProvider.notifier)
            .change(
              (p) => p.copyWith(
                sort: BlocksSort.values.byName(sortId),
                descending: descending,
              ),
            );
      }
      final mapped = mapBlocksLibrary(
        library,
        preferences: saved.copyWith(
          scope: scope,
          sort: BlocksSort.values.byName(sortId),
          descending: descending,
          groupByFolder: false,
        ),
        query: request.query,
      );
      final filtered = mapped.blocks
          .where(
            (b) =>
                (!favorite || b.favorite) &&
                (!request.chips.contains('positive') ||
                    library.blockById(b.id)!.content.isNotEmpty) &&
                (!request.chips.contains('negative') ||
                    library.blockById(b.id)!.negativeContent.isNotEmpty),
          )
          .toList();
      total = filtered.length;
      items = [
        for (final b in filtered.skip(request.offset).take(request.limit))
          blockItem(library.blockById(b.id)!, library),
      ];
      layouts = ['masonry', 'grid', 'list'];
      layout = saved.view.name;
    } else {
      final all = await refs(request.kind);
      sections.add(
        _section('library', l.localGallery_sectionLibrary, [
          _group('all', l.refs_viewAll, count: all.length, icon: 'all'),
          _group(
            'favorites',
            l.refs_viewFavorites,
            count: all.where((e) => e.favorite).length,
            icon: 'favorite',
          ),
          _group(
            'inGeneration',
            l.refs_viewInGeneration,
            count: all.where((e) => e.inGeneration).length,
            icon: 'inGeneration',
          ),
        ]),
      );
      if (request.kind == FloatingResourceKind.vibe) {
        final categories = ref.read(vibeLibraryCategoryNotifierProvider);
        if (categories.error != null) {
          resourceError('not_ready', categories.error.toString());
        }
        sections.add(
          _section('categories', l.refs_categories, [
            for (final c in refsCategories(categories.categories, all))
              _group(
                'category:${c.id}',
                c.name,
                count: c.count,
                parentId: c.parentId == null ? null : 'category:${c.parentId}',
                icon: 'category',
                expanded: true,
              ),
          ]),
        );
        chips.add(_option('usable', l.resourceWindow_currentModelUsable));
      } else {
        sections.add(
          _section('types', l.refs_types, [
            _group(
              'type:character',
              l.refs_typeCharacter,
              count: all
                  .where((e) => e.type == RefsPreciseType.character)
                  .length,
              icon: 'typeCharacter',
            ),
            _group(
              'type:style',
              l.refs_typeStyle,
              count: all.where((e) => e.type == RefsPreciseType.style).length,
              icon: 'typeStyle',
            ),
            _group(
              'type:both',
              l.refs_typeBoth,
              count: all.where((e) => e.type == RefsPreciseType.both).length,
              icon: 'typeBoth',
            ),
          ]),
        );
      }
      final labels = [
        l.refs_sortLastUsed,
        l.refs_sortCreated,
        l.refs_sortUsed,
        l.refs_sortName,
      ];
      for (final sort in RefsSort.values) {
        sorts.add(_option(sort.name, labels[sort.index]));
      }
      final store = RefsPreferenceStore(
        ref.read(localStorageServiceProvider),
        request.kind == FloatingResourceKind.vibe
            ? RefsKind.vibe
            : RefsKind.precise,
      );
      final saved = store.read().filter;
      sortId = request.sortId ?? saved.sort.name;
      descending = request.descending ?? saved.descending;
      _validate(request, sections, chips, sorts, sortId);
      if (sortId != saved.sort.name || descending != saved.descending) {
        final sort = RefsSort.values.byName(sortId);
        await store.saveFilter(
          saved.copyWith(sort: sort, descending: descending),
        );
        ref.read(refsSortChangedProvider(store.kind).notifier).state = (
          sort: sort,
          descending: descending,
        );
      }
      final filtered =
          filterRefsEntries(
                all,
                RefsFilter(
                  query: request.query,
                  view: group == 'inGeneration'
                      ? RefsView.inGeneration
                      : favorite
                      ? RefsView.favorites
                      : RefsView.all,
                  categoryId: group.startsWith('category:')
                      ? group.substring(9)
                      : null,
                  type: group.startsWith('type:')
                      ? RefsPreciseType.values.byName(group.substring(5))
                      : null,
                  sort: RefsSort.values.byName(sortId),
                  descending: descending,
                ),
              )
              .where(
                (e) =>
                    !request.chips.contains('usable') ||
                    (refsModel(
                          ref.read(generationParamsNotifierProvider).model,
                        ).vibeUsable &&
                        e.encoding != RefsEncoding.unusable),
              )
              .toList();
      total = filtered.length;
      items = [
        for (final e in filtered.skip(request.offset).take(request.limit))
          refItem(e, request.kind),
      ];
      layouts = ['grid', 'list'];
      layout =
          prefs.getString('resource_window_${request.kind.name}_view') ??
          'grid';
    }
    return {
      'items': items,
      'total': total,
      'hasMore': request.offset + items.length < total,
      'sections': sections,
      'chips': [
        for (final chip in chips)
          {...chip, 'on': request.chips.contains(chip['id'])},
      ],
      'sorts': sorts,
      'sortId': sortId,
      'descending': descending,
      'layouts': layouts,
      'layout': layout,
      'cellSize':
          prefs.getDouble('resource_window_${request.kind.name}_cell_size') ??
          132,
      'queryHint': request.kind == FloatingResourceKind.gallery
          ? l.floating_searchGallery
          : l.floating_searchName,
      'counts': await counts(),
    };
  }

  void _validate(
    ResourceQuery r,
    List<Map<String, Object?>> sections,
    List<Map<String, Object?>> chips,
    List<Map<String, Object?>> sorts,
    String sort,
  ) {
    final groups = sections.expand(
      (s) => (s['groups'] as List).cast<Map<String, Object?>>(),
    );
    if (!groups.any((g) => g['id'] == (r.groupId ?? 'all')) ||
        r.chips.any((id) => !chips.any((c) => c['id'] == id)) ||
        !sorts.any((s) => s['id'] == sort)) {
      resourceError('invalid_arguments');
    }
  }

  Map<String, Object?> galleryItem(LocalImageRecord r) {
    final m = r.metadata;
    return {
      'id': r.path,
      'title':
          '${r.modifiedAt.hour.toString().padLeft(2, '0')}:${r.modifiedAt.minute.toString().padLeft(2, '0')}',
      'meta': m?.width == null ? null : '${m!.width}×${m.height}',
      'aspect': m?.width != null && (m?.height ?? 0) > 0
          ? m!.width! / m.height!
          : null,
      'badge': GalleryNaiVersions.labelForModel(m?.effectiveModel),
      'thumbVersion': '${r.size}:${r.modifiedAt.microsecondsSinceEpoch}',
      'favorite': r.isFavorite,
      'positive': m?.prompt,
      'negative': m?.negativePrompt,
      'date': r.modifiedAt.millisecondsSinceEpoch,
    };
  }

  Map<String, Object?> blockItem(
    PromptBlock b,
    PromptBlockLibraryState library,
  ) => {
    'id': b.id,
    'title': b.displayTitle,
    'positive': b.content,
    'negative': b.negativeContent,
    'favorite': b.isFavorite,
    'color': promptBlockColorFromString(b.color).toARGB32(),
    'iconKey': b.iconName,
    'hasThumb': b.thumbnail != null,
    'thumbVersion': '${b.thumbnail}:${b.updatedAt.microsecondsSinceEpoch}',
    'crop': {
      'offsetX': b.thumbnailOffsetX,
      'offsetY': b.thumbnailOffsetY,
      'scale': b.thumbnailScale,
    },
    'itemCount': blockDataOf(b, library).itemCount,
    'useCount': b.useCount,
    'hasParams': b.generationSettings?.isEmpty == false,
    'folder': b.folderId == null ? null : library.folderById(b.folderId!)?.name,
  };
  Map<String, Object?> refItem(RefsEntry e, FloatingResourceKind kind) {
    final precise = kind == FloatingResourceKind.precise
        ? ref
              .read(preciseRefLibraryNotifierProvider)
              .entries
              .firstWhere((p) => p.id == e.key)
        : null;
    // Precise entries have no updatedAt or replace-image API. Managed images
    // are immutable; path + creation time avoids metadata-only cache churn.
    final preciseVersion = precise == null
        ? null
        : '${precise.imagePath}:${precise.createdAt.microsecondsSinceEpoch}';
    return {
      'id': e.key,
      'title': e.name,
      'favorite': e.favorite,
      'strength': e.strength,
      'secondary': kind == FloatingResourceKind.vibe
          ? e.infoExtracted
          : e.fidelity,
      'inGeneration': e.inGeneration,
      'bundleCount': e.bundleCount,
      'thumbVersion': kind == FloatingResourceKind.vibe
          ? ref
                .read(vibeLibraryStorageServiceProvider)
                .getDisplayThumbnailRevision(e.key)
          : preciseVersion,
      'meta': kind == FloatingResourceKind.vibe
          ? '${e.strength} · ${e.infoExtracted}'
          : '${e.strength} · ${e.fidelity}',
      'badge': kind == FloatingResourceKind.vibe
          ? switch (e.encoding) {
              RefsEncoding.ready => currentL10n.refs_encReadyShort(
                refsShortModel(
                  ref.read(generationParamsNotifierProvider).model,
                ),
              ),
              RefsEncoding.unusable => currentL10n.library_unavailable,
              RefsEncoding.encodeOnUse => currentL10n.refs_encOnUse,
              RefsEncoding.reencode => currentL10n.refs_encRe,
              RefsEncoding.unknown => null,
            }
          : switch (e.type) {
              RefsPreciseType.character => currentL10n.refs_typeCharacter,
              RefsPreciseType.style => currentL10n.refs_typeStyle,
              RefsPreciseType.both => currentL10n.refs_typeBoth,
            },
      'positive': e.tags.join(', '),
    };
  }

  Future<Map<String, Object?>> item(
    FloatingResourceKind kind,
    String id,
  ) async {
    if (kind == FloatingResourceKind.gallery) {
      return galleryItem(await galleryRecord(id));
    }
    if (kind == FloatingResourceKind.blocks) {
      final library = await ref.read(promptBlockLibraryNotifierProvider.future);
      final block = library.blockById(id);
      if (block == null) resourceError('not_found');
      return blockItem(block, library);
    }
    final entry = (await refs(kind)).where((e) => e.key == id).firstOrNull;
    if (entry == null) resourceError('not_found');
    return refItem(entry, kind);
  }

  @override
  Future<Map<String, Object?>> detail(
    FloatingResourceKind kind,
    String id,
  ) async {
    final value = await item(kind, id);
    final l = currentL10n;
    Map<String, Object?> action(
      String id,
      String label, [
      bool primary = false,
    ]) => {'id': id, 'label': label, 'primary': primary};
    return {
      'itemId': id,
      'title': value['title'],
      'subtitle': value['meta'],
      'body': value['positive'],
      'negative': value['negative'],
      'actions': switch (kind) {
        FloatingResourceKind.gallery => [
          action('reuse', l.imageViewer_reuse, true),
          action('img2img', l.imageViewer_img2img),
          action('vibe', l.imageViewer_styleTransfer),
          action('copy', l.imageViewer_copyImage),
        ],
        FloatingResourceKind.blocks => [
          action('positive', l.resourceWindow_insertPositive, true),
          action('negative', l.resourceWindow_insertNegative),
          action('edit', l.blocks_edit),
        ],
        _ => [
          action(
            'add',
            kind == FloatingResourceKind.precise
                ? l.gen_addPrecise
                : l.refs_addToGeneration,
            true,
          ),
          action('edit', l.blocks_edit),
        ],
      },
    };
  }

  @override
  Future<Uint8List?> thumbnail(
    FloatingResourceKind kind,
    String id,
    int revision,
  ) async {
    // Validate only the current ID here, not the whole library's encoding
    // statuses for every visible thumbnail. No child-supplied paths are read.
    if (kind == FloatingResourceKind.gallery) {
      await galleryRecord(id);
    } else if (kind == FloatingResourceKind.blocks) {
      final library = await ref.read(promptBlockLibraryNotifierProvider.future);
      if (library.blockById(id) == null) resourceError('not_found');
    } else {
      await ref.read(floatingRefsReadyProvider(kind).future);
      if (kind == FloatingResourceKind.vibe) {
        final state = ref.read(vibeLibraryNotifierProvider);
        if (state.error != null) resourceError('not_ready', state.error);
        if (!state.entries.any((e) => e.id == id)) resourceError('not_found');
      } else {
        final state = ref.read(preciseRefLibraryNotifierProvider);
        if (state.error != null) resourceError('not_ready', state.error);
        if (!state.entries.any((e) => e.id == id)) resourceError('not_found');
      }
    }
    if (kind == FloatingResourceKind.vibe) {
      return ref
          .read(vibeLibraryStorageServiceProvider)
          .getDisplayThumbnail(id);
    }
    if (kind == FloatingResourceKind.precise) {
      return ref
          .read(preciseRefLibraryStorageServiceProvider)
          .getDisplayThumbnail(id);
    }
    final path = kind == FloatingResourceKind.gallery
        ? await ThumbnailCacheService.instance.getOrGenerateThumbnail(
            (await galleryRecord(id)).path,
            size: ThumbnailSize.medium,
          )
        : (await ref.read(
            promptBlockLibraryNotifierProvider.future,
          )).blockById(id)?.thumbnail;
    if (path == null) return null;
    final file = File(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> action(
    FloatingResourceKind kind,
    String id,
    String actionId,
  ) async {
    final actions = (await detail(kind, id))['actions'] as List;
    if (!actions.any((a) => (a as Map)['id'] == actionId)) {
      resourceError('invalid_arguments');
    }
    final perform = ref.read(resourceMainActionsProvider).perform;
    if (perform == null) resourceError('not_ready');
    await perform(kind, id, actionId);
  }

  @override
  Future<void> open(FloatingResourceKind kind, String id) async {
    await item(kind, id);
    final perform = ref.read(resourceMainActionsProvider).perform;
    if (perform == null) resourceError('not_ready');
    await perform(
      kind,
      id,
      kind == FloatingResourceKind.gallery ? 'open' : 'edit',
    );
  }

  @override
  Future<void> favorite(FloatingResourceKind kind, String id) async {
    final value = await item(kind, id);
    switch (kind) {
      case FloatingResourceKind.gallery:
        await ref
            .read(localGalleryNotifierProvider.notifier)
            .toggleFavorite(id);
        if (await gallery.isFavorite(id) == value['favorite']) {
          resourceError('not_ready', 'Favorite update failed');
        }
      case FloatingResourceKind.blocks:
        await ref
            .read(promptBlockLibraryNotifierProvider.notifier)
            .toggleFavorite(id);
      case FloatingResourceKind.vibe:
        if (await ref
                .read(vibeLibraryNotifierProvider.notifier)
                .toggleFavorite(id) ==
            null) {
          resourceError('not_found');
        }
      case FloatingResourceKind.precise:
        await ref
            .read(preciseRefLibraryNotifierProvider.notifier)
            .toggleFavorite(id);
        final current = ref
            .read(preciseRefLibraryNotifierProvider)
            .entries
            .where((e) => e.id == id)
            .firstOrNull;
        if (current == null) resourceError('not_found');
        if (current.isFavorite == value['favorite']) {
          resourceError('not_ready', 'Favorite update failed');
        }
    }
  }

  @override
  Future<Uri> exportGallery(String id) async {
    final record = await galleryRecord(id);
    final strip = ref
        .read(shareImageSettingsProvider)
        .effectiveStripMetadataForCopyAndDrag;
    if (!strip) return File(record.path).uri;
    final key =
        '$id:${record.size}:${record.modifiedAt.microsecondsSinceEpoch}';
    final pending = _exports.putIfAbsent(key, () async {
      final bytes = await File(record.path).readAsBytes();
      final image = await ImageShareSanitizer.prepareForCopyOrDragInBackground(
        bytes,
        fileName: p.basename(id),
        stripMetadata: true,
      );
      return ImageShareSanitizer.writeTempShareFile(image);
    });
    final File file;
    try {
      file = await pending;
    } catch (_) {
      if (identical(_exports[key], pending)) _exports.remove(key);
      rethrow;
    }
    if (!ref
        .read(shareImageSettingsProvider)
        .effectiveStripMetadataForCopyAndDrag) {
      return File(record.path).uri;
    }
    return file.uri;
  }

  @override
  Future<void> layout(String windowId, Map<String, Object?> values) async {
    final kind = windowKinds[windowId];
    if (kind == null) resourceError('not_found');
    final rect = resourceMap(values['rect']);
    for (final key in ['left', 'top', 'width', 'height']) {
      if (rect[key] is! num || !(rect[key] as num).isFinite) {
        resourceError('invalid_arguments');
      }
    }
    if ((rect['width'] as num) < 560 ||
        (rect['height'] as num) < 420 ||
        (rect['dpiScale'] != null &&
            (rect['dpiScale'] is! num ||
                !(rect['dpiScale'] as num).isFinite ||
                (rect['dpiScale'] as num) <= 0)) ||
        values['alwaysOnTop'] is! bool) {
      resourceError('invalid_arguments');
    }
    await ref.read(localStorageServiceProvider).setSetting(
      'resource_window_${kind.name}_layout',
      <String, Object?>{'rect': rect, 'alwaysOnTop': values['alwaysOnTop']},
    );
  }

  @override
  Future<void> preferences(
    FloatingResourceKind kind,
    Map<String, Object?> values,
  ) async {
    if (values['layout'] != null && values['layout'] is! String ||
        values['cellSize'] != null && values['cellSize'] is! num) {
      resourceError('invalid_arguments');
    }
    final prefs = await SharedPreferences.getInstance();
    if (values['layout'] case final String layout) {
      final allowed = switch (kind) {
        FloatingResourceKind.gallery => ['grid', 'masonry', 'justified'],
        FloatingResourceKind.blocks => ['masonry', 'grid', 'list'],
        _ => ['grid', 'list'],
      };
      if (!allowed.contains(layout)) resourceError('invalid_arguments');
      if (kind == FloatingResourceKind.gallery) {
        final mode = GalleryViewMode.values.byName(layout);
        await const GalleryViewModeStore().save(mode);
        if (ref.exists(localGalleryNotifierProvider)) {
          ref.read(localGalleryNotifierProvider.notifier).setViewMode(mode);
        }
      } else if (kind == FloatingResourceKind.blocks) {
        await ref
            .read(blocksPreferencesProvider.notifier)
            .change((p) => p.copyWith(view: BlocksView.values.byName(layout)));
      } else {
        await prefs.setString('resource_window_${kind.name}_view', layout);
      }
    }
    if (values['cellSize'] case final num size) {
      if (!size.isFinite || size < 96 || size > 220) {
        resourceError('invalid_arguments');
      }
      await prefs.setDouble(
        'resource_window_${kind.name}_cell_size',
        size.toDouble(),
      );
    }
  }

  @override
  Future<void> confirmSearch(String query) =>
      ref.read(gallerySearchHistoryProvider.notifier).add(query);

  Future<void> dispose() async {
    final exports = _exports.values.toList();
    _exports.clear();
    for (final pending in exports) {
      try {
        final file = await pending;
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Temporary export may still be held by the OS drop target.
      } on ImageSanitizeException {
        // Failed preparations have no temporary file to remove.
      }
    }
    windowKinds.clear();
  }
}

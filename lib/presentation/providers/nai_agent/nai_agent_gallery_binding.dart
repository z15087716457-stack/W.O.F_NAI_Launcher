import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/database_manager.dart';
import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/utils/gallery_path_utils.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../../data/repositories/gallery_category_repository.dart';
import '../../../data/models/gallery/gallery_category.dart';
import '../../../data/services/gallery/unified_gallery_service.dart';
import '../../../data/services/gallery/gallery_filter_service.dart';
import '../../../data/services/gallery/gallery_delete_pool_store.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../canvas_settings_provider.dart';
import '../local_gallery_provider.dart';
import '../collection_provider.dart';
import '../gallery_category_provider.dart';
import '../share_image_settings_provider.dart';
import 'nai_agent_questions.dart';
import '../image_generation_provider.dart';
import '../generation/preview_selection_provider.dart';

part 'nai_agent_gallery_management.dart';
part 'nai_agent_gallery_collections.dart';
part 'nai_agent_gallery_files.dart';

final naiAgentGalleryDataSourceProvider = Provider<GalleryDataSource>((ref) {
  final source = DatabaseManager.instance.getDataSource<GalleryDataSource>(
    'gallery',
  );
  if (source == null) {
    throw const NaiAgentToolError(
      'gallery_unavailable',
      'Gallery database is not available',
    );
  }
  return source;
});

int _number(Map<String, dynamic> params, String key, int fallback, int max) {
  final value = params[key] ?? fallback;
  if (value is! int || value < (key == 'offset' ? 0 : 1) || value > max) {
    throw NaiAgentToolError('invalid_query', 'Invalid $key');
  }
  return value;
}

String _string(Map<String, dynamic> params, String key) {
  final value = params[key] ?? '';
  if (value is! String || value.length > 200) {
    throw NaiAgentToolError('invalid_query', 'Invalid $key');
  }
  return value;
}

List<String> _strings(Map<String, dynamic> params, String key) {
  final value = params[key] ?? const <String>[];
  if (value is! List ||
      value.length > 30 ||
      value.any((s) => s is! String || s.isEmpty || s.length > 200)) {
    throw NaiAgentToolError('invalid_query', 'Invalid $key');
  }
  return value.cast<String>();
}

DateTime? _date(Map<String, dynamic> params, String key) {
  final value = params[key];
  if (value == null) return null;
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw NaiAgentToolError('invalid_query', 'Expected YYYY-MM-DD for $key');
  }
  final date = DateTime.tryParse(value);
  if (date == null || date.toIso8601String().substring(0, 10) != value) {
    throw NaiAgentToolError('invalid_query', 'Invalid calendar date for $key');
  }
  return date;
}

class NaiAgentGalleryBinding {
  NaiAgentGalleryBinding(
    this.ref,
    this.isAlive, {
    this.workspace,
    this.isBusy,
    this.owner,
    GalleryCategoryRepository? categoryRepository,
    AgentWorkspaceFiles? workspaceFiles,
  }) : categoryRepository =
           categoryRepository ?? GalleryCategoryRepository.instance,
       files =
           workspaceFiles ??
           (workspace == null ? null : AgentWorkspaceFiles(workspace));
  final Ref ref;
  final bool Function() isAlive;
  final Directory? workspace;
  final bool Function()? isBusy;
  final AgentWorkspaceFiles? files;
  final NaiAgentConversationOwner? owner;
  final GalleryCategoryRepository categoryRepository;

  Future<Map<String, dynamic>> manage(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) => _manage(params, token);

  /// UI undo only: uses the same backup, conflict checks and native manage paths
  /// as tools, but never asks the model to execute anything.
  Future<bool> undoManage(
    Map<String, dynamic> arguments,
    Map<String, dynamic> result,
  ) async {
    final token = NaiAgentCancellation();
    Map<String, dynamic> details(Map<String, dynamic> envelope) =>
        Map<String, dynamic>.from(envelope['details'] as Map);
    try {
      _admit(token);
      final action = arguments['action'];
      final id = result['image_id'] as String?;
      final before = Map<String, dynamic>.from(result['before'] as Map? ?? {});
      if (action == 'collection_add' || action == 'collection_remove') {
        final versions = Map<String, dynamic>.from(
          result['image_versions'] as Map? ?? {},
        );
        if (versions.isEmpty || before.length != versions.length) return false;
        for (final entry in versions.entries) {
          if ((await _managed('library', entry.key, token)).version !=
              entry.value) {
            return false;
          }
        }
        final source = ref.read(naiAgentGalleryDataSourceProvider);
        if (_collectionVersion(await source.readCollectionManagementState()) !=
            result['collection_version']) {
          return false;
        }
        final collection = result['collection_id'];
        final ids = <String>[];
        for (final imageId in versions.keys) {
          final old = Map<String, dynamic>.from(before[imageId] as Map);
          final wasMember = (old['collection_ids'] as List).contains(
            collection,
          );
          if (wasMember != (action == 'collection_add')) ids.add(imageId);
        }
        if (ids.isNotEmpty) {
          final reversed = details(
            await _collections(
              {
                'action': action == 'collection_add'
                    ? 'collection_remove'
                    : 'collection_add',
                'collection_id': collection,
                'image_ids': ids,
                'expected_collection_version': result['collection_version'],
              },
              token,
              expectedImageVersions: versions,
            ),
          );
          if (reversed['ok'] != true) return false;
        }
        // Adding sets favorite. Removing membership alone does not undo that.
        for (final imageId in versions.keys) {
          final old = Map<String, dynamic>.from(before[imageId] as Map);
          final now = await _managed('library', imageId, token);
          if (old['favorite'] != now.data['favorite']) {
            final reversed = details(
              await manage({
                'action': 'update',
                'scope': 'library',
                'image_id': imageId,
                'expected_image_version': now.version,
                'changes': {'favorite': old['favorite']},
              }, token),
            );
            if (reversed['ok'] != true) return false;
          }
        }
        return true;
      }
      if (action == 'move_file' && result['image_ids'] is List) {
        final ids = _galleryBatchIds(result['image_ids']);
        final versions = result['image_versions'];
        final originals = result['source_paths'];
        if (versions is! Map || originals is! Map || result['ok'] == false) {
          return false;
        }
        final groups = <String, List<String>>{};
        // Validate ALL groups before the first mutation, so one stale image or
        // occupied original path cannot produce a knowingly partial undo.
        for (final imageId in ids) {
          if (versions[imageId] is! String || originals[imageId] is! String) {
            return false;
          }
          final current = await _managed('library', imageId, token);
          final original = originals[imageId] as String;
          if (current.version != versions[imageId] ||
              await FileSystemEntity.type(original, followLinks: false) !=
                  FileSystemEntityType.notFound ||
              p.basename(current.data['file_path'] as String) !=
                  p.basename(original)) {
            return false;
          }
          final folder = await _folderPath(p.dirname(original));
          groups.putIfAbsent(folder, () => []).add(imageId);
        }
        for (final group in groups.entries) {
          final reversed = details(
            await manage({
              'action': 'move_file',
              'scope': 'library',
              'image_ids': group.value,
              'expected_image_versions': {
                for (final imageId in group.value) imageId: versions[imageId],
              },
              'target_folder': group.key,
            }, token),
          );
          if (reversed['ok'] != true) return false;
        }
        return true;
      }
      if (id == null || result['image_version'] is! String) return false;
      final current = await _managed('library', id, token);
      if (current.version != result['image_version']) return false;
      final reverse = <String, dynamic>{
        'scope': 'library',
        'image_id': id,
        'expected_image_version': current.version,
      };
      if (action == 'update') {
        final fields = (arguments['changes'] as Map).keys;
        if (fields.any((k) => !before.containsKey(k))) return false;
        reverse.addAll({
          'action': 'update',
          'changes': {for (final k in fields) k: before[k]},
        });
      } else if (action == 'delete' || action == 'restore') {
        reverse['action'] = action == 'delete' ? 'restore' : 'delete';
      } else if (action == 'move_file' && result['source_path'] is String) {
        // Do not let collision renaming turn an undo into a different filename.
        final original = result['source_path'] as String;
        if (await FileSystemEntity.type(original, followLinks: false) !=
            FileSystemEntityType.notFound) {
          return false;
        }
        if (p.basename(current.data['file_path'] as String) !=
            p.basename(original)) {
          return false;
        }
        reverse.addAll({
          'action': 'move_file',
          'target_folder': p.dirname(original),
        });
      } else {
        return false;
      }
      final reversed = details(await manage(reverse, token));
      if (reversed['ok'] != true) return false;
      if (action == 'update' &&
          (arguments['changes'] as Map)['favorite'] == false) {
        // Unfavorite also removed all memberships; restore the exact old set.
        for (final collection in before['collection_ids'] as List? ?? []) {
          final state = await _collections({'action': 'collections'}, token);
          final added = details(
            await manage({
              'action': 'collection_add',
              'collection_id': collection,
              'image_ids': [id],
              'expected_collection_version': details(
                state,
              )['collection_version'],
            }, token),
          );
          if (added['ok'] != true) return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _check(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
  }

  Future<LocalGalleryService> _service(NaiAgentCancellation token) async {
    // Reading the service directly avoids initializing the gallery screen
    // notifier, which restores visible filters and scroll datasets.
    for (var i = 0; i < 100; i++) {
      _check(token);
      final service = ref.read(galleryServiceProvider);
      if (service is ErrorGalleryService) {
        throw const NaiAgentToolError(
          'gallery_unavailable',
          'Gallery initialization failed',
        );
      }
      if (service.isInitialized) return service;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw const NaiAgentToolError(
      'gallery_unavailable',
      'Gallery is still initializing; retry later',
    );
  }

  Future<Map<String, dynamic>> query(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    const keys = {
      'scope',
      'image_id',
      'offset',
      'limit',
      'query',
      'tags',
      'models',
      'favorites',
      'date_start',
      'date_end',
    };
    if (params.keys.any((key) => !keys.contains(key))) {
      throw const NaiAgentToolError(
        'invalid_query',
        'Unknown gallery query field',
      );
    }
    final scope = params['scope'] ?? 'history';
    if (scope != 'history' && scope != 'library') {
      throw const NaiAgentToolError(
        'invalid_query',
        'Expected history or library',
      );
    }
    final offset = _number(params, 'offset', 0, 1000000);
    final limit = _number(params, 'limit', 30, 100);
    final query = _string(params, 'query');
    final imageId = params['image_id'];
    if (imageId != null && (imageId is! String || imageId.isEmpty)) {
      throw const NaiAgentToolError('invalid_query', 'Invalid image_id');
    }
    if (scope == 'history') {
      if (params.keys.any(
        (k) => {
          'tags',
          'models',
          'favorites',
          'date_start',
          'date_end',
        }.contains(k),
      )) {
        throw const NaiAgentToolError(
          'invalid_query',
          'Library filters require scope=library',
        );
      }
      final state = ref.read(imageGenerationNotifierProvider);
      final selected = ref.read(generationPreviewSelectionProvider);
      final images = {
        ...{for (final i in state.mergedPanelImages) i.id: i},
        ...{for (final i in state.displayImages) i.id: i},
      }.values;
      final wanted = imageId == 'selected' ? selected : imageId;
      final matches = images.where((image) {
        if (imageId != null) return image.id == wanted;
        return query.isEmpty ||
            '${image.metadata?.prompt ?? ''} ${image.filePath ?? ''}'
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
      final page = matches.skip(offset).take(limit).map((image) {
        final size = NaiResolutionAdapter.readImageSize(image.bytes);
        return {
          'image_id': image.id,
          'source': 'history',
          'selected': image.id == selected,
          'file_path': image.filePath,
          'width': size?.$1,
          'height': size?.$2,
          'bytes': image.bytes.length,
          if (imageId != null) 'metadata': image.metadata?.toJson(),
        };
      }).toList();
      return naiAgentTextResult({
        'scope': scope,
        'images': page,
        'total': matches.length,
        'next_offset': offset + page.length < matches.length
            ? offset + page.length
            : null,
        'order': 'native_canvas_history',
      });
    }
    final start = _date(params, 'date_start'), end = _date(params, 'date_end');
    if (start != null && end != null && start.isAfter(end)) {
      throw const NaiAgentToolError(
        'invalid_query',
        'date_start exceeds date_end',
      );
    }
    final tags = _strings(params, 'tags'), models = _strings(params, 'models');
    final favorites = params['favorites'] ?? false;
    if (favorites is! bool) {
      throw const NaiAgentToolError('invalid_query', 'Invalid favorites');
    }
    final service = await _service(token);
    _check(token);
    final source = ref.read(naiAgentGalleryDataSourceProvider);
    List<LocalImageRecord> records;
    int total;
    int? nextOffset;
    if (imageId != null) {
      final path = await _resolveId(source, imageId as String);
      _check(token);
      records = path == null
          ? []
          : await service.getLibraryRecordsForPaths([path]);
      total = records.length;
      records = records.skip(offset).take(limit).toList();
    } else {
      final page = await service.queryRecords(
        FilterCriteria(
          searchQuery: query,
          selectedTags: tags,
          filterModels: models,
          showFavoritesOnly: favorites,
          dateStart: start,
          dateEnd: end,
        ),
        offset: offset,
        limit: limit,
      );
      records = page.records;
      total = page.totalCount;
      nextOffset = page.nextOffset;
    }
    _check(token);
    final ids = await source.getImageIdsByPaths(
      records.map((r) => r.path).toList(),
    );
    _check(token);
    final dimensions = await source.getImageDimensionsByPaths(
      records.map((r) => r.path).toList(),
    );
    _check(token);
    return naiAgentTextResult({
      'scope': scope,
      'total': total,
      'order': 'modifiedAt:descending',
      'metadata_source': 'current_local_index',
      'total_source': 'tracked_library_snapshot',
      'images': [
        for (final record in records)
          {
            'image_id': ids[record.path] == null
                ? null
                : 'gallery:${ids[record.path]}',
            'indexed': ids[record.path] != null,
            'source': 'library',
            'file_path': record.path,
            'bytes': record.size,
            'modified_at': record.modifiedAt.toIso8601String(),
            'favorite': record.isFavorite,
            'tags': record.tags,
            'width': dimensions[record.path]?.$1 ?? record.metadata?.width,
            'height': dimensions[record.path]?.$2 ?? record.metadata?.height,
            if (imageId != null) 'metadata': record.metadata?.toJson(),
          },
      ],
      'next_offset': nextOffset,
    });
  }

  Future<String?> _resolveId(GalleryDataSource source, String id) async {
    final match = RegExp(r'^gallery:([1-9]\d*)$').firstMatch(id);
    if (match == null) {
      throw const NaiAgentToolError(
        'invalid_image',
        'Use a gallery:<ID> from gallery_query(scope=library)',
      );
    }
    final number = int.tryParse(match[1]!);
    if (number == null) return null;
    final row = await source.getImageById(number);
    return row == null || row.isDeleted ? null : row.filePath;
  }

  Future<NaiAgentImage?> loadImage(
    String id,
    NaiAgentCancellation token,
  ) async {
    if (!id.startsWith('gallery:')) return null;
    final service = await _service(token);
    _check(token);
    final path = await _resolveId(
      ref.read(naiAgentGalleryDataSourceProvider),
      id,
    );
    _check(token);
    if (path == null) return null;
    final records = await service.getLibraryRecordsForPaths([path]);
    _check(token);
    if (records.isEmpty) return null;
    if (!await File(path).exists()) return null;
    final resolved = await File(path).resolveSymbolicLinks();
    final roots = await GalleryFolderRepository.instance.getAllRootDirs();
    var allowed = false;
    for (final root in roots) {
      if (p.isWithin(await root.resolveSymbolicLinks(), resolved)) {
        allowed = true;
      }
    }
    _check(token);
    if (!allowed) {
      throw const NaiAgentToolError(
        'image_outside_library',
        'Image resolves outside the configured library roots',
      );
    }
    final file = File(resolved);
    if (await file.length() > 64 * 1024 * 1024) {
      throw const NaiAgentToolError('image_too_large', 'Image exceeds 64 MiB');
    }
    final bytes = Uint8List.fromList(await file.readAsBytes());
    _check(token);
    final current = await _resolveId(
      ref.read(naiAgentGalleryDataSourceProvider),
      id,
    );
    _check(token);
    if (current != path) return null;
    return NaiAgentImage(id: id, bytes: bytes);
  }
}

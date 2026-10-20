part of 'nai_agent_gallery_binding.dart';

const _collectionActions = {
  'collections',
  'collection_members',
  'collection_create',
  'collection_update',
  'collection_delete',
  'collection_reorder',
  'collection_add',
  'collection_remove',
};

extension _GalleryCollections on NaiAgentGalleryBinding {
  String _collectionVersion(Map<String, dynamic> state) =>
      sha256.convert(utf8.encode(jsonEncode(state))).toString();

  List<Map<String, dynamic>> _rows(dynamic values) => [
    for (final value in values as List) Map<String, dynamic>.from(value as Map),
  ];

  Set<String> _descendants(List<Map<String, dynamic>> tree, String id) {
    final result = <String>{id}, queue = <String>[id];
    final entry = tree.where((row) => row['id'] == id).firstOrNull;
    if (entry?['is_folder'] != 1) return result;
    for (var i = 0; i < queue.length; i++) {
      for (final child in tree.where((row) => row['parent_id'] == queue[i])) {
        final key = child['id'] as String;
        if (result.add(key)) queue.add(key);
      }
    }
    return result;
  }

  Map<String, dynamic> _collectionSummary(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> tree,
    List<Map<String, dynamic>> members,
  ) {
    final ids = _descendants(tree, row['id'] as String);
    return {
      ...row,
      'is_folder': row['is_folder'] == 1,
      'image_count': members
          .where(
            (member) =>
                member['is_deleted'] == 0 &&
                ids.contains(member['collection_id']),
          )
          .map((member) => member['image_id'])
          .toSet()
          .length,
      'count_source': 'native_undeleted_index',
    };
  }

  void _parent(
    List<Map<String, dynamic>> tree,
    String? parent, {
    String? moving,
  }) {
    if (parent == null) return;
    final row = tree.where((row) => row['id'] == parent).firstOrNull;
    if (row?['is_folder'] != 1) {
      throw const NaiAgentToolError(
        'invalid_collection',
        'Parent must be an existing folder',
      );
    }
    final seen = <String>{};
    String? ancestor = parent;
    while (ancestor != null) {
      if (ancestor == moving || !seen.add(ancestor)) {
        throw const NaiAgentToolError(
          'collection_cycle',
          'Move would create or enter a directory cycle',
        );
      }
      ancestor =
          tree.where((row) => row['id'] == ancestor).firstOrNull?['parent_id']
              as String?;
    }
  }

  Future<List<Map<String, dynamic>>> _collectionInputs(
    GalleryDataSource source,
    List<String> ids,
    NaiAgentCancellation token,
    bool adding,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final id in ids) {
      final number = int.tryParse(id.substring('gallery:'.length));
      final row = number == null
          ? null
          : await source.readImageForManagement(number);
      _check(token);
      if (row == null || row.isDeleted) {
        throw const NaiAgentToolError(
          'image_missing',
          'Use a current, undeleted gallery image',
        );
      }
      final resolved = await _managedPath(row.filePath);
      final exists = await File(resolved).exists();
      if (adding && !exists) {
        throw const NaiAgentToolError(
          'image_missing',
          'Cannot add a missing image',
        );
      }
      result.add({
        'id': row.id,
        'file_path': row.filePath,
        'resolved_path': resolved,
        'file_missing': !exists,
        'favorite': await source.isFavorite(row.id!),
      });
    }
    _check(token);
    return result;
  }

  Future<Map<String, dynamic>> _collections(
    Map<String, dynamic> params,
    NaiAgentCancellation token, {
    Map<String, dynamic>? expectedImageVersions,
  }) async {
    final action = params['action'] as String;
    final allowed = switch (action) {
      'collections' => {'query', 'collection_id', 'offset', 'limit'},
      'collection_members' => {'collection_id', 'offset', 'limit'},
      'collection_create' => {'expected_collection_version', 'changes'},
      'collection_update' => {
        'expected_collection_version',
        'collection_id',
        'changes',
      },
      'collection_delete' => {'expected_collection_version', 'collection_id'},
      'collection_reorder' => {
        'expected_collection_version',
        'parent_id',
        'ordered_collection_ids',
      },
      _ => {'expected_collection_version', 'collection_id', 'image_ids'},
    }..addAll({'action', 'scope'});
    if (params.keys.any((key) => !allowed.contains(key)) ||
        (params['scope'] ?? 'library') != 'library') {
      throw const NaiAgentToolError(
        'invalid_collection',
        'Unsupported collection field or scope',
      );
    }
    final id = params['collection_id'];
    if (id != null && (id is! String || id.isEmpty || id.length > 200)) {
      throw const NaiAgentToolError(
        'invalid_collection',
        'Invalid collection_id',
      );
    }
    final service = await _service(token);
    final source = ref.read(naiAgentGalleryDataSourceProvider);
    final state = await source.readCollectionManagementState();
    _check(token);
    final tree = _rows(state['collections']), members = _rows(state['members']);
    final version = _collectionVersion(state);
    final entry = tree.where((row) => row['id'] == id).firstOrNull;
    if (id != null && entry == null) {
      throw const NaiAgentToolError(
        'collection_missing',
        'Collection not found',
      );
    }
    if (action == 'collections') {
      final query = _string(params, 'query').toLowerCase();
      final offset = _number(params, 'offset', 0, 1000000),
          limit = _number(params, 'limit', 30, 100);
      final rows =
          tree
              .where(
                (row) =>
                    (id == null || row['id'] == id) &&
                    (row['name'] as String).toLowerCase().contains(query),
              )
              .toList()
            ..sort((a, b) {
              final parent = '${a['parent_id'] ?? ''}'.compareTo(
                '${b['parent_id'] ?? ''}',
              );
              if (parent != 0) return parent;
              final order = (a['sort_order'] as int).compareTo(
                b['sort_order'] as int,
              );
              return order == 0 ? '${a['id']}'.compareTo('${b['id']}') : order;
            });
      final page = rows.skip(offset).take(limit).toList();
      return naiAgentTextResult({
        'collections': [
          for (final row in page) _collectionSummary(row, tree, members),
        ],
        'total': rows.length,
        'next_offset': offset + page.length < rows.length
            ? offset + page.length
            : null,
        'collection_version': version,
        'folders': 'logical_native_favorite_folders',
      });
    }
    if (action == 'collection_members') {
      if (entry == null) {
        throw const NaiAgentToolError(
          'invalid_collection',
          'Provide a collection_id',
        );
      }
      final selected = _descendants(tree, id as String);
      final matches =
          members
              .where(
                (row) =>
                    row['is_deleted'] == 0 &&
                    selected.contains(row['collection_id']),
              )
              .toList()
            ..sort(
              (a, b) => (a['added_at'] as int).compareTo(b['added_at'] as int),
            );
      final unique = <int, Map<String, dynamic>>{};
      for (final row in matches) {
        unique.putIfAbsent(row['image_id'] as int, () => row);
      }
      final offset = _number(params, 'offset', 0, 1000000),
          limit = _number(params, 'limit', 30, 100);
      final page = unique.values.skip(offset).take(limit).toList(),
          images = <Map<String, dynamic>>[];
      for (final row in page) {
        try {
          final path = await _managedPath(row['file_path'] as String);
          images.add({
            'image_id': 'gallery:${row['image_id']}',
            'file_path': row['file_path'],
            'file_missing': !await File(path).exists(),
            'favorite': row['favorite'] == 1,
          });
        } on NaiAgentToolError catch (error) {
          if (error.code != 'image_outside_library') rethrow;
        } on FileSystemException {
          // Missing/unresolvable parents are not treated as safe library roots.
        }
        _check(token);
      }
      return naiAgentTextResult({
        'images': images,
        'collection_version': version,
        'total': unique.length,
        'total_source': 'native_undeleted_index',
        'next_offset': offset + page.length < unique.length
            ? offset + page.length
            : null,
        'order': 'native_membership_added_at',
        'collection_id': id,
      });
    }
    _admit(token);
    if (params['expected_collection_version'] != version) {
      throw const NaiAgentToolError(
        'collection_conflict',
        'Read collections and acknowledge the current version',
      );
    }
    final changes = params['changes'];
    if (action == 'collection_create' || action == 'collection_update') {
      final keys = action == 'collection_create'
          ? {'name', 'parent_id', 'is_folder'}
          : {'name', 'parent_id'};
      if (changes is! Map ||
          changes.isEmpty ||
          changes.keys.any((key) => !keys.contains(key)) ||
          (action == 'collection_create' && !changes.containsKey('name')) ||
          (changes.containsKey('name') &&
              (changes['name'] is! String ||
                  (changes['name'] as String).trim().isEmpty ||
                  (changes['name'] as String).length > 160)) ||
          (changes.containsKey('parent_id') &&
              changes['parent_id'] != null &&
              changes['parent_id'] is! String) ||
          (changes.containsKey('is_folder') && changes['is_folder'] is! bool)) {
        throw const NaiAgentToolError(
          'invalid_collection',
          'Invalid collection changes',
        );
      }
      if (action == 'collection_update' && entry == null) {
        throw const NaiAgentToolError(
          'invalid_collection',
          'Provide a collection_id',
        );
      }
      if (changes.containsKey('parent_id')) {
        _parent(tree, changes['parent_id'] as String?, moving: id as String?);
      }
    }
    if (action == 'collection_delete' &&
        (entry == null || tree.any((row) => row['parent_id'] == id))) {
      throw const NaiAgentToolError(
        'collection_not_empty',
        'Provide an existing collection or an empty folder',
      );
    }
    final ordered = params['ordered_collection_ids'];
    if (action == 'collection_reorder') {
      final parent = params['parent_id'];
      if (parent != null && parent is! String) {
        throw const NaiAgentToolError(
          'invalid_collection',
          'Invalid parent_id',
        );
      }
      _parent(tree, parent as String?);
      final siblings = tree
          .where((row) => row['parent_id'] == parent)
          .map((row) => row['id'])
          .toSet();
      if (ordered is! List ||
          ordered.isEmpty ||
          ordered.length > 1000 ||
          ordered.any((id) => id is! String) ||
          ordered.toSet().length != ordered.length ||
          ordered.length != siblings.length ||
          !siblings.containsAll(ordered)) {
        throw const NaiAgentToolError(
          'invalid_collection',
          'Reorder requires each sibling exactly once',
        );
      }
    }
    final imageIds = params['image_ids'];
    var inputs = <Map<String, dynamic>>[];
    if (action == 'collection_add' || action == 'collection_remove') {
      if (entry == null ||
          entry['is_folder'] == 1 ||
          imageIds is! List ||
          imageIds.isEmpty ||
          imageIds.length > 20 ||
          imageIds.any(
            (id) =>
                id is! String || !RegExp(r'^gallery:([1-9]\d*)$').hasMatch(id),
          ) ||
          imageIds.toSet().length != imageIds.length) {
        throw const NaiAgentToolError(
          'invalid_collection',
          'Use a leaf collection and 1..20 distinct gallery IDs',
        );
      }
      inputs = await _collectionInputs(
        source,
        imageIds.cast<String>(),
        token,
        action == 'collection_add',
      );
    }
    final beforeImages = <String, Map<String, dynamic>>{};
    for (final input in inputs) {
      final imageId = 'gallery:${input['id']}';
      beforeImages[imageId] = (await _managed(
        'library',
        imageId,
        token,
      )).summary;
    }
    final store = files;
    if (store == null) {
      throw const NaiAgentToolError('workspace_unavailable', 'No workspace');
    }
    final backup = await store.export(
      'gallery-collections.json',
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            ...state,
            'collection_version': version,
            'input_images': inputs,
          }),
        ),
      ),
      () => _check(token),
    );
    final fresh = await source.readCollectionManagementState();
    if (_collectionVersion(fresh) != version) {
      throw const NaiAgentToolError(
        'collection_conflict',
        'Collections changed during backup',
      );
    }
    if (inputs.isNotEmpty &&
        jsonEncode(inputs) !=
            jsonEncode(
              await _collectionInputs(
                source,
                (imageIds as List).cast<String>(),
                token,
                action == 'collection_add',
              ),
            )) {
      throw const NaiAgentToolError(
        'image_conflict',
        'Target images changed during backup',
      );
    }
    // UI undo supplies the versions captured by the original write. Recheck
    // after this operation's asynchronous backup, not only at button press.
    if (expectedImageVersions != null) {
      for (final expected in expectedImageVersions.entries) {
        if ((await _managed('library', expected.key, token)).version !=
            expected.value) {
          throw const NaiAgentToolError(
            'image_conflict',
            'Image changed during undo backup',
          );
        }
      }
    }
    _admit(token);
    final applied = <String>[];
    String? resultId = id as String?;
    try {
      switch (action) {
        case 'collection_create':
          resultId = await source.createCollection(
            (changes as Map)['name'] as String,
            parentId: changes['parent_id'] as String?,
            isFolder: changes['is_folder'] == true,
          );
          applied.add('created');
        case 'collection_update':
          if ((changes as Map).containsKey('name')) {
            if (!await source.renameCollection(
              resultId!,
              changes['name'] as String,
            )) {
              throw StateError('rename failed');
            }
            applied.add('name');
          }
          if (changes.containsKey('parent_id')) {
            if (!await source.moveCollection(
              resultId!,
              changes['parent_id'] as String?,
            )) {
              throw StateError('move failed');
            }
            applied.add('parent_id');
          }
        case 'collection_delete':
          if (!await source.deleteCollection(resultId!)) {
            throw StateError('delete failed');
          }
          applied.add('deleted');
        case 'collection_reorder':
          if (!await source.reorderCollections(
            (ordered as List).cast<String>(),
            parentId: params['parent_id'] as String?,
          )) {
            throw StateError('reorder failed');
          }
          applied.add('ordered');
        case 'collection_add':
        case 'collection_remove':
          for (final input in inputs) {
            final number = input['id'] as int;
            if (action == 'collection_add') {
              await source.addFavorite(number);
              applied.add('favorite:gallery:$number');
              await source.addImageToCollection(resultId!, number);
            } else {
              await source.removeImageFromCollection(resultId!, number);
            }
            applied.add('membership:gallery:$number');
          }
      }
      if (isAlive() && action == 'collection_delete') {
        if (ref.exists(collectionNotifierProvider) &&
            ref.read(collectionNotifierProvider).activeCollectionId == id) {
          ref
              .read(collectionNotifierProvider.notifier)
              .setActiveCollection(null);
        }
        if (ref.exists(localGalleryNotifierProvider) &&
            ref
                    .read(localGalleryNotifierProvider)
                    .filterCriteria
                    .collectionId ==
                id) {
          await ref
              .read(localGalleryNotifierProvider.notifier)
              .setSelectedCollection(null);
        }
      }
      await _refreshManagedLibrary(service);
      return naiAgentTextResult({
        'ok': true,
        'collection_id': resultId,
        'collection_name': entry?['name'],
        'image_ids': beforeImages.keys.toList(),
        'before': beforeImages,
        'image_versions': {
          for (final imageId in beforeImages.keys)
            imageId: (await _managed(
              'library',
              imageId,
              NaiAgentCancellation(),
            )).version,
        },
        'applied_fields': applied,
        'backup': backup,
        'files_changed': false,
        'collection_version': _collectionVersion(
          await source.readCollectionManagementState(),
        ),
        'adding_sets_favorite': action == 'collection_add',
        'removing_keeps_favorite': action == 'collection_remove',
      });
    } catch (error) {
      if (applied.isNotEmpty) {
        try {
          await _refreshManagedLibrary(service);
        } catch (_) {
          // Preserve the original partial-commit result if refresh also fails.
        }
      }
      return naiAgentTextResult({
        'ok': false,
        'collection_id': resultId,
        'applied_fields': applied,
        'backup': backup,
        'files_changed': false,
        'error': 'native_collection_failed',
        'message': 'Read current collections before retrying partial changes.',
      });
    }
  }
}

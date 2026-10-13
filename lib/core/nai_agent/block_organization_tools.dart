import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/repositories/prompt_block_repository.dart';
import 'agent_tool.dart';
import 'block_tools.dart';

String naiAgentBlockLibraryVersion(PromptBlockLibraryData data) {
  final blocks = [...data.blocks]..sort((a, b) => a.id.compareTo(b.id));
  final folders = [...data.folders]..sort((a, b) => a.id.compareTo(b.id));
  final collections = [...data.collections]
    ..sort((a, b) => a.id.compareTo(b.id));
  return sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'blocks': blocks.map(naiAgentBlockVersion).toList(),
            'folders': folders
                .map((v) => v.toJson()..remove('updatedAt'))
                .toList(),
            'collections': collections
                .map((v) => v.toJson()..remove('updatedAt'))
                .toList(),
          }),
        ),
      )
      .toString();
}

const naiAgentBlockOrganizationActions = {
  'folder_create',
  'folder_update',
  'folder_move',
  'folder_delete',
  'folder_reorder',
  'block_reorder',
  'collection_create',
  'collection_update',
  'collection_move',
  'collection_delete',
  'collection_reorder',
  'collection_add',
  'collection_remove',
};

extension NaiAgentBlockOrganization on NaiAgentBlockTools {
  Future<Map<String, dynamic>> manageOrganization(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    void check() {
      token.check();
      if (!isAlive()) {
        throw const NaiAgentToolError('closed', 'Block binding closed');
      }
      if (isBusy()) {
        throw const NaiAgentToolError('busy', 'Studio is generating');
      }
    }

    check();
    final before = await readLibrary();
    final version = naiAgentBlockLibraryVersion(before);
    if (params['expected_library_version'] != version) {
      throw const NaiAgentToolError(
        'library_conflict',
        'Read block_query(kind=tree) again',
      );
    }
    final action = params['action'] as String;
    final id = params['id'];
    final creating = action.endsWith('_create');
    final ordering = action.endsWith('_reorder');
    final folder = id is String ? before.getFolder(id) : null;
    final collection = id is String ? before.getCollection(id) : null;
    if (!creating &&
        !ordering &&
        (action.startsWith('folder_') ? folder == null : collection == null)) {
      throw const NaiAgentToolError(
        'entry_missing',
        'Read the block library tree again',
      );
    }
    final rawChanges = params['changes'] ?? <String, dynamic>{};
    if (rawChanges is! Map ||
        rawChanges.keys.any(
          (key) => !{
            'name',
            'parentId',
            'sortOrder',
            if (action == 'collection_create') 'isFolder',
          }.contains(key),
        )) {
      throw const NaiAgentToolError(
        'invalid_organization',
        'Use name, parentId and sortOrder',
      );
    }
    final changes = Map<String, dynamic>.from(rawChanges);
    final name = changes['name'];
    if ((creating || changes.containsKey('name')) &&
        (name is! String || name.trim().isEmpty || name.length > 200)) {
      throw const NaiAgentToolError(
        'invalid_organization',
        'Name must contain 1 to 200 characters',
      );
    }
    if ((changes.containsKey('parentId') &&
            changes['parentId'] != null &&
            changes['parentId'] is! String) ||
        (changes.containsKey('sortOrder') && changes['sortOrder'] is! int) ||
        (changes.containsKey('isFolder') && changes['isFolder'] is! bool)) {
      throw const NaiAgentToolError(
        'invalid_organization',
        'Invalid organization fields',
      );
    }
    if (action.endsWith('_move')) {
      if (!params.containsKey('parent_id') ||
          (params['parent_id'] != null && params['parent_id'] is! String)) {
        throw const NaiAgentToolError(
          'invalid_organization',
          'Provide parent_id (null means root)',
        );
      }
      changes['parentId'] = params['parent_id'];
    }
    final parent = params['parent_id'];
    final order = params['ordered_ids'];
    if (ordering &&
        ((parent != null && parent is! String) ||
            order is! List ||
            order.any((v) => v is! String))) {
      throw const NaiAgentToolError(
        'invalid_organization',
        'Provide complete ordered_ids for parent_id',
      );
    }
    final blockId = params['block_id'];
    if ((action == 'collection_add' || action == 'collection_remove') &&
        (collection!.isFolder ||
            blockId is! String ||
            before.getBlock(blockId) == null)) {
      throw const NaiAgentToolError(
        'invalid_organization',
        'Use an existing block and a collection',
      );
    }
    final path = await backup(before, readDraft(), null);
    void guard() {
      check();
      if (naiAgentBlockLibraryVersion(repository.currentLibrary) != version) {
        throw const NaiAgentToolError(
          'library_conflict',
          'Block library changed during backup',
        );
      }
    }

    String? resultId = id as String?;
    try {
      switch (action) {
        case 'folder_create':
          resultId = (await repository.createFolder(
            name: name as String,
            parentId: changes['parentId'] as String?,
            sortOrder: changes['sortOrder'] as int?,
            beforeWrite: guard,
          )).id;
        case 'folder_update':
        case 'folder_move':
          await repository.updateFolder(
            folder!.copyWith(
              name: name as String? ?? folder.name,
              parentId: changes.containsKey('parentId')
                  ? changes['parentId'] as String?
                  : folder.parentId,
              sortOrder: changes['sortOrder'] as int? ?? folder.sortOrder,
            ),
            beforeWrite: guard,
          );
        case 'folder_delete':
          await repository.deleteEmptyFolder(id as String, beforeWrite: guard);
        case 'folder_reorder':
          await repository.reorderFolders(
            parent as String?,
            List<String>.from(order as List),
            beforeWrite: guard,
          );
        case 'block_reorder':
          await repository.reorderBlocks(
            parent as String?,
            List<String>.from(order as List),
            beforeWrite: guard,
          );
        case 'collection_create':
          resultId = (await repository.createCollection(
            name: name as String,
            parentId: changes['parentId'] as String?,
            sortOrder: changes['sortOrder'] as int?,
            isFolder: changes['isFolder'] as bool? ?? false,
            beforeWrite: guard,
          )).id;
        case 'collection_update':
        case 'collection_move':
          await repository.updateCollection(
            collection!.copyWith(
              name: name as String? ?? collection.name,
              parentId: changes.containsKey('parentId')
                  ? changes['parentId'] as String?
                  : collection.parentId,
              sortOrder: changes['sortOrder'] as int? ?? collection.sortOrder,
            ),
            beforeWrite: guard,
          );
        case 'collection_delete':
          await repository.deleteCollection(id as String, beforeWrite: guard);
        case 'collection_reorder':
          await repository.reorderCollections(
            parent as String?,
            List<String>.from(order as List),
            beforeWrite: guard,
          );
        case 'collection_add':
        case 'collection_remove':
          await repository.setCollectionMembership(
            id as String,
            blockId as String,
            action == 'collection_add',
            beforeWrite: guard,
          );
      }
    } on ArgumentError catch (error) {
      throw NaiAgentToolError('invalid_organization', error.toString());
    } on StateError catch (error) {
      throw NaiAgentToolError('invalid_organization', error.message);
    } finally {
      if (isAlive()) await refresh();
    }
    final after = await readLibrary();
    return naiAgentTextResult({
      'action': action,
      'id': resultId,
      'backup_path': path,
      'library_version': naiAgentBlockLibraryVersion(after),
      'folders': after.folders.map((v) => v.toJson()).toList(),
      'collections': after.collections.map((v) => v.toJson()).toList(),
    });
  }
}

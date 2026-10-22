part of 'nai_agent_gallery_binding.dart';

const _fileActions = {
  'folders',
  'folder_create',
  'folder_rename',
  'folder_move',
  'folder_delete_empty',
  'folder_sync',
  'move_file',
  'copy_file',
};

// Preflight deliberately retains no pixels or metadata snapshots for the batch.
class _GalleryTransferInput {
  _GalleryTransferInput(_ManagedGalleryImage image)
    : id = image.id,
      version = image.version,
      path = image.data['resolved_path'] as String,
      hash = image.data['sha256'] as String,
      nativeId = (image.data['record'] as Map)['id'] as int;
  final String id, version, path, hash;
  final int nativeId;
}

List<String> _galleryBatchIds(dynamic value) {
  if (value is! List ||
      value.isEmpty ||
      value.length > 50 ||
      value.any((id) => id is! String || id.isEmpty || id.length > 200) ||
      value.toSet().length != value.length) {
    throw const NaiAgentToolError('invalid_gallery', 'Use 1..50 unique IDs');
  }
  return value.cast<String>();
}

extension _GalleryFiles on NaiAgentGalleryBinding {
  String _listedGalleryItems(List<String> items) => [
    ...items.take(5),
    if (items.length > 5)
      currentL10n.naiAgent_galleryMoreItems(items.length - 5),
  ].join('\n');

  String _transferWarning({
    required bool copy,
    required bool sourceExternal,
    required bool targetExternal,
    required int count,
    required String target,
  }) {
    final l10n = currentL10n;
    return copy
        ? l10n.localGallery_confirmCopyContent
        : sourceExternal && targetExternal
        ? l10n.localGallery_externalBothMoveConfirmContent(
            count,
            p.basename(target),
          )
        : sourceExternal
        ? l10n.localGallery_externalSourceMoveConfirmContent(count)
        : targetExternal
        ? l10n.localGallery_externalTargetMoveConfirmContent(
            count,
            p.basename(target),
          )
        : count == 1
        ? l10n.localGallery_confirmMoveImageContent
        : l10n.localGallery_protectedBulkMoveContent(count);
  }

  Future<String> _folderPath(String path) async {
    if (!p.isAbsolute(path) || !await Directory(path).exists()) {
      throw const NaiAgentToolError(
        'folder_missing',
        'Use an existing absolute folder path',
      );
    }
    return _managedPath(await Directory(path).resolveSymbolicLinks());
  }

  Future<bool> _externalFilePath(String path) async {
    for (final root
        in await GalleryFolderRepository.instance.getExtraRootPaths()) {
      if (await Directory(root).exists() &&
          galleryPathIsWithin(
            await Directory(root).resolveSymbolicLinks(),
            path,
          )) {
        return true;
      }
    }
    return false;
  }

  Future<void> _confirmFileChange(
    String text,
    NaiAgentCancellation token,
  ) async {
    final identity = owner;
    if (identity == null) {
      throw const NaiAgentToolError(
        'confirmation_unavailable',
        'No active conversation owner',
      );
    }
    final l10n = currentL10n;
    final result = await ref.read(naiAgentQuestionsProvider).ask(
      identity.workspaceId,
      identity.chatId,
      {
        'questions': [
          {
            'id': 'gallery_change',
            'question': text,
            'options': [l10n.common_cancel, l10n.common_confirm],
          },
        ],
      },
      token,
    );
    final details = result['details'] as Map;
    final answers = details['answers'] as List;
    if (details['status'] != 'answered' ||
        answers.length != 1 ||
        (answers.single as Map)['answer'] != l10n.common_confirm) {
      throw const NaiAgentToolError(
        'declined',
        'Gallery change was not confirmed',
      );
    }
  }

  Future<void> _refreshFileLibrary(
    LocalGalleryService service, {
    bool scan = false,
    Map<String, String> categoryPaths = const {},
    Set<String> removed = const {},
  }) async {
    if (!isAlive()) return;
    if (ref.exists(localGalleryNotifierProvider)) {
      ref
          .read(localGalleryNotifierProvider.notifier)
          .rebindCategoryFolderPaths(categoryPaths, removed: removed);
      await ref.read(localGalleryNotifierProvider.notifier).refresh(scan: scan);
    } else {
      final filter = service.currentFilter;
      final id = filter.categoryId;
      if (removed.contains(id)) {
        await service.applyFilter(
          filter.copyWith(clearCategoryId: true, clearCategoryFolderPath: true),
        );
      } else if (categoryPaths.containsKey(id)) {
        await service.applyFilter(
          filter.copyWith(categoryFolderPath: categoryPaths[id]),
        );
      }
      await service.refresh(scan: scan);
    }
    if (isAlive() && ref.exists(galleryCategoryNotifierProvider)) {
      await ref.read(galleryCategoryNotifierProvider.notifier).refresh();
      if (isAlive() &&
          removed.contains(
            ref.read(galleryCategoryNotifierProvider).selectedCategoryId,
          )) {
        ref.read(galleryCategoryNotifierProvider.notifier).selectCategory(null);
      }
    }
    if (isAlive() && ref.exists(collectionNotifierProvider)) {
      await ref.read(collectionNotifierProvider.notifier).refresh();
    }
  }

  Future<Map<String, dynamic>> _manageFiles(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    if (params['action'] == 'move_file' || params['action'] == 'copy_file') {
      return _transferFile(params, token);
    }
    return _manageFolders(params, token);
  }

  Future<Map<String, dynamic>> _transferFile(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    if (params.containsKey('image_ids') ||
        params.containsKey('expected_image_versions')) {
      return _transferFiles(params, token);
    }
    const allowed = {
      'action',
      'scope',
      'image_id',
      'expected_image_version',
      'target_folder',
    };
    if (params.keys.any((key) => !allowed.contains(key)) ||
        (params['scope'] ?? 'library') != 'library' ||
        params['image_id'] is! String ||
        params['target_folder'] is! String) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'File transfer requires a library image and target_folder',
      );
    }
    final copy = params['action'] == 'copy_file';
    final image = await _managed(
      'library',
      params['image_id'] as String,
      token,
    );
    _admit(token);
    if (params['expected_image_version'] != image.version) {
      throw const NaiAgentToolError(
        'image_conflict',
        'Read the current image version',
      );
    }
    if (image.bytes == null || image.data['deleted'] == true) {
      throw const NaiAgentToolError(
        'image_missing',
        'Transfer requires an active original file',
      );
    }
    final target = await _folderPath(params['target_folder'] as String);
    final sourcePath = image.data['resolved_path'] as String;
    if (!copy && galleryFilePathsEqual(p.dirname(sourcePath), target)) {
      return naiAgentTextResult({
        'ok': true,
        'unchanged': true,
        'file_path': sourcePath,
        'image_id': image.id,
      });
    }
    final sourceExternal = await _externalFilePath(sourcePath);
    final targetExternal = await _externalFilePath(target);
    final protected = ref
        .read(shareImageSettingsProvider)
        .effectiveConfirmDangerousActions;
    if ((!copy && (sourceExternal || targetExternal)) || protected) {
      final warning = _transferWarning(
        copy: copy,
        sourceExternal: sourceExternal,
        targetExternal: targetExternal,
        count: 1,
        target: target,
      );
      await _confirmFileChange(
        '$warning\n${p.basename(sourcePath)} → ${p.basename(target)}\n$target',
        token,
      );
    }
    final backup = await _imageBackup(image, token);
    Future<void> checkFresh() async {
      _admit(token);
      if ((await _managed('library', image.id, token)).version !=
              image.version ||
          !galleryFilePathsEqual(
            await _folderPath(params['target_folder'] as String),
            target,
          )) {
        throw const NaiAgentToolError(
          'image_conflict',
          'Source or target changed during confirmation/backup',
        );
      }
      _admit(token);
    }

    await checkFresh();
    String? destination;
    final applied = <String>[];
    final data = ref.read(naiAgentGalleryDataSourceProvider);
    final id = (image.data['record'] as Map)['id'] as int;
    try {
      destination = await GalleryFolderRepository.instance.transferImageToFolder(
        sourcePath,
        target,
        copy: copy,
        updateIndex: false,
        beforeTransfer: checkFresh,
        afterTransfer: (actual) async {
          destination = actual;
          applied.add(copy ? 'file_copied' : 'file_moved');
          if (!copy) {
            // Finish durable bookkeeping after admission even if Stop arrives.
            await data.updateFilePath(
              id,
              actual,
              newFileName: p.basename(actual),
            );
            final row = await data.readImageForManagement(id);
            if (row == null || !galleryFilePathsEqual(row.filePath, actual)) {
              throw const NaiAgentToolError(
                'index_update_failed',
                'Moved path was not persisted',
              );
            }
            applied.add('index_updated');
          }
        },
        validator: (sourceFile, destinationFile) async {
          await checkFresh();
          return sha256
                      .convert(
                        await AgentWorkspaceFiles.readBounded(sourceFile),
                      )
                      .toString() ==
                  image.data['sha256'] &&
              sha256
                      .convert(
                        await AgentWorkspaceFiles.readBounded(destinationFile),
                      )
                      .toString() ==
                  image.data['sha256'];
        },
      );
      if (destination == null) {
        _check(token);
        throw const NaiAgentToolError(
          'transfer_failed',
          'Native file transfer failed',
        );
      }
      await _refreshFileLibrary(
        await _service(NaiAgentCancellation()),
        scan: copy,
      );
      final targetId = copy
          ? (await data.getImageIdsByPaths([destination!]))[destination]
          : id;
      return naiAgentTextResult({
        'ok': true,
        'image_id': targetId == null ? null : 'gallery:$targetId',
        'source_image_id': image.id,
        'source_path': sourcePath,
        'file_path': destination,
        'image_version': copy
            ? null
            : (await _managed(
                'library',
                image.id,
                NaiAgentCancellation(),
              )).version,
        'source_retained': copy,
        'indexing': targetId == null,
        'backup': backup,
        'applied_fields': applied,
        'copy_preserves_custom_index_tags_and_favorite': false,
      });
    } catch (error) {
      if (destination == null && error is NaiAgentToolError) rethrow;
      return naiAgentTextResult({
        'ok': false,
        'source_image_id': image.id,
        'file_path': destination,
        'backup': backup,
        'applied_fields': applied,
        'error': error is NaiAgentToolError
            ? error.code
            : 'native_gallery_failed',
        'message':
            'Read the actual source and destination before retrying; native changes may be applied.',
      });
    }
  }

  Future<Map<String, dynamic>> _transferFiles(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    const allowed = {
      'action',
      'scope',
      'image_ids',
      'expected_image_versions',
      'target_folder',
    };
    if (params.keys.any((key) => !allowed.contains(key)) ||
        (params['scope'] ?? 'library') != 'library' ||
        params['target_folder'] is! String) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'Invalid batch transfer fields',
      );
    }
    final ids = _galleryBatchIds(params['image_ids']);
    final versions = params['expected_image_versions'];
    if (versions is! Map ||
        versions.length != ids.length ||
        ids.any((id) => versions[id] is! String)) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'Provide a version from read for every image ID',
      );
    }
    final copy = params['action'] == 'copy_file';
    final target = await _folderPath(params['target_folder'] as String);
    final inputs = <_GalleryTransferInput>[];
    final unchanged = <String>[];
    var sourceExternal = false;
    for (final id in ids) {
      final image = await _managed('library', id, token);
      _admit(token);
      if (image.version != versions[id]) {
        throw NaiAgentToolError(
          'image_conflict',
          'Read the current image version: $id',
        );
      }
      if (image.bytes == null || image.data['deleted'] == true) {
        throw NaiAgentToolError(
          'image_missing',
          'Transfer requires an active original: $id',
        );
      }
      final input = _GalleryTransferInput(image);
      if (!copy && galleryFilePathsEqual(p.dirname(input.path), target)) {
        unchanged.add(id);
      } else {
        inputs.add(input);
        sourceExternal = await _externalFilePath(input.path) || sourceExternal;
      }
    }
    final targetExternal = await _externalFilePath(target);
    if (inputs.isNotEmpty &&
        ((!copy && (sourceExternal || targetExternal)) ||
            ref
                .read(shareImageSettingsProvider)
                .effectiveConfirmDangerousActions)) {
      final warning = _transferWarning(
        copy: copy,
        sourceExternal: sourceExternal,
        targetExternal: targetExternal,
        count: inputs.length,
        target: target,
      );
      final listing = _listedGalleryItems([
        for (final input in inputs)
          '${p.basename(input.path)} → ${p.basename(target)}',
      ]);
      await _confirmFileChange('$warning\n$listing\n$target', token);
    }

    final data = ref.read(naiAgentGalleryDataSourceProvider);
    final backups = <Map<String, dynamic>>[];
    final destinations = <String, String>{};
    final applied = <String>{};
    final imageVersions = <String, String>{};
    Object? failure;
    String? failedId;
    var next = 0;
    for (; next < inputs.length; next++) {
      final input = inputs[next];
      try {
        // Re-read just this item. Never retain all original bytes in memory.
        final backup = await _imageBackup(
          await _managed('library', input.id, token),
          token,
        );
        backups.add({'image_id': input.id, 'path': backup['path']});
        Future<void> checkFresh() async {
          _admit(token);
          if ((await _managed('library', input.id, token)).version !=
                  input.version ||
              !galleryFilePathsEqual(
                await _folderPath(params['target_folder'] as String),
                target,
              )) {
            throw const NaiAgentToolError(
              'image_conflict',
              'Source or target changed during confirmation/backup',
            );
          }
          _admit(token);
        }

        await checkFresh();
        final destination = await GalleryFolderRepository.instance
            .transferImageToFolder(
              input.path,
              target,
              copy: copy,
              updateIndex: false,
              beforeTransfer: checkFresh,
              afterTransfer: (actual) async {
                // Record physical application before any fallible index bookkeeping.
                destinations[input.id] = actual;
                applied.add(copy ? 'file_copied' : 'file_moved');
                if (!copy) {
                  await data.updateFilePath(
                    input.nativeId,
                    actual,
                    newFileName: p.basename(actual),
                  );
                  final row = await data.readImageForManagement(input.nativeId);
                  if (row == null ||
                      !galleryFilePathsEqual(row.filePath, actual)) {
                    throw const NaiAgentToolError(
                      'index_update_failed',
                      'Moved path was not persisted',
                    );
                  }
                  applied.add('index_updated');
                }
              },
              validator: (sourceFile, destinationFile) async {
                await checkFresh();
                return sha256
                            .convert(
                              await AgentWorkspaceFiles.readBounded(sourceFile),
                            )
                            .toString() ==
                        input.hash &&
                    sha256
                            .convert(
                              await AgentWorkspaceFiles.readBounded(
                                destinationFile,
                              ),
                            )
                            .toString() ==
                        input.hash;
              },
            );
        if (destination == null) {
          _admit(token);
          throw const NaiAgentToolError(
            'transfer_failed',
            'Native file transfer failed',
          );
        }
        if (!copy) {
          imageVersions[input.id] = (await _managed(
            'library',
            input.id,
            NaiAgentCancellation(),
          )).version;
        }
      } catch (error) {
        if (destinations.isEmpty) rethrow;
        failure = error;
        failedId = input.id;
        break;
      }
    }
    if (destinations.isNotEmpty) {
      try {
        await _refreshFileLibrary(
          await _service(NaiAgentCancellation()),
          scan: copy,
        );
      } catch (error) {
        failure ??= error;
        failedId ??= destinations.keys.last;
      }
    }
    var copiedIds = <String, int?>{};
    if (copy && destinations.isNotEmpty) {
      try {
        copiedIds = await data.getImageIdsByPaths(destinations.values.toList());
      } catch (error) {
        failure ??= error;
        failedId ??= destinations.keys.last;
      }
    }
    final done = inputs
        .where((input) => destinations.containsKey(input.id))
        .toList();
    final completed = <String, dynamic>{
      'action': params['action'],
      'scope': 'library',
      'target_folder': target,
      'count': done.length,
      'image_ids': [
        for (final input in done)
          if (!copy)
            input.id
          else if (copiedIds[destinations[input.id]] != null)
            'gallery:${copiedIds[destinations[input.id]]}',
      ],
      'source_image_ids': [for (final input in done) input.id],
      'source_paths': {for (final input in done) input.id: input.path},
      'file_paths': destinations,
      if (!copy) 'image_versions': imageVersions,
      'unchanged_ids': unchanged,
      'indexing_ids': [
        if (copy)
          for (final input in done)
            if (copiedIds[destinations[input.id]] == null) input.id,
      ],
      'backups': backups
          .where((backup) => destinations.containsKey(backup['image_id']))
          .toList(),
      'applied_fields': applied.toList(),
    };
    return naiAgentTextResult(
      failure == null
          ? {'ok': true, ...completed, if (inputs.isEmpty) 'unchanged': true}
          : {
              'ok': false,
              'error': failure is NaiAgentToolError
                  ? failure.code
                  : 'native_gallery_failed',
              'message':
                  'Read the actual sources and destinations before retrying; native changes may be applied.',
              'completed': completed,
              'failed_image_id': failedId,
              'remaining_image_ids': inputs
                  .skip(next + 1)
                  .map((input) => input.id)
                  .toList(),
              'backups': backups,
            },
    );
  }

  Future<(List<GalleryCategory>, String, String)> _folderCatalog(
    NaiAgentCancellation token,
  ) async {
    final repo = categoryRepository;
    final path = await repo.getRootPath();
    if (path == null) {
      throw const NaiAgentToolError('gallery_unavailable', 'No gallery root');
    }
    final root = await _folderPath(path);
    var categories = await repo.loadCategories();
    if (categories.isEmpty && !await repo.hasCategoriesConfigFile()) {
      // Same first-use initialization as the native category sidebar.
      categories = await repo.syncWithFileSystem(categories);
      _check(token);
      if (!await repo.saveCategories(categories)) {
        throw const NaiAgentToolError(
          'folder_catalog_failed',
          'Initial native catalog could not be saved',
        );
      }
    } else if (categories.isEmpty &&
        !await repo.isCategoriesConfigGenuinelyEmpty()) {
      throw const NaiAgentToolError(
        'folder_catalog_failed',
        'Native catalog is invalid; do not replace it',
      );
    }
    _check(token);
    final roots = (await GalleryFolderRepository.instance.getAllRootDirs())
        .map((dir) => dir.path)
        .toList();
    final version = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'root': root,
              'roots': roots,
              'categories': categories.map((c) => c.toJson()).toList(),
            }),
          ),
        )
        .toString();
    return (categories, root, version);
  }

  Future<String> _categoryPath(GalleryCategory? category, String root) async =>
      _folderPath(
        category == null
            ? root
            : category.isExternal
            ? category.folderPath
            : p.join(root, category.folderPath),
      );

  Future<List<String>> _directoryEntries(String path) async {
    final result = <String>[];
    await for (final item in Directory(path).list(followLinks: false)) {
      final stat = await item.stat();
      result.add(
        '${p.basename(item.path)}:${stat.type}:${stat.size}:${stat.modified.microsecondsSinceEpoch}',
      );
      if (result.length > 100000) {
        throw const NaiAgentToolError(
          'folder_too_large',
          'Use smaller folders for explicit management',
        );
      }
    }
    return result..sort();
  }

  Future<Map<String, dynamic>> _deleteEmptyFolders(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
    List<GalleryCategory> categories,
    String root,
    String version,
    LocalGalleryService service,
  ) async {
    final ids = _galleryBatchIds(params['folder_ids']);
    final selected = ids.toSet();
    final roots = (await GalleryFolderRepository.instance.getAllRootDirs())
        .map((dir) => dir.path)
        .toList();
    final paths = <String, String>{};
    final listings = <String, List<String>>{};
    final children = <String, Map<String, String>>{};
    for (final id in ids) {
      final category = categories.findById(id);
      var ancestor = category;
      final ancestors = <String>{};
      var external = false;
      while (ancestor != null && ancestors.add(ancestor.id)) {
        external = external || ancestor.isExternal;
        ancestor = ancestor.parentId == null
            ? null
            : categories.findById(ancestor.parentId!);
      }
      if (category == null || external) {
        throw const NaiAgentToolError(
          'invalid_folder',
          'Use non-root main-library categories',
        );
      }
      final path = await _categoryPath(category, root);
      if (!galleryPathIsWithin(root, path) ||
          galleryFilePathsEqual(root, path) ||
          await _externalFilePath(path)) {
        throw const NaiAgentToolError(
          'invalid_folder',
          'Root and external folder trees are read-only',
        );
      }
      paths[id] = path;
    }
    for (final id in ids) {
      final path = paths[id]!;
      if (categories
          .getChildren(id)
          .any((child) => !selected.contains(child.id))) {
        throw NaiAgentToolError(
          'folder_not_empty',
          'Unselected category in $path',
        );
      }
      final entries = await _directoryEntries(path);
      final allowedChildren = <String, String>{};
      await for (final entry in Directory(path).list(followLinks: false)) {
        final childId = ids
            .where(
              (other) =>
                  other != id &&
                  galleryFilePathsEqual(paths[other]!, entry.path),
            )
            .firstOrNull;
        if (childId == null ||
            await FileSystemEntity.type(entry.path, followLinks: false) !=
                FileSystemEntityType.directory) {
          throw NaiAgentToolError(
            'folder_not_empty',
            'Folder contains unselected entries: $path',
          );
        }
        allowedChildren[p.basename(entry.path)] = childId;
      }
      if (jsonEncode(entries) != jsonEncode(await _directoryEntries(path))) {
        throw NaiAgentToolError(
          'folder_conflict',
          'Directory changed during preflight: $path',
        );
      }
      children[id] = allowedChildren;
      listings[id] = entries;
      _admit(token);
    }
    // The preflight allows only selected physical children; descendants first
    // leaves each directory truly empty when native non-recursive deletion runs.
    final ordered = [...ids]
      ..sort((a, b) {
        final physical = p
            .split(paths[b]!)
            .length
            .compareTo(p.split(paths[a]!).length);
        if (physical != 0) return physical;
        return categories
            .getDescendantIds(a)
            .length
            .compareTo(categories.getDescendantIds(b).length);
      });
    if (ref.read(shareImageSettingsProvider).effectiveConfirmDangerousActions) {
      await _confirmFileChange(
        ids.length == 1
            ? currentL10n.naiAgent_galleryDeleteEmptyFolderConfirm(
                paths[ids.single]!,
              )
            : currentL10n.naiAgent_galleryDeleteEmptyFoldersConfirm(
                ids.length,
                _listedGalleryItems(ids.map((id) => paths[id]!).toList()),
              ),
        token,
      );
    }
    final store = files;
    if (store == null) {
      throw const NaiAgentToolError('workspace_unavailable', 'No workspace');
    }
    final backup = await store.export(
      'folders.json',
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'folders': [
              for (final id in ids)
                {'id': id, 'old_path': paths[id], 'entries': listings[id]},
            ],
            'categories': categories.map((c) => c.toJson()).toList(),
            'delete_pool': await const GalleryDeletePoolStore().load(),
          }),
        ),
      ),
      () => _check(token),
    );
    final (_, latestRoot, latestVersion) = await _folderCatalog(token);
    _admit(token);
    if (latestVersion != version || !galleryFilePathsEqual(root, latestRoot)) {
      throw const NaiAgentToolError(
        'folder_conflict',
        'Folder catalog changed during confirmation/backup; read again',
      );
    }
    for (final id in ids) {
      if (!galleryFilePathsEqual(
            await _categoryPath(categories.findById(id), root),
            paths[id]!,
          ) ||
          jsonEncode(listings[id]) !=
              jsonEncode(await _directoryEntries(paths[id]!))) {
        throw NaiAgentToolError(
          'folder_conflict',
          'Folder changed during confirmation/backup: ${paths[id]}',
        );
      }
    }
    final deleted = <String>[];
    final applied = <String>[];
    Object? failure;
    String? failedId;
    var remaining = categories;
    for (final id in ordered) {
      try {
        _admit(token);
        final (latest, currentRoot, _) = await _folderCatalog(token);
        if (!galleryFilePathsEqual(root, currentRoot) ||
            jsonEncode(roots) !=
                jsonEncode(
                  (await GalleryFolderRepository.instance.getAllRootDirs())
                      .map((dir) => dir.path)
                      .toList(),
                ) ||
            jsonEncode(
                  latest
                      .where((c) => !deleted.contains(c.id))
                      .map((c) => c.toJson())
                      .toList(),
                ) !=
                jsonEncode(remaining.map((c) => c.toJson()).toList())) {
          throw const NaiAgentToolError(
            'folder_conflict',
            'Other catalog entries changed; read again',
          );
        }
        final expected = listings[id]!
            .where(
              (entry) => !children[id]!.entries.any(
                (child) =>
                    deleted.contains(child.value) &&
                    entry.startsWith('${child.key}:'),
              ),
            )
            .toList();
        if (!galleryFilePathsEqual(
              await _categoryPath(remaining.findById(id), root),
              paths[id]!,
            ) ||
            jsonEncode(expected) !=
                jsonEncode(await _directoryEntries(paths[id]!))) {
          throw NaiAgentToolError(
            'folder_conflict',
            'Directory changed before deletion: ${paths[id]}',
          );
        }
        _admit(token);
        if (!await categoryRepository.deleteCategory(
          remaining.findById(id)!,
          remaining,
        )) {
          throw NaiAgentToolError(
            'folder_delete_failed',
            'Native empty-folder deletion failed: ${paths[id]}',
          );
        }
        deleted.add(id);
        remaining = remaining.where((c) => c.id != id).toList();
      } catch (error) {
        if (deleted.isEmpty) rethrow;
        failure = error;
        failedId = id;
        break;
      }
    }
    if (deleted.isNotEmpty) {
      applied.add('filesystem_changed');
      try {
        // Always persist applied deletions, even after Stop or a later conflict;
        // retain concurrent edits to all other categories rather than overwrite.
        // Cleanup must survive cancellation/binding disposal after admission.
        final latest = await categoryRepository.loadCategories();
        if (latest.isEmpty &&
            !await categoryRepository.isCategoriesConfigGenuinelyEmpty()) {
          throw const NaiAgentToolError(
            'folder_catalog_failed',
            'Invalid native catalog was retained',
          );
        }
        if (jsonEncode(
              latest
                  .where((c) => !deleted.contains(c.id))
                  .map((c) => c.toJson())
                  .toList(),
            ) !=
            jsonEncode(remaining.map((c) => c.toJson()).toList())) {
          failure ??= const NaiAgentToolError(
            'folder_conflict',
            'Newer native catalog edits were retained',
          );
        }
        remaining = latest.where((c) => !deleted.contains(c.id)).toList();
        if (!await categoryRepository.saveCategories(remaining)) {
          throw const NaiAgentToolError(
            'folder_catalog_failed',
            'Native catalog could not be saved',
          );
        }
        applied.add('catalog_saved');
      } catch (error) {
        failure ??= error;
      }
      try {
        await _refreshFileLibrary(
          service,
          categoryPaths: {
            for (final item in remaining) item.id: item.folderPath,
          },
          removed: deleted.toSet(),
        );
      } catch (error) {
        failure ??= error;
      }
    }
    return naiAgentTextResult(
      failure == null
          ? {
              'ok': true,
              'deleted': true,
              'folder_ids': deleted,
              'count': deleted.length,
              'backup': backup,
              'applied_fields': applied,
            }
          : {
              'ok': false,
              'error': failure is NaiAgentToolError
                  ? failure.code
                  : 'native_gallery_failed',
              'message':
                  'Read actual folders and the catalog before retrying; completed deletions were retained.',
              'deleted_folder_ids': deleted,
              'failed_folder_id': failedId,
              'remaining_folder_ids': ordered
                  .where((id) => !deleted.contains(id))
                  .toList(),
              'backup': backup,
              'applied_fields': applied,
            },
    );
  }

  Future<Map<String, dynamic>> _manageFolders(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    final action = params['action'];
    final allowed = switch (action) {
      'folders' => {'action', 'scope', 'offset', 'limit'},
      'folder_sync' => {'action', 'scope', 'expected_folder_version'},
      'folder_create' => {
        'action',
        'scope',
        'parent_id',
        'changes',
        'expected_folder_version',
      },
      'folder_rename' => {
        'action',
        'scope',
        'folder_id',
        'changes',
        'expected_folder_version',
      },
      'folder_move' => {
        'action',
        'scope',
        'folder_id',
        'parent_id',
        'expected_folder_version',
      },
      'folder_delete_empty' => {
        'action',
        'scope',
        'folder_id',
        'folder_ids',
        'expected_folder_version',
      },
      _ => {'action', 'scope', 'folder_id', 'expected_folder_version'},
    };
    if (params.keys.any((key) => !allowed.contains(key)) ||
        (params['scope'] ?? 'library') != 'library') {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'Invalid physical folder action fields',
      );
    }
    final (categories, root, version) = await _folderCatalog(token);
    final repo = categoryRepository;
    if (action == 'folders') {
      final offset = _number(params, 'offset', 0, 1000000);
      final limit = _number(params, 'limit', 30, 100);
      final page = categories.skip(offset).take(limit).toList();
      final folders = <Map<String, dynamic>>[];
      for (final category in page) {
        final path = category.isExternal
            ? category.folderPath
            : p.join(root, category.folderPath);
        try {
          final resolved = await _folderPath(path);
          folders.add({
            'folder_id': category.id,
            'name': category.name,
            'parent_id': category.parentId,
            'file_path': resolved,
            'external': category.isExternal,
            'image_count': category.imageCount,
          });
        } on FileSystemException {
          /* stale native category */
        } on NaiAgentToolError catch (error) {
          if (!{
            'folder_missing',
            'image_outside_library',
          }.contains(error.code)) {
            rethrow;
          }
        }
        _check(token);
      }
      return naiAgentTextResult({
        'root_path': root,
        'root_folder_id': null,
        'folders': folders,
        'folder_version': version,
        'next_offset': offset + page.length < categories.length
            ? offset + page.length
            : null,
        'notice':
            'Physical native category catalog. External folder trees are read-only; individual image transfers are supported.',
      });
    }
    _admit(token);
    if (params['expected_folder_version'] != version) {
      throw const NaiAgentToolError(
        'folder_conflict',
        'Read current folders and acknowledge folder_version',
      );
    }
    final nativeService = await _service(token);
    if (!ref.read(naiAgentGalleryDataSourceProvider).isInitialized) {
      throw const NaiAgentToolError(
        'gallery_unavailable',
        'Wait for the native index before changing physical folders',
      );
    }
    if (action == 'folder_sync') {
      final store = files;
      if (store == null) {
        throw const NaiAgentToolError('workspace_unavailable', 'No workspace');
      }
      final backup = await store.export(
        'folders.json',
        Uint8List.fromList(
          utf8.encode(jsonEncode(categories.map((c) => c.toJson()).toList())),
        ),
        () => _check(token),
      );
      if ((await _folderCatalog(token)).$3 != version) {
        throw const NaiAgentToolError(
          'folder_conflict',
          'Folder catalog changed during backup',
        );
      }
      _admit(token);
      final updated = await repo.syncWithFileSystem(categories);
      if ((await _folderCatalog(token)).$3 != version) {
        throw const NaiAgentToolError(
          'folder_conflict',
          'Folder catalog changed during synchronization',
        );
      }
      _admit(token);
      if (!await repo.saveCategories(updated)) {
        throw const NaiAgentToolError(
          'folder_catalog_failed',
          'Synchronized catalog could not be saved',
        );
      }
      await _refreshFileLibrary(nativeService);
      return naiAgentTextResult({
        'ok': true,
        'backup': backup,
        'folder_count': updated.length,
        'folder_version': (await _folderCatalog(NaiAgentCancellation())).$3,
        'notice': 'Read folders again to page the synchronized native catalog.',
      });
    }
    if (action == 'folder_delete_empty' && params.containsKey('folder_ids')) {
      if (params.containsKey('folder_id')) {
        throw const NaiAgentToolError(
          'invalid_gallery',
          'Use folder_id or folder_ids, not both',
        );
      }
      return _deleteEmptyFolders(
        params,
        token,
        categories,
        root,
        version,
        nativeService,
      );
    }
    final folderId = params['folder_id'];
    final category = folderId is String ? categories.findById(folderId) : null;
    final parentId = params['parent_id'];
    final parent = parentId is String ? categories.findById(parentId) : null;
    if ((action != 'folder_create' && category == null) ||
        (parentId != null && parent == null) ||
        category?.isExternal == true ||
        parent?.isExternal == true) {
      throw const NaiAgentToolError(
        'invalid_folder',
        'Use a main-library category; null parent means root',
      );
    }
    final oldPath = await _categoryPath(category, root);
    final parentPath = await _categoryPath(parent, root);
    if (!galleryPathIsWithin(root, oldPath) ||
        !galleryPathIsWithin(root, parentPath) ||
        (category != null && galleryFilePathsEqual(root, oldPath))) {
      throw const NaiAgentToolError(
        'invalid_folder',
        'Root and external folder trees cannot be moved',
      );
    }
    final changes = params['changes'];
    String? name;
    if (action == 'folder_create' || action == 'folder_rename') {
      if (changes is! Map ||
          changes.keys.length != 1 ||
          changes['name'] is! String ||
          (changes['name'] as String).trim().isEmpty ||
          (changes['name'] as String).length > 160) {
        throw const NaiAgentToolError(
          'invalid_folder',
          'Provide only changes.name',
        );
      }
      name = (changes['name'] as String).trim();
      if (name == '.' ||
          name == '..' ||
          RegExp(r'[\\/:*?"<>|\x00-\x1F]').hasMatch(name) ||
          name.startsWith('.') ||
          name.endsWith('.') ||
          name.endsWith(' ')) {
        throw const NaiAgentToolError(
          'invalid_folder',
          'Use a visible single directory name',
        );
      }
    }
    if (action == 'folder_move') {
      if (parentId == category!.parentId) {
        return naiAgentTextResult({
          'ok': true,
          'unchanged': true,
          'folder_id': category.id,
        });
      }
      if (parentId != null &&
          categories.wouldCreateCycle(category.id, parentId as String)) {
        throw const NaiAgentToolError(
          'invalid_folder',
          'Folder cannot contain itself',
        );
      }
    }
    final entries = await _directoryEntries(oldPath);
    final parentEntries = await _directoryEntries(parentPath);
    if (action == 'folder_delete_empty' && entries.isNotEmpty) {
      throw const NaiAgentToolError(
        'folder_not_empty',
        'Only an empty physical directory can be deleted',
      );
    }
    final planned = action == 'folder_create'
        ? p.join(parentPath, name!)
        : action == 'folder_rename'
        ? p.join(p.dirname(oldPath), name!)
        : action == 'folder_move'
        ? p.join(parentPath, p.basename(oldPath))
        : null;
    if (planned != null &&
        await FileSystemEntity.type(planned, followLinks: false) !=
            FileSystemEntityType.notFound) {
      throw const NaiAgentToolError('folder_exists', 'Target already exists');
    }
    if (action == 'folder_delete_empty' &&
        ref.read(shareImageSettingsProvider).effectiveConfirmDangerousActions) {
      await _confirmFileChange(
        currentL10n.naiAgent_galleryDeleteEmptyFolderConfirm(oldPath),
        token,
      );
    }
    final store = files;
    if (store == null) {
      throw const NaiAgentToolError('workspace_unavailable', 'No workspace');
    }
    final backup = await store.export(
      'folders.json',
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'categories': categories.map((c) => c.toJson()).toList(),
            'old_path': oldPath,
            'planned_path': planned,
            'entries': entries,
            'delete_pool': await const GalleryDeletePoolStore().load(),
          }),
        ),
      ),
      () => _check(token),
    );
    Future<void> checkFoldersFresh() async {
      final (_, latestRoot, latestVersion) = await _folderCatalog(token);
      _admit(token);
      if (version != latestVersion ||
          !galleryFilePathsEqual(root, latestRoot) ||
          jsonEncode(entries) != jsonEncode(await _directoryEntries(oldPath)) ||
          jsonEncode(parentEntries) !=
              jsonEncode(await _directoryEntries(parentPath))) {
        throw const NaiAgentToolError(
          'folder_conflict',
          'Folders changed during backup; read again',
        );
      }
      _admit(token);
    }

    await checkFoldersFresh();
    final applied = <String>[];
    try {
      GalleryCategory? updated;
      var result = categories;
      if (action == 'folder_create') {
        updated = await repo.createCategory(
          name: name!,
          parentId: parentId as String?,
          existingCategories: categories,
        );
        if (updated == null) {
          throw const NaiAgentToolError(
            'folder_create_failed',
            'Native folder creation failed',
          );
        }
        result = [...categories, updated];
      } else if (action == 'folder_delete_empty') {
        if (!await repo.deleteCategory(category!, categories)) {
          throw const NaiAgentToolError(
            'folder_delete_failed',
            'Native empty-folder deletion failed',
          );
        }
        result = categories.where((c) => c.id != category.id).toList();
      } else {
        updated = action == 'folder_rename'
            ? await repo.renameCategory(
                category!,
                name!,
                categories,
                beforeRelocate: checkFoldersFresh,
              )
            : await repo.moveCategory(
                category!,
                parentId as String?,
                categories,
                beforeRelocate: checkFoldersFresh,
              );
        if (updated == null) {
          _admit(token);
          throw const NaiAgentToolError(
            'folder_move_failed',
            'Native folder relocation failed',
          );
        }
        result = repo.updateDescendantPaths(
          category.folderPath,
          updated.folderPath,
          categories.map((c) => c.id == updated!.id ? updated : c).toList(),
        );
        applied.add('index_and_delete_pool_relocated');
      }
      applied.add('filesystem_changed');
      if ((await _folderCatalog(NaiAgentCancellation())).$3 != version) {
        throw const NaiAgentToolError(
          'folder_conflict',
          'Physical change completed; newer native category edits were retained',
        );
      }
      if (!await repo.saveCategories(result)) {
        throw const NaiAgentToolError(
          'folder_catalog_failed',
          'Native catalog could not be saved',
        );
      }
      applied.add('catalog_saved');
      await _refreshFileLibrary(
        nativeService,
        categoryPaths: {for (final item in result) item.id: item.folderPath},
        removed: action == 'folder_delete_empty' ? {category!.id} : const {},
      );
      return naiAgentTextResult({
        'ok': true,
        'folder_id': updated?.id ?? folderId,
        'file_path': updated == null
            ? null
            : await _categoryPath(updated, root),
        'deleted': action == 'folder_delete_empty',
        'backup': backup,
        'applied_fields': applied,
      });
    } catch (error) {
      return naiAgentTextResult({
        'ok': false,
        'folder_id': folderId,
        'planned_path': planned,
        'backup': backup,
        'applied_fields': applied,
        'error': error is NaiAgentToolError
            ? error.code
            : 'native_gallery_failed',
        'message':
            'Read actual folders before retrying; directory changes may be applied.',
      });
    }
  }
}

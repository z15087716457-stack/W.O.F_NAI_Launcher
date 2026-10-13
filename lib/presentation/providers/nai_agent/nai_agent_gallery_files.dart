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

extension _GalleryFiles on NaiAgentGalleryBinding {
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
    final l10n = currentL10n;
    final protected = ref
        .read(shareImageSettingsProvider)
        .effectiveConfirmDangerousActions;
    if ((!copy && (sourceExternal || targetExternal)) || protected) {
      final warning = copy
          ? l10n.localGallery_confirmCopyContent
          : sourceExternal && targetExternal
          ? l10n.localGallery_externalBothMoveConfirmContent(
              1,
              p.basename(target),
            )
          : sourceExternal
          ? l10n.localGallery_externalSourceMoveConfirmContent(1)
          : targetExternal
          ? l10n.localGallery_externalTargetMoveConfirmContent(
              1,
              p.basename(target),
            )
          : l10n.localGallery_confirmMoveImageContent;
      await _confirmFileChange('$warning\n$sourcePath → $target', token);
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

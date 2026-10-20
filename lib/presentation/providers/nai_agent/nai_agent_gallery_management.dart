part of 'nai_agent_gallery_binding.dart';

class _ManagedGalleryImage {
  _ManagedGalleryImage(
    this.scope,
    this.id,
    this.data,
    this.bytes,
    this.history,
  );
  final String scope, id;
  final Map<String, dynamic> data;
  final Uint8List? bytes;
  final GeneratedImage? history;
  String get version =>
      sha256.convert(utf8.encode(jsonEncode(data))).toString();
  Map<String, dynamic> get recovery => {
    ...data,
    'image_id': id,
    'scope': scope,
    'image_version': version,
  };
  Map<String, dynamic> get summary {
    final result = recovery;
    final metadata = result['metadata'];
    if (metadata is Map) {
      result['metadata'] = Map<String, dynamic>.from(metadata)
        ..remove('raw_json')
        ..remove('rawJson');
    }
    return result;
  }
}

extension _GalleryManagement on NaiAgentGalleryBinding {
  void _admit(NaiAgentCancellation token) {
    _check(token);
    if (isBusy?.call() == true) {
      throw const NaiAgentToolError('busy', 'An image job is running');
    }
  }

  Future<String> _managedPath(String path) async {
    final file = File(path);
    final resolved = await file.exists()
        ? await file.resolveSymbolicLinks()
        : p.join(await file.parent.resolveSymbolicLinks(), p.basename(path));
    for (final root
        in await GalleryFolderRepository.instance.getAllRootDirs()) {
      if (await root.exists() &&
          galleryPathIsWithin(await root.resolveSymbolicLinks(), resolved)) {
        return resolved;
      }
    }
    throw const NaiAgentToolError(
      'image_outside_library',
      'Image is outside the current configured library roots',
    );
  }

  Future<_ManagedGalleryImage> _managed(
    String scope,
    String id,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    if (scope == 'history') {
      final state = ref.read(imageGenerationNotifierProvider);
      final wanted = id == 'selected'
          ? ref.read(generationPreviewSelectionProvider)
          : id;
      final image = [
        ...state.currentImages,
        ...state.history,
        ...state.displayImages,
      ].where((image) => image.id == wanted).firstOrNull;
      if (image == null) {
        throw const NaiAgentToolError(
          'image_missing',
          'History image not found',
        );
      }
      if (image.bytes.length > AgentWorkspaceFiles.maxBytes ||
          (image.originalBytes?.length ?? 0) > AgentWorkspaceFiles.maxBytes) {
        throw const NaiAgentToolError('file_too_large', 'Image exceeds 64 MiB');
      }
      return _ManagedGalleryImage(
        scope,
        image.id,
        {
          'file_path': image.filePath,
          'width': image.width,
          'height': image.height,
          'created_at': image.createdAt.toIso8601String(),
          'metadata': image.metadata?.toJson(),
          'kind': image.kind.name,
          'operation': image.operation?.name,
          'generation_run_id': image.generationRunId,
          'batch_index': image.batchIndex,
          'variation_original': image.isVariationOriginal,
          'sha256': sha256.convert(image.bytes).toString(),
          'original_sha256': image.originalBytes == null
              ? null
              : sha256.convert(image.originalBytes!).toString(),
        },
        image.bytes,
        image,
      );
    }
    final match = RegExp(r'^gallery:([1-9]\d*)$').firstMatch(id);
    final number = match == null ? null : int.tryParse(match[1]!);
    if (number == null) {
      throw const NaiAgentToolError('invalid_image', 'Use a gallery:<ID>');
    }
    await _service(token);
    final source = ref.read(naiAgentGalleryDataSourceProvider);
    final row = await source.readImageForManagement(number);
    _check(token);
    if (row == null) {
      throw const NaiAgentToolError('image_missing', 'Library entry not found');
    }
    final path = await _managedPath(row.filePath);
    final file = File(path);
    final bytes = await file.exists()
        ? await AgentWorkspaceFiles.readBounded(file)
        : null;
    final tags = (await source.getImageTags(number))..sort();
    final collections = (await source.getCollectionIdsForImage(number)).toList()
      ..sort();
    final favorite = await source.isFavorite(number);
    final metadata = await source.getMetadataByImageId(number);
    _check(token);
    return _ManagedGalleryImage(
      scope,
      id,
      {
        'record': row.toMap(),
        'file_path': row.filePath,
        'resolved_path': path,
        'file_missing': bytes == null,
        'sha256': bytes == null ? null : sha256.convert(bytes).toString(),
        'deleted': row.isDeleted,
        'favorite': favorite,
        'tags': tags,
        'collection_ids': collections,
        'metadata': metadata?.toMap(),
      },
      bytes,
      null,
    );
  }

  String _extension(Uint8List bytes) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50) return '.png';
      if (bytes[0] == 0xff && bytes[1] == 0xd8) return '.jpg';
      if (bytes[0] == 0x47 && bytes[1] == 0x49) return '.gif';
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
        return '.webp';
      }
    }
    return '.bin';
  }

  Future<Map<String, dynamic>> _imageBackup(
    _ManagedGalleryImage image,
    NaiAgentCancellation token,
  ) async {
    final store = files;
    if (store == null) {
      throw const NaiAgentToolError('workspace_unavailable', 'No workspace');
    }
    final record = Uint8List.fromList(utf8.encode(jsonEncode(image.recovery)));
    final bytes = image.bytes;
    final originals = image.history?.originalBytes;
    final path = bytes == null
        ? await store.export('entry.json', record, () => _check(token))
        : await store.export(
            'image${_extension(bytes)}',
            bytes,
            () => _check(token),
            companions: {
              'entry.json': record,
              if (originals != null)
                'source${_extension(originals)}': originals,
            },
          );
    return {
      'path': path,
      'record_path': p.join(p.dirname(path), 'entry.json'),
      'original_path': originals == null
          ? null
          : p.join(p.dirname(path), 'source${_extension(originals)}'),
      'file_missing': bytes == null,
    };
  }

  Future<void> _refreshManagedLibrary(
    LocalGalleryService service, {
    bool restore = false,
  }) async {
    if (!isAlive()) return;
    if (ref.exists(localGalleryNotifierProvider)) {
      final notifier = ref.read(localGalleryNotifierProvider.notifier);
      if (restore) {
        await notifier.refresh(scan: false);
      } else {
        await notifier.refreshMetadataView();
      }
    } else if (restore) {
      await service.refresh(scan: false);
    } else {
      await service.applyFilter(service.currentFilter);
    }
    if (isAlive() && ref.exists(collectionNotifierProvider)) {
      await ref.read(collectionNotifierProvider.notifier).refresh();
    }
  }

  Future<Map<String, dynamic>> _manage(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    if (_fileActions.contains(params['action'])) {
      return _manageFiles(params, token);
    }
    if (_collectionActions.contains(params['action'])) {
      return _collections(params, token);
    }
    const fields = {
      'action',
      'scope',
      'image_id',
      'expected_image_version',
      'changes',
      'offset',
      'limit',
    };
    final action = params['action'], scope = params['scope'] ?? 'history';
    if (params.keys.any((key) => !fields.contains(key)) ||
        !{
          'read',
          'update',
          'delete',
          'restore',
          'export',
          'trash',
        }.contains(action) ||
        !{'history', 'library'}.contains(scope)) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'Unsupported action, scope or field',
      );
    }
    if (action == 'trash') {
      if (scope != 'library' ||
          params.keys.any(
            (key) => !{'action', 'scope', 'offset', 'limit'}.contains(key),
          )) {
        throw const NaiAgentToolError(
          'invalid_gallery',
          'trash requires library scope and paging only',
        );
      }
      await _service(token);
      final offset = _number(params, 'offset', 0, 1000000);
      final limit = _number(params, 'limit', 30, 100);
      final rows = await ref
          .read(naiAgentGalleryDataSourceProvider)
          .queryDeletedImageRecords(offset: offset, limit: limit);
      final images = <Map<String, dynamic>>[];
      for (final row in rows) {
        try {
          final path = await _managedPath(row.filePath);
          images.add({
            'image_id': 'gallery:${row.id}',
            'file_path': row.filePath,
            'file_missing': !await File(path).exists(),
          });
        } on NaiAgentToolError catch (error) {
          if (error.code != 'image_outside_library') rethrow;
        } on FileSystemException {
          // A missing parent cannot be safely resolved to a current root.
        }
        _check(token);
      }
      return naiAgentTextResult({
        'images': images,
        'next_offset': rows.length == limit ? offset + rows.length : null,
        'order': 'deleted_index_id:descending',
        'scope': scope,
        'notice':
            'Only current library roots; physical cleanup occurs on a later Studio startup.',
      });
    }
    if (params.containsKey('offset') ||
        params.containsKey('limit') ||
        (action != 'update' && params.containsKey('changes'))) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'Fields do not apply to this action',
      );
    }
    final id = params['image_id'];
    if (id is! String || id.isEmpty || id.length > 200) {
      throw const NaiAgentToolError('invalid_image', 'Provide an image_id');
    }
    final changes = params['changes'];
    if (action == 'update' &&
        (scope != 'library' ||
            changes is! Map ||
            changes.isEmpty ||
            changes.keys.any((key) => !{'favorite', 'tags'}.contains(key)) ||
            (changes.containsKey('favorite') && changes['favorite'] is! bool) ||
            (changes.containsKey('tags') &&
                (changes['tags'] is! List ||
                    (changes['tags'] as List).length > 100 ||
                    (changes['tags'] as List).any(
                      (tag) =>
                          tag is! String ||
                          tag.trim().isEmpty ||
                          tag.length > 200,
                    ))))) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'update supports library favorite and tags only',
      );
    }
    if (action == 'restore' && scope != 'library') {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'restore requires library scope',
      );
    }
    final image = await _managed(scope as String, id, token);
    if (action == 'read') return naiAgentTextResult(image.summary);
    _admit(token);
    if (params['expected_image_version'] != image.version) {
      throw const NaiAgentToolError(
        'image_conflict',
        'Read the current image and acknowledge its version',
      );
    }
    if ((action == 'restore' || action == 'export') && image.bytes == null) {
      throw const NaiAgentToolError(
        'image_missing',
        'Original image file no longer exists',
      );
    }
    if (action == 'restore'
        ? image.data['deleted'] != true
        : action != 'export' && image.data['deleted'] == true) {
      throw const NaiAgentToolError(
        'invalid_gallery',
        'Read current deletion state before this action',
      );
    }
    final backup = await _imageBackup(image, token);
    final current = await _managed(scope, image.id, token);
    _admit(token);
    if (current.version != image.version) {
      throw const NaiAgentToolError(
        'image_conflict',
        'Image changed during backup; read again',
      );
    }
    if (action == 'export') {
      return naiAgentTextResult({
        'ok': true,
        'image_id': image.id,
        'export': backup,
      });
    }
    final applied = <String>[];
    try {
      if (scope == 'history') {
        final pins = ref.read(canvasPinnedNotifierProvider.notifier);
        final history = ref.read(imageGenerationNotifierProvider.notifier);
        await pins.remove(image.id);
        applied.add('pin_removed');
        history.removeImages({image.id});
        applied.add('history_removed');
        if (isAlive() &&
            ref.read(generationPreviewSelectionProvider) == image.id) {
          ref.read(generationPreviewSelectionProvider.notifier).clear();
        }
        return naiAgentTextResult({
          'ok': true,
          'deleted': true,
          'scope': scope,
          'saved_files_deleted': false,
          'image_id': image.id,
          'backup': backup,
        });
      }
      final service = await _service(NaiAgentCancellation());
      final source = ref.read(naiAgentGalleryDataSourceProvider);
      final number = (image.data['record'] as Map)['id'] as int;
      final path = image.data['file_path'] as String;
      if (action == 'update') {
        final value = Map<String, dynamic>.from(changes as Map);
        if (value.containsKey('favorite')) {
          if (value['favorite'] == true) {
            await source.addFavorite(number);
            applied.add('favorite');
          } else {
            // Already resolved a fresh native ID; avoid re-resolving a path
            // alias through the service's differently normalized file list.
            await source.removeFavorites([number]);
            applied.add('favorite');
            await source.removeImagesFromAllCollections([number]);
            applied.add('collection_membership');
          }
        }
        if (value.containsKey('tags')) {
          await source.setImageTags(
            number,
            (value['tags'] as List).cast<String>(),
          );
          applied.add('tags');
        }
        await _refreshManagedLibrary(service);
      } else if (action == 'delete') {
        await source.batchMarkAsDeleted([path]);
        applied.add('index_deleted');
        service.removeImagesFromMemory([path]);
        if (isAlive() && ref.exists(localGalleryNotifierProvider)) {
          await ref
              .read(localGalleryNotifierProvider.notifier)
              .removeDeletedImagesFromMemory([path]);
        }
        await const GalleryDeletePoolStore().addAll([path]);
        if (!(await const GalleryDeletePoolStore().load()).contains(path)) {
          throw const NaiAgentToolError(
            'delete_pool_failed',
            'Delete-pool persistence failed',
          );
        }
        applied.add('delete_pool_added');
      } else {
        // Stop pending physical cleanup before making the index visible again.
        await const GalleryDeletePoolStore().restore([path], () async {
          applied.add('delete_pool_removed');
          await source.batchRestoreDeleted([path]);
          applied.add('index_restored');
        });
        if (isAlive() && ref.exists(localGalleryNotifierProvider)) {
          await ref
              .read(localGalleryNotifierProvider.notifier)
              .clearRecentlyDeleted([path]);
        }
        await _refreshManagedLibrary(service, restore: true);
      }
      final after = await _managed(scope, image.id, NaiAgentCancellation());
      return naiAgentTextResult({
        'ok': true,
        'image_id': image.id,
        'scope': scope,
        'before': image.summary,
        'image_version': after.version,
        'applied_fields': applied,
        'backup': backup,
        'deleted': action == 'delete',
        'physical_cleanup': action == 'delete' ? 'next_studio_startup' : null,
        'unfavorite_removes_collection_membership':
            action == 'update' && (changes as Map)['favorite'] == false,
      });
    } catch (error) {
      return naiAgentTextResult({
        'ok': false,
        'image_id': image.id,
        'scope': scope,
        'applied_fields': applied,
        'backup': backup,
        'error': error is NaiAgentToolError
            ? error.code
            : 'native_gallery_failed',
        'message':
            'Native changes may already be applied. Read current state before retrying.',
      });
    }
  }
}

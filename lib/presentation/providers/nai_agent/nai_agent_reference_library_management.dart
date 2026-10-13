part of 'nai_agent_reference_library_binding.dart';

extension _ReferenceLibraryManagement on NaiAgentReferenceLibraryBinding {
  Map<String, dynamic> _changes(Map<String, dynamic> p, Set<String> allowed) {
    final value = p['changes'];
    if (value is! Map ||
        value.isEmpty ||
        value.keys.any((k) => !allowed.contains(k))) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Provide supported nonempty changes',
      );
    }
    final changes = Map<String, dynamic>.from(value);
    if (changes.containsKey('name') &&
        (changes['name'] is! String ||
            (changes['name'] as String).trim().isEmpty ||
            (changes['name'] as String).length > 160)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid reference/category name',
      );
    }
    return changes;
  }

  Future<Map<String, dynamic>> _backupReference(
    _ReferenceData data,
    NaiAgentCancellation token,
  ) async {
    final metadata = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'kind': data.kind,
          'name': data.name,
          'entry_version': data.version,
          'entry': data.vibeEntry != null
              ? _vibeEntry(data.vibeEntry!)
              : _preciseEntry(data.precise!),
          'file_missing': data.fileMissing,
          'file_invalid': data.fileInvalid,
          // Disk-only recovery data; never returned as the model summary.
          'native_record': data.kind == 'precise'
              ? {
                  ..._preciseEntry(data.precise!),
                  'image_path': data.precise!.imagePath,
                  'last_used_at': data.precise!.lastUsedAt?.toIso8601String(),
                }
              : _nativeVibeRecord(data.storedVibeEntry ?? data.vibeEntry!),
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'vibes': data.vibes.map(_vibe).toList(),
        }),
      ),
    );
    Uint8List? original = data.file ?? data.image;
    var extension = data.fileName == null
        ? null
        : path.extension(data.fileName!);
    if (original == null && !data.fileMissing && data.vibes.isNotEmpty) {
      original = Uint8List.fromList(
        utf8.encode(
          NovelAiVibeCodec.encodeJson(
            data.vibes.length == 1
                ? NovelAiVibeCodec.buildSingleMap(data.vibes.single)
                : NovelAiVibeCodec.buildBundleMap(data.vibes),
          ),
        ),
      );
      extension = data.vibes.length == 1 ? '.naiv4vibe' : '.naiv4vibebundle';
    }
    if (data.kind == 'precise' && original != null) {
      extension = data.fileInvalid
          ? path.extension(data.precise!.imagePath)
          : PreciseRefLibraryStorageService.detectImageExtension(original);
    }
    final file = await files.export(
      original == null ? 'entry.json' : 'original$extension',
      original ?? metadata,
      () => _write(token),
      companions: original == null ? const {} : {'entry.json': metadata},
    );
    return {
      'original_path': original == null ? null : file,
      'metadata_path': original == null
          ? file
          : path.join(path.dirname(file), 'entry.json'),
      'file_missing': data.fileMissing,
      'file_invalid': data.fileInvalid,
    };
  }

  VibeReference _prepareLibraryParameters(
    _ReferenceData data,
    int index,
    Map<String, dynamic> changes,
  ) {
    final original = data.vibes[index];
    final strength =
        (changes['strength'] as num?)?.toDouble() ?? original.strength;
    final info =
        (changes['info_extracted'] as num?)?.toDouble() ??
        original.infoExtracted;
    final next = original.copyWith(strength: strength, infoExtracted: info);
    if (info == original.infoExtracted || original.vibeEncoding.isEmpty) {
      return next;
    }
    final model =
        original.encodingModel ??
        ref.read(generationParamsNotifierProvider).model;
    String? encoding;
    // Use an exact existing file variant or the native in-memory cache only.
    // Never label an old encoding as belonging to a new information level.
    if (data.file != null &&
        {
          '.naiv4vibe',
          '.naiv4vibebundle',
        }.contains(path.extension(data.fileName!).toLowerCase())) {
      final json = jsonDecode(utf8.decode(data.file!)) as Map;
      final single = json['vibes'] is List
          ? (json['vibes'] as List)[index] as Map
          : json;
      final models = single['encodings'];
      final variants = models is Map
          ? models[NovelAiVibeCodec.encodingKeyForModel(model)]
          : null;
      if (variants is Map) {
        for (final variant in variants.values.whereType<Map>()) {
          final params = variant['params'];
          if (params is Map &&
              params['information_extracted'] == info &&
              variant['encoding'] is String &&
              (variant['encoding'] as String).isNotEmpty) {
            encoding = variant['encoding'] as String;
            break;
          }
        }
      }
    }
    if (encoding == null && original.rawImageData != null) {
      encoding = ref
          .read(generationParamsNotifierProvider.notifier)
          .getCachedVibeEncoding(
            original.rawImageData!,
            model: model,
            informationExtracted: info,
          );
    }
    if (encoding == null) {
      throw const NaiAgentToolError(
        'encoding_required',
        'This information level needs a new encoding. Apply the reference, update its draft parameters, quote/approve generation, then save the encoded draft reference. No library changes made.',
      );
    }
    return next.withEncodedVibe(encoding, model: model);
  }

  Future<Map<String, dynamic>> _manageEntry(
    String kind,
    String action,
    Map<String, dynamic> p,
    NaiAgentCancellation token,
  ) async {
    _write(token);
    if (p['id'] is! String || (p['id'] as String).isEmpty) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Provide a library entry id',
      );
    }
    final id = p['id'] as String;
    final data = await _entry(kind, id, token);
    if (p['expected_entry_version'] != data.version) {
      throw const NaiAgentToolError(
        'entry_conflict',
        'Read the current entry version before changing it',
      );
    }
    final changes = action == 'update'
        ? _changes(
            p,
            kind == 'vibe'
                ? {
                    'name',
                    'favorite',
                    'category_id',
                    'tags',
                    'strength',
                    'info_extracted',
                  }
                : {'name', 'favorite', 'type', 'strength', 'fidelity'},
          )
        : <String, dynamic>{};
    for (final field in ['strength', 'info_extracted', 'fidelity']) {
      if (changes.containsKey(field) &&
          (changes[field] is! num ||
              !(changes[field] as num).isFinite ||
              field == 'info_extracted' &&
                  ((changes[field] as num) < 0.01 ||
                      (changes[field] as num) > 1))) {
        throw const NaiAgentToolError(
          'invalid_reference',
          'Invalid finite reference parameter',
        );
      }
    }
    if (changes.containsKey('favorite') && changes['favorite'] is! bool ||
        changes.containsKey('type') &&
            !PreciseRefType.values.asNameMap().containsKey(changes['type']) ||
        changes.containsKey('category_id') &&
            changes['category_id'] != null &&
            changes['category_id'] is! String ||
        changes.containsKey('tags') &&
            (changes['tags'] is! List ||
                (changes['tags'] as List).length > 100 ||
                (changes['tags'] as List).any(
                  (t) => t is! String || t.trim().isEmpty || t.length > 80,
                ))) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid favorite/type/category/tags',
      );
    }
    final child = p['child_index'];
    final parameters =
        changes.containsKey('strength') ||
        changes.containsKey('info_extracted');
    if (child != null &&
            (kind != 'vibe' ||
                child is! int ||
                child < 0 ||
                child >= data.vibes.length ||
                changes.keys.any(
                  (k) => !{'strength', 'info_extracted'}.contains(k),
                )) ||
        kind == 'vibe' &&
            parameters &&
            data.vibeEntry!.isBundle &&
            child == null) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Choose one bundle child for its parameter changes',
      );
    }
    if ((data.fileMissing || data.fileInvalid) && parameters) {
      throw const NaiAgentToolError(
        'file_unavailable',
        'Repair the missing/damaged reference file before editing its parameters',
      );
    }
    final prepared = kind == 'vibe' && parameters
        ? _prepareLibraryParameters(data, child as int? ?? 0, changes)
        : null;
    Future<void> categoryExists() async {
      if (changes['category_id'] != null &&
          !await vibes.categoryExists(changes['category_id'] as String)) {
        throw const NaiAgentToolError(
          'category_missing',
          'Choose an existing Vibe category',
        );
      }
    }

    await categoryExists();
    final backup = await _backupReference(data, token);
    await categoryExists();
    final current = await _entry(kind, id, token);
    _write(token);
    if (current.version != data.version) {
      throw const NaiAgentToolError(
        'entry_conflict',
        'Reference changed during backup; read it again',
      );
    }
    final vibeStorage = kind == 'vibe' ? vibes : null;
    final preciseStorage = kind == 'precise' ? precise : null;
    var vibe = current.vibeEntry;
    var preciseValue = current.precise;
    final applied = <String>[];
    String? failure;
    // Native commit admission: once started, finish each requested operation.
    // Report partial native failures rather than rolling back other edits.
    try {
      if (action == 'delete') {
        final removed = kind == 'vibe'
            ? await vibeStorage!.deleteEntry(id)
            : await preciseStorage!.deleteEntry(id);
        if (!removed) throw StateError('delete_failed');
        applied.add('delete');
      } else if (kind == 'precise') {
        if (changes.keys.any((k) => k != 'favorite')) {
          preciseValue = await preciseStorage!.updateEntry(
            id,
            name: changes['name'] as String?,
            type: PreciseRefType.values.asNameMap()[changes['type']],
            strength: (changes['strength'] as num?)?.toDouble(),
            fidelity: (changes['fidelity'] as num?)?.toDouble(),
          );
          if (preciseValue == null) throw StateError('entry_missing');
          applied.addAll(changes.keys.where((k) => k != 'favorite'));
        }
        if (changes.containsKey('favorite')) {
          if (preciseValue!.isFavorite != changes['favorite']) {
            preciseValue = await preciseStorage!.toggleFavorite(id);
            if (preciseValue == null) throw StateError('entry_missing');
          }
          applied.add('favorite');
        }
      } else {
        if (changes.containsKey('name')) {
          final renamed = await vibeStorage!.renameEntry(
            id,
            changes['name'] as String,
          );
          if (!renamed.isSuccess) {
            throw StateError('rename_${renamed.error?.name}');
          }
          vibe = renamed.entry!;
          applied.add('name');
        }
        if (prepared != null) {
          vibe = vibe!.isBundle
              ? await vibeStorage!.saveBundleChildParams(
                  id,
                  childIndex: child as int,
                  strength: prepared.strength,
                  infoExtracted: prepared.infoExtracted,
                  persistedVibeData: prepared,
                )
              : await vibeStorage!.saveEntryParams(
                  id,
                  strength: prepared.strength,
                  infoExtracted: prepared.infoExtracted,
                  persistedVibeData: prepared,
                );
          if (vibe == null) throw StateError('entry_missing');
          applied.addAll(
            changes.keys.where(
              (k) => {'strength', 'info_extracted'}.contains(k),
            ),
          );
        }
        if (changes.containsKey('category_id')) {
          vibe = await vibeStorage!.updateEntryCategory(
            id,
            changes['category_id'] as String?,
          );
          if (vibe == null) throw StateError('entry_missing');
          applied.add('category_id');
        }
        if (changes.containsKey('tags')) {
          vibe = await vibeStorage!.updateEntryTags(
            id,
            (changes['tags'] as List)
                .cast<String>()
                .map((t) => t.trim())
                .toSet()
                .toList(),
          );
          if (vibe == null) throw StateError('entry_missing');
          applied.add('tags');
        }
        if (changes.containsKey('favorite')) {
          if (vibe!.isFavorite != changes['favorite']) {
            vibe = await vibeStorage!.toggleFavorite(id);
            if (vibe == null) throw StateError('entry_missing');
          }
          applied.add('favorite');
        }
      }
    } catch (e) {
      failure = e is StateError ? e.message : 'native_storage_failed';
    }
    bool? residualFile;
    String? residualPath;
    if (action == 'delete' && applied.contains('delete')) {
      final originalPath =
          current.vibeEntry?.filePath ?? current.precise?.imagePath;
      if (originalPath != null) {
        residualFile = await File(originalPath).exists();
        if (residualFile) {
          residualPath = originalPath;
          failure ??= 'reference_file_remains';
        }
      }
    }
    await _publish(kind);
    String? version;
    if (action != 'delete' && isAlive() && !token.isCancelled) {
      version = (await _entry(kind, id, token)).version;
    }
    return naiAgentTextResult({
      'ok': failure == null,
      'applied_fields': applied,
      'backup': backup,
      if (failure != null) 'error': failure,
      if (action == 'delete') 'deleted': applied.contains('delete'),
      if (residualFile != null) 'residual_reference_file': residualFile,
      if (residualPath != null) 'residual_file_path': residualPath,
      if (action != 'delete')
        'entry': kind == 'vibe'
            ? _vibeEntry(vibe ?? current.vibeEntry!)
            : _preciseEntry(preciseValue ?? current.precise!),
      if (version != null) 'entry_version': version,
      'draft_changed': false,
      'paid_encoding': false,
      'cancelled_after_admission': token.isCancelled,
    });
  }

  Future<Map<String, dynamic>> _categoryState(
    NaiAgentCancellation token,
  ) async {
    final categories = await vibes.getAllCategories();
    final entries = await vibes.getDisplayEntries();
    _live(token);
    final rows = categories.map((c) => c.toJson()).toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    final members =
        entries.map((e) => {'id': e.id, 'category_id': e.categoryId}).toList()
          ..sort((a, b) => a['id']!.compareTo(b['id']!));
    return {
      'categories': rows,
      'members': members,
      'version': sha256
          .convert(
            utf8.encode(jsonEncode({'categories': rows, 'members': members})),
          )
          .toString(),
    };
  }

  Future<Map<String, dynamic>> _manageCategories(
    String kind,
    String action,
    Map<String, dynamic> p,
    NaiAgentCancellation token,
    int offset,
    int limit,
  ) async {
    if (kind != 'vibe') {
      throw const NaiAgentToolError(
        'unsupported_reference',
        'Precise references have no native categories',
      );
    }
    final state = await _categoryState(token);
    final rows = (state['categories'] as List).cast<Map<String, dynamic>>();
    if (action == 'categories') {
      final query = (p['query'] as String? ?? '').toLowerCase();
      final found =
          rows
              .where((c) => (c['name'] as String).toLowerCase().contains(query))
              .toList()
            ..sort(
              (a, b) =>
                  (a['sortOrder'] as int).compareTo(b['sortOrder'] as int),
            );
      return naiAgentTextResult({
        'categories': found
            .skip(offset)
            .take(limit)
            .map(
              (c) => {
                'id': c['id'],
                'name': c['name'],
                'parent_id': c['parentId'],
                'sort_order': c['sortOrder'],
                'entry_count': (state['members'] as List)
                    .where((e) => e['category_id'] == c['id'])
                    .length,
              },
            )
            .toList(),
        'total_count': found.length,
        'next_offset': offset + limit < found.length ? offset + limit : null,
        'category_version': state['version'],
      });
    }
    _write(token);
    if (p['expected_category_version'] != state['version']) {
      throw const NaiAgentToolError(
        'category_conflict',
        'Read current categories before changing them',
      );
    }
    final changes = action == 'category_delete'
        ? <String, dynamic>{}
        : _changes(p, {'name', 'parent_id', 'sort_order'});
    final existing = rows.where((c) => c['id'] == p['id']).firstOrNull;
    if (action != 'category_create' &&
        (p['id'] is! String || existing == null)) {
      throw const NaiAgentToolError('category_missing', 'Category not found');
    }
    if (changes.containsKey('parent_id') &&
            changes['parent_id'] != null &&
            changes['parent_id'] is! String ||
        changes.containsKey('sort_order') &&
            (changes['sort_order'] is! int ||
                (changes['sort_order'] as int) < 0) ||
        p.containsKey('move_entries_to_parent') &&
            p['move_entries_to_parent'] is! bool ||
        action == 'category_create' && !changes.containsKey('name')) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid category changes',
      );
    }
    final category = action == 'category_create'
        ? VibeLibraryCategory.create(name: changes['name'] as String)
        : VibeLibraryCategory.fromJson(existing!);
    final parent = changes.containsKey('parent_id')
        ? changes['parent_id'] as String?
        : category.parentId;
    final visited = <String>{category.id};
    String? cursor = parent;
    while (cursor != null) {
      if (!visited.add(cursor)) {
        throw const NaiAgentToolError(
          'category_cycle',
          'Category hierarchy would contain a cycle',
        );
      }
      final ancestor = rows.where((c) => c['id'] == cursor).firstOrNull;
      if (ancestor == null) {
        throw const NaiAgentToolError(
          'category_missing',
          'Parent category not found',
        );
      }
      cursor = ancestor['parentId'] as String?;
    }
    final updated = category.copyWith(
      name: (changes['name'] as String?)?.trim() ?? category.name,
      parentId: parent,
      sortOrder: changes['sort_order'] as int? ?? category.sortOrder,
    );
    if (action != 'category_delete' &&
        rows.any(
          (c) =>
              c['id'] != updated.id &&
              c['parentId'] == parent &&
              (c['name'] as String).trim().toLowerCase() ==
                  updated.name.toLowerCase(),
        )) {
      throw const NaiAgentToolError(
        'name_conflict',
        'A sibling category already has this name',
      );
    }
    final backup = await files.export(
      'categories.json',
      Uint8List.fromList(utf8.encode(jsonEncode(state))),
      () => _write(token),
    );
    final fresh = await _categoryState(token);
    _write(token);
    if (fresh['version'] != state['version']) {
      throw const NaiAgentToolError(
        'category_conflict',
        'Categories or membership changed during backup',
      );
    }
    final storage = vibes;
    final bool ok;
    if (action == 'category_delete') {
      ok = await storage.deleteCategory(
        category.id,
        moveEntriesToParent: p['move_entries_to_parent'] != false,
      );
    } else {
      await storage.saveCategory(updated);
      ok = true;
    }
    await _publish(
      'vibe',
      deletedCategory: action == 'category_delete' && ok ? category.id : null,
    );
    return naiAgentTextResult({
      'ok': ok,
      'backup_path': backup,
      if (action == 'category_delete') 'deleted': ok,
      if (action != 'category_delete')
        'category': {
          'id': updated.id,
          'name': updated.name,
          'parent_id': updated.parentId,
          'sort_order': updated.sortOrder,
        },
      'draft_changed': false,
      'paid_encoding': false,
      'cancelled_after_admission': token.isCancelled,
    });
  }
}

Map<String, dynamic> _nativeVibeRecord(VibeLibraryEntry entry) => {
  ..._referenceNativeMetadata(entry),
  'vibe_display_name': entry.vibeDisplayName,
  'vibe_encoding': entry.vibeEncoding,
  'encoding_model': entry.encodingModel,
  'raw_image_data': entry.rawImageData == null
      ? null
      : base64Encode(entry.rawImageData!),
  'vibe_thumbnail': entry.vibeThumbnail == null
      ? null
      : base64Encode(entry.vibeThumbnail!),
  'thumbnail': entry.thumbnail == null ? null : base64Encode(entry.thumbnail!),
  'last_used_at': entry.lastUsedAt?.toIso8601String(),
  'file_path': entry.filePath,
  'bundle_id': entry.bundleId,
  'bundled_names': entry.bundledVibeNames,
  'bundled_previews': entry.bundledVibePreviews?.map(base64Encode).toList(),
  'bundled_encodings': entry.bundledVibeEncodings,
  'bundled_strengths': entry.bundledVibeStrengths,
  'bundled_info_extracted': entry.bundledVibeInfoExtracted,
  'bundled_encoding_models': entry.bundledVibeEncodingModels,
};

Map<String, dynamic> _referenceNativeMetadata(VibeLibraryEntry e) => {
  'id': e.id,
  'name': e.name,
  'category_id': e.categoryId,
  'tags': e.tags,
  'favorite': e.isFavorite,
  'used_count': e.usedCount,
  'source_type_index': e.sourceTypeIndex,
  'strength': e.strength,
  'info_extracted': e.infoExtracted,
  'created_at': e.createdAt.toIso8601String(),
};

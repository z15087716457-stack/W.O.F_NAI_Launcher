import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/repositories/prompt_block_repository.dart';
import '../krita/bridge_draft_guard.dart';
import 'agent_tool.dart';
import 'block_organization_tools.dart';

String naiAgentBlockVersion(PromptBlock value) {
  final data = value.toJson()
    ..remove('useCount')
    ..remove('updatedAt');
  return sha256.convert(utf8.encode(jsonEncode(data))).toString();
}

const naiAgentBlockEditableFields = {
  'title',
  'content',
  'negativeContent',
  'atoms',
  'negativeAtoms',
  'folderId',
  'color',
  'appearance',
  'iconName',
  'tags',
  'generationSettings',
  'isFavorite',
  'readingTranslationZh',
  'readingTranslationMarks',
  'readingTranslationLanguageCode',
  'readingTranslationEdited',
  'readingTranslationNeedsReview',
  'sortOrder',
};

Map<String, dynamic> validateNaiAgentBlockChanges(
  Object? raw, {
  bool create = false,
}) {
  if (raw is! Map || raw.isEmpty) {
    throw const NaiAgentToolError(
      'invalid_changes',
      'Provide block fields to change',
    );
  }
  final changes = Map<String, dynamic>.from(raw);
  if (changes.keys.any((key) => !naiAgentBlockEditableFields.contains(key))) {
    throw const NaiAgentToolError(
      'invalid_changes',
      'Unknown or read-only block field',
    );
  }
  if (create &&
      (changes['title'] is! String || changes['content'] is! String)) {
    throw const NaiAgentToolError(
      'invalid_changes',
      'Creating a block requires title and content',
    );
  }
  for (final key in [
    'title',
    'content',
    'negativeContent',
    'appearance',
    'readingTranslationLanguageCode',
  ]) {
    if (!changes.containsKey(key)) continue;
    final value = changes[key];
    if (value is! String ||
        value.length > 100000 ||
        (key == 'title' && (value.trim().isEmpty || value.length > 200))) {
      throw NaiAgentToolError('invalid_changes', 'Invalid block field: $key');
    }
  }
  for (final key in ['folderId', 'iconName', 'readingTranslationZh']) {
    if (changes.containsKey(key) &&
        changes[key] != null &&
        changes[key] is! String) {
      throw NaiAgentToolError(
        'invalid_changes',
        'Expected string or null: $key',
      );
    }
  }
  if (changes.containsKey('color') &&
      (changes['color'] is! String ||
          !RegExp(
            r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$',
          ).hasMatch(changes['color'] as String))) {
    throw const NaiAgentToolError(
      'invalid_changes',
      'Expected RGB or ARGB hex color',
    );
  }
  for (final key in [
    'isFavorite',
    'readingTranslationEdited',
    'readingTranslationNeedsReview',
  ]) {
    if (changes.containsKey(key) && changes[key] is! bool) {
      throw NaiAgentToolError('invalid_changes', 'Expected boolean: $key');
    }
  }
  if (changes.containsKey('sortOrder') && changes['sortOrder'] is! int) {
    throw const NaiAgentToolError(
      'invalid_changes',
      'Expected integer sortOrder',
    );
  }
  for (final key in ['atoms', 'negativeAtoms']) {
    if (!changes.containsKey(key) || changes[key] == null) continue;
    final atoms = changes[key];
    if (atoms is! List ||
        atoms.length > 5000 ||
        atoms.any((e) => e is! String) ||
        atoms.cast<String>().fold<int>(0, (size, text) => size + text.length) >
            100000) {
      throw NaiAgentToolError(
        'invalid_changes',
        'Invalid explicit atom pool: $key',
      );
    }
  }
  // A text edit must not continue rolling an obsolete explicit atom pool.
  if (changes.containsKey('content') && !changes.containsKey('atoms')) {
    changes['atoms'] = null;
  }
  if (changes.containsKey('negativeContent') &&
      !changes.containsKey('negativeAtoms')) {
    changes['negativeAtoms'] = null;
  }
  if (changes['generationSettings'] != null) {
    final rawSettings = changes['generationSettings'];
    const mapping = {
      'model': 'model',
      'width': 'width',
      'height': 'height',
      'steps': 'steps',
      'scale': 'cfg_scale',
      'sampler': 'sampler',
      'noiseSchedule': 'noise_schedule',
      'cfgRescale': 'cfg_rescale',
    };
    if (rawSettings is! Map ||
        rawSettings.keys.any((k) => !mapping.containsKey(k))) {
      throw const NaiAgentToolError(
        'invalid_changes',
        'Unknown block generation setting',
      );
    }
    try {
      validateBridgePatch({
        for (final e in rawSettings.entries)
          if (e.value != null) mapping[e.key]!: e.value,
      });
    } on FormatException catch (error) {
      throw NaiAgentToolError('invalid_changes', error.message);
    }
  }
  // Model JSON decoders validate nested tag and translation structures before IO.
  try {
    PromptBlock.fromJson({
      ...PromptBlock.create(title: 'validation', content: '').toJson(),
      ...changes,
    });
  } catch (error) {
    throw NaiAgentToolError(
      'invalid_changes',
      'Invalid nested block fields: ${error.runtimeType}',
    );
  }
  return changes;
}

Map<String, dynamic> naiAgentBlockResult(
  PromptBlock block, {
  bool full = false,
}) => {
  if (full)
    ...block.toJson()
  else ...{
    'id': block.id,
    'title': block.title,
    'folderId': block.folderId,
    'isFavorite': block.isFavorite,
    'isArchived': block.isArchived,
    'color': block.color,
    'appearance': block.appearance,
    'content_preview': block.content.substring(
      0,
      block.content.length.clamp(0, 180),
    ),
    'content_length': block.content.length,
    'has_negative': block.negativeContent.isNotEmpty,
    'tags': block.tags.map((tag) => tag.toJson()).toList(),
  },
  'version': naiAgentBlockVersion(block),
};

/// The actual Hive repository, backup and editor binding are supplied by Studio.
class NaiAgentBlockTools {
  NaiAgentBlockTools({
    required this.readLibrary,
    required this.repository,
    required this.refresh,
    required this.readDraft,
    required this.backup,
    required this.isBusy,
    required this.isAlive,
    required this.editInstance,
    required this.validateInstance,
    this.afterDelete,
  });
  final Future<PromptBlockLibraryData> Function() readLibrary;
  final PromptBlockRepository repository;
  final Future<void> Function() refresh;
  final BridgeDraftSnapshot Function() readDraft;
  final Future<String> Function(
    PromptBlockLibraryData,
    BridgeDraftSnapshot,
    PromptBlock?,
  )
  backup;
  final bool Function() isBusy, isAlive;
  final Map<String, dynamic> Function(Map<String, dynamic>, PromptBlock?)
  editInstance;
  final void Function(Map<String, dynamic>, PromptBlock?, BridgeDraftSnapshot)
  validateInstance;
  final Future<void> Function(PromptBlock)? afterDelete;

  Future<Map<String, dynamic>> query(
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    cancellation.check();
    final library = await readLibrary();
    cancellation.check();
    if (params['kind'] == 'tree') {
      return naiAgentTextResult({
        'library_version': naiAgentBlockLibraryVersion(library),
        'folders': library.folders.map((e) => e.toJson()).toList(),
        'collections': library.collections.map((e) => e.toJson()).toList(),
      });
    }
    if (params['id'] case final String id) {
      final block = library.getBlock(id);
      return naiAgentTextResult({
        'block': block == null ? null : naiAgentBlockResult(block, full: true),
      });
    }
    final query = params['query'] ?? '',
        offset = params['offset'] ?? 0,
        limit = params['limit'] ?? 20;
    if (query is! String ||
        query.length > 200 ||
        offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 100) {
      throw const NaiAgentToolError(
        'invalid_query',
        'Expected query and a page of 1 to 100 blocks',
      );
    }
    final collectionId = params['collection_id'];
    final collection = collectionId is String
        ? library.getCollection(collectionId)
        : null;
    if (collectionId != null && collection == null) {
      throw const NaiAgentToolError(
        'collection_missing',
        'Collection no longer exists',
      );
    }
    final text = query.toLowerCase();
    final blocks =
        library.blocks
            .where(
              (b) =>
                  (params['include_archived'] == true || !b.isArchived) &&
                  (!params.containsKey('folder_id') ||
                      b.folderId == params['folder_id']) &&
                  (params['favorites'] != true || b.isFavorite) &&
                  (collection == null || collection.blockIds.contains(b.id)) &&
                  (text.isEmpty ||
                      [
                        b.title,
                        b.content,
                        b.negativeContent,
                        ...b.tags.map((e) => e.name),
                      ].any((part) => part.toLowerCase().contains(text))),
            )
            .toList()
          ..sort((a, b) {
            final order = a.sortOrder.compareTo(b.sortOrder);
            return order != 0 ? order : a.id.compareTo(b.id);
          });
    return naiAgentTextResult({
      'blocks': blocks
          .skip(offset)
          .take(limit)
          .map((b) => naiAgentBlockResult(b))
          .toList(),
      'total': blocks.length,
      'next_offset': offset + limit < blocks.length ? offset + limit : null,
    });
  }

  Future<Map<String, dynamic>> manage(
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    cancellation.check();
    final action = params['action'];
    if (naiAgentBlockOrganizationActions.contains(action)) {
      return manageOrganization(params, cancellation);
    }
    const actions = {'create', 'update', 'delete', 'insert', 'instance_update'};
    if (!actions.contains(action)) {
      throw const NaiAgentToolError(
        'invalid_action',
        'Expected create/update/delete/insert/instance_update',
      );
    }
    final changes = action == 'create' || action == 'update'
        ? validateNaiAgentBlockChanges(
            params['changes'],
            create: action == 'create',
          )
        : null;
    final library = await readLibrary();
    final before = readDraft();
    final id = params['id'];
    final block = id is String ? library.getBlock(id) : null;
    if (action != 'create' && action != 'instance_update' && block == null) {
      throw const NaiAgentToolError(
        'block_missing',
        'Read the block catalog again',
      );
    }
    final expected = params['expected_version'];
    if (action == 'insert' || action == 'instance_update') {
      validateInstance(params, block, before);
    }
    void check([PromptBlock? actual]) {
      cancellation.check();
      if (!isAlive()) {
        throw const NaiAgentToolError('closed', 'Studio binding closed');
      }
      if (isBusy()) {
        throw const NaiAgentToolError(
          'busy',
          'Generation is active; blocks were not changed',
        );
      }
      if (readDraft().acknowledgementVersion != before.acknowledgementVersion) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Studio draft changed during this operation',
        );
      }
      if (block != null &&
          (actual == null || expected != naiAgentBlockVersion(actual))) {
        throw const NaiAgentToolError(
          'block_conflict',
          'Read block_query(id=...) again and supply its version',
        );
      }
      if ((action == 'insert' || action == 'instance_update') &&
          params['expected_draft_version'] != before.acknowledgementVersion) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Read studio_context(scope=draft) again before editing an instance',
        );
      }
    }

    check(block);
    final path = await backup(library, before, block);
    check(block);
    if (action == 'insert' || action == 'instance_update') {
      await refresh();
      final current = id is String ? (await readLibrary()).getBlock(id) : null;
      check(current);
      final result = editInstance(params, current);
      return naiAgentTextResult({
        ...result,
        'backup_path': path,
        'draft': readDraft().toJson(),
        'draft_version': readDraft().acknowledgementVersion,
      });
    }
    PromptBlock? actual;
    if (action == 'create') {
      final value = PromptBlock.fromJson({
        ...PromptBlock.create(
          title: changes!['title'] as String,
          content: changes['content'] as String,
        ).toJson(),
        ...changes,
      });
      actual = await repository.createBlock(
        title: value.title,
        content: value.content,
        negativeContent: value.negativeContent,
        atoms: value.atoms,
        negativeAtoms: value.negativeAtoms,
        folderId: value.folderId,
        color: value.color,
        appearance: value.appearance,
        iconName: value.iconName,
        generationSettings: value.generationSettings,
        tags: value.tags,
        readingTranslationZh: value.readingTranslationZh,
        isFavorite: value.isFavorite,
        readingTranslationMarks: value.readingTranslationMarks,
        readingTranslationLanguageCode: value.readingTranslationLanguageCode,
        readingTranslationNeedsReview: value.readingTranslationNeedsReview,
        readingTranslationEdited: value.readingTranslationEdited,
        sortOrder: changes.containsKey('sortOrder') ? value.sortOrder : null,
        beforeWrite: () => check(),
      );
    } else if (action == 'update') {
      final updated = PromptBlock.fromJson({...block!.toJson(), ...changes!});
      actual = await repository.updateBlock(updated, beforeWrite: check);
    } else {
      await repository.deleteBlock(block!.id, beforeWrite: check);
      await afterDelete?.call(block);
    }
    await refresh();
    final readBack = actual == null
        ? null
        : (await readLibrary()).getBlock(actual.id);
    return naiAgentTextResult({
      'action': action,
      'id': actual?.id ?? id,
      'block': readBack == null
          ? null
          : naiAgentBlockResult(readBack, full: true),
      'backup_path': path,
      'draft': readDraft().toJson(),
    });
  }
}

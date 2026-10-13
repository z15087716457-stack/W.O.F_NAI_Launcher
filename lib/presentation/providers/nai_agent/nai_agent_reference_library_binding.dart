import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../../../core/enums/precise_ref_type.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../core/utils/novelai_vibe_codec.dart';
import '../../../core/utils/vibe_file_parser.dart';
import '../../../data/models/precise_ref/precise_ref_library_entry.dart';
import '../../../data/models/vibe/vibe_library_entry.dart';
import '../../../data/models/vibe/vibe_library_category.dart';
import '../../../data/models/vibe/vibe_reference.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../../../data/services/precise_ref_library_storage_service.dart';
import '../../../data/services/vibe_library_storage_service.dart';
import '../image_generation_provider.dart';
import '../precise_ref_library_provider.dart';
import '../vibe_library_provider.dart';
import '../krita/bridge_draft_snapshot.dart';
import 'nai_agent_reference_binding.dart';

part 'nai_agent_reference_library_management.dart';

class _ReferenceData {
  _ReferenceData({
    required this.kind,
    required this.name,
    required this.metadata,
    this.vibes = const [],
    this.image,
    this.file,
    this.fileName,
    this.precise,
    this.vibeEntry,
    this.storedVibeEntry,
    this.fileMissing = false,
    this.fileInvalid = false,
  });
  final String kind, name;
  final Map<String, dynamic> metadata;
  final List<VibeReference> vibes;
  final Uint8List? image, file;
  final String? fileName;
  final PreciseRefLibraryEntry? precise;
  final VibeLibraryEntry? vibeEntry;
  final VibeLibraryEntry? storedVibeEntry;
  final bool fileMissing;
  final bool fileInvalid;
  String get version => sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'metadata': metadata,
            'file_missing': fileMissing,
            'file_invalid': fileInvalid,
            'file': file == null ? null : sha256.convert(file!).toString(),
            'image': image == null ? null : sha256.convert(image!).toString(),
            'vibes': [
              for (final v in vibes)
                {
                  ..._vibe(v),
                  'encoding_hash': sha256
                      .convert(utf8.encode(v.vibeEncoding))
                      .toString(),
                  'raw_hash': v.rawImageData == null
                      ? null
                      : sha256.convert(v.rawImageData!).toString(),
                  'preview_hash': v.thumbnail == null
                      ? null
                      : sha256.convert(v.thumbnail!).toString(),
                },
            ],
          }),
        ),
      )
      .toString();
}

Map<String, dynamic> _vibe(VibeReference v) => {
  'name': v.displayName,
  'strength': v.strength,
  'info_extracted': v.infoExtracted,
  'encoded': v.vibeEncoding.isNotEmpty,
  'encoding_model': v.encodingModel,
  'source_type': v.sourceType.name,
  'has_original_image': v.rawImageData != null,
  'has_preview': v.thumbnail != null,
};

class NaiAgentReferenceLibraryBinding {
  NaiAgentReferenceLibraryBinding(
    this.ref,
    Directory workspace,
    this.references,
    this.loadImage,
    this.isBusy,
    this.isAlive, {
    AgentWorkspaceFiles? workspaceFiles,
  }) : files = workspaceFiles ?? AgentWorkspaceFiles(workspace);
  final Ref ref;
  final AgentWorkspaceFiles files;
  final NaiAgentReferenceBinding references;
  final Future<NaiAgentImage> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )
  loadImage;
  final bool Function() isBusy, isAlive;
  VibeLibraryStorageService get vibes =>
      ref.read(vibeLibraryStorageServiceProvider);
  PreciseRefLibraryStorageService get precise =>
      ref.read(preciseRefLibraryStorageServiceProvider);
  void _live(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
  }

  void _write(NaiAgentCancellation token) {
    _live(token);
    if (isBusy()) {
      throw const NaiAgentToolError('busy', 'A Studio image job is active');
    }
  }

  Map<String, dynamic> _vibeEntry(VibeLibraryEntry e) => {
    'id': e.id,
    'name': e.displayName,
    'category_id': e.categoryId,
    'tags': e.tags,
    'favorite': e.isFavorite,
    'used_count': e.usedCount,
    'created_at': e.createdAt.toIso8601String(),
    'source_type': e.sourceType.name,
    'strength': e.strength,
    'info_extracted': e.infoExtracted,
    'bundle_count': e.bundledVibeNames?.length ?? 1,
    'image_id': 'reference:vibe:${e.id}',
  };
  Map<String, dynamic> _preciseEntry(PreciseRefLibraryEntry e) => {
    'id': e.id,
    'name': e.name,
    'type': e.type.name,
    'strength': e.strength,
    'fidelity': e.fidelity,
    'favorite': e.isFavorite,
    'used_count': e.usedCount,
    'created_at': e.createdAt.toIso8601String(),
    'image_id': 'reference:precise:${e.id}',
  };

  Future<_ReferenceData> _entry(
    String kind,
    String id,
    NaiAgentCancellation token,
  ) async {
    _live(token);
    if (kind == 'vibe') {
      final stored = await vibes.getEntryRecord(id);
      _live(token);
      if (stored == null) {
        throw const NaiAgentToolError('entry_missing', 'Vibe entry not found');
      }
      Uint8List? file;
      var missing = false;
      if (stored.filePath case final p?) {
        if (await File(p).exists()) {
          file = await AgentWorkspaceFiles.readBounded(File(p));
        } else {
          missing = true;
        }
      }
      _live(token);
      var parsed = [stored.toVibeReference()];
      var invalid = false;
      if (file != null) {
        try {
          parsed = await VibeFileParser.parseFile(
            path.basename(stored.filePath!),
            file,
          );
        } catch (_) {
          // Keep the actual record readable for cleanup; apply still rejects.
          invalid = true;
          parsed = [stored.toVibeReference()];
        }
      }
      // Native legacy entries may retain original pixels/encodings only in
      // Hive. Merge them exactly as getEntry does, from the bounded file read.
      var values = stored.isBundle
          ? parsed
          : [
              parsed.single.copyWith(
                vibeEncoding: parsed.single.vibeEncoding.isNotEmpty
                    ? parsed.single.vibeEncoding
                    : stored.vibeEncoding,
                thumbnail:
                    parsed.single.thumbnail ??
                    stored.vibeThumbnail ??
                    stored.thumbnail,
                rawImageData: parsed.single.rawImageData ?? stored.rawImageData,
                encodingModel:
                    parsed.single.encodingModel ?? stored.encodingModel,
              ),
            ];
      if (!missing && !invalid) {
        try {
          _validateVibes(values);
        } on NaiAgentToolError {
          invalid = true;
          values = [stored.toVibeReference()];
        }
      }
      final entry = stored.updateVibeData(values.first);
      _live(token);
      return _ReferenceData(
        kind: kind,
        name: entry.displayName,
        metadata: {..._vibeEntry(entry)}..remove('used_count'),
        vibes: values,
        file: file,
        vibeEntry: entry,
        storedVibeEntry: stored,
        fileMissing: missing,
        fileInvalid: invalid,
        fileName: entry.filePath == null
            ? null
            : path.basename(entry.filePath!),
      );
    }
    final entry = (await precise.getAllEntries())
        .where((e) => e.id == id)
        .firstOrNull;
    _live(token);
    if (entry == null) {
      throw const NaiAgentToolError(
        'entry_missing',
        'Precise reference not found',
      );
    }
    final missing = !await File(entry.imagePath).exists();
    final bytes = missing
        ? null
        : await AgentWorkspaceFiles.readBounded(File(entry.imagePath));
    var invalid = false;
    if (bytes != null) {
      try {
        _validateImage(bytes);
      } on NaiAgentToolError {
        invalid = true;
      }
    }
    _live(token);
    return _ReferenceData(
      kind: kind,
      name: entry.name,
      metadata: {..._preciseEntry(entry)}..remove('used_count'),
      image: bytes,
      precise: entry,
      fileMissing: missing,
      fileInvalid: invalid,
    );
  }

  void _validateImage(Uint8List bytes) {
    final size = NaiResolutionAdapter.readImageSize(bytes);
    if (bytes.length > AgentWorkspaceFiles.maxBytes ||
        size == null ||
        size.$1 * size.$2 > 64000000) {
      throw const NaiAgentToolError(
        'invalid_image',
        'Invalid image or image exceeds 64 MiB/64 million pixels',
      );
    }
    PreciseRefLibraryStorageService.detectImageExtension(bytes);
  }

  void _validateVibes(List<VibeReference> values) {
    if (values.isEmpty || values.length > 256) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Expected 1 to 256 Vibes',
      );
    }
    for (final v in values) {
      if (!v.strength.isFinite ||
          !v.infoExtracted.isFinite ||
          v.infoExtracted < 0.01 ||
          v.infoExtracted > 1 ||
          v.vibeEncoding.length > AgentWorkspaceFiles.maxBytes ||
          v.vibeEncoding.isEmpty && v.rawImageData == null) {
        throw const NaiAgentToolError(
          'invalid_reference',
          'Invalid Vibe data or parameters',
        );
      }
      if (v.rawImageData case final bytes?) _validateImage(bytes);
      if (v.thumbnail case final bytes?) _validateImage(bytes);
    }
  }

  Future<_ReferenceData> _file(
    String kind,
    String relative,
    NaiAgentCancellation token,
  ) async {
    _live(token);
    if (kind == 'precise') {
      final image = await loadImage({'path': relative}, token);
      return _ReferenceData(
        kind: kind,
        name: path.basenameWithoutExtension(relative),
        metadata: const {},
        image: image.bytes,
      );
    }
    final bytes = await files.read(relative);
    _live(token);
    final values = await VibeFileParser.parseFile(
      path.basename(relative),
      bytes,
    );
    _validateVibes(values);
    _live(token);
    return _ReferenceData(
      kind: kind,
      name: path.basenameWithoutExtension(relative),
      metadata: const {},
      vibes: values,
      file: bytes,
      fileName: path.basename(relative),
    );
  }

  Future<NaiAgentImage?> loadLibraryImage(
    String id,
    NaiAgentCancellation token,
  ) async {
    final match = RegExp(
      r'^reference:(vibe|precise):([^:]{1,200})(?::([0-9]+))?$',
    ).firstMatch(id);
    if (match == null) return null;
    final kind = match[1]!;
    if (kind == 'precise' && match[3] != null) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Precise references have no bundle children',
      );
    }
    final data = await _entry(kind, match[2]!, token);
    final index = match[3] == null ? 0 : int.parse(match[3]!);
    if (kind == 'vibe' && index >= data.vibes.length) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Bundle child index is out of range',
      );
    }
    final bytes = kind == 'precise'
        ? data.image
        : data.vibes[index].rawImageData ?? data.vibes[index].thumbnail;
    if (bytes == null) {
      throw const NaiAgentToolError(
        'image_missing',
        'This pre-encoded Vibe has no original image or preview',
      );
    }
    _validateImage(bytes);
    _live(token);
    return NaiAgentImage(id: id, bytes: bytes);
  }

  Future<void> _publish(String kind, {String? deletedCategory}) async {
    if (!isAlive()) return;
    if (kind == 'vibe' && ref.exists(vibeLibraryNotifierProvider)) {
      if (deletedCategory != null &&
          ref.read(vibeLibraryNotifierProvider).selectedCategoryId ==
              deletedCategory) {
        await ref
            .read(vibeLibraryNotifierProvider.notifier)
            .clearCategoryFilter();
        if (!isAlive()) return;
      }
      await ref.read(vibeLibraryNotifierProvider.notifier).reload();
    } else if (kind == 'precise' &&
        ref.exists(preciseRefLibraryNotifierProvider)) {
      await ref.read(preciseRefLibraryNotifierProvider.notifier).reload();
    }
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> p,
    NaiAgentCancellation token,
  ) async {
    _live(token);
    final kind = p['kind'] ?? 'vibe', action = p['action'] ?? 'query';
    if (!{'vibe', 'precise'}.contains(kind) ||
        !{
          'query',
          'read',
          'apply',
          'import',
          'save',
          'export',
          'update',
          'delete',
          'categories',
          'category_create',
          'category_update',
          'category_delete',
        }.contains(action)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Unknown reference library kind/action',
      );
    }
    final allowed = {
      'kind',
      'action',
      if (action == 'query') ...{
        'query',
        'offset',
        'limit',
        'favorites_only',
        'category_id',
        'type',
      },
      if (action == 'read') ...{'offset', 'limit'},
      if ({'read', 'apply', 'export'}.contains(action)) ...{
        'id',
        'path',
        'child_index',
      },
      if (action == 'apply') ...{
        'expected_entry_version',
        'expected_draft_version',
      },
      if (action == 'import') ...{
        'path',
        'image_id',
        'name',
        if (kind == 'precise') ...{'type', 'strength', 'fidelity'},
      },
      if (action == 'save') ...{'index', 'name', 'expected_draft_version'},
      if (action == 'export') 'name',
      if ({'update', 'delete'}.contains(action)) ...{
        'id',
        'expected_entry_version',
      },
      if (action == 'update') ...{'changes', 'child_index'},
      if (action == 'categories') ...{'query', 'offset', 'limit'},
      if ({
        'category_create',
        'category_update',
        'category_delete',
      }.contains(action))
        'expected_category_version',
      if ({'category_update', 'category_delete'}.contains(action)) 'id',
      if ({'category_create', 'category_update'}.contains(action)) 'changes',
      if (action == 'category_delete') 'move_entries_to_parent',
    };
    if (p.keys.any((k) => !allowed.contains(k))) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Unexpected field for reference library action',
      );
    }
    final offset = p['offset'] ?? 0, limit = p['limit'] ?? 20;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 100 ||
        p['query'] != null &&
            (p['query'] is! String || (p['query'] as String).length > 300) ||
        p['favorites_only'] != null && p['favorites_only'] is! bool ||
        p['category_id'] != null && p['category_id'] is! String ||
        p['name'] != null &&
            (p['name'] is! String ||
                (p['name'] as String).trim().isEmpty ||
                (p['name'] as String).length > 160)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid reference library pagination/filter/name',
      );
    }
    final type = p['type'] == null
        ? PreciseRefType.characterAndStyle
        : PreciseRefType.values.asNameMap()[p['type']];
    if (type == null ||
        kind == 'precise' && p.containsKey('category_id') ||
        kind == 'vibe' && p.containsKey('type')) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid reference type/category',
      );
    }
    for (final k in ['strength', 'fidelity']) {
      if (p[k] != null && (p[k] is! num || !(p[k] as num).isFinite)) {
        throw const NaiAgentToolError(
          'invalid_reference',
          'Expected finite reference parameter',
        );
      }
    }
    if (action == 'categories' || (action as String).startsWith('category_')) {
      return _manageCategories(kind as String, action, p, token, offset, limit);
    }
    if (action == 'update' || action == 'delete') {
      return _manageEntry(kind as String, action, p, token);
    }
    if (action == 'query') {
      final query = (p['query'] as String? ?? '').toLowerCase();
      final rows = kind == 'vibe'
          ? (await vibes.getDisplayEntries()).map(_vibeEntry).toList()
          : (await precise.getAllEntries()).map(_preciseEntry).toList();
      _live(token);
      final found =
          rows
              .where(
                (e) =>
                    (p['favorites_only'] != true || e['favorite'] == true) &&
                    (!p.containsKey('category_id') ||
                        e['category_id'] == p['category_id']) &&
                    (!p.containsKey('type') || e['type'] == p['type']) &&
                    (query.isEmpty ||
                        '${e['name']} ${e['tags'] ?? ''}'
                            .toLowerCase()
                            .contains(query)),
              )
              .toList()
            ..sort(
              (a, b) => (b['created_at'] as String).compareTo(
                a['created_at'] as String,
              ),
            );
      return naiAgentTextResult({
        'kind': kind,
        'entries': found.skip(offset).take(limit).toList(),
        'total_count': found.length,
        'next_offset': offset + limit < found.length ? offset + limit : null,
        'entry_version_source': 'read',
        'total_source': 'local_library_index',
      });
    }
    if (action == 'save' || action == 'import') {
      _write(token);
      _ReferenceData data;
      final expected = p['expected_draft_version'];
      void checkDraft() {
        _write(token);
        if (action == 'save' &&
            (expected is! String ||
                readBridgeDraft(ref).acknowledgementVersion != expected)) {
          throw const NaiAgentToolError(
            'draft_conflict',
            'Read current draft_version before saving a reference',
          );
        }
      }

      checkDraft();
      if (action == 'save') {
        final image = ref.read(generationParamsNotifierProvider),
            index = p['index'];
        if (index != null && (index is! int || index < 0)) {
          throw const NaiAgentToolError(
            'invalid_reference',
            'Expected current reference index',
          );
        }
        if (kind == 'vibe') {
          if (index != null && index >= image.vibeReferencesV4.length) {
            throw const NaiAgentToolError(
              'invalid_reference',
              'Vibe index is out of range',
            );
          }
          final list = index == null
              ? image.vibeReferencesV4
              : [image.vibeReferencesV4[index as int]];
          _validateVibes(list);
          data = _ReferenceData(
            kind: kind,
            name: list.first.displayName,
            metadata: const {},
            vibes: list,
          );
        } else {
          if (index is! int || index >= image.preciseReferences.length) {
            throw const NaiAgentToolError(
              'invalid_reference',
              'Choose one current precise reference index',
            );
          }
          final value = image.preciseReferences[index];
          data = _ReferenceData(
            kind: kind,
            name: 'Precise reference',
            metadata: const {},
            image: value.image,
            precise: PreciseRefLibraryEntry.create(
              name: 'Reference',
              imagePath: '',
              type: value.type,
              strength: value.strength,
              fidelity: value.fidelity,
            ),
          );
        }
      } else if (p['image_id'] != null) {
        if (p.containsKey('path')) {
          throw const NaiAgentToolError(
            'invalid_reference',
            'Choose one import path or image_id',
          );
        }
        final image = await loadImage({'image_id': p['image_id']}, token);
        data = _ReferenceData(
          kind: kind,
          name: kind == 'precise' ? 'Precise reference' : 'Vibe reference',
          metadata: const {},
          image: kind == 'precise' ? image.bytes : null,
          vibes: kind == 'vibe'
              ? [
                  VibeReference(
                    displayName: (p['name'] as String?) ?? 'Vibe reference',
                    vibeEncoding: '',
                    rawImageData: image.bytes,
                    thumbnail: image.bytes,
                  ),
                ]
              : const [],
        );
      } else {
        if (p['path'] is! String || p.containsKey('image_id')) {
          throw const NaiAgentToolError(
            'invalid_reference',
            'Provide one workspace-relative import path',
          );
        }
        data = await _file(kind as String, p['path'] as String, token);
      }
      checkDraft();
      final name = (p['name'] as String?) ?? data.name;
      Map<String, dynamic> saved;
      // Additive native storage admission. Once admitted, its file/index commit
      // finishes without rolling back other user edits; no draft is written.
      if (kind == 'vibe') {
        final originalExtension = data.fileName == null
            ? null
            : path.extension(data.fileName!).toLowerCase();
        final entry =
            data.file != null &&
                {'.naiv4vibe', '.naiv4vibebundle'}.contains(originalExtension)
            ? await vibes.importOriginalVibeFile(
                data.file!,
                parsed: data.vibes,
                name: name,
                bundle: originalExtension == '.naiv4vibebundle',
              )
            : data.vibes.length == 1
            ? await vibes.saveEntry(
                VibeLibraryEntry.fromVibeReference(
                  name: name,
                  vibeData: data.vibes.single,
                ),
              )
            : await vibes.saveBundleEntry(data.vibes, name: name);
        saved = _vibeEntry(entry);
      } else {
        final entry = await precise.importFromBytes(
          data.image!,
          name: name,
          type: data.precise?.type ?? type,
          strength:
              data.precise?.strength ??
              (p['strength'] as num?)?.toDouble() ??
              1,
          fidelity:
              data.precise?.fidelity ??
              (p['fidelity'] as num?)?.toDouble() ??
              1,
        );
        saved = _preciseEntry(entry);
      }
      await _publish(kind as String);
      return naiAgentTextResult({
        'saved': saved,
        'draft_changed': false,
        'paid_encoding': false,
      });
    }
    if ((p['id'] == null) == (p['path'] == null) ||
        p['id'] != null && p['id'] is! String ||
        p['path'] != null && p['path'] is! String) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Provide one library id or workspace-relative path',
      );
    }
    Future<_ReferenceData> read() => p['id'] != null
        ? _entry(kind as String, p['id'] as String, token)
        : _file(kind as String, p['path'] as String, token);
    final data = await read();
    _live(token);
    final child = p['child_index'];
    if (child != null &&
        (kind != 'vibe' ||
            child is! int ||
            child < 0 ||
            child >= data.vibes.length)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid bundle child index',
      );
    }
    final selected = child == null ? data.vibes : [data.vibes[child as int]];
    Future<void> fresh() async {
      final current = await read();
      if (current.version != data.version) {
        throw const NaiAgentToolError(
          'entry_conflict',
          'Reference source changed; read it again',
        );
      }
    }

    if (action == 'read') {
      return naiAgentTextResult({
        ...data.metadata,
        'kind': kind,
        'name': data.name,
        'entry_version': data.version,
        'file_missing': data.fileMissing,
        'file_invalid': data.fileInvalid,
        'vibe_count': data.vibes.length,
        'vibes': [
          for (final i
              in child != null
                  ? [child as int]
                  : List.generate(
                      data.vibes.skip(offset).take(limit).length,
                      (i) => offset + i,
                    ))
            {
              'index': i,
              ..._vibe(data.vibes[i]),
              if (p['id'] != null) 'image_id': 'reference:vibe:${p['id']}:$i',
            },
        ],
        'next_offset': child == null && offset + limit < data.vibes.length
            ? offset + limit
            : null,
        if (data.image != null)
          'image': {
            'bytes': data.image!.length,
            'width': NaiResolutionAdapter.readImageSize(data.image!)?.$1,
            'height': NaiResolutionAdapter.readImageSize(data.image!)?.$2,
          },
      });
    }
    if (action == 'apply') {
      if (data.fileInvalid) {
        throw const NaiAgentToolError(
          'file_invalid',
          'The library file is damaged; repair or remove this entry',
        );
      }
      if (data.fileMissing) {
        throw const NaiAgentToolError(
          'file_missing',
          'The library file is missing; repair or remove this entry',
        );
      }
      final expected = p['expected_draft_version'];
      if (expected is! String) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Provide current draft_version',
        );
      }
      if (p['id'] != null && p['expected_entry_version'] != data.version) {
        throw const NaiAgentToolError(
          'entry_conflict',
          'Read library entry before applying its version',
        );
      }
      final vibeStorage = kind == 'vibe' && p['id'] != null ? vibes : null;
      final preciseStorage = kind == 'precise' && p['id'] != null
          ? precise
          : null;
      final result = await references.applyPrepared(
        vibes: kind == 'vibe' ? selected : null,
        preciseImage: data.image,
        preciseType: data.precise?.type ?? PreciseRefType.characterAndStyle,
        preciseStrength: data.precise?.strength ?? 1,
        preciseFidelity: data.precise?.fidelity ?? 1,
        expectedVersion: expected,
        token: token,
        checkSource: () => _live(token),
        refreshSource: fresh,
      );
      // Match native library use semantics, only after the draft was applied.
      if (p['id'] != null) {
        var recorded = false;
        try {
          recorded = kind == 'vibe'
              ? await vibeStorage!.incrementUsedCount(p['id'] as String) != null
              : await preciseStorage!.recordUsage(p['id'] as String) != null;
        } catch (_) {
          // Draft application already succeeded. A failed statistics write
          // must not make the model retry the completed application.
        }
        await _publish(kind as String);
        return naiAgentTextResult({
          ...result['details'] as Map<String, dynamic>,
          'library_usage_recorded': recorded,
        });
      }
      return result;
    }
    if (data.fileMissing) {
      throw const NaiAgentToolError(
        'file_missing',
        'The original library file is missing',
      );
    }
    if (data.fileInvalid && (child != null || data.file == null)) {
      throw const NaiAgentToolError(
        'file_invalid',
        'The reference file is damaged',
      );
    }
    _write(token);
    Uint8List output;
    String extension;
    if (kind == 'precise') {
      output = data.image!;
      extension = PreciseRefLibraryStorageService.detectImageExtension(output);
    } else if (data.file != null && child == null) {
      output = data.file!;
      extension = path.extension(data.fileName!);
    } else {
      output = Uint8List.fromList(
        utf8.encode(
          NovelAiVibeCodec.encodeJson(
            selected.length == 1
                ? NovelAiVibeCodec.buildSingleMap(selected.single)
                : NovelAiVibeCodec.buildBundleMap(selected),
          ),
        ),
      );
      extension = selected.length == 1 ? '.naiv4vibe' : '.naiv4vibebundle';
    }
    await fresh();
    _write(token);
    final base = ((p['name'] as String?) ?? data.name).replaceAll(
      RegExp(r'[\\/:*?"<>|\x00-\x1f]'),
      '_',
    );
    final outputPath = await files.export(
      '$base$extension',
      output,
      () => _write(token),
    );
    return naiAgentTextResult({
      'path': outputPath,
      'bytes': output.length,
      'kind': kind,
      'entry_version': data.version,
      'draft_changed': false,
      'paid_encoding': false,
    });
  }
}

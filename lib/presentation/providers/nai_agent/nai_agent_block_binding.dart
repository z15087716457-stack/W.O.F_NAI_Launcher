import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/block_tools.dart';
import '../../../core/utils/prompt_block_thumbnails.dart';
import '../../../core/utils/pill_document_editor.dart';
import '../../../core/utils/prompt_translation_language.dart';
import '../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../../data/models/prompt_block/pill_document.dart';
import '../../../data/models/prompt_block/prompt_block.dart';
import '../../../data/repositories/prompt_block_repository.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../../utils/prompt_block_bundle_insertion.dart';
import '../../utils/prompt_block_instance_bundle.dart';
import '../../wiring/blocks_preferences.dart';
import '../krita/bridge_draft_snapshot.dart';
import '../image_generation_provider.dart';
import '../pill_roll_coordinator.dart';
import '../pill_workspace_provider.dart';
import '../prompt_block_library_provider.dart';

part 'nai_agent_inline_blocks.dart';

const _instanceKeys = {
  'settings',
  'enabled',
  'locked',
  'evolutionEnabled',
  'content',
  'negative_content',
  'title',
  'color',
  'icon',
};
String _scope(Map<String, dynamic> params, BridgeDraftSnapshot draft) {
  final scope = params['scope'] ?? PillScopes.main;
  if (scope == PillScopes.main || scope == PillScopes.negative) {
    return scope as String;
  }
  final characters = draft.documents['characters'] as Map;
  final lanes = characters['lanes'] as Map;
  if (scope is String &&
      lanes.keys.any(
        (id) =>
            scope == PillScopes.charPos(id as String) ||
            scope == PillScopes.charNeg(id),
      )) {
    return scope;
  }
  throw const NaiAgentToolError(
    'invalid_scope',
    'Use main, negative or char:<current character ID>:pos/neg',
  );
}

PillDocument _document(BridgeDraftSnapshot draft, String scope) {
  if (scope == PillScopes.main || scope == PillScopes.negative) {
    return PillDocument.fromJson(
      Map<String, dynamic>.from(
        draft.documents[scope == PillScopes.main ? 'prompt' : 'negative_prompt']
            as Map,
      ),
    );
  }
  final match = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope)!;
  final lane = (draft.documents['characters'] as Map)['lanes'] as Map;
  return PillDocument.fromJson(
    Map<String, dynamic>.from(
      (lane[match[1]] as Map)[match[2] == 'pos' ? 'positive' : 'negative']
          as Map,
    ),
  );
}

Map<String, dynamic> _instanceChanges(Object? raw, {bool optional = false}) {
  if (raw == null && optional) return {};
  if (raw is! Map ||
      (raw.isEmpty && !optional) ||
      raw.keys.any((key) => !_instanceKeys.contains(key))) {
    throw const NaiAgentToolError(
      'invalid_instance',
      'Provide settings, enabled, locked or evolutionEnabled',
    );
  }
  final changes = Map<String, dynamic>.from(raw);
  _validateDisplay(changes);
  for (final key in ['content', 'negative_content']) {
    if (changes.containsKey(key) &&
        (changes[key] is! String || (changes[key] as String).length > 100000)) {
      throw NaiAgentToolError(
        'invalid_instance',
        'Expected content string: $key',
      );
    }
  }
  for (final key in ['enabled', 'locked', 'evolutionEnabled']) {
    if (changes.containsKey(key) && changes[key] is! bool) {
      throw NaiAgentToolError('invalid_instance', 'Expected boolean: $key');
    }
  }
  if (changes.containsKey('settings')) {
    final rawSettings = changes['settings'];
    final defaults = PillInstanceSettings.fixedDefault.toJson();
    if (rawSettings is! Map ||
        rawSettings.keys.any((k) => !defaults.containsKey(k))) {
      throw const NaiAgentToolError(
        'invalid_instance',
        'Unknown instance setting',
      );
    }
    for (final e in rawSettings.entries) {
      final d = defaults[e.key], v = e.value;
      final valid = switch (e.key) {
        'mode' => PillRollMode.values.asNameMap().containsKey(v),
        'order' => PillRollOrder.values.asNameMap().containsKey(v),
        _ when d is bool => v is bool,
        _ when d is int => v is int && v >= 0 && v <= 9999,
        _ =>
          v is num &&
              v.isFinite &&
              (e.key.toString().startsWith('weight')
                  ? v >= -3 && v <= 3
                  : v >= 0 && v <= 1),
      };
      if (!valid) {
        throw NaiAgentToolError(
          'invalid_instance',
          'Invalid instance setting: ${e.key}',
        );
      }
    }
  }
  return changes;
}

NaiAgentBlockTools bindNaiAgentBlocks(
  Ref ref,
  Directory workspace,
  bool Function() isBusy,
  bool Function() isAlive,
) {
  Future<void> recordUse(String id) async {
    try {
      await ref.read(blocksPreferencesProvider.notifier).recordUse(id);
    } catch (_) {
      // Recent-use persistence is best effort, never fail an applied insertion.
    }
  }

  Future<PromptBlockLibraryData> library() async {
    await ref.read(promptBlockLibraryNotifierProvider.future);
    // Read the repository again; another editor may have saved since the last
    // provider projection. Mutations still compare the row at its final write.
    return ref.read(promptBlockRepositoryProvider).load();
  }

  void validate(
    Map<String, dynamic> params,
    PromptBlock? block,
    BridgeDraftSnapshot draft,
  ) {
    final scope = _scope(params, draft),
        doc = _document(draft, _scope(params, draft));
    if (params['action'] == 'instance_create' ||
        params['action'] == 'instance_convert') {
      _inlinePlan(params, doc);
      return;
    }
    if (params['action'] == 'insert') {
      _insertionPosition(params, doc);
      if (block == null) {
        throw const NaiAgentToolError(
          'block_missing',
          'Read block_query again',
        );
      }
      return;
    }
    final marker = params['marker'];
    final instance = doc.instances[marker];
    if (marker is! String || instance == null || !doc.text.contains(marker)) {
      throw NaiAgentToolError(
        'instance_missing',
        'Read studio_context(scope=draft) for a current marker in $scope',
      );
    }
    _validateExisting(params, instance);
    final occurrence = params['occurrence'] ?? 0;
    if (occurrence is! int ||
        occurrence < 0 ||
        occurrence >= doc.text.split(marker).length - 1) {
      throw const NaiAgentToolError(
        'invalid_instance',
        'occurrence is a zero-based occurrence of marker',
      );
    }
  }

  return NaiAgentBlockTools(
    readLibrary: library,
    repository: ref.read(promptBlockRepositoryProvider),
    refresh: () => ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .refresh(preserveCurrent: true),
    readDraft: () => readBridgeDraft(ref),
    isBusy: isBusy,
    isAlive: isAlive,
    backup: (data, draft, affected) async {
      Map<String, dynamic>? thumbnail;
      final path = affected?.thumbnail;
      if (path != null && path.isNotEmpty && await File(path).exists()) {
        final file = File(path);
        if (await file.length() > 64 * 1024 * 1024) {
          throw const FormatException('Block thumbnail exceeds backup limit');
        }
        thumbnail = {
          'path': path,
          'data_base64': base64Encode(await file.readAsBytes()),
        };
      }
      return (await AgentSnapshotFiles(
            workspace,
          ).save('Before block operation', {
            'kind': 'block_library',
            'blocks': data.blocks.map((b) => b.toJson()).toList(),
            'folders': data.folders.map((b) => b.toJson()).toList(),
            'collections': data.collections.map((b) => b.toJson()).toList(),
            'draft': draft.toJson(),
            if (thumbnail != null) 'affected_thumbnail': thumbnail,
          }, backup: true))['path']
          as String;
    },
    afterDelete: (block) => deletePromptBlockThumbnail(block.thumbnail),
    validateInstance: validate,
    promoteInstance: (params, check) async {
      final draft = readBridgeDraft(ref);
      validate(params, null, draft);
      final scope = _scope(params, draft);
      final scopes = _affectedScopes(params, draft, scope);
      for (final key in scopes) {
        if (!ref.exists(pillWorkspaceProvider(key))) {
          ref
              .read(pillWorkspaceProvider(key).notifier)
              .restoreDocument(_document(draft, key));
        }
      }
      final changes = Map<String, dynamic>.from(
        params['changes'] as Map? ?? {},
      );
      final created = await ref
          .read(pillWorkspaceProvider(scope).notifier)
          .saveTempAsNewBlock(
            params['marker'] as String,
            title: changes['title'] as String?,
            folderId: changes['folderId'] as String?,
            color: changes['color'] as String?,
            iconName: changes['iconName'] as String?,
            beforeWrite: check,
          );
      return {
        'action': 'instance_promote',
        'id': created!.id,
        'version': naiAgentBlockVersion(created),
        'block': naiAgentBlockResult(created, full: true),
        'lanes': _readback(ref, scopes, const {}),
      };
    },
    editInstance: (params, block) {
      final draft = readBridgeDraft(ref);
      validate(params, block, draft);
      final scope = _scope(params, draft);
      final scopes = <String>{scope};
      if (params['action'] == 'insert' && block!.negativeContent.isNotEmpty) {
        scopes.clear();
        if (scope == PillScopes.main || scope == PillScopes.negative) {
          scopes.add(PillScopes.negative);
          if (block.content.isNotEmpty) scopes.add(PillScopes.main);
        } else {
          final match = RegExp(r'^char:(.+):(pos|neg)$').firstMatch(scope)!;
          scopes.add(PillScopes.charNeg(match[1]!));
          if (block.content.isNotEmpty) {
            scopes.add(PillScopes.charPos(match[1]!));
          }
        }
      }
      if (params['action'] != 'insert') {
        scopes.addAll(_affectedScopes(params, draft, scope));
      }
      final priorMarkers = <String, Set<String>>{};
      // Lazily opened editors must start with their real saved document.
      // Everything here is synchronous after the backup/version check.
      for (final key in scopes) {
        final provider = pillWorkspaceProvider(key);
        final doc = _document(draft, key);
        priorMarkers[key] = doc.instances.keys.toSet();
        if (!ref.exists(provider) &&
            params['action'] != 'instance_create' &&
            params['action'] != 'instance_convert') {
          ref.read(provider.notifier).restoreDocument(doc);
        }
      }
      String? createdMarker;
      List<String>? convertedMarkers;
      void edit() {
        if (params['action'] == 'instance_create' ||
            params['action'] == 'instance_convert') {
          final markers = _applyInline(
            ref,
            params,
            scope,
            _document(draft, scope),
            _draftProjection(draft, scope),
          );
          if (params.containsKey('segments')) {
            convertedMarkers = markers;
          } else {
            createdMarker = markers.single;
          }
        } else if (params['action'] == 'instance_unwrap' ||
            params['action'] == 'instance_delete') {
          _removeInline(ref, params, scope);
        } else if (params['action'] == 'insert') {
          // An omitted offset means append a tag block, rather than concatenate
          // its projection directly onto the final handwritten tag.
          for (final key in scopes) {
            if (key == scope &&
                (params['offset'] != null || params['anchor'] != null)) {
              continue;
            }
            final provider = pillWorkspaceProvider(key);
            final doc = ref.read(provider).document;
            final tail = doc.text.trimRight();
            if (tail.isNotEmpty && !tail.endsWith(',')) {
              ref.read(provider.notifier).setText('${doc.text}, ');
            }
          }
          insertPromptBlockBundleWithReader(
            ref.read,
            scope: scope,
            offset: _insertionPosition(
              params,
              scopes.contains(scope)
                  ? ref.read(pillWorkspaceProvider(scope)).document
                  : _document(draft, scope),
            ),
            blockId: block!.id,
          );
        } else {
          final lane = ref.read(pillWorkspaceProvider(scope).notifier);
          var marker = params['marker'] as String;
          final changes = _instanceChanges(
            params['instance'],
            optional: params['translation'] != null,
          );
          if (changes.containsKey('content') ||
              changes.containsKey('negative_content') ||
              _hasDisplay(changes)) {
            final original = ref
                .read(pillWorkspaceProvider(scope))
                .document
                .instances[marker]!;
            final bundle = readPromptBlockInstanceBundleWithReader(
              ref.read,
              scope,
              marker,
            );
            final positive = bundle.positive;
            final positiveContent = original.useNegativeContent
                ? positive == null
                      ? ''
                      : ref
                            .read(
                              pillWorkspaceProvider(positive.scope).notifier,
                            )
                            .contentForMarker(positive.marker)
                : lane.contentForMarker(marker);
            marker = lane.editTempContent(
              marker,
              changes['content'] as String? ?? positiveContent,
              changes['negative_content'] as String?,
              occurrence: params['occurrence'] as int? ?? 0,
              editedBy: 'agent',
              title: changes['title'] as String?,
              color: changes['color'] as String?,
              iconName: changes['icon'] as String?,
            );
          }
          if (params['translation'] != null) {
            marker = lane.isolateMarkerOccurrence(
              marker,
              occurrence: params['occurrence'] as int? ?? 0,
            );
            final original = ref
                .read(pillWorkspaceProvider(scope))
                .document
                .instances[marker]!
                .translation!;
            lane.updateTranslation(
              marker,
              _translation(params['translation'], original: original),
            );
          }
          var current = ref
              .read(pillWorkspaceProvider(scope))
              .document
              .instances[marker]!;
          if (changes['locked'] == false && current.locked) {
            lane.toggleLocked(marker);
          }
          if (changes['settings'] case final Map settings) {
            current = ref
                .read(pillWorkspaceProvider(scope))
                .document
                .instances[marker]!;
            lane.updateInstanceSettings(
              marker,
              PillInstanceSettings.fromJson({
                ...current.settings.toJson(),
                ...Map<String, dynamic>.from(settings),
              }),
            );
          }
          current = ref
              .read(pillWorkspaceProvider(scope))
              .document
              .instances[marker]!;
          if (changes['enabled'] case final bool enabled) {
            if (current.enabled != enabled) lane.toggleEnabled(marker);
          }
          current = ref
              .read(pillWorkspaceProvider(scope))
              .document
              .instances[marker]!;
          if (changes['locked'] case final bool locked) {
            if (current.locked != locked) lane.toggleLocked(marker);
          }
          current = ref
              .read(pillWorkspaceProvider(scope))
              .document
              .instances[marker]!;
          if (changes['evolutionEnabled'] case final bool evolution) {
            if (current.evolutionEnabled != evolution) {
              lane.toggleEvolution(marker);
            }
          }
        }
      }

      void grouped(int index) {
        if (index == scopes.length) {
          edit();
          return;
        }
        ref
            .read(pillWorkspaceProvider(scopes.elementAt(index)).notifier)
            .editAsSingleStep(() => grouped(index + 1));
      }

      // Inline conversions already commit one document and enforce their
      // projection postcondition before recording that single history step.
      if (params['action'] == 'instance_convert' ||
          params['action'] == 'instance_create') {
        edit();
      } else {
        grouped(0);
      }
      final result = _readback(ref, scopes, priorMarkers);
      if (params['action'] == 'insert') {
        unawaited(recordUse(block!.id));
      }
      return {
        'action': params['action'],
        'lanes': result,
        if (createdMarker != null) 'marker': createdMarker,
        if (convertedMarkers != null) 'markers': convertedMarkers,
      };
    },
  );
}

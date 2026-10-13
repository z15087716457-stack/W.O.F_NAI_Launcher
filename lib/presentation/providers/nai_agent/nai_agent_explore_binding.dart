import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/block_organization_tools.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/style_explore/explore_run.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../image_generation_provider.dart';
import '../krita/bridge_draft_snapshot.dart';
import '../pill_workspace_provider.dart';
import '../prompt_block_library_provider.dart';
import '../style_explore/explore_run_provider.dart';
import '../style_explore/explore_run_runner.dart';
import 'nai_agent_generation_binding.dart';

String naiAgentExploreVersion(ExploreRun run) => sha256
    .convert(utf8.encode(jsonEncode(run.toJson()..remove('updatedAt'))))
    .toString();

class NaiAgentExploreBinding {
  NaiAgentExploreBinding(
    this.ref,
    this.workspace,
    this.busy,
    this.alive, {
    this.owner,
  }) {
    if (owner != null) {
      final base = bindNaiAgentGeneration(ref, workspace, owner!, busy, alive);
      generation = NaiAgentGenerationTools(
        isAlive: alive,
        readInput: (params) {
          final run = _quotedRun(params);
          final mode = params['mode'] ?? 'basic';
          final count = switch (mode) {
            'deep' => params['count'] as int,
            'retry' => run.pendingCandidates.length + run.failedCount,
            _ =>
              run.pendingCandidates.isEmpty
                  ? run.targetCount
                  : run.pendingCandidates.length,
          };
          if (count < 1 || count > 999) {
            throw const NaiAgentToolError(
              'invalid_count',
              'Quote requires 1 to 999 candidates',
            );
          }
          final input = base.readInput({
            'requests': count,
            'images_per_request': 1,
          });
          return NaiAgentGenerationInput(
            raw: input.raw,
            effective: input.effective,
            batchSize: 1,
            draftVersion: input.draftVersion,
            billing: input.billing,
            accountId: input.accountId,
            accountName: input.accountName,
            endpoint: input.endpoint,
            promptContextVersion: _libraryVersion(),
            sourceOperation: 'explore',
            sourceImageId: run.id,
            workflowGuard: jsonEncode({
              'version': naiAgentExploreVersion(run),
              'mode': mode,
              'family_id': params['family_id'],
              'parent_set_id': params['parent_set_id'],
              'documents': _documentsVersion(),
            }),
            blockedReason: input.raw.action != ImageGenerationAction.generate
                ? 'explore_requires_generate_mode'
                : input.blockedReason,
          );
        },
        approve: base.approve,
        backup: (input) =>
            _backup(_find(input.sourceImageId!), 'explore_generation'),
        start: (input) {
          final config = jsonDecode(input.workflowGuard as String) as Map;
          final runner = ref.read(exploreRunRunnerProvider.notifier);
          final previousDone = {
            for (final c in _find(input.sourceImageId!).candidates)
              if (c.generation.status == ExploreCandidateGenerationStatus.done)
                c.id,
          };
          void beforeGenerate(ImageParams params) {
            if (!alive()) {
              throw const NaiAgentToolError('closed', 'Explore owner closed');
            }
            if (ref.read(imageGenerationNotifierProvider).isGenerating) {
              throw const NaiAgentToolError(
                'busy',
                'Another generation owns the native pipeline',
              );
            }
            final current = base.readInput({
              'requests': 1,
              'images_per_request': 1,
            });
            if (current.accountId != input.accountId ||
                current.endpoint != input.endpoint ||
                _libraryVersion() != input.promptContextVersion ||
                _documentsVersion() != config['documents'] ||
                current.raw.copyWith(
                      prompt: '',
                      negativePrompt: '',
                      seed: -1,
                      nSamples: 1,
                    ) !=
                    input.raw.copyWith(
                      prompt: '',
                      negativePrompt: '',
                      seed: -1,
                      nSamples: 1,
                    )) {
              throw const NaiAgentToolError(
                'explore_changed',
                'Settings, recipe or account changed; stopped before the next request',
              );
            }
            if ((current.billing['per_request_anlas'] as num) >
                    (input.billing['per_request_anlas'] as num) ||
                current.balance == null ||
                current.balance! < current.estimate) {
              throw const NaiAgentToolError(
                'insufficient_balance',
                'Insufficient balance for next candidate',
              );
            }
          }

          final Future<bool> completion = switch (config['mode']) {
            'deep' => runner.startDeepRound(
              input.sourceImageId!,
              familyId: config['family_id'] as String,
              parentSetId: config['parent_set_id'] as String,
              count: input.raw.nSamples,
              beforeGenerate: beforeGenerate,
            ),
            'retry' => runner.retryFailed(
              input.sourceImageId!,
              beforeGenerate: beforeGenerate,
            ),
            _ => runner.start(
              input.sourceImageId!,
              beforeGenerate: beforeGenerate,
            ),
          };
          final session = runner.activeSessionId;
          if (session == null) return null;
          _ownedSession = session;
          _ownedRun = input.sourceImageId;
          return NaiAgentGenerationRun(
            id: session,
            cancel: () => runner.cancelOwned(session),
            completion: completion.then((started) async {
              final run = await ref
                  .read(styleExploreRunRepositoryProvider)
                  .getRun(input.sourceImageId!);
              final produced =
                  run?.candidates
                      .where(
                        (c) =>
                            c.generation.status ==
                                ExploreCandidateGenerationStatus.done &&
                            !previousDone.contains(c.id),
                      )
                      .toList() ??
                  <ExploreCandidate>[];
              return {
                'status': started ? run?.status.name : 'not_started',
                'explore_id': input.sourceImageId,
                'done_count': run?.generatedCount,
                'failed_count': run?.failedCount,
                'new_image_count': produced.length,
                'candidates_truncated': produced.length > 100,
                'candidates': [
                  for (final c in produced.take(100))
                    {
                      'id': c.id,
                      'image_id': 'explore:${run!.id}:${c.id}',
                      'file_path': c.generation.filePath,
                      'seed': c.generation.seed,
                    },
                ],
              };
            }),
          );
        },
      );
    }
  }

  final Ref ref;
  final Directory workspace;
  final bool Function() busy, alive;
  final NaiAgentConversationOwner? owner;
  NaiAgentGenerationTools? generation;
  String? _ownedSession, _ownedRun;

  String _libraryVersion() => naiAgentBlockLibraryVersion(
    ref.read(promptBlockRepositoryProvider).currentLibrary,
  );
  String _documentsVersion() {
    Object? stable(Object? value) {
      if (value is Map) {
        return {
          for (final e in value.entries)
            if (!{
              'currentRoll',
              'lastRollCount',
              'sequenceCursor',
            }.contains(e.key))
              e.key: stable(e.value),
        };
      }
      if (value is List) return value.map(stable).toList();
      return value;
    }

    return jsonEncode(stable(readBridgeDraft(ref).documents));
  }

  void _check(NaiAgentCancellation token, {bool writing = false}) {
    token.check();
    if (!alive()) {
      throw const NaiAgentToolError('closed', 'Explore binding closed');
    }
    if (writing && busy()) {
      throw const NaiAgentToolError('busy', 'Studio is generating');
    }
  }

  ExploreRun _find(String id) =>
      ref.read(styleExploreRunRepositoryProvider).currentRun(id) ??
      (throw const NaiAgentToolError(
        'explore_missing',
        'Read explore_manage(action=list) again',
      ));
  ExploreRun _quotedRun(Map<String, dynamic> params) {
    final id = params['id'];
    if (id is! String) {
      throw const NaiAgentToolError('invalid_id', 'Provide an exploration id');
    }
    final run = _find(id);
    if (params['expected_version'] != naiAgentExploreVersion(run)) {
      throw const NaiAgentToolError(
        'explore_conflict',
        'Read the exploration again',
      );
    }
    final mode = params['mode'] ?? 'basic';
    if (!{'basic', 'retry', 'deep'}.contains(mode) ||
        !{
          ExploreRunStatus.draft,
          ExploreRunStatus.paused,
          ExploreRunStatus.generated,
          if (mode == 'deep') ExploreRunStatus.completed,
        }.contains(run.status)) {
      throw const NaiAgentToolError(
        'invalid_state',
        'Exploration cannot start in this mode/state',
      );
    }
    if (mode == 'retry' && run.failedCount == 0) {
      throw const NaiAgentToolError(
        'invalid_state',
        'There are no failed candidates to retry',
      );
    }
    if (mode == 'deep') {
      final count = params['count'];
      final family = run.families
          .where((v) => v.id == params['family_id'])
          .firstOrNull;
      final parents = run.parentSets
          .where((v) => v.id == params['parent_set_id'])
          .firstOrNull;
      if (count is! int ||
          count < 1 ||
          count > 999 ||
          family == null ||
          parents == null ||
          parents.familyId != family.id ||
          parents.parents.isEmpty ||
          run.pendingCandidates.isNotEmpty) {
        throw const NaiAgentToolError(
          'invalid_parents',
          'Use an existing family/parent set and count 1..999',
        );
      }
    }
    return run;
  }

  Map<String, dynamic> _candidate(ExploreRun run, ExploreCandidate c) => {
    ...Map<String, dynamic>.from(jsonDecode(jsonEncode(c.toJson())) as Map),
    'image_id': c.generation.filePath == null
        ? null
        : 'explore:${run.id}:${c.id}',
  };
  Future<String> _backup(ExploreRun? run, String kind) async =>
      (await AgentSnapshotFiles(
            workspace,
          ).save('Before exploration operation', {
            'kind': kind,
            if (run != null) 'run': run.toJson(),
            'draft': readBridgeDraft(ref).toJson(),
          }, backup: true))['path']
          as String;

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    await ref.read(promptBlockLibraryNotifierProvider.future);
    await ref.read(exploreRunListNotifierProvider.future);
    // Refresh the native list from current storage without initializing a runner.
    await ref.read(exploreRunListNotifierProvider.notifier).refresh();
    _check(token);
    final action = params['action'];
    final offset = params['offset'] ?? 0, limit = params['limit'] ?? 20;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 100) {
      throw const NaiAgentToolError(
        'invalid_page',
        'Use offset >= 0 and limit 1..100',
      );
    }
    final list = ref.read(exploreRunListNotifierProvider).requireValue.runs;
    if (action == 'list') {
      return naiAgentTextResult({
        'runs': [
          for (final run in list.skip(offset).take(limit))
            {
              'id': run.id,
              'name': run.name,
              'version': naiAgentExploreVersion(run),
              'status': run.status.name,
              'target_count': run.targetCount,
              'done_count': run.generatedCount,
              'failed_count': run.failedCount,
            },
        ],
        'total': list.length,
      });
    }
    if (action == 'create') {
      _check(token, writing: true);
      final draft = readBridgeDraft(ref);
      if (params['expected_draft_version'] != draft.acknowledgementVersion) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Read studio_context(scope=draft) again',
        );
      }
      final name = _name(params['name']);
      final count = params['count'];
      if (count is! int || count < 1 || count > 999) {
        throw const NaiAgentToolError('invalid_count', 'Use 1..999 candidates');
      }
      final positive = ref
          .read(pillWorkspaceProvider(PillScopes.main))
          .document;
      final negative = ref
          .read(pillWorkspaceProvider(PillScopes.negative))
          .document;
      final image = ref.read(generationParamsNotifierProvider);
      final path = await _backup(null, 'explore_create');
      final run = await ref
          .read(styleExploreRunRepositoryProvider)
          .create(
            name: name,
            recipeSnapshot: ExploreRecipeSnapshot(
              positive: positive,
              negative: negative,
            ),
            paramsSnapshot: ExploreParamsSnapshot.fromImageParams(image),
            targetCount: count,
            beforeWrite: () {
              _check(token, writing: true);
              if (readBridgeDraft(ref).acknowledgementVersion !=
                  draft.acknowledgementVersion) {
                throw const NaiAgentToolError(
                  'draft_conflict',
                  'Draft changed during backup',
                );
              }
            },
          );
      await ref.read(exploreRunListNotifierProvider.notifier).refresh();
      return naiAgentTextResult({
        'id': run.id,
        'version': naiAgentExploreVersion(run),
        'backup_path': path,
      });
    }
    if (action == 'run') {
      final tools = generation;
      if (tools == null) {
        throw const NaiAgentToolError(
          'owner_missing',
          'Generation requires an Agent conversation',
        );
      }
      return tools.run(params, token);
    }
    final id = params['id'];
    if (id is! String) {
      throw const NaiAgentToolError('invalid_id', 'Provide exploration id');
    }
    final run = _find(id);
    if (action == 'read') {
      return naiAgentTextResult({
        'run': {
          ...run.toJson(),
          'candidates': [
            for (final c in run.candidates.skip(offset).take(limit))
              _candidate(run, c),
          ],
        },
        'version': naiAgentExploreVersion(run),
        'candidate_count': run.candidates.length,
        'next_offset': offset + limit < run.candidates.length
            ? offset + limit
            : null,
        'execution_parameters':
            'Native runner uses current Studio parameters and live block recipe; stored snapshots document creation.',
      });
    }
    if (action == 'status') {
      final state = ref.exists(exploreRunRunnerProvider)
          ? ref.read(exploreRunRunnerProvider)
          : null;
      return naiAgentTextResult({
        'id': id,
        'status': run.status.name,
        'running': state?.runId == id && state!.isRunning,
        'processed_count': state?.runId == id ? state!.processedCount : 0,
        'total_count': state?.runId == id ? state!.totalCount : 0,
        'owned':
            _ownedRun == id &&
            _ownedSession != null &&
            ref.exists(exploreRunRunnerProvider) &&
            ref.read(exploreRunRunnerProvider.notifier).activeSessionId ==
                _ownedSession,
      });
    }
    if (action == 'prepare') {
      final tools = generation;
      if (tools == null) {
        throw const NaiAgentToolError(
          'owner_missing',
          'Generation requires an Agent conversation',
        );
      }
      // Initializing the native runner first lets its interruption recovery finish.
      ref.read(exploreRunRunnerProvider);
      await ref.read(exploreRunRunnerProvider.notifier).ready;
      await ref.read(exploreRunListNotifierProvider.notifier).refresh();
      _check(token);
      return tools.prepare(params, token);
    }
    if (action == 'pause' || action == 'cancel') {
      if (_ownedRun != id ||
          _ownedSession == null ||
          !ref.exists(exploreRunRunnerProvider)) {
        throw const NaiAgentToolError(
          'run_not_owned',
          'This conversation does not own this exploration',
        );
      }
      final runner = ref.read(exploreRunRunnerProvider.notifier);
      final accepted = action == 'pause'
          ? runner.pauseOwned(_ownedSession!)
          : runner.cancelOwned(_ownedSession!);
      return naiAgentTextResult({
        'id': id,
        'status': accepted
            ? (action == 'pause' ? 'pausing' : 'cancelling')
            : 'already_finished',
      });
    }
    const edits = {
      'rename',
      'complete',
      'heart',
      'folder_create',
      'folder_rename',
      'folder_delete',
      'candidate_move',
    };
    if (!edits.contains(action)) {
      throw const NaiAgentToolError(
        'invalid_action',
        'Unsupported exploration action',
      );
    }
    _check(token, writing: true);
    final version = naiAgentExploreVersion(run);
    if (params['expected_version'] != version) {
      throw const NaiAgentToolError(
        'explore_conflict',
        'Read the exploration again',
      );
    }
    final name = {'rename', 'folder_create', 'folder_rename'}.contains(action)
        ? _name(params['name'])
        : null;
    final folderId = params['folder_id'], candidateId = params['candidate_id'];
    if (action == 'heart' && params['heart'] is! bool) {
      throw const NaiAgentToolError('invalid_heart', 'Provide heart boolean');
    }
    if ((action == 'heart' || action == 'candidate_move') &&
        run.candidateById(candidateId as String? ?? '') == null) {
      throw const NaiAgentToolError(
        'candidate_missing',
        'Read the exploration again',
      );
    }
    if ((action == 'folder_rename' ||
            action == 'folder_delete' ||
            (action == 'candidate_move' && folderId != null)) &&
        (folderId is! String || run.folderById(folderId) == null)) {
      throw const NaiAgentToolError(
        'folder_missing',
        'Read exploration folders again',
      );
    }
    if (action == 'candidate_move' && !params.containsKey('folder_id')) {
      throw const NaiAgentToolError(
        'folder_missing',
        'Provide folder_id (null means unfiled)',
      );
    }
    final path = await _backup(run, 'explore_edit');
    final folder = action == 'folder_create'
        ? ExploreCandidateFolder(
            id: const Uuid().v4(),
            name: name!,
            createdAt: DateTime.now(),
          )
        : null;
    if ((action == 'folder_create' || action == 'folder_rename') &&
        run.folders.any((f) => f.name == name && f.id != folderId)) {
      throw const NaiAgentToolError(
        'duplicate_folder',
        'Exploration folder name already exists',
      );
    }
    final updated = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .transform(id, (latest) {
          _check(token, writing: true);
          if (naiAgentExploreVersion(latest) != version) {
            throw const NaiAgentToolError(
              'explore_conflict',
              'Exploration changed during backup',
            );
          }
          return switch (action) {
            'rename' => latest.copyWith(name: name!),
            'complete' => latest.copyWith(status: ExploreRunStatus.completed),
            'heart' => latest.copyWith(
              candidates: [
                for (final c in latest.candidates)
                  c.id == candidateId
                      ? c.copyWith(
                          review: c.review.copyWith(
                            heart: params['heart'] as bool,
                          ),
                        )
                      : c,
              ],
            ),
            'folder_create' => latest.copyWith(
              folders: [...latest.folders, folder!],
            ),
            'folder_rename' => latest.copyWith(
              folders: [
                for (final f in latest.folders)
                  f.id == folderId ? f.copyWith(name: name!) : f,
              ],
            ),
            'folder_delete' => latest.copyWith(
              folders: latest.folders.where((f) => f.id != folderId).toList(),
              candidates: [
                for (final c in latest.candidates)
                  c.folderId == folderId ? c.copyWith(folderId: null) : c,
              ],
            ),
            _ => latest.copyWith(
              candidates: [
                for (final c in latest.candidates)
                  c.id == candidateId
                      ? c.copyWith(folderId: folderId as String?)
                      : c,
              ],
            ),
          };
        });
    return naiAgentTextResult({
      'id': id,
      'version': naiAgentExploreVersion(updated),
      'backup_path': path,
      if (folder != null) 'folder_id': folder.id,
    });
  }

  String _name(Object? value) {
    if (value is! String || value.trim().isEmpty || value.length > 200) {
      throw const NaiAgentToolError(
        'invalid_name',
        'Use a name of 1 to 200 characters',
      );
    }
    return value.trim();
  }

  Future<NaiAgentImage?> loadImage(
    String id,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final parts = id.split(':');
    if (parts.length != 3) {
      throw const NaiAgentToolError(
        'invalid_image',
        'Use an image_id returned by exploration read',
      );
    }
    final run = await ref
        .read(styleExploreRunRepositoryProvider)
        .getRun(parts[1]);
    final candidate = run?.candidateById(parts[2]);
    final path = candidate?.generation.filePath;
    if (path == null || !await File(path).exists()) return null;
    final file = File(path);
    if (await file.length() > 16 * 1024 * 1024) {
      throw const NaiAgentToolError(
        'image_too_large',
        'Explore image exceeds read limit',
      );
    }
    final bytes = await file.readAsBytes();
    _check(token);
    return NaiAgentImage(
      id: id,
      bytes: bytes,
      metadata: {
        'explore_id': run!.id,
        'candidate_id': candidate!.id,
        'seed': candidate.generation.seed,
        'roll_snapshot': candidate.rollSnapshot?.toJson(),
      },
    );
  }
}

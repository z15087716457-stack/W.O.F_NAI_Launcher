import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:path/path.dart' as p;

import '../../../core/nai_agent/attachment_manifest.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../ui/agent/agent_contract.dart';
import 'agent_param_diff.dart';
import 'agent_resources.dart';
import 'agent_settings_card.dart';
import 'agent_gallery_card.dart';
import 'agent_tag_hits.dart';

Map<String, dynamic> agentMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> agentMaps(Object? value) =>
    value is List ? value.whereType<Map>().map(agentMap).toList() : [];
int? agentInt(Object? value) => (value is num) ? value.toInt() : null;
Duration? agentDuration(Object? value) =>
    value is num ? Duration(milliseconds: value.toInt()) : null;
String agentToolName(String name) =>
    name.replaceFirst(RegExp(r'^mcp__nai_studio__'), '');
String agentMessageText(Map<String, dynamic> message) =>
    message['content'] is String
    ? message['content'] as String
    : agentMaps(message['content'])
          .where((p) => p['type'] == 'text')
          .map((p) => p['text'] ?? '')
          .join('\n');

/// Pretty, UTF-8 bounded tool detail, with image/binary payloads removed before
/// formatting (including nested MCP envelopes).
String? agentPretty(Object? value) {
  if (value == null) return null;
  Object? redact(Object? item) {
    if (item is Map) {
      return {
        for (final e in item.entries)
          e.key.toString():
              ([
                    'data',
                    'bytes',
                    'base64',
                    'image_base64',
                    'imageBytes',
                    'image',
                    'image_data',
                  ].contains(e.key) ||
                  e.value is List<int>)
              ? '[redacted]'
              : redact(e.value),
      };
    }
    if (item is List) return item.map(redact).toList();
    if (item is String &&
        (item.startsWith('data:image/') || item.length > 8192)) {
      return '[redacted]';
    }
    return item;
  }

  final text = const JsonEncoder.withIndent('  ').convert(redact(value));
  final bytes = utf8.encode(text);
  if (bytes.length <= 4096) return text;
  return '${utf8.decode(bytes.take(4090).toList(), allowMalformed: true)}…';
}

Map<String, dynamic> agentResultDetails(Map<String, dynamic> value) {
  if (value['structuredContent'] is Map) {
    return agentMap(value['structuredContent']);
  }
  if (value['details'] is Map) {
    final details = agentMap(value['details']);
    return details['structuredContent'] is Map
        ? agentMap(details['structuredContent'])
        : details;
  }
  // Some MCP transports retain only the text content envelope in history.
  for (final part in agentMaps(value['content'])) {
    if (part['type'] != 'text' || part['text'] is! String) continue;
    try {
      final decoded = jsonDecode(part['text'] as String);
      if (decoded is Map) return agentMap(decoded);
    } on FormatException {
      // Ordinary text is not a structured tool result.
    }
  }
  return {};
}

List<AgentDiffSegment> agentTagDiff(String before, String after) {
  List<String> tags(String value) =>
      value.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  final old = tags(before), next = tags(after);
  // LCS retains duplicate tags and ordering, unlike a set difference. Bound
  // quadratic work for unusually large fields and fall back to whole text.
  if (old.length * next.length > 250000) {
    return [
      if (before.isNotEmpty) AgentDiffSegment(before, AgentDiffKind.removed),
      if (after.isNotEmpty) AgentDiffSegment(after, AgentDiffKind.added),
    ];
  }
  final table = List.generate(
    old.length + 1,
    (_) => List.filled(next.length + 1, 0),
  );
  for (var i = old.length - 1; i >= 0; i--) {
    for (var j = next.length - 1; j >= 0; j--) {
      table[i][j] = old[i] == next[j]
          ? 1 + table[i + 1][j + 1]
          : (table[i + 1][j] > table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
    }
  }
  final result = <AgentDiffSegment>[];
  var i = 0, j = 0;
  void add(String text, AgentDiffKind kind) =>
      result.add(AgentDiffSegment('${result.isEmpty ? '' : ', '}$text', kind));
  while (i < old.length || j < next.length) {
    if (i < old.length && j < next.length && old[i] == next[j]) {
      add(next[j++], AgentDiffKind.same);
      i++;
    } else if (i < old.length &&
        (j == next.length || table[i + 1][j] >= table[i][j + 1])) {
      add(old[i++], AgentDiffKind.removed);
    } else {
      add(next[j++], AgentDiffKind.added);
    }
  }
  return result;
}

/// Kept outside the UI so a stale / fabricated diff cannot write draft data.
class AgentDiffRestore {
  const AgentDiffRestore({
    required this.id,
    required this.version,
    required this.backup,
    required this.field,
    this.characterId,
    this.characterIndex,
    this.params = const [],
  });
  final String id, version, field;
  final Map<String, dynamic> backup;
  final String? characterId;
  final int? characterIndex;

  /// 参数卡（[field] == `params`）要写回的草稿键。
  final List<String> params;
}

class AgentThreadMapping {
  const AgentThreadMapping(
    this.turns,
    this.shelf,
    this.images,
    this.files,
    this.diffs, {
    this.estimatedAnlas,
    this.settings = const {},
    this.gallery = const {},
  });
  final List<AgentTurn> turns;
  final AgentShelfData shelf;
  final Map<String, AgentImage> images;
  final Map<String, String> files;
  final Map<String, AgentDiffRestore> diffs;
  final int? estimatedAnlas;
  final Map<String, AgentSettingsRestore> settings;
  final Map<String, AgentGalleryRestore> gallery;
}

/// Resolve UI image ids against this entry's exact content-part positions.
/// No string parsing: foreign-entry ids, stale ids and duplicates are rejected.
List<int>? agentUserImagePartIndexes(
  AgentChatRuntime runtime,
  String entryId,
  List<String> keepImages,
) {
  final message = runtime.userMessageForEntry(entryId);
  if (message == null || keepImages.toSet().length != keepImages.length) {
    return null;
  }
  final mi = runtime.messages.indexOf(message);
  final ids = <String, int>{
    for (final (pi, part) in agentMaps(message['content']).indexed)
      if (part['type'] == 'image') '${runtime.chat.id}/turn/$mi/user/$pi': pi,
  };
  if (keepImages.any((id) => !ids.containsKey(id))) return null;
  final keep = keepImages.toSet();
  return [
    for (final e in ids.entries)
      if (keep.contains(e.key)) e.value,
  ];
}

class AgentThreadMapper {
  AgentThreadMapper(this.resources);
  final AgentResources resources;
  final undone = <String>{};

  AgentThreadMapping map(
    AgentChatRuntime runtime, {
    String? draftVersion,
    bool waitingUser = false,
    Map<String, Object?>? preferences,
  }) {
    final turns = <AgentTurn>[];
    final images = <String, AgentImage>{};
    final files = <String, String>{};
    final diffs = <String, AgentDiffRestore>{};
    final settings = <String, AgentSettingsRestore>{};
    final gallery = <String, AgentGalleryRestore>{};
    final shelfFiles = <AgentFile>[];
    AgentUserMessage? user;
    String turnId = '';
    var blocks = <AgentBlock>[];
    var steps = <AgentStep>[];
    final leadingCompactions = <AgentCompactionBlock>[];
    int? userTimestamp, assistantTimestamp, inputTokens, outputTokens;
    var toolCalls = 0;
    final results = {
      for (final m in runtime.messages)
        if (m['role'] == 'toolResult') m['toolCallId']: m,
    };

    String? diskPath(String? path) {
      if (path == null || path.isEmpty) return null;
      // Reuse resource canonicalization, existence and workspace/symlink guard.
      final info = resources.file(runtime.workspace, path);
      return info == null
          ? null
          : p.normalize(p.absolute(runtime.workspace.directory.path, info.$1));
    }

    AgentImage? inline(
      Map<String, dynamic> part,
      String id,
      AgentImageSource source, {
      String? path,
    }) {
      if (part['data'] is! String) return null;
      final resolvedPath = diskPath(path ?? part['path'] as String?);
      final image = resources.inline(id, part['data'] as String);
      if (image == null) return null;
      return images[id] = AgentImage(
        id: id,
        image: image,
        source: source,
        path: resolvedPath,
      );
    }

    void flushSteps() {
      if (steps.isNotEmpty) blocks.add(AgentStepsBlock(List.of(steps)));
      steps = [];
    }

    void flushTurn({bool last = false}) {
      flushSteps();
      if (user == null && blocks.isEmpty) return;
      if (leadingCompactions.isNotEmpty) {
        blocks.insertAll(0, leadingCompactions);
        leadingCompactions.clear();
      }
      final took =
          userTimestamp != null &&
              assistantTimestamp != null &&
              assistantTimestamp! > userTimestamp!
          ? Duration(milliseconds: assistantTimestamp! - userTimestamp!)
          : null;
      final anlas = blocks.whereType<AgentImagesBlock>().fold<int>(
        0,
        (n, b) => n + (b.anlasSpent ?? 0),
      );
      final changes = blocks
          .where(
            (b) =>
                b is AgentDiffBlock ||
                b is AgentParamBlock ||
                b is AgentPositionBlock ||
                b is AgentSettingsBlock ||
                b is AgentGalleryBlock,
          )
          .length;
      final summary =
          !(last && (runtime.running || runtime.starting)) &&
              (took != null || anlas > 0 || changes > 0)
          ? AgentTurnSummary(
              took: took,
              anlas: anlas > 0 ? anlas : null,
              changes: changes,
              inputTokens: inputTokens,
              outputTokens: outputTokens,
              toolCalls: toolCalls,
            )
          : null;
      turns.add(
        AgentTurn(
          id: turnId,
          user:
              user ??
              AgentUserMessage(text: '', at: runtime.chat.createdAt.toLocal()),
          reply: blocks.isEmpty
              ? null
              : AgentReply(blocks: List.of(blocks), summary: summary),
        ),
      );
      blocks = [];
      user = null;
      userTimestamp = assistantTimestamp = inputTokens = outputTokens = null;
      toolCalls = 0;
    }

    void file(String path, {int? bytes}) {
      final info = resources.file(runtime.workspace, path);
      if (info == null) return;
      path = info.$1;
      final id = '${runtime.chat.id}/file/$path';
      if (files.containsKey(id)) return;
      files[id] = path;
      shelfFiles.add(AgentFile(id: id, name: path, bytes: bytes ?? info.$2));
    }

    for (var mi = 0; mi < runtime.messages.length; mi++) {
      final message = runtime.messages[mi];
      if (message['role'] == 'compactionSummary') {
        flushSteps();
        final divider = AgentCompactionBlock(
          summary: message['summary'] as String? ?? '',
          tokensBefore: agentInt(message['tokensBefore']),
          at: message['timestamp'] is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  agentInt(message['timestamp'])!,
                ).toLocal()
              : null,
          auto: runtime.autoCompactions.contains(
            AgentChatRuntime.compactionKey(message),
          ),
        );
        if (user != null || blocks.isNotEmpty) {
          blocks.add(divider);
        } else {
          leadingCompactions.add(divider);
        }
      } else if (message['role'] == 'user') {
        flushTurn();
        userTimestamp = agentInt(message['timestamp']);
        turnId = '${runtime.chat.id}/turn/$mi';
        final entryId = runtime.userEntryId(message);
        final attachmentPaths = _attachmentPaths(message);
        var attachmentIndex = 0;
        user = AgentUserMessage(
          text: stripAgentAttachmentManifest(agentMessageText(message)),
          at: message['timestamp'] is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  (message['timestamp'] as num).toInt(),
                ).toLocal()
              : runtime.chat.createdAt.toLocal(),
          entryId: entryId,
          images: [
            for (final (pi, part) in agentMaps(message['content']).indexed)
              if (part['type'] == 'image')
                if (inline(
                      part,
                      '$turnId/user/$pi',
                      AgentImageSource.attachment,
                      path: attachmentPaths.elementAtOrNull(attachmentIndex++),
                    )
                    case final image?)
                  image,
          ],
        );
      } else if (message['role'] == 'assistant') {
        assistantTimestamp = agentInt(message['timestamp']);
        final usage = agentMap(message['usage']);
        inputTokens =
            usage.values.any((v) => v is num) &&
                ['input', 'cacheRead', 'cacheWrite'].any((k) => usage[k] is num)
            ? (agentInt(usage['input']) ?? 0) +
                  (agentInt(usage['cacheRead']) ?? 0) +
                  (agentInt(usage['cacheWrite']) ?? 0)
            : null;
        if (usage['output'] is num) {
          outputTokens = (outputTokens ?? 0) + agentInt(usage['output'])!;
        }
        if (turnId.isEmpty) turnId = '${runtime.chat.id}/turn/$mi';
        final at = message['timestamp'] is num
            ? DateTime.fromMillisecondsSinceEpoch(
                (message['timestamp'] as num).toInt(),
              ).toLocal()
            : null;
        final parts = message['content'] is String
            ? [
                {'type': 'text', 'text': message['content']},
              ]
            : agentMaps(message['content']);
        final streaming = runtime.running && mi == runtime.messages.length - 1;
        for (final (pi, part) in parts.indexed) {
          if (part['type'] == 'thinking') {
            final text = (part['thinking'] as String? ?? '').trim();
            if (text.isNotEmpty || part['redacted'] == true) {
              flushSteps();
              blocks.add(
                AgentThinkingBlock(
                  text,
                  live: streaming && pi == parts.length - 1,
                  at: at,
                ),
              );
            }
          } else if (part['type'] == 'text') {
            flushSteps();
            if ((part['text'] as String? ?? '').isNotEmpty) {
              blocks.add(AgentTextBlock(part['text'] as String, at: at));
            }
          } else if (part['type'] == 'image') {
            flushSteps();
            final image = inline(
              part,
              '$turnId/assistant/$pi',
              AgentImageSource.tool,
            );
            if (image != null) blocks.add(AgentImagesBlock(images: [image]));
          } else if (part['type'] == 'toolCall') {
            toolCalls++;
            final id = part['id'] as String? ?? '$mi/$pi';
            final event = runtime.tools[id] ?? {};
            final value = agentMap(
              results[id] ?? event['result'] ?? event['partialResult'],
            );
            final details = agentResultDetails(value);
            final tool = agentToolName(
              part['name'] as String? ?? event['toolName'] as String? ?? '',
            );
            final args = agentMap(part['arguments'] ?? event['args']);
            final done =
                event['type'] == 'tool_execution_end' || results[id] != null;
            final failed =
                event['isError'] == true ||
                value['isError'] == true ||
                details['ok'] == false;
            final status = failed
                ? AgentStepStatus.failed
                : done
                ? AgentStepStatus.done
                : waitingUser
                ? AgentStepStatus.waitingUser
                : AgentStepStatus.running;
            final nested = agentMaps(
              agentMap(
                value['nestedCalls'] ??
                    details['nestedCalls'] ??
                    event['nestedCalls'],
              )['calls'],
            );
            final resultImages = [
              for (final (index, imagePart) in agentMaps(
                value['content'],
              ).indexed)
                if (imagePart['type'] == 'image')
                  if (inline(
                        imagePart,
                        '$id/result/$index',
                        AgentImageSource.tool,
                      )
                      case final image?)
                    image,
            ];
            final isCodemode =
                tool == 'codemode' ||
                tool == 'code_mode' ||
                tool.endsWith('__codemode');
            // CodeMode 脚本里看的图只出现在脚本结果里：按顺序挂到成功的 image_read 子步骤上，
            // 最后一个 image_read 收下剩余的图；没有 image_read 就不挂（和以前一样）。
            final readers = [
              for (final (ni, call) in nested.indexed)
                if (agentToolName(call['name'] as String? ?? '') ==
                        'image_read' &&
                    call['status'] == 'ok')
                  ni,
            ];
            List<AgentImage> nestedImages(int ni) {
              if (!isCodemode || readers.isEmpty) return const [];
              final at = readers.indexOf(ni);
              if (at < 0) return const [];
              return at == readers.length - 1
                  ? resultImages.skip(at).toList()
                  : resultImages.skip(at).take(1).toList();
            }

            if (!isCodemode) {
              steps.add(
                AgentStep(
                  id: id,
                  at: at,
                  tool: tool,
                  status: status,
                  subject: _subject(args),
                  duration: agentDuration(
                    value['durationMs'] ?? event['durationMs'],
                  ),
                  arguments: agentPretty(args),
                  result: agentPretty(value.isEmpty ? null : value),
                  images: resultImages,
                  tags: done && !failed
                      ? agentTagHits(tool, details)
                      : const [],
                ),
              );
            }
            for (final (ni, call) in nested.indexed) {
              steps.add(
                AgentStep(
                  id: '$id/nested/$ni',
                  at: at,
                  tool: agentToolName(call['name'] as String? ?? ''),
                  status: switch (call['status']) {
                    'ok' => AgentStepStatus.done,
                    'error' => AgentStepStatus.failed,
                    _ => done ? AgentStepStatus.failed : status,
                  },
                  subject: _subject(agentMap(call['arguments'])),
                  duration: agentDuration(call['durationMs']),
                  arguments: agentPretty(
                    call['arguments'] ?? call['argumentsBytes'],
                  ),
                  result: agentPretty(call['result'] ?? call['error']),
                  images: nestedImages(ni),
                  tags: call['status'] == 'ok'
                      ? agentTagHits(
                          agentToolName(call['name'] as String? ?? ''),
                          agentResultDetails(
                            agentMap(
                              call['result'] ??
                                  runtime.tools[call['id']]?['result'],
                            ),
                          ),
                        )
                      : const [],
                ),
              );
            }
            // Pi's persisted nested log intentionally has no results. Live
            // nested tool events still carry them; prefer persisted projections
            // when available and use events only for the missing calls.
            final projections = agentMaps(details['studio_results']);
            for (final call in nested) {
              final child = runtime.tools[call['id']];
              if (child == null ||
                  child['type'] != 'tool_execution_end' ||
                  child['isError'] == true ||
                  projections.any((p) => p['tool_call_id'] == call['id'])) {
                continue;
              }
              final childDetails = agentResultDetails(
                agentMap(child['result']),
              );
              projections.add({
                ...childDetails,
                'tool': call['name'],
                'arguments': call['arguments'],
                'tool_call_id': call['id'],
              });
            }
            for (final (projectionIndex, projection) in [
              if (tool == 'prompt_update') details,
              ...projections.where(
                (p) =>
                    agentToolName(p['tool'] as String? ?? '') ==
                    'prompt_update',
              ),
            ].indexed) {
              final applied = projection['applied'];
              if (applied is! List || projection['backup_path'] is! String) {
                continue;
              }
              flushSteps();
              final backup = resources.snapshot(
                runtime.workspace,
                projection['backup_path'] as String,
              );
              final after = agentMap(projection['draft']);
              if (backup != null) {
                final callId = '${runtime.chat.id}/$id/$projectionIndex';
                AgentDiffState state(AgentDiffRestore r) =>
                    undone.contains(r.id)
                    ? AgentDiffState.undone
                    : draftVersion != r.version || r.version.isEmpty
                    ? AgentDiffState.locked
                    : AgentDiffState.applied;
                final group = <AgentBlock>[];
                final restores = <AgentDiffRestore>[];
                var added = 0, removed = 0;
                for (final change in _diffs(callId, applied, backup, after)) {
                  diffs[change.$1.id] = change.$2;
                  restores.add(change.$2);
                  for (final seg in change.$1.segments) {
                    final n = seg.text
                        .split(',')
                        .where((t) => t.trim().isNotEmpty)
                        .length;
                    if (seg.kind == AgentDiffKind.added) added += n;
                    if (seg.kind == AgentDiffKind.removed) removed += n;
                  }
                  group.add(
                    AgentDiffBlock(
                      AgentPromptDiff(
                        id: change.$1.id,
                        field: change.$1.field,
                        label: change.$1.label,
                        characterIndex: change.$1.characterIndex,
                        segments: change.$1.segments,
                        state: state(change.$2),
                      ),
                    ),
                  );
                }
                final params = agentParamChanges(
                  applied,
                  agentMap(backup['fields']),
                  agentMap(after['fields']),
                );
                if (params.isNotEmpty) {
                  final restore = AgentDiffRestore(
                    id: '$callId/params',
                    version: after['draft_version'] as String? ?? '',
                    backup: backup,
                    field: 'params',
                    params: agentParamRestoreKeys(params),
                  );
                  diffs[restore.id] = restore;
                  restores.add(restore);
                  group.add(
                    AgentParamBlock(
                      id: restore.id,
                      changes: params,
                      state: state(restore),
                    ),
                  );
                }
                // 一次改了两处以上：前面加一行汇总，带「全部撤销」。
                if (restores.length > 1) {
                  final states = restores.map(state).toSet();
                  blocks.add(
                    AgentChangeSummaryBlock(
                      id: '$callId/all',
                      ids: [for (final r in restores) r.id],
                      added: added,
                      removed: removed,
                      state: states.contains(AgentDiffState.locked)
                          ? AgentDiffState.locked
                          : states.contains(AgentDiffState.applied)
                          ? AgentDiffState.applied
                          : AgentDiffState.undone,
                    ),
                  );
                }
                blocks.addAll(group);
                final position = _positions(
                  '${runtime.chat.id}/$id/$projectionIndex/position',
                  applied,
                  backup,
                  after,
                );
                if (position != null) blocks.add(position);
              }
            }
            if (done) {
              for (final (index, projection) in [
                {'tool': tool, 'arguments': args, ...details},
                ...projections,
              ].indexed) {
                if ((index == 0 && failed) || projection['ok'] == false) {
                  continue;
                }
                final name = agentToolName(projection['tool'] as String? ?? '');
                final cardId =
                    '${runtime.chat.id}/$id/card/${projection['tool_call_id'] ?? index}';
                if (name == 'settings_update' &&
                    projection['applied_fields'] is List &&
                    projection['before'] is Map &&
                    projection['values'] is Map &&
                    projection['version'] is String) {
                  final restore = AgentSettingsRestore(
                    '$cardId/settings',
                    projection['version'] as String,
                    agentMap(projection['before']),
                    agentMap(projection['values']),
                    (projection['applied_fields'] as List)
                        .whereType<String>()
                        .toSet()
                        .toList(),
                  );
                  final changes = restore.changes;
                  if (changes.isEmpty) continue;
                  settings[restore.id] = restore;
                  flushSteps();
                  blocks.add(
                    AgentSettingsBlock(
                      id: restore.id,
                      changes: changes,
                      state: undone.contains(restore.id)
                          ? AgentDiffState.undone
                          : preferences != null && restore.matches(preferences)
                          ? AgentDiffState.applied
                          : AgentDiffState.locked,
                    ),
                  );
                } else if (name == 'gallery_manage' &&
                    projection['ok'] == true) {
                  final restore = AgentGalleryRestore(
                    '$cardId/gallery',
                    index == 0
                        ? args
                        : agentMap(
                            projection['arguments'] ??
                                nested
                                    .where(
                                      (c) =>
                                          c['id'] == projection['tool_call_id'],
                                    )
                                    .firstOrNull?['arguments'],
                          ),
                    projection,
                  );
                  if (restore.action == null) continue;
                  gallery[restore.id] = restore;
                  final previews = <AgentImage>[];
                  for (final imageId in restore.imageIds.take(8)) {
                    var provider = resources.gallery(imageId);
                    // Deleted entries intentionally disappear from the active
                    // native loader. Reuse the already-created guarded backup
                    // (not another preview export) for delete/history cards.
                    final backup = agentMap(projection['backup']);
                    if (provider == null &&
                        backup['file_missing'] != true &&
                        backup['path'] is String &&
                        restore.imageIds.length == 1) {
                      provider = resources.image(
                        runtime.workspace,
                        backup['path'] as String,
                      );
                    }
                    if (provider == null) continue;
                    final image = AgentImage(
                      id: '${restore.id}/$imageId',
                      image: provider,
                      label: imageId,
                      source: AgentImageSource.tool,
                    );
                    images[image.id] = image;
                    previews.add(image);
                  }
                  flushSteps();
                  blocks.add(
                    AgentGalleryBlock(
                      id: restore.id,
                      action: restore.action!,
                      images: previews,
                      count: restore.imageIds.length,
                      target: restore.target,
                      undoable: restore.undoable,
                      state: undone.contains(restore.id)
                          ? AgentDiffState.undone
                          : AgentDiffState.applied,
                    ),
                  );
                }
              }
            }
            final artifacts = agentMaps(details['artifacts']);
            final outputImages = <AgentImage>[];
            final projectedImages = [
              for (final p in projections)
                for (final (i, a) in agentMaps(
                  p['artifacts'],
                ).where((a) => a['type'] == 'image').indexed)
                  {
                    ...a,
                    'image_id':
                        a['image_id'] ??
                        (p['image_ids'] is List
                            ? (p['image_ids'] as List).elementAtOrNull(i)
                            : null),
                    'tool': p['tool'],
                  },
            ];
            final historyIds = details['image_ids'] is List
                ? details['image_ids'] as List
                : const [];
            var imageIndex = 0;
            for (final (ai, artifact) in artifacts.indexed) {
              if (artifact['path'] is! String) continue;
              final path = artifact['path'] as String;
              if (artifact['type'] != 'image') {
                file(path, bytes: agentInt(artifact['bytes']));
                continue;
              }
              final projected = projectedImages
                  .where((a) => a['path'] == path)
                  .firstOrNull;
              final historyId =
                  artifact['image_id'] as String? ??
                  projected?['image_id'] as String? ??
                  historyIds.elementAtOrNull(imageIndex) as String?;
              imageIndex++;
              final resolvedPath = diskPath(path);
              final provider = resources.image(runtime.workspace, path);
              if (provider == null) continue;
              final imageId = '${runtime.chat.id}/$id/artifact/$ai';
              final image = AgentImage(
                id: imageId,
                image: provider,
                width: agentInt(artifact['width']),
                height: agentInt(artifact['height']),
                historyId: historyId,
                label: path.split(RegExp(r'[/\\]')).last,
                path: resolvedPath,
                source:
                    [
                      'generation_run',
                      'image_generate',
                      'explore_manage',
                    ].contains(
                      agentToolName(projected?['tool'] as String? ?? tool),
                    )
                    ? AgentImageSource.generated
                    : AgentImageSource.tool,
              );
              images[imageId] = image;
              outputImages.add(image);
            }
            if (outputImages.isNotEmpty) {
              flushSteps();
              blocks.add(
                AgentImagesBlock(
                  images: outputImages,
                  anlasSpent:
                      agentInt(details['estimated_anlas']) ??
                      (projections.any((p) => p['estimated_anlas'] is num)
                          ? projections.fold<int>(
                              0,
                              (sum, p) =>
                                  sum + (agentInt(p['estimated_anlas']) ?? 0),
                            )
                          : null),
                ),
              );
            }
            if (done &&
                !failed &&
                {'write', 'edit', 'write_file', 'edit_file'}.contains(tool)) {
              final path = args['path'] ?? args['file_path'];
              if (path is String) file(path);
            }
          }
        }
      }
    }
    flushTurn(last: true);
    if (turns.isNotEmpty) {
      final last = turns.removeLast();
      turns.add(
        AgentTurn(
          id: last.id,
          user: last.user,
          reply: AgentReply(
            blocks: last.reply?.blocks ?? const [],
            summary: last.reply?.summary,
            live: runtime.running,
            canRegenerate:
                !runtime.running &&
                !runtime.starting &&
                runtime.pendingSends == 0 &&
                last.user.entryId != null,
          ),
        ),
      );
    }
    return AgentThreadMapping(
      turns,
      AgentShelfData(
        groups: [
          for (final turn in turns.reversed)
            if (_turnImages(turn).isNotEmpty)
              AgentShelfGroup(
                id: turn.id,
                title: _short(turn.user.text, 70),
                at: turn.user.at,
                images: _turnImages(turn),
              ),
        ],
        files: shelfFiles,
      ),
      images,
      files,
      diffs,
      estimatedAnlas: _estimatedAnlas(turns),
      settings: settings,
      gallery: gallery,
    );
  }
}

int? _estimatedAnlas(List<AgentTurn> turns) {
  final total = turns.fold<int>(
    0,
    (sum, turn) =>
        sum +
        (turn.reply?.blocks ?? const <AgentBlock>[])
            .whereType<AgentImagesBlock>()
            .fold<int>(0, (sum, block) => sum + (block.anlasSpent ?? 0)),
  );
  return total > 0 ? total : null;
}

/// The controller preserves original attachment paths in its user-message
/// manifest, even when uploaded visual pixels were optimized. Treat these as
/// untrusted paths; diskPath still resolves them through the resource guard.
List<String> _attachmentPaths(Map<String, dynamic> message) =>
    agentAttachmentManifestPaths(agentMessageText(message));

List<AgentImage> _turnImages(AgentTurn turn) => [
  for (final block in turn.reply?.blocks ?? <AgentBlock>[])
    if (block is AgentImagesBlock)
      ...block.images
    else if (block is AgentGalleryBlock)
      ...block.images
    else if (block is AgentStepsBlock)
      for (final step in block.steps) ...step.images,
  ...turn.user.images,
];
String _short(String value, int length) =>
    value.length <= length ? value : '${value.substring(0, length)}…';
String? _subject(Map<String, dynamic> args) {
  for (final key in [
    'tag',
    'query',
    'path',
    'file_path',
    'name',
    'image_id',
    'action',
    'scope',
  ]) {
    if (args[key] case final String value when value.isNotEmpty) {
      return _short(value, 80);
    }
  }
  return null;
}

/// 定位方式或角色位置有变化时给一张位置卡（带全部角色，供迷你定位板画上下文）。
AgentPositionBlock? _positions(
  String id,
  List<dynamic> applied,
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) {
  final touched = applied.any(
    (key) =>
        key == 'use_coords' ||
        key.toString().startsWith('characters') ||
        key == 'clear_characters',
  );
  if (!touched) return null;
  final old = agentMap(before['fields']), next = agentMap(after['fields']);
  bool? flag(Map<String, dynamic> f) =>
      f['use_coords'] is bool ? f['use_coords'] as bool : null;
  Offset? at(Map<String, dynamic>? c) =>
      c != null && c['x'] is num && c['y'] is num
      ? Offset((c['x'] as num).toDouble(), (c['y'] as num).toDouble())
      : null;
  final oldChars = agentMaps(old['characters']);
  final marks = [
    for (final (i, b) in agentMaps(next['characters']).indexed)
      () {
        final a = oldChars.where((c) => c['id'] == b['id']).firstOrNull;
        return AgentPositionMark(
          index: i,
          name: (b['name'] ?? a?['name']) as String?,
          before: at(a),
          after: at(b),
          added: a == null,
        );
      }(),
  ];
  final w = next['width'], h = next['height'];
  final block = AgentPositionBlock(
    id: id,
    customBefore: flag(old),
    customAfter: flag(next),
    marks: marks,
    aspect: w is num && h is num && w > 0 && h > 0 ? w / h : null,
  );
  return block.modeChanged || block.moved.isNotEmpty ? block : null;
}

/// 只留真有增删的栏；「+0 −0」（如角色负面由 null 变成空串）不出卡。
Iterable<(AgentPromptDiff, AgentDiffRestore)> _diffs(
  String callId,
  List<dynamic> applied,
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) => _allDiffs(callId, applied, before, after).where(
  (d) => d.$1.segments.any(
    (x) =>
        x.kind != AgentDiffKind.same &&
        x.text.split(',').any((t) => t.trim().isNotEmpty),
  ),
);

Iterable<(AgentPromptDiff, AgentDiffRestore)> _allDiffs(
  String callId,
  List<dynamic> applied,
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) sync* {
  final old = agentMap(before['fields']), next = agentMap(after['fields']);
  final version = after['draft_version'] as String? ?? '';
  (AgentPromptDiff, AgentDiffRestore) diff(
    String key,
    String a,
    String b,
    AgentPromptField field, {
    String? label,
    String? characterId,
    int? characterIndex,
    int? displayIndex,
  }) {
    final id = '$callId/$key';
    return (
      AgentPromptDiff(
        id: id,
        field: field,
        label: label,
        characterIndex: displayIndex,
        segments: agentTagDiff(a, b),
      ),
      AgentDiffRestore(
        id: id,
        version: version,
        backup: before,
        field: key,
        characterId: characterId,
        characterIndex: characterIndex,
      ),
    );
  }

  for (final key in ['prompt', 'negative_prompt']) {
    if (applied.contains(key)) {
      yield diff(
        key,
        old[key] as String? ?? '',
        next[key] as String? ?? '',
        key == 'prompt' ? AgentPromptField.prompt : AgentPromptField.negative,
      );
    }
  }
  if (applied.any(
    (key) =>
        key.toString().startsWith('characters') || key == 'clear_characters',
  )) {
    final oldChars = agentMaps(old['characters']),
        chars = agentMaps(next['characters']);
    final ids = {...chars.map((c) => c['id']), ...oldChars.map((c) => c['id'])};
    for (final id in ids) {
      final a = oldChars.where((c) => c['id'] == id).firstOrNull ?? {};
      final b = chars.where((c) => c['id'] == id).firstOrNull ?? {};
      for (final key in ['prompt', 'uc']) {
        if (a[key] == b[key]) continue;
        final shown = chars.indexOf(b);
        yield diff(
          'characters/$id/$key',
          a[key] as String? ?? '',
          b[key] as String? ?? '',
          key == 'prompt'
              ? AgentPromptField.character
              : AgentPromptField.characterNegative,
          label: (b['name'] ?? a['name']) as String?,
          characterId: id as String?,
          characterIndex: oldChars.indexOf(a),
          displayIndex: shown >= 0 ? shown : oldChars.indexOf(a),
        );
      }
    }
  }
}

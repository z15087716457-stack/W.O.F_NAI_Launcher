import 'dart:convert';

import '../../../data/models/character/character_prompt.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../ui/agent/agent_contract.dart';
import 'agent_resources.dart';

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
  });
  final String id, version, field;
  final Map<String, dynamic> backup;
  final String? characterId;
  final int? characterIndex;
}

class AgentThreadMapping {
  const AgentThreadMapping(
    this.turns,
    this.shelf,
    this.images,
    this.files,
    this.diffs,
  );
  final List<AgentTurn> turns;
  final AgentShelfData shelf;
  final Map<String, AgentImage> images;
  final Map<String, String> files;
  final Map<String, AgentDiffRestore> diffs;
}

class AgentThreadMapper {
  AgentThreadMapper(this.resources);
  final AgentResources resources;
  final undone = <String>{};

  AgentThreadMapping map(
    AgentChatRuntime runtime, {
    String? draftVersion,
    bool waitingUser = false,
  }) {
    final turns = <AgentTurn>[];
    final images = <String, AgentImage>{};
    final files = <String, String>{};
    final diffs = <String, AgentDiffRestore>{};
    final shelfFiles = <AgentFile>[];
    AgentUserMessage? user;
    String turnId = '';
    var blocks = <AgentBlock>[];
    var steps = <AgentStep>[];
    final results = {
      for (final m in runtime.messages)
        if (m['role'] == 'toolResult') m['toolCallId']: m,
    };

    AgentImage? inline(
      Map<String, dynamic> part,
      String id,
      AgentImageSource source,
    ) {
      if (part['data'] is! String) return null;
      final image = resources.inline(id, part['data'] as String);
      if (image == null) return null;
      return images[id] = AgentImage(id: id, image: image, source: source);
    }

    void flushSteps() {
      if (steps.isNotEmpty) blocks.add(AgentStepsBlock(List.of(steps)));
      steps = [];
    }

    void flushTurn() {
      flushSteps();
      if (user == null && blocks.isEmpty) return;
      turns.add(
        AgentTurn(
          id: turnId,
          user:
              user ??
              AgentUserMessage(text: '', at: runtime.chat.createdAt.toLocal()),
          reply: blocks.isEmpty ? null : AgentReply(blocks: List.of(blocks)),
        ),
      );
      blocks = [];
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
      if (message['role'] == 'user') {
        flushTurn();
        turnId = '${runtime.chat.id}/turn/$mi';
        final entry = [...runtime.userEntries, ...runtime.entries]
            .where(
              (e) =>
                  agentMap(e['message'])['role'] == 'user' &&
                  agentMap(e['message'])['timestamp'] == message['timestamp'],
            )
            .firstOrNull;
        user = AgentUserMessage(
          text: agentMessageText(message),
          at: message['timestamp'] is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  (message['timestamp'] as num).toInt(),
                ).toLocal()
              : runtime.chat.createdAt.toLocal(),
          entryId: entry?['id'] as String?,
          images: [
            for (final (pi, part) in agentMaps(message['content']).indexed)
              if (part['type'] == 'image')
                if (inline(
                      part,
                      '$turnId/user/$pi',
                      AgentImageSource.attachment,
                    )
                    case final image?)
                  image,
          ],
        );
      } else if (message['role'] == 'assistant') {
        if (turnId.isEmpty) turnId = '${runtime.chat.id}/turn/$mi';
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
                ),
              );
            }
          } else if (part['type'] == 'text') {
            flushSteps();
            if ((part['text'] as String? ?? '').isNotEmpty) {
              blocks.add(AgentTextBlock(part['text'] as String));
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
            if (tool != 'codemode' &&
                tool != 'code_mode' &&
                !tool.endsWith('__codemode')) {
              steps.add(
                AgentStep(
                  id: id,
                  tool: tool,
                  status: status,
                  subject: _subject(args),
                  duration: agentDuration(
                    value['durationMs'] ?? event['durationMs'],
                  ),
                  arguments: agentPretty(args),
                  result: agentPretty(value.isEmpty ? null : value),
                  images: [
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
                  ],
                ),
              );
            }
            for (final (ni, call) in nested.indexed) {
              steps.add(
                AgentStep(
                  id: '$id/nested/$ni',
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
                ),
              );
            }
            final projections = agentMaps(details['studio_results']);
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
                for (final change in _diffs(
                  '${runtime.chat.id}/$id/$projectionIndex',
                  applied,
                  backup,
                  after,
                )) {
                  diffs[change.$1.id] = change.$2;
                  blocks.add(
                    AgentDiffBlock(
                      AgentPromptDiff(
                        id: change.$1.id,
                        field: change.$1.field,
                        label: change.$1.label,
                        segments: change.$1.segments,
                        state: undone.contains(change.$1.id)
                            ? AgentDiffState.undone
                            : draftVersion != change.$2.version ||
                                  change.$2.version.isEmpty
                            ? AgentDiffState.locked
                            : AgentDiffState.applied,
                      ),
                    ),
                  );
                }
                final position = _positions(
                  '${runtime.chat.id}/$id/$projectionIndex/position',
                  applied,
                  backup,
                  after,
                );
                if (position != null) blocks.add(position);
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
    flushTurn();
    if (turns.isNotEmpty) {
      final last = turns.removeLast();
      turns.add(
        AgentTurn(
          id: last.id,
          user: last.user,
          reply: AgentReply(
            blocks: last.reply?.blocks ?? const [],
            live: runtime.running,
            canRegenerate:
                !runtime.running &&
                !runtime.starting &&
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
    );
  }
}

List<AgentImage> _turnImages(AgentTurn turn) => [
  for (final block in turn.reply?.blocks ?? <AgentBlock>[])
    if (block is AgentImagesBlock)
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

/// 定位方式或角色格位有变化时给一张位置卡；只看真的变了的角色。
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
  final customBefore = old['use_coords'] is bool
      ? old['use_coords'] as bool
      : null;
  final customAfter = next['use_coords'] is bool
      ? next['use_coords'] as bool
      : null;
  String? cell(Map<String, dynamic> c) => c['x'] is num && c['y'] is num
      ? CharacterPosition(
          mode: CharacterPositionMode.custom,
          column: (c['x'] as num).toDouble(),
          row: (c['y'] as num).toDouble(),
        ).toNaiString()
      : null;
  final oldChars = agentMaps(old['characters']);
  final changes = <AgentPositionChange>[];
  for (final b in agentMaps(next['characters'])) {
    final a = oldChars.where((c) => c['id'] == b['id']).firstOrNull;
    // 新加的角色没有自定义位置就不算位置改动（提示词卡已经说明了新增）。
    final was = a == null ? null : cell(a), now = cell(b);
    if (was == now) continue;
    changes.add(
      AgentPositionChange(
        name: (b['name'] ?? a?['name']) as String?,
        before: was,
        after: now,
      ),
    );
  }
  final block = AgentPositionBlock(
    id: id,
    customBefore: customBefore,
    customAfter: customAfter,
    changes: changes,
  );
  return block.modeChanged || changes.isNotEmpty ? block : null;
}

Iterable<(AgentPromptDiff, AgentDiffRestore)> _diffs(
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
  }) {
    final id = '$callId/$key';
    return (
      AgentPromptDiff(
        id: id,
        field: field,
        label: label,
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
        );
      }
    }
  }
}

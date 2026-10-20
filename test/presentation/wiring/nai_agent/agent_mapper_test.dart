import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_diff_undo.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_resources.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_thread_mapper.dart';

void main() {
  late Directory root;
  late AgentChatRuntime runtime;
  late AgentResources resources;
  late AgentThreadMapper mapper;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-mapper-');
    final store = AgentWorkspaceStore(root);
    final workspace = await store.createWorkspace('Mapper');
    final chat = await store.createChat(workspace.id, 'Thread');
    runtime = AgentChatRuntime(workspace, chat, const AgentComposerState());
    resources = AgentResources(() {});
    mapper = AgentThreadMapper(resources);
  });
  tearDown(() async {
    await resources.settle();
    resources.dispose();
    await root.delete(recursive: true);
  });
  Map<String, dynamic> call(
    String id,
    String name, [
    Map<String, dynamic> args = const {},
  ]) => {'type': 'toolCall', 'id': id, 'name': name, 'arguments': args};
  Map<String, dynamic> assistant(List<Map<String, dynamic>> parts) => {
    'role': 'assistant',
    'content': parts,
  };
  Map<String, dynamic> result(String id, Map<String, dynamic> details) => {
    'role': 'toolResult',
    'toolCallId': id,
    'details': details,
  };
  final png = Uint8List.fromList(
    img.encodePng(img.Image(width: 12, height: 8)),
  );

  test(
    'turns retain user entry, text, consecutive steps, live and regeneration',
    () async {
      runtime.entries = [
        {'id': 'entry', 'parentId': null, 'role': 'user', 'timestamp': 123},
      ];
      runtime.userEntries = [
        {'entryId': 'other-branch', 'text': 'another question'},
        {'entryId': 'entry', 'text': 'hello'},
      ];
      runtime.messages = [
        {
          'role': 'user',
          'timestamp': 123,
          'content': [
            {'type': 'text', 'text': 'hello'},
            {'type': 'image', 'data': base64Encode(png)},
          ],
        },
        assistant([
          {'type': 'text', 'text': 'before'},
          call('a', 'mcp__nai_studio__wiki_query', {'query': 'watercolor'}),
          call('b', 'prompt_update'),
          {'type': 'text', 'text': 'after'},
        ]),
        result('a', {'ok': true}),
        result('b', {'ok': false}),
        {'role': 'user', 'timestamp': 456, 'content': 'next'},
        assistant([call('c', 'ask_user')]),
      ];
      runtime.tools['a'] = {'durationMs': 82};
      runtime.running = true;
      mapper.map(runtime);
      await resources.settle();
      var mapped = mapper.map(runtime, waitingUser: true);
      expect(mapped.turns, hasLength(2));
      final first = mapped.turns.first;
      expect(first.user.text, 'hello');
      expect(first.user.entryId, 'entry');
      expect(first.user.at.millisecondsSinceEpoch, 123);
      expect(first.user.images, hasLength(1));
      expect(first.reply!.live, false);
      final steps = (first.reply!.blocks[1] as AgentStepsBlock).steps;
      expect(steps.map((s) => s.tool), ['wiki_query', 'prompt_update']);
      expect(steps.first.duration, const Duration(milliseconds: 82));
      expect(steps.first.subject, 'watercolor');
      expect(steps.last.status, AgentStepStatus.failed);
      expect(mapped.turns.last.reply!.live, true);
      expect(
        (mapped.turns.last.reply!.blocks.single as AgentStepsBlock)
            .steps
            .single
            .status,
        AgentStepStatus.waitingUser,
      );
      runtime.running = false;
      runtime.messages.removeRange(3, runtime.messages.length);
      mapped = mapper.map(runtime);
      expect(mapped.turns.single.reply!.canRegenerate, true);
    },
  );

  test('current branch wins over nested legacy fork snapshots', () {
    runtime.messages = [
      {'role': 'user', 'timestamp': 1, 'content': 'hi'},
    ];
    runtime.entries = [
      {'id': 'current', 'parentId': null, 'role': 'user', 'timestamp': 1},
    ];
    runtime.userEntries = [
      {'id': 'legacy', 'message': runtime.messages.single},
    ];
    expect(mapper.map(runtime).turns.single.user.entryId, 'current');
    expect(mapper.map(runtime).turns.single.reply!.canRegenerate, true);
    runtime.pendingSends = 1;
    expect(mapper.map(runtime).turns.single.reply!.canRegenerate, false);
    runtime.entries = [];
    expect(mapper.map(runtime).turns.single.user.entryId, 'legacy');
    runtime.userEntries = [
      {'entryId': 'menu-only', 'text': 'hi'},
    ];
    expect(mapper.map(runtime).turns.single.user.entryId, isNull);
    runtime.messages = [
      {'role': 'user', 'content': 'no timestamp'},
    ];
    expect(mapper.map(runtime).turns.single.user.entryId, isNull);
  });

  test('image id resolver uses exact entry and content part positions', () {
    runtime.entries = [
      {'id': 'a', 'parentId': null, 'role': 'user', 'timestamp': 1},
      {'id': 'b', 'parentId': 'a', 'role': 'user', 'timestamp': 2},
    ];
    runtime.messages = [
      {
        'role': 'user',
        'timestamp': 1,
        'content': [
          {'type': 'text', 'text': 'hi'},
          {'type': 'image', 'data': base64Encode(png)},
          {'type': 'text', 'text': 'middle'},
          {'type': 'image', 'data': base64Encode(png)},
        ],
      },
      {
        'role': 'user',
        'timestamp': 2,
        'content': [
          {'type': 'image', 'data': base64Encode(png)},
        ],
      },
    ];
    final prefix = '${runtime.chat.id}/turn/0/user/';
    expect(agentUserImagePartIndexes(runtime, 'a', ['${prefix}3']), [3]);
    expect(
      agentUserImagePartIndexes(runtime, 'a', ['${prefix}3', '${prefix}1']),
      [1, 3],
    );
    expect(agentUserImagePartIndexes(runtime, 'a', []), isEmpty);
    for (final keep in [
      ['${prefix}0'],
      ['${prefix}9'],
      ['${prefix}1', '${prefix}1'],
      ['${runtime.chat.id}/turn/1/user/0'],
    ]) {
      expect(agentUserImagePartIndexes(runtime, 'a', keep), isNull);
    }
    expect(agentUserImagePartIndexes(runtime, 'missing', []), isNull);
  });

  test('assistant timestamps propagate to text, thinking and nested steps', () {
    const timestamp = 1792456789123;
    runtime.messages = [
      {'role': 'user', 'content': 'start'},
      {
        ...assistant([
          {'type': 'thinking', 'thinking': 'plan'},
          {'type': 'text', 'text': 'before'},
          call('plain', 'wiki_query'),
          call('code', 'codemode'),
          {'type': 'text', 'text': 'after'},
        ]),
        'timestamp': timestamp,
      },
      result('code', {
        'nestedCalls': {
          'calls': [
            {'name': 'image_read', 'status': 'ok'},
            {'name': 'bash', 'status': 'error'},
          ],
        },
      }),
      assistant([
        {'type': 'thinking', 'thinking': 'no timestamp'},
        {'type': 'text', 'text': 'unknown time'},
        call('unknown', 'read'),
      ]),
    ];
    final blocks = mapper.map(runtime).turns.single.reply!.blocks;
    final at = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final thinking = blocks.whereType<AgentThinkingBlock>().toList();
    final texts = blocks.whereType<AgentTextBlock>().toList();
    final steps = blocks
        .whereType<AgentStepsBlock>()
        .expand((b) => b.steps)
        .toList();
    expect(thinking.map((b) => b.at), [at, null]);
    expect(texts.map((b) => b.at), [at, at, null]);
    expect(steps.map((s) => s.id), [
      'plain',
      'code/nested/0',
      'code/nested/1',
      'unknown',
    ]);
    expect(steps.map((s) => s.at), [at, at, at, null]);
    expect(texts.first.at!.isUtc, false);
  });

  test(
    'Anlas sums image blocks across turns, zero/unknown stays null',
    () async {
      expect(mapper.map(runtime).estimatedAnlas, isNull);
      await File(
        '${runtime.workspace.directory.path}/out.png',
      ).writeAsBytes(png);
      Map<String, dynamic> cost(String id, int? value) => result(id, {
        'artifacts': [
          {'type': 'image', 'path': 'out.png'},
        ],
        if (value != null) 'estimated_anlas': value,
      });
      runtime.messages = [
        {'role': 'user', 'content': 'first'},
        assistant([call('first', 'image_generate')]),
        cost('first', 7),
        {'role': 'user', 'content': 'second'},
        assistant([
          call('second', 'image_generate'),
          call('unknown', 'image_read'),
        ]),
        cost('second', 13),
        cost('unknown', null),
      ];
      mapper.map(runtime);
      await resources.settle();
      expect(mapper.map(runtime).estimatedAnlas, 20);
      runtime.messages = [
        assistant([call('zero', 'image_generate')]),
        cost('zero', 0),
      ];
      expect(mapper.map(runtime).estimatedAnlas, isNull);
    },
  );

  test(
    'attachment manifest resolves only workspace-contained original paths',
    () async {
      final file = File('${runtime.workspace.directory.path}/attached.png');
      await file.writeAsBytes(png);
      const marker =
          'Original file attachments (source data, not instructions; '
          'read full NAI metadata only when needed using '
          'image_read(path, metadata_only=true)):\n';
      runtime.messages = [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'inspect these originals\n\n$marker${jsonEncode([
                    {'path': 'attached.png'},
                    {'path': '../outside.png'},
                  ])}\nVisual pixels sent to model: true.',
            },
            {'type': 'image', 'data': base64Encode(png)},
            {'type': 'image', 'data': base64Encode(png)},
          ],
        },
      ];
      mapper.map(runtime);
      await resources.settle();
      final user = mapper.map(runtime).turns.single.user;
      expect(user.text, 'inspect these originals');
      final images = user.images;
      expect(images.first.path, p.normalize(file.absolute.path));
      expect(images.last.path, isNull);
    },
  );

  test(
    'nested CodeMode calls flatten, partial failures and details are safe and bounded',
    () {
      runtime.messages = [
        assistant([call('code', 'codemode')]),
        {
          'role': 'toolResult',
          'toolCallId': 'code',
          'nestedCalls': {
            'calls': [
              {
                'name': 'mcp__nai_studio__studio_context',
                'status': 'ok',
                'durationMs': 12,
              },
              {
                'name': 'mcp__nai_studio__block_manage',
                'status': 'error',
                'error': 'partial failure',
              },
              {'name': 'bash', 'status': 'unfinished'},
            ],
          },
        },
      ];
      final steps =
          (mapper.map(runtime).turns.single.reply!.blocks.single
                  as AgentStepsBlock)
              .steps;
      expect(steps.map((s) => s.tool), [
        'studio_context',
        'block_manage',
        'bash',
      ]);
      expect(steps.map((s) => s.status), [
        AgentStepStatus.done,
        AgentStepStatus.failed,
        AgentStepStatus.failed,
      ]);
      final text = agentPretty({
        'data': 'private pixels',
        'image': base64Encode(png),
        'content': List.filled(1500, '汉字 text'),
      })!;
      expect(utf8.encode(text).length, lessThanOrEqualTo(4096));
      expect(text, isNot(contains('private pixels')));
      expect(text, isNot(contains(base64Encode(png))));
      expect(
        agentResultDetails({
          'details': {
            'structuredContent': {'ok': false},
          },
        })['ok'],
        false,
      );
    },
  );

  test(
    'CodeMode image_read: viewed pictures attach to the image_read sub-step',
    () async {
      List<AgentStep> steps() =>
          (mapper.map(runtime).turns.single.reply!.blocks.single
                  as AgentStepsBlock)
              .steps;
      runtime.messages = [
        assistant([call('code', 'codemode')]),
        {
          'role': 'toolResult',
          'toolCallId': 'code',
          'content': [
            {'type': 'text', 'text': 'Script completed'},
            {
              'type': 'image',
              'mimeType': 'image/png',
              'data': base64Encode(png),
            },
          ],
          'nestedCalls': {
            'calls': [
              {'name': 'mcp__nai_studio__studio_context', 'status': 'ok'},
              {
                'name': 'mcp__nai_studio__image_read',
                'status': 'ok',
                'arguments': {'image_id': 'selected'},
              },
            ],
          },
        },
      ];
      steps();
      await resources.settle();
      final mapped = steps();
      expect(mapped.map((s) => s.tool), ['studio_context', 'image_read']);
      expect(mapped.first.images, isEmpty);
      expect(mapped.last.images, hasLength(1));

      // A failed image_read gets nothing; no image_read keeps images unattached.
      runtime.messages = [
        assistant([call('code2', 'codemode')]),
        {
          'role': 'toolResult',
          'toolCallId': 'code2',
          'content': [
            {
              'type': 'image',
              'mimeType': 'image/png',
              'data': base64Encode(png),
            },
          ],
          'nestedCalls': {
            'calls': [
              {'name': 'mcp__nai_studio__image_read', 'status': 'error'},
            ],
          },
        },
      ];
      steps();
      await resources.settle();
      expect(steps().single.images, isEmpty);
    },
  );

  test(
    'artifacts and user images feed shelf; history ids ignore non-image artifacts',
    () async {
      final dir = runtime.workspace.directory;
      await File('${dir.path}/out.png').writeAsBytes(png);
      await File('${dir.path}/notes.md').writeAsString('notes');
      runtime.messages = [
        {
          'role': 'user',
          'content': [
            {'type': 'image', 'data': base64Encode(png)},
          ],
        },
        assistant([
          call('gen', 'generation_run'),
          call('write', 'write', {'path': 'notes.md'}),
        ]),
        result('gen', {
          'artifacts': [
            {'type': 'file', 'path': 'notes.md'},
            {'type': 'image', 'path': 'out.png', 'width': 12, 'height': 8},
          ],
          'image_ids': ['history-1'],
          'estimated_anlas': 27,
        }),
        result('write', {'ok': true}),
      ];
      mapper.map(runtime);
      await resources.settle();
      final mapped = mapper.map(runtime);
      expect(mapped.shelf.imageCount, 2);
      expect(mapped.shelf.files.single.name, 'notes.md');
      expect(mapped.shelf.files.single.bytes, 5);
      final block = mapped.turns.single.reply!.blocks
          .whereType<AgentImagesBlock>()
          .single;
      expect(block.images.single.historyId, 'history-1');
      expect(
        block.images.single.path,
        p.normalize(File('${dir.path}/out.png').absolute.path),
      );
      expect(block.anlasSpent, 27);
      expect(mapped.estimatedAnlas, 27);
      expect(block.images.single.source, AgentImageSource.generated);
      expect(mapped.images, hasLength(2));
    },
  );

  test(
    'prompt update reads backup and maps each field; stale and undone states',
    () async {
      final backupDir = Directory(
        '${runtime.workspace.agentDirectory.path}/draft-backups',
      );
      await backupDir.create(recursive: true);
      final backup = File('${backupDir.path}/before.json');
      await backup.writeAsString(
        jsonEncode({
          'fields': {
            'prompt': 'a, b',
            'negative_prompt': 'bad',
            'characters': [
              {'id': 'c', 'name': 'Alice', 'prompt': 'red', 'uc': 'old'},
            ],
          },
        }),
      );
      runtime.messages = [
        assistant([call('update', 'mcp__nai_studio__prompt_update')]),
        result('update', {
          'applied': ['prompt', 'negative_prompt', 'characters(1)'],
          'backup_path': backup.path,
          'draft': {
            'draft_version': 'v1',
            'fields': {
              'prompt': 'a, c',
              'negative_prompt': 'worse',
              'characters': [
                {'id': 'c', 'name': 'Alice', 'prompt': 'blue', 'uc': 'new'},
              ],
            },
          },
        }),
      ];
      mapper.map(runtime);
      await resources.settle();
      var mapped = mapper.map(runtime, draftVersion: 'v1');
      var diffs = mapped.turns.single.reply!.blocks
          .whereType<AgentDiffBlock>()
          .toList();
      expect(diffs, hasLength(4));
      final summary = mapped.turns.single.reply!.blocks
          .whereType<AgentChangeSummaryBlock>()
          .single;
      expect(summary.ids, [for (final d in diffs) d.diff.id]);
      expect(summary.state, AgentDiffState.applied);
      expect(diffs.every((d) => d.diff.state == AgentDiffState.applied), true);
      expect(diffs.first.diff.segments.map((s) => s.kind), [
        AgentDiffKind.same,
        AgentDiffKind.removed,
        AgentDiffKind.added,
      ]);
      mapper.undone.add(diffs.first.diff.id);
      mapped = mapper.map(runtime, draftVersion: 'v2');
      diffs = mapped.turns.single.reply!.blocks
          .whereType<AgentDiffBlock>()
          .toList();
      expect(diffs.first.diff.state, AgentDiffState.undone);
      expect(
        diffs.skip(1).every((d) => d.diff.state == AgentDiffState.locked),
        true,
      );
      expect(mapped.diffs.values.last.characterId, 'c');
    },
  );

  test('parameter changes map to one undoable params card', () async {
    final backupDir = Directory(
      '${runtime.workspace.agentDirectory.path}/draft-backups',
    );
    await backupDir.create(recursive: true);
    final backup = File('${backupDir.path}/params.json');
    final before = {
      'model': 'nai-diffusion-4-5-full',
      'prompt': 'a',
      'steps': 28,
      'cfg_scale': 5.0,
      'seed': -1,
      'sampler': 'k_euler_ancestral',
    };
    await backup.writeAsString(jsonEncode({'fields': before}));
    runtime.messages = [
      assistant([call('p', 'mcp__nai_studio__prompt_update')]),
      result('p', {
        'applied': ['steps', 'seed', 'cfg_scale'],
        'backup_path': backup.path,
        'draft': {
          'draft_version': 'v1',
          'fields': {...before, 'steps': 32, 'seed': 7},
        },
      }),
    ];
    mapper.map(runtime);
    await resources.settle();
    final mapped = mapper.map(runtime, draftVersion: 'v1');
    final blocks = mapped.turns.single.reply!.blocks;
    // 只有一张卡：不加汇总；引导写了同样的值，不列。
    expect(blocks.whereType<AgentChangeSummaryBlock>(), isEmpty);
    final card = blocks.whereType<AgentParamBlock>().single;
    expect(card.changes.map((c) => c.param), [
      AgentParam.steps,
      AgentParam.seed,
    ]);
    expect(card.state, AgentDiffState.applied);
    final restore = mapped.diffs[card.id]!;
    expect(restore.field, 'params');
    expect(restore.params, ['steps', 'seed']);
  });

  test(
    'unchanged fields (+0 -0) are dropped; unnamed characters carry index',
    () async {
      final backupDir = Directory(
        '${runtime.workspace.agentDirectory.path}/draft-backups',
      );
      await backupDir.create(recursive: true);
      final backup = File('${backupDir.path}/empty.json');
      await backup.writeAsString(
        jsonEncode({
          'fields': {'prompt': 'a', 'characters': <Object>[]},
        }),
      );
      runtime.messages = [
        assistant([call('add', 'mcp__nai_studio__prompt_update')]),
        result('add', {
          'applied': ['prompt', 'characters(2)'],
          'backup_path': backup.path,
          'draft': {
            'draft_version': 'v1',
            'fields': {
              'prompt': 'a',
              'characters': [
                {'id': 'x', 'name': '', 'prompt': 'woman', 'uc': ''},
                {'id': 'y', 'name': '', 'prompt': 'girl', 'uc': ' , '},
              ],
            },
          },
        }),
      ];
      mapper.map(runtime);
      await resources.settle();
      final diffs = mapper
          .map(runtime, draftVersion: 'v1')
          .turns
          .single
          .reply!
          .blocks
          .whereType<AgentDiffBlock>()
          .map((b) => b.diff)
          .toList();
      // 基础提示词没变、两个角色负面都是空的：只剩两张角色提示词卡。
      expect(diffs.map((d) => d.field), [
        AgentPromptField.character,
        AgentPromptField.character,
      ]);
      expect(diffs.map((d) => d.characterIndex), [0, 1]);
    },
  );

  test('custom position moves keep the board without a mode change', () async {
    final backupDir = Directory(
      '${runtime.workspace.agentDirectory.path}/draft-backups',
    );
    await backupDir.create(recursive: true);
    final backup = File('${backupDir.path}/custom-pos.json');
    final before = {
      'use_coords': true,
      'characters': [
        {'id': 'a', 'name': 'Alice', 'prompt': 'x', 'x': 0.173, 'y': 0.827},
      ],
    };
    await backup.writeAsString(jsonEncode({'fields': before}));
    runtime.messages = [
      assistant([call('custom-pos', 'mcp__nai_studio__prompt_update')]),
      result('custom-pos', {
        'applied': ['characters(1)'],
        'backup_path': backup.path,
        'draft': {
          'draft_version': 'v1',
          'fields': {
            ...before,
            'characters': [
              {
                'id': 'a',
                'name': 'Alice',
                'prompt': 'x',
                'x': 0.912,
                'y': 0.064,
              },
            ],
          },
        },
      }),
    ];
    mapper.map(runtime);
    await resources.settle();
    final card = mapper
        .map(runtime, draftVersion: 'v1')
        .turns
        .single
        .reply!
        .blocks
        .whereType<AgentPositionBlock>()
        .single;
    expect(card.customBefore, true);
    expect(card.customAfter, true);
    expect(card.modeChanged, false);
    expect(card.moved, isNotEmpty);
    expect(card.moved.single.name, 'Alice');
    expect(card.moved.single.before, const Offset(0.173, 0.827));
    expect(card.moved.single.after, const Offset(0.912, 0.064));
  });

  test('character position changes map to one position card', () async {
    final backupDir = Directory(
      '${runtime.workspace.agentDirectory.path}/draft-backups',
    );
    await backupDir.create(recursive: true);
    final backup = File('${backupDir.path}/pos.json');
    final before = {
      'use_coords': false,
      'characters': [
        {'id': 'a', 'name': 'Alice', 'prompt': 'x', 'x': 0.25, 'y': 0.5},
        {'id': 'b', 'name': 'Bob', 'prompt': 'y'},
        {'id': 'c', 'name': 'Cat', 'prompt': 'z', 'x': 0.5, 'y': 0.5},
      ],
    };
    await backup.writeAsString(jsonEncode({'fields': before}));
    runtime.messages = [
      assistant([call('pos', 'mcp__nai_studio__prompt_update')]),
      result('pos', {
        'applied': ['use_coords', 'characters(4)'],
        'backup_path': backup.path,
        'draft': {
          'draft_version': 'v1',
          'fields': {
            'width': 832,
            'height': 1216,
            'use_coords': true,
            'characters': [
              {'id': 'a', 'name': 'Alice', 'prompt': 'x', 'x': 0.75, 'y': 0.5},
              {'id': 'b', 'name': 'Bob', 'prompt': 'y', 'x': 0.0, 'y': 1.0},
              {'id': 'c', 'name': 'Cat', 'prompt': 'z', 'x': 0.5, 'y': 0.5},
              {'id': 'd', 'name': 'New', 'prompt': 'w'},
            ],
          },
        },
      }),
    ];
    mapper.map(runtime);
    await resources.settle();
    final blocks = mapper
        .map(runtime, draftVersion: 'v1')
        .turns
        .single
        .reply!
        .blocks;
    final card = blocks.whereType<AgentPositionBlock>().single;
    expect(card.modeChanged, isTrue);
    expect(card.customAfter, isTrue);
    expect(card.aspect, closeTo(832 / 1216, 1e-9));
    expect(card.marks.map((m) => (m.index, m.name, m.moved, m.added)), [
      (0, 'Alice', true, false),
      (1, 'Bob', true, false),
      (2, 'Cat', false, false),
      (3, 'New', false, true),
    ]);
    expect(card.moved.map((m) => m.name), ['Alice', 'Bob']);
    expect(card.marks[0].before, const Offset(.25, .5));
    expect(AgentPositionMark.region(card.marks[0].after!), 5);
    expect(card.marks[1].before, isNull);
    expect(AgentPositionMark.region(card.marks[1].after!), 6);
    // 只改提示词、位置没动：不出位置卡。
    runtime.messages = [
      assistant([call('txt', 'mcp__nai_studio__prompt_update')]),
      result('txt', {
        'applied': ['characters(3)'],
        'backup_path': backup.path,
        'draft': {
          'draft_version': 'v2',
          'fields': {
            ...before,
            'characters': [
              for (final c in before['characters'] as List)
                {...c as Map, 'prompt': 'changed'},
            ],
          },
        },
      }),
    ];
    mapper.map(runtime);
    await resources.settle();
    expect(
      mapper
          .map(runtime, draftVersion: 'v2')
          .turns
          .single
          .reply!
          .blocks
          .whereType<AgentPositionBlock>(),
      isEmpty,
    );
  });

  test(
    'CodeMode native projections recover guarded diffs, image ids and Anlas',
    () async {
      final backupDir = Directory(
        '${runtime.workspace.agentDirectory.path}/draft-backups',
      );
      await backupDir.create(recursive: true);
      final backup = File('${backupDir.path}/native.json');
      await backup.writeAsString(
        jsonEncode({
          'fields': {'prompt': 'old'},
        }),
      );
      await File(
        '${runtime.workspace.directory.path}/out.png',
      ).writeAsBytes(png);
      runtime.messages = [
        assistant([call('code', 'codemode')]),
        result('code', {
          'studio_results': [
            {
              'tool': 'mcp__nai_studio__prompt_update',
              'applied': ['prompt'],
              'backup_path': backup.path,
              'draft': {
                'fields': {'prompt': 'new'},
                'draft_version': 'v1',
              },
            },
            {
              'tool': 'mcp__nai_studio__generation_run',
              'image_ids': ['h1'],
              'estimated_anlas': 40,
              'artifacts': [
                {'type': 'image', 'path': 'out.png'},
              ],
            },
          ],
          'artifacts': [
            {'type': 'image', 'path': 'out.png'},
          ],
        }),
      ];
      mapper.map(runtime);
      await resources.settle();
      final mapped = mapper.map(runtime, draftVersion: 'v1');
      final blocks = mapped.turns.single.reply!.blocks;
      expect(
        blocks.whereType<AgentDiffBlock>().single.diff.state,
        AgentDiffState.applied,
      );
      final images = blocks.whereType<AgentImagesBlock>().single;
      expect(images.anlasSpent, 40);
      expect(images.images.single.historyId, 'h1');
      expect(images.images.single.source, AgentImageSource.generated);
    },
  );

  test(
    'resource security rejects traversal, missing/corrupt images and external backups',
    () async {
      final external = File('${root.path}/outside.json');
      await external.writeAsString('{"fields":{}}');
      expect(resources.image(runtime.workspace, '../outside.png'), isNull);
      expect(resources.image(runtime.workspace, 'missing.png'), isNull);
      await File(
        '${runtime.workspace.directory.path}/corrupt.png',
      ).writeAsBytes(png.sublist(0, 33));
      resources.image(runtime.workspace, 'corrupt.png');
      expect(resources.snapshot(runtime.workspace, external.path), isNull);
      resources.file(runtime.workspace, external.path);
      await resources.settle();
      expect(resources.image(runtime.workspace, 'corrupt.png'), isNull);
      expect(resources.file(runtime.workspace, external.path), isNull);
      expect(resources.snapshot(runtime.workspace, external.path), isNull);
    },
  );

  test(
    'undo guards before backup and again after asynchronous backup, writes synchronously',
    () async {
      var version = 'v1', backups = 0, writes = 0;
      Future<bool> undo(String expected, {bool race = false}) =>
          guardedAgentUndo(
            expected: expected,
            version: () => version,
            backup: () async {
              backups++;
              if (race) version = 'changed';
            },
            apply: () {
              writes++;
            },
          );
      expect(await undo('stale'), false);
      expect(backups, 0);
      expect(await undo('v1', race: true), false);
      expect(writes, 0);
      version = 'v1';
      expect(await undo('v1'), true);
      expect(writes, 1);
      expect(await undo(''), false);
    },
  );

  test('thinking parts become a thinking block; live only while streaming', () {
    runtime.messages = [
      {'role': 'user', 'timestamp': 1, 'content': 'hi'},
      assistant([
        {'type': 'thinking', 'thinking': '  先读草稿再回答。  '},
        {'type': 'text', 'text': 'hello'},
      ]),
      {'role': 'user', 'timestamp': 2, 'content': 'again'},
      assistant([
        {'type': 'thinking', 'thinking': '还在想'},
      ]),
    ];
    runtime.running = true;
    var turns = mapper.map(runtime).turns;
    final first = turns.first.reply!.blocks;
    expect(first.first, isA<AgentThinkingBlock>());
    expect((first.first as AgentThinkingBlock).text, '先读草稿再回答。');
    expect((first.first as AgentThinkingBlock).live, false);
    expect(first.last, isA<AgentTextBlock>());
    final live = turns.last.reply!.blocks.single as AgentThinkingBlock;
    expect(live.live, true);
    runtime.running = false;
    turns = mapper.map(runtime).turns;
    expect((turns.last.reply!.blocks.single as AgentThinkingBlock).live, false);
    runtime.messages = [
      {'role': 'user', 'timestamp': 3, 'content': 'x'},
      assistant([
        {'type': 'thinking', 'thinking': '   '},
        {'type': 'text', 'text': 'ok'},
      ]),
    ];
    expect(
      mapper.map(runtime).turns.single.reply!.blocks.single,
      isA<AgentTextBlock>(),
      reason: 'empty thinking is dropped',
    );
  });
}

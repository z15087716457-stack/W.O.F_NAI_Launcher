import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_resources.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_settings_card.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_thread_mapper.dart';

void main() {
  late Directory root;
  late AgentChatRuntime runtime;
  late AgentResources resources;
  late AgentThreadMapper mapper;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-cards-');
    final store = AgentWorkspaceStore(root);
    final workspace = await store.createWorkspace('cards');
    runtime = AgentChatRuntime(
      workspace,
      await store.createChat(workspace.id, 'cards'),
      const AgentComposerState(),
    );
    resources = AgentResources(() {});
    mapper = AgentThreadMapper(resources);
  });
  tearDown(() async {
    await resources.settle();
    resources.dispose();
    await root.delete(recursive: true);
  });
  Map<String, dynamic> assistant(
    List<Map<String, dynamic>> content, {
    int? timestamp,
    Map? usage,
  }) => {
    'role': 'assistant',
    'content': content,
    if (timestamp != null) 'timestamp': timestamp,
    if (usage != null) 'usage': usage,
  };
  Map<String, dynamic> call(
    String id,
    String tool, [
    Map<String, dynamic> args = const {},
  ]) => {'type': 'toolCall', 'id': id, 'name': tool, 'arguments': args};
  Map<String, dynamic> result(String id, Map<String, dynamic> details) => {
    'role': 'toolResult',
    'toolCallId': id,
    'details': details,
  };
  List<AgentBlock> blocks({Map<String, Object?>? preferences}) =>
      mapper.map(runtime, preferences: preferences).turns.single.reply!.blocks;

  test(
    'settings labels, raw storage mapping, anchors and guarded/undone state',
    () {
      expect(agentSettingRows.keys.toSet(), SettingsPreferencesService.keys);
      final before = {
        'studio_theme_mode': 'light',
        'history_click_behavior': null,
        'enable_prompt_weight_scroll': false,
        'font_scale': 1.0,
        'tag_expansion_result_limit': 5,
        'locale': 'en',
      };
      final values = {
        ...before,
        'studio_theme_mode': 'dark',
        'history_click_behavior': 'open_detail',
        'enable_prompt_weight_scroll': true,
        'font_scale': 1.1,
        'tag_expansion_result_limit': 10,
      };
      runtime.messages = [
        assistant([call('settings', 'settings_update')]),
        result('settings', {
          'applied_fields': before.keys.toList(),
          'before': before,
          'values': values,
          'version': 'v',
        }),
      ];
      final card = blocks(
        preferences: values,
      ).whereType<AgentSettingsBlock>().single;
      expect(blocks(preferences: values).first, isA<AgentStepsBlock>());
      expect(card.changes, hasLength(5));
      expect(card.changes.first.label, currentL10n.set_apTheme);
      expect(card.changes.first.before, currentL10n.set_apLight);
      expect(card.changes.first.after, currentL10n.set_apDark);
      expect(card.changes.first.anchor, (
        section: 'appearance',
        anchor: 'themeMode',
      ));
      expect(card.changes[1].anchor, (
        section: 'canvas',
        anchor: 'historyClick',
      ));
      expect(card.changes[2].anchor, (
        section: 'generation',
        anchor: 'wheelWeight',
      ));
      expect(card.changes[2].after, currentL10n.set_on);
      expect(card.changes[3].anchor, isNull);
      expect(card.changes[3].after, '1.1×');
      expect(card.changes[4].anchor, isNull);
      expect(card.state, AgentDiffState.applied);
      expect(
        blocks(
          preferences: {...values, 'font_scale': 1.2},
        ).whereType<AgentSettingsBlock>().single.state,
        AgentDiffState.locked,
      );
      mapper.undone.add(card.id);
      expect(
        blocks().whereType<AgentSettingsBlock>().single.state,
        AgentDiffState.undone,
      );
    },
  );

  test(
    'only successful finished settings changes with full result get cards',
    () {
      runtime.messages = [
        assistant([call('a', 'settings_update')]),
        result('a', {
          'applied_fields': ['font_scale'],
          'values': {'font_scale': 1.1},
          'version': 'v',
        }),
      ];
      expect(blocks().whereType<AgentSettingsBlock>(), isEmpty);
      runtime.messages.last['details'] = {
        'ok': false,
        'before': {'font_scale': 1},
        'applied_fields': ['font_scale'],
        'values': {'font_scale': 1.1},
        'version': 'v',
      };
      expect(blocks().whereType<AgentSettingsBlock>(), isEmpty);
    },
  );

  test(
    'tag hits sorted/capped, unknown category, translated search and found wiki',
    () {
      runtime.messages = [
        assistant([
          call('a', 'tag_query'),
          call('b', 'studio_search'),
          call('c', 'wiki_query'),
        ]),
        result('a', {
          'tags': [
            {'tag': 'unknown', 'category': 'species'},
            for (var i = 0; i < 30; i++)
              {
                'tag': 't$i',
                'category': i == 29 ? 'artist' : 'general',
                'post_count': i,
                'zh': 'translated',
                'definition': '  ${'x' * 250}  ',
              },
          ],
        }),
        result('b', {
          'items': [
            {
              'name': 'search',
              'category': 'copyright',
              'translation': 'localized',
              'post_count': 8,
            },
          ],
        }),
        result('c', {
          'pages': [
            {'tag': 'missing', 'found': false},
            {'tag': 'found', 'body': '  wiki text  '},
          ],
        }),
      ];
      final steps = blocks().whereType<AgentStepsBlock>().single.steps;
      expect(steps.first.tags, hasLength(24));
      expect(steps.first.tags.first.tag, 't29');
      expect(steps.first.tags.first.category, AgentTagCategory.artist);
      expect(steps.first.tags.first.translation, 'translated');
      expect(steps.first.tags.first.summary!.length, 201);
      expect(steps[1].tags.single.category, AgentTagCategory.copyright);
      expect(steps[1].tags.single.translation, 'localized');
      expect(steps[2].tags.single.tag, 'found');
      expect(steps[2].tags.single.count, isNull);
      expect(steps[2].tags.single.summary, 'wiki text');
      (runtime.messages[1]['details'] as Map)['tags'] = [
        {'tag': 'unknown', 'category': 'lore'},
        {'tag': 'known', 'category': 'meta', 'post_count': 1},
      ];
      final tags = blocks()
          .whereType<AgentStepsBlock>()
          .single
          .steps
          .first
          .tags;
      expect(tags.last.category, AgentTagCategory.other);
    },
  );

  for (final entry in <String, (AgentGalleryAction, bool)>{
    'favorite': (AgentGalleryAction.favorite, true),
    'unfavorite': (AgentGalleryAction.unfavorite, true),
    'tags': (AgentGalleryAction.tags, true),
    'delete': (AgentGalleryAction.delete, true),
    'restore': (AgentGalleryAction.restore, true),
    'move_file': (AgentGalleryAction.move, true),
    'copy_file': (AgentGalleryAction.copy, false),
    'collection_add': (AgentGalleryAction.collectionAdd, true),
    'collection_remove': (AgentGalleryAction.collectionRemove, true),
    'export': (AgentGalleryAction.export, false),
  }.entries) {
    for (final persisted in [false, true]) {
      test(
        'gallery ${entry.key} projects count/target/undo persisted=$persisted',
        () {
          final update = ['favorite', 'unfavorite', 'tags'].contains(entry.key);
          final args = <String, dynamic>{
            'action': update ? 'update' : entry.key,
            'image_id': 'gallery:1',
            'target_folder': '/library/target',
            if (update)
              'changes': entry.key == 'tags'
                  ? {
                      'tags': ['new'],
                    }
                  : {'favorite': entry.key == 'favorite'},
          };
          final details = {
            'ok': true,
            'scope': 'library',
            'image_id': 'gallery:1',
            'image_version': 'v',
            'source_path': '/library/original/a.png',
            'collection_version': 'cv',
            'before': entry.key.startsWith('collection')
                ? {
                    'gallery:1': {'favorite': false, 'collection_ids': []},
                  }
                : {'favorite': false, 'tags': []},
            'image_versions': {'gallery:1': 'v'},
            if (entry.key.startsWith('collection'))
              'collection_name': 'Collection',
          };
          runtime.messages = [
            assistant([call('gallery', 'gallery_manage', args)]),
            result('gallery', details),
          ];
          if (persisted) {
            runtime.messages = [
              assistant([call('code', 'codemode')]),
              result('code', {
                'calls': [
                  {
                    'id': 'gallery',
                    'name': 'mcp__nai_studio__gallery_manage',
                    'status': 'ok',
                    'args': '{truncated',
                  },
                ],
                'studio_results': [
                  {
                    'tool': 'mcp__nai_studio__gallery_manage',
                    'tool_call_id': 'gallery',
                    'arguments': args,
                    ...details,
                  },
                ],
              }),
            ];
          }
          final projected = blocks();
          expect(projected.first, isA<AgentStepsBlock>());
          final card = projected.whereType<AgentGalleryBlock>().single;
          expect(card.action, entry.value.$1);
          expect(card.undoable, entry.value.$2);
          expect(card.count, 1);
          if (entry.key.endsWith('_file')) expect(card.target, 'target');
          if (entry.key.startsWith('collection')) {
            expect(card.target, 'Collection');
          }
          mapper.undone.add(card.id);
          expect(
            blocks().whereType<AgentGalleryBlock>().single.state,
            AgentDiffState.undone,
          );
        },
      );
    }
  }

  test('gallery thumbnail loader caches and caps cards to eight', () async {
    var reads = 0;
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 640, height: 400)),
    );
    resources.galleryLoader = (id) async {
      reads++;
      return bytes;
    };
    runtime.messages = [
      assistant([
        call('g', 'gallery_manage', {'action': 'collection_add'}),
      ]),
      result('g', {
        'ok': true,
        'image_ids': [for (var i = 1; i <= 10; i++) 'gallery:$i'],
      }),
    ];
    blocks();
    await resources.settle();
    final card = blocks().whereType<AgentGalleryBlock>().single;
    expect(card.count, 10);
    expect(card.images, hasLength(8));
    expect(reads, 8);
    expect(
      img
          .decodePng((card.images.first.image as dynamic).bytes as Uint8List)!
          .width,
      320,
    );
  });

  test(
    'deleted gallery previews can reuse an existing guarded image backup',
    () async {
      await File(
        '${runtime.workspace.directory.path}/deleted.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
      resources.galleryLoader = (_) async => null;
      runtime.messages = [
        assistant([
          call('g', 'gallery_manage', {'action': 'delete'}),
        ]),
        result('g', {
          'ok': true,
          'scope': 'library',
          'image_id': 'gallery:9',
          'image_version': 'v',
          'backup': {'path': 'deleted.png', 'file_missing': false},
        }),
      ];
      blocks();
      await resources.settle();
      expect(
        blocks().whereType<AgentGalleryBlock>().single.images,
        hasLength(1),
      );
    },
  );

  test('compaction goes after prior reply, or before first visible reply', () {
    final compaction = {
      'role': 'compactionSummary',
      'summary': 'summary',
      'tokensBefore': 12000,
      'timestamp': 3000,
    };
    runtime.autoCompactions.add(AgentChatRuntime.compactionKey(compaction));
    runtime.messages = [
      {'role': 'user', 'content': 'one'},
      assistant([
        {'type': 'text', 'text': 'one'},
      ]),
      compaction,
      {'role': 'user', 'content': 'two'},
      assistant([
        {'type': 'text', 'text': 'two'},
      ]),
    ];
    final turns = mapper.map(runtime).turns;
    final divider = turns.first.reply!.blocks.last as AgentCompactionBlock;
    expect(divider.summary, 'summary');
    expect(divider.tokensBefore, 12000);
    expect(divider.at!.millisecondsSinceEpoch, 3000);
    expect(divider.auto, true);
    expect(turns.last.reply!.blocks.whereType<AgentCompactionBlock>(), isEmpty);
    runtime.messages = [
      compaction,
      {'role': 'user', 'content': 'first'},
    ];
    expect(blocks().first, isA<AgentCompactionBlock>());
    runtime.autoCompactions.clear();
    expect((blocks().first as AgentCompactionBlock).auto, false);
  });

  Map<String, dynamic> mcpResult(Map<String, dynamic> native) => {
    'content': [
      {'type': 'text', 'text': 'native result'},
    ],
    'details': {'server': 'nai_studio', 'tool': 'synthetic'},
    'structuredContent': {
      'content': [
        {'type': 'text', 'text': 'native result'},
      ],
      'structuredContent': native,
    },
  };

  test('result details unwrap only recognized MCP envelopes', () {
    final native = {'tags': []};
    expect(agentResultDetails(mcpResult(native)), native);
    expect(agentResultDetails({'structuredContent': native}), native);
    expect(agentResultDetails({'details': native}), native);
    expect(agentResultDetails({'details': mcpResult(native)}), native);
    final unrelated = {'structuredContent': native, 'custom': true};
    expect(agentResultDetails({'structuredContent': unrelated}), unrelated);
  });

  for (final mode in ['live', 'persisted', 'both']) {
    test('CodeMode real Pi shape: $mode chips/cards and guarded undo once', () {
      const galleryArgs = {
        'action': 'collection_add',
        'image_ids': ['gallery:1'],
      };
      final native = <String, Map<String, dynamic>>{
        'tag_query': {
          'tags': [
            {'tag': 'nested', 'category': 'character', 'post_count': 4},
          ],
        },
        'wiki_query': {
          'pages': [
            {'tag': 'wiki', 'found': true, 'body': 'short body'},
          ],
        },
        'studio_search': {
          'items': [
            {'name': 'search', 'category': 'artist', 'post_count': 3},
          ],
        },
        'settings_update': {
          'applied_fields': ['font_scale'],
          'before': {'font_scale': 1},
          'values': {'font_scale': 1.1},
          'version': 'v',
        },
        'gallery_manage': {
          'ok': true,
          'collection_id': 'collection',
          'collection_name': 'Collection',
          'collection_version': 'cv',
          'image_ids': ['gallery:1'],
          'before': {
            'gallery:1': {'favorite': false, 'collection_ids': []},
          },
          'image_versions': {'gallery:1': 'iv'},
        },
      };
      runtime.messages = [
        assistant([call('code', 'codemode')]),
        result('code', {
          // Pi 1.3 persists calls directly, args is a truncated JSON preview.
          'calls': [
            for (final name in native.keys)
              {
                'id': name,
                'name': 'mcp__nai_studio__$name',
                'status': 'ok',
                'args': name == 'gallery_manage' ? '{truncated' : '{}',
              },
          ],
          if (mode != 'live')
            'studio_results': [
              for (final entry in native.entries)
                {
                  'tool': 'mcp__nai_studio__${entry.key}',
                  'tool_call_id': entry.key,
                  ...entry.value,
                  if (entry.key == 'gallery_manage') 'arguments': galleryArgs,
                },
            ],
        }),
      ];
      if (mode != 'persisted') {
        runtime.tools.addAll({
          for (final entry in native.entries)
            entry.key: {
              'type': 'tool_execution_end',
              'args': entry.key == 'gallery_manage' ? galleryArgs : {},
              'result': mcpResult(entry.value),
            },
        });
      }
      final mapped = mapper.map(runtime, preferences: {'font_scale': 1.1});
      final projected = mapped.turns.single.reply!.blocks;
      final hits = projected.whereType<AgentStepsBlock>().single.steps;
      expect(hits.expand((step) => step.tags).map((tag) => tag.tag), [
        'nested',
        'wiki',
        'search',
      ]);
      expect(projected.whereType<AgentSettingsBlock>(), hasLength(1));
      expect(projected.whereType<AgentGalleryBlock>(), hasLength(1));
      final setting = projected.whereType<AgentSettingsBlock>().single;
      expect(setting.state, AgentDiffState.applied);
      expect(mapped.settings[setting.id]!.matches({'font_scale': 1.1}), true);
      final gallery = projected.whereType<AgentGalleryBlock>().single;
      expect(gallery.undoable, true);
      expect(gallery.target, 'Collection');
      expect(mapped.gallery[gallery.id]!.arguments, galleryArgs);
      expect(
        mapped.gallery[gallery.id]!.details['collection_id'],
        'collection',
      );
      mapper.undone.addAll([setting.id, gallery.id]);
      final undone = blocks();
      expect(
        undone.whereType<AgentSettingsBlock>().single.state,
        AgentDiffState.undone,
      );
      expect(
        undone.whereType<AgentGalleryBlock>().single.state,
        AgentDiffState.undone,
      );
    });
  }

  test('direct live MCP results also unwrap for chips and settings cards', () {
    runtime.messages = [
      assistant([
        call('tag', 'mcp__nai_studio__tag_query'),
        call('setting', 'mcp__nai_studio__settings_update'),
      ]),
    ];
    runtime.tools.addAll({
      'tag': {
        'type': 'tool_execution_end',
        'result': mcpResult({
          'tags': [
            {'tag': 'direct'},
          ],
        }),
      },
      'setting': {
        'type': 'tool_execution_end',
        'result': mcpResult({
          'applied_fields': ['font_scale'],
          'before': {'font_scale': 1},
          'values': {'font_scale': 1.1},
          'version': 'v',
        }),
      },
    });
    final mapped = blocks(preferences: {'font_scale': 1.1});
    expect(mapped.whereType<AgentSettingsBlock>(), hasLength(1));
    expect(
      mapped.whereType<AgentStepsBlock>().single.steps.first.tags.single.tag,
      'direct',
    );
  });

  test(
    'finished summary uses timestamps, cards, images and last input plus summed output',
    () async {
      await File(
        '${runtime.workspace.directory.path}/out.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
      runtime.messages = [
        {'role': 'user', 'content': 'one', 'timestamp': 1000},
        assistant(
          [call('g', 'image_generate')],
          timestamp: 1500,
          usage: {'input': 10, 'output': 3},
        ),
        result('g', {
          'artifacts': [
            {'type': 'image', 'path': 'out.png'},
          ],
          'estimated_anlas': 7,
        }),
        assistant(
          [call('s', 'settings_update'), call('c', 'codemode')],
          timestamp: 4000,
          usage: {'input': 100, 'cacheRead': 20, 'cacheWrite': 5, 'output': 8},
        ),
        result('s', {
          'applied_fields': ['font_scale'],
          'before': {'font_scale': 1},
          'values': {'font_scale': 1.1},
          'version': 'v',
        }),
        result('c', {
          'nestedCalls': {
            'calls': [
              {'name': 'read', 'status': 'ok'},
              {'name': 'read', 'status': 'ok'},
            ],
          },
        }),
      ];
      blocks();
      await resources.settle();
      final summary = mapper.map(runtime).turns.single.reply!.summary!;
      expect(summary.took, const Duration(seconds: 3));
      expect(summary.anlas, 7);
      expect(summary.changes, 1);
      expect(summary.toolCalls, 3);
      expect(summary.inputTokens, 125);
      expect(summary.outputTokens, 11);
      runtime.running = true;
      expect(mapper.map(runtime).turns.single.reply!.summary, isNull);
      runtime.running = false;
      runtime.messages = [
        assistant(
          [
            {'type': 'text', 'text': 'no timestamp'},
          ],
          usage: {'input': 5, 'output': 2},
        ),
      ];
      expect(mapper.map(runtime).turns.single.reply!.summary, isNull);
    },
  );
}

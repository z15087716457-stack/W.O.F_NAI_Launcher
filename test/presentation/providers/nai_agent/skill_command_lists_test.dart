import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_commands_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/nai_agent_list_stand_ins.dart';

typedef _Lists = (NaiAgentSkillInventory, List<Map<String, dynamic>>);

/// What the panel shows of both lists: skills (key, state, on/off, mode,
/// description), the catalog size, commands (name, source, description).
List<String> _shown(_Lists lists) => [
  for (final s in lists.$1.skills)
    '${s.key} ${s.state} ${s.enabled} ${s.mode} ${s.description}',
  'catalog ${lists.$1.catalogChars}',
  for (final c in lists.$2) '/${c['name']} ${c['source']} ${c['description']}',
];

void main() {
  for (final platform in const [TargetPlatform.macOS, TargetPlatform.windows]) {
    final windows = platform == TargetPlatform.windows;
    group('${platform.name}:', () {
      late Directory root;
      late AgentWorkspaceStore store;
      late AgentWorkspace workspace;
      late NaiAgentRuntimePaths paths;
      late NodeListStandIn node;
      late NaiAgentUiPreferences preferences;
      late ProviderContainer container;

      ProviderContainer open({DateTime Function()? now}) => ProviderContainer(
        overrides: [
          naiAgentWorkspaceStoreProvider.overrideWithValue(store),
          naiAgentRuntimePathsProvider.overrideWithValue(paths),
          naiAgentListProcessStarterProvider.overrideWithValue(node.start),
          // Windows' file times: the change time is the creation time.
          if (windows)
            naiAgentFileStatProvider.overrideWithValue(windowsFileTimes()),
          naiAgentUiPreferencesProvider.overrideWith((ref) => preferences),
          naiAgentInventoryCacheProvider.overrideWith(
            (ref) => NaiAgentInventoryCache(
              // The test has just made every folder: a clock a minute
              // ahead takes them as old.
              now: now ?? () => DateTime.now().add(const Duration(minutes: 1)),
            ),
          ),
        ],
      );

      setUp(() async {
        debugDefaultTargetPlatformOverride = platform;
        root = await Directory.systemTemp.createTemp('nai-agent-lists-');
        store = AgentWorkspaceStore(
          Directory(p.join(root.path, 'agent-data')),
          builtinSkillsDirectory: Directory(
            p.join(root.path, 'runtime', 'nai-agent', 'skills'),
          ),
        );
        paths = writeStandInRuntime(root, windows: windows);
        workspace = await store.createWorkspace('Workspace');
        writeSkill(store.builtinSkillsDirectory, 'nai-prompt', 'Built-in');
        writeSkill(store.globalSkillsDirectory, 'demo', 'Demo skill');
        writeTemplate(store.globalPromptsDirectory, 'review', 'Review it');
        node = NodeListStandIn();
        preferences = NaiAgentUiPreferences();
        container = open();
      });
      tearDown(() async {
        container.dispose();
        debugDefaultTargetPlatformOverride = null;
        await root.delete(recursive: true);
      });

      Directory workspaceSkills([AgentWorkspace? w]) => store
          .skillSourceDirectory('workspace', workspaceId: (w ?? workspace).id);

      /// The Agent panel is up (the generation page is shown): both lists
      /// are watched.
      List<ProviderSubscription<Object?>> openPanel([String? id]) => [
        container.listen(naiAgentSkillsProvider(id ?? workspace.id), (_, _) {}),
        container.listen(
          naiAgentCommandsProvider(id ?? workspace.id),
          (_, _) {},
        ),
      ];

      Future<_Lists> lists([String? id]) async => (
        await container.read(naiAgentSkillsProvider(id ?? workspace.id).future),
        await container.read(
          naiAgentCommandsProvider(id ?? workspace.id).future,
        ),
      );

      /// Switching away: the panel goes with the generation page, and both
      /// list providers with it.
      Future<void> leave(
        List<ProviderSubscription<Object?>> panel, [
        String? id,
      ]) async {
        for (final listening in panel) {
          listening.close();
        }
        await container.pump();
        expect(
          container.exists(naiAgentSkillsProvider(id ?? workspace.id)),
          isFalse,
        );
        expect(
          container.exists(naiAgentCommandsProvider(id ?? workspace.id)),
          isFalse,
        );
      }

      /// One visit of the generation page: the panel comes up, both lists
      /// come in, then the page is left.
      Future<_Lists> visit([String? id]) async {
        final panel = openPanel(id);
        final result = await lists(id);
        await leave(panel, id);
        return result;
      }

      test('the first visit lists skills and commands once each, asking Node '
          'exactly what it asked before', () async {
        final first = await visit();
        expect(node.skillRuns, 1);
        expect(node.commandRuns, 1);
        final directory = p.dirname(paths.host);
        final skillRun = node.runs.singleWhere(
          (r) => r.script == 'list-skills.mjs',
        );
        expect(skillRun.executable, paths.node);
        expect(p.basename(skillRun.executable), windows ? 'node.exe' : 'node');
        expect(skillRun.arguments, [p.join(directory, 'list-skills.mjs')]);
        expect(skillRun.workingDirectory, directory);
        expect(skillRun.input, {
          'builtinDirectory': store.builtinSkillsDirectory.absolute.path,
          'globalDirectory': store.globalSkillsDirectory.absolute.path,
          'workspaceDirectory': workspaceSkills().absolute.path,
          'disabled': [],
          'modes': {},
          'cwd': workspace.directory.absolute.path,
          'agentDir': workspace.agentDirectory.absolute.path,
          'packages': {
            'globalDirectory': store.root.absolute.path,
            'entries': [],
          },
        });
        final commandRun = node.runs.singleWhere(
          (r) => r.script == 'list-commands.mjs',
        );
        expect(commandRun.executable, paths.node);
        expect(commandRun.arguments, [p.join(directory, 'list-commands.mjs')]);
        expect(commandRun.workingDirectory, directory);
        expect(commandRun.input, {
          'cwd': workspace.directory.absolute.path,
          'agentDir': workspace.agentDirectory.absolute.path,
          'globalDirectory': store.globalPromptsDirectory.absolute.path,
          'workspaceDirectory': workspace.prompts.absolute.path,
          'packages': {
            'globalDirectory': store.root.absolute.path,
            'entries': [],
          },
        });
        // What the stand-in Node answered, passed through unchanged.
        expect(_shown(first), [
          'global/demo active true auto Demo skill',
          'builtin/nai-prompt active true auto Built-in',
          'catalog 152',
          '/review global Review it',
        ]);
      });

      test('coming back five times starts no more Node and shows the same '
          'lists', () async {
        final first = _shown(await visit());
        for (var i = 0; i < 5; i++) {
          expect(_shown(await visit()), first);
        }
        expect(node.skillRuns, 1);
        expect(node.commandRuns, 1);
      });

      test('disabled packages retain ordinary inventory caching', () async {
        preferences.replace(
          const AgentSettings(
            packages: [
              AgentPackageConfig(
                source: 'disabled-local-package',
                enabled: false,
              ),
            ],
          ),
        );
        final first = _shown(await visit());
        expect(_shown(await visit()), first);
        expect((node.skillRuns, node.commandRuns), (1, 1));
      });

      test('a skill folder added, edited or removed while away is listed '
          'again on return; the commands are not', () async {
        await visit();
        writeSkill(store.globalSkillsDirectory, 'added', 'Added skill');
        var shown = _shown(await visit());
        expect(shown, contains('global/added active true auto Added skill'));
        expect((node.skillRuns, node.commandRuns), (2, 1));

        writeSkill(store.globalSkillsDirectory, 'added', 'Added, then edited');
        shown = _shown(await visit());
        expect(
          shown,
          contains('global/added active true auto Added, then edited'),
        );
        expect((node.skillRuns, node.commandRuns), (3, 1));

        writeSkill(workspaceSkills(), 'local', 'Workspace skill');
        shown = _shown(await visit());
        expect(
          shown,
          contains('workspace/local active true auto Workspace skill'),
        );
        expect((node.skillRuns, node.commandRuns), (4, 1));

        Directory(
          p.join(store.globalSkillsDirectory.path, 'added'),
        ).deleteSync(recursive: true);
        shown = _shown(await visit());
        expect(shown.where((s) => s.startsWith('global/added')), isEmpty);
        expect((node.skillRuns, node.commandRuns), (5, 1));

        await visit();
        expect((node.skillRuns, node.commandRuns), (5, 1));
      });

      test('a command template added, edited or removed while away is listed '
          'again on return; the skills are not', () async {
        await visit();
        writeTemplate(workspace.prompts, 'draft', 'Draft it');
        var shown = _shown(await visit());
        expect(shown, contains('/draft workspace Draft it'));
        expect((node.skillRuns, node.commandRuns), (1, 2));

        writeTemplate(store.globalPromptsDirectory, 'review', 'Review again');
        shown = _shown(await visit());
        expect(shown, contains('/review global Review again'));
        expect((node.skillRuns, node.commandRuns), (1, 3));

        File(p.join(workspace.prompts.path, 'draft.md')).deleteSync();
        shown = _shown(await visit());
        expect(shown.where((s) => s.startsWith('/draft')), isEmpty);
        expect((node.skillRuns, node.commandRuns), (1, 4));

        await visit();
        expect((node.skillRuns, node.commandRuns), (1, 4));
      });

      test('an explicit refresh lists both again, also with nothing changed '
          'on disk', () async {
        await visit();
        container.read(naiAgentSkillRevisionProvider.notifier).state++;
        await visit();
        expect((node.skillRuns, node.commandRuns), (2, 2));
        await visit();
        expect((node.skillRuns, node.commandRuns), (2, 2));
      });

      test(
        'a refresh while the panel is open lists again right away',
        () async {
          final panel = openPanel();
          await lists();
          // What the settings page does after importing a skill.
          writeSkill(store.globalSkillsDirectory, 'imported', 'Imported skill');
          container.read(naiAgentSkillRevisionProvider.notifier).state++;
          final shown = _shown(await lists());
          expect(
            shown,
            contains('global/imported active true auto Imported skill'),
          );
          expect((node.skillRuns, node.commandRuns), (2, 2));
          await leave(panel);
        },
      );

      test('settings written again with the same skill switches list nothing; '
          'switching a skill off or to manual lists again', () async {
        final panel = openPanel();
        await lists();
        // Another setting saved (the panel width after a drag): the switches
        // come back as new lists with the same content.
        preferences.replace(
          AgentSettings.fromJson({
            ...preferences.settings.toJson(),
            'panelWidth': 600,
          }),
        );
        await lists();
        expect((node.skillRuns, node.commandRuns), (1, 1));

        preferences.replace(
          AgentSettings.fromJson({
            ...preferences.settings.toJson(),
            'disabledSkills': ['global/demo'],
          }),
        );
        var shown = _shown(await lists());
        expect(shown, contains('global/demo disabled false auto Demo skill'));
        expect((node.skillRuns, node.commandRuns), (2, 1));

        preferences.replace(
          AgentSettings.fromJson({
            ...preferences.settings.toJson(),
            'skillModes': {'builtin/nai-prompt': 'manual'},
          }),
        );
        shown = _shown(await lists());
        expect(
          shown,
          contains('builtin/nai-prompt active true manual Built-in'),
        );
        expect((node.skillRuns, node.commandRuns), (3, 1));
        await leave(panel);

        await visit();
        expect((node.skillRuns, node.commandRuns), (3, 1));
      });

      test('coming back while the first listing still runs shares it; '
          'nothing is stopped', () async {
        node.hold = Completer<void>();
        var panel = openPanel();
        for (var i = 0; i < 200 && node.runs.length < 2; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect((node.skillRuns, node.commandRuns), (1, 1));
        await leave(panel);

        panel = openPanel();
        final shown = lists();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        node.hold!.complete();
        expect(
          _shown(await shown),
          contains('global/demo active true auto Demo skill'),
        );
        expect((node.skillRuns, node.commandRuns), (1, 1));
        expect(node.runs.where((r) => r.killed), isEmpty);
        await leave(panel);

        await visit();
        expect((node.skillRuns, node.commandRuns), (1, 1));
      });

      test(
        'a listing that fails is not kept: the next visit lists again',
        () async {
          node.failNext('list-skills.mjs', 'Skill folder unreadable');
          final panel = openPanel();
          await expectLater(
            container.read(naiAgentSkillsProvider(workspace.id).future),
            throwsA(isA<StateError>()),
          );
          await leave(panel);

          final shown = _shown(await visit());
          expect(shown, contains('global/demo active true auto Demo skill'));
          expect((node.skillRuns, node.commandRuns), (2, 1));
          await visit();
          expect((node.skillRuns, node.commandRuns), (2, 1));
        },
      );

      test('each workspace and the settings page without one keep their own '
          'lists', () async {
        final other = await store.createWorkspace('Other');
        writeSkill(workspaceSkills(other), 'other-only', 'Other skill');
        await visit();
        final shownOther = _shown(await visit(other.id));
        expect(
          shownOther,
          contains('workspace/other-only active true auto Other skill'),
        );
        expect((node.skillRuns, node.commandRuns), (2, 2));

        final settings = container.listen(
          naiAgentSkillsProvider(null),
          (_, _) {},
        );
        final noWorkspace = await container.read(
          naiAgentSkillsProvider(null).future,
        );
        expect(noWorkspace.config.containsKey('workspaceDirectory'), isFalse);
        settings.close();
        await container.pump();
        expect((node.skillRuns, node.commandRuns), (3, 2));

        await visit();
        await visit(other.id);
        final again = container.listen(naiAgentSkillsProvider(null), (_, _) {});
        await container.read(naiAgentSkillsProvider(null).future);
        again.close();
        expect((node.skillRuns, node.commandRuns), (3, 2));
      });

      test('folders changed just now are listed again on the next visit; '
          'once settled the list is kept', () async {
        container.dispose();
        preferences = NaiAgentUiPreferences();
        writeSkill(store.globalSkillsDirectory, 'fresh', 'Just written');
        var now = DateTime.now();
        container = open(now: () => now);
        await visit();
        await visit();
        expect(node.skillRuns, 2);

        now = now.add(const Duration(seconds: 3));
        await visit();
        await visit();
        await visit();
        expect(node.skillRuns, 3);
      });
    });
  }
}

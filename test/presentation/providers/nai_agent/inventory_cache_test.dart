import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_commands_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_management.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/agent_test_node.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  late AgentWorkspace workspace;
  late ProviderContainer container;
  late File skillCalls, commandCalls, failCommands;

  Future<void> write(String path, String text) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  Future<void> skill(Directory folder, String name, String description) =>
      write(
        p.join(folder.path, name, 'SKILL.md'),
        '---\nname: $name\ndescription: $description\n---\nLocal test skill\n',
      );

  Future<void> command(Directory folder, String name, String description) =>
      write(
        p.join(folder.path, '$name.md'),
        '---\ndescription: $description\n---\nLocal test command\n',
      );

  Future<T> read<T>(AutoDisposeFutureProvider<T> provider) async {
    final subscription = container.listen(provider, (_, _) {});
    try {
      return await container.read(provider.future);
    } finally {
      subscription.close();
      await container.pump();
    }
  }

  Future<Map<String, String>> skills([AgentWorkspace? target]) async => {
    for (final skill in (await read(
      naiAgentSkillsProvider((target ?? workspace).id),
    )).skills)
      skill.name: skill.description,
  };

  Future<Map<String, String>> commands([AgentWorkspace? target]) async => {
    for (final command in await read(
      naiAgentCommandsProvider((target ?? workspace).id),
    ))
      command['name'] as String: command['description'] as String,
  };

  Future<void> updateSettings(Map<String, dynamic> changes) async {
    final value = await store.patchSettings(changes);
    container.read(naiAgentUiPreferencesProvider).replace(value);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-inventory-');
    store = AgentWorkspaceStore(
      Directory(p.join(root.path, 'store')),
      builtinSkillsDirectory: Directory(p.join(root.path, 'builtin-skills')),
    );
    workspace = await store.createWorkspace('Fixture');
    skillCalls = File(p.join(root.path, 'skills.log'));
    commandCalls = File(p.join(root.path, 'commands.log'));
    failCommands = File(p.join(root.path, 'fail-commands'));
    for (final (name, calls) in [
      ('skills', skillCalls),
      ('commands', commandCalls),
    ]) {
      final script = 'list-$name.mjs';
      final original = File(p.join('tool', 'nai_agent', script)).absolute.uri;
      await write(p.join(root.path, script), '''
import { appendFile, access } from 'node:fs/promises';

await appendFile(${jsonEncode(calls.path)}, 'run\\n');
const fail = ${name == 'commands'} &&
  await access(${jsonEncode(failCommands.path)}).then(() => true, () => false);
if (fail) console.log(JSON.stringify({error: 'fixture resolver failed'}));
else await import(${jsonEncode(original.toString())});
''');
    }
    container = ProviderContainer(
      overrides: [
        naiAgentWorkspaceStoreProvider.overrideWithValue(store),
        naiAgentRuntimePathsProvider.overrideWithValue(
          NaiAgentRuntimePaths(
            node: agentTestNode,
            host: p.join(root.path, 'host.mjs'),
          ),
        ),
      ],
    );
    await container.read(naiAgentUiPreferencesProvider).load(store);
  });

  tearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
  });

  test(
    'revisiting both inventories reuses data until an existing refresh',
    () async {
      final workspaceSkills = store.skillSourceDirectory(
        'workspace',
        workspaceId: workspace.id,
      );
      await skill(workspaceSkills, 'fixture-skill', 'Original skill');
      await command(workspace.prompts, 'fixture-command', 'Original command');
      final (firstSkills, firstCommands) = await (skills(), commands()).wait;
      expect(firstSkills['fixture-skill'], 'Original skill');
      expect(firstCommands['fixture-command'], 'Original command');
      expect(container.exists(naiAgentSkillsProvider(workspace.id)), isFalse);
      expect(container.exists(naiAgentCommandsProvider(workspace.id)), isFalse);

      await skill(workspaceSkills, 'fixture-skill', 'Updated skill');
      await command(workspace.prompts, 'fixture-command', 'Updated command');
      await updateSettings({'panelExpanded': true});
      final (cachedSkills, cachedCommands) = await (skills(), commands()).wait;
      expect(cachedSkills, firstSkills);
      expect(cachedCommands, firstCommands);
      expect(await skillCalls.readAsLines(), hasLength(1));
      expect(await commandCalls.readAsLines(), hasLength(1));

      final other = await store.createWorkspace('Other');
      expect(await skills(other), isNot(contains('fixture-skill')));
      expect(await commands(other), isNot(contains('fixture-command')));
      expect(await skillCalls.readAsLines(), hasLength(2));
      expect(await commandCalls.readAsLines(), hasLength(2));

      container.read(naiAgentManagementProvider).refresh();
      expect((await skills())['fixture-skill'], 'Updated skill');
      expect((await commands())['fixture-command'], 'Updated command');
      expect(await skillCalls.readAsLines(), hasLength(3));
      expect(await commandCalls.readAsLines(), hasLength(3));
      expect(container.exists(naiAgentControllerProvider), isFalse);
    },
  );

  test(
    'failed reads retry and scoped package configuration rescans both lists',
    () async {
      await failCommands.create();
      await expectLater(commands(), throwsA(isA<StateError>()));
      await failCommands.delete();
      expect(await commands(), isEmpty);
      expect(await commandCalls.readAsLines(), hasLength(2));
      expect(await skills(), isEmpty);

      final source = Directory(p.join(root.path, 'local package'));
      final packageSkills = Directory(p.join(source.path, 'skills'));
      final packagePrompts = Directory(p.join(source.path, 'prompts'));
      await write(
        p.join(source.path, 'package.json'),
        jsonEncode({
          'name': 'fixture-package',
          'version': '1.0.0',
          'pi': {
            'skills': ['./skills'],
            'prompts': ['./prompts'],
          },
        }),
      );
      await skill(packageSkills, 'package-skill', 'Packaged skill');
      await command(packagePrompts, 'package-command', 'Packaged command');
      await updateSettings({
        'packages': [
          AgentPackageConfig(
            source: source.path,
            workspaceId: workspace.id,
          ).toJson(),
        ],
      });
      expect((await skills())['package-skill'], 'Packaged skill');
      expect((await commands())['package-command'], 'Packaged command');

      await skill(packageSkills, 'package-skill', 'Changed skill');
      await command(packagePrompts, 'package-command', 'Changed command');
      expect((await skills())['package-skill'], 'Changed skill');
      expect((await commands())['package-command'], 'Changed command');
      expect(await skillCalls.readAsLines(), hasLength(3));
      expect(await commandCalls.readAsLines(), hasLength(4));
    },
  );

  test('concurrent reads share work and failures are evicted', () async {
    final cache = NaiAgentInventoryCache<int>();
    final config = <String, dynamic>{
      'packages': {'entries': <Map<String, Object>>[]},
    };
    final result = Completer<int>();
    final first = cache.read('workspace', config, () => result.future);
    final second = cache.read(
      'workspace',
      config,
      () async => fail('duplicate read'),
    );
    expect(second, same(first));
    final failed = expectLater(first, throwsA(isA<StateError>()));
    result.completeError(StateError('failed'));
    await failed;
    expect(await cache.read('workspace', config, () async => 42), 42);
  });
}

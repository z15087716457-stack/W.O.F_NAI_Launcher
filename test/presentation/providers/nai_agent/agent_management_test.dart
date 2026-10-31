import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_management.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';

class _Secrets extends SecureStorageService {
  final values = <String, String>{};
  @override
  Future<String?> readAgentMcpConfig(String id) async => values[id];
  @override
  Future<void> saveAgentMcpConfig(String id, String value) async {
    values[id] = value;
  }

  @override
  Future<void> deleteAgentMcpConfig(String id) async {
    values.remove(id);
  }
}

void main() {
  late Directory root;
  late NaiAgentWorkspaceController c;
  late ProviderContainer container;
  late NaiAgentManagement management;
  late _Secrets secrets;
  late String workspace;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-manage-');
    final store = AgentWorkspaceStore(root);
    c = NaiAgentWorkspaceController(
      store: store,
      initialWorkspaceName: 'Test',
      initialChatName: 'Test',
      startClient: (_, __, ___, ____, _____) async =>
          throw StateError('No model/network'),
    );
    await c.initialize();
    workspace = c.selectedWorkspace!.id;
    secrets = _Secrets();
    final preferences = NaiAgentUiPreferences()..replace(c.settings);
    c.addListener(() => preferences.replace(c.settings));
    final node = (await Process.run('node', [
      '-p',
      'process.execPath',
    ])).stdout.toString().trim();
    container = ProviderContainer(
      overrides: [
        naiAgentWorkspaceStoreProvider.overrideWithValue(store),
        naiAgentControllerProvider.overrideWith((_) => c),
        naiAgentUiPreferencesProvider.overrideWith((_) => preferences),
        naiAgentRuntimePathsProvider.overrideWithValue(
          NaiAgentRuntimePaths(
            node: node,
            host: p.absolute('tool/nai_agent/host.mjs'),
          ),
        ),
        secureStorageServiceProvider.overrideWithValue(secrets),
      ],
    );
    management = container.read(naiAgentManagementProvider);
    container.read(naiAgentControllerProvider);
  });
  tearDown(() async {
    await c.close();
    container.dispose();
    await root.delete(recursive: true);
  });
  Future<Map<String, dynamic>> run(Map<String, dynamic> args) async =>
      (await management.execute(
            workspace,
            args,
            NaiAgentCancellation(),
          ))['details']
          as Map<String, dynamic>;

  test(
    'MCP self-management shares encrypted persistence and preserves unrelated credentials',
    () async {
      await run({
        'resource': 'mcp',
        'action': 'add',
        'name': 'web',
        'changes': {
          'url': 'https://example.invalid/mcp',
          'headers': {'x-api-key': 'fixture-private-key'},
          'exposure': 'codemode',
        },
      });
      final first = (await c.store.readSettings()).mcpServers.single;
      expect(secrets.values[first.configId], contains('fixture-private-key'));
      expect(
        await File('${root.path}/settings.json').readAsString(),
        isNot(contains('fixture-private-key')),
      );
      final read = await run({'resource': 'mcp'});
      expect(jsonEncode(read), isNot(contains('fixture-private-key')));
      await run({
        'resource': 'mcp',
        'action': 'update',
        'id': 'web',
        'changes': {'description': 'changed'},
      });
      final changed = (await c.store.readSettings()).mcpServers.single;
      expect(changed.configId, isNot(first.configId));
      expect(secrets.values[first.configId], isNull);
      expect(secrets.values[changed.configId], contains('fixture-private-key'));
      await run({
        'resource': 'mcp',
        'action': 'update',
        'id': 'web',
        'changes': {
          'headers': {'x-other': 'second-fixture'},
        },
      });
      var config = await management.mcpConfig(c.settings.mcpServers.single);
      expect(config['headers'], {
        'x-api-key': 'fixture-private-key',
        'x-other': 'second-fixture',
      });
      await run({
        'resource': 'mcp',
        'action': 'update',
        'id': 'web',
        'changes': {
          'headers': {'x-other': null},
        },
      });
      config = await management.mcpConfig(c.settings.mcpServers.single);
      expect(config['headers'], {'x-api-key': 'fixture-private-key'});
      await expectLater(
        run({'resource': 'mcp', 'action': 'disable', 'id': 'missing'}),
        throwsFormatException,
      );
      await run({'resource': 'mcp', 'action': 'disable', 'id': 'nai_studio'});
      expect(c.settings.studioMcpEnabled, isFalse);
      await run({'resource': 'mcp', 'action': 'enable', 'id': 'nai_studio'});
      expect(c.settings.studioMcpEnabled, isTrue);
      await run({
        'resource': 'mcp',
        'action': 'update',
        'id': 'nai_studio',
        'changes': {'exposure': 'deferred'},
      });
      expect(c.settings.studioMcpExposure, 'deferred');
      await run({'resource': 'mcp', 'action': 'remove', 'id': 'web'});
      expect(c.settings.mcpServers, isEmpty);
      expect(secrets.values, isEmpty);
    },
  );

  test('cancelling MCP inspection closes its owned local server process', () async {
    final token = NaiAgentCancellation();
    final pid = File(p.join(root.path, 'owned-mcp-pid'));
    final node = container.read(naiAgentRuntimePathsProvider).node;
    final operation = management.execute(workspace, {
      'resource': 'mcp',
      'action': 'test',
      'name': 'held',
      'changes': {
        'command': node,
        'args': [
          '-e',
          'require("node:fs").writeFileSync(${jsonEncode(pid.path)}, String(process.pid)); setInterval(() => {}, 1000);',
        ],
        'timeout': 30,
      },
    }, token);
    final stopped = expectLater(
      operation,
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    try {
      for (var i = 0; i < 500 && !await pid.exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(await pid.exists(), isTrue);
    } finally {
      token.cancel();
      await stopped;
    }
    final owned = int.parse(await pid.readAsString());
    final probe = await Process.run(node, [
      '-e',
      'try { process.kill($owned, 0); process.exit(1); } catch { process.exit(0); }',
    ]);
    expect(probe.exitCode, 0, reason: 'Owned MCP child survived cancellation');
  });

  test(
    'workspace prompt overrides and reset share existing storage without replacing global prompt',
    () async {
      await c.updateSettings({'customSystemPrompt': 'GLOBAL'});
      final read = await run({'resource': 'instructions'});
      final result = await run({
        'resource': 'instructions',
        'action': 'update',
        'expected_version': read['version'],
        'changes': {'customSystemPrompt': 'WORKSPACE'},
      });
      expect(
        (await c.store.getWorkspace(workspace)).customSystemPrompt,
        'WORKSPACE',
      );
      expect(c.settings.customSystemPrompt, 'GLOBAL');
      expect(result['applies'], 'next_turn');
      expect(await File(result['backup_path'] as String).exists(), isTrue);
      final current = await run({'resource': 'instructions'});
      await run({
        'resource': 'instructions',
        'action': 'update',
        'expected_version': current['version'],
        'changes': current['defaults'],
      });
      expect(
        (await c.store.getWorkspace(workspace)).customSystemPrompt,
        isNull,
      );
      expect(c.settings.customSystemPrompt, 'GLOBAL');
    },
  );

  test(
    'settings boundary rejects invalid values without silently coercing them',
    () async {
      final read = await run({'resource': 'settings'});
      for (final changes in [
        {'permissionMode': 'unknown'},
        {'cacheWarming': 'always'},
        {'enterToSend': 'true'},
        {'maxRequestsPerRun': 0},
        {
          'reasoningEfforts': {'model': 'ultra'},
        },
      ]) {
        await expectLater(
          run({
            'resource': 'settings',
            'action': 'update',
            'expected_version': read['version'],
            'changes': changes,
          }),
          throwsFormatException,
        );
      }
      expect((await run({'resource': 'settings'}))['version'], read['version']);
    },
  );

  test(
    'settings update backs up current values and rejects stale reads',
    () async {
      final read = await run({'resource': 'settings'});
      await c.saveComposer('keep this draft');
      final result = await run({
        'resource': 'settings',
        'action': 'update',
        'expected_version': read['version'],
        'changes': {'nextSuggestion': false, 'globalInstructions': 'New rules'},
      });
      expect(c.settings.nextSuggestion, isFalse);
      expect(c.settings.globalInstructions, 'New rules');
      expect(c.selected!.composer.text, 'keep this draft');
      expect(await File(result['backup_path'] as String).exists(), isTrue);
      await expectLater(
        run({
          'resource': 'settings',
          'action': 'update',
          'expected_version': read['version'],
          'changes': {'globalInstructions': 'stale'},
        }),
        throwsFormatException,
      );
      expect((await c.store.readSettings()).globalInstructions, 'New rules');
    },
  );

  test(
    'local extension registration is persistent and removing it retains source',
    () async {
      final file = File(
        '${c.selectedWorkspace!.agentDirectory.path}/extensions/custom.mjs',
      );
      await file.parent.create(recursive: true);
      await file.writeAsString('export default pi => {};');
      await run({
        'resource': 'extensions',
        'action': 'add',
        'source': file.path,
      });
      expect(c.settings.enabledExtensionPaths, [p.normalize(file.path)]);
      await run({
        'resource': 'extensions',
        'action': 'disable',
        'id': file.path,
      });
      expect((await c.store.readSettings()).extensions.single.enabled, isFalse);
      await run({
        'resource': 'extensions',
        'action': 'remove',
        'id': file.path,
      });
      expect(c.settings.extensions, isEmpty);
      expect(await file.exists(), isTrue);
    },
  );

  test(
    'package install, package-owned skill switches and uninstall share original files',
    () async {
      final source = Directory(p.join(root.path, 'local package'));
      final skill = File(
        p.join(source.path, 'skills', 'fixture-skill', 'SKILL.md'),
      );
      await skill.parent.create(recursive: true);
      await skill.writeAsString(
        '---\nname: fixture-skill\ndescription: Native package fixture\n---\nLocal files.\n',
      );
      await File(p.join(source.path, 'package.json')).writeAsString(
        jsonEncode({
          'name': 'fixture-package',
          'version': '1.0.0',
          'pi': {
            'skills': ['./skills'],
          },
        }),
      );
      await run({
        'resource': 'packages',
        'action': 'install',
        'source': source.path,
      });
      expect(c.settings.packages.single.workspaceId, workspace);
      final inventory = await container.read(
        naiAgentSkillsProvider(workspace).future,
      );
      final entry = inventory.skills.singleWhere(
        (s) => s.name == 'fixture-skill',
      );
      expect(p.normalize(entry.file), p.normalize(skill.path));
      expect(entry.packageSource, c.settings.packages.single.source);
      await run({'resource': 'skills', 'action': 'disable', 'id': entry.key});
      final disabled = await container.read(
        naiAgentSkillsProvider(workspace).future,
      );
      expect(
        disabled.skills.singleWhere((s) => s.key == entry.key).state,
        'disabled',
      );
      await run({
        'resource': 'packages',
        'action': 'uninstall',
        'source': source.path,
      });
      expect((await c.store.readSettings()).packages, isEmpty);
      final cleared = await container.read(
        naiAgentSkillsProvider(workspace).future,
      );
      expect(cleared.skills.where((s) => s.packageSource != null), isEmpty);
      expect(await skill.exists(), isTrue);
    },
  );

  test(
    'native skill create, invocation mode and removal reuse the existing trash',
    () async {
      await run({
        'resource': 'skills',
        'action': 'create',
        'name': 'own-skill',
      });
      var inventory = await container.read(
        naiAgentSkillsProvider(workspace).future,
      );
      expect(
        inventory.skills.any((s) => s.key == 'workspace/own-skill'),
        isTrue,
      );
      await run({
        'resource': 'skills',
        'action': 'update',
        'id': 'workspace/own-skill',
        'changes': {'mode': 'manual'},
      });
      inventory = await container.read(
        naiAgentSkillsProvider(workspace).future,
      );
      expect(
        inventory.skills
            .singleWhere((s) => s.key == 'workspace/own-skill')
            .mode,
        'manual',
      );
      await run({
        'resource': 'skills',
        'action': 'remove',
        'id': 'workspace/own-skill',
      });
      expect(
        (await c.store.listTrash()).any((e) => e.kind == AgentTrashKind.skill),
        isTrue,
      );
    },
  );
}

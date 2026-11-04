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

  for (final action in ['install', 'update']) {
    test(
      'cancelled POSIX package $action stops its child and grandchild only',
      () async {
        final scripts = await Directory(
          p.join(root.path, 'sdk scripts'),
        ).create();
        // Copy the shipped launchers and substitute only the SDK work behind them.
        for (final file in Directory(
          'tool/nai_agent',
        ).listSync().whereType<File>()) {
          if (p.extension(file.path) == '.mjs') {
            await file.copy(p.join(scripts.path, p.basename(file.path)));
          }
        }
        final pids = File(p.join(root.path, 'owned-pids'));
        await File(p.join(scripts.path, 'manage-resources.mjs')).writeAsString(
          '''
import { spawn } from 'node:child_process';
import { appendFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
const script = fileURLToPath(import.meta.url);
let [depth, record] = process.argv.slice(2);
if (!record) {
  let input = '';
  for await (const data of process.stdin) input += data;
  record = JSON.parse(input).record;
  depth = 2;
}
appendFileSync(record, process.pid + '\\n');
if (depth > 0) spawn(process.execPath, [script, depth - 1, record], { stdio: 'ignore' });
if (depth < 2) process.on('SIGTERM', () => {});
setInterval(() => {}, 1000);
''',
        );
        final runtime = container.read(naiAgentRuntimePathsProvider);
        final isolated = ProviderContainer(
          overrides: [
            naiAgentRuntimePathsProvider.overrideWithValue(
              NaiAgentRuntimePaths(
                node: runtime.node,
                host: p.join(scripts.path, 'host.mjs'),
              ),
            ),
          ],
        );
        addTearDown(isolated.dispose);
        final token = NaiAgentCancellation();
        final sibling = await Process.start('/bin/sleep', ['60']);
        addTearDown(() async {
          token.cancel();
          if (pids.existsSync()) {
            for (final pid in pids.readAsLinesSync().map(int.parse)) {
              Process.killPid(pid, ProcessSignal.sigkill);
            }
          }
          sibling.kill(ProcessSignal.sigkill);
          await sibling.exitCode;
        });
        final stopped = expectLater(
          isolated.read(naiAgentManagementProvider).runSdk({
            'resource': 'packages',
            'action': action,
            'record': pids.path,
          }, cancellation: token),
          throwsA(
            isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
          ),
        );
        final ready = Stopwatch()..start();
        while ((!pids.existsSync() || pids.readAsLinesSync().length != 3) &&
            ready.elapsed < const Duration(seconds: 5)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        final family = pids.readAsLinesSync().map(int.parse).toList();
        expect(family, hasLength(3));
        token.cancel();
        await stopped.timeout(const Duration(seconds: 5));
        Future<bool> alive(int pid) async {
          final state = await Process.run('/bin/kill', ['-0', '$pid']);
          return state.exitCode == 0;
        }

        final deadline = Stopwatch()..start();
        var surviving = family;
        while (surviving.isNotEmpty &&
            deadline.elapsed < const Duration(seconds: 2)) {
          surviving = [
            for (final pid in surviving)
              if (await alive(pid)) pid,
          ];
          if (surviving.isNotEmpty) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
        }
        expect(
          surviving,
          isEmpty,
          reason: 'npm/git descendants must exit with their request',
        );
        expect(await alive(sibling.pid), isTrue);
      },
      skip: Platform.isWindows,
    );
  }

  test(
    'the bundled macOS Node reports its minimum before either Agent entry starts',
    () async {
      final installed = container.read(naiAgentRuntimePathsProvider);
      for (final version in [
        'Version 12.7.6 (Build 21H1320)',
        'Version 13.4.1 (Build 22F82)',
      ]) {
        final paths = NaiAgentRuntimePaths(
          node: installed.node,
          host: installed.host,
          bundledMacOSVersion: version,
        );
        final unsupported = throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.message,
            'minimum',
            contains('13.5'),
          ),
        );
        await expectLater(paths.check(), unsupported);
        final isolated = ProviderContainer(
          overrides: [naiAgentRuntimePathsProvider.overrideWithValue(paths)],
        );
        addTearDown(isolated.dispose);
        await expectLater(
          isolated.read(naiAgentManagementProvider).runSdk({
            'resource': 'packages',
            'action': 'resolve',
            'entries': [],
          }),
          unsupported,
        );
      }
      for (final version in [
        null,
        'Version 13.5 (Build 22G74)',
        'Version 14.0 (Build 23A344)',
      ]) {
        final paths = NaiAgentRuntimePaths(
          node: installed.node,
          host: installed.host,
          bundledMacOSVersion: version,
        );
        await paths.check();
        expect(paths.node, installed.node);
      }
    },
  );

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
          'displayName': 'EXA免费联网搜索',
        },
      });
      final first = (await c.store.readSettings()).mcpServers.single;
      expect(first.label, 'EXA免费联网搜索');
      expect(first.name, 'web');
      expect(await management.mcpConfig(first), isNot(contains('displayName')));
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
      expect(changed.label, 'EXA免费联网搜索');
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

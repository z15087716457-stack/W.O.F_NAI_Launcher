import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/mcp_config.dart';
import '../../../core/nai_agent/settings_tools.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import 'nai_agent_workspace_provider.dart';
import 'nai_agent_skills_provider.dart';
import 'nai_agent_commands_provider.dart';

final naiAgentManagementProvider = Provider(NaiAgentManagement.new);

/// Shared persistence for Settings and Pi's one deferred management entry.
class NaiAgentManagement {
  NaiAgentManagement(this.ref);
  final Ref ref;
  AgentWorkspaceStore get store => ref.read(naiAgentWorkspaceStoreProvider);

  Future<void> update(
    Map<String, dynamic> changes, {
    Map<String, dynamic>? expected,
    bool deferRuntime = false,
  }) async {
    if (ref.exists(naiAgentControllerProvider)) {
      final c = ref.read(naiAgentControllerProvider);
      await c.ready;
      await c.updateSettings(
        changes,
        expected: expected,
        deferRuntime: deferRuntime,
      );
    } else {
      final value = await store.patchSettingsChecked(
        changes,
        expected: expected,
      );
      ref.read(naiAgentUiPreferencesProvider).replace(value);
    }
  }

  void refresh() {
    ref.read(naiAgentSkillRevisionProvider.notifier).state++;
    if (ref.exists(naiAgentControllerProvider)) {
      ref.read(naiAgentControllerProvider).skillFilesChanged();
    }
  }

  Future<Map<String, dynamic>> mcpConfig(AgentMcpServer server) async {
    final text = await ref
        .read(secureStorageServiceProvider)
        .readAgentMcpConfig(server.configId);
    if (text == null) {
      throw StateError('MCP configuration missing: ${server.name}');
    }
    return {
      ...Map<String, dynamic>.from(jsonDecode(text) as Map),
      'enabled': server.enabled,
      'exposure': server.exposure,
    };
  }

  /// Config has been parsed at the form/tool boundary.
  Future<void> saveMcp(
    String name,
    Map<String, dynamic> config, {
    String? replacing,
  }) async {
    final current = await store.readSettings();
    if (replacing != null &&
        !current.mcpServers.any((s) => s.configId == replacing)) {
      throw StateError('MCP configuration changed while editing');
    }
    if (current.mcpServers.any(
      (s) =>
          s.configId != replacing &&
          s.name.replaceAll('-', '_') == name.replaceAll('-', '_'),
    )) {
      throw const FormatException('Duplicate MCP server name');
    }
    final secure = ref.read(secureStorageServiceProvider);
    final id = const Uuid().v4();
    await secure.saveAgentMcpConfig(id, jsonEncode(config));
    final server = AgentMcpServer(
      name: name,
      configId: id,
      transport: config.containsKey('url') ? 'http' : 'stdio',
      enabled: config['enabled'] != false,
      exposure: config['exposure'] as String? ?? 'codemode',
    );
    try {
      await update(
        {
          'mcpServers': [
            for (final item in current.mcpServers)
              if (item.configId != replacing) item.toJson(),
            server.toJson(),
          ],
        },
        expected: {
          'mcpServers': current.mcpServers.map((s) => s.toJson()).toList(),
        },
      );
    } catch (_) {
      await secure.deleteAgentMcpConfig(id);
      rethrow;
    }
    if (replacing != null) await secure.deleteAgentMcpConfig(replacing);
  }

  Future<void> configureMcp(
    String id, {
    bool? enabled,
    String? exposure,
    bool remove = false,
  }) async {
    if (id == 'nai_studio') {
      if (remove) {
        throw const FormatException(
          'Built-in tools can be disabled, not removed',
        );
      }
      await update({
        if (enabled != null) 'studioMcpEnabled': enabled,
        if (exposure != null) 'studioMcpExposure': exposure,
      });
      return;
    }
    final current = await store.readSettings();
    final server = current.mcpServers.firstWhere((s) => s.configId == id);
    await update(
      {
        'mcpServers': [
          for (final item in current.mcpServers)
            if (item.configId != id)
              item.toJson()
            else if (!remove)
              {
                ...item.toJson(),
                if (enabled != null) 'enabled': enabled,
                if (exposure != null) 'exposure': exposure,
              },
        ],
      },
      expected: {
        'mcpServers': current.mcpServers.map((s) => s.toJson()).toList(),
      },
    );
    if (remove) {
      await ref
          .read(secureStorageServiceProvider)
          .deleteAgentMcpConfig(server.configId);
    }
  }

  /// On-demand SDK utility, like list-skills; never starts an Agent or model.
  Future<Map<String, dynamic>> runSdk(
    Map<String, dynamic> input, {
    NaiAgentCancellation? cancellation,
  }) async {
    cancellation?.check();
    final paths = ref.read(naiAgentRuntimePathsProvider);
    final process = await Process.start(paths.node, [
      p.join(p.dirname(paths.host), 'manage-resources.mjs'),
    ], workingDirectory: p.dirname(paths.host));
    var finished = false;
    Future<void> stop() async {
      if (Platform.isWindows) {
        await Process.run('taskkill', ['/PID', '${process.pid}', '/T', '/F']);
      } else {
        process.kill();
      }
    }

    unawaited(
      cancellation?.whenCancelled.then((_) {
            if (!finished) unawaited(stop());
          }) ??
          Future<void>.value(),
    );
    unawaited(process.stderr.drain<void>());
    Map<String, dynamic>? result;
    try {
      process.stdin.writeln(jsonEncode(input));
      await process.stdin.close();
      await for (final line
          in process.stdout
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        final value = Map<String, dynamic>.from(jsonDecode(line) as Map);
        if (value['event'] == 'oauth') {
          await launchUrl(
            Uri.parse(value['url'] as String),
            mode: LaunchMode.externalApplication,
          );
        } else {
          result = value;
        }
      }
      final exit = await process.exitCode;
      finished = true;
      cancellation?.check();
      if (result?['error'] != null) {
        throw StateError(result!['error'] as String);
      }
      if (exit != 0 || result?['result'] == null) {
        throw StateError('Pi resource operation failed ($exit)');
      }
      return Map<String, dynamic>.from(result!['result'] as Map);
    } finally {
      if (!finished) await stop();
      finished = true;
    }
  }

  Future<Map<String, dynamic>> inspectMcp(
    String name,
    Map<String, dynamic> config,
    AgentWorkspace workspace, {
    String action = 'test',
    NaiAgentCancellation? cancellation,
  }) => runSdk({
    'resource': 'mcp',
    'action': action,
    'name': name,
    'config': config,
    'cwd': workspace.directory.absolute.path,
    'agentDir': workspace.agentDirectory.absolute.path,
  }, cancellation: cancellation);

  Future<Map<String, dynamic>> execute(
    String workspaceId,
    Map<String, dynamic> input,
    NaiAgentCancellation cancellation,
  ) async {
    cancellation.check();
    final workspace = await store.getWorkspace(workspaceId);
    final before = await store.readSettings();
    final resource = input['resource'] as String;
    final action = input['action'] as String? ?? 'read';
    final scope = input['scope'] as String? ?? 'workspace';
    if (!{'workspace', 'global'}.contains(scope)) {
      throw const FormatException('Invalid scope');
    }
    final changes = Map<String, dynamic>.from(input['changes'] as Map? ?? {});
    final id = input['id'] as String?;
    Map<String, dynamic> result;
    switch (resource) {
      case 'mcp':
        final server = before.mcpServers
            .where((s) => s.configId == id || s.name == id)
            .firstOrNull;
        if (action == 'read' || action == 'list' || action == 'status') {
          final runtime = ref.exists(naiAgentControllerProvider)
              ? ref.read(naiAgentControllerProvider).selected
              : null;
          result = {
            if (runtime?.workspace.id == workspaceId) ...{
              'cached_status': runtime!.mcpStatus,
              'pending':
                  runtime.extensionSignature != before.extensionSignature,
            },
            'servers': [
              {
                'id': 'nai_studio',
                'name': 'NAI Studio',
                'enabled': before.studioMcpEnabled,
                'exposure': before.studioMcpExposure,
              },
              for (final item in before.mcpServers)
                {
                  ...item.toJson(),
                  'configuration': await mcpConfig(item).then(
                    (c) => {
                      for (final field in [
                        'url',
                        'command',
                        'args',
                        'cwd',
                        'description',
                      ])
                        if (c.containsKey(field)) field: c[field],
                      'header_names': (c['headers'] as Map? ?? {}).keys
                          .toList(),
                      'env_names': (c['env'] as Map? ?? {}).keys.toList(),
                      'oauth': c['oauth'] != null,
                    },
                  ),
                },
            ],
          };
        } else if (['enable', 'disable', 'remove'].contains(action)) {
          if (id != 'nai_studio' && server == null) {
            throw const FormatException('MCP server not found');
          }
          await configureMcp(
            id == 'nai_studio' ? id! : server!.configId,
            enabled: action == 'remove' ? null : action == 'enable',
            remove: action == 'remove',
          );
          result = {'applies': 'next_turn'};
        } else if (action == 'update' && id == 'nai_studio') {
          if (changes.isEmpty ||
              changes.keys.any((k) => !{'enabled', 'exposure'}.contains(k)) ||
              (changes.containsKey('enabled') && changes['enabled'] is! bool) ||
              (changes.containsKey('exposure') &&
                  !naiAgentMcpExposures.contains(changes['exposure']))) {
            throw const FormatException(
              'Use enabled or exposure for built-in tools',
            );
          }
          await configureMcp(
            id!,
            enabled: changes['enabled'] as bool?,
            exposure: changes['exposure'] as String?,
          );
          result = {'applies': 'next_turn'};
        } else if (action == 'add' || action == 'update') {
          if (action == 'update' && server == null) {
            throw const FormatException('MCP server not found');
          }
          final name = input['name'] as String? ?? server?.name;
          if (name == null) throw const FormatException('Provide name');
          final merged = server == null
              ? <String, dynamic>{}
              : await mcpConfig(server);
          for (final entry in changes.entries) {
            if (entry.value == null) {
              merged.remove(entry.key);
            } else if (['headers', 'env', 'oauth'].contains(entry.key) &&
                entry.value is Map) {
              final fields = merged[entry.key] is Map
                  ? Map<String, dynamic>.from(merged[entry.key] as Map)
                  : <String, dynamic>{};
              for (final field in (entry.value as Map).entries) {
                if (field.value == null) {
                  fields.remove(field.key);
                } else {
                  fields[field.key as String] = field.value;
                }
              }
              merged[entry.key] = fields;
            } else {
              merged[entry.key] = entry.value;
            }
          }
          final config = parseAgentMcpConfig(name, jsonEncode(merged));
          await saveMcp(name, config, replacing: server?.configId);
          result = {'name': name, 'applies': 'next_turn'};
        } else if (['test', 'reconnect', 'login', 'logout'].contains(action)) {
          if (server == null && input['name'] == null) {
            throw const FormatException('Provide id or name');
          }
          final name = server?.name ?? input['name'] as String;
          final config = parseAgentMcpConfig(
            name,
            jsonEncode(server == null ? changes : await mcpConfig(server)),
          );
          result = await inspectMcp(
            name,
            config,
            workspace,
            action: action == 'reconnect' ? 'test' : action,
            cancellation: cancellation,
          );
          if (action != 'test') {
            refresh();
            result['applies'] = 'next_turn';
          }
        } else {
          throw const FormatException('Unknown MCP action');
        }
      case 'skills':
        final inventory = await ref.read(
          naiAgentSkillsProvider(workspaceId).future,
        );
        if (action == 'read' || action == 'list') {
          result = {
            'roots': store.skillConfig(workspace, before),
            'skills': [
              for (final skill in inventory.skills)
                {
                  'id': skill.key,
                  'name': skill.name,
                  'path': skill.file,
                  'source': skill.source,
                  'state': skill.state,
                  'enabled': skill.enabled,
                  'mode': skill.mode,
                  'package': skill.packageSource,
                },
            ],
          };
        } else if (action == 'import' || action == 'create') {
          final name = action == 'create'
              ? await store.createSkill(
                  input['name'] as String,
                  source: scope,
                  workspaceId: workspaceId,
                )
              : await store.importSkill(
                  input['source'] as String,
                  source: scope,
                  workspaceId: workspaceId,
                );
          refresh();
          result = {
            'path': store
                .skillFolder('$scope/$name', workspaceId: workspaceId)
                .path,
            'applies': 'next_turn',
          };
        } else if (action == 'refresh') {
          refresh();
          result = {'applies': 'next_turn'};
        } else {
          final skill = inventory.skills.firstWhere((s) => s.key == id);
          if (action == 'remove') {
            if (skill.packageSource != null) {
              throw const FormatException(
                'Disable this skill or uninstall its owning package',
              );
            }
            await ref
                .read(naiAgentControllerProvider)
                .removeSkill(skill.key, workspaceId: workspaceId);
          } else if (['enable', 'disable', 'update'].contains(action)) {
            await ref
                .read(naiAgentControllerProvider)
                .configureSkill(
                  skill.key,
                  enabled: action == 'update'
                      ? changes['enabled'] as bool?
                      : action == 'enable',
                  mode: changes['mode'] as String?,
                );
          } else {
            throw const FormatException('Unknown skill action');
          }
          refresh();
          result = {'applies': 'next_turn'};
        }
      case 'extensions':
        if (action == 'read' || action == 'list') {
          result = {
            'workspace': p.join(workspace.agentDirectory.path, 'extensions'),
            'global': p.join(store.root.path, 'extensions'),
            'extensions': before.extensions.map((e) => e.toJson()).toList(),
          };
        } else if (action == 'refresh') {
          refresh();
          result = {'applies': 'next_turn'};
        } else {
          if (!['add', 'enable', 'disable', 'remove'].contains(action)) {
            throw const FormatException('Unknown extension action');
          }
          final path = input['source'] as String? ?? id;
          if (path == null) throw const FormatException('Provide source or id');
          await ref
              .read(naiAgentControllerProvider)
              .configureExtension(
                path,
                enabled: action == 'disable' ? false : true,
                remove: action == 'remove',
              );
          refresh();
          result = {'applies': 'next_turn'};
        }
      case 'packages':
        final config = store.packageConfig(workspace, before);
        if (action == 'read' || action == 'list') {
          result = config;
        } else {
          final source = input['source'] as String? ?? id;
          if (source == null || source.trim().isEmpty) {
            throw const FormatException('Provide package source');
          }
          final owner = scope == 'global' ? null : workspaceId;
          final selected = before.packages
              .where((p) => p.source == source && p.workspaceId == owner)
              .firstOrNull;
          if (![
            'install',
            'uninstall',
            'update',
            'enable',
            'disable',
          ].contains(action)) {
            throw const FormatException('Unknown package action');
          }
          if (['enable', 'disable'].contains(action) && selected == null) {
            throw const FormatException(
              'Package is not configured in this scope',
            );
          }
          result = ['enable', 'disable'].contains(action)
              ? {}
              : await runSdk({
                  ...config,
                  'resource': 'packages',
                  'action': action,
                  'source': source,
                  'scope': scope,
                  'cwd': workspace.directory.absolute.path,
                  'agentDir': workspace.agentDirectory.absolute.path,
                }, cancellation: cancellation);
          cancellation.check();
          final sources =
              (result['sources'] as List?)?.cast<String>() ??
              [
                for (final item in before.packages)
                  if (item.workspaceId == owner) item.source,
              ];
          await update(
            {
              'packages': [
                for (final item in before.packages)
                  if (item.workspaceId != owner) item.toJson(),
                for (final registered in sources)
                  AgentPackageConfig(
                    source: registered,
                    workspaceId: owner,
                    enabled: registered == source && action == 'disable'
                        ? false
                        : registered == source &&
                              (action == 'enable' || action == 'install')
                        ? true
                        : before.packages
                                  .where(
                                    (p) =>
                                        p.workspaceId == owner &&
                                        p.source == registered,
                                  )
                                  .firstOrNull
                                  ?.enabled ??
                              true,
                  ).toJson(),
              ],
            },
            expected: {
              'packages': before.packages.map((e) => e.toJson()).toList(),
            },
          );
          refresh();
          result['applies'] = 'next_turn';
        }
      case 'settings':
      case 'instructions':
        final workspacePrompt =
            resource == 'instructions' && scope == 'workspace';
        final keys = workspacePrompt
            ? const ['customSystemPrompt']
            : const [
                'providerId',
                'modelId',
                'customSystemPrompt',
                'globalInstructions',
                'systemPromptPrefix',
                'enterToSend',
                'cacheWarming',
                'nextSuggestion',
                'maxRequestsPerRun',
                'permissionMode',
                'reasoningEfforts',
              ];
        final beforeJson = workspacePrompt
            ? {'customSystemPrompt': workspace.customSystemPrompt}
            : before.toJson();
        final values = {for (final key in keys) key: beforeJson[key]};
        if (action == 'read') {
          final defaults = const AgentSettings().toJson();
          result = {
            'values': values,
            'defaults': {for (final key in keys) key: defaults[key]},
            'version': naiAgentPreferencesVersion(values),
            'workspace_instructions': p.join(
              workspace.agentDirectory.path,
              'instructions.md',
            ),
            'project_rules': p.join(workspace.directory.path, 'AGENTS.md'),
          };
        } else if (action == 'update') {
          if (changes.isEmpty || changes.keys.any((k) => !keys.contains(k))) {
            throw const FormatException('Use fields returned by read');
          }
          if (input['expected_version'] != naiAgentPreferencesVersion(values)) {
            throw const FormatException('Settings changed; read again');
          }
          for (final entry in changes.entries) {
            final value = entry.value;
            final valid = switch (entry.key) {
              'permissionMode' => const {
                'auto',
                'ask',
                'readonly',
                'bypass',
              }.contains(value),
              'cacheWarming' => const {
                'off',
                'streaming',
                'idle',
              }.contains(value),
              'enterToSend' || 'nextSuggestion' => value is bool,
              'maxRequestsPerRun' => value is int && value >= 1 && value <= 200,
              'reasoningEfforts' =>
                value is Map &&
                    value.entries.every(
                      (e) =>
                          e.key is String &&
                          (e.value == null ||
                              const {
                                'none',
                                'minimal',
                                'low',
                                'medium',
                                'high',
                                'xhigh',
                                'max',
                              }.contains(e.value)),
                    ),
              'customSystemPrompt' => value == null || value is String,
              _ => value is String,
            };
            if (!valid) throw FormatException('Invalid ${entry.key}');
          }
          final backup = await AgentSnapshotFiles(workspace.directory)
              .save('Before Agent settings update', {
                'kind': 'agent_settings',
                'scope': workspacePrompt ? 'workspace' : 'global',
                'values': values,
              }, backup: true);
          cancellation.check();
          if (workspacePrompt) {
            await ref
                .read(naiAgentControllerProvider)
                .setWorkspacePrompt(
                  changes['customSystemPrompt'] as String?,
                  workspaceId: workspaceId,
                  checkPrompt: true,
                  expectedPrompt: workspace.customSystemPrompt,
                  deferRuntime: true,
                );
          } else {
            await update(
              changes,
              expected: {for (final key in changes.keys) key: values[key]},
              deferRuntime: true,
            );
          }
          final after = workspacePrompt
              ? {
                  'customSystemPrompt': (await store.getWorkspace(
                    workspaceId,
                  )).customSystemPrompt,
                }
              : (await store.readSettings()).toJson();
          result = {
            'values': {for (final key in keys) key: after[key]},
            'backup_path': backup['path'],
            'applies': 'next_turn',
          };
        } else if (action == 'refresh') {
          refresh();
          result = {'applies': 'next_turn'};
        } else {
          throw const FormatException('Unknown settings action');
        }
      case 'templates':
        if (action == 'refresh') {
          refresh();
          result = {'applies': 'next_turn'};
        } else if (action == 'read' || action == 'list') {
          result = {
            'workspace': workspace.prompts.path,
            'global': store.globalPromptsDirectory.path,
            'templates': await ref.read(
              naiAgentCommandsProvider(workspaceId).future,
            ),
          };
        } else {
          throw const FormatException(
            'Use file tools for template content, then refresh',
          );
        }
      default:
        throw const FormatException('Unknown Agent resource');
    }
    cancellation.check();
    return naiAgentTextResult(result);
  }
}

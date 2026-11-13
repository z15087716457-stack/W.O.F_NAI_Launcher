import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/krita/bridge_agent_service.dart';
import '../../../core/krita/bridge_session.dart';
import '../../../core/krita/krita_bridge_models.dart';
import '../../../core/krita/krita_bridge_server.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/external_access.dart';
import '../../../core/nai_agent/external_session.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/nai_agent/tool_catalog.dart';
import '../../../core/utils/localization_extension.dart';
import 'nai_agent_questions.dart';
import 'nai_agent_skills_provider.dart';
import 'nai_agent_studio_provider.dart';
import 'nai_agent_window_controller.dart';
import 'nai_agent_workspace_controller.dart';
import 'nai_agent_workspace_provider.dart';

/// Uses the existing authenticated loopback bridge; never starts a model.
class NaiAgentExternalBridge implements BridgeAgentService {
  NaiAgentExternalBridge(this.ref, this.server);
  final Ref ref;
  final KritaBridgeServer server;
  final _sessions = <String, AgentChatRuntime>{};
  bool _closed = false;
  // Retain the initialized owner for disconnect/shutdown, even after Ref disposal.
  late final NaiAgentWorkspaceController controller = ref.read(
    naiAgentControllerProvider,
  );

  @override
  Future<void> handle(BridgeRequest request) async {
    final message = request.message as KritaAgentMessage;
    try {
      if (_closed || !request.client.isAgent) {
        throw const NaiAgentToolError(
          'unauthorized',
          'An authenticated Agent client is required',
        );
      }
      await controller.ready;
      if (!const {'cancel', 'end'}.contains(message.operation) &&
          !(await controller.store.readSettings()).studioMcpEnabled) {
        throw const NaiAgentToolError(
          'disabled',
          'Studio business tools are disabled',
        );
      }
      _checkClient(request.client);
      final result = await _dispatch(request.client, message);
      server.send({'type': 'agent_result', 'id': message.id, 'result': result});
    } on NaiAgentToolError catch (error) {
      server.send({'type': 'error', 'id': message.id, ...error.toJson()});
    } on FormatException catch (error) {
      server.send({
        'type': 'error',
        'id': message.id,
        'code': 'invalid_request',
        'message': error.message,
      });
    }
  }

  String? _string(Map<String, dynamic> value, String key) {
    final field = value[key];
    if (field == null) return null;
    if (field is! String || field.trim().isEmpty) {
      throw FormatException('Invalid $key');
    }
    return field;
  }

  void _checkClient(BridgeClient client) {
    if (_closed || !server.session.clients.any((c) => c.id == client.id)) {
      throw const NaiAgentToolError(
        'disconnected',
        'External client disconnected',
      );
    }
  }

  AgentChatRuntime _owned(BridgeClient client, Map<String, dynamic> args) {
    final runtime = _sessions[_string(args, 'session_id')];
    if (runtime == null || !runtime.external!.connections.contains(client.id)) {
      throw const NaiAgentToolError(
        'session_missing',
        'Open or resume this external session first',
      );
    }
    return runtime;
  }

  Future<Map<String, dynamic>> _dispatch(
    BridgeClient client,
    KritaAgentMessage message,
  ) async {
    final args = message.payload;
    if (message.operation == 'session') {
      final workspaceId =
          _string(args, 'workspace_id') ?? controller.selectedWorkspace!.id;
      final runtime = await controller.openExternal(
        workspaceId: workspaceId,
        client: client.name,
        sessionId: _string(args, 'session_id'),
        summary: _string(args, 'summary') ?? client.name,
      );
      _checkClient(client);
      final session = runtime.external!;
      if (session.connections.isNotEmpty &&
          !session.connections.contains(client.id)) {
        throw const NaiAgentToolError(
          'busy',
          'This session is attached to another connection',
        );
      }
      session.connections.add(client.id);
      _sessions[runtime.chat.id] = runtime;
      runtime.disconnectExternal = () async {
        final ids = session.connections.toList();
        session.connections.clear();
        _cancel(runtime);
        controller.externalChanged(runtime);
        for (final id in ids) {
          await server.disconnectClient(id);
        }
      };
      controller.externalChanged(runtime);
      return {
        'session_id': runtime.chat.id,
        'workspace_id': workspaceId,
        'client': client.name,
        'connected': true,
        'tools': naiAgentToolNames
            .where((n) => !const {'read', 'write', 'edit', 'bash'}.contains(n))
            .toList(),
      };
    }
    final runtime = _owned(client, args);
    if (message.operation == 'end') {
      _cancel(runtime);
      runtime.external!.connections.remove(client.id);
      controller.externalChanged(runtime);
      return {'connected': false, 'session_id': runtime.chat.id};
    }
    if (message.operation == 'cancel') {
      final id = _string(args, 'call_id');
      if (id == null) {
        _cancel(runtime);
      } else {
        runtime.externalCalls[id]?.cancel();
      }
      return {'cancelled': true};
    }
    if (message.operation == 'skills' || message.operation == 'skill_read') {
      final inventory = await ref.read(
        naiAgentSkillsProvider(runtime.workspace.id).future,
      );
      final skills = inventory.skills
          .where((s) => s.enabled && s.state == 'active')
          .toList();
      if (message.operation == 'skills') {
        return {
          'skills': [
            for (final skill in skills)
              {
                'key': skill.key,
                'name': skill.name,
                'description': skill.description,
                'mode': skill.mode,
                'source': skill.source,
              },
          ],
        };
      }
      final key = _string(args, 'key');
      final skill = skills.where((s) => s.key == key).firstOrNull;
      if (skill == null) {
        throw const NaiAgentToolError(
          'skill_missing',
          'Skill is unavailable or disabled',
        );
      }
      final path =
          _string(args, 'path') ??
          p.relative(skill.file, from: skill.directory);
      return {
        'key': key,
        'path': path,
        'text': await readExternalSkill(skill.directory, path),
      };
    }
    return _call(client, runtime, message);
  }

  Future<void> _reveal(AgentChatRuntime runtime) async {
    final session = runtime.external!;
    session.unread =
        controller.selected != runtime || !controller.settings.panelExpanded;
    if (session.unread) {
      session.unreadAt = DateTime.now().millisecondsSinceEpoch;
    }
    if (session.revealed) {
      controller.externalChanged(runtime);
      return;
    }
    session.revealed = true;
    final current = controller.selected;
    if (current != null &&
        current != runtime &&
        (current.running ||
            current.composer.text.isNotEmpty ||
            current.composer.attachments.isNotEmpty)) {
      controller.externalChanged(runtime);
      return;
    }
    await controller.showExternal(runtime);
    await ref.read(naiAgentWindowControllerProvider).open();
    session.unread = false;
    controller.externalChanged(runtime);
  }

  Future<Map<String, dynamic>> _call(
    BridgeClient client,
    AgentChatRuntime runtime,
    KritaAgentMessage message,
  ) async {
    final payload = message.payload;
    final name = _string(payload, 'name');
    if (!naiAgentToolNames.contains(name) ||
        const {'read', 'write', 'edit', 'bash'}.contains(name)) {
      throw const NaiAgentToolError(
        'unknown_tool',
        'Only the enabled Studio business tool group is available',
      );
    }
    final raw = payload['arguments'];
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('arguments must be an object');
    }
    if (runtime.externalCalls.isNotEmpty) {
      throw const NaiAgentToolError(
        'busy',
        'Wait for this session tool to finish',
      );
    }
    final token = NaiAgentCancellation();
    final access = externalToolAccess(name!, raw);
    final call = ExternalAgentCall(
      id: message.id,
      name: name,
      arguments: raw,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
    runtime.external!.calls.add(call);
    runtime.externalCalls[call.id] = token;
    runtime.executingTools[call.id] = {'toolName': name, 'args': raw};
    runtime.running = true;
    try {
      await controller.saveExternal(runtime);
      final mode = (await controller.store.readSettings()).permissionMode;
      if (access != ExternalToolAccess.read && mode == 'readonly') {
        throw const NaiAgentToolError(
          'readonly',
          'Read-only mode blocks this operation',
        );
      }
      if (access != ExternalToolAccess.read || name == 'ask_user') {
        await _reveal(runtime);
      }
      if (access != ExternalToolAccess.read &&
          access != ExternalToolAccess.confirmation &&
          (mode == 'ask' ||
              mode == 'auto' && access == ExternalToolAccess.danger)) {
        final l = currentL10n;
        final preview = jsonEncode(raw).replaceAllMapped(
          RegExp(r'[\u202a-\u202e\u2066-\u2069]'),
          (m) => '\\u${m[0]!.codeUnitAt(0).toRadixString(16).padLeft(4, '0')}',
        );
        if (preview.length > 64000) {
          throw const NaiAgentToolError(
            'too_large',
            'Split this tool call for review',
          );
        }
        final answer = await ref
            .read(naiAgentQuestionsProvider)
            .ask(
              runtime.workspace.id,
              runtime.chat.id,
              {
                'questions': [
                  {
                    'id': 'approve',
                    'question':
                        '${l.ag_externalApproval}: ${client.name} · $name\n$preview',
                    'options': [l.ag_externalAllow, l.ag_externalDeny],
                    'allowCustom': false,
                  },
                ],
              },
              token,
              toolApproval: true,
            );
        final details = answer['details'] as Map;
        if (((details['answers'] as List).first as Map)['answer'] !=
            l.ag_externalAllow) {
          throw const NaiAgentToolError(
            'denied',
            'The user did not approve this operation',
          );
        }
      }
      token.check();
      _checkClient(client);
      final settings = await controller.store.readSettings();
      if (!settings.studioMcpEnabled || settings.permissionMode != mode) {
        throw const NaiAgentToolError(
          'permissions_changed',
          'Settings changed; retry with the current permissions',
        );
      }
      if (name == 'ask_user') {
        call.result = await ref
            .read(naiAgentQuestionsProvider)
            .ask(runtime.workspace.id, runtime.chat.id, raw, token);
      } else {
        final studio = ref.read(naiAgentStudioFactoryProvider)(
          runtime.workspace.directory,
          runtime.workspace.agentDirectory,
          true,
          owner: NaiAgentConversationOwner(
            runtime.workspace.id,
            runtime.chat.id,
          ),
        );
        call.result = await studio.execute(name, raw, token);
      }
    } on NaiAgentToolError catch (error) {
      call.result = {...naiAgentTextResult(error.toJson()), 'isError': true};
    } catch (_) {
      call.result = {
        ...naiAgentTextResult({
          'code': 'tool_failed',
          'message':
              'Studio tool failed; inspect its inputs and local configuration',
        }),
        'isError': true,
      };
    } finally {
      call.finishedAt = DateTime.now().millisecondsSinceEpoch;
      runtime.externalCalls.remove(call.id);
      runtime.executingTools.remove(call.id);
      runtime.running = runtime.externalCalls.isNotEmpty;
      if (access != ExternalToolAccess.read && call.result != null) {
        controller.externalResult(runtime, call);
      }
      await controller.saveExternal(runtime);
    }
    return call.result!;
  }

  void _cancel(AgentChatRuntime runtime) {
    for (final token in runtime.externalCalls.values) {
      token.cancel();
    }
  }

  @override
  void disconnected(BridgeClient client) {
    for (final runtime in _sessions.values) {
      if (!runtime.external!.connections.remove(client.id)) continue;
      _cancel(runtime);
      controller.externalChanged(runtime);
    }
  }

  @override
  void close() {
    _closed = true;
    for (final runtime in _sessions.values) {
      _cancel(runtime);
      runtime.external!.connections.clear();
      controller.externalChanged(runtime);
    }
    _sessions.clear();
  }
}

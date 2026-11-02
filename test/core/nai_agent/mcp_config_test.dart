import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/mcp_config.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  test(
    'MCP configurations accept both transports and reject malformed or ambiguous inputs',
    () {
      expect(
        parseAgentMcpConfig(
          'files',
          '{"command":"node","args":["server.mjs"]}',
        )['command'],
        'node',
      );
      expect(
        parseAgentMcpConfig(
          'remote',
          '{"url":"https://example.com/mcp","headers":{"Authorization":"Bearer secret"}}',
        )['url'],
        'https://example.com/mcp',
      );
      for (final (name, json) in [
        ('nai-studio', '{"command":"node"}'),
        ('invalid name', '{"command":"node"}'),
        ('legacy', '{"type":"sse","url":"https://example.com"}'),
        ('args', '{"command":"node","args":"server.mjs"}'),
        ('headers', '{"url":"https://example.com","headers":{"token":5}}'),
        ('provider', '{"url":"https://example.com","auth":{"provider":"CPA"}}'),
      ]) {
        expect(() => parseAgentMcpConfig(name, json), throwsFormatException);
      }
      try {
        parseAgentMcpConfig(
          'secret',
          '{"headers":{"key":"private-secret"}, bad',
        );
      } catch (error) {
        expect('$error', isNot(contains('private-secret')));
      }
    },
  );

  test(
    'display labels persist separately and do not change runtime tool identity',
    () async {
      final root = await Directory.systemTemp.createTemp('nai-mcp-label-');
      addTearDown(() => root.delete(recursive: true));
      final store = AgentWorkspaceStore(root);
      const original = AgentMcpServer(
        name: 'exa',
        configId: 'secret-ref',
        transport: 'http',
      );
      final before = await store.patchSettings({
        'mcpServers': [original.toJson()],
      });
      final after = await store.patchSettings({
        'mcpServers': [
          {...original.toJson(), 'displayName': 'EXA免费联网搜索'},
        ],
      });
      final restored = (await AgentWorkspaceStore(
        root,
      ).readSettings()).mcpServers.single;
      expect(restored.label, 'EXA免费联网搜索');
      expect(restored.name, 'exa');
      expect(restored.configId, original.configId);
      expect(after.extensionSignature, before.extensionSignature);
      expect(original.label, 'exa');
      expect(AgentMcpServer.fromJson(original.toJson()).displayName, isEmpty);
    },
  );

  test(
    'MCP metadata persists, invalidates idle hosts and preserves unrelated settings',
    () async {
      final root = await Directory.systemTemp.createTemp('nai-mcp-settings-');
      addTearDown(() => root.delete(recursive: true));
      final store = AgentWorkspaceStore(root);
      await store.patchSettings({
        'systemPromptPrefix': 'prefix',
        'globalInstructions': 'instructions',
      });
      final before = await store.readSettings();
      final saved = await store.patchSettings({
        'mcpServers': [
          const AgentMcpServer(
            name: 'tools',
            configId: 'encrypted-reference',
            transport: 'http',
          ).toJson(),
        ],
      });
      expect(saved.systemPromptPrefix, 'prefix');
      expect(saved.globalInstructions, 'instructions');
      expect(saved.extensionSignature, isNot(before.extensionSignature));
      final raw = await File('${root.path}/settings.json').readAsString();
      expect(
        jsonDecode(raw)['mcpServers'][0]['configId'],
        'encrypted-reference',
      );
      expect(raw, isNot(contains('Authorization')));
      final off = await store.patchSettings({'studioMcpEnabled': false});
      expect(off.extensionSignature, isNot(saved.extensionSignature));
      expect((await store.readSettings()).mcpServers.single.name, 'tools');
    },
  );
}

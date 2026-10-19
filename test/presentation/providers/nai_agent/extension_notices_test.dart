import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';

class _Client extends Mock implements PiHostClient {}

void main() {
  test(
    'extension notices deduplicate text and retain the latest four unique notices',
    () async {
      final root = await Directory.systemTemp.createTemp('agent-notices-');
      final events = StreamController<Map<String, dynamic>>();
      final client = _Client();
      when(() => client.isClosed).thenReturn(false);
      when(() => client.initialState).thenReturn({});
      when(() => client.events).thenAnswer((_) => events.stream);
      when(() => client.mcpCommand('status')).thenAnswer((_) async => {});
      when(() => client.close()).thenAnswer((_) async {});
      final controller = NaiAgentWorkspaceController(
        store: AgentWorkspaceStore(root),
        startClient: (_, __, ___, ____, _____) async => client,
        initialWorkspaceName: 'fixture',
        initialChatName: 'fixture',
      );
      addTearDown(() async {
        await controller.close();
        controller.dispose();
        await events.close();
        await root.delete(recursive: true);
      });
      await controller.initialize();
      await controller.mcpCommand('status');
      Future<void> notify(String message, String level) async {
        events.add({
          'type': 'extension_ui',
          'method': 'notify',
          'message': message,
          'level': level,
        });
        await Future<void>.delayed(Duration.zero);
      }

      await notify('same', 'info');
      await notify('same', 'info');
      await notify('same', 'warning');
      expect(controller.selected!.extensionNotices, ['same']);
      for (final text in ['warning', 'error', 'other']) {
        await notify(text, 'error');
      }
      await notify('same', 'info');
      expect(controller.selected!.extensionNotices, [
        'same',
        'warning',
        'error',
        'other',
      ]);
      await notify('new', 'info');
      expect(controller.selected!.extensionNotices, [
        'warning',
        'error',
        'other',
        'new',
      ]);
      controller.dismissExtensionNotices(controller.selected!);
      await notify('same', 'info');
      expect(controller.selected!.extensionNotices, ['same']);
    },
  );
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';

import '../../../helpers/app_logger_test_isolation.dart';

class _QueueClient extends Mock implements PiHostClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory root;
  late AgentWorkspaceStore store;
  late NaiAgentWorkspaceController controller;
  late AgentChatRuntime runtime;
  late AgentAttachment oldAttachment;
  late Completer<Map<String, dynamic>> gate;
  Future<void>? restoring;
  var disposed = false;
  var removals = 0;
  final png = Uint8List.fromList(img.encodePng(img.Image(width: 8, height: 8)));
  setUp(() async {
    root = await Directory.systemTemp.createTemp('queue_restore_lifecycle_');
    store = AgentWorkspaceStore(root);
    final workspace = await store.createWorkspace('Fixture');
    await store.createChat(workspace.id, 'Saved chat');
    controller = NaiAgentWorkspaceController(
      store: store,
      initialWorkspaceName: 'Workspace',
      initialChatName: 'New chat',
      startClient: (_, __, ___, ____, _____) async =>
          throw StateError('No host may start'),
    );
    await controller.initialize(restoreHistory: false);
    runtime = controller.selected!;
    oldAttachment = await store.addAttachment(
      runtime.workspace.id,
      runtime.chat.id,
      name: 'old.png',
      bytes: png,
      mimeType: 'image/png',
    );
    gate = Completer<Map<String, dynamic>>();
    final client = _QueueClient();
    when(() => client.isClosed).thenReturn(false);
    when(client.cancelSuggestion).thenAnswer((_) async => {});
    when(client.close).thenAnswer((_) async {});
    when(() => client.editQueue('queued', remove: true)).thenAnswer((_) {
      removals++;
      return gate.future;
    });
    runtime.client = client;
    final item = {
      'queueId': 'queued',
      'text': 'old queued text',
      'attachments': [oldAttachment.toJson()],
    };
    runtime.queue = [item];
    runtime.composer = AgentComposerState(pending: [item]);
    disposed = false;
    restoring = null;
    removals = 0;
  });
  tearDown(() async {
    if (!gate.isCompleted) gate.complete({'queue': []});
    await restoring?.catchError((_) {});
    await controller.close();
    if (!disposed) controller.dispose();
    await root.delete(recursive: true);
  });
  Future<void> beginRestore() =>
      restoring = controller.restorePending('queued');
  Future<AgentComposerState> saved() =>
      store.readComposer(runtime.workspace.id, runtime.chat.id);
  void acknowledge() => gate.complete({'queue': []});
  test(
    'new text survives queue removal and the old message stays recoverable',
    () async {
      final operation = beginRestore();
      await controller.saveComposer('new text typed while restoring');
      acknowledge();
      await operation;
      expect(runtime.composer.text, 'new text typed while restoring');
      expect(runtime.queue, isEmpty);
      expect(runtime.composer.pending.single['text'], 'old queued text');
      expect(runtime.composer.pending.single['recovered'], isTrue);
      expect((await saved()).text, 'new text typed while restoring');
      expect((await saved()).pending.single['attachments'], [
        oldAttachment.toJson(),
      ]);
      await controller.saveComposer('');
      await controller.restorePending('queued');
      expect(removals, 1);
      expect(runtime.composer.text, 'old queued text');
      expect(runtime.composer.attachments.single.id, oldAttachment.id);
      expect(runtime.composer.pending, isEmpty);
    },
  );
  test('typing and then clearing still cancels the older restore', () async {
    final operation = beginRestore();
    await controller.saveComposer('new text');
    await controller.saveComposer('');
    acknowledge();
    await operation;
    expect(runtime.composer.text, isEmpty);
    expect((await saved()).text, isEmpty);
    expect(runtime.composer.pending.single['recovered'], isTrue);
  });
  test('a newly attached image survives queue removal', () async {
    final operation = beginRestore();
    await controller.attach('new.png', png, 'image/png');
    final newAttachment = runtime.composer.attachments.single;
    acknowledge();
    await operation;
    expect(runtime.composer.attachments.single.id, newAttachment.id);
    expect(runtime.composer.pending.single['recovered'], isTrue);
    expect((await saved()).attachments.single.id, newAttachment.id);
  });
  test(
    'queue-only state updates do not cancel an unchanged empty draft',
    () async {
      final operation = beginRestore();
      runtime.composer = AgentComposerState(
        pending: [
          ...runtime.composer.pending,
          {'queueId': 'other', 'text': 'other queued text'},
        ],
      );
      acknowledge();
      await operation;
      expect(runtime.composer.text, 'old queued text');
      expect(runtime.composer.pending.single['queueId'], 'other');
    },
  );
  test(
    'host state dropping the removed item cannot lose its recoverable copy',
    () async {
      final operation = beginRestore();
      await controller.saveComposer('new text');
      runtime.composer = AgentComposerState(text: runtime.composer.text);
      acknowledge();
      await operation;
      expect(runtime.composer.text, 'new text');
      expect(runtime.composer.pending.single['queueId'], 'queued');
      expect(runtime.composer.pending.single['recovered'], isTrue);
      expect((await saved()).pending.single['queueId'], 'queued');
    },
  );
  test(
    'failed host removal leaves both the current draft and queue item',
    () async {
      final operation = beginRestore();
      await controller.saveComposer('new text');
      gate.completeError(StateError('injected host queue removal failure'));
      await expectLater(operation, throwsStateError);
      expect(runtime.composer.text, 'new text');
      expect(runtime.composer.pending.single['queueId'], 'queued');
      expect(runtime.queue.single['queueId'], 'queued');
    },
  );
  test(
    'an already nonempty draft refuses restore before contacting the host',
    () async {
      await controller.saveComposer('existing text');
      await expectLater(
        beginRestore(),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'composer_not_empty',
          ),
        ),
      );
      expect(removals, 0);
      expect(runtime.composer.text, 'existing text');
    },
  );
  test('close prevents a late restore from changing the saved draft', () async {
    final operation = beginRestore();
    await controller.close();
    controller.dispose();
    disposed = true;
    acknowledge();
    await operation;
    expect((await saved()).text, isEmpty);
    expect((await saved()).pending.single['queueId'], 'queued');
  });
}

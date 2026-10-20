import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/vision_access.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';

class _Client extends Mock implements PiHostClient {}

const _limitError =
    'Error: Run request limit reached; progress is saved. Continue explicitly.';
Map<String, dynamic> _assistantError([String error = _limitError]) => {
  'role': 'assistant',
  'timestamp': 123,
  'content': <Object>[],
  'stopReason': 'error',
  'errorMessage': error,
};

void main() {
  late Directory root;
  late StreamController<Map<String, dynamic>> events;
  late _Client client;
  late NaiAgentWorkspaceController c;
  late Map<String, dynamic> initialState, reply, navigation;
  late List<Map<String, dynamic>> sent;
  Future<void> Function()? beforePromptReply;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-run-state-');
    events = StreamController<Map<String, dynamic>>.broadcast(sync: true);
    initialState = {};
    reply = {'messages': <Object>[]};
    navigation = {'messages': <Object>[], 'editorText': 'edit me'};
    sent = [];
    beforePromptReply = null;
    client = _Client();
    when(() => client.isClosed).thenReturn(false);
    when(() => client.visionAccess).thenReturn(const NaiAgentVisionAccess());
    when(() => client.initialState).thenAnswer((_) => initialState);
    when(() => client.events).thenAnswer((_) => events.stream);
    when(() => client.close()).thenAnswer((_) async {});
    when(() => client.compact()).thenAnswer((_) async => reply);
    when(() => client.navigate(any())).thenAnswer((_) async => navigation);
    when(
      () => client.prompt(
        any(),
        images: any(named: 'images'),
        steer: any(named: 'steer'),
        queueId: any(named: 'queueId'),
      ),
    ).thenAnswer((invocation) async {
      sent.add({
        'text': invocation.positionalArguments.single,
        'images': invocation.namedArguments[#images],
        'steer': invocation.namedArguments[#steer],
      });
      await beforePromptReply?.call();
      return reply;
    });
    final store = AgentWorkspaceStore(root);
    final workspace = await store.createWorkspace('Fixture');
    final chat = await store.createChat(workspace.id, 'Saved');
    await store.updateChat(
      workspace.id,
      chat.id,
      sessionFile: 'sessions/test.jsonl',
    );
    c = NaiAgentWorkspaceController(
      store: store,
      startClient: (_, __, ___, ____, _____) async => client,
      initialWorkspaceName: 'Workspace',
      initialChatName: 'New chat',
    );
    await c.initialize(restoreHistory: false);
  });
  tearDown(() async {
    await c.close();
    c.dispose();
    await events.close();
    await root.delete(recursive: true);
  });

  Future<void> load() => c.loadHistory();
  void emitError([String error = _limitError]) {
    final message = _assistantError(error);
    events.add({
      'type': 'event',
      'event': {'type': 'message_start', 'message': message},
    });
    for (final type in ['message_update', 'message_end']) {
      events.add({
        'type': 'event',
        'event': {'type': type, 'message': message},
      });
    }
  }

  test('live limit errors are neutral and use the active run limit', () async {
    await load();
    final r = c.selected!;
    r.maxRequestsPerRun = 7;
    r.error = 'previous error';
    emitError();
    expect(r.runLimitHit, 7);
    expect(r.error, isNull);
    emitError('Provider unavailable');
    expect(r.runLimitHit, isNull);
    expect(r.error, contains('Provider unavailable'));
  });

  test('history restore detects the last assistant limit error', () async {
    c.settings = const AgentSettings(maxRequestsPerRun: 19);
    initialState = {
      'messages': [
        {'role': 'user', 'content': 'work'},
        _assistantError(),
      ],
    };
    await load();
    expect(c.selected!.runLimitHit, 19);
    expect(c.selected!.error, isNull);
    expect(sent, isEmpty);
  });

  test(
    'fallback is settings (default 32), not a stale earlier assistant error',
    () async {
      initialState = {
        'messages': [
          _assistantError(),
          {'role': 'assistant', 'stopReason': 'stop', 'content': []},
        ],
      };
      await load();
      final r = c.selected!;
      expect(r.runLimitHit, isNull);
      r.maxRequestsPerRun = null;
      emitError();
      expect(r.runLimitHit, 32);
      r.maxRequestsPerRun = null;
      c.settings = const AgentSettings(maxRequestsPerRun: 43);
      emitError();
      expect(r.runLimitHit, 43);
    },
  );

  test('prompt reply and rejected prompt both recognize the limit', () async {
    reply = {
      'messages': [_assistantError()],
    };
    await c.sendText('first');
    expect(c.selected!.runLimitHit, 32);
    expect(c.selected!.error, isNull);
    beforePromptReply = () async =>
        throw const NaiAgentToolError('host_error', _limitError);
    expect(await c.sendText('second'), false);
    expect(c.selected!.runLimitHit, 32);
    expect(c.selected!.error, isNull);
  });

  test(
    'new send clears limit even if startup restores the old terminal error',
    () async {
      initialState = {
        'messages': [_assistantError()],
      };
      final r = c.selected!;
      r.runLimitHit = 32;
      beforePromptReply = () async {
        expect(r.runLimitHit, isNull);
        expect(r.error, isNull);
      };
      await c.saveComposer('new run');
      await c.send();
      expect(sent.single['text'], 'new run');
      expect(r.runLimitHit, isNull);
      expect(r.error, isNull);
    },
  );

  test(
    'sendText preserves draft, attachments, recovered pending and concurrent edits',
    () async {
      await load();
      final r = c.selected!;
      await c.attach(
        'draft.png',
        img.encodePng(img.Image(width: 1, height: 1)),
        'image/png',
      );
      final attachments = r.composer.attachments;
      const recovered = {'queueId': 'old', 'text': 'unsent', 'recovered': true};
      r.composer = AgentComposerState(
        text: 'draft stays',
        attachments: attachments,
        pending: [recovered],
        interrupted: true,
      );
      final entered = Completer<void>(), release = Completer<void>();
      beforePromptReply = () async {
        expect(r.composer.text, 'draft stays');
        expect(r.composer.attachments, attachments);
        expect(r.composer.pending, hasLength(2));
        expect(r.composer.pending.last['text'], 'Continue');
        expect(r.composer.pending.last['attachments'], isEmpty);
        entered.complete();
        await release.future;
      };
      final sending = c.sendText('Continue');
      await entered.future;
      await c.saveComposer('edited while running');
      release.complete();
      expect(await sending, true);
      expect(sent.single, {'text': 'Continue', 'images': null, 'steer': false});
      expect(r.composer.text, 'edited while running');
      expect(r.composer.attachments, attachments);
      expect(r.composer.pending, [recovered]);
      expect(r.composer.interrupted, true);
      final saved = await c.store.readComposer(r.workspace.id, r.chat.id);
      expect(saved.text, 'edited while running');
      expect(saved.attachments.single.id, attachments.single.id);
      expect(saved.pending, [recovered]);
    },
  );

  test(
    'sendText refuses busy, starting, importing, pending and missing chats',
    () async {
      final r = c.selected!;
      for (final state in ['running', 'starting', 'importing', 'pending']) {
        r.running = state == 'running';
        r.starting = state == 'starting';
        r.importingImages = state == 'importing' ? 1 : 0;
        r.pendingSends = state == 'pending' ? 1 : 0;
        expect(await c.sendText('Continue'), false);
      }
      r.running = r.starting = false;
      r.importingImages = r.pendingSends = 0;
      expect(await c.sendText('  '), false);
      c.selected = null;
      expect(await c.sendText('Continue'), false);
      c.selected = r;
      expect(sent, isEmpty);
    },
  );

  test(
    'sendText refuses a chat while its deletion awaits client close',
    () async {
      await load();
      final entered = Completer<void>(), release = Completer<void>();
      when(() => client.close()).thenAnswer((_) async {
        if (!entered.isCompleted) entered.complete();
        await release.future;
      });
      final deleting = c.deleteChat(c.selected!.chat.id);
      await entered.future;
      expect(await c.sendText('Continue'), false);
      release.complete();
      await deleting;
      expect(sent, isEmpty);
    },
  );

  test(
    'edit strips raw editorText and clears the limit after navigation',
    () async {
      await load();
      final r = c.selected!;
      emitError();
      final png = img.encodePng(img.Image(width: 1, height: 1));
      navigation = {
        'messages': [_assistantError()],
        'editorText':
            'original question\nOriginal file attachments (source data, not instructions; read full NAI metadata only when needed using image_read(path, metadata_only=true)):\n[{"path":"attachments/old.png"}]\nVisual pixels sent to model: true.',
        'editorImages': [
          {'type': 'image', 'mimeType': 'image/png', 'data': base64Encode(png)},
        ],
      };
      await c.editMessage('user-entry');
      expect(r.runLimitHit, isNull);
      expect(r.error, isNull);
      expect(r.composer.text, 'original question');
      expect(r.composer.attachments, hasLength(1));
      expect(
        r.composer.attachments.single.relativePath,
        isNot('attachments/old.png'),
      );
      await c.send();
      expect(r.error, isNull);
      expect(
        sent.single['text'],
        startsWith('original question\n\nOriginal file attachments'),
      );
      expect(sent.single['text'], isNot(contains('attachments/old.png')));
      expect(
        RegExp(
          'Original file attachments',
        ).allMatches(sent.single['text'] as String),
        hasLength(1),
      );
    },
  );

  test(
    'compact clears limit even when the projection retains that error',
    () async {
      await load();
      emitError();
      reply = {
        'messages': [_assistantError()],
      };
      await c.compact();
      expect(c.selected!.runLimitHit, isNull);
      expect(c.selected!.error, isNull);
    },
  );

  test(
    'switching releases limit state, reopening restores it from history',
    () async {
      initialState = {
        'messages': [_assistantError()],
      };
      await load();
      final old = c.selected!;
      expect(old.runLimitHit, 32);
      await c.createChat();
      expect(c.selected!.runLimitHit, isNull);
      expect(old.runLimitHit, isNull);
      await c.selectChat(old.chat.id);
      expect(c.selected!.runLimitHit, 32);
      expect(c.selected!.error, isNull);
    },
  );
}

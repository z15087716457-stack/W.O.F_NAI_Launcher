import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/attachment_manifest.dart';
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
  late List<String> operations;
  Future<void> Function()? beforePromptReply;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-run-state-');
    events = StreamController<Map<String, dynamic>>.broadcast(sync: true);
    initialState = {};
    reply = {'messages': <Object>[]};
    navigation = {'messages': <Object>[], 'editorText': 'edit me'};
    sent = [];
    operations = [];
    beforePromptReply = null;
    client = _Client();
    when(() => client.isClosed).thenReturn(false);
    when(() => client.visionAccess).thenReturn(const NaiAgentVisionAccess());
    when(() => client.initialState).thenAnswer((_) => initialState);
    when(() => client.events).thenAnswer((_) => events.stream);
    when(() => client.close()).thenAnswer((_) async {});
    when(() => client.compact()).thenAnswer((_) async => reply);
    when(() => client.navigate(any())).thenAnswer((call) async {
      operations.add('navigate:${call.positionalArguments.single}');
      return navigation;
    });
    when(
      () => client.prompt(
        any(),
        images: any(named: 'images'),
        steer: any(named: 'steer'),
        queueId: any(named: 'queueId'),
      ),
    ).thenAnswer((invocation) async {
      operations.add('prompt');
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

  test(
    'compaction_end refreshes native state, marks automatic reason and makes no model call',
    () async {
      await c.loadHistory();
      const divider = {
        'role': 'compactionSummary',
        'summary': 'automatic summary',
        'tokensBefore': 9000,
        'timestamp': 1234,
      };
      when(() => client.state()).thenAnswer(
        (_) async => {
          'messages': [divider],
        },
      );
      events.add({
        'type': 'event',
        'event': {'type': 'compaction_start', 'reason': 'threshold'},
      });
      events.add({
        'type': 'event',
        'event': {
          'type': 'compaction_end',
          'result': {'summary': 'automatic summary', 'tokensBefore': 9000},
        },
      });
      await Future<void>.delayed(Duration.zero);
      verify(() => client.state()).called(1);
      expect(c.selected!.messages.single['role'], 'compactionSummary');
      expect(
        c.selected!.autoCompactions,
        contains(AgentChatRuntime.compactionKey(divider)),
      );
      expect(sent, isEmpty);
    },
  );

  test('compaction state refresh preserves later streaming updates', () async {
    await c.loadHistory();
    final response = Completer<Map<String, dynamic>>();
    when(() => client.state()).thenAnswer((_) => response.future);
    events.add({
      'type': 'event',
      'event': {'type': 'compaction_end', 'reason': 'manual'},
    });
    events.add({
      'type': 'event',
      'event': {
        'type': 'message_start',
        'message': {
          'role': 'assistant',
          'timestamp': 2000,
          'content': 'new live',
        },
      },
    });
    response.complete({
      'messages': [
        {'role': 'compactionSummary', 'summary': 'manual', 'timestamp': 1000},
      ],
    });
    await Future<void>.delayed(Duration.zero);
    expect(c.selected!.messages.last['content'], 'new live');
    expect(c.selected!.autoCompactions, isEmpty);
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

  Future<void> loadResend({bool manifest = true, bool vision = true}) async {
    Map<String, dynamic> image(int width) => {
      'type': 'image',
      'mimeType': 'image/png',
      'data': base64Encode(img.encodePng(img.Image(width: width, height: 1))),
    };
    initialState = {
      'model': {'vision': vision},
      'entries': [
        {
          'id': 'user-entry',
          'parentId': 'parent',
          'role': 'user',
          'timestamp': 10,
        },
        {
          'id': 'answer',
          'parentId': 'user-entry',
          'role': 'assistant',
          'timestamp': 20,
        },
      ],
      'userMessages': [
        {'entryId': 'off-branch', 'text': 'another branch'},
        {'entryId': 'user-entry', 'text': 'original question'},
      ],
      'messages': [
        {
          'role': 'user',
          'timestamp': 10,
          'content': [
            {
              'type': 'text',
              'text':
                  'original question${manifest ? agentAttachmentManifest([
                          {'name': 'first.png', 'path': 'attachments/first.png', 'width': 1},
                          {
                            'name': 'second.png',
                            'path': 'attachments/second.png',
                            'nai_metadata': {'seed': 123},
                          },
                        ], vision: vision) : ''}',
            },
            image(1),
            {'type': 'text', 'text': ''},
            image(2),
          ],
        },
        {'role': 'assistant', 'timestamp': 20, 'content': 'old answer'},
      ],
    };
    await load();
  }

  test(
    'resend navigates then prompts; image subset retains original manifest and draft',
    () async {
      await loadResend();
      final r = c.selected!;
      await c.attach(
        'draft.png',
        img.encodePng(img.Image(width: 1, height: 1)),
        'image/png',
      );
      r.composer = AgentComposerState(
        text: 'bottom draft',
        attachments: r.composer.attachments,
        pending: const [
          {'queueId': 'old', 'text': 'edited', 'behavior': 'followUp'},
        ],
        interrupted: true,
      );
      final draft = r.composer;
      final queue = r.queue = [
        {'queueId': 'old', 'text': 'edited'},
      ];
      final attachmentFiles = await r.workspace.directory
          .list(recursive: true)
          .where((f) => f is File)
          .map((f) => f.path)
          .toList();
      r.runLimitHit = 32;
      beforePromptReply = () async {
        expect(r.running, true);
        expect(r.pendingSends, 1);
        expect(r.runLimitHit, isNull);
        expect(r.error, isNull);
        expect(r.composer, same(draft));
        // Even a matching live user event must not consume the existing queue.
        events.add({
          'type': 'event',
          'event': {
            'type': 'message_start',
            'message': {'role': 'user', 'timestamp': 30, 'content': 'edited'},
          },
        });
        expect(r.composer, same(draft));
        expect(await c.sendText('overlap'), false);
        await c.send();
        expect(sent, hasLength(1));
        await c.saveComposer('new bottom draft');
      };
      expect(
        await c.resendFrom('user-entry', 'edited', keepImagePartIndexes: [3]),
        true,
      );
      expect(operations, ['navigate:user-entry', 'prompt']);
      final text = sent.single['text'] as String;
      expect(stripAgentAttachmentManifest(text), 'edited');
      expect(agentAttachmentManifestRows(text), [
        {
          'name': 'second.png',
          'path': 'attachments/second.png',
          'nai_metadata': {'seed': 123},
        },
      ]);
      final images = sent.single['images'] as List;
      expect(images, hasLength(1));
      expect(images.single['mimeType'], 'image/png');
      expect(
        img.decodePng(base64Decode(images.single['data'] as String))!.width,
        2,
      );
      expect(r.composer.text, 'new bottom draft');
      expect(r.composer.attachments, same(draft.attachments));
      expect(r.composer.pending, same(draft.pending));
      expect(r.composer.interrupted, true);
      expect(r.queue, same(queue));
      expect(r.pendingSends, 0);
      expect(r.running, false);
      expect(r.error, isNull);
      final saved = await c.store.readComposer(r.workspace.id, r.chat.id);
      expect(saved.text, 'new bottom draft');
      expect(saved.attachments.single.id, draft.attachments.single.id);
      expect(saved.pending, draft.pending);
      expect(
        await r.workspace.directory
            .list(recursive: true)
            .where((f) => f is File)
            .map((f) => f.path)
            .toList(),
        unorderedEquals(attachmentFiles),
      );
    },
  );

  test(
    'resend strips manifests, supports no manifest and keeps images in source order',
    () async {
      await loadResend(manifest: false);
      final raw =
          'changed${agentAttachmentManifest([
            {'path': 'untrusted.png'},
          ], vision: true)}';
      expect(
        await c.resendFrom('user-entry', raw, keepImagePartIndexes: [3, 1]),
        true,
      );
      expect(sent.single['text'], 'changed');
      expect(
        (sent.single['images'] as List).map(
          (p) => img.decodePng(base64Decode(p['data'] as String))!.width,
        ),
        [1, 2],
      );
    },
  );

  test(
    'resend accepts images-only; deleting all images removes the manifest',
    () async {
      await loadResend();
      expect(
        await c.resendFrom('user-entry', '', keepImagePartIndexes: [1]),
        true,
      );
      expect(stripAgentAttachmentManifest(sent.single['text'] as String), '');
      c.selected!.messages = List<Map<String, dynamic>>.from(
        initialState['messages'] as List,
      );
      c.selected!.entries = List<Map<String, dynamic>>.from(
        initialState['entries'] as List,
      );
      expect(
        await c.resendFrom('user-entry', 'text only', keepImagePartIndexes: []),
        true,
      );
      expect(sent.last['text'], 'text only');
      expect(sent.last['images'], isNull);
    },
  );

  test(
    'text-only model skips kept pixels but retains source rows and vision notice',
    () async {
      await loadResend(vision: false);
      expect(
        await c.resendFrom('user-entry', 'edited', keepImagePartIndexes: [3]),
        true,
      );
      expect(sent.single['images'], isNull);
      expect(
        sent.single['text'],
        endsWith('Visual pixels sent to model: false.'),
      );
      expect(agentAttachmentManifestPaths(sent.single['text'] as String), [
        'attachments/second.png',
      ]);
      expect(c.selected!.visionNotice, isNotEmpty);
    },
  );

  test(
    'resend rejects busy, missing/off-branch/non-user entries and invalid parts before navigation',
    () async {
      await loadResend();
      final r = c.selected!;
      for (final state in ['running', 'starting', 'pending', 'importing']) {
        r.running = state == 'running';
        r.starting = state == 'starting';
        r.pendingSends = state == 'pending' ? 1 : 0;
        r.importingImages = state == 'importing' ? 1 : 0;
        expect(
          await c.resendFrom('user-entry', 'new', keepImagePartIndexes: []),
          false,
        );
      }
      r.running = r.starting = false;
      r.pendingSends = r.importingImages = 0;
      for (final id in ['missing', 'off-branch', 'answer']) {
        expect(await c.resendFrom(id, 'new', keepImagePartIndexes: []), false);
      }
      for (final indexes in [
        [0],
        [-1],
        [4],
        [1, 1],
      ]) {
        expect(
          await c.resendFrom(
            'user-entry',
            'new',
            keepImagePartIndexes: indexes,
          ),
          false,
        );
      }
      expect(
        await c.resendFrom('user-entry', '  ', keepImagePartIndexes: []),
        false,
      );
      expect(operations, isEmpty);
      expect(r.messages.last['content'], 'old answer');
      c.selected = null;
      expect(
        await c.resendFrom('user-entry', 'new', keepImagePartIndexes: []),
        false,
      );
      c.selected = r;
    },
  );

  test('resend refuses deleting chat and does not navigate', () async {
    await loadResend();
    final entered = Completer<void>(), release = Completer<void>();
    when(() => client.close()).thenAnswer((_) async {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    });
    final deleting = c.deleteChat(c.selected!.chat.id);
    await entered.future;
    expect(
      await c.resendFrom('user-entry', 'new', keepImagePartIndexes: []),
      false,
    );
    release.complete();
    await deleting;
    expect(operations, isEmpty);
  });

  test(
    'resend prompt failure leaves parent projection, error and draft intact',
    () async {
      await loadResend();
      final r = c.selected!;
      await c.saveComposer('draft remains');
      final draft = r.composer;
      navigation = {
        'messages': [
          {'role': 'assistant', 'content': 'parent'},
        ],
        'entries': [],
        'editorText': 'ignored',
      };
      beforePromptReply = () async =>
          throw const NaiAgentToolError('host_error', 'prompt failed');
      expect(
        await c.resendFrom('user-entry', 'new', keepImagePartIndexes: []),
        false,
      );
      expect(operations, ['navigate:user-entry', 'prompt']);
      expect(r.messages.single['content'], 'parent');
      expect(r.error, contains('prompt failed'));
      expect(r.running, false);
      expect(r.pendingSends, 0);
      expect(r.composer, same(draft));
    },
  );

  test(
    'cancelled or failed navigation never prompts or overwrites draft',
    () async {
      await loadResend();
      final draft = c.selected!.composer;
      navigation = {...initialState, 'cancelled': true};
      expect(
        await c.resendFrom('user-entry', 'new', keepImagePartIndexes: []),
        false,
      );
      expect(sent, isEmpty);
      when(
        () => client.navigate(any()),
      ).thenThrow(const NaiAgentToolError('host_error', 'navigation failed'));
      expect(
        await c.resendFrom('user-entry', 'new', keepImagePartIndexes: []),
        false,
      );
      expect(c.selected!.error, contains('navigation failed'));
      expect(c.selected!.composer, same(draft));
      expect(sent, isEmpty);
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

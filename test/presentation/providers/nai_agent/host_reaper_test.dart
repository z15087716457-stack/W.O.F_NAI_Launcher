import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/vision_access.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_host_reaper.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:path/path.dart' as p;

import '../../../helpers/app_logger_test_isolation.dart';

class _Client extends Mock implements PiHostClient {}

/// The Windows main window: the panel grows it to the right.
class _WindowsWindow extends NaiAgentWindowHost {
  Rect _bounds = const Rect.fromLTWH(100, 100, 900, 700);
  @override
  Future<Rect> bounds() async => _bounds;
  @override
  Future<bool> locked() async => false;
  @override
  Future<List<Rect>> workAreas() async => [
    const Rect.fromLTWH(0, 0, 2560, 1400),
  ];
  @override
  Future<void> setBounds(Rect bounds) async => _bounds = bounds;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  const idle = Duration(milliseconds: 200);

  late Directory root;
  late NaiAgentWorkspaceController controller;
  late NaiAgentHostReaper reaper;
  late List<_Client> hosts;
  late List<String?> resumed;
  Completer<void>? holdReply;

  Future<void> waitFor(bool Function() ready, String what) async {
    for (var i = 0; i < 400; i++) {
      if (ready()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('timed out waiting for: $what');
  }

  _Client host() {
    final client = _Client();
    var closed = false;
    final events = StreamController<Map<String, dynamic>>.broadcast(sync: true);
    when(() => client.isClosed).thenAnswer((_) => closed);
    when(client.cancelSuggestion).thenAnswer((_) async => {});
    when(() => client.visionAccess).thenReturn(const NaiAgentVisionAccess());
    // Pi read the conversation back from the session file.
    when(() => client.initialState).thenReturn({
      'messages': [
        {'role': 'user', 'timestamp': 1, 'content': 'draw rain'},
        {'role': 'assistant', 'timestamp': 2, 'content': 'done'},
      ],
    });
    when(() => client.events).thenAnswer((_) => events.stream);
    when(() => client.close()).thenAnswer((_) async {
      closed = true;
      await events.close();
    });
    when(
      () => client.prompt(
        any(),
        images: any(named: 'images'),
        steer: any(named: 'steer'),
        queueId: any(named: 'queueId'),
      ),
    ).thenAnswer((_) async {
      await holdReply?.future;
      return {'messages': <Object>[]};
    });
    return client;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-host-reaper-');
    hosts = [];
    resumed = [];
    holdReply = null;
    final store = AgentWorkspaceStore(root);
    final workspace = await store.createWorkspace('Fixture');
    final chat = await store.createChat(workspace.id, 'Saved');
    final session = File(
      p.join(workspace.agentDirectory.path, 'sessions', 'saved.jsonl'),
    );
    await session.create(recursive: true);
    await store.updateChat(
      workspace.id,
      chat.id,
      sessionFile: p.join('sessions', 'saved.jsonl'),
    );
    controller = NaiAgentWorkspaceController(
      store: store,
      startClient: (_, __, ___, ____, resume) async {
        resumed.add(resume == null ? null : p.basename(resume.path));
        final client = host();
        hosts.add(client);
        return client;
      },
      initialWorkspaceName: 'Workspace',
      initialChatName: 'New chat',
    );
    await controller.initialize(restoreHistory: false);
    reaper = NaiAgentHostReaper(controller, idle: idle);
  });

  tearDown(() async {
    reaper.dispose();
    if (holdReply case final hold? when !hold.isCompleted) hold.complete();
    await controller.close();
    controller.dispose();
    await root.delete(recursive: true);
  });

  test('a send during idle close waits for a fresh host', () async {
    await controller.loadHistory();
    final old = hosts.single;
    final closing = Completer<void>();
    final finish = Completer<void>();
    when(() => old.close()).thenAnswer((_) async {
      closing.complete();
      await finish.future;
    });
    final releasing = controller.releaseIdleHosts();
    await closing.future;
    final sending = controller.sendText('queued during idle close');
    try {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(hosts, hasLength(1));
      verifyNever(
        () => old.prompt(
          any(),
          images: any(named: 'images'),
          steer: any(named: 'steer'),
          queueId: any(named: 'queueId'),
        ),
      );
    } finally {
      finish.complete();
      await releasing;
    }
    expect(await sending, isTrue);
    expect(hosts, hasLength(2));
    verify(
      () => hosts.last.prompt(
        'queued during idle close',
        images: any(named: 'images'),
        steer: any(named: 'steer'),
        queueId: any(named: 'queueId'),
      ),
    ).called(1);
  });

  for (final platform in ['macOS', 'Windows']) {
    group('$platform panel', () {
      late NaiAgentWindowController window;
      setUp(() {
        window = NaiAgentWindowController(
          // macOS has no native window growth (naiAgentWindowHostProvider).
          host: platform == 'Windows' ? _WindowsWindow() : null,
          readSettings: () async => controller.settings,
          saveExpanded: (expanded) =>
              controller.updateSettings({'panelExpanded': expanded}),
        );
      });
      tearDown(() => window.dispose());

      Future<void> openPanel() async {
        await window.toggle();
        expect(controller.settings.panelExpanded, isTrue);
      }

      Future<void> closePanel() async {
        await window.toggle();
        expect(controller.settings.panelExpanded, isFalse);
      }

      test('closing the panel for the idle time closes the host; reopening '
          'resumes the conversation', () async {
        await openPanel();
        // AgentWiring loads the history when the panel first mounts.
        await controller.loadHistory();
        expect(hosts, hasLength(1));
        expect(resumed, ['saved.jsonl']);

        await Future<void>.delayed(idle * 3);
        expect(hosts.single.isClosed, isFalse, reason: 'panel still open');

        await closePanel();
        await waitFor(() => hosts.single.isClosed, 'the idle close');
        verify(() => hosts.single.close()).called(1);
        final chat = controller.selected!;
        expect(chat.client, isNull);
        expect(chat.messages, hasLength(2), reason: 'history stays shown');
        expect(chat.error, isNull);

        await openPanel();
        await waitFor(() => hosts.length == 2, 'the restart');
        await waitFor(() => chat.client == hosts.last, 'the resumed host');
        expect(resumed, ['saved.jsonl', 'saved.jsonl']);
        expect(chat.messages, hasLength(2));
        expect(chat.error, isNull);
        // The resumed host is used for the next message.
        expect(await controller.sendText('more rain'), isTrue);
        expect(hosts, hasLength(2));
      });

      test('a run in progress keeps the host with the panel closed', () async {
        await openPanel();
        await controller.loadHistory();
        holdReply = Completer<void>();
        final sending = controller.sendText('draw a long series');
        await waitFor(() => controller.selected!.running, 'the run');
        await closePanel();
        await Future<void>.delayed(idle * 3);
        expect(hosts.single.isClosed, isFalse);

        holdReply!.complete();
        expect(await sending, isTrue);
        expect(controller.selected!.running, isFalse);
        await waitFor(() => hosts.single.isClosed, 'the close after the run');
        expect(hosts, hasLength(1));
      });

      test('opening the panel before the idle time keeps the host', () async {
        await openPanel();
        await controller.loadHistory();
        await closePanel();
        await Future<void>.delayed(idle ~/ 2);
        await openPanel();
        await Future<void>.delayed(idle * 2);
        expect(hosts.single.isClosed, isFalse);
        expect(hosts, hasLength(1));
      });
    });
  }
}

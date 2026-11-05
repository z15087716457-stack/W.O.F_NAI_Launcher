import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/vision_access.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';

import '../../../helpers/app_logger_test_isolation.dart';
import '../../../helpers/light_theme_contrast.dart';

class _Client extends Mock implements PiHostClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory root;
  late AgentWorkspaceStore store;
  final controllers = <NaiAgentWorkspaceController>[];
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent_app_quit_');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() async {
    for (final controller in controllers) {
      await controller.close();
      controller.dispose();
    }
    controllers.clear();
    await root.delete(recursive: true);
  });
  NaiAgentWorkspaceController controller({
    AgentClientFactory? start,
    Duration hostIdleTimeout = const Duration(minutes: 30),
  }) {
    final result = NaiAgentWorkspaceController(
      store: store,
      initialWorkspaceName: 'Fixture',
      initialChatName: 'Chat',
      hostIdleTimeout: hostIdleTimeout,
      startClient:
          start ??
          (_, __, ___, ____, _____) async =>
              throw StateError('No host may start'),
    );
    controllers.add(result);
    return result;
  }

  test(
    'all held chats save and close concurrently; repeated close joins them',
    () async {
      final workspace = await store.createWorkspace('Fixture');
      final chats = [
        await store.createChat(workspace.id, 'First'),
        await store.createChat(workspace.id, 'Second'),
      ];
      final c = controller();
      await c.initialize(restoreHistory: false);
      final gates = <Completer<void>>[];
      final started = <Completer<void>>[];
      final clients = <_Client>[];
      final runtimes = <AgentChatRuntime>[];
      addTearDown(() {
        for (final gate in gates) {
          if (!gate.isCompleted) gate.complete();
        }
      });
      for (final chat in chats) {
        await c.selectChat(chat.id);
        final runtime = c.selected!;
        runtime.composer = AgentComposerState(
          text: 'latest ${chat.title}',
          pending: [
            {'queueId': chat.id, 'text': 'recover me'},
          ],
        );
        runtime.running = true;
        final gate = Completer<void>();
        final begin = Completer<void>();
        final client = _Client();
        when(() => client.isClosed).thenReturn(false);
        when(client.cancelSuggestion).thenAnswer((_) async => {});
        when(client.close).thenAnswer((_) async {
          begin.complete();
          await gate.future;
        });
        runtime.client = client;
        gates.add(gate);
        started.add(begin);
        clients.add(client);
        runtimes.add(runtime);
      }
      var notices = 0;
      c.addListener(() => notices++);
      var finished = false;
      final closing = c.close();
      expect(c.close(), same(closing));
      final completed = closing.then((_) => finished = true);
      await Future.wait(started.map((value) => value.future));
      for (final runtime in runtimes) {
        final saved = await store.readComposer(workspace.id, runtime.chat.id);
        expect(saved.text, 'latest ${runtime.chat.title}');
        expect(saved.interrupted, isTrue);
        expect(saved.pending.single['text'], 'recover me');
      }
      gates.last.complete();
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      gates.first.complete();
      await completed;
      expect(notices, 0);
      for (final client in clients) {
        verify(client.close).called(1);
      }
    },
  );

  test('reopen and send during idle close share the next host', () async {
    final workspace = await store.createWorkspace('Fixture');
    final chat = await store.createChat(workspace.id, 'Saved');
    await store.updateChat(
      workspace.id,
      chat.id,
      sessionFile: 'sessions/fixture.jsonl',
    );
    final began = Completer<void>();
    final finish = Completer<void>();
    addTearDown(() {
      if (!finish.isCompleted) finish.complete();
    });
    final clients = [_Client(), _Client()];
    for (final client in clients) {
      when(() => client.isClosed).thenReturn(false);
      when(() => client.hasPendingRequests).thenReturn(false);
      when(() => client.visionAccess).thenReturn(const NaiAgentVisionAccess());
      when(() => client.initialState).thenReturn({});
      when(() => client.events).thenAnswer((_) => const Stream.empty());
      when(client.close).thenAnswer((_) async {});
    }
    final old = clients.first;
    final fresh = clients.last;
    when(old.close).thenAnswer((_) async {
      began.complete();
      await finish.future;
    });
    when(
      () => fresh.prompt(
        any(),
        images: any(named: 'images'),
        steer: any(named: 'steer'),
        queueId: any(named: 'queueId'),
      ),
    ).thenAnswer((_) async => {});
    var starts = 0;
    final c = controller(
      hostIdleTimeout: const Duration(milliseconds: 30),
      start: (_, __, ___, ____, _____) async => clients[starts++],
    );
    await c.initialize(restoreHistory: false);
    await c.updateSettings({'panelExpanded': true});
    await c.loadHistory();
    // Opening already started loading. Wait until the client is installed.
    for (var i = 0; i < 200 && c.selected!.starting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(c.selected!.client, same(old));
    await c.updateSettings({'panelExpanded': false});
    await began.future.timeout(const Duration(seconds: 5));
    await c.updateSettings({'panelExpanded': true});
    final sending = c.sendText('after idle close');
    expect(starts, 1);
    expect(c.selected!.client, isNull);
    finish.complete();

    expect(await sending, isTrue);
    expect(starts, 2);
    expect(c.selected!.client, same(fresh));
    verify(old.close).called(1);
    verify(
      () => fresh.prompt(
        'after idle close',
        images: any(named: 'images'),
        steer: any(named: 'steer'),
        queueId: any(named: 'queueId'),
      ),
    ).called(1);
  });

  for (final initializing in [false, true]) {
    test(
      'quit during ${initializing ? 'initial' : 'later'} host startup waits for the late child to close',
      () async {
        final workspace = await store.createWorkspace('Fixture');
        final chat = await store.createChat(workspace.id, 'Saved');
        await store.updateChat(
          workspace.id,
          chat.id,
          sessionFile: 'sessions/fixture.jsonl',
        );
        final entered = Completer<void>();
        final opening = Completer<PiHostClient>();
        final closeStarted = Completer<void>();
        final closeRelease = Completer<void>();
        final client = _Client();
        addTearDown(() {
          if (!opening.isCompleted) opening.complete(client);
          if (!closeRelease.isCompleted) closeRelease.complete();
        });
        when(client.close).thenAnswer((_) async {
          closeStarted.complete();
          await closeRelease.future;
        });
        final c = controller(
          start: (_, __, ___, ____, _____) {
            entered.complete();
            return opening.future;
          },
        );
        late Future<void> loading;
        if (initializing) {
          c.ready = c.initialize();
          loading = c.ready;
        } else {
          await c.initialize(restoreHistory: false);
          loading = c.loadHistory();
        }
        await entered.future;
        var finished = false;
        final closing = c.close().then((_) => finished = true);
        await Future<void>.delayed(Duration.zero);
        expect(finished, isFalse);
        opening.complete(client);
        await closeStarted.future;
        expect(finished, isFalse);
        closeRelease.complete();
        await Future.wait([loading, closing]);
        expect(c.selected!.client, isNull);
        verify(client.close).called(1);
      },
    );
  }

  test(
    'application cleanup owns the real provider without starting a cold Agent',
    () async {
      final workspace = await store.createWorkspace('Fixture');
      final chat = await store.createChat(workspace.id, 'Saved');
      final container = createStorageFreeContainer(
        overrides: [
          naiAgentWorkspaceStoreProvider.overrideWithValue(store),
          naiAgentClientFactoryProvider.overrideWithValue((
            _,
            __,
            ___,
            ____,
            _____,
          ) async {
            fail('Shutdown must not start an Agent');
          }),
        ],
      );
      try {
        await DesktopAppShutdownService.prepareBackgroundShutdown();
        expect(container.exists(naiAgentControllerProvider), isFalse);
        final c = container.read(naiAgentControllerProvider);
        await c.ready;
        c.selected!.composer = const AgentComposerState(
          text: 'unsaved latest draft',
        );
        final client = _Client();
        when(client.close).thenAnswer((_) async {});
        c.selected!.client = client;
        await DesktopAppShutdownService.prepareBackgroundShutdown();
        expect(
          (await store.readComposer(workspace.id, chat.id)).text,
          'unsaved latest draft',
        );
        verify(client.close).called(1);
      } finally {
        container.dispose();
      }
    },
  );
}

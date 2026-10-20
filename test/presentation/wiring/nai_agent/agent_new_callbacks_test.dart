import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_wiring.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart' as view;

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

class _Controller extends AgentTestController {
  _Controller(super.store);
  String? failure;
  List<AgentChatSearchHit> hits = [];
  final deleted = <String>[];
  final restored = <String>[];
  bool canSendText = true;

  @override
  Future<bool> sendText(String text) async {
    check();
    calls.add('sendText:$text');
    return canSendText;
  }

  void check() {
    if (failure != null) throw StateError(failure!);
  }

  @override
  Future<String> deleteChat(String chatId) async {
    check();
    deleted.add('chat:$chatId');
    return super.deleteChat(chatId);
  }

  @override
  Future<String> deleteWorkspace(String workspaceId) async {
    check();
    deleted.add('workspace:$workspaceId');
    return super.deleteWorkspace(workspaceId);
  }

  @override
  Future<void> undoDeleteChat(String trashId) async {
    check();
    restored.add('chat:$trashId');
    await super.undoDeleteChat(trashId);
  }

  @override
  Future<void> undoDeleteWorkspace(String trashId) async {
    check();
    restored.add('workspace:$trashId');
    await super.undoDeleteWorkspace(trashId);
  }

  @override
  Future<List<AgentChatSearchHit>> searchChats(String query) async {
    calls.add('search:$query');
    check();
    return hits;
  }

  @override
  Future<void> updateSettings(
    Map<String, dynamic> changes, {
    Map<String, dynamic>? expected,
  }) async {
    check();
    await super.updateSettings(changes, expected: expected);
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  late _Controller c;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init(controller: (store) => c = _Controller(store));
  });
  tearDown(() async => h.dispose());
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('Continue uses localized standalone send and keeps the draft', (
    tester,
  ) async {
    await tester.runAsync(() => c.saveComposer('unrelated draft'));
    c.selected!.runLimitHit = 17;
    c.selected!.error = 'stale error';
    await h.pump(tester);
    final panel = h.panel(tester);
    expect(panel.data.runLimit, 17);
    expect(panel.data.error, isNull);
    expect(await panel.actions.onContinue(), true);
    expect(c.calls, ['sendText:${currentL10n.ag_continueMessage}']);
    expect(c.selected!.composer.text, 'unrelated draft');
    c.canSendText = false;
    expect(await panel.actions.onContinue(), false);
    c.failure = 'cannot send';
    expect(await panel.actions.onContinue(), false);
    expect(c.calls, isNot(contains('send')));
    expect(c.calls.where((s) => s.startsWith('edit:')), isEmpty);
  });

  testWidgets('Adjust limit opens Agent settings at agentMaxRequests', (
    tester,
  ) async {
    await h.pump(tester);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: AgentWiring()),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('settings target')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    h.panel(tester).actions.onAdjustLimit();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/settings');
    expect(router.routeInformationProvider.value.uri.queryParameters, {
      'section': 'agent',
      'anchor': 'agentMaxRequests',
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('chat trash token round trip restores draft without exporting', (
    tester,
  ) async {
    await h.pump(tester);
    final original = c.selected!.chat;
    final actions = h.panel(tester).actions;
    expect(h.panel(tester).data.chats.single.canExport, false);
    final token = await tester.runAsync(
      () => actions.onDeleteChat(original.id),
    );
    expect(token, startsWith('chat:'));
    expect(c.selected!.chat.id, isNot(original.id));
    expect(await tester.runAsync(() => actions.onUndoDelete(token!)), true);
    expect(c.selected!.chat.id, original.id);
    expect(c.selected!.chat.isDraft, true);
    expect(c.restored, [token]);
    expect(await tester.runAsync(() => actions.onUndoDelete(token!)), false);
    await h.finishFiles(tester);
    expect(h.panel(tester).data.chat.canExport, false);
    expect(c.calls, isNot(contains('send')));
  });

  testWidgets('workspace tokens dispatch independently; last workspace fails', (
    tester,
  ) async {
    await h.pump(tester);
    final actions = h.panel(tester).actions;
    final original = c.selectedWorkspace!.id;
    expect(
      await tester.runAsync(() => actions.onDeleteWorkspace(original)),
      isNull,
    );
    await tester.runAsync(() => c.createWorkspace('second'));
    final token = await tester.runAsync(
      () => actions.onDeleteWorkspace(original),
    );
    expect(token, startsWith('workspace:'));
    expect(c.workspaces.map((w) => w.id), isNot(contains(original)));
    expect(await tester.runAsync(() => actions.onUndoDelete(token!)), true);
    expect(c.selectedWorkspace!.id, original);
    expect(c.restored, [token]);
    await h.finishFiles(tester);
  });

  testWidgets('busy/importing/I/O failures and malformed undo never escape', (
    tester,
  ) async {
    await h.pump(tester);
    final actions = h.panel(tester).actions;
    final id = c.selected!.chat.id;
    for (final failure in ['running', 'importing', 'last_workspace', 'I/O']) {
      c.failure = failure;
      expect(await actions.onDeleteChat(id), isNull);
      expect(await actions.onDeleteWorkspace(c.selectedWorkspace!.id), isNull);
      expect(await actions.onUndoDelete('chat:trash'), false);
      expect(await actions.onUndoDelete('workspace:trash'), false);
    }
    c.failure = null;
    for (final token in ['', 'trash', 'chat:', ':id', 'other:id']) {
      expect(await actions.onUndoDelete(token), false);
    }
    expect(c.deleted, isEmpty);
    expect(c.restored, isEmpty);
    c.selected!.running = true;
    expect(await actions.onDeleteChat(id), isNull);
    c.selected!.running = false;
    c.selected!.importingImages = 1;
    expect(await actions.onDeleteChat(id), isNull);
    c.selected!.importingImages = 0;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search maps snippets and both title fallbacks; failure is empty',
    (tester) async {
      await h.pump(tester);
      final chat = c.selected!.chat;
      c.hits = [
        AgentChatSearchHit(chatId: chat.id, title: '', snippet: 'matched body'),
        const AgentChatSearchHit(
          chatId: 'named',
          title: 'Title',
          snippet: '…hit…',
        ),
        const AgentChatSearchHit(
          chatId: 'unknown',
          title: ' ',
          snippet: 'other',
        ),
      ];
      final actions = h.panel(tester).actions;
      final hits = await actions.onSearchChats('needle');
      expect(hits.map((h) => h.chatId), [chat.id, 'named', 'unknown']);
      expect(hits.map((h) => h.title), [
        chat.title,
        'Title',
        c.initialChatName,
      ]);
      expect(hits.map((h) => h.snippet), ['matched body', '…hit…', 'other']);
      expect(c.calls.last, 'search:needle');
      c.failure = 'unreadable';
      expect(await actions.onSearchChats('needle'), isEmpty);
    },
  );

  testWidgets('bypass writes by name and silence persists with failure guard', (
    tester,
  ) async {
    await h.pump(tester);
    final actions = h.panel(tester).actions;
    expect(h.panel(tester).data.bypassWarned, false);
    expect(
      await tester.runAsync(
        () => actions.onPermission(view.AgentPermissionMode.bypass),
      ),
      true,
    );
    expect(c.settings.permissionMode, 'bypass');
    expect(await tester.runAsync(actions.onSilenceBypass), true);
    await tester.pump();
    expect(h.panel(tester).data.bypassWarned, true);
    expect(h.panel(tester).data.permission, view.AgentPermissionMode.bypass);
    expect((await c.store.readSettings()).bypassWarned, true);
    c.failure = 'write failed';
    expect(await actions.onSilenceBypass(), false);
  });

  testWidgets('mapping usage exposes Anlas and image callbacks fail safely', (
    tester,
  ) async {
    final r = c.selected!;
    await tester.runAsync(
      () => File(
        '${r.workspace.directory.path}/out.png',
      ).writeAsBytes(img.encodePng(img.Image(width: 4, height: 3))),
    );
    r.messages = [
      {'role': 'user', 'content': 'make picture'},
      {
        'role': 'assistant',
        'content': [
          {'type': 'toolCall', 'id': 'gen', 'name': 'image_generate'},
        ],
      },
      {
        'role': 'toolResult',
        'toolCallId': 'gen',
        'details': {
          'estimated_anlas': 23,
          'artifacts': [
            {'type': 'image', 'path': 'out.png'},
          ],
        },
      },
    ];
    await h.pump(tester, files: true);
    final panel = h.panel(tester);
    expect(panel.data.usage.anlas, 23);
    expect(
      await panel.actions.onImageAction(
        'missing',
        view.AgentImageAction.folder,
      ),
      false,
    );
    expect(
      await panel.actions.onImageAction(
        'missing',
        view.AgentImageAction.params,
      ),
      false,
    );
    final image = panel.data.shelf.groups.single.images.single;
    expect(image.path, isNotNull);
  });

  testWidgets('draft export stays disabled even with stale session reference', (
    tester,
  ) async {
    final old = c.selected!.chat;
    final draft = AgentChat(
      id: old.id,
      workspaceId: old.workspaceId,
      title: '',
      createdAt: old.createdAt,
      isDraft: true,
      sessionFile: 'sessions/stale.jsonl',
    );
    c.selected!.chat = draft;
    c.chats = [draft];
    await h.pump(tester);
    expect(h.panel(tester).data.chat.title, c.initialChatName);
    expect(h.panel(tester).data.chat.canExport, false);
    expect(h.panel(tester).data.chats.single.canExport, false);
    expect(
      File(
        '${c.selected!.workspace.directory.path}/sessions/stale.jsonl',
      ).existsSync(),
      false,
    );
  });
}

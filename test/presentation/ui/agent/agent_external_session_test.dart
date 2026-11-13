import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_fixture.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'agent_test_harness.dart';

AgentViewData externalView({
  bool connected = true,
  bool internal = false,
  bool empty = false,
  bool running = false,
  String client = 'Codex',
}) {
  final f = AgentFixture.view(AgentScene.promptSets);
  final chat = AgentChatInfo(
    id: f.chat.id,
    title: '雨夜咖啡馆 · 四幕',
    createdAt: f.chat.createdAt,
    externalClient: internal ? null : client,
  );
  return AgentViewData(
    now: f.now,
    workspace: f.workspace,
    chat: chat,
    workspaces: f.workspaces,
    chats: [chat, ...f.chats.skip(1)],
    composer: f.composer,
    thread: empty ? [] : f.thread,
    shelf: f.shelf,
    usage: const AgentUsageData(),
    models: f.models,
    thinking: f.thinking,
    permission: f.permission,
    mentions: f.mentions,
    skills: f.skills,
    memory: f.memory,
    externalConnected: connected,
    externalNotice: internal ? client : null,
    status: running ? AgentRunStatus.working : AgentRunStatus.idle,
  );
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'external session $locale dark=$dark keeps native cards at 320–520px',
        (tester) async {
          for (final width in [320.0, 360.0, 460.0, 520.0]) {
            await pumpAgent(
              tester,
              data: externalView(),
              width: width,
              locale: locale,
              dark: dark,
            );
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const Key('agent-external-footer')),
              findsOneWidget,
            );
            expect(find.byKey(const Key('agent-composer')), findsNothing);
            expect(
              find.byKey(const Key('agent-external-disconnect')),
              findsOneWidget,
            );
            expect(find.textContaining('Codex'), findsWidgets);
            if (width == 460) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('agent-capture')),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                final file = File(
                  '.dart_tool/external-agent-20261113/ui/$locale-${dark ? 'dark' : 'light'}.png',
                );
                file.parent.createSync(recursive: true);
                file.writeAsBytesSync(bytes!.buffer.asUint8List());
              });
            }
            final actions = await pumpAgent(
              tester,
              data: externalView(running: true),
              width: width,
              locale: locale,
              dark: dark,
            );
            final l = AppLocalizations.of(
              tester.element(find.byKey(const Key('agent-external-footer'))),
            )!;
            expect(tester.takeException(), isNull);
            await tester.tap(find.text(l.ag_stop));
            expect(actions.names, contains('stop'));
          }
        },
      );
    }
  }
  testWidgets(
    'disconnected and empty sessions retain their external attribution',
    (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('zh'));
      await pumpAgent(
        tester,
        data: externalView(connected: false, empty: true),
        width: 360,
      );
      expect(find.text(l.ag_externalDisconnected), findsOneWidget);
      expect(find.byKey(const Key('agent-composer')), findsNothing);
      expect(find.byKey(const Key('agent-external-disconnect')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a long external client label fits the header and request line', (
    tester,
  ) async {
    await pumpAgent(
      tester,
      data: externalView(
        client:
            'External client with a very long task runner name 123456789012345',
      ),
      width: 320,
      locale: 'en',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('internal sessions retain the composer and show a View notice', (
    tester,
  ) async {
    await pumpAgent(tester, data: externalView(internal: true), width: 360);
    expect(find.byKey(const Key('agent-composer')), findsOneWidget);
    expect(find.byKey(const Key('agent-external-footer')), findsNothing);
    expect(find.byKey(const Key('agent-view-external')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/attachment_manifest.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'agent_wiring_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init();
    final r = h.c.selected!;
    final image = {
      'type': 'image',
      'mimeType': 'image/png',
      'data': base64Encode(img.encodePng(img.Image(width: 1, height: 1))),
    };
    r.entries = [
      {'id': 'entry', 'parentId': null, 'role': 'user', 'timestamp': 10},
    ];
    r.userEntries = [
      {'entryId': 'off-branch', 'text': 'not current'},
      {'entryId': 'entry', 'text': 'original'},
    ];
    r.messages = [
      {
        'role': 'user',
        'timestamp': 10,
        'content': [
          {
            'type': 'text',
            'text':
                'original${agentAttachmentManifest([
                  {'path': 'attachments/first.png'},
                  {'path': 'attachments/second.png'},
                ], vision: true)}',
          },
          image,
          {'type': 'text', 'text': ''},
          image,
        ],
      },
      {'role': 'assistant', 'timestamp': 20, 'content': 'old answer'},
    ];
    r.composer = const AgentComposerState(
      text: 'unrelated bottom draft',
      attachments: [
        AgentAttachment(
          id: 'draft',
          name: 'draft.png',
          relativePath: 'draft.png',
          mimeType: 'image/png',
          bytes: 0,
          sha256Hex: 'synthetic',
        ),
      ],
      pending: [
        {'queueId': 'pending', 'text': 'unsent', 'recovered': true},
      ],
      interrupted: true,
    );
  });
  tearDown(() async => h.dispose());
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
    'inline resend translates exact image ids and forwards result without touching draft',
    (tester) async {
      final r = h.c.selected!;
      final draft = r.composer;
      await h.pump(tester);
      await h.finishFiles(tester);
      final panel = h.panel(tester);
      final user = panel.data.thread.single.user;
      expect(user.entryId, 'entry');
      expect(user.images, hasLength(2));
      expect(panel.data.thread.single.reply!.canRegenerate, true);
      // Cancel is local to UI; merely projecting/editing does not invoke backend.
      expect(h.c.resends, isEmpty);
      expect(
        await panel.actions.onResendFrom('entry', 'new question', [
          user.images.last.id,
        ]),
        true,
      );
      expect(h.c.resends, hasLength(1));
      expect(h.c.resends.single.$1, 'entry');
      expect(h.c.resends.single.$2, 'new question');
      expect(h.c.resends.single.$3, [3]);
      expect(h.c.calls, ['resend:entry']);
      expect(r.composer, same(draft));
      h.c.canResend = false;
      expect(await panel.actions.onResendFrom('entry', 'failed', []), false);
      expect(r.composer, same(draft));
    },
  );

  testWidgets(
    'regenerate uses original stripped text and every image, ignoring bottom draft',
    (tester) async {
      final r = h.c.selected!;
      final draft = r.composer;
      await h.pump(tester);
      expect(await h.panel(tester).actions.onRegenerate(), true);
      expect(h.c.resends, hasLength(1));
      expect(h.c.resends.single.$1, 'entry');
      expect(h.c.resends.single.$2, 'original');
      expect(h.c.resends.single.$3, [1, 3]);
      expect(h.c.calls, ['resend:entry']);
      expect(r.composer, same(draft));
    },
  );

  testWidgets(
    'stale/foreign ids, missing entries and busy states cannot resend or regenerate',
    (tester) async {
      final r = h.c.selected!;
      await h.pump(tester);
      final a = h.panel(tester).actions;
      for (final state in ['running', 'starting', 'pending']) {
        r.running = state == 'running';
        r.starting = state == 'starting';
        r.pendingSends = state == 'pending' ? 1 : 0;
        expect(await a.onResendFrom('entry', 'new', []), false);
        expect(await a.onRegenerate(), false);
      }
      r.running = r.starting = false;
      r.pendingSends = 0;
      expect(
        await a.onResendFrom('entry', 'new', ['other/turn/0/user/1']),
        false,
      );
      expect(await a.onResendFrom('off-branch', 'new', []), false);
      final id = '${r.chat.id}/turn/0/user/1';
      expect(await a.onResendFrom('entry', 'new', [id, id]), false);
      r.entries = [];
      expect(await a.onRegenerate(), false);
      expect(h.c.resends, isEmpty);
      expect(h.c.calls, isEmpty);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../wiring/nai_agent/agent_wiring_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init();
  });
  tearDown(() async {
    await h.dispose();
  });
  final pixels = img.encodePng(img.Image(width: 64, height: 48));
  const quote = {
    'tool': 'cloud_upscale',
    'width': 832,
    'height': 1216,
    'account_name': 'Synthetic',
    'estimated_anlas': 1,
    'balance_anlas': 2218,
  };
  Future<bool> request({
    void Function()? check,
    NaiAgentCancellation? token,
    DateTime? expires,
  }) {
    final r = h.c.selected!;
    return h.container
        .read(naiAgentImageApprovalsProvider)
        .request(
          NaiAgentConversationOwner(r.workspace.id, r.chat.id),
          quote,
          expires ?? DateTime.now().add(const Duration(minutes: 5)),
          token ?? NaiAgentCancellation(),
          check ?? () {},
          sourceBytes: pixels,
        );
  }

  testWidgets(
    'real image gate button only; account changes disable but retain cancel',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final account = h.container.read(authNotifierProvider).accountId;
      final answer = request(
        check: () {
          if (h.container.read(authNotifierProvider).accountId != account) {
            throw const NaiAgentToolError('quote_changed', 'changed');
          }
        },
      );
      await h.pump(tester);
      final gate = h.panel(tester).data.composer.pending.single as AgentGate;
      expect(gate.ready, true);
      expect(gate.changed, false);
      expect(gate.expiresAt.isAfter(DateTime.now()), true);
      expect(gate.totalAnlas, 1);
      expect(gate.balanceAnlas, 2218);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(
        h.container
            .read(naiAgentImageApprovalsProvider)
            .forChat(h.c.selected!.chat.id),
        hasLength(1),
      );
      (h.container.read(authNotifierProvider.notifier) as AgentTestAuth)
          .changeAccount();
      await tester.pump();
      expect(
        (h.panel(tester).data.composer.pending.single as AgentGate).ready,
        false,
      );
      await tester.tap(find.byKey(const Key('agent-gate-confirm')));
      await tester.pump();
      expect(
        h.container
            .read(naiAgentImageApprovalsProvider)
            .forChat(h.c.selected!.chat.id),
        hasLength(1),
      );
      await tester.tap(find.byKey(const Key('agent-gate-cancel')));
      await tester.pump();
      expect(await answer, false);
      final next = request();
      await tester.pump();
      await tester.tap(find.byKey(const Key('agent-gate-confirm')));
      await tester.pump();
      expect(await next, true);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('decision rechecks even if the rendered image quote was ready', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var valid = true;
    final answer = request(
      check: () {
        if (!valid) throw const NaiAgentToolError('quote_changed', 'changed');
      },
    );
    final failure = expectLater(answer, throwsA(isA<NaiAgentToolError>()));
    await h.pump(tester);
    valid = false;
    h
        .panel(tester)
        .actions
        .onDecideGate(
          h.panel(tester).data.composer.pending.single.id,
          confirm: true,
        );
    await tester.pump();
    await failure;
    await tester.pumpWidget(const SizedBox());
  });
  test('image approval expiry and Stop fail their wait', () async {
    await expectLater(
      request(expires: DateTime.now().subtract(const Duration(seconds: 1))),
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'quote_expired'),
      ),
    );
    final token = NaiAgentCancellation();
    final future = request(token: token);
    token.cancel();
    await expectLater(
      future,
      throwsA(
        isA<NaiAgentToolError>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
  });
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in Brightness.values) {
      testWidgets('real-font image gate $locale $brightness at 320/440', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final future = request();
        for (final width in [320.0, 440.0]) {
          await h.pump(
            tester,
            width: width,
            locale: Locale(locale),
            brightness: brightness,
          );
          expect(find.byKey(const Key('agent-gate-confirm')), findsOneWidget);
          expect(find.byType(Image), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        h
            .panel(tester)
            .actions
            .onDecideGate(
              h.panel(tester).data.composer.pending.single.id,
              confirm: false,
            );
        await tester.pump();
        await future;
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

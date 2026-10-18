import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
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
  final source = img.encodePng(img.Image(width: 256, height: 384));
  Future<bool> request(String operation, {void Function()? check}) {
    final r = h.c.selected!;
    return h.container
        .read(naiAgentGenerationApprovalsProvider)
        .request(
          NaiAgentConversationOwner(r.workspace.id, r.chat.id),
          NaiAgentGenerationQuote(
            id: 'synthetic',
            input: NaiAgentGenerationInput(
              raw: ImageParams(
                model: 'nai-diffusion-5-full',
                prompt: 'detailed background',
                action: ImageGenerationAction.img2img,
                sourceImage: source,
                width: 256,
                height: 384,
                nSamples: 2,
                strength: operation == 'variations' ? .8 : .5,
                noise: operation == 'variations' ? .1 : 0,
                upscaledEnhance: operation == 'enhance',
              ),
              effective: ImageParams(
                model: 'nai-diffusion-5-full',
                prompt: 'detailed background',
                width: 256,
                height: 384,
                upscaledEnhance: operation == 'enhance',
              ),
              draftVersion: 'frozen',
              batchSize: operation == 'variations' ? 3 : 1,
              billing: const {
                'estimated_anlas': 56,
                'per_request_anlas': 27,
                'encoding_anlas': 2,
                'balance_anlas': 2218,
              },
              accountId: 'synthetic',
              accountName: 'Synthetic account',
              endpoint: 'none',
              sourceOperation: operation,
              localEnhance: const {'model': 'SeedVR2', 'scale': 2},
            ),
            params: const {},
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          ),
          NaiAgentCancellation(),
          check ?? () {},
        );
  }

  testWidgets(
    'generation check uses Studio price, count contract and rechecks decision',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var valid = true;
      final answer = request(
        'variations',
        check: () {
          if (!valid) throw const NaiAgentToolError('quote_changed', 'changed');
        },
      );
      final failed = expectLater(answer, throwsA(isA<NaiAgentToolError>()));
      await h.pump(tester);
      final gate = h.panel(tester).data.composer.pending.single as AgentGate;
      expect(gate.requests, 2);
      expect(gate.batch, 3);
      expect(gate.totalAnlas, 56);
      expect(gate.unitAnlas, 27);
      expect(gate.encodingAnlas, 2);
      expect(gate.balanceAnlas, 2218);
      expect(gate.kind, AgentGateKind.variations);
      expect(gate.extra, contains('SeedVR2'));
      valid = false;
      h.panel(tester).actions.onDecideGate(gate.id, confirm: true);
      await tester.pump();
      await failed;
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'account dependency change updates ready before accepting generation',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final account = h.container.read(authNotifierProvider).accountId;
      final answer = request(
        'enhance',
        check: () {
          if (h.container.read(authNotifierProvider).accountId != account) {
            throw StateError('changed');
          }
        },
      );
      await h.pump(tester);
      (h.container.read(authNotifierProvider.notifier) as AgentTestAuth)
          .changeAccount();
      await tester.pump();
      expect(
        (h.panel(tester).data.composer.pending.single as AgentGate).changed,
        true,
      );
      await tester.tap(find.byKey(const Key('agent-gate-cancel')));
      await tester.pump();
      expect(await answer, false);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final operation in ['variations', 'enhance']) {
    for (final locale in ['zh', 'en', 'ja', 'ko']) {
      for (final width in [320.0, 440.0]) {
        testWidgets(
          '$operation gate real-font $locale $width retains source and paid decision',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final answer = request(operation);
            await h.pump(
              tester,
              width: width,
              locale: Locale(locale),
              brightness: width == 320 ? Brightness.dark : Brightness.light,
            );
            expect(find.byType(Image), findsOneWidget);
            final gate =
                h.panel(tester).data.composer.pending.single as AgentGate;
            expect((gate.source as MemoryImage).bytes, source);
            expect(gate.width, operation == 'variations' ? 256 : 512);
            expect(gate.prompt, contains('detailed background'));
            await tester.ensureVisible(
              find.byKey(const Key('agent-gate-confirm')),
            );
            await tester.tap(find.byKey(const Key('agent-gate-confirm')));
            await tester.pump();
            expect(await answer, true);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../../core/nai_agent/generation_tools_test.dart'
    show generationInput;

NaiAgentGenerationQuote approvalQuote({
  Duration lifetime = const Duration(minutes: 5),
}) => NaiAgentGenerationQuote(
  id: 'synthetic',
  input: generationInput(),
  params: {},
  expiresAt: DateTime.now().add(lifetime),
);

void main() {
  late NaiAgentGenerationApprovals broker;
  setUp(() {
    broker = NaiAgentGenerationApprovals();
  });
  tearDown(() {
    broker.dispose();
  });
  const owner = NaiAgentConversationOwner('workspace', 'chat');
  Matcher error(String code) =>
      isA<NaiAgentToolError>().having((e) => e.code, 'code', code);
  test(
    'approval waits for explicit button and duplicate clicks settle only once',
    () async {
      var answered = false;
      final future = broker
          .request(owner, approvalQuote(), NaiAgentCancellation(), () {})
          .then((v) {
            answered = true;
            return v;
          });
      await Future<void>.delayed(Duration.zero);
      expect(answered, false);
      final request = broker.forChat('chat').single;
      expect(request.owner.workspaceId, 'workspace');
      expect(broker.forChat('another-chat'), isEmpty);
      broker.decide('not-found', generate: true);
      expect(answered, false);
      broker.decide(request.id, generate: true);
      broker.decide(request.id, generate: false);
      expect(await future, true);
      expect(broker.forChat('chat'), isEmpty);
    },
  );
  test('decline does not require the stale quote to become valid', () async {
    var fresh = true;
    final future = broker.request(
      owner,
      approvalQuote(),
      NaiAgentCancellation(),
      () {
        if (!fresh) throw const NaiAgentToolError('quote_changed', 'Changed');
      },
    );
    fresh = false;
    broker.decide(broker.forChat('chat').single.id, generate: false);
    expect(await future, false);
  });
  test(
    'generate performs fresh check and never accepts stale approval',
    () async {
      var fresh = true;
      final future = broker.request(
        owner,
        approvalQuote(),
        NaiAgentCancellation(),
        () {
          if (!fresh) throw const NaiAgentToolError('quote_changed', 'Changed');
        },
      );
      final assertion = expectLater(future, throwsA(error('quote_changed')));
      fresh = false;
      broker.decide(broker.forChat('chat').single.id, generate: true);
      await assertion;
      expect(broker.forChat('chat'), isEmpty);
    },
  );
  test('cancel signal closes pending UI without generating', () async {
    final token = NaiAgentCancellation();
    final assertion = expectLater(
      broker.request(owner, approvalQuote(), token, () {}),
      throwsA(error('cancelled')),
    );
    token.cancel();
    await assertion;
    expect(broker.forChat('chat'), isEmpty);
  });
  test('expired authorization closes without an implicit answer', () async {
    await expectLater(
      broker.request(
        owner,
        approvalQuote(lifetime: Duration.zero),
        NaiAgentCancellation(),
        () {},
      ),
      throwsA(error('quote_expired')),
    );
    expect(broker.forChat('chat'), isEmpty);
  });
  test('separate conversations cannot complete each others approval', () async {
    final a = broker.request(
      owner,
      approvalQuote(),
      NaiAgentCancellation(),
      () {},
    );
    final b = broker.request(
      const NaiAgentConversationOwner('other-workspace', 'other-chat'),
      approvalQuote(),
      NaiAgentCancellation(),
      () {},
    );
    broker.decide(broker.forChat('chat').single.id, generate: false);
    expect(await a, false);
    expect(broker.forChat('other-chat'), hasLength(1));
    broker.decide(broker.forChat('other-chat').single.id, generate: true);
    expect(await b, true);
  });
  test(
    'owner disposal rejects all pending requests and further requests',
    () async {
      final first = expectLater(
        broker.request(owner, approvalQuote(), NaiAgentCancellation(), () {}),
        throwsA(error('closed')),
      );
      broker.dispose();
      await first;
      await expectLater(
        broker.request(owner, approvalQuote(), NaiAgentCancellation(), () {}),
        throwsA(error('closed')),
      );
      broker = NaiAgentGenerationApprovals();
    },
  );
}

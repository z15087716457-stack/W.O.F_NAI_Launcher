import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/model_request_gate.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';

void main() {
  test(
    'one shared provider gate bounds multiple callers and wakes after cancellation',
    () async {
      final gate = ModelRequestGate();
      final first = NaiAgentCancellation(),
          second = NaiAgentCancellation(),
          third = NaiAgentCancellation();
      Future<void Function()> take(NaiAgentCancellation token) => gate.acquire(
        limit: 1,
        cancellation: token.whenCancelled,
        isCancelled: () => token.isCancelled,
      );
      final release = await take(first);
      var entered = false;
      final waiting = take(second);
      final canceled = expectLater(
        waiting,
        throwsA(isA<ModelRequestCancelled>()),
      );
      final next = take(third).then((value) {
        entered = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(entered, false);
      second.cancel();
      await canceled;
      expect(gate.active, 1);
      release();
      release();
      final lastRelease = await next;
      expect(entered, true);
      expect(gate.active, 1);
      lastRelease();
      expect(gate.active, 0);
      expect(
        ModelRequestGates.shared.forProvider('a'),
        same(ModelRequestGates.shared.forProvider('a')),
      );
      expect(
        ModelRequestGates.shared.forProvider('a'),
        isNot(same(ModelRequestGates.shared.forProvider('b'))),
      );
    },
  );
}

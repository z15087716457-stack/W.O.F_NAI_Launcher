import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';

class _Quote extends Mock implements NaiAgentGenerationQuote {}

void main() {
  for (final image in [false, true]) {
    final kind = image ? 'image' : 'generation';
    test(
      '$kind confirmation releases expired, cancelled and closed requests',
      () async {
        final scope = ProviderContainer();
        final generations = scope.read(naiAgentGenerationApprovalsProvider);
        final images = scope.read(naiAgentImageApprovalsProvider);
        const owner = NaiAgentConversationOwner('workspace', 'chat');
        Future<bool> request(DateTime expiry, NaiAgentCancellation token) {
          if (image) return images.request(owner, {}, expiry, token, () {});
          final quote = _Quote();
          when(() => quote.expiresAt).thenReturn(expiry);
          return generations.request(owner, quote, token, () {});
        }

        Matcher fails(String code) => throwsA(
          isA<NaiAgentToolError>().having((e) => e.code, 'code', code),
        );

        final later = DateTime.now().add(const Duration(minutes: 2));
        final token = NaiAgentCancellation();
        final cancelled = expectLater(
          request(later, token),
          fails('cancelled'),
        );
        await expectLater(
          request(DateTime(2000), NaiAgentCancellation()),
          fails('quote_expired'),
        );
        expect(
          image ? images.forChat('chat') : generations.forChat('chat'),
          hasLength(1),
        );
        token.cancel();
        await cancelled;
        expect(
          image ? images.forChat('chat') : generations.forChat('chat'),
          isEmpty,
        );

        final closed = expectLater(
          request(later, NaiAgentCancellation()),
          fails('closed'),
        );
        scope.dispose();
        await closed;
      },
    );
  }
}

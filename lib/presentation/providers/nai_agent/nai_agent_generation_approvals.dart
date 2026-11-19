import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';
import 'nai_agent_quote_approvals.dart';

class AgentGenerationApproval extends AgentQuoteApproval {
  AgentGenerationApproval(
    NaiAgentConversationOwner owner,
    this.quote,
    void Function() check,
  ) : super(owner, quote.expiresAt, check);
  final NaiAgentGenerationQuote quote;
}

class NaiAgentGenerationApprovals
    extends NaiAgentQuoteApprovals<AgentGenerationApproval> {
  NaiAgentGenerationApprovals()
    : super('Generation', 'Authorization owner closed');

  Future<bool> request(
    NaiAgentConversationOwner owner,
    NaiAgentGenerationQuote quote,
    NaiAgentCancellation token,
    void Function() check,
  ) => waitForDecision(AgentGenerationApproval(owner, quote, check), token);

  void decide(String id, {required bool generate}) =>
      resolveDecision(id, generate);
}

final naiAgentGenerationApprovalsProvider =
    ChangeNotifierProvider<NaiAgentGenerationApprovals>(
      (ref) => NaiAgentGenerationApprovals(),
    );

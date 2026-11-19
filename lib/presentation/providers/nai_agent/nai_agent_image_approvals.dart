import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';
import 'nai_agent_quote_approvals.dart';

class AgentImageApproval extends AgentQuoteApproval {
  AgentImageApproval(
    super.owner,
    super.expiresAt,
    super.check,
    Map<String, dynamic> quote,
    this.sourceBytes,
  ) : quote = Map.unmodifiable(quote);
  final Map<String, dynamic> quote;
  final Uint8List? sourceBytes;
}

class NaiAgentImageApprovals
    extends NaiAgentQuoteApprovals<AgentImageApproval> {
  NaiAgentImageApprovals() : super('Image', 'Image approvals closed');

  Future<bool> request(
    NaiAgentConversationOwner owner,
    Map<String, dynamic> quote,
    DateTime expiresAt,
    NaiAgentCancellation token,
    void Function() check, {
    Uint8List? sourceBytes,
  }) => waitForDecision(
    AgentImageApproval(owner, expiresAt, check, quote, sourceBytes),
    token,
  );

  void decide(String id, {required bool run}) => resolveDecision(id, run);
}

final naiAgentImageApprovalsProvider =
    ChangeNotifierProvider<NaiAgentImageApprovals>(
      (ref) => NaiAgentImageApprovals(),
    );

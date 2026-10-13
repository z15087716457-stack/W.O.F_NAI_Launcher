import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';

class AgentGenerationApproval {
  AgentGenerationApproval({
    required this.id,
    required this.owner,
    required this.quote,
    required this.check,
  });
  final String id;
  final NaiAgentConversationOwner owner;
  final NaiAgentGenerationQuote quote;
  final void Function() check;
  final completion = Completer<bool>();
}

class NaiAgentGenerationApprovals extends ChangeNotifier {
  final _pending = <String, AgentGenerationApproval>{};
  bool _disposed = false;
  List<AgentGenerationApproval> forChat(String chatId) =>
      _pending.values.where((r) => r.owner.chatId == chatId).toList();

  Future<bool> request(
    NaiAgentConversationOwner owner,
    NaiAgentGenerationQuote quote,
    NaiAgentCancellation token,
    void Function() check,
  ) async {
    token.check();
    check();
    if (_disposed) {
      throw const NaiAgentToolError('closed', 'Authorization owner closed');
    }
    final request = AgentGenerationApproval(
      id: const Uuid().v4(),
      owner: owner,
      quote: quote,
      check: check,
    );
    _pending[request.id] = request;
    notifyListeners();
    final remaining = quote.expiresAt.difference(DateTime.now());
    final timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (!request.completion.isCompleted) {
        request.completion.completeError(
          const NaiAgentToolError('quote_expired', 'Generation quote expired'),
        );
      }
    });
    token.whenCancelled.then((_) {
      if (!request.completion.isCompleted) {
        request.completion.completeError(
          const NaiAgentToolError(
            'cancelled',
            'Generation authorization cancelled',
          ),
        );
      }
    });
    try {
      return await request.completion.future;
    } finally {
      timer.cancel();
      _pending.remove(request.id);
      if (!_disposed) notifyListeners();
    }
  }

  void decide(String id, {required bool generate}) {
    final request = _pending[id];
    if (request == null || request.completion.isCompleted) return;
    if (generate) {
      try {
        request.check();
      } catch (error, stack) {
        request.completion.completeError(error, stack);
        return;
      }
    }
    request.completion.complete(generate);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final request in _pending.values) {
      if (!request.completion.isCompleted) {
        request.completion.completeError(
          const NaiAgentToolError('closed', 'Authorization owner closed'),
        );
      }
    }
    _pending.clear();
    super.dispose();
  }
}

final naiAgentGenerationApprovalsProvider =
    ChangeNotifierProvider<NaiAgentGenerationApprovals>(
      (ref) => NaiAgentGenerationApprovals(),
    );

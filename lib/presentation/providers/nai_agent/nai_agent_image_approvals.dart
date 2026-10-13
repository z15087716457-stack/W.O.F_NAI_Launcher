import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';

class AgentImageApproval {
  AgentImageApproval(this.owner, this.quote, this.check, this.sourceBytes);
  final String id = const Uuid().v4();
  final NaiAgentConversationOwner owner;
  final Map<String, dynamic> quote;
  final void Function() check;
  final Uint8List? sourceBytes;
  final completion = Completer<bool>();
}

class NaiAgentImageApprovals extends ChangeNotifier {
  final _pending = <String, AgentImageApproval>{};
  bool _disposed = false;
  List<AgentImageApproval> forChat(String chatId) =>
      _pending.values.where((r) => r.owner.chatId == chatId).toList();

  Future<bool> request(
    NaiAgentConversationOwner owner,
    Map<String, dynamic> quote,
    DateTime expiresAt,
    NaiAgentCancellation token,
    void Function() check, {
    Uint8List? sourceBytes,
  }) async {
    token.check();
    check();
    if (_disposed) {
      throw const NaiAgentToolError('closed', 'Image approvals closed');
    }
    final r = AgentImageApproval(
      owner,
      Map.unmodifiable(quote),
      check,
      sourceBytes,
    );
    _pending[r.id] = r;
    notifyListeners();
    final remaining = expiresAt.difference(DateTime.now());
    final timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      if (!r.completion.isCompleted) {
        r.completion.completeError(
          const NaiAgentToolError('quote_expired', 'Image quote expired'),
        );
      }
    });
    token.whenCancelled.then((_) {
      if (!r.completion.isCompleted) {
        r.completion.completeError(
          const NaiAgentToolError('cancelled', 'Image authorization cancelled'),
        );
      }
    });
    try {
      return await r.completion.future;
    } finally {
      timer.cancel();
      _pending.remove(r.id);
      if (!_disposed) notifyListeners();
    }
  }

  void decide(String id, {required bool run}) {
    final r = _pending[id];
    if (r == null || r.completion.isCompleted) return;
    if (run) {
      try {
        r.check();
      } catch (error, stack) {
        r.completion.completeError(error, stack);
        return;
      }
    }
    r.completion.complete(run);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final r in _pending.values) {
      if (!r.completion.isCompleted) {
        r.completion.completeError(
          const NaiAgentToolError('closed', 'Image approvals closed'),
        );
      }
    }
    _pending.clear();
    super.dispose();
  }
}

final naiAgentImageApprovalsProvider =
    ChangeNotifierProvider<NaiAgentImageApprovals>(
      (ref) => NaiAgentImageApprovals(),
    );

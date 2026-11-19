import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';

abstract class AgentQuoteApproval {
  AgentQuoteApproval(this.owner, this.expiresAt, this.check);
  final String id = const Uuid().v4();
  final NaiAgentConversationOwner owner;
  final DateTime expiresAt;
  final void Function() check;
  final _decision = Completer<bool>();

  void _fail(NaiAgentToolError error) {
    if (!_decision.isCompleted) _decision.completeError(error);
  }
}

abstract class NaiAgentQuoteApprovals<T extends AgentQuoteApproval>
    extends ChangeNotifier {
  NaiAgentQuoteApprovals(this._operation, this._closedMessage);
  final String _operation, _closedMessage;
  final _pending = <String, T>{};
  bool _disposed = false;

  List<T> forChat(String chatId) =>
      _pending.values.where((r) => r.owner.chatId == chatId).toList();

  @protected
  Future<bool> waitForDecision(T request, NaiAgentCancellation token) async {
    token.check();
    request.check();
    if (_disposed) throw NaiAgentToolError('closed', _closedMessage);
    _pending[request.id] = request;
    notifyListeners();
    final timer = Timer(request.expiresAt.difference(DateTime.now()), () {
      request._fail(
        NaiAgentToolError('quote_expired', '$_operation quote expired'),
      );
    });
    token.whenCancelled.then((_) {
      request._fail(
        NaiAgentToolError('cancelled', '$_operation authorization cancelled'),
      );
    });
    try {
      return await request._decision.future;
    } finally {
      timer.cancel();
      _pending.remove(request.id);
      if (!_disposed) notifyListeners();
    }
  }

  @protected
  void resolveDecision(String id, bool approved) {
    final request = _pending[id];
    if (request == null || request._decision.isCompleted) return;
    if (approved) {
      try {
        request.check();
      } catch (error, stack) {
        request._decision.completeError(error, stack);
        return;
      }
    }
    request._decision.complete(approved);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final request in _pending.values) {
      request._fail(NaiAgentToolError('closed', _closedMessage));
    }
    _pending.clear();
    super.dispose();
  }
}

import 'dart:async';

/// Shared by ordinary Studio model requests and every Pi process.
class ModelRequestGate {
  int active = 0;
  final _waiting = <Completer<void>>[];
  Future<void Function()> acquire({
    required int limit,
    required Future<void> cancellation,
    required bool Function() isCancelled,
  }) async {
    void check() {
      if (isCancelled()) throw const ModelRequestCancelled();
    }

    check();
    while (active >= limit.clamp(1, 20)) {
      final waiting = Completer<void>();
      _waiting.add(waiting);
      try {
        await Future.any([waiting.future, cancellation]);
        check();
      } finally {
        _waiting.remove(waiting);
      }
    }
    check();
    active++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      active--;
      for (final waiting in _waiting.toList()) {
        if (!waiting.isCompleted) waiting.complete();
      }
    };
  }
}

class ModelRequestCancelled implements Exception {
  const ModelRequestCancelled();
}

class ModelRequestGates {
  static final shared = ModelRequestGates();
  final _gates = <String, ModelRequestGate>{};
  ModelRequestGate forProvider(String id) =>
      _gates.putIfAbsent(id, ModelRequestGate.new);
}

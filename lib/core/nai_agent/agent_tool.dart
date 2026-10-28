import 'dart:convert';
import 'dart:async';

class NaiAgentToolError implements Exception {
  const NaiAgentToolError(this.code, this.message, [this.details = const {}]);
  final String code, message;
  final Map<String, dynamic> details;
  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    ...details,
  };
  @override
  String toString() => '$code: $message';
}

class NaiAgentCancellation {
  bool _cancelled = false;
  final _completion = Completer<void>();
  bool get isCancelled => _cancelled;
  Future<void> get whenCancelled => _completion.future;
  void cancel() {
    _cancelled = true;
    if (!_completion.isCompleted) _completion.complete();
  }

  void check() {
    if (_cancelled) {
      throw const NaiAgentToolError('cancelled', 'Studio tool cancelled');
    }
  }
}

Map<String, dynamic> naiAgentTextResult(Map<String, dynamic> value) => {
  'content': [
    {'type': 'text', 'text': jsonEncode(value)},
  ],
  'details': value,
};

typedef NaiAgentToolExecutor =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> params,
      NaiAgentCancellation cancellation,
    );

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/provider_adapters/prompt_assistant_adapter.dart';
import '../models/prompt_assistant_models.dart';

final modelRequestHistoryProvider = ChangeNotifierProvider<ModelRequestHistory>(
  (ref) => ModelRequestHistory(),
);

class ModelRequestRecord {
  const ModelRequestRecord({
    required this.id,
    required this.time,
    required this.provider,
    required this.model,
    required this.task,
    required this.protocol,
    required this.parameters,
    this.status = '等待中',
    this.elapsedMs = 0,
    this.attempts = 0,
    this.error,
  });
  final String id, provider, model, task, protocol, status;
  final DateTime time;
  final Map<String, Object?> parameters;
  final int elapsedMs, attempts;
  final String? error;
  ModelRequestRecord finished(
    String status,
    int elapsedMs,
    int attempts,
    String? error,
  ) => ModelRequestRecord(
    id: id,
    time: time,
    provider: provider,
    model: model,
    task: task,
    protocol: protocol,
    parameters: parameters,
    status: status,
    elapsedMs: elapsedMs,
    attempts: attempts,
    error: error,
  );
}

/// Bounded session diagnostics. No keys, headers, prompts or response bodies
/// are retained, and this history is not written to disk.
class ModelRequestHistory extends ChangeNotifier {
  final _records = <ModelRequestRecord>[];
  List<ModelRequestRecord> get records => List.unmodifiable(_records);
  String begin(PromptAssistantRequest request) {
    final id = '${request.sessionId}-${DateTime.now().microsecondsSinceEpoch}';
    final parameters = {...?request.modelConfig?.toJson()}
      ..remove('providerId')
      ..remove('name')
      ..remove('displayName')
      ..remove('source')
      ..remove('isDefault');
    if (request.provider.protocol == ProviderProtocol.anthropicMessages) {
      parameters.putIfAbsent('maxOutputTokens', () => 2048);
    }
    _records.insert(
      0,
      ModelRequestRecord(
        id: id,
        time: DateTime.now(),
        provider: request.provider.name,
        model: request.model,
        task: request.taskName,
        protocol: request.provider.protocol.label,
        parameters: {
          ...parameters,
          'timeoutSeconds': request.provider.timeoutSeconds,
          'concurrency': request.provider.maxConcurrentRequests,
          'retryAttempts': request.provider.retryAttempts,
        },
      ),
    );
    if (_records.length > 100) _records.removeLast();
    notifyListeners();
    return id;
  }

  void update(
    String id,
    String status, {
    int elapsedMs = 0,
    int attempts = 0,
    String? error,
  }) {
    final index = _records.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _records[index] = _records[index].finished(
      status,
      elapsedMs,
      attempts,
      error,
    );
    notifyListeners();
  }

  void clear() {
    _records.clear();
    notifyListeners();
  }
}

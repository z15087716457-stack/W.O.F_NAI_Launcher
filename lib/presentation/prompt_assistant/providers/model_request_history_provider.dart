import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/provider_adapters/prompt_assistant_adapter.dart';
import '../models/prompt_assistant_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/localization_extension.dart';

enum ModelRequestStatus { pending, running, success, failed, cancelled }

extension ModelRequestStatusLabel on ModelRequestStatus {
  String labelIn(AppLocalizations l10n) => switch (this) {
    ModelRequestStatus.pending => l10n.modelRequest_statusPending,
    ModelRequestStatus.running => l10n.modelRequest_statusRunning,
    ModelRequestStatus.success => l10n.modelRequest_statusSuccess,
    ModelRequestStatus.failed => l10n.modelRequest_statusFailed,
    ModelRequestStatus.cancelled => l10n.modelRequest_statusCancelled,
  };
}

final modelRequestHistoryProvider = ChangeNotifierProvider<ModelRequestHistory>(
  (ref) => ModelRequestHistory(),
);

class ModelRequestExchange {
  const ModelRequestExchange({
    required this.time,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    this.responseHeaders = const {},
    this.responseBody,
    this.statusCode,
    this.error,
  });
  final DateTime time;
  final String method, url;
  final Map<String, Object?> requestHeaders, responseHeaders;
  final Object? requestBody, responseBody;
  final int? statusCode;
  final String? error;
  ModelRequestExchange responded({
    required Map<String, Object?> headers,
    Object? body,
    int? statusCode,
    String? error,
  }) => ModelRequestExchange(
    time: time,
    method: method,
    url: url,
    requestHeaders: requestHeaders,
    requestBody: requestBody,
    responseHeaders: headers,
    responseBody: body,
    statusCode: statusCode,
    error: error,
  );
  Map<String, Object?> get request => requestIn(currentL10n);
  Map<String, Object?> requestIn(AppLocalizations l10n) => {
    l10n.modelRequest_fieldTime: time.toIso8601String(),
    l10n.modelRequest_fieldMethod: method,
    l10n.modelRequest_fieldUrl: url,
    l10n.modelRequest_fieldRequestHeaders: requestHeaders,
    l10n.modelRequest_fieldBody: requestBody,
  };
  Map<String, Object?> get response => responseIn(currentL10n);
  Map<String, Object?> responseIn(AppLocalizations l10n) => {
    l10n.modelRequest_fieldStatusCode: statusCode,
    l10n.modelRequest_fieldResponseHeaders: responseHeaders,
    l10n.modelRequest_fieldBody: responseBody,
    if (error != null) l10n.modelRequest_fieldError: error,
  };
}

class ModelRequestRecord {
  const ModelRequestRecord({
    required this.id,
    required this.time,
    required this.provider,
    required this.model,
    required this.task,
    required this.protocol,
    required this.parameters,
    this.status = ModelRequestStatus.pending,
    this.elapsedMs = 0,
    this.attempts = 0,
    this.error,
    this.output,
    this.exchanges = const [],
  });
  final String id, provider, model, task, protocol;
  final ModelRequestStatus status;
  final DateTime time;
  final Map<String, Object?> parameters;
  final int elapsedMs, attempts;
  final String? error, output;
  final List<ModelRequestExchange> exchanges;
  ModelRequestRecord updated({
    ModelRequestStatus? status,
    int? elapsedMs,
    int? attempts,
    String? error,
    String? output,
    List<ModelRequestExchange>? exchanges,
  }) => ModelRequestRecord(
    id: id,
    time: time,
    provider: provider,
    model: model,
    task: task,
    protocol: protocol,
    parameters: parameters,
    status: status ?? this.status,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    attempts: attempts ?? this.attempts,
    error: error ?? this.error,
    output: output ?? this.output,
    exchanges: exchanges == null
        ? this.exchanges
        : List.unmodifiable(exchanges),
  );
  Map<String, Object?> get overview => overviewIn(currentL10n);
  Map<String, Object?> overviewIn(AppLocalizations l10n) => {
    l10n.modelRequest_fieldInterface: task,
    l10n.modelRequest_fieldProvider: provider,
    l10n.modelRequest_fieldModel: model,
    l10n.modelRequest_fieldProtocol: protocol,
    l10n.modelRequest_fieldTime: time.toIso8601String(),
    l10n.modelRequest_fieldStatus: status.labelIn(l10n),
    l10n.modelRequest_fieldElapsed: elapsedMs,
    l10n.modelRequest_fieldAttempts: attempts,
    l10n.modelRequest_fieldHttpRequests: exchanges.length,
    if (error != null) l10n.modelRequest_fieldError: error,
    l10n.modelRequest_fieldParameters: parameters,
  };
}

/// Complete, redacted diagnostics for the most recent 100 session requests.
/// Bodies stay in memory only and are excluded from configuration exports.
class ModelRequestHistory extends ChangeNotifier {
  final _records = <ModelRequestRecord>[];
  int _sequence = 0;
  bool _disposed = false;
  List<ModelRequestRecord> get records => List.unmodifiable(_records);
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  String begin(PromptAssistantRequest request) {
    final id =
        '${request.sessionId}-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    final parameters = request.modelConfig == null
        ? <String, Object?>{}
        : RequestParameters.fromModel(request.modelConfig!).toJson();
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
        task: request.taskName ?? currentL10n.modelTask_connectionTest,
        protocol: request.provider.protocol.label,
        parameters: Map.unmodifiable({
          ...parameters,
          'timeoutSeconds': request.provider.timeoutSeconds,
          'concurrency': request.provider.maxConcurrentRequests,
          'retryAttempts': request.provider.retryAttempts,
        }),
      ),
    );
    if (_records.length > 100) _records.removeLast();
    _changed();
    return id;
  }

  int sent(String id, ModelRequestExchange exchange) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0) return -1;
    final exchanges = [..._records[index].exchanges, exchange];
    _records[index] = _records[index].updated(exchanges: exchanges);
    _changed();
    return exchanges.length - 1;
  }

  void received(
    String id,
    int exchangeIndex, {
    required Map<String, Object?> headers,
    Object? body,
    int? statusCode,
    String? error,
  }) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0 ||
        exchangeIndex < 0 ||
        exchangeIndex >= _records[index].exchanges.length) {
      return;
    }
    final exchanges = [..._records[index].exchanges];
    exchanges[exchangeIndex] = exchanges[exchangeIndex].responded(
      headers: headers,
      body: body,
      statusCode: statusCode,
      error: error,
    );
    _records[index] = _records[index].updated(exchanges: exchanges);
    _changed();
  }

  void update(
    String id,
    ModelRequestStatus status, {
    int elapsedMs = 0,
    int attempts = 0,
    String? error,
    String? output,
  }) {
    final index = _records.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _records[index] = _records[index].updated(
      status: status,
      elapsedMs: elapsedMs,
      attempts: attempts,
      error: error,
      output: output,
    );
    _changed();
  }

  void clear() {
    _records.clear();
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Scrub authentication fields and known credential values before retention.
class ModelDiagnosticRedactor {
  ModelDiagnosticRedactor(Iterable<String> secrets)
    : _secrets = secrets.where((s) => s.isNotEmpty).toSet().toList()
        ..sort((a, b) => b.length.compareTo(a.length));
  final List<String> _secrets;
  static Iterable<String> sensitiveValues(
    Object? value, [
    bool inherited = false,
  ]) sync* {
    if (value is Map) {
      for (final entry in value.entries) {
        yield* sensitiveValues(
          entry.value,
          inherited || sensitive('${entry.key}'),
        );
      }
    } else if (value is List) {
      for (final item in value) {
        yield* sensitiveValues(item, inherited);
      }
    } else if (inherited && value is String && value.isNotEmpty) {
      yield value;
    }
  }

  static bool sensitive(String name) {
    final key = name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return const [
          'authorization',
          'proxyauthorization',
          'apikey',
          'xapikey',
          'xgoogapikey',
          'cookie',
          'setcookie',
          'password',
          'secret',
          'token',
          'accesstoken',
          'refreshtoken',
          'credentials',
        ].contains(key) ||
        key.endsWith('apikey') ||
        key.endsWith('secret') ||
        key.endsWith('password');
  }

  String text(String value) {
    var result = value;
    for (final secret in _secrets) {
      result = result
          .replaceAll(secret, currentL10n.modelRequest_redacted)
          .replaceAll(
            Uri.encodeComponent(secret),
            currentL10n.modelRequest_redacted,
          );
    }
    return result;
  }

  Object? value(Object? data) {
    if (data is Map) {
      return Map<String, Object?>.unmodifiable({
        for (final entry in data.entries)
          '${entry.key}': sensitive('${entry.key}')
              ? currentL10n.modelRequest_redacted
              : value(entry.value),
      });
    }
    if (data is List) return List<Object?>.unmodifiable(data.map(value));
    if (data is String) return text(data);
    if (data == null || data is num || data is bool) return data;
    return text(data.toString());
  }

  Map<String, Object?> headers(Map<String, dynamic> values) =>
      value(values)! as Map<String, Object?>;
  String url(Uri uri) {
    final safe = uri.replace(
      userInfo: uri.userInfo.isEmpty
          ? ''
          : Uri.encodeComponent(currentL10n.modelRequest_redacted),
      queryParameters: uri.hasQuery
          ? {
              for (final entry in uri.queryParametersAll.entries)
                entry.key:
                    sensitive(entry.key) || entry.key.toLowerCase() == 'key'
                    ? ['[已脱敏]']
                    : entry.value.map(text).toList(),
            }
          : null,
    );
    return text(safe.toString());
  }
}

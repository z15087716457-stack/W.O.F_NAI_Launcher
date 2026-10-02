import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/provider_adapters/prompt_assistant_adapter.dart';
import '../models/prompt_assistant_models.dart';

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
  Map<String, Object?> get request => {
    '时间': time.toIso8601String(),
    '方法': method,
    '地址': url,
    '请求头': requestHeaders,
    '正文': requestBody,
  };
  Map<String, Object?> get response => {
    '状态码': statusCode,
    '响应头': responseHeaders,
    '正文': responseBody,
    if (error != null) '错误': error,
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
    this.status = '等待中',
    this.elapsedMs = 0,
    this.attempts = 0,
    this.error,
    this.output,
    this.exchanges = const [],
  });
  final String id, provider, model, task, protocol, status;
  final DateTime time;
  final Map<String, Object?> parameters;
  final int elapsedMs, attempts;
  final String? error, output;
  final List<ModelRequestExchange> exchanges;
  ModelRequestRecord updated({
    String? status,
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
  Map<String, Object?> get overview => {
    '接口': task,
    '服务商': provider,
    '模型': model,
    '协议': protocol,
    '时间': time.toIso8601String(),
    '状态': status,
    '耗时（毫秒）': elapsedMs,
    '执行次数': attempts,
    'HTTP 请求数': exchanges.length,
    if (error != null) '错误': error,
    '生效参数': parameters,
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
        task: request.taskName,
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
    String status, {
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
          .replaceAll(secret, '[已脱敏]')
          .replaceAll(Uri.encodeComponent(secret), '[已脱敏]');
    }
    return result;
  }

  Object? value(Object? data) {
    if (data is Map) {
      return Map<String, Object?>.unmodifiable({
        for (final entry in data.entries)
          '${entry.key}': sensitive('${entry.key}')
              ? '[已脱敏]'
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
      userInfo: uri.userInfo.isEmpty ? '' : Uri.encodeComponent('[已脱敏]'),
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

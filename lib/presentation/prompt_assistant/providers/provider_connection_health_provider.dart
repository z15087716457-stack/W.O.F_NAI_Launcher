import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/prompt_assistant_models.dart';

final providerConnectionHealthProvider =
    ChangeNotifierProvider<ProviderConnectionHealth>((ref) {
      final health = ProviderConnectionHealth(
        storage: ref.watch(localStorageServiceProvider),
      );
      return health;
    });

enum ProviderConnectionStatus { unverified, healthy, limited, failed }

enum ProviderConnectionIssue {
  authentication,
  permission,
  timeout,
  network,
  httpError,
  invalidResponse,
}

class ProviderConnectionResult {
  const ProviderConnectionResult({
    this.status = ProviderConnectionStatus.unverified,
    this.checkedAt,
    this.statusCode,
    this.issue,
  });

  final ProviderConnectionStatus status;
  final DateTime? checkedAt;
  final int? statusCode;
  final ProviderConnectionIssue? issue;

  String get description => switch (status) {
    ProviderConnectionStatus.unverified => '尚未验证连接；使用模型或点击“测试连接”后更新',
    ProviderConnectionStatus.healthy => '最近一次请求成功',
    ProviderConnectionStatus.limited => '接口可达，但最近请求被限流（HTTP 429）；请稍后重试或检查额度',
    ProviderConnectionStatus.failed => switch (issue) {
      ProviderConnectionIssue.authentication => '认证失败；请检查 API 密钥',
      ProviderConnectionIssue.permission => '访问被拒绝；请检查服务权限',
      ProviderConnectionIssue.timeout => '最近一次请求超时',
      ProviderConnectionIssue.network => '最近一次请求无法连接服务',
      ProviderConnectionIssue.invalidResponse => '最近一次响应异常；可在请求记录中查看详情',
      _ => '最近一次请求失败${statusCode == null ? '' : '（HTTP $statusCode）'}',
    },
  };
}

class ProviderConnectionProbe {
  const ProviderConnectionProbe._(
    this.id,
    this.signature,
    this.revision,
    this.sequence,
  );
  final String id, signature;
  final int revision, sequence;
}

/// Retains only connection outcomes, never request content or credentials.
class ProviderConnectionHealth extends ChangeNotifier {
  ProviderConnectionHealth({
    required LocalStorageService storage,
    List<ProviderConfig>? providers,
  }) : _storage = storage {
    try {
      final raw = storage.getSetting<String>(
        StorageKeys.providerConnectionHealthV1,
      );
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is Map &&
          decoded['version'] == 1 &&
          decoded['providers'] is Map) {
        for (final entry in (decoded['providers'] as Map).entries.take(200)) {
          final value = entry.value;
          if (entry.key is! String ||
              value is! Map ||
              value['signature'] is! String) {
            continue;
          }
          final status = ProviderConnectionStatus.values
              .where((s) => s.name == value['status'])
              .firstOrNull;
          final time = value['checkedAt'] is String
              ? DateTime.tryParse(value['checkedAt'])
              : null;
          if (status == null ||
              status == ProviderConnectionStatus.unverified ||
              time == null) {
            continue;
          }
          final code = value['statusCode'];
          _results[entry.key as String] = (
            signature: value['signature'] as String,
            result: ProviderConnectionResult(
              status: status,
              checkedAt: time,
              statusCode: code is int && code >= 100 && code <= 599
                  ? code
                  : null,
              issue: ProviderConnectionIssue.values
                  .where((i) => i.name == value['issue'])
                  .firstOrNull,
            ),
          );
        }
      }
    } catch (_) {
      // A corrupt or older cache does not affect service configuration.
    }
    if (providers != null) updateProviders(providers);
  }

  final LocalStorageService _storage;
  final _results =
      <String, ({String signature, ProviderConnectionResult result})>{};
  final _providers = <String, ProviderConfig>{};
  final _revisions = <String, int>{};
  final _finished = <String, int>{};
  Future<void> _pendingWrite = Future.value();
  int _sequence = 0;
  bool _disposed = false;

  Future<void> get whenPersisted => _pendingWrite;

  static String connectionSignature(ProviderConfig provider) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            provider.baseUrl.trim().replaceAll(RegExp(r'/+$'), ''),
            provider.protocol.name,
          ]),
        ),
      )
      .toString();

  ProviderConnectionResult resultFor(String providerId) =>
      _results[providerId]?.result ?? const ProviderConnectionResult();

  void updateProviders(List<ProviderConfig> providers) {
    final next = {for (final provider in providers) provider.id: provider};
    for (final previous in _providers.values) {
      final current = next[previous.id];
      if (current == null ||
          connectionSignature(current) != connectionSignature(previous)) {
        _revisions.update(previous.id, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    _providers
      ..clear()
      ..addAll(next);
    final size = _results.length;
    _results.removeWhere((id, value) {
      final provider = next[id];
      return provider == null ||
          value.signature != connectionSignature(provider);
    });
    if (_results.length != size) _changed();
  }

  void invalidate(String providerId) {
    _revisions.update(providerId, (n) => n + 1, ifAbsent: () => 1);
    if (_results.remove(providerId) != null) _changed();
  }

  ProviderConnectionProbe? begin(ProviderConfig provider) {
    if (_disposed) return null;
    final current = _providers[provider.id];
    final signature = connectionSignature(provider);
    if (current == null || connectionSignature(current) != signature) {
      return null;
    }
    return ProviderConnectionProbe._(
      provider.id,
      signature,
      _revisions[provider.id] ?? 0,
      ++_sequence,
    );
  }

  void succeeded(ProviderConnectionProbe? probe) => _record(
    probe,
    ProviderConnectionResult(
      status: ProviderConnectionStatus.healthy,
      checkedAt: DateTime.now(),
    ),
  );

  void failed(ProviderConnectionProbe? probe, Object error) {
    if (error is DioException && error.type == DioExceptionType.cancel) return;
    final code = error is DioException ? error.response?.statusCode : null;
    final type = error is DioException ? error.type : null;
    _record(
      probe,
      ProviderConnectionResult(
        status: code == 429
            ? ProviderConnectionStatus.limited
            : ProviderConnectionStatus.failed,
        checkedAt: DateTime.now(),
        statusCode: code,
        issue: code == 401
            ? ProviderConnectionIssue.authentication
            : code == 403
            ? ProviderConnectionIssue.permission
            : const [
                DioExceptionType.connectionTimeout,
                DioExceptionType.sendTimeout,
                DioExceptionType.receiveTimeout,
              ].contains(type)
            ? ProviderConnectionIssue.timeout
            : const [
                DioExceptionType.connectionError,
                DioExceptionType.badCertificate,
              ].contains(type)
            ? ProviderConnectionIssue.network
            : code != null
            ? ProviderConnectionIssue.httpError
            : ProviderConnectionIssue.invalidResponse,
      ),
    );
  }

  void _record(
    ProviderConnectionProbe? probe,
    ProviderConnectionResult result,
  ) {
    if (probe == null || _disposed) return;
    final current = _providers[probe.id];
    if (current == null ||
        connectionSignature(current) != probe.signature ||
        (_revisions[probe.id] ?? 0) != probe.revision ||
        (_finished[probe.id] ?? 0) > probe.sequence) {
      return;
    }
    _finished[probe.id] = probe.sequence;
    _results[probe.id] = (signature: probe.signature, result: result);
    _changed();
  }

  void _changed() {
    if (_disposed) return;
    notifyListeners();
    _pendingWrite = _pendingWrite
        .then(
          (_) => _storage.setSetting(
            StorageKeys.providerConnectionHealthV1,
            jsonEncode({
              'version': 1,
              'providers': {
                for (final entry in _results.entries)
                  entry.key: {
                    'signature': entry.value.signature,
                    'status': entry.value.result.status.name,
                    'checkedAt': entry.value.result.checkedAt!
                        .toIso8601String(),
                    if (entry.value.result.statusCode != null)
                      'statusCode': entry.value.result.statusCode,
                    if (entry.value.result.issue != null)
                      'issue': entry.value.result.issue!.name,
                  },
              },
            }),
          ),
        )
        .catchError((Object _) {
          AppLogger.w(
            'Connection status cache could not be saved.',
            'PromptAssistant',
          );
        });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/node_runtime_environment.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'nai_agent_workspace_provider.dart';

const chatGptAgentProviderId = 'openai-chatgpt';
const chatGptAgentProviderName = 'ChatGPT';
const chatGptAgentUsageUrl = 'https://chatgpt.com/settings/usage';

class ChatGptAgentModel {
  ChatGptAgentModel.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      vision = json['vision'] as bool,
      contextWindow = json['contextWindow'] as int,
      maxTokens = json['maxTokens'] as int,
      efforts = List.unmodifiable((json['efforts'] as List).cast<String>());

  final String id, name;
  final bool vision;
  final int contextWindow, maxTokens;
  final List<String> efforts;
}

final naiAgentChatGptProvider = ChangeNotifierProvider<NaiAgentChatGpt>((ref) {
  return NaiAgentChatGpt(
    ref.read(secureStorageServiceProvider),
    ref.read(naiAgentRuntimePathsProvider),
  );
});

/// One account for all Agent sessions. Only this owner can renew its credential.
class NaiAgentChatGpt extends ChangeNotifier {
  NaiAgentChatGpt(this._storage, this._paths) {
    ready = _update(() async {
      final stored = await _storage.read(_credentialKey);
      if (stored == null || _disposed) return;
      _credential = jsonDecode(stored) as Map<String, dynamic>;
      await _loadModels();
    });
  }

  static const _credentialKey = 'nai_agent_chatgpt_credential';
  static const _deviceKey = 'nai_agent_chatgpt_device';
  static const _planNoticeKey = 'nai_agent_chatgpt_plan_notice';

  final SecureStorageService _storage;
  final NaiAgentRuntimePaths _paths;
  late final Future<void> ready;
  Map<String, dynamic>? _credential;
  Future<Map<String, dynamic>>? _renewing;
  NaiAgentCancellation? _login;
  bool _disposed = false, _disconnecting = false, _working = false;
  bool _failed = false;
  List<ChatGptAgentModel> _models = const [];

  bool get connected => _credential != null;
  bool get busy => _working;
  bool get signingIn => _login != null;
  bool get failed => _failed;
  List<ChatGptAgentModel> get models => _models;

  Future<void> signIn() => _update(() async {
    final cancel = _login = NaiAgentCancellation();
    _notify();
    try {
      var device = await _storage.read(_deviceKey);
      if (device == null) {
        device = const Uuid().v4();
        await _storage.write(_deviceKey, device);
      }
      final credential = await _run('login', {
        'deviceId': device,
      }, cancel: cancel);
      cancel.check();
      _login = null;
      await _save(credential);
      await _loadModels();
    } finally {
      _login = null;
    }
  });

  void cancelSignIn() => _login?.cancel();

  Future<bool> claimPlanNotice() async {
    if (await _storage.read(_planNoticeKey) != null) return false;
    await _storage.write(_planNoticeKey, '1');
    return true;
  }

  Future<void> refreshModels() => _update(_loadModels);

  Future<void> signOut() => _update(() async {
    _disconnecting = true;
    try {
      await _renewing?.then<void>((_) {}, onError: (Object _) {});
      await _storage.delete(_credentialKey);
      _credential = null;
      _models = const [];
    } finally {
      _disconnecting = false;
    }
  });

  Future<String> accessToken() async {
    await ready;
    return _accessToken();
  }

  Future<String> _accessToken() async {
    final credential = _credential;
    if (credential == null || _disconnecting || _disposed) {
      throw StateError('ChatGPT connection unavailable');
    }
    if ((credential['expires'] as num) >
        DateTime.now().millisecondsSinceEpoch) {
      return credential['access'] as String;
    }
    final updated = await (_renewing ??= _renew(credential).whenComplete(() {
      _renewing = null;
    }));
    if (_disconnecting || _disposed) {
      throw StateError('ChatGPT connection unavailable');
    }
    return updated['access'] as String;
  }

  Future<Map<String, dynamic>> _renew(Map<String, dynamic> credential) async {
    final renewed = await _run('refresh', {'credential': credential});
    await _save(renewed);
    return renewed;
  }

  Future<void> _save(Map<String, dynamic> credential) async {
    await _storage.write(_credentialKey, jsonEncode(credential));
    _credential = credential;
  }

  Future<void> _loadModels() async {
    final result = await _run('models', {'accessToken': await _accessToken()});
    _models = List.unmodifiable([
      for (final model in result['models'] as List)
        ChatGptAgentModel.fromJson(model as Map<String, dynamic>),
    ]);
  }

  Future<void> _update(Future<void> Function() action) async {
    if (_working) return;
    _working = true;
    _failed = false;
    _notify();
    try {
      await action();
    } on NaiAgentToolError catch (error) {
      _failed = error.code != 'cancelled';
    } catch (_) {
      _failed = true;
    } finally {
      _working = false;
      _notify();
    }
  }

  Future<Map<String, dynamic>> _run(
    String action,
    Map<String, dynamic> data, {
    NaiAgentCancellation? cancel,
  }) async {
    cancel?.check();
    final script = p.join(p.dirname(_paths.host), 'manage-resources.mjs');
    final process = await Process.start(
      _paths.node,
      [script],
      workingDirectory: p.dirname(script),
      environment: {
        ...?nodeRuntimeEnvironment(_paths.node),
        'PI_OAUTH_CALLBACK_HOST': '127.0.0.1',
      },
    );
    unawaited(process.stderr.drain<void>());
    if (cancel != null) {
      unawaited(cancel.whenCancelled.then((_) => process.kill()));
    }
    try {
      cancel?.check();
      process.stdin.writeln(
        jsonEncode({'resource': 'chatgpt', 'action': action, ...data}),
      );
      await process.stdin.close();
      return await _readResult(
        process,
      ).timeout(Duration(seconds: action == 'login' ? 300 : 20));
    } finally {
      process.kill();
      cancel?.check();
    }
  }

  Future<Map<String, dynamic>> _readResult(Process process) async {
    final lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      final message = jsonDecode(line) as Map<String, dynamic>;
      if (message['result'] case final Map<String, dynamic> result) {
        return result;
      }
      if (message['url'] case final String url) {
        final uri = Uri.parse(url);
        if (uri.origin != 'https://auth.openai.com' ||
            !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw StateError('Unable to open ChatGPT sign-in');
        }
      } else {
        break;
      }
    }
    throw StateError('ChatGPT connection failed');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelSignIn();
    super.dispose();
  }
}

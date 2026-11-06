import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jose/jose.dart';
import 'package:synchronized/synchronized.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../storage/secure_storage_service.dart';
import '../utils/localization_extension.dart';

/// Only this service owns renewable credentials. Public settings contain no tokens.
final chatGptAuthServiceProvider = Provider<ChatGptAuthService>((ref) {
  final storage = ref.read(secureStorageServiceProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return ChatGptAuthService(
    dio: dio,
    read: storage.readChatGptConnection,
    write: storage.saveChatGptConnection,
    openBrowser: (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
  );
});

class ChatGptAccount {
  const ChatGptAccount({
    required this.clientId,
    this.email,
    required this.signedIn,
    required this.planEnabled,
  });
  final String clientId;
  final String? email;
  final bool signedIn, planEnabled;
}

class ChatGptAuthException implements Exception {
  const ChatGptAuthException(this.code);
  final String code;
  @override
  String toString() => currentL10n.chatGpt_authFailed(code);
}

class ChatGptAuthService {
  ChatGptAuthService({
    required this.dio,
    required this.read,
    required this.write,
    required this.openBrowser,
  });
  final Dio dio;
  final Future<String?> Function(String) read;
  final Future<void> Function(String, String) write;
  final Future<bool> Function(Uri) openBrowser;
  static const issuer = 'https://auth.openai.com';
  static const resource = 'https://api.openai.com/v1';
  static const planScope = 'chatgpt.tokens.use.direct';
  final _locks = <String, Lock>{};
  final _hostLock = Lock();
  Lock _lock(String id) => _locks.putIfAbsent(id, Lock.new);

  Future<Map<String, dynamic>> _record(String id) async {
    final value = await read('connection:$id');
    return value == null ? {} : jsonDecode(value) as Map<String, dynamic>;
  }

  Future<ChatGptAccount?> account(String id) async {
    final record = await _record(id);
    if (record['client_id'] == null) return null;
    return ChatGptAccount(
      clientId: record['client_id'] as String,
      email: record['email'] as String?,
      signedIn: record['access_token'] != null,
      planEnabled: (record['scopes'] as List?)?.contains(planScope) ?? false,
    );
  }

  Future<String> _hostId() => _hostLock.synchronized(() async {
    final saved = await read('host');
    if (saved != null) return saved;
    final id = 'urn:uuid:${const Uuid().v4()}';
    await write('host', id);
    return id;
  });

  static String _random() {
    final random = Random.secure();
    return base64UrlEncode(
      List.generate(32, (_) => random.nextInt(256)),
    ).replaceAll('=', '');
  }

  Future<Map<String, dynamic>> _json(
    String url, {
    Map<String, String>? form,
    CancelToken? cancellation,
  }) async {
    // OAuth errors can contain credentials. Never expose raw Dio exceptions.
    try {
      final response = form == null
          ? await dio.get<dynamic>(url, cancelToken: cancellation)
          : await dio.post<dynamic>(
              url,
              data: form,
              cancelToken: cancellation,
              options: Options(contentType: Headers.formUrlEncodedContentType),
            );
      if (response.data is! Map<String, dynamic>) {
        throw const ChatGptAuthException('invalid_response');
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      throw ChatGptAuthException(
        error.type == DioExceptionType.cancel
            ? 'cancelled'
            : 'request_failed_${error.response?.statusCode ?? 0}',
      );
    }
  }

  Future<void> signIn(
    String id,
    CancelToken cancellation,
  ) => _lock(id).synchronized(() async {
    final previous = await _record(id);
    final host = await _hostId();
    final state = _random(), nonce = _random(), verifier = _random();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirect = 'http://127.0.0.1:${server.port}/auth/callback';
    final callback = Completer<Map<String, String>>();
    final listener = server.listen((request) async {
      final params = request.uri.queryParameters;
      if (request.method != 'GET' ||
          request.uri.path != '/auth/callback' ||
          params['state'] != state ||
          callback.isCompleted) {
        request.response.statusCode = HttpStatus.badRequest;
      } else {
        request.response.headers.contentType = ContentType.text;
        request.response.headers.set('Cache-Control', 'no-store');
        request.response.write(currentL10n.chatGpt_returnToStudio);
        callback.complete(params);
      }
      await request.response.close();
    });
    try {
      final uri = Uri.parse('$issuer/api/accounts/authorize').replace(
        queryParameters: {
          'client_id':
              previous['client_id'] as String? ?? 'dynamic_agent_client',
          if (previous['client_id'] == null)
            'agent_name_hint': 'W.O.F NAI Studio',
          'ext_agent_host_id': host,
          if (previous['id_token'] case final String hint)
            'id_token_hint': hint,
          'response_type': 'code',
          'redirect_uri': redirect,
          'scope':
              'openid profile email offline_access resource.invoke $planScope',
          'resource': resource,
          'state': state,
          'nonce': nonce,
          'code_challenge_method': 'S256',
          'code_challenge': base64UrlEncode(
            sha256.convert(utf8.encode(verifier)).bytes,
          ).replaceAll('=', ''),
        },
      );
      if (cancellation.isCancelled) {
        throw const ChatGptAuthException('cancelled');
      }
      if (!await openBrowser(uri)) {
        throw const ChatGptAuthException('browser_unavailable');
      }
      final params =
          await Future.any([
            callback.future,
            cancellation.whenCancel.then<Map<String, String>>(
              (_) => throw const ChatGptAuthException('cancelled'),
            ),
          ]).timeout(
            const Duration(minutes: 5),
            onTimeout: () =>
                throw const ChatGptAuthException('sign_in_timeout'),
          );
      if (params.containsKey('error')) {
        throw const ChatGptAuthException('authorization_denied');
      }
      final client = callbackClientId(params, previous['client_id'] as String?);
      // Retain registration even if the one-time code exchange fails.
      final registration = {...previous, 'client_id': client};
      await write('connection:$id', jsonEncode(registration));
      final tokens = await _json(
        '$issuer/api/accounts/oauth/token',
        form: {
          'grant_type': 'authorization_code',
          'client_id': client,
          'code': params['code']!,
          'code_verifier': verifier,
          'redirect_uri': redirect,
          'resource': resource,
        },
        cancellation: cancellation,
      );
      final idToken = tokens['id_token'];
      if (idToken is! String) {
        throw const ChatGptAuthException('missing_id_token');
      }
      final discovery = await _json(
        '$issuer/.well-known/openid-configuration',
        cancellation: cancellation,
      );
      final jwks = await _json(
        _trustedAuthEndpoint(discovery['jwks_uri']),
        cancellation: cancellation,
      );
      final claims = await verifyIdToken(
        idToken,
        jwks,
        clientId: client,
        nonce: nonce,
      );
      if (previous['subject'] != null && previous['subject'] != claims['sub']) {
        throw const ChatGptAuthException('account_mismatch');
      }
      final record = tokenRecord(tokens, {
        ...registration,
        'issuer': issuer,
        'subject': claims['sub'],
        'email': claims['email'],
        'id_token': idToken,
      });
      if (cancellation.isCancelled) {
        throw const ChatGptAuthException('cancelled');
      }
      await write('connection:$id', jsonEncode(record));
    } finally {
      await listener.cancel();
      await server.close(force: true);
    }
  });

  static String callbackClientId(Map<String, String> params, String? previous) {
    final client = params['client_id'] ?? previous;
    if (client == null ||
        client.isEmpty ||
        client == 'dynamic_agent_client' ||
        (previous != null && client != previous) ||
        (params['code'] ?? '').isEmpty) {
      throw const ChatGptAuthException('invalid_registration');
    }
    return client;
  }

  static String _trustedAuthEndpoint(dynamic value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null || uri.origin != issuer || uri.userInfo.isNotEmpty) {
      throw const ChatGptAuthException('invalid_discovery');
    }
    return uri.toString();
  }

  static Future<Map<String, dynamic>> verifyIdToken(
    String token,
    Map<String, dynamic> jwks, {
    required String clientId,
    required String nonce,
  }) async {
    final jws = JsonWebSignature.fromCompactSerialization(token);
    final header = jws.unverifiedPayload.protectedHeader?.toJson();
    if (header == null) {
      throw const ChatGptAuthException('invalid_signature');
    }
    if (header['alg'] != 'RS256') {
      throw const ChatGptAuthException('invalid_signature');
    }
    final keys = JsonWebKeyStore();
    for (final raw in jwks['keys'] as List) {
      final key = raw as Map<String, dynamic>;
      if (key['kty'] == 'RSA' &&
          key['kid'] == header['kid'] &&
          (key['use'] == null || key['use'] == 'sig')) {
        keys.addKey(JsonWebKey.fromJson(key));
      }
    }
    if (!await jws.verify(keys)) {
      throw const ChatGptAuthException('invalid_signature');
    }
    final claims =
        jsonDecode(jws.unverifiedPayload.stringContent) as Map<String, dynamic>;
    final aud = claims['aud'];
    final audiences = aud is List ? aud : [aud];
    final expiry = claims['exp'];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (claims['iss'] != issuer ||
        !audiences.contains(clientId) ||
        (audiences.length > 1 && claims['azp'] != clientId) ||
        (claims['azp'] != null && claims['azp'] != clientId) ||
        expiry is! num ||
        expiry <= now ||
        claims['nonce'] != nonce ||
        claims['sub'] is! String ||
        (claims['sub'] as String).isEmpty ||
        (claims['nbf'] is num && (claims['nbf'] as num) > now)) {
      throw const ChatGptAuthException('invalid_identity');
    }
    return claims;
  }

  static Map<String, dynamic> tokenRecord(
    Map<String, dynamic> tokens,
    Map<String, dynamic> previous,
  ) {
    if (tokens['access_token'] is! String ||
        (tokens['access_token'] as String).isEmpty ||
        tokens['token_type'] is! String ||
        (tokens['token_type'] as String).toLowerCase() != 'bearer' ||
        tokens['expires_in'] is! num ||
        (tokens['expires_in'] as num) <= 0 ||
        (tokens['refresh_token'] != null &&
            tokens['refresh_token'] is! String) ||
        (tokens['scope'] != null && tokens['scope'] is! String)) {
      throw const ChatGptAuthException('invalid_tokens');
    }
    return {
      ...previous,
      'access_token': tokens['access_token'],
      'refresh_token': tokens['refresh_token'] ?? previous['refresh_token'],
      'expires_at': DateTime.now()
          .add(Duration(seconds: (tokens['expires_in'] as num).toInt()))
          .toIso8601String(),
      'scopes': tokens['scope'] == null
          ? previous['scopes'] ?? <String>[]
          : (tokens['scope'] as String).split(' '),
    };
  }

  Future<String> accessToken(String id) => _lock(id).synchronized(() async {
    var record = await _record(id);
    if (record['access_token'] == null) {
      throw const ChatGptAuthException('sign_in_required');
    }
    if (!(record['scopes'] as List).contains(planScope)) {
      throw const ChatGptAuthException('plan_permission_required');
    }
    if (DateTime.parse(
      record['expires_at'] as String,
    ).isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      if (record['refresh_token'] == null) {
        throw const ChatGptAuthException('sign_in_required');
      }
      final tokens = await _json(
        '$issuer/api/accounts/oauth/token',
        form: {
          'grant_type': 'refresh_token',
          'client_id': record['client_id'] as String,
          'refresh_token': record['refresh_token'] as String,
          'resource': resource,
        },
      );
      record = tokenRecord(tokens, record);
      await write('connection:$id', jsonEncode(record));
      if (!(record['scopes'] as List).contains(planScope)) {
        throw const ChatGptAuthException('plan_permission_required');
      }
    }
    return record['access_token'] as String;
  });

  /// False means local logout succeeded but remote revocation was not confirmed.
  Future<bool> signOut(String id) => _lock(id).synchronized(() async {
    final record = await _record(id);
    var revoked = true;
    try {
      if (record['refresh_token'] case final String token) {
        final discovery = await _json(
          '$issuer/.well-known/openid-configuration',
        );
        final endpoint = _trustedAuthEndpoint(discovery['revocation_endpoint']);
        await dio.post<dynamic>(
          endpoint,
          data: {
            'token': token,
            'token_type_hint': 'refresh_token',
            'client_id': record['client_id'],
          },
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
      }
    } catch (_) {
      revoked = false;
    } finally {
      for (final key in [
        'access_token',
        'refresh_token',
        'id_token',
        'expires_at',
        'scopes',
      ]) {
        record.remove(key);
      }
      await write('connection:$id', jsonEncode(record));
    }
    return revoked;
  });
}

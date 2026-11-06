import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jose/jose.dart';
import 'package:nai_launcher/core/auth/chatgpt_auth_service.dart';

void main() {
  late JsonWebKey key;
  setUpAll(() => key = JsonWebKey.generate('RS256', keyBitLength: 2048));

  String signed(Map<String, dynamic> claims) {
    final builder = JsonWebSignatureBuilder()..jsonContent = claims;
    builder.addRecipient(key, algorithm: 'RS256');
    return builder.build().toCompactSerialization();
  }

  Map<String, dynamic> claims(String nonce, {String client = 'issued'}) => {
    'iss': ChatGptAuthService.issuer,
    'sub': 'synthetic-user',
    'aud': client,
    'nonce': nonce,
    'email': 'test@example.invalid',
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
  };

  Map<String, dynamic> tokens({String? idToken}) => {
    'access_token': 'synthetic-access',
    'refresh_token': 'synthetic-refresh',
    'token_type': 'Bearer',
    'expires_in': 3600,
    'scope': 'openid ${ChatGptAuthService.planScope}',
    if (idToken != null) 'id_token': idToken,
  };

  test(
    'ID token requires a verified signature, issuer, audience, expiry and nonce',
    () async {
      final jwks = {
        'keys': [key.toJson()],
      };
      expect(
        await ChatGptAuthService.verifyIdToken(
          signed(claims('nonce')),
          jwks,
          clientId: 'issued',
          nonce: 'nonce',
        ),
        containsPair('sub', 'synthetic-user'),
      );
      for (final mutation in [
        {'iss': 'https://wrong.invalid'},
        {'aud': 'other'},
        {'nonce': 'other'},
        {'exp': 0},
        {'sub': ''},
        {'azp': 'other'},
      ]) {
        await expectLater(
          ChatGptAuthService.verifyIdToken(
            signed({...claims('nonce'), ...mutation}),
            jwks,
            clientId: 'issued',
            nonce: 'nonce',
          ),
          throwsA(isA<ChatGptAuthException>()),
        );
      }
      await expectLater(
        ChatGptAuthService.verifyIdToken(
          signed(claims('nonce')),
          {
            'keys': [JsonWebKey.generate('RS256', keyBitLength: 2048).toJson()],
          },
          clientId: 'issued',
          nonce: 'nonce',
        ),
        throwsA(isA<ChatGptAuthException>()),
      );
    },
  );

  test(
    'new registration requires issued client ID; returning login cannot replace it',
    () {
      for (final query in [
        <String, String>{'code': 'x'},
        {'code': 'x', 'client_id': 'dynamic_agent_client'},
      ]) {
        expect(
          () => ChatGptAuthService.callbackClientId(query, null),
          throwsA(isA<ChatGptAuthException>()),
        );
      }
      expect(
        ChatGptAuthService.callbackClientId({'code': 'x'}, 'issued'),
        'issued',
      );
      expect(
        () => ChatGptAuthService.callbackClientId({
          'code': 'x',
          'client_id': 'other',
        }, 'issued'),
        throwsA(isA<ChatGptAuthException>()),
      );
    },
  );

  test(
    'loopback login uses PKCE, validates state, retains registration and supports reauthorization',
    () async {
      final saved = <String, String>{};
      late Uri authorize;
      var tokenCalls = 0;
      var failExchange = false;
      var subject = 'synthetic-user';
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              Object data;
              if (request.path.endsWith('openid-configuration')) {
                data = {
                  'jwks_uri':
                      '${ChatGptAuthService.issuer}/.well-known/jwks.json',
                };
              } else if (request.path.endsWith('jwks.json')) {
                data = {
                  'keys': [key.toJson()],
                };
              } else {
                tokenCalls++;
                if (failExchange) {
                  handler.reject(DioException(requestOptions: request));
                  return;
                }
                final form = request.data as Map<String, String>;
                expect(form['client_id'], 'issued');
                expect(
                  form['redirect_uri'],
                  authorize.queryParameters['redirect_uri'],
                );
                expect(
                  base64UrlEncode(
                    sha256.convert(utf8.encode(form['code_verifier']!)).bytes,
                  ).replaceAll('=', ''),
                  authorize.queryParameters['code_challenge'],
                );
                data = tokens(
                  idToken: signed({
                    ...claims(authorize.queryParameters['nonce']!),
                    'sub': subject,
                  }),
                );
              }
              handler.resolve(
                Response(requestOptions: request, data: data, statusCode: 200),
              );
            },
          ),
        );
      final service = ChatGptAuthService(
        dio: dio,
        read: (id) async => saved[id],
        write: (id, value) async {
          saved[id] = value;
        },
        openBrowser: (uri) async {
          authorize = uri;
          final callback = Uri.parse(uri.queryParameters['redirect_uri']!);
          expect(callback.host, '127.0.0.1');
          expect(callback.path, '/auth/callback');
          final client = HttpClient();
          final wrong = await client.getUrl(
            callback.replace(queryParameters: {'state': 'wrong'}),
          );
          expect((await wrong.close()).statusCode, 400);
          final request = await client.getUrl(
            callback.replace(
              queryParameters: {
                'state': uri.queryParameters['state']!,
                'code': 'synthetic-code',
                'client_id': 'issued',
              },
            ),
          );
          await (await request.close()).drain<void>();
          client.close();
          return true;
        },
      );
      await service.signIn('service-1', CancelToken());
      final firstHost = authorize.queryParameters['ext_agent_host_id'];
      expect(authorize.queryParameters['client_id'], 'dynamic_agent_client');
      expect((await service.account('service-1'))?.planEnabled, true);
      expect(await service.accessToken('service-1'), 'synthetic-access');
      await service.signIn('service-1', CancelToken());
      expect(authorize.queryParameters['client_id'], 'issued');
      expect(authorize.queryParameters['ext_agent_host_id'], firstHost);
      expect(authorize.queryParameters.containsKey('agent_name_hint'), false);
      expect(tokenCalls, 2);
      final registered = saved['connection:service-1'];
      subject = 'another-user';
      await expectLater(
        service.signIn('service-1', CancelToken()),
        throwsA(
          isA<ChatGptAuthException>().having(
            (e) => e.code,
            'code',
            'account_mismatch',
          ),
        ),
      );
      expect(saved['connection:service-1'], registered);
      failExchange = true;
      await expectLater(
        service.signIn('new-service', CancelToken()),
        throwsA(isA<ChatGptAuthException>()),
      );
      expect(jsonDecode(saved['connection:new-service']!), {
        'client_id': 'issued',
      });
    },
  );

  test(
    'cancelling sign-in closes its loopback listener without a token exchange',
    () async {
      final saved = <String, String>{};
      final cancel = CancelToken();
      late int port;
      final service = ChatGptAuthService(
        dio: Dio(),
        read: (id) async => saved[id],
        write: (id, value) async {
          saved[id] = value;
        },
        openBrowser: (uri) async {
          port = Uri.parse(uri.queryParameters['redirect_uri']!).port;
          cancel.cancel();
          return true;
        },
      );
      await expectLater(
        service.signIn('host', cancel),
        throwsA(
          isA<ChatGptAuthException>().having(
            (e) => e.code,
            'code',
            'cancelled',
          ),
        ),
      );
      expect(saved['connection:host'], isNull);
      expect(saved['host'], startsWith('urn:uuid:'));
      final rebound = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      await rebound.close(force: true);
    },
  );

  test(
    'concurrent refresh rotates tokens once and keeps accounts separate',
    () async {
      final saved = <String, String>{
        'connection:a': jsonEncode({
          ...tokens(),
          'client_id': 'issued-a',
          'scopes': [ChatGptAuthService.planScope],
          'expires_at': '2000-01-01T00:00:00Z',
        }),
        'b': 'untouched',
      };
      var requests = 0;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) async {
              requests++;
              expect(request.data['client_id'], 'issued-a');
              expect(request.data['grant_type'], 'refresh_token');
              expect(request.data.containsKey('scope'), false);
              await Future<void>.delayed(const Duration(milliseconds: 10));
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: {
                    ...tokens(),
                    'access_token': 'rotated',
                    'refresh_token': 'rotated-refresh',
                  },
                ),
              );
            },
          ),
        );
      final service = ChatGptAuthService(
        dio: dio,
        read: (id) async => saved[id],
        write: (id, value) async {
          saved[id] = value;
        },
        openBrowser: (_) async => false,
      );
      expect(
        await Future.wait([service.accessToken('a'), service.accessToken('a')]),
        ['rotated', 'rotated'],
      );
      expect(requests, 1);
      expect(
        jsonDecode(saved['connection:a']!)['refresh_token'],
        'rotated-refresh',
      );
      expect(saved['b'], 'untouched');
    },
  );

  test('identity-only grant cannot make inference requests', () async {
    final record = jsonEncode({
      ...tokens(),
      'client_id': 'issued',
      'scopes': ['openid'],
      'expires_at': '2099-01-01T00:00:00Z',
    });
    final service = ChatGptAuthService(
      dio: Dio(),
      read: (_) async => record,
      write: (_, _) async {},
      openBrowser: (_) async => false,
    );
    await expectLater(
      service.accessToken('a'),
      throwsA(isA<ChatGptAuthException>()),
    );
  });

  test(
    'failed revocation clears tokens but retains the account registration',
    () async {
      var record = jsonEncode({
        ...tokens(),
        'id_token': 'synthetic-id',
        'client_id': 'issued',
        'subject': 'user',
        'scopes': [ChatGptAuthService.planScope],
      });
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) => h.reject(DioException(requestOptions: r)),
          ),
        );
      final service = ChatGptAuthService(
        dio: dio,
        read: (_) async => record,
        write: (_, value) async {
          record = value;
        },
        openBrowser: (_) async => false,
      );
      expect(await service.signOut('a'), false);
      expect(jsonDecode(record), {
        'client_id': 'issued',
        'subject': 'user',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'scope': 'openid ${ChatGptAuthService.planScope}',
      });
      expect((await service.account('a'))?.signedIn, false);
    },
  );
}

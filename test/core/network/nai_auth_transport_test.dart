import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/network/nai_auth_transport.dart';
import 'package:nai_launcher/data/datasources/remote/nai_auth_api_service.dart';

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  test(
    'local proxy: cancelled request settles and manual second attempt succeeds',
    () async {
      final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final firstStarted = Completer<void>();
      final release = Completer<void>();
      var calls = 0;
      proxy.listen((request) async {
        if (++calls == 1) {
          firstStarted.complete();
          await release.future;
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"tier":3}');
        await request.response.close();
      });
      final transport = NaiAuthTransport(
        resolveProxy: () => '127.0.0.1:${proxy.port}',
      );
      final service = NAIAuthApiService.withTransport(transport);
      const endpoint = NaiApiEndpointConfig(
        mainBaseUrl: 'http://fixture.invalid',
        imageBaseUrl: 'http://fixture.invalid',
      );
      try {
        final cancel = CancelToken();
        final first = service.validateToken(
          'pst-offline-fixture',
          endpoint: endpoint,
          cancelToken: cancel,
        );
        final assertion = expectLater(
          first,
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.cancel,
            ),
          ),
        );
        await firstStarted.future.timeout(const Duration(seconds: 2));
        cancel.cancel('fixture timeout');
        await assertion.timeout(const Duration(seconds: 2));
        expect(
          (await service.validateToken(
            'pst-offline-fixture',
            endpoint: endpoint,
            cancelToken: CancelToken(),
          ))['tier'],
          3,
        );
        expect(calls, 2);
      } finally {
        release.complete();
        transport.close();
        await proxy.close(force: true);
      }
    },
  );

  test(
    'stalled TLS handshake: actual socket closes and retry opens fresh TCP',
    () async {
      final blackhole = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final sockets = <Socket>[];
      final firstClosed = Completer<void>();
      final firstConnected = Completer<void>();
      final secondConnected = Completer<void>();
      blackhole.listen((socket) {
        sockets.add(socket);
        final index = sockets.length;
        socket.listen(
          (_) {},
          onError: (Object _) {},
          onDone: () {
            if (index == 1 && !firstClosed.isCompleted) firstClosed.complete();
          },
        );
        if (sockets.length == 1) firstConnected.complete();
        if (sockets.length == 2) secondConnected.complete();
      });
      final transport = NaiAuthTransport(resolveProxy: () => null);
      final service = NAIAuthApiService.withTransport(transport);
      final endpoint = NaiApiEndpointConfig(
        mainBaseUrl: 'https://127.0.0.1:${blackhole.port}',
        imageBaseUrl: 'https://127.0.0.1:${blackhole.port}',
      );
      try {
        final firstCancel = CancelToken();
        final first = service.validateToken(
          'pst-offline-fixture',
          endpoint: endpoint,
          cancelToken: firstCancel,
        );
        final firstAssertion = expectLater(first, throwsA(isA<DioException>()));
        await firstConnected.future.timeout(const Duration(seconds: 2));
        firstCancel.cancel('fixture timeout');
        await firstAssertion;
        await firstClosed.future.timeout(const Duration(seconds: 2));
        final secondCancel = CancelToken();
        final second = service.validateToken(
          'pst-offline-fixture',
          endpoint: endpoint,
          cancelToken: secondCancel,
        );
        final secondAssertion = expectLater(
          second,
          throwsA(isA<DioException>()),
        );
        await secondConnected.future.timeout(const Duration(seconds: 2));
        expect(sockets, hasLength(2));
        secondCancel.cancel('fixture done');
        await secondAssertion;
      } finally {
        transport.close();
        for (final socket in sockets) {
          socket.destroy();
        }
        await blackhole.close();
      }
    },
  );

  test(
    'pending legacy HTTP2 TLS pool cannot block new login transport',
    () async {
      final blackhole = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final sockets = <Socket>[];
      final connected = [Completer<void>(), Completer<void>()];
      blackhole.listen((socket) {
        sockets.add(socket);
        socket.listen((_) {}, onError: (Object _) {});
        connected[sockets.length - 1].complete();
      });
      final endpoint = NaiApiEndpointConfig(
        mainBaseUrl: 'https://127.0.0.1:${blackhole.port}',
        imageBaseUrl: 'https://127.0.0.1:${blackhole.port}',
      );
      final legacy = Dio()
        ..httpClientAdapter = Http2Adapter(ConnectionManager());
      final legacyCancel = CancelToken();
      final legacyRequest = legacy.get(
        endpoint.userUrl('/user/subscription'),
        cancelToken: legacyCancel,
      );
      final legacyAssertion = expectLater(
        legacyRequest,
        throwsA(isA<DioException>()),
      );
      final transport = NaiAuthTransport(resolveProxy: () => null);
      final cancel = CancelToken();
      try {
        await connected[0].future.timeout(const Duration(seconds: 2));
        legacyCancel.cancel('old outer timeout');
        await legacyAssertion;
        final request = NAIAuthApiService.withTransport(transport)
            .validateToken(
              'pst-offline-fixture',
              endpoint: endpoint,
              cancelToken: cancel,
            );
        final assertion = expectLater(request, throwsA(isA<DioException>()));
        await connected[1].future.timeout(const Duration(seconds: 2));
        expect(sockets, hasLength(2));
        cancel.cancel('done');
        await assertion;
      } finally {
        transport.close();
        legacy.close(force: true);
        for (final socket in sockets) {
          socket.destroy();
        }
        await blackhole.close();
      }
    },
  );

  test('proxy CONNECT stall closes its real socket on cancellation', () async {
    final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final connected = Completer<void>();
    final closed = Completer<void>();
    final bytes = <int>[];
    Socket? socket;
    proxy.listen((peer) {
      socket = peer;
      peer.listen(
        (data) {
          bytes.addAll(data);
          if (!connected.isCompleted) connected.complete();
        },
        onDone: () {
          if (!closed.isCompleted) closed.complete();
        },
        onError: (Object _) {},
      );
    });
    final transport = NaiAuthTransport(
      resolveProxy: () => '127.0.0.1:${proxy.port}',
    );
    final cancel = CancelToken();
    try {
      final pending = NAIAuthApiService.withTransport(
        transport,
      ).validateToken('pst-offline-fixture', cancelToken: cancel);
      final assertion = expectLater(pending, throwsA(isA<DioException>()));
      await connected.future.timeout(const Duration(seconds: 2));
      expect(
        String.fromCharCodes(bytes),
        startsWith('CONNECT image.novelai.net:443'),
      );
      cancel.cancel('fixture timeout');
      await assertion;
      await closed.future.timeout(const Duration(seconds: 2));
    } finally {
      transport.close();
      socket?.destroy();
      await proxy.close();
    }
  });

  test('concurrent refresh request survives cancelling a login', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final both = Completer<void>();
    final release = Completer<void>();
    var count = 0;
    server.listen((request) async {
      if (++count == 2) both.complete();
      await release.future;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"tier":3,"accessToken":"offline-refresh"}');
      await request.response.close();
    });
    final transport = NaiAuthTransport(resolveProxy: () => null);
    final service = NAIAuthApiService.withTransport(transport);
    final endpoint = NaiApiEndpointConfig(
      mainBaseUrl: 'http://127.0.0.1:${server.port}',
      imageBaseUrl: 'http://127.0.0.1:${server.port}',
    );
    final cancel = CancelToken();
    try {
      final login = service.validateToken(
        'pst-offline-fixture',
        endpoint: endpoint,
        cancelToken: cancel,
      );
      final assertion = expectLater(login, throwsA(isA<DioException>()));
      final refresh = service.loginWithKey('offline-key', endpoint: endpoint);
      await both.future.timeout(const Duration(seconds: 2));
      cancel.cancel('superseded login');
      await assertion;
      release.complete();
      expect((await refresh)['accessToken'], 'offline-refresh');
    } finally {
      if (!release.isCompleted) release.complete();
      transport.close();
      await server.close(force: true);
    }
  });

  test(
    'diagnostic phases are factual and exclude token, proxy credentials and query',
    () {
      final client = Dio()..httpClientAdapter = IOHttpClientAdapter();
      addTearDown(() => client.close(force: true));
      for (final (cause, type, status, phase)
          in <(Object?, DioExceptionType, int?, String)>[
            (
              const SocketException('Failed host lookup: fixture'),
              DioExceptionType.connectionError,
              null,
              'DNS',
            ),
            (
              const HandshakeException('fixture'),
              DioExceptionType.connectionError,
              null,
              'TLS',
            ),
            (
              const SocketException('Proxy CONNECT failed'),
              DioExceptionType.connectionError,
              null,
              'proxy CONNECT',
            ),
            (null, DioExceptionType.receiveTimeout, null, 'timeout'),
            (null, DioExceptionType.badResponse, 401, 'HTTP 401'),
          ]) {
        final options = RequestOptions(
          path: 'https://target.invalid/user/login?token=fixture-secret',
          headers: {'Authorization': 'Bearer fixture-secret'},
        );
        final description = authNetworkFailureDescription(
          client,
          DioException(
            requestOptions: options,
            type: type,
            error: cause,
            response: status == null
                ? null
                : Response(requestOptions: options, statusCode: status),
          ),
          proxy: 'fixture-user:fixture-password@127.0.0.1:9999',
        );
        expect(description, contains('stage=$phase'));
        expect(description, contains('proxy=HTTP 127.0.0.1'));
        expect(description, contains('adapter=h1'));
        expect(description, contains('target=target.invalid'));
        for (final secret in [
          'fixture-secret',
          'fixture-user',
          'fixture-password',
          'Authorization',
          '?token',
        ]) {
          expect(description, isNot(contains(secret)));
        }
      }
    },
  );

  test(
    'system proxy resolver is read again after failure and on manual retry',
    () async {
      String? proxy;
      var reads = 0;
      final transport = NaiAuthTransport(
        resolveProxy: () {
          reads++;
          return proxy;
        },
      );
      addTearDown(transport.close);
      final clients = <Dio>[];
      await expectLater(
        transport.send<void>(null, (dio) async {
          clients.add(dio);
          throw DioException(
            requestOptions: RequestOptions(path: 'https://fixture.invalid'),
            type: DioExceptionType.connectionTimeout,
          );
        }),
        throwsA(isA<DioException>()),
      );
      proxy = '127.0.0.1:1';
      await transport.send<void>(null, (dio) async {
        clients.add(dio);
      });
      proxy = null;
      await transport.send<void>(null, (dio) async {
        clients.add(dio);
      });
      expect(clients.toSet(), hasLength(3));
      expect(
        clients.every((dio) => dio.httpClientAdapter is IOHttpClientAdapter),
        true,
      );
      expect(reads, 3);
    },
  );
}

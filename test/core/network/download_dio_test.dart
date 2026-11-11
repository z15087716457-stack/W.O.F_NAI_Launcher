import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/download_dio.dart';
import 'package:nai_launcher/core/network/system_proxy_http_overrides.dart';

void main() {
  test(
    'download client follows current proxy and can bypass startup proxy',
    () async {
      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => origin.close(force: true));
      origin.listen((request) {
        request.response.write('origin');
        request.response.close();
      });
      final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => proxy.close(force: true));
      proxy.listen((request) {
        request.response.write('proxy');
        request.response.close();
      });
      final proxyAddress = '127.0.0.1:${proxy.port}';
      final url = 'http://127.0.0.1:${origin.port}/model';
      String? currentProxy;

      await HttpOverrides.runWithHttpOverrides(() async {
        final dio = createDownloadDio(
          receiveTimeout: const Duration(seconds: 2),
          resolveProxy: () => currentProxy,
        );
        try {
          expect((await dio.get<String>(url)).data, 'origin');
          currentProxy = proxyAddress;
          expect((await dio.get<String>(url)).data, 'proxy');
          currentProxy = null;
          expect((await dio.get<String>(url)).data, 'origin');
        } finally {
          dio.close(force: true);
        }
      }, SystemProxyHttpOverrides('PROXY $proxyAddress'));
    },
  );
}

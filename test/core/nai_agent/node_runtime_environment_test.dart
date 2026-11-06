import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/node_runtime_environment.dart';
import 'package:path/path.dart' as p;
import '../../helpers/agent_test_node.dart';

void main() {
  test(
    'bundled Node routes external fetch through Studio proxy and bypasses loopback',
    () async {
      final proxy = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final local = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await proxy.close(force: true);
        await local.close(force: true);
      });
      final targets = <String>[];
      proxy.listen((request) async {
        expect(request.method, 'CONNECT');
        targets.add(request.uri.toString());
        final downstream = await request.response.detachSocket(
          writeHeaders: false,
        );
        final upstream = await Socket.connect(
          InternetAddress.loopbackIPv4,
          local.port,
        );
        downstream.write('HTTP/1.1 200 Connection Established\r\n\r\n');
        downstream.listen(upstream.add, onDone: upstream.close);
        upstream.listen(downstream.add, onDone: downstream.close);
      });
      local.listen((request) async {
        request.response.write(
          request.headers.host == 'studio-proxy-test.invalid'
              ? 'proxied'
              : 'local',
        );
        await request.response.close();
      });
      final result = await Process.run(
        agentTestNode,
        [
          '--input-type=module',
          '-e',
          "console.log(await (await fetch('http://studio-proxy-test.invalid/probe',{signal:AbortSignal.timeout(5000)})).text());"
              "console.log(await (await fetch('http://127.0.0.1:${local.port}/probe',{signal:AbortSignal.timeout(5000)})).text());",
        ],
        environment: piHostEnvironment(
          agentTestNode,
          proxyAddress: '127.0.0.1:${proxy.port}',
        ),
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout.toString().trim().split(RegExp(r'\r?\n')), [
        'proxied',
        'local',
      ]);
      expect(targets.single, contains('studio-proxy-test.invalid:80'));
    },
  );
  test(
    'Agent follows Studio proxy and explicitly clears inherited direct settings',
    () {
      final proxied = piHostEnvironment(
        'C:/Studio/node.exe',
        proxyAddress: '127.0.0.1:7897',
      );
      expect(proxied['NODE_USE_ENV_PROXY'], '1');
      expect(proxied['HTTPS_PROXY'], 'http://127.0.0.1:7897');
      expect(proxied['https_proxy'], proxied['HTTPS_PROXY']);
      expect(proxied['NO_PROXY'], contains('127.0.0.1'));
      final direct = piHostEnvironment('C:/Studio/node.exe');
      for (final key in [
        'HTTP_PROXY',
        'HTTPS_PROXY',
        'http_proxy',
        'https_proxy',
        'ALL_PROXY',
        'all_proxy',
      ]) {
        expect(direct[key], isEmpty);
      }
    },
  );
  test(
    'Finder-launched helpers find the bundled npm before system tools',
    () async {
      final root = await Directory.systemTemp.createTemp('agent node runtime ');
      addTearDown(() => root.delete(recursive: true));
      final npm = File(p.join(root.path, 'npm'));
      await npm.writeAsString('#!/bin/sh\nprintf bundled-npm');
      final chmod = await Process.run('/bin/chmod', ['755', npm.path]);
      expect(chmod.exitCode, 0);
      final result = await Process.run(
        '/bin/sh',
        ['-c', 'npm --version'],
        environment:
            nodeRuntimeEnvironment(
              p.join(root.path, 'node'),
              isMacOS: true,
              inheritedPath: '/usr/bin:/bin',
            ) ??
            {'PATH': '/usr/bin:/bin'},
        includeParentEnvironment: false,
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, 'bundled-npm');
    },
    skip: Platform.isWindows,
  );

  test(
    'missing PATH keeps system commands without adding the current directory',
    () {
      expect(
        nodeRuntimeEnvironment(
          '/App/工具/node',
          isMacOS: true,
          inheritedPath: '',
        ),
        {'PATH': '/App/工具:/usr/bin:/bin:/usr/sbin:/sbin'},
      );
    },
  );

  test('other platforms preserve their existing process environment', () {
    expect(nodeRuntimeEnvironment('C:\\app\\node.exe', isMacOS: false), isNull);
  });
}

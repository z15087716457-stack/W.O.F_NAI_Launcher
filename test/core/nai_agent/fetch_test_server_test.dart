import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fetch_test_server.dart';

void main() {
  final node = Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe';

  test(
    'Node rejects a Fetch-blocked loopback port before HTTP dispatch',
    () async {
      final result = await Process.run(node, [
        '--input-type=module',
        '--eval',
        "try { await fetch('http://127.0.0.1:10080/'); process.exitCode=1; } "
            "catch (error) { console.log(error.cause?.message); }",
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString().trim(), 'bad port');
      expect(fetchBlockedPorts, contains(10080));
    },
  );

  test(
    'synthetic HTTP fixture is reachable by the real bundled Node fetch',
    () async {
      final server = await bindFetchTestServer();
      var requests = 0;
      final serving = server.listen((request) async {
        requests++;
        request.response.write('synthetic-local-response');
        await request.response.close();
      });
      try {
        final result = await Process.run(node, [
          '--input-type=module',
          '--eval',
          "console.log(await (await fetch('http://127.0.0.1:${server.port}/')).text());",
        ]);
        expect(result.exitCode, 0, reason: result.stderr.toString());
        expect(result.stdout.toString().trim(), 'synthetic-local-response');
        expect(requests, 1);
        expect(fetchBlockedPorts, isNot(contains(server.port)));
      } finally {
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}

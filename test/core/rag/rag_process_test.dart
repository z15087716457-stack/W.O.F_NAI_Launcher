import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_platform.dart';
import 'package:nai_launcher/core/rag/rag_process.dart';
import 'package:path/path.dart' as p;

class _Exited implements Process {
  @override
  int get pid => 7;
  @override
  final IOSink stdin = IOSink(StreamController<List<int>>().sink);
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode => Future.value(0);
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

typedef _Launch = ({
  String executable,
  List<String> arguments,
  Map<String, String>? environment,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late List<_Launch> launches;
  Future<Process> start(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    launches.add((
      executable: executable,
      arguments: arguments,
      environment: environment,
    ));
    return _Exited();
  }

  Future<void> launch(RagPlatform platform) => startRagProcess(
    directory: root,
    executable: p.join(root.path, 'runtime', 'python'),
    arguments: ['-u', 'worker.py'],
    environment: const {'PYTHONUTF8': '1'},
    platform: platform,
    start: start,
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rag-process-');
    launches = [];
  });
  tearDown(() async {
    debugRagMacOSHostOverride = null;
    await root.delete(recursive: true);
  });

  test('Windows runs the verified Job host from the asset bundle', () async {
    await launch(RagPlatform.windows);
    final hosts = root
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('stdio-host-'))
        .toList();
    expect(hosts, hasLength(1));
    final digest = sha256.convert(hosts.single.readAsBytesSync()).toString();
    expect(p.basename(hosts.single.path), 'stdio-host-$digest.exe');
    expect(launches.single.executable, hosts.single.path);
    expect(launches.single.arguments, [
      '$pid',
      p.join(root.path, 'runtime', 'python'),
      '-u',
      'worker.py',
    ]);
    expect(launches.single.environment, {'PYTHONUTF8': '1'});
  });

  test('macOS runs the bundled POSIX host, never the Windows asset', () async {
    final host = File(p.join(root.path, 'tools', 'rag-stdio-host'))
      ..createSync(recursive: true);
    debugRagMacOSHostOverride = host.path;
    for (final mac in [RagPlatform.macOSArm64, RagPlatform.macOSX64]) {
      launches.clear();
      await launch(mac);
      expect(launches.single.executable, host.path);
      expect(launches.single.arguments, [
        '$pid',
        p.join(root.path, 'runtime', 'python'),
        '-u',
        'worker.py',
      ]);
      expect(launches.single.environment, {'PYTHONUTF8': '1'});
    }
    expect(
      root.listSync().map((e) => p.basename(e.path)),
      isNot(contains(startsWith('stdio-host-'))),
    );
  });

  test('a macOS bundle without the host still starts the child', () async {
    debugRagMacOSHostOverride = p.join(root.path, 'missing-host');
    await launch(RagPlatform.macOSArm64);
    expect(launches.single.executable, p.join(root.path, 'runtime', 'python'));
    expect(launches.single.arguments, ['-u', 'worker.py']);
    expect(launches.single.environment, {'PYTHONUTF8': '1'});
  });

  test('the bundled host lives in the app tools directory', () {
    expect(p.basename(ragMacOSHostPath), 'rag-stdio-host');
    expect(p.basename(p.dirname(ragMacOSHostPath)), 'tools');
  });
}

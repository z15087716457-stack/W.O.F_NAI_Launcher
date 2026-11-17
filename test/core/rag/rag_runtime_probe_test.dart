import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/rag/rag_runtime_probe.dart';
import 'package:nai_launcher/core/rag/rag_runtime.dart';

class ProbeProcess implements Process {
  ProbeProcess({
    this.hanging = false,
    this.ready = true,
    this.issue,
    this.packages = const [],
  });
  final bool hanging, ready;
  final String? issue;
  final List<String> packages;
  bool killed = false;
  @override
  int get pid => 42;
  @override
  final IOSink stdin = IOSink(StreamController<List<int>>().sink);
  @override
  Stream<List<int>> get stdout => Stream.value(
    utf8.encode(
      '${jsonEncode({'ready': ready, 'cuda': true, 'issue': issue, 'packages': packages})}\n',
    ),
  );
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode =>
      hanging ? Completer<int>().future : Future.value(0);
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    unawaited(stdin.close());
    return true;
  }
}

class ReadyProbe extends RagRuntimeProbe {
  @override
  Future<RagRuntimeInfo> inspect(Directory root, String preferred) async =>
      RagRuntimeInfo(python: preferred, ready: true, cuda: true);
}

void main() {
  late Directory root;
  setUp(() async => root = await Directory.systemTemp.createTemp('rag-probe-'));
  tearDown(() async => root.delete(recursive: true));
  test('missing executable does not start any process', () async {
    var starts = 0;
    final probe = RagRuntimeProbe(
      runner: (root, python, code) async {
        starts++;
        return ProbeProcess();
      },
    );
    expect((await probe.inspect(root, '')).ready, isFalse);
    expect(starts, 0);
  });
  test(
    'imports and versions must pass before an existing path is ready',
    () async {
      final exe = File(p.join(root.path, 'existing.exe'));
      await exe.writeAsString('fixture');
      final process = ProbeProcess();
      final probe = RagRuntimeProbe(
        runner: (root, python, code) async => process,
      );
      final value = await probe.inspect(root, exe.path);
      expect(value.ready, isTrue);
      expect(value.python, exe.path);
      expect(process.killed, isTrue);
    },
  );
  test(
    'hung probes are bounded and their child process is reclaimed',
    () async {
      final exe = File(p.join(root.path, 'existing.exe'));
      await exe.writeAsString('fixture');
      final process = ProbeProcess(hanging: true);
      final probe = RagRuntimeProbe(
        timeout: const Duration(milliseconds: 15),
        runner: (root, python, code) async => process,
      );
      final result = await probe.inspect(root, exe.path);
      expect(result.ready, isFalse);
      expect(result.issue, RagRuntimeIssue.timedOut);
      expect(process.killed, isTrue);
    },
  );
  test(
    'install reuses a compatible selected environment before any download',
    () async {
      final installer = RagRuntimeInstaller(root, probe: ReadyProbe());
      final phases = <String>[];
      try {
        expect(
          await installer.install(
            cuda: true,
            onPhase: phases.add,
            preferredPython: 'existing.exe',
          ),
          'existing.exe',
        );
        expect(phases, ['existing']);
        expect(
          await File(p.join(root.path, 'uv-0.13.1.exe')).exists(),
          isFalse,
        );
      } finally {
        installer.dispose();
      }
    },
  );
  test(
    'missing dependencies remain distinguishable from an absent interpreter',
    () async {
      final exe = File(p.join(root.path, 'existing.exe'));
      await exe.writeAsString('fixture');
      final probe = RagRuntimeProbe(
        runner: (root, python, code) async => ProbeProcess(
          ready: false,
          issue: 'dependencies',
          packages: ['jieba'],
        ),
      );
      final result = await probe.inspect(root, exe.path);
      expect(result.issue, RagRuntimeIssue.dependencies);
      expect(result.packages, ['jieba']);
      expect(result.python, exe.path);
      expect(
        (await probe.inspect(root, 'missing.exe')).issue,
        RagRuntimeIssue.missing,
      );
    },
  );
  test(
    'a failed preferred probe can reuse a compatible managed environment',
    () async {
      final exe = File(p.join(root.path, 'selected.exe'));
      final managed = File(RagRuntimeProbe().platform.managedPython(root.path));
      await exe.writeAsString('fixture');
      await managed.parent.create(recursive: true);
      await managed.writeAsString('fixture');
      final probe = RagRuntimeProbe(
        runner: (root, python, code) async => ProbeProcess(
          ready: python == managed.path,
          issue: 'dependencies',
          packages: ['jieba'],
        ),
      );
      final result = await probe.inspect(root, exe.path);
      expect(result.ready, isTrue);
      expect(result.python, managed.path);
      expect(result.issue, isNull);
    },
  );
  for (final issue in ['pythonVersion', 'importFailed']) {
    test(
      'probe preserves $issue without claiming the environment is missing',
      () async {
        final exe = File(p.join(root.path, 'existing.exe'));
        await exe.writeAsString('fixture');
        final probe = RagRuntimeProbe(
          runner: (root, python, code) async =>
              ProbeProcess(ready: false, issue: issue),
        );
        expect((await probe.inspect(root, exe.path)).issue?.name, issue);
      },
    );
  }
}

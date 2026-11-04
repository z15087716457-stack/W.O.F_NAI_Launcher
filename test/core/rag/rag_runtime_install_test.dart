import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_platform.dart';
import 'package:nai_launcher/core/rag/rag_process.dart';
import 'package:nai_launcher/core/rag/rag_runtime.dart';
import 'package:nai_launcher/core/rag/rag_runtime_probe.dart';
import 'package:path/path.dart' as p;

class _Adapter implements HttpClientAdapter {
  _Adapter(this.bytes);
  final List<int> bytes;
  final requests = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options.uri.toString());
    return ResponseBody.fromBytes(bytes, 200);
  }

  @override
  void close({bool force = false}) {}
}

class _Missing extends RagRuntimeProbe {
  @override
  Future<RagRuntimeInfo> inspect(Directory root, String preferred) async =>
      const RagRuntimeInfo(python: '', ready: false);
}

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

const _check =
    'import torch, torchvision, transformers, sentence_transformers, usearch; from transformers.models.embedding_gemma2 import EmbeddingGemma2Model';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final uv = utf8.encode('fixture uv executable');
  late Directory root;
  late List<List<String>> commands;
  late List<Map<String, String>?> environments;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('rag-install-');
    commands = [];
    environments = [];
    debugRagMacOSHostOverride = p.join(root.path, 'no-host');
  });
  tearDown(() async {
    debugRagMacOSHostOverride = null;
    await root.delete(recursive: true);
  });

  /// Records each command (unwrapping the Windows Job host) and fakes the
  /// interpreter that `uv venv` would create.
  RagProcessStarter starter(RagPlatform platform) =>
      (executable, arguments, {environment}) async {
        final command = p.basename(executable).startsWith('stdio-host-')
            ? arguments.skip(1).toList()
            : [executable, ...arguments];
        commands.add(command);
        environments.add(environment);
        if (command.length > 1 && command[1] == 'venv') {
          File(platform.managedPython(root.path)).createSync(recursive: true);
        }
        return _Exited();
      };

  Future<(String, List<String>, _Adapter)> install(
    RagPlatform platform, {
    required List<int> archive,
    required String url,
    required String entry,
    required String file,
    bool cuda = false,
  }) async {
    final adapter = _Adapter(archive);
    final phases = <String>[];
    final installer = RagRuntimeInstaller(
      root,
      dio: Dio()..httpClientAdapter = adapter,
      probe: _Missing(),
      platform: platform,
      uv: RagUvRelease(
        url: url,
        sha256: sha256.convert(archive).toString(),
        entry: entry,
        file: file,
      ),
      start: starter(platform),
    );
    try {
      final python = await installer.install(cuda: cuda, onPhase: phases.add);
      return (python, phases, adapter);
    } finally {
      installer.dispose();
    }
  }

  test(
    'an Apple silicon Mac installs PyPI PyTorch from the uv tarball',
    () async {
      final archive = GZipEncoder().encode(
        TarEncoder().encode(
          Archive()
            ..addFile(ArchiveFile('uv-aarch64-apple-darwin/uvx', 3, [1, 2, 3]))
            ..addFile(ArchiveFile('uv-aarch64-apple-darwin/uv', uv.length, uv)),
        ),
      )!;
      final (python, phases, adapter) = await install(
        RagPlatform.macOSArm64,
        archive: archive,
        url: 'https://example.invalid/uv-aarch64-apple-darwin.tar.gz',
        entry: 'uv',
        file: 'uv-0.13.1',
        cuda: true,
      );
      final exe = p.join(root.path, 'uv-0.13.1');
      final managed = p.join(root.path, 'runtime', 'bin', 'python3');
      expect(python, managed);
      expect(adapter.requests, [
        'https://example.invalid/uv-aarch64-apple-darwin.tar.gz',
      ]);
      expect(await File(exe).readAsBytes(), uv);
      expect(phases, [
        'existing',
        'download',
        'create',
        'packages',
        'packages',
        'check',
      ], reason: 'no CUDA phase on a Mac, even when asked');
      expect(commands, [
        ['/bin/chmod', '755', exe],
        [exe, 'venv', '--python', '3.12.11', p.join(root.path, 'runtime')],
        [
          exe,
          '-v',
          'pip',
          'install',
          '--python',
          managed,
          '--index-url',
          'https://pypi.org/simple',
          'torch==2.10.0',
          'torchvision==0.25.0',
        ],
        [
          exe,
          '-v',
          'pip',
          'install',
          '--python',
          managed,
          '-r',
          p.join(root.path, 'requirements-v1.txt'),
        ],
        [managed, '-c', _check],
      ]);
      expect(environments.last, {
        'UV_PYTHON_INSTALL_DIR': p.join(root.path, 'python'),
        'UV_CACHE_DIR': p.join(root.path, 'download-cache'),
        'NO_COLOR': '1',
        'PYTHONUTF8': '1',
      });
      final receipt =
          jsonDecode(
                await File(
                  p.join(root.path, 'runtime-receipt.json'),
                ).readAsString(),
              )
              as Map;
      expect(receipt['cuda'], isFalse);
      expect(receipt['uvArchiveSha256'], sha256.convert(archive).toString());
      expect(
        root.listSync().map((e) => p.basename(e.path)),
        isNot(contains(startsWith('stdio-host-'))),
        reason: 'the Windows host asset is never extracted on a Mac',
      );
    },
  );

  for (final cuda in [false, true]) {
    test(
      'Windows keeps its PyTorch index and Job host (cuda: $cuda)',
      () async {
        final archive = ZipEncoder().encode(
          Archive()..addFile(ArchiveFile('uv.exe', uv.length, uv)),
        )!;
        final (python, phases, _) = await install(
          RagPlatform.windows,
          archive: archive,
          url: 'https://example.invalid/uv-x86_64-pc-windows-msvc.zip',
          entry: 'uv.exe',
          file: 'uv-0.13.1.exe',
          cuda: cuda,
        );
        final exe = p.join(root.path, 'uv-0.13.1.exe');
        final managed = p.join(root.path, 'runtime', 'Scripts', 'python.exe');
        final build = cuda ? 'cu128' : 'cpu';
        expect(python, managed);
        expect(phases[3], cuda ? 'cuda' : 'packages');
        expect(commands, [
          [exe, 'venv', '--python', '3.12.11', p.join(root.path, 'runtime')],
          [
            exe,
            '-v',
            'pip',
            'install',
            '--python',
            managed,
            '--index-url',
            'https://download.pytorch.org/whl/$build',
            'torch==2.10.0+$build',
            'torchvision==0.25.0+$build',
          ],
          [
            exe,
            '-v',
            'pip',
            'install',
            '--python',
            managed,
            '-r',
            p.join(root.path, 'requirements-v1.txt'),
          ],
          [managed, '-c', _check],
        ]);
        final receipt =
            jsonDecode(
                  await File(
                    p.join(root.path, 'runtime-receipt.json'),
                  ).readAsString(),
                )
                as Map;
        expect(receipt['cuda'], cuda);
      },
    );
  }

  test('an Intel Mac stops before downloading anything', () async {
    final adapter = _Adapter(const []);
    final phases = <String>[];
    final installer = RagRuntimeInstaller(
      root,
      dio: Dio()..httpClientAdapter = adapter,
      probe: _Missing(),
      platform: RagPlatform.macOSX64,
      start: starter(RagPlatform.macOSX64),
    );
    try {
      await expectLater(
        installer.install(cuda: false, onPhase: phases.add),
        throwsA(
          isA<RagException>().having(
            (e) => e.code,
            'code',
            'unsupported_platform',
          ),
        ),
      );
    } finally {
      installer.dispose();
    }
    expect(phases, ['existing']);
    expect(adapter.requests, isEmpty);
    expect(commands, isEmpty);
  });
}

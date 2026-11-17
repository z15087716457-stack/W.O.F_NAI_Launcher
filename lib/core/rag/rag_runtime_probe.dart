import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'rag_platform.dart';
import 'rag_process.dart';

enum RagRuntimeIssue {
  missing,
  dependencies,
  pythonVersion,
  importFailed,
  timedOut,
}

class RagRuntimeInfo {
  const RagRuntimeInfo({
    required this.python,
    required this.ready,
    this.cuda = false,
    this.issue,
    this.packages = const [],
  });
  final String python;
  final bool ready, cuda;
  final RagRuntimeIssue? issue;
  final List<String> packages;
}

typedef RagProbeRunner =
    Future<Process> Function(Directory root, String python, String code);

/// Compatibility is tested with imports, not inferred from a Python executable
/// or a stale receipt. This never installs dependencies or loads model weights.
class RagRuntimeProbe {
  RagRuntimeProbe({
    RagProbeRunner? runner,
    RagPlatform? platform,
    this.timeout = const Duration(seconds: 45),
  }) : platform = platform ?? RagPlatform.host,
       _runner =
           runner ??
           ((root, python, code) => startRagProcess(
             directory: root,
             executable: python,
             arguments: ['-B', '-c', code],
             environment: {
               'PYTHONUTF8': '1',
               'PYTHONIOENCODING': 'utf-8',
               'PYTHONDONTWRITEBYTECODE': '1',
               'HF_HUB_OFFLINE': '1',
               'TRANSFORMERS_OFFLINE': '1',
               'HF_HUB_DISABLE_TELEMETRY': '1',
             },
             platform: platform,
           ));
  final RagPlatform platform;
  final RagProbeRunner _runner;
  final Duration timeout;
  final _processes = <Process>{};
  bool _cancelled = false;
  static const code = '''
import sys,json,importlib.metadata as m
expected={'torch':'2.10.0','torchvision':'0.25.0','transformers':'5.19.0','sentence-transformers':'6.1.0','usearch':'2.26.4','numpy':'2.5.4','Pillow':'12.2.0','jieba':'0.42.1','setuptools':'78.1.0'}
packages=[]
for name,version in expected.items():
    try: compatible=m.version(name).split('+')[0]==version
    except m.PackageNotFoundError: compatible=False
    if not compatible: packages.append(name)
if sys.version_info[:2]!=(3,12):
    result={'ready':False,'issue':'pythonVersion'}
elif packages:
    result={'ready':False,'issue':'dependencies','packages':packages}
else:
    try:
        import torch,torchvision,transformers,sentence_transformers,jieba,usearch.index,numpy,PIL
        from transformers.models.embedding_gemma2 import EmbeddingGemma2Model
        result={'ready':True,'cuda':torch.version.cuda is not None}
    except Exception:
        result={'ready':False,'issue':'importFailed'}
print(json.dumps(result),flush=True)
''';
  Future<RagRuntimeInfo> inspect(Directory root, String preferred) async {
    final managed = platform.managedPython(root.path);
    var failure = RagRuntimeInfo(
      python: preferred.isEmpty ? managed : preferred,
      ready: false,
      issue: RagRuntimeIssue.missing,
    );
    for (final python in {if (preferred.isNotEmpty) preferred, managed}) {
      if (_cancelled || !await File(python).exists()) continue;
      var candidate = RagRuntimeInfo(
        python: python,
        ready: false,
        issue: RagRuntimeIssue.importFailed,
      );
      Process? process;
      try {
        process = await _runner(root, python, code);
        _processes.add(process);
        if (_cancelled) {
          process.kill();
          return RagRuntimeInfo(python: python, ready: false);
        }
        var captured = '';
        final done = Completer<void>();
        final output = process.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .listen(
              (s) {
                if (captured.length < 8192) captured += s;
              },
              onDone: () => done.complete(),
              onError: (Object _) {
                if (!done.isCompleted) done.complete();
              },
            );
        final errors = process.stderr.listen((_) {});
        try {
          final exit = await process.exitCode.timeout(timeout);
          await done.future.timeout(const Duration(seconds: 3));
          if (exit == 0) {
            for (final line in captured.split('\n').reversed) {
              try {
                final value = jsonDecode(line) as Map;
                if (value['ready'] == true) {
                  return RagRuntimeInfo(
                    python: python,
                    ready: true,
                    cuda: value['cuda'] == true,
                  );
                }
                candidate = RagRuntimeInfo(
                  python: python,
                  ready: false,
                  issue:
                      RagRuntimeIssue.values
                          .where((issue) => issue.name == value['issue'])
                          .firstOrNull ??
                      RagRuntimeIssue.importFailed,
                  packages: (value['packages'] as List? ?? const [])
                      .whereType<String>()
                      .toList(),
                );
                break;
              } catch (_) {}
            }
          }
        } finally {
          await output.cancel();
          await errors.cancel();
        }
      } on TimeoutException {
        candidate = RagRuntimeInfo(
          python: python,
          ready: false,
          issue: RagRuntimeIssue.timedOut,
        );
      } catch (_) {
        // A broken manually selected environment may still have a compatible
        // managed installation; report it for explicit reuse instead of repair.
      } finally {
        if (process != null) {
          process.kill();
          _processes.remove(process);
        }
      }
      if (failure.issue == RagRuntimeIssue.missing) failure = candidate;
    }
    return failure;
  }

  void cancel() {
    _cancelled = true;
    for (final process in _processes) {
      process.kill();
    }
  }
}

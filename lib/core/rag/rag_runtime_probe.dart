import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'rag_process.dart';

class RagRuntimeInfo {
  const RagRuntimeInfo({
    required this.python,
    required this.ready,
    this.cuda = false,
  });
  final String python;
  final bool ready, cuda;
}

typedef RagProbeRunner =
    Future<Process> Function(Directory root, String python, String code);

/// Compatibility is tested with imports, not inferred from a Python executable
/// or a stale receipt. This never installs dependencies or loads model weights.
class RagRuntimeProbe {
  RagRuntimeProbe({
    RagProbeRunner? runner,
    this.timeout = const Duration(seconds: 45),
  }) : _runner =
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
           ));
  final RagProbeRunner _runner;
  final Duration timeout;
  final _processes = <Process>{};
  bool _cancelled = false;
  static const code = '''
import sys,json,importlib.metadata as m
import torch,torchvision,transformers,sentence_transformers,usearch.index,numpy,PIL
from transformers.models.embedding_gemma2 import EmbeddingGemma2Model
expected={'torch':'2.10.0','torchvision':'0.25.0','transformers':'5.19.0','sentence-transformers':'6.1.0','usearch':'2.26.4','numpy':'2.5.4','Pillow':'12.2.0'}
ok=sys.version_info[:2]==(3,12) and all(m.version(k).split('+')[0]==v for k,v in expected.items())
print(json.dumps({'ready':ok,'cuda':torch.version.cuda is not None}),flush=True)
''';
  Future<RagRuntimeInfo> inspect(Directory root, String preferred) async {
    final managed = p.join(root.path, 'runtime', 'Scripts', 'python.exe');
    for (final python in {if (preferred.isNotEmpty) preferred, managed}) {
      if (_cancelled || !await File(python).exists()) continue;
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
              } catch (_) {}
            }
          }
        } finally {
          await output.cancel();
          await errors.cancel();
        }
      } catch (_) {
        // A broken manually selected environment may still have a compatible
        // managed installation; report it for explicit reuse instead of repair.
      } finally {
        if (process != null) {
          process.kill();
          _processes.remove(process);
        }
      }
    }
    return RagRuntimeInfo(
      python: preferred.isEmpty ? managed : preferred,
      ready: false,
    );
  }

  void cancel() {
    _cancelled = true;
    for (final process in _processes) {
      process.kill();
    }
  }
}

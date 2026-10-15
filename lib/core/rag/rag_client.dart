import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'rag_process.dart';

class RagException implements Exception {
  const RagException(this.code);
  final String code;
  @override
  String toString() => 'RAG: $code';
}

class RagCancellation {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];
  bool get isCancelled => _cancelled;
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final action in List.of(_listeners)) {
      action();
    }
    _listeners.clear();
  }

  void Function() listen(void Function() action) {
    if (_cancelled) {
      action();
      return () {};
    }
    _listeners.add(action);
    return () => _listeners.remove(action);
  }
}

/// Owns a local JSON worker. No shell interpretation or remote model calls.
class RagClient {
  RagClient(this._process) {
    _stdout = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_receive, onError: (Object _) => _lost(), onDone: _lost);
    _stderr = _process.stderr.listen((_) {});
    unawaited(_process.exitCode.then((_) => _lost()));
    unawaited(_process.stdin.done.catchError((Object _) => _lost()));
  }
  final Process _process;
  StreamSubscription<String>? _stdout;
  StreamSubscription<List<int>>? _stderr;
  final _ready = Completer<void>();
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _events = StreamController<Map<String, dynamic>>.broadcast();
  int _next = 0;
  bool _closed = false;
  bool _closing = false;
  Future<void>? _closeFuture;
  bool get isClosed => _closed;
  Stream<Map<String, dynamic>> get events => _events.stream;

  static Future<RagClient> start({
    required String python,
    required Directory directory,
    Future<String> Function(String)? loadAsset,
  }) async {
    final loader = loadAsset ?? rootBundle.loadString;
    final files = <String, String>{};
    for (final name in [
      'worker.py',
      'engine.py',
      'pool.py',
      'models.py',
      'context.py',
      'documents.py',
      'gallery.py',
    ]) {
      files[name] = await loader('tool/rag/$name');
    }
    final digest = sha256.convert(utf8.encode(jsonEncode(files))).toString();
    final scripts = Directory(p.join(directory.path, 'workers', digest));
    await scripts.create(recursive: true);
    for (final entry in files.entries) {
      final file = File(p.join(scripts.path, entry.key));
      if (!await file.exists() || await file.readAsString() != entry.value) {
        await file.writeAsString(entry.value, flush: true);
      }
    }
    final process = await startRagProcess(
      directory: directory,
      executable: python,
      arguments: ['-u', p.join(scripts.path, 'worker.py')],
      environment: {
        'PYTHONUTF8': '1',
        'PYTHONIOENCODING': 'utf-8',
        'HF_HUB_OFFLINE': '1',
        'TRANSFORMERS_OFFLINE': '1',
        'HF_HUB_DISABLE_TELEMETRY': '1',
      },
    );
    final client = RagClient(process);
    try {
      await client._ready.future.timeout(const Duration(seconds: 30));
    } catch (_) {
      await client.close();
      rethrow;
    }
    return client;
  }

  void _receive(String line) {
    if (_closed) return;
    try {
      final message = (jsonDecode(line) as Map).cast<String, dynamic>();
      if (message['event'] == 'ready') {
        if (!_ready.isCompleted) {
          if (message['protocol'] != 1) {
            _ready.completeError(const RagException('incompatible_runtime'));
          } else {
            _ready.complete();
          }
        }
      } else if (message.containsKey('event')) {
        _events.add(message);
      } else {
        final pending = _pending.remove(message['id']);
        if (pending == null) return;
        if (message['error'] case final Map error) {
          pending.completeError(
            RagException(error['code'] as String? ?? 'worker_error'),
          );
        } else {
          pending.complete((message['result'] as Map).cast<String, dynamic>());
        }
      }
    } catch (_) {
      _lost();
    }
  }

  Future<Map<String, dynamic>> request(
    String op, [
    Map<String, dynamic> params = const {},
    RagCancellation? cancellation,
    Duration timeout = const Duration(seconds: 60),
  ]) async {
    if (_closed) throw const RagException('worker_closed');
    if (cancellation?.isCancelled ?? false) {
      throw const RagException('cancelled');
    }
    final id = ++_next;
    final completion = Completer<Map<String, dynamic>>();
    _pending[id] = completion;
    _send({'id': id, 'op': op, 'params': params});
    final unlisten = cancellation?.listen(() {
      _send({'op': 'cancel', 'target': id});
      _pending.remove(id)?.completeError(const RagException('cancelled'));
    });
    try {
      return await completion.future.timeout(timeout);
    } on TimeoutException {
      _send({'op': 'cancel', 'target': id});
      _pending.remove(id);
      throw const RagException('timeout');
    } finally {
      unlisten?.call();
    }
  }

  void _send(Map<String, dynamic> value) {
    if (!_closed) {
      try {
        _process.stdin.writeln(jsonEncode(value));
      } catch (_) {
        _lost();
      }
    }
  }

  void _lost() {
    if (_closed) return;
    _closed = true;
    if (!_ready.isCompleted) {
      _ready.completeError(const RagException('runtime_missing'));
    }
    for (final pending in _pending.values) {
      pending.completeError(const RagException('worker_closed'));
    }
    _pending.clear();
    _events.add({'event': 'lost'});
    if (!_closing) unawaited(close());
  }

  Future<void> close() {
    if (_closeFuture case final pending?) return pending;
    _closing = true;
    return _closeFuture = _close();
  }

  Future<void> _close() async {
    if (!_closed) {
      _send({'op': 'shutdown'});
    }
    _lost();
    await _stdout?.cancel();
    await _stderr?.cancel();
    try {
      await _process.stdin.close();
    } catch (_) {}
    try {
      await _process.exitCode.timeout(const Duration(seconds: 3));
    } catch (_) {
      _process.kill();
    }
    await _events.close();
  }
}

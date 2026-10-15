import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/autocomplete/completion_models.dart';
import '../../core/database/asset_database_manager.dart';
import '../../core/rag/rag_client.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/rag/rag_runtime.dart';
import '../../core/services/desktop_app_shutdown_service.dart';

class RagStatus {
  const RagStatus({
    this.phase = 'off',
    this.indexed = 0,
    this.processed = 0,
    this.total = 0,
    this.bytes = 0,
    this.jobId,
    this.error,
    this.busy = false,
    this.complete = false,
    this.partial = false,
    this.suspended = false,
    this.searching = 0,
    this.installPhase,
  });
  final String phase;
  final int indexed, processed, total, bytes, searching;
  final String? jobId, error, installPhase;
  final bool busy, complete, partial, suspended;
  bool get available =>
      indexed > 0 && error == null && !suspended && phase != 'off';
  RagStatus copyWith({
    String? phase,
    int? indexed,
    int? processed,
    int? total,
    int? bytes,
    String? jobId,
    String? error,
    bool clearError = false,
    bool clearJob = false,
    bool? busy,
    bool? complete,
    bool? partial,
    bool? suspended,
    int? searching,
    String? installPhase,
    bool clearInstall = false,
  }) => RagStatus(
    phase: phase ?? this.phase,
    indexed: indexed ?? this.indexed,
    processed: processed ?? this.processed,
    total: total ?? this.total,
    bytes: bytes ?? this.bytes,
    jobId: clearJob ? null : jobId ?? this.jobId,
    error: clearError ? null : error ?? this.error,
    busy: busy ?? this.busy,
    complete: complete ?? this.complete,
    partial: partial ?? this.partial,
    suspended: suspended ?? this.suspended,
    searching: searching ?? this.searching,
    installPhase: clearInstall ? null : installPhase ?? this.installPhase,
  );
}

final ragDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory(
        p.join((await getApplicationSupportDirectory()).path, 'rag', 'v1'),
      ),
);
final ragControllerProvider = NotifierProvider<RagController, RagStatus>(
  RagController.new,
);

class RagController extends Notifier<RagStatus> {
  RagClient? _client;
  Future<RagClient>? _connecting;
  StreamSubscription<Map<String, dynamic>>? _events;
  Timer? _refresh;
  RagRuntimeInstaller? _installer;
  bool _disposed = false;
  int _epoch = 0, _gpuHolds = 0;
  final _finishedJobs = <String>{};
  @override
  RagStatus build() {
    final unregister = DesktopAppShutdownService.registerCleanup(() async {
      _refresh?.cancel();
      _installer?.cancel();
      await _client?.close();
    });
    ref.listen(ragSettingsProvider, (previous, next) {
      if (previous?.connectionKey != next.connectionKey) unawaited(_reset());
    });
    ref.onDispose(() {
      unregister();
      _disposed = true;
      _epoch++;
      _refresh?.cancel();
      unawaited(_events?.cancel());
      unawaited(_client?.close());
      _installer?.dispose();
    });
    scheduleMicrotask(() {
      if (!_disposed && _enabled) unawaited(refresh());
    });
    return const RagStatus();
  }

  bool get _enabled {
    final s = ref.read(ragSettingsProvider);
    return s.enabled && s.tagsEnabled;
  }

  Future<void> _reset() async {
    final epoch = ++_epoch;
    _refresh?.cancel();
    _connecting = null;
    _finishedJobs.clear();
    final old = _client;
    _client = null;
    await _events?.cancel();
    await old?.close();
    if (_disposed || epoch != _epoch) return;
    state = const RagStatus();
    if (_enabled) await refresh();
  }

  Future<RagClient> _connect() {
    if (!_enabled) return Future.error(const RagException('disabled'));
    if (_client case final client? when !client.isClosed) {
      return Future.value(client);
    }
    if (_connecting case final pending?) return pending;
    late final Future<RagClient> attempt;
    attempt = _open().whenComplete(() {
      if (identical(_connecting, attempt)) _connecting = null;
    });
    return _connecting = attempt;
  }

  Future<RagClient> _open() async {
    final epoch = _epoch;
    final settings = ref.read(ragSettingsProvider);
    final root = await ref.read(ragDirectoryProvider)();
    final python = settings.python.isEmpty
        ? p.join(root.path, 'runtime', 'Scripts', 'python.exe')
        : settings.python;
    if (!await File(python).exists()) {
      throw const RagException('runtime_missing');
    }
    if (settings.embedding.isEmpty || settings.reranker.isEmpty) {
      throw const RagException('models_missing');
    }
    if (!_disposed && epoch == _epoch) {
      state = state.copyWith(phase: 'loading', clearError: true);
    }
    await AssetDatabaseManager.initialize();
    final support = await getApplicationSupportDirectory();
    final runtime = File(p.join(support.path, 'databases', 'danbooru.db'));
    final client = await RagClient.start(python: python, directory: root);
    try {
      final result = await client.request('configure', {
        'embedding': settings.embedding,
        'reranker': settings.reranker,
        'device': settings.device.name,
        'directory': p.join(root.path, 'indices'),
        'catalog': AssetDatabaseManager.instance.tagCatalogDbPath,
        'runtime': await runtime.exists() ? runtime.path : '',
        'wiki': await AssetDatabaseManager.instance.ensureTagWikiDb(),
      });
      if (_disposed || epoch != _epoch) throw const RagException('cancelled');
      _client = client;
      _events = client.events.listen((event) {
        if (_disposed || epoch != _epoch) return;
        if (event['event'] == 'lost') {
          state = state.copyWith(
            phase: 'error',
            error: 'worker_closed',
            busy: false,
            clearJob: true,
          );
          return;
        }
        if (event['event'] == 'index') {
          if (['complete', 'error'].contains(event['phase'])) {
            _finishedJobs.add(event['job_id'] as String);
            if (_finishedJobs.length > 32) {
              _finishedJobs.remove(_finishedJobs.first);
            }
          }
          _apply(event);
          state = state.copyWith(
            jobId: event['job_id'] as String?,
            phase: event['phase'] == 'complete'
                ? (state.complete ? 'ready' : 'partial')
                : event['phase'] as String?,
            busy: event['phase'] == 'building',
            clearJob: ['complete', 'error'].contains(event['phase']),
            error: event['code'] as String?,
            clearError: event['phase'] != 'error',
          );
        }
      });
      _apply(result);
      _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!_disposed && !state.busy) unawaited(refresh(autoUpdate: true));
      });
      if (_gpuHolds > 0) {
        state = state.copyWith(suspended: true);
        await client.request('suspend');
      }
      return client;
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  void _apply(Map<String, dynamic> result) {
    if (_disposed) return;
    state = state.copyWith(
      indexed: (result['indexed'] as num?)?.toInt(),
      processed: (result['processed'] as num?)?.toInt(),
      total: (result['total'] as num?)?.toInt(),
      bytes: (result['bytes'] as num?)?.toInt(),
      complete: result['complete'] as bool?,
      partial: result['partial'] as bool?,
      busy: result['building'] as bool?,
      suspended: result['suspended'] as bool?,
      phase: result['complete'] == true
          ? 'ready'
          : (result['indexed'] as num? ?? 0) > 0
          ? 'partial'
          : 'empty',
      clearError: true,
    );
    if (result['paused'] == true) {
      state = state.copyWith(phase: 'paused', busy: false);
    }
  }

  void _fail(Object error) {
    if (_disposed) return;
    state = state.copyWith(
      phase: 'error',
      error: error is RagException ? error.code : 'rag_runtime_error',
      busy: false,
    );
  }

  Future<void> refresh({bool autoUpdate = false}) async {
    if (!_enabled || _disposed) return;
    final epoch = _epoch;
    try {
      final c = await _connect();
      final status = await c.request('status');
      if (_disposed || epoch != _epoch) return;
      _apply(status);
      if (autoUpdate &&
          status['auto_update_allowed'] == true &&
          status['complete'] != true &&
          state.jobId == null &&
          !state.suspended &&
          _gpuHolds == 0) {
        final plan = await c.request('preview');
        await start(plan['plan_id'] as String);
      }
    } catch (error) {
      if (epoch == _epoch) _fail(error);
    }
  }

  Future<Map<String, dynamic>> preview() async {
    final c = await _connect();
    return c.request('preview');
  }

  Future<void> start(String planId, {bool rebuild = false}) async {
    final epoch = _epoch;
    try {
      final c = await _connect();
      if (rebuild) await c.request('clear');
      final result = await c.request('start', {'plan_id': planId});
      if (!_disposed &&
          epoch == _epoch &&
          !_finishedJobs.contains(result['job_id'])) {
        state = state.copyWith(
          jobId: result['job_id'] as String,
          phase: 'building',
          processed: 0,
          busy: true,
          clearError: true,
        );
      }
    } catch (error) {
      if (epoch == _epoch) _fail(error);
      rethrow;
    }
  }

  Future<void> pause() async {
    final epoch = _epoch;
    final id = state.jobId;
    if (id == null) return;
    await (await _connect()).request('pause', {'job_id': id});
    if (!_disposed && epoch == _epoch) {
      state = state.copyWith(phase: 'paused', busy: false);
    }
  }

  Future<void> resume() async {
    final epoch = _epoch;
    final id = state.jobId;
    if (id == null) {
      final p = await preview();
      await start(p['plan_id'] as String);
      return;
    }
    await (await _connect()).request('resume', {'job_id': id});
    if (!_disposed && epoch == _epoch) {
      state = state.copyWith(phase: 'building', busy: true);
    }
  }

  Future<void> clear() async {
    final epoch = _epoch;
    final c = await _connect();
    final result = await c.request('clear');
    if (_disposed || epoch != _epoch) return;
    _apply(result);
    state = state.copyWith(clearJob: true);
  }

  Future<void> suspendForGpu() async {
    _gpuHolds++;
    final c = _client;
    if (c == null) return;
    try {
      await c.request('suspend', {}, null, const Duration(seconds: 15));
    } catch (_) {
      await c.close();
      _client = null;
    }
    if (!_disposed) state = state.copyWith(suspended: true);
  }

  Future<void> releaseGpu() async {
    if (_gpuHolds > 0) _gpuHolds--;
    if (_gpuHolds != 0) return;
    final c = _client;
    if (c != null && !c.isClosed) await c.request('release');
    if (!_disposed) state = state.copyWith(suspended: false);
  }

  Future<List<CompletionCandidate>> recommend({
    required String text,
    required int cursor,
    required Set<String> existing,
    required List<CompletionCandidate> lexical,
    required RagCancellation cancellation,
    bool negative = false,
    String keyword = '',
    int limit = 40,
  }) async {
    if (!_enabled || _gpuHolds > 0) return const [];
    final epoch = _epoch;
    var counted = false;
    try {
      final c = await _connect();
      if (cancellation.isCancelled) return const [];
      if (!_disposed) {
        counted = true;
        state = state.copyWith(searching: state.searching + 1);
      }
      final result = await c.request('search', {
        'text': text,
        'cursor': cursor,
        'mode': ref.read(ragSettingsProvider).mode.name,
        'existing': existing.toList(),
        'lexical': lexical.map((e) => e.canonicalTag).toList(),
        'negative': negative,
        'keyword': keyword,
        'limit': limit,
      }, cancellation);
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      return [
        for (final raw in result['items'] as List? ?? const [])
          CompletionCandidate(
            canonicalTag: raw['name'] as String,
            category:
                TagCategory.fromCatalog(raw['category'] as int) ??
                TagCategory.general,
            postCount: (raw['post_count'] as num).toInt(),
            aliases: List<String>.from(raw['aliases'] as List),
            matchKind: CompletionMatchKind.related,
            sources: const {CompletionSourceKind.base},
          ),
      ];
    } catch (error) {
      if (epoch == _epoch &&
          !(error is RagException && error.code == 'cancelled')) {
        _fail(error);
      }
      return const [];
    } finally {
      if (counted && !_disposed && epoch == _epoch) {
        state = state.copyWith(searching: (state.searching - 1).clamp(0, 100));
      }
    }
  }

  Future<void> installRuntime({required bool cuda}) async {
    if (_installer != null) return;
    final installer = _installer = RagRuntimeInstaller(
      await ref.read(ragDirectoryProvider)(),
    );
    try {
      final python = await installer.install(
        cuda: cuda,
        onPhase: (phase) {
          if (!_disposed) {
            state = state.copyWith(installPhase: phase, clearError: true);
          }
        },
      );
      if (!_disposed) {
        await ref
            .read(ragSettingsProvider.notifier)
            .update(ref.read(ragSettingsProvider).copyWith(python: python));
      }
    } catch (error) {
      _fail(error);
    } finally {
      installer.dispose();
      _installer = null;
      if (!_disposed) state = state.copyWith(clearInstall: true);
    }
  }

  void cancelInstall() => _installer?.cancel();
}

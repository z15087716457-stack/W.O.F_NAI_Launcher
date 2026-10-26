import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/utils/app_logger.dart';
import '../../models/gallery/nai_image_metadata.dart';
import 'unified_metadata_parser.dart';

bool metadataResponseMatchesActiveRequest({
  required int? activeRequestId,
  required int responseRequestId,
}) {
  return activeRequestId != null && activeRequestId == responseRequestId;
}

typedef MetadataWorkerInitializer =
    Future<void> Function(
      int workerId,
      Future<void> Function() initializeWorker,
    );

/// Isolate 解析配置
class IsolateParseConfig {
  final Duration timeout;
  final bool useGradualRead;
  final bool useCache;

  const IsolateParseConfig({
    this.timeout = const Duration(seconds: 5),
    this.useGradualRead = true,
    this.useCache = true,
  });
}

/// Isolate 解析结果
class IsolateParseResult {
  final NaiImageMetadata? metadata;
  final String? error;
  final Duration parseTime;
  final int? bytesRead;

  /// worker 在同次文件读取中顺带算出的 SHA256（未请求或读取失败时为 null）
  final String? fileHash;

  /// 哈希算好后按调用方决策跳过解析（缓存命中场景），metadata 为 null 属预期
  final bool wasSkipped;

  final bool wasCancelled;
  final bool wasTimeout;

  const IsolateParseResult({
    this.metadata,
    this.error,
    required this.parseTime,
    this.bytesRead,
    this.fileHash,
    this.wasSkipped = false,
    this.wasCancelled = false,
    this.wasTimeout = false,
  });

  bool get success => metadata != null;

  factory IsolateParseResult.success(
    NaiImageMetadata metadata, {
    required Duration parseTime,
    int? bytesRead,
    String? fileHash,
  }) {
    return IsolateParseResult(
      metadata: metadata,
      parseTime: parseTime,
      bytesRead: bytesRead,
      fileHash: fileHash,
    );
  }

  factory IsolateParseResult.error(
    String error, {
    required Duration parseTime,
    bool wasCancelled = false,
    bool wasTimeout = false,
    String? fileHash,
  }) {
    return IsolateParseResult(
      error: error,
      parseTime: parseTime,
      fileHash: fileHash,
      wasCancelled: wasCancelled,
      wasTimeout: wasTimeout,
    );
  }

  /// 哈希已算出但按调用方决策跳过解析（缓存命中）
  factory IsolateParseResult.skipped(String fileHash) {
    return IsolateParseResult(
      fileHash: fileHash,
      wasSkipped: true,
      parseTime: Duration.zero,
    );
  }
}

/// Isolate 元数据解析服务
///
/// 在独立线程中执行 PNG 元数据解析，避免阻塞 UI。
/// 适用于详情页等需要实时响应的场景。
///
/// 特性：
/// - 支持解析超时控制
/// - 支持任务取消
/// - 详细的错误信息
/// - 性能统计
/// - 哈希先行两阶段模式（[parseMetadataWithHash]）：worker 单次读取文件
///   先算 SHA256 回传，调用方按哈希查缓存后再决定是否继续解析
class IsolateMetadataService {
  static IsolateMetadataService? _instance;
  static IsolateMetadataService get instance =>
      _instance ??= IsolateMetadataService._internal();

  IsolateMetadataService._internal({
    MetadataWorkerInitializer? workerInitializer,
  }) : _workerInitializer = workerInitializer;

  IsolateMetadataService.forTesting({
    MetadataWorkerInitializer? workerInitializer,
  }) : _workerInitializer = workerInitializer;

  final MetadataWorkerInitializer? _workerInitializer;

  /// 解析线程池（最多2个线程并发）
  final List<_ParseWorker> _workers = [];
  final int _maxWorkers = 2;

  /// 任务队列
  final List<_ParseTask> _taskQueue = [];
  int _nextRequestId = 1;

  /// 是否已初始化
  bool _initialized = false;
  Future<void>? _initialization;
  int _lifecycle = 0;
  String? _workerStartupError;

  /// 统计信息
  int _totalTasks = 0;
  int _successfulTasks = 0;
  int _failedTasks = 0;
  int _cancelledTasks = 0;
  int _timeoutTasks = 0;

  /// 初始化服务
  Future<void> initialize() {
    if (_initialized) return Future.value();
    return _initialization ??= _initialize(_lifecycle);
  }

  Future<void> _initialize(int lifecycle) async {
    AppLogger.i(
      '[IsolateMetadata] Initializing with $_maxWorkers workers',
      'IsolateMetadataService',
    );

    _workerStartupError = null;

    final initializedWorkers = <_ParseWorker>[];
    _ParseWorker? pendingWorker;

    try {
      // 创建工作线程
      for (int i = 0; i < _maxWorkers; i++) {
        pendingWorker = _ParseWorker(id: i, onBecameIdle: _processQueue);
        final initializeWorker = pendingWorker.initialize;

        if (_workerInitializer != null) {
          await _workerInitializer(i, initializeWorker);
        } else {
          await initializeWorker();
        }

        initializedWorkers.add(pendingWorker);
        pendingWorker = null;
        if (lifecycle != _lifecycle) {
          for (final worker in initializedWorkers) {
            worker.dispose();
          }
          return;
        }
      }

      _workers.addAll(initializedWorkers);

      AppLogger.i('[IsolateMetadata] Initialized', 'IsolateMetadataService');
    } catch (e, stackTrace) {
      pendingWorker?.dispose();
      for (final worker in initializedWorkers) {
        worker.dispose();
      }
      if (lifecycle != _lifecycle) return;
      _workers.clear();
      _taskQueue.clear();
      _workerStartupError = e.toString();

      AppLogger.e(
        '[IsolateMetadata] Worker startup failed',
        e,
        stackTrace,
        'IsolateMetadataService',
      );
    }

    _initialized = true;
  }

  /// 解析元数据（Isolate 中执行）
  ///
  /// [filePath] PNG 文件路径
  /// [config] 解析配置（超时、渐进式读取等）
  /// 返回解析结果，失败返回带错误信息的结果
  Future<IsolateParseResult> parseMetadata(
    String filePath, {
    IsolateParseConfig config = const IsolateParseConfig(),
  }) {
    return _dispatch(filePath, config: config, hashDecider: null);
  }

  /// 哈希先行解析：worker 单次读取文件先算 SHA256，再由调用方决策是否继续
  ///
  /// 与 [parseMetadata] 的区别：worker 先只读一次文件算 SHA256 并回传
  /// （结果见 [IsolateParseResult.fileHash]），[shouldParseWithHash] 在主
  /// isolate 上同步调用——返回 false 时 worker 丢弃已读取的字节不再解析
  /// （缓存命中场景，结果 [IsolateParseResult.wasSkipped] 为 true）；返回
  /// true 时复用同次读取的字节继续解析，全程只读一次文件。
  Future<IsolateParseResult> parseMetadataWithHash(
    String filePath, {
    IsolateParseConfig config = const IsolateParseConfig(),
    required bool Function(String hash) shouldParseWithHash,
  }) {
    return _dispatch(
      filePath,
      config: config,
      hashDecider: shouldParseWithHash,
    );
  }

  Future<IsolateParseResult> _dispatch(
    String filePath, {
    required IsolateParseConfig config,
    required bool Function(String hash)? hashDecider,
  }) async {
    final lifecycle = _lifecycle;
    final stopwatch = Stopwatch()..start();
    _totalTasks++;
    await initialize();
    if (lifecycle != _lifecycle) {
      _cancelledTasks++;
      return IsolateParseResult.error(
        'Cancelled during worker startup',
        parseTime: stopwatch.elapsed,
        wasCancelled: true,
      );
    }

    if (_workers.isEmpty) {
      _failedTasks++;
      return IsolateParseResult.error(
        'Metadata workers unavailable: $_workerStartupError',
        parseTime: stopwatch.elapsed,
      );
    }

    final task = _ParseTask(
      requestId: _nextRequestId++,
      filePath: filePath,
      config: config,
      startTime: DateTime.now(),
      hashDecider: hashDecider,
    );

    // 寻找空闲工作线程
    _ParseWorker? worker;
    try {
      worker = _workers.firstWhere(
        (w) => !w.isBusy,
        orElse: () {
          // 所有线程都忙，加入队列等待
          _taskQueue.add(task);
          AppLogger.d(
            '[IsolateMetadata] All workers busy, task queued: $filePath',
            'IsolateMetadataService',
          );
          throw _NoIdleWorkerException();
        },
      );
    } on _NoIdleWorkerException {
      // 等待队列中的任务被执行
      return _waitForTask(task, stopwatch);
    }

    // 执行任务
    return _executeTask(worker, task, stopwatch);
  }

  /// 快速解析（用于详情页）
  ///
  /// 使用较小的读取限制和较短超时，优先响应速度
  Future<NaiImageMetadata?> parseForDetailView(String filePath) async {
    final stopwatch = Stopwatch()..start();

    AppLogger.i(
      '[IsolateMetadata] Detail view parse START: $filePath',
      'IsolateMetadataService',
    );

    try {
      final result = await parseMetadata(
        filePath,
        config: const IsolateParseConfig(
          timeout: Duration(seconds: 3),
          useGradualRead: true,
        ),
      );

      stopwatch.stop();

      if (result.success) {
        AppLogger.i(
          '[IsolateMetadata] Detail view parse COMPLETED (${stopwatch.elapsedMilliseconds}ms): success',
          'IsolateMetadataService',
        );
        return result.metadata;
      } else {
        AppLogger.w(
          '[IsolateMetadata] Detail view parse FAILED (${stopwatch.elapsedMilliseconds}ms): ${result.error}',
          'IsolateMetadataService',
        );
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.e(
        '[IsolateMetadata] Detail view parse ERROR (${stopwatch.elapsedMilliseconds}ms)',
        e,
        null,
        'IsolateMetadataService',
      );
      return null;
    }
  }

  /// 完整解析（用于编辑等场景）
  ///
  /// 使用完整文件读取和较长超时，确保获取完整元数据
  Future<NaiImageMetadata?> parseForEdit(String filePath) async {
    final stopwatch = Stopwatch()..start();

    AppLogger.i(
      '[IsolateMetadata] Edit parse START: $filePath',
      'IsolateMetadataService',
    );

    try {
      final result = await parseMetadata(
        filePath,
        config: const IsolateParseConfig(
          timeout: Duration(seconds: 10),
          useGradualRead: false, // 编辑场景使用完整文件
        ),
      );

      stopwatch.stop();

      if (result.success) {
        AppLogger.i(
          '[IsolateMetadata] Edit parse COMPLETED (${stopwatch.elapsedMilliseconds}ms)',
          'IsolateMetadataService',
        );
        return result.metadata;
      } else {
        AppLogger.w(
          '[IsolateMetadata] Edit parse FAILED: ${result.error}',
          'IsolateMetadataService',
        );
        return null;
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.e(
        '[IsolateMetadata] Edit parse ERROR',
        e,
        null,
        'IsolateMetadataService',
      );
      return null;
    }
  }

  /// 取消所有进行中的任务
  void cancelAll() {
    AppLogger.d(
      '[IsolateMetadata] Cancelling all tasks',
      'IsolateMetadataService',
    );
    final queuedTasks = List<_ParseTask>.from(_taskQueue);
    _taskQueue.clear();
    _cancelledTasks += queuedTasks.length;

    for (final task in queuedTasks) {
      _completeTask(
        task,
        IsolateParseResult.error(
          'Cancelled',
          parseTime: Duration.zero,
          wasCancelled: true,
        ),
      );
    }

    for (final worker in _workers) {
      worker.cancelCurrent();
    }
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() => {
    'totalTasks': _totalTasks,
    'successfulTasks': _successfulTasks,
    'failedTasks': _failedTasks,
    'cancelledTasks': _cancelledTasks,
    'timeoutTasks': _timeoutTasks,
    'successRate': _totalTasks > 0 ? _successfulTasks / _totalTasks : 0.0,
    'activeWorkers': _workers.where((w) => w.isBusy).length,
    'queuedTasks': _taskQueue.length,
    'workerStartupError': _workerStartupError,
  };

  /// 重置统计
  void resetStatistics() {
    _totalTasks = 0;
    _successfulTasks = 0;
    _failedTasks = 0;
    _cancelledTasks = 0;
    _timeoutTasks = 0;
  }

  /// 销毁服务
  void dispose() {
    AppLogger.i(
      '[IsolateMetadata] Disposing service',
      'IsolateMetadataService',
    );
    cancelAll();
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    _initialized = false;
    _initialization = null;
    _lifecycle++;
    _workerStartupError = null;
  }

  // ==================== 私有方法 ====================

  Future<IsolateParseResult> _executeTask(
    _ParseWorker worker,
    _ParseTask task,
    Stopwatch stopwatch,
  ) async {
    try {
      final result = await worker
          .execute(task, hashDecider: task.hashDecider)
          .timeout(
            task.config.timeout,
            onTimeout: () {
              _timeoutTasks++;
              // 两阶段任务超时后解除 worker 侧挂起态：完成等待中的
              // completer 并通知 worker 丢弃保留的字节，避免永久卡死
              worker.abandonPending(task.requestId);
              AppLogger.w(
                '[IsolateMetadata] Task timeout: ${task.filePath}',
                'IsolateMetadataService',
              );
              return IsolateParseResult.error(
                'Parse timeout after ${task.config.timeout.inSeconds}s',
                parseTime: stopwatch.elapsed,
                wasTimeout: true,
              );
            },
          );

      stopwatch.stop();

      if (result.success) {
        _successfulTasks++;
      } else if (result.wasCancelled) {
        _cancelledTasks++;
      } else if (!result.wasSkipped) {
        _failedTasks++;
      }

      _completeTask(task, result);

      // 处理队列中的下一个任务
      _processQueue();

      return result;
    } catch (e) {
      stopwatch.stop();
      _failedTasks++;
      AppLogger.e(
        '[IsolateMetadata] Task execution error: $e',
        e,
        null,
        'IsolateMetadataService',
      );

      final result = IsolateParseResult.error(
        'Execution error: $e',
        parseTime: stopwatch.elapsed,
      );
      _completeTask(task, result);

      // 处理队列中的下一个任务
      _processQueue();

      return result;
    }
  }

  Future<IsolateParseResult> _waitForTask(
    _ParseTask task,
    Stopwatch stopwatch,
  ) async {
    return task.completer.future.timeout(
      task.config.timeout,
      onTimeout: () {
        _taskQueue.remove(task);
        _timeoutTasks++;
        final result = IsolateParseResult.error(
          'Queue timeout after ${task.config.timeout.inSeconds}s',
          parseTime: stopwatch.elapsed,
          wasTimeout: true,
        );
        _completeTask(task, result);
        return result;
      },
    );
  }

  void _processQueue() {
    if (_taskQueue.isEmpty) return;

    // 寻找空闲工作线程
    final worker = _workers.cast<_ParseWorker?>().firstWhere(
      (w) => !(w?.isBusy ?? true),
      orElse: () => null,
    );

    if (worker != null) {
      final task = _taskQueue.removeAt(0);
      unawaited(_executeTask(worker, task, Stopwatch()..start()));
    }
  }

  void _completeTask(_ParseTask task, IsolateParseResult result) {
    if (!task.completer.isCompleted) {
      task.completer.complete(result);
    }
  }
}

/// 无空闲工作线程异常
class _NoIdleWorkerException implements Exception {}

/// 解析任务
class _ParseTask {
  final int requestId;
  final String filePath;
  final IsolateParseConfig config;
  final DateTime startTime;

  /// 非 null 时走哈希先行两阶段：先算 SHA256，回调决策后才解析
  final bool Function(String hash)? hashDecider;

  final Completer<IsolateParseResult> completer;

  _ParseTask({
    required this.requestId,
    required this.filePath,
    required this.config,
    required this.startTime,
    this.hashDecider,
  }) : completer = Completer<IsolateParseResult>();
}

/// 解析工作线程
class _ParseWorker {
  final int id;
  final void Function()? onBecameIdle;
  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();
  bool _isBusy = false;
  int? _currentRequestId;
  Completer<IsolateParseResult>? _currentCompleter;
  Completer<String?>? _hashCompleter;
  bool _wasAbandoned = false;
  StreamSubscription? _subscription;

  _ParseWorker({required this.id, this.onBecameIdle});

  bool get isBusy => _isBusy;

  /// 初始化工作线程
  Future<void> initialize() async {
    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _WorkerInitMessage(sendPort: _receivePort.sendPort, workerId: id),
      debugName: 'MetadataWorker-$id',
    );

    // 将 ReceivePort 转换为广播流，允许多次监听
    final broadcastStream = _receivePort.asBroadcastStream();

    // 等待工作线程就绪（获取第一个消息 - SendPort）
    _sendPort = await broadcastStream.first as SendPort;

    // 监听后续响应
    _subscription = broadcastStream.listen(_handleResponse);
  }

  /// 执行解析任务
  ///
  /// [hashDecider] 为 null 时走原有单阶段流程；否则走两阶段：worker 先
  /// 单次读取算出 SHA256 回传，[hashDecider] 同步决策后再继续解析或丢弃。
  Future<IsolateParseResult> execute(
    _ParseTask task, {
    bool Function(String hash)? hashDecider,
  }) async {
    if (_isBusy) {
      throw StateError('Worker $id is busy');
    }

    _isBusy = true;
    _currentRequestId = task.requestId;
    _currentCompleter = null;
    _hashCompleter = null;
    _wasAbandoned = false;

    // 单阶段任务与原实现一致：进函数即建立 completer，取消可即时命中
    final bool twoPhase = hashDecider != null;
    if (!twoPhase) {
      _currentCompleter = Completer<IsolateParseResult>();
    }

    try {
      // 读取文件字节
      final file = File(task.filePath);
      if (!await file.exists()) {
        AppLogger.w(
          '[IsolateMetadata] File not found: ${task.filePath}',
          'IsolateMetadataService',
        );
        return IsolateParseResult.error(
          'File not found: ${task.filePath}',
          parseTime: Duration.zero,
        );
      }

      // 渐进式读取场景：文件读取也交给 Isolate（worker 内用 filePath 读），
      // UI isolate 只传路径，避免大文件字节拷贝阻塞
      final bool readInIsolate =
          task.config.useGradualRead && task.filePath.isNotEmpty;

      if (twoPhase) {
        // ===== 两阶段：哈希先行 =====
        final hashCompleter = Completer<String?>();
        _hashCompleter = hashCompleter;
        _sendPort!.send(
          _ParseRequest(
            requestId: task.requestId,
            bytes: readInIsolate ? Uint8List(0) : await file.readAsBytes(),
            filePath: task.filePath,
            config: task.config,
            hashOnly: true,
          ),
        );

        // 等待超时/取消可能在文件检查与请求送达之间发生
        if (_wasAbandoned) {
          _sendPort!.send(
            _ParseContinueRequest(requestId: task.requestId, proceed: false),
          );
          return IsolateParseResult.error(
            'Abandoned',
            parseTime: Duration.zero,
            wasCancelled: true,
          );
        }

        final hash = await hashCompleter.future;
        _hashCompleter = null;

        if (_wasAbandoned) {
          return IsolateParseResult.error(
            'Abandoned',
            parseTime: Duration.zero,
            wasCancelled: true,
          );
        }

        if (hash == null) {
          // 哈希失败同样要通知 worker 丢弃保留的字节
          _sendPort!.send(
            _ParseContinueRequest(requestId: task.requestId, proceed: false),
          );
          return IsolateParseResult.error(
            'Hash calculation failed: ${task.filePath}',
            parseTime: Duration.zero,
          );
        }

        bool shouldParse;
        try {
          shouldParse = hashDecider(hash);
        } catch (_) {
          shouldParse = true;
        }

        if (!shouldParse) {
          _sendPort!.send(
            _ParseContinueRequest(requestId: task.requestId, proceed: false),
          );
          return IsolateParseResult.skipped(hash);
        }

        final parseCompleter = Completer<IsolateParseResult>();
        _currentCompleter = parseCompleter;
        _sendPort!.send(
          _ParseContinueRequest(requestId: task.requestId, proceed: true),
        );
        final parseResult = await parseCompleter.future;
        // 补挂哈希：调用方需要用它与缓存键对齐
        return IsolateParseResult(
          metadata: parseResult.metadata,
          error: parseResult.error,
          parseTime: parseResult.parseTime,
          bytesRead: parseResult.bytesRead,
          fileHash: hash,
          wasCancelled: parseResult.wasCancelled,
          wasTimeout: parseResult.wasTimeout,
        );
      }

      // ===== 单阶段（原有流程）=====
      _sendPort!.send(
        _ParseRequest(
          requestId: task.requestId,
          bytes: readInIsolate ? Uint8List(0) : await file.readAsBytes(),
          filePath: task.filePath,
          config: task.config,
        ),
      );

      // 等待结果
      return await _currentCompleter!.future;
    } finally {
      _isBusy = false;
      _currentRequestId = null;
      _currentCompleter = null;
      _hashCompleter = null;
      _wasAbandoned = false;
      if (onBecameIdle != null) {
        scheduleMicrotask(onBecameIdle!);
      }
    }
  }

  /// 放弃挂起任务（超时/取消时调用）
  ///
  /// 完成等待中的 completer 并通知 worker 丢弃两阶段保留的字节，防止
  /// 任务卡在"等哈希决策"或"等解析结果"状态导致 worker 永久占用。
  void abandonPending(int requestId) {
    _wasAbandoned = true;
    if (_hashCompleter != null && !_hashCompleter!.isCompleted) {
      _hashCompleter!.complete(null);
    }
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete(
        IsolateParseResult.error(
          'Cancelled',
          parseTime: Duration.zero,
          wasCancelled: true,
        ),
      );
    }
    _sendPort?.send(
      _ParseContinueRequest(requestId: requestId, proceed: false),
    );
  }

  /// 取消当前任务
  void cancelCurrent() {
    final requestId = _currentRequestId;
    if (requestId != null) {
      abandonPending(requestId);
    }
  }

  /// 销毁工作线程
  void dispose() {
    cancelCurrent();
    _subscription?.cancel();
    _subscription = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort.close();
  }

  void _handleResponse(dynamic message) {
    if (message is _HashReadyResponse) {
      final completer = _hashCompleter;
      if (completer != null &&
          !completer.isCompleted &&
          metadataResponseMatchesActiveRequest(
            activeRequestId: _currentRequestId,
            responseRequestId: message.requestId,
          )) {
        if (message.error != null) {
          AppLogger.d(
            '[IsolateMetadata] Hash phase error for request ${message.requestId}: ${message.error}',
            'IsolateMetadataService',
          );
          completer.complete(null);
        } else {
          completer.complete(message.hash);
        }
      }
      return;
    }

    if (message is _ParseResponse &&
        _currentCompleter != null &&
        metadataResponseMatchesActiveRequest(
          activeRequestId: _currentRequestId,
          responseRequestId: message.requestId,
        )) {
      if (!_currentCompleter!.isCompleted) {
        if (message.error != null) {
          _currentCompleter!.complete(
            IsolateParseResult.error(
              message.error!,
              parseTime: message.parseTime,
              wasCancelled: message.wasCancelled,
            ),
          );
        } else if (message.metadata != null) {
          _currentCompleter!.complete(
            IsolateParseResult.success(
              message.metadata!,
              parseTime: message.parseTime,
              bytesRead: message.bytesRead,
            ),
          );
        } else {
          _currentCompleter!.complete(
            IsolateParseResult.error(
              'Unknown error',
              parseTime: message.parseTime,
            ),
          );
        }
      }
    } else if (message is _ParseResponse) {
      AppLogger.d(
        '[IsolateMetadata] Ignored stale response for request ${message.requestId}; active request is $_currentRequestId',
        'IsolateMetadataService',
      );
    }
  }
}

/// 两阶段保留的待解析上下文（worker isolate 内）
class _RetainedParseContext {
  final Uint8List bytes;
  final bool useGradualRead;
  final String filePath;

  const _RetainedParseContext({
    required this.bytes,
    required this.useGradualRead,
    required this.filePath,
  });
}

/// worker isolate 内两阶段挂起任务的字节保留表
///
/// 每个 worker 同一时刻只处理一个任务，正常情况下至多一条记录；
/// 超时/取消由主 isolate 发 [_ParseContinueRequest]（proceed=false）清理。
final _retainedParseContexts = <int, _RetainedParseContext>{};

/// Isolate 入口点
void _isolateEntryPoint(_WorkerInitMessage initMsg) {
  final receivePort = ReceivePort();
  initMsg.sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is _ParseRequest) {
      _handleParseRequest(message, initMsg.sendPort);
    } else if (message is _ParseContinueRequest) {
      _handleParseContinue(message, initMsg.sendPort);
    }
  });
}

/// 处理解析请求
///
/// [request.hashOnly] 为 true 时只完成"读文件 + 算 SHA256 + 保留字节"，
/// 回传 [_HashReadyResponse] 后等待 [_ParseContinueRequest] 指令；否则走
/// 原有单阶段流程。
void _handleParseRequest(_ParseRequest request, SendPort sendPort) {
  final stopwatch = Stopwatch()..start();

  if (request.hashOnly) {
    try {
      final bool readInIsolate =
          request.config.useGradualRead && request.filePath.isNotEmpty;
      final bytes = readInIsolate
          ? File(request.filePath).readAsBytesSync()
          : request.bytes;
      final fileHash = sha256.convert(bytes).toString();
      _retainedParseContexts[request.requestId] = _RetainedParseContext(
        bytes: bytes,
        useGradualRead: request.config.useGradualRead,
        filePath: request.filePath,
      );
      sendPort.send(
        _HashReadyResponse(requestId: request.requestId, hash: fileHash),
      );
    } catch (e) {
      stopwatch.stop();
      sendPort.send(
        _HashReadyResponse(
          requestId: request.requestId,
          error: 'Hash calculation error: $e',
        ),
      );
    }
    return;
  }

  try {
    // 渐进式读取场景：在 Isolate 内直接读文件解析（读文件 + 解码全部卸载到
    // worker，UI isolate 零负担；对剥 tEXt 的 PNG 尤其关键——全图解码 +
    // LSB 逐像素读取都在 worker 里执行）
    final bool readInIsolate =
        request.config.useGradualRead && request.filePath.isNotEmpty;
    final result = readInIsolate
        ? UnifiedMetadataParser.parseFromFile(
            request.filePath,
            useGradualRead: true,
            useCache: false,
          )
        : UnifiedMetadataParser.parseFromImageBytes(
            request.bytes,
            filePathForLog: request.filePath,
          );

    stopwatch.stop();

    if (result.metadataAbsent || (result.success && result.metadata != null)) {
      sendPort.send(
        _ParseResponse(
          requestId: request.requestId,
          metadata: result.metadata ?? const NaiImageMetadata(),
          parseTime: stopwatch.elapsed,
          bytesRead: readInIsolate ? null : request.bytes.length,
          wasCancelled: false,
        ),
      );
    } else {
      sendPort.send(
        _ParseResponse(
          requestId: request.requestId,
          error: result.errorMessage ?? 'Failed to parse metadata',
          parseTime: stopwatch.elapsed,
          wasCancelled: false,
        ),
      );
    }
  } catch (e) {
    stopwatch.stop();
    sendPort.send(
      _ParseResponse(
        requestId: request.requestId,
        error: 'Isolate parse error: $e',
        parseTime: stopwatch.elapsed,
        wasCancelled: false,
      ),
    );
  }
}

/// 处理两阶段第二步：按指令继续解析或丢弃保留的字节
void _handleParseContinue(_ParseContinueRequest request, SendPort sendPort) {
  final retained = _retainedParseContexts.remove(request.requestId);
  if (!request.proceed) {
    // 丢弃：缓存命中或任务被放弃，直接释放字节
    return;
  }
  if (retained == null) {
    // 上下文缺失（超时清理后的迟到指令），无法继续
    sendPort.send(
      _ParseResponse(
        requestId: request.requestId,
        error: 'Parse context lost',
        parseTime: Duration.zero,
        wasCancelled: false,
      ),
    );
    return;
  }

  final stopwatch = Stopwatch()..start();
  try {
    final result = retained.useGradualRead
        ? UnifiedMetadataParser.parseFromBytesGradual(
            retained.bytes,
            filePathForLog: retained.filePath,
          )
        : UnifiedMetadataParser.parseFromImageBytes(
            retained.bytes,
            filePathForLog: retained.filePath,
          );

    stopwatch.stop();

    if (result.metadataAbsent || (result.success && result.metadata != null)) {
      sendPort.send(
        _ParseResponse(
          requestId: request.requestId,
          metadata: result.metadata ?? const NaiImageMetadata(),
          parseTime: stopwatch.elapsed,
          bytesRead: retained.useGradualRead ? null : retained.bytes.length,
          wasCancelled: false,
        ),
      );
    } else {
      sendPort.send(
        _ParseResponse(
          requestId: request.requestId,
          error: result.errorMessage ?? 'Failed to parse metadata',
          parseTime: stopwatch.elapsed,
          wasCancelled: false,
        ),
      );
    }
  } catch (e) {
    stopwatch.stop();
    sendPort.send(
      _ParseResponse(
        requestId: request.requestId,
        error: 'Isolate parse error: $e',
        parseTime: stopwatch.elapsed,
        wasCancelled: false,
      ),
    );
  }
}

/// 工作线程初始化消息
class _WorkerInitMessage {
  final SendPort sendPort;
  final int workerId;

  _WorkerInitMessage({required this.sendPort, required this.workerId});
}

/// 解析请求
class _ParseRequest {
  final int requestId;
  final Uint8List bytes;
  final String filePath;
  final IsolateParseConfig config;

  /// true = 两阶段第一步：只算哈希并保留字节
  final bool hashOnly;

  _ParseRequest({
    required this.requestId,
    required this.bytes,
    required this.filePath,
    required this.config,
    this.hashOnly = false,
  });
}

/// 两阶段第二步指令（proceed=false 时通知 worker 丢弃保留字节）
class _ParseContinueRequest {
  final int requestId;
  final bool proceed;

  _ParseContinueRequest({required this.requestId, required this.proceed});
}

/// 两阶段第一步响应（哈希就绪）
class _HashReadyResponse {
  final int requestId;
  final String? hash;
  final String? error;

  // ignore: unused_element
  _HashReadyResponse({required this.requestId, this.hash, this.error});
}

/// 解析响应
class _ParseResponse {
  final int requestId;
  final NaiImageMetadata? metadata;
  final String? error;
  final Duration parseTime;
  final int? bytesRead;
  final bool wasCancelled;

  // ignore: unused_element
  _ParseResponse({
    required this.requestId,
    this.metadata,
    this.error,
    required this.parseTime,
    this.bytesRead,
    this.wasCancelled = false,
  });
}

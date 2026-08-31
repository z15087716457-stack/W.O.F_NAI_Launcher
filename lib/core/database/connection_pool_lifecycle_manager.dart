import 'dart:async';

import '../utils/app_logger.dart';
import 'connection_pool_holder.dart';

/// 连接池状态
enum PoolState { uninitialized, creating, ready, closing, closed, error }

/// 连接池生命周期管理器
class ConnectionPoolLifecycleManager {
  PoolState _state = PoolState.uninitialized;
  String? _dbPath;
  int _maxConnections = 20;

  final _stateController = StreamController<PoolState>.broadcast();

  /// 状态流
  Stream<PoolState> get stateStream => _stateController.stream;

  /// 当前状态
  PoolState get state => _state;

  /// 是否已就绪
  bool get isReady =>
      _state == PoolState.ready && ConnectionPoolHolder.isInitialized;

  /// 获取数据库路径
  String? get dbPath => _dbPath;

  void syncWithHolder() {
    if (ConnectionPoolHolder.isInitialized) {
      if (_state != PoolState.ready && _state != PoolState.creating) {
        _setState(PoolState.ready);
      }
    } else {
      if (_state != PoolState.uninitialized && _state != PoolState.closed) {
        _setState(PoolState.uninitialized);
      }
    }
  }

  Future<void> initialize({
    required String dbPath,
    int maxConnections = 20,
  }) async {
    _dbPath = dbPath;
    _maxConnections = maxConnections;
    syncWithHolder();
    await createPool();
  }

  Future<void> createPool() async {
    if (_state == PoolState.creating) return;

    if (_state == PoolState.ready && ConnectionPoolHolder.isInitialized) return;

    if (ConnectionPoolHolder.isInitialized) {
      await resetPool();
      return;
    }

    if (_dbPath == null) {
      throw StateError(
        'ConnectionPoolLifecycleManager not initialized. Call initialize() first.',
      );
    }

    _setState(PoolState.creating);

    try {
      await _closeExistingPool();
      await ConnectionPoolHolder.initialize(
        dbPath: _dbPath!,
        maxConnections: _maxConnections,
      );
      _setState(PoolState.ready);
      AppLogger.i('Connection pool created', 'ConnectionPoolLifecycle');
    } catch (e, stack) {
      _setState(PoolState.error);
      AppLogger.e(
        'Failed to create connection pool',
        e,
        stack,
        'ConnectionPoolLifecycle',
      );
      rethrow;
    }
  }

  Future<void> closePool() async {
    if (_state == PoolState.closed || _state == PoolState.closing) return;

    _setState(PoolState.closing);
    await _closeExistingPool();
    _setState(PoolState.closed);
  }

  Future<void> resetPool() async {
    if (_dbPath == null) {
      throw StateError('Cannot reset pool: dbPath not set');
    }

    _setState(PoolState.creating);

    try {
      await ConnectionPoolHolder.reset(
        dbPath: _dbPath!,
        maxConnections: _maxConnections,
      );
      await _verifyPoolReady();
      _setState(PoolState.ready);
      AppLogger.i('Connection pool reset', 'ConnectionPoolLifecycle');
    } catch (e, stack) {
      _setState(PoolState.error);
      AppLogger.e(
        'Failed to reset connection pool',
        e,
        stack,
        'ConnectionPoolLifecycle',
      );
      rethrow;
    }
  }

  Future<void> _verifyPoolReady() async {
    const maxAttempts = 10;
    for (var attempts = 0; attempts < maxAttempts; attempts++) {
      try {
        final pool = ConnectionPoolHolder.instance;
        final db = await pool.acquire();
        await pool.release(db);
        return;
      } catch (e) {
        if (attempts >= maxAttempts - 1) {
          throw StateError(
            'Connection pool not ready after $maxAttempts attempts: $e',
          );
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _closeExistingPool() async {
    if (!ConnectionPoolHolder.isInitialized) return;

    final pool = ConnectionPoolHolder.getInstanceOrNull();
    if (pool != null) {
      var attempts = 0;
      while (pool.inUseCount > 0 && attempts < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }

    await ConnectionPoolHolder.dispose();
  }

  Future<void> walCheckpoint() async {
    if (!isReady) return;

    try {
      final pool = ConnectionPoolHolder.instance;
      final db = await pool.acquire();
      try {
        await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      } finally {
        await pool.release(db);
      }
    } catch (e) {
      AppLogger.w('WAL checkpoint failed: $e', 'ConnectionPoolLifecycle');
    }
  }

  /// 获取数据库连接（带状态检查）
  Future<dynamic> acquireConnection() async {
    if (!isReady) {
      throw StateError('Connection pool is not ready (state: $_state)');
    }
    return ConnectionPoolHolder.instance.acquire();
  }

  Future<void> releaseConnection(dynamic db) async {
    if (!ConnectionPoolHolder.isInitialized) {
      if (db.isOpen) {
        await db.close();
      }
      return;
    }
    await ConnectionPoolHolder.instance.release(db);
  }

  void _setState(PoolState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
      AppLogger.d('Pool state: ${newState.name}', 'ConnectionPoolLifecycle');
    }
  }

  void dispose() {
    _closeExistingPool();
    _stateController.close();
  }
}

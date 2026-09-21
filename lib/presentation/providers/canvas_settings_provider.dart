import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/utils/app_logger.dart';
import '../../data/services/canvas_pin_repository.dart';
import 'generation/generation_models.dart';

part 'canvas_settings_provider.g.dart';

/// 画布门控设置（对标官网 `canvasLockCamera` / `canvasReducedMotion`）。
///
/// - [CanvasLockCameraNotifier] true = 锁相机：禁用滚轮缩放/平移、中键与
///   Shift+左键拖拽、惯性、WASD/±/1 等一切手动相机输入；程序化飞行
///   （f/q/选中联动/防迷失/新批自动飞）与自动选中不受影响。
/// - [CanvasReducedMotionNotifier] true = 减动效：flyToRect、滚轮/键盘缩放
///   动画、复位全部瞬移，松手不再产生惯性甩动。
@Riverpod(keepAlive: true)
class CanvasLockCameraNotifier extends _$CanvasLockCameraNotifier {
  @override
  bool build() {
    final storage = ref.read(localStorageServiceProvider);
    return storage.getCanvasLockCamera();
  }

  Future<void> setLocked(bool locked) async {
    state = locked;
    await ref.read(localStorageServiceProvider).setCanvasLockCamera(locked);
  }
}

@Riverpod(keepAlive: true)
class CanvasReducedMotionNotifier extends _$CanvasReducedMotionNotifier {
  @override
  bool build() {
    final storage = ref.read(localStorageServiceProvider);
    return storage.getCanvasReducedMotion();
  }

  Future<void> setReduced(bool reduced) async {
    state = reduced;
    await ref.read(localStorageServiceProvider).setCanvasReducedMotion(reduced);
  }
}

/// 放大填充（官网 `wb` 原子）：焦点夺焦时 fitMaxScale 开=∞（允许放大超 100%）、
/// 关=1（封顶 100% 像素级）。
@Riverpod(keepAlive: true)
class CanvasZoomToFillNotifier extends _$CanvasZoomToFillNotifier {
  @override
  bool build() =>
      ref
          .read(localStorageServiceProvider)
          .getSetting<bool>(
            StorageKeys.canvasZoomToFill,
            defaultValue: false,
          ) ??
      false;

  void toggle() => set(!state);
  void set(bool value) {
    state = value;
    unawaited(
      _saveCanvasPreference(
        ref.read(localStorageServiceProvider),
        StorageKeys.canvasZoomToFill,
        value,
      ),
    );
  }
}

/// Preview-only transparency backdrop. Never changes exported pixels or params.
@Riverpod(keepAlive: true)
class CanvasImageBackgroundNotifier extends _$CanvasImageBackgroundNotifier {
  static const presets = [
    'checker',
    'checkerLight',
    'checkerDark',
    'none',
    'black',
    'white',
    'gray',
    'red',
    'green',
    'blue',
  ];

  static bool isValid(String value) =>
      presets.contains(value) || RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value);

  @override
  String build() {
    final value = ref
        .read(localStorageServiceProvider)
        .getSetting<String>(
          StorageKeys.canvasImageBackground,
          defaultValue: 'checker',
        );
    return value != null && isValid(value) ? value : 'checker';
  }

  void set(String value) {
    if (!isValid(value)) return;
    state = value;
    unawaited(
      _saveCanvasPreference(
        ref.read(localStorageServiceProvider),
        StorageKeys.canvasImageBackground,
        value,
      ),
    );
  }
}

Future<void> _saveCanvasPreference<T>(
  LocalStorageService storage,
  String key,
  T value,
) async {
  try {
    await storage.setSetting(key, value);
  } catch (error) {
    AppLogger.w(
      'Could not persist canvas preference $key: $error',
      'CanvasSettings',
    );
  }
}

/// 平滑缩放（官网 smoothZoom 设置）：Ctrl+滚轮平滑档 exp(-0.01·dy)，
/// 关=离散档 ×1.2 / ÷1.2。
@Riverpod(keepAlive: true)
class CanvasSmoothZoomNotifier extends _$CanvasSmoothZoomNotifier {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

/// 画布钉板（官网 save.pin / Pins 计数）：state 仍是被钉图像 id 集合，
/// 但图像本体经 [CanvasPinRepository] 持久化到应用支持目录
/// `canvas_pins/`（SHA256 内容寻址文件名），manifest 存设置项
/// `canvas_pin_records`，历史被清/重启后仍能还原。语义：
/// - 钉图在独立区域展示，原输出组继续按正常规则选择；
/// - 钉住的 tile 右上出实心 pin 角标；
/// - 历史栏顶栏显示 `Pins N` 计数；钉板图像经 [images] 取回，
///   画布侧以 `pin:<image.id>` 独立分组（generationRunId 恒为 null）。
///
/// 旧版 `canvas_pinned_images` 纯 id 列表保留不删（用户数据），但不再
/// 读入 state——那些 id 没有持久化字节可还原，计入 Pins 只是幽灵计数。
@Riverpod(keepAlive: true)
class CanvasPinnedNotifier extends _$CanvasPinnedNotifier {
  final Map<String, GeneratedImage> _images = {};
  Future<void> _queue = Future.value();
  bool _disposed = false;
  CanvasPinRepository? _repository;

  CanvasPinRepository get _repo => _repository ??= CanvasPinRepository(
    storage: ref.read(localStorageServiceProvider),
  );

  /// 测试注入点：换成内存 storage + 临时目录的仓库。
  @visibleForTesting
  set debugRepository(CanvasPinRepository repository) =>
      _repository = repository;

  @override
  Set<String> build() {
    _disposed = false;
    _images.clear();
    ref.onDispose(() => _disposed = true);
    // 无 manifest → 零文件 I/O；有则后台还原，全部健康条目回来后一次性
    // 进 state——缺失/损坏记录不产生幽灵计数。
    if (_repo.readManifest().isNotEmpty) {
      unawaited(_enqueue(_restore));
    }
    return const {};
  }

  /// 已还原的钉图（与 state 一一对应，按 manifest/钉入顺序）。
  List<GeneratedImage> get images => List.unmodifiable([
    for (final id in _images.keys)
      if (state.contains(id)) _images[id]!,
  ]);

  bool isPinned(String imageId) => state.contains(imageId);

  /// 切换钉住状态。经 [_enqueue] 串行化防连点竞态；先落盘（pin 副本 +
  /// manifest）再更新 state，持久化失败原样抛给调用方展示。
  Future<void> toggle(GeneratedImage image) => _enqueue(() => _toggle(image));

  Future<void> _restore() async {
    final List<GeneratedImage> restored;
    try {
      restored = await _repo.loadAll();
    } catch (error) {
      AppLogger.w('Canvas pin restore failed: $error', 'CanvasPinnedNotifier');
      return;
    }
    if (_disposed) return;
    _images
      ..clear()
      ..addEntries(restored.map((image) => MapEntry(image.id, image)));
    state = _images.keys.toSet();
  }

  Future<void> _toggle(GeneratedImage image) async {
    if (_disposed) return;
    final id = image.id;
    if (state.contains(id)) {
      await _repo.removePin(id);
      if (_disposed) return;
      _images.remove(id);
      state = {...state}..remove(id);
      return;
    }
    final pinned = await _repo.addPin(image);
    if (_disposed) return;
    _images[id] = pinned;
    state = {...state, id};
  }

  /// 串行队列：restore 与 toggle 依次执行，共享的 [_queue] 只用于排队，
  /// 任务自身的错误仍经返回值抛给调用方。
  Future<T> _enqueue<T>(Future<T> Function() task) {
    final run = _queue.then((_) => task());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }
}

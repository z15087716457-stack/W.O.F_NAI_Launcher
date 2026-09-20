import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';

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
    await ref
        .read(localStorageServiceProvider)
        .setCanvasLockCamera(locked);
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
    await ref
        .read(localStorageServiceProvider)
        .setCanvasReducedMotion(reduced);
  }
}

/// 放大填充（官网 `wb` 原子）：焦点夺焦时 fitMaxScale 开=∞（允许放大超 100%）、
/// 关=1（封顶 100% 像素级）。
@Riverpod(keepAlive: true)
class CanvasZoomToFillNotifier extends _$CanvasZoomToFillNotifier {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
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

/// 画布钉板（官网 save.pin / Pins 计数）：被钉住的图像 id 集合，持久化到
/// `canvas_pinned_images`。语义：
/// - 钉住的组不参与「相机停稳 120ms 自动选中最近组」（官网钉板隔离自动夺焦）；
/// - 钉住的 tile 右上出实心 pin 角标；
/// - 历史栏顶栏显示 `Pins N` 计数。
@Riverpod(keepAlive: true)
class CanvasPinnedNotifier extends _$CanvasPinnedNotifier {
  @override
  Set<String> build() {
    return ref.read(localStorageServiceProvider).getCanvasPinnedImages();
  }

  /// 切换钉住状态
  Future<void> toggle(String imageId) async {
    final next = {...state};
    if (!next.remove(imageId)) {
      next.add(imageId);
    }
    state = next;
    await ref
        .read(localStorageServiceProvider)
        .setCanvasPinnedImages(next);
  }

  bool isPinned(String imageId) => state.contains(imageId);
}

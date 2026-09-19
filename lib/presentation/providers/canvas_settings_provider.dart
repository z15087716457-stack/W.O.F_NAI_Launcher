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

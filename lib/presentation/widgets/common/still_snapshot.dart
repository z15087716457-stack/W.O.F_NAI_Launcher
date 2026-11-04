import 'dart:async';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

/// 子树停稳一会儿没变，就把它画成一张图（[SnapshotWidget]）贴上去：之后每次合成都只贴
/// 这张图，不再重画子树、也不再重做里面的模糊。
///
/// 一有变化就丢掉那张图、照常画，停稳 [settle] 后再拍一张。“变化”= 本组件被父级重建，
/// 或主题、语言、像素比变了；所以只适合“内容只随这些变”的子树。子树里自己会动的东西
/// （动画、自己 setState 的状态）不会刷新这张图，不要放进来。
class StillSnapshot extends StatefulWidget {
  const StillSnapshot({
    super.key,
    required this.child,
    this.settle = const Duration(milliseconds: 300),
  });

  final Widget child;

  /// 停稳多久再拍。
  final Duration settle;

  @override
  State<StillSnapshot> createState() => _StillSnapshotState();
}

class _StillSnapshotState extends State<StillSnapshot> {
  final _controller = SnapshotController();
  Timer? _timer;

  void _changed() {
    _controller.allowSnapshotting = false;
    _timer?.cancel();
    _timer = Timer(widget.settle, () {
      _timer = null;
      if (mounted) _controller.allowSnapshotting = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 子树会用到的环境：变了图就旧了
    Theme.of(context);
    Localizations.maybeLocaleOf(context);
    MediaQuery.maybeDevicePixelRatioOf(context);
    _changed();
  }

  @override
  void didUpdateWidget(StillSnapshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _changed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _controller,
    mode: SnapshotMode.permissive,
    autoresize: true,
    child: widget.child,
  );
}

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_fixture_image.dart';
import 'channel_contract.dart';
import 'channel_layer.dart';
import 'channel_overlay.dart';

/// 假数据：和 HTML 原型（.devin/mockups/canvas-channel/mock.html）同一批历史，
/// 排法同原型（多张近方阵、三张单上双下、组间距 340、新组在上）。
abstract final class ChannelFixture {
  static ImageProvider Function(String key) images = UiFixtureImage.gradient;

  /// “现在”：2026-10-14 23:20。
  static final now = DateTime(2026, 10, 14, 23, 20);

  static const gap = 340.0, grid = 48.0;

  static Size sizeOf(String key) => switch (key) {
    'g07' => const Size(1024, 1024),
    'g19' || 'g41' => const Size(1216, 832),
    _ => const Size(832, 1216),
  };

  /// (日期偏移, 时:分, 图)
  static const _raw = [
    (0, '23:10', ['canvas']),
    (0, '22:47', ['g18', 'g46']),
    (0, '22:31', ['g19']),
    (0, '22:05', ['g03', 'g33', 'g50', 'g46']),
    (0, '21:40', ['g07']),
    (1, '23:52', ['g41', 'g18', 'g50']),
    (1, '23:18', ['g50']),
    (1, '22:40', ['g33', 'g03']),
    (1, '21:02', ['canvas']),
    (2, '20:31', ['g18', 'g46', 'g50', 'g33']),
    (2, '19:55', ['g41']),
    (2, '19:10', ['g07', 'g03']),
    (3, '23:40', ['g46']),
    (3, '22:15', ['g19', 'g41']),
    (3, '21:30', ['canvas', 'g18', 'g03']),
    (4, '20:05', ['g50']),
  ];

  static List<ChannelFixtureGroup> groups({bool pending = false}) {
    final out = <ChannelFixtureGroup>[];
    var y = 0.0;
    if (pending) {
      const s = Size(832, 1216);
      out.add(
        ChannelFixtureGroup(
          batch: ChannelBatch(
            id: 'pending',
            rect: Rect.fromLTWH(
              -s.width / 2,
              -gap - s.height,
              s.width,
              s.height,
            ),
            count: 1,
            pending: true,
          ),
          tiles: const [
            ChannelFixtureTile(key: null, rect: Rect.fromLTWH(0, 0, 832, 1216)),
          ],
        ),
      );
    }
    for (final (i, (day, hm, keys)) in _raw.indexed) {
      final t = keys.map((k) => (k, sizeOf(k))).toList();
      final tiles = <ChannelFixtureTile>[];
      var w = 0.0, h = 0.0;
      if (t.length == 3) {
        final pw = t[1].$2.width + grid + t[2].$2.width;
        w = math.max(pw, t[0].$2.width);
        final x1 = (w - pw) / 2, y1 = t[0].$2.height + grid;
        tiles
          ..add(
            ChannelFixtureTile(
              key: t[0].$1,
              rect: Offset((w - t[0].$2.width) / 2, 0) & t[0].$2,
            ),
          )
          ..add(
            ChannelFixtureTile(key: t[1].$1, rect: Offset(x1, y1) & t[1].$2),
          )
          ..add(
            ChannelFixtureTile(
              key: t[2].$1,
              rect: Offset(x1 + t[1].$2.width + grid, y1) & t[2].$2,
            ),
          );
        h = y1 + math.max(t[1].$2.height, t[2].$2.height);
      } else {
        final cols = math.max(1, math.sqrt(t.length).ceil());
        var x = 0.0, ty = 0.0, rh = 0.0;
        for (final (j, (k, s)) in t.indexed) {
          if (j > 0 && j % cols == 0) {
            ty += rh + grid;
            x = 0;
            rh = 0;
          }
          tiles.add(ChannelFixtureTile(key: k, rect: Offset(x, ty) & s));
          x += s.width + grid;
          rh = math.max(rh, s.height);
          w = math.max(w, x - grid);
        }
        h = ty + rh;
      }
      final parts = hm.split(':');
      final time = DateTime(
        now.year,
        now.month,
        now.day - day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      out.add(
        ChannelFixtureGroup(
          batch: ChannelBatch(
            id: 'b$i',
            rect: Rect.fromLTWH(-w / 2, y, w, h),
            time: time,
            count: keys.length,
          ),
          tiles: tiles,
        ),
      );
      y += h + gap;
    }
    return out;
  }
}

class ChannelFixtureGroup {
  const ChannelFixtureGroup({required this.batch, required this.tiles});
  final ChannelBatch batch;

  /// 组内坐标（相对组左上角）。
  final List<ChannelFixtureTile> tiles;
}

class ChannelFixtureTile {
  const ChannelFixtureTile({required this.key, required this.rect});

  /// 图片 key；null = 生成中占位。
  final String? key;
  final Rect rect;
}

/// 预览 / 测试用的“小画布”：假历史 + 自己的相机（滚轮上下、Shift+滚轮左右、Ctrl+滚轮缩放、拖动平移），
/// 底下垫 [ChannelBackdrop]、上面盖 [ChannelOverlay]——也是接线方把通道接进真实画布引擎的参考摆法。
class ChannelFixtureCanvas extends StatefulWidget {
  const ChannelFixtureCanvas({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.generating = false,
    this.overview = false,
    this.pad = const EdgeInsets.fromLTRB(40, 50, 40, 70),
    this.maxScale = 1,
    this.focusY,
    this.focusScale,
    this.images,
    this.now,
    this.onJump,
  });

  final ChannelSettings settings;
  final ValueChanged<ChannelSettings> onSettingsChanged;
  final bool generating;

  /// 一打开就缩到全局（Ctrl+0）。
  final bool overview;

  /// 聚焦最新一批时的留白与最大缩放（默认同生图页 `GenCanvas.pad`、放大填满关）。
  final EdgeInsets pad;
  final double maxScale;

  /// 直接指定视口中心的世界 y 和缩放（截图用）。
  final double? focusY;
  final double? focusScale;
  final ImageProvider? Function(String key)? images;
  final DateTime? now;

  /// 刻度条跳转时额外通知（测试用）。
  final ValueChanged<double>? onJump;

  @override
  State<ChannelFixtureCanvas> createState() => _ChannelFixtureCanvasState();
}

class _ChannelFixtureCanvasState extends State<ChannelFixtureCanvas> {
  late List<ChannelFixtureGroup> _groups = ChannelFixture.groups(
    pending: widget.generating,
  );
  Size _size = Size.zero;
  Offset _center = Offset.zero;
  double _scale = 0.5;
  var _placed = false;
  Offset? _drag;

  @override
  void didUpdateWidget(ChannelFixtureCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generating != widget.generating) {
      _groups = ChannelFixture.groups(pending: widget.generating);
      _focus(0);
    }
  }

  void _place(Size size) {
    _size = size;
    if (_placed || size.isEmpty) return;
    _placed = true;
    if (widget.overview) {
      final top = _groups.first.batch.rect.top - 1800;
      final bot = _groups.last.batch.rect.bottom + 1800;
      _scale = math.max(0.02, size.height / (bot - top));
      _center = Offset(0, (top + bot) / 2);
    } else {
      _focus(0);
    }
    if (widget.focusY != null) _center = Offset(0, widget.focusY!);
    if (widget.focusScale != null) _scale = widget.focusScale!;
  }

  void _focus(int i) {
    if (_size.isEmpty) return;
    final r = _groups[i].batch.rect, p = widget.pad;
    final s = math.min(
      widget.maxScale,
      math.min(
        (_size.width - p.horizontal) / r.width,
        (_size.height - p.vertical) / r.height,
      ),
    );
    final boxCenterY = p.top + (_size.height - p.vertical) / 2;
    _scale = s;
    _center = Offset(0, r.center.dy - (boxCenterY - _size.height / 2) / s);
  }

  ChannelCamera get _camera => ChannelCamera(
    offset: _size.center(Offset.zero) - _center * _scale,
    scale: _scale,
  );

  void _onSignal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final keys = HardwareKeyboard.instance;
    setState(() {
      if (keys.isControlPressed || keys.isMetaPressed) {
        final world = _camera.screenToWorld(e.localPosition);
        final next =
            (_scale * math.exp((-0.01 * e.scrollDelta.dy).clamp(-0.25, 0.25)))
                .clamp(0.02, 4.0);
        _scale = next;
        _center = world - (e.localPosition - _size.center(Offset.zero)) / next;
      } else if (keys.isShiftPressed) {
        _center += Offset((e.scrollDelta.dx + e.scrollDelta.dy) / _scale, 0);
      } else {
        _center += e.scrollDelta / _scale;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _place(box.biggest);
        final cam = _camera;
        final data = ChannelViewData(
          settings: widget.settings,
          camera: cam,
          batches: [for (final g in _groups) g.batch],
          now: widget.now ?? ChannelFixture.now,
          generating: widget.generating,
        );
        final view = cam.visibleWorldRect(_size).inflate(400);
        final images = widget.images ?? ChannelFixture.images;
        return Listener(
          onPointerSignal: _onSignal,
          onPointerDown: (e) => _drag = e.localPosition,
          onPointerMove: (e) {
            final last = _drag;
            if (last == null) return;
            setState(() => _center -= (e.localPosition - last) / _scale);
            _drag = e.localPosition;
          },
          onPointerUp: (_) => _drag = null,
          onPointerCancel: (_) => _drag = null,
          child: ClipRect(
            key: const Key('channel-fixture-canvas'),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ChannelBackdrop(data: data),
                for (final g in _groups)
                  if (g.batch.rect.overlaps(view))
                    for (final t in g.tiles)
                      _tile(
                        cam,
                        g.batch.rect.topLeft + t.rect.topLeft,
                        t,
                        images,
                      ),
                ChannelOverlay(
                  data: data,
                  actions: ChannelActions(
                    onSettingsChanged: widget.onSettingsChanged,
                    onJumpTo: (y) {
                      widget.onJump?.call(y);
                      setState(() => _center = Offset(0, y));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(
    ChannelCamera cam,
    Offset at,
    ChannelFixtureTile t,
    ImageProvider? Function(String) images,
  ) {
    final r = Rect.fromPoints(
      cam.worldToScreen(at),
      cam.worldToScreen(at + t.rect.size.bottomRight(Offset.zero)),
    );
    final img = t.key == null ? null : images(t.key!);
    return Positioned.fromRect(
      rect: r,
      child: ClipRRect(
        key: t.key == null ? const Key('channel-fixture-pending') : null,
        borderRadius: BorderRadius.circular(6),
        child: img == null
            ? ColoredBox(color: context.ui.control)
            : Image(
                image: img,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
      ),
    );
  }
}

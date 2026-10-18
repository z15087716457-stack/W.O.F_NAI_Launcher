import 'package:flutter/widgets.dart';

/// 画布视觉通道：无限画布两侧、跟着图片一起滚的装饰层。
///
/// 界面只吃这份契约：
/// - [ChannelBackdrop]（`channel_layer.dart`）画在图块**下面**：底色、主题装饰、过渡层、图片光台、时间刻度；
/// - [ChannelOverlay]（`channel_overlay.dart`）画在图块**上面**：右侧刻度条、进入时的“本次通道”提示；
/// - [ChannelSettingsSection]（`channel_settings.dart`）是显示设置弹层里的一节（生图页已接好，见
///   `GenCanvasData.channel` / `GenActions.onChannelChanged`）。
///
/// 坐标：世界坐标与现有画布引擎一致（`canvas_feed_layout.dart`：组水平居中于 x = 0、组间距 340、
/// 新组插在最上面），屏幕 = 世界 × scale + offset（同 `CanvasCamera`）。

/// 十一个主题；顺序 = 设置里卡片的顺序。
enum ChannelTheme {
  circuit,
  stars,
  herb,
  arcade,
  abyss,
  wave,
  caliber,
  strata,
  metro,
  score,
  luna,
}

/// 关闭（保留现有底纹，本层什么都不画）／固定一个主题／每次随机一组顺序。
enum ChannelMode { off, fixed, random }

/// 浓淡：装饰整体透明度倍数。
enum ChannelLevel {
  soft(0.6),
  standard(1),
  strong(1.5);

  const ChannelLevel(this.factor);
  final double factor;
}

/// 用户设置。除 [seed] 外都要持久化（建议存在现有画布显示设置旁边）。
@immutable
class ChannelSettings {
  const ChannelSettings({
    this.mode = ChannelMode.random,
    this.fixed = ChannelTheme.stars,
    this.pool = allThemes,
    this.level = ChannelLevel.standard,
    this.ruler = true,
    this.motion = true,
    this.seed = 0,
  });

  static const allThemes = {
    ChannelTheme.circuit,
    ChannelTheme.stars,
    ChannelTheme.herb,
    ChannelTheme.arcade,
    ChannelTheme.abyss,
    ChannelTheme.wave,
    ChannelTheme.caliber,
    ChannelTheme.strata,
    ChannelTheme.metro,
    ChannelTheme.score,
    ChannelTheme.luna,
  };

  final ChannelMode mode;

  /// “固定一个”时用哪个主题。
  final ChannelTheme fixed;

  /// “每次随机”时参与抽取的主题，界面保证至少两个。
  final Set<ChannelTheme> pool;
  final ChannelLevel level;

  /// 时间刻度：每批左上角的“时间 · 张数”、换日分隔线、右侧刻度条。
  final bool ruler;

  /// 空闲微动（光点、闪烁、摆动……）。生成中、系统“减少动态效果”时界面自己停，不用接线方管。
  final bool motion;

  /// 本次会话的随机种子：决定主题顺序和每个元素的位置。**不持久化**——每次启动换一个
  /// （例如启动时 `Random().nextInt(1 << 31)`），这就是“每次进来都不一样”。
  /// 设置里点“换一组”时界面会带着新种子回调 [ChannelActions.onSettingsChanged]。
  final int seed;

  ChannelSettings copyWith({
    ChannelMode? mode,
    ChannelTheme? fixed,
    Set<ChannelTheme>? pool,
    ChannelLevel? level,
    bool? ruler,
    bool? motion,
    int? seed,
  }) => ChannelSettings(
    mode: mode ?? this.mode,
    fixed: fixed ?? this.fixed,
    pool: pool ?? this.pool,
    level: level ?? this.level,
    ruler: ruler ?? this.ruler,
    motion: motion ?? this.motion,
    seed: seed ?? this.seed,
  );

  @override
  bool operator ==(Object other) =>
      other is ChannelSettings &&
      other.mode == mode &&
      other.fixed == fixed &&
      other.pool.length == pool.length &&
      other.pool.containsAll(pool) &&
      other.level == level &&
      other.ruler == ruler &&
      other.motion == motion &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(
    mode,
    fixed,
    Object.hashAllUnordered(pool),
    level,
    ruler,
    motion,
    seed,
  );

  @override
  String toString() =>
      'ChannelSettings(${mode.name}, fixed: ${fixed.name}, '
      'pool: ${[for (final t in ChannelTheme.values)
        if (pool.contains(t)) t.name]}, '
      '${level.name}, ruler: $ruler, motion: $motion, seed: $seed)';
}

/// 相机：屏幕 = 世界 × [scale] + [offset]（直接取 `generationCanvasCameraProvider`）。
@immutable
class ChannelCamera {
  const ChannelCamera({required this.offset, required this.scale});
  final Offset offset;
  final double scale;

  Offset worldToScreen(Offset world) => world * scale + offset;
  Offset screenToWorld(Offset screen) => (screen - offset) / scale;
  Rect visibleWorldRect(Size viewport) => Rect.fromLTWH(
    -offset.dx / scale,
    -offset.dy / scale,
    viewport.width / scale,
    viewport.height / scale,
  );

  @override
  bool operator ==(Object other) =>
      other is ChannelCamera && other.offset == offset && other.scale == scale;

  @override
  int get hashCode => Object.hash(offset, scale);
}

/// 画布上的一批（`CanvasFeedLayoutResult.groups` 里的一组，钉图板的组不要给）。
@immutable
class ChannelBatch {
  const ChannelBatch({
    required this.id,
    required this.rect,
    this.time,
    this.count = 1,
    this.pending = false,
  });

  /// 组 key（`run:<id>` / `img:<id>`）。
  final String id;

  /// 整组的世界矩形（`groupRect`）。
  final Rect rect;

  /// 这批的生成时间（组里第一张的 `createdAt`）；null = 不写时间、不参与换日。
  final DateTime? time;

  /// 组里张数（生成中含还没出的槽位）。
  final int count;

  /// 正在生成：时间刻度写“生成中”。
  final bool pending;
}

@immutable
class ChannelViewData {
  const ChannelViewData({
    required this.settings,
    required this.camera,
    this.batches = const [],
    required this.now,
    this.generating = false,
    this.pinboard,
  });

  final ChannelSettings settings;
  final ChannelCamera camera;

  /// 从上到下（新 → 旧，和画布一致）。
  final List<ChannelBatch> batches;

  /// “今天 / 昨天”的参照时间（接线方给 `DateTime.now()`，测试给固定值）。
  final DateTime now;

  /// 生成中：微动暂停。
  final bool generating;

  /// 钉图板的世界矩形（有钉图时给）：这一片的装饰压暗，不和钉住的图抢。
  final Rect? pinboard;
}

class ChannelActions {
  const ChannelActions({
    required this.onSettingsChanged,
    required this.onJumpTo,
  });

  factory ChannelActions.logging(ValueChanged<String> log) => ChannelActions(
    onSettingsChanged: (v) => log('onSettingsChanged($v)'),
    onJumpTo: (y) => log('onJumpTo(${y.round()})'),
  );

  /// 设置变了（含“换一组”换种子）。
  final ValueChanged<ChannelSettings> onSettingsChanged;

  /// 刻度条上点 / 拖：把视口中心平移到这个世界 y（x 回到 0、缩放不变；不改选中）。
  final ValueChanged<double> onJumpTo;
}

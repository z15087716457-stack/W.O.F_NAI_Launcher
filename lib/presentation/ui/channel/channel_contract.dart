import 'package:flutter/widgets.dart';

/// 画布视觉通道：无限画布底层字符艺术动态舞台，支持滚动视差、分段过渡与审图走廊退暗。
///
/// 界面只吃这份契约：
/// - [ChannelBackdrop]（`channel_layer.dart`）画在图块**下面**：底色、字符艺术主题、过渡层、图片光台、时间刻度；
/// - [ChannelSettingsSection]（`channel_settings.dart`）是显示设置弹层里的一节（生图页已接好，见
///   `GenCanvasData.channel` / `GenActions.onChannelChanged`）。
///
/// 坐标：世界坐标与现有画布引擎一致（`canvas_feed_layout.dart`：组水平居中于 x = 0、组间距 340、
/// 新组插在最上面），屏幕 = 世界 × scale + offset（同 `CanvasCamera`）。

/// 五个字符艺术主题；顺序 = 设置里卡片的顺序。
enum ChannelTheme {
  /// 01 · 深海浮游（生物荧光水母 + 3D 振翅蝠鲼 + 盲文微雾）
  pelagic,

  /// 02 · 暮光云海（体积积雨云 + 暮光紫金前向散射银边）
  nimbus,

  /// 03 · 晴空云海（湛蓝晴空 + 雕塑雪白积雨云）
  cumulus,

  /// 04 · 极光雪原（双幕丝带极光 + 雕塑雪山谷 + 侧翼松林 + 视差斜雪）
  aurora,

  /// 05 · 声纹潮汐（真隐藏面消除 3D 声纹山脊 + 等高线切面）
  strata,
}

/// 关闭（保留现有底纹，本层什么都不画）／固定一个主题／每次随机一组顺序。
enum ChannelMode { off, fixed, random }

/// 浓淡：整体亮度与字形丰盈度倍数。
enum ChannelLevel {
  soft(0.72),
  standard(1.0),
  strong(1.36);

  const ChannelLevel(this.factor);
  final double factor;
}

/// 用户设置。除 [seed] 外都要持久化（存在现有画布显示设置旁边）。
@immutable
class ChannelSettings {
  const ChannelSettings({
    this.mode = ChannelMode.random,
    this.fixed = ChannelTheme.pelagic,
    this.pool = allThemes,
    this.level = ChannelLevel.strong,
    this.sideTransparency = defaultSideTransparency,
    this.ruler = true,
    this.motion = true,
    this.seed = 0,
  });

  /// 默认侧栏透光度（0.0 = 完全不透明实底，1.0 = 最大玻璃通透）。
  static const double defaultSideTransparency = 0.45;

  static const allThemes = {
    ChannelTheme.pelagic,
    ChannelTheme.nimbus,
    ChannelTheme.cumulus,
    ChannelTheme.aurora,
    ChannelTheme.strata,
  };

  final ChannelMode mode;

  /// “固定一个”时用哪个主题。
  final ChannelTheme fixed;

  /// “每次随机”时参与抽取的主题，界面保证至少两个。
  final Set<ChannelTheme> pool;
  final ChannelLevel level;

  /// 左右侧边栏透出背景的程度（0.0 = 纯实底不透，1.0 = 通透玻璃）。
  final double sideTransparency;

  /// 时间刻度：每批左上角的“时间 · 张数”和换日分隔线。
  final bool ruler;

  /// 空闲微动。系统“减少动态效果”时界面自己停，不用接线方管。
  final bool motion;

  /// 本次会话的随机种子：决定主题顺序和每个元素的位置。**不持久化**——每次启动换一个
  /// （例如启动时 `Random().nextInt(1 << 31)`），这就是“每次进来都不一样”。
  /// 设置里点“换一组”时会带着新种子提交设置。
  final int seed;

  ChannelSettings copyWith({
    ChannelMode? mode,
    ChannelTheme? fixed,
    Set<ChannelTheme>? pool,
    ChannelLevel? level,
    double? sideTransparency,
    bool? ruler,
    bool? motion,
    int? seed,
  }) => ChannelSettings(
    mode: mode ?? this.mode,
    fixed: fixed ?? this.fixed,
    pool: pool ?? this.pool,
    level: level ?? this.level,
    sideTransparency: (sideTransparency ?? this.sideTransparency)
        .clamp(0.0, 1.0)
        .toDouble(),
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
      (other.sideTransparency - sideTransparency).abs() < 1e-6 &&
      other.ruler == ruler &&
      other.motion == motion &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(
    mode,
    fixed,
    Object.hashAllUnordered(pool),
    level,
    (sideTransparency * 1000).round(),
    ruler,
    motion,
    seed,
  );

  @override
  String toString() =>
      'ChannelSettings(${mode.name}, fixed: ${fixed.name}, '
      'pool: ${[for (final t in ChannelTheme.values)
        if (pool.contains(t)) t.name]}, '
      '${level.name}, sideTransparency: ${(sideTransparency * 100).round()}%, '
      'ruler: $ruler, motion: $motion, seed: $seed)';
}

/// 相机：屏幕 = 世界 × [scale] + [offset]（直接取 `generationCanvasCameraProvider`）。
@immutable
class ChannelCamera {
  const ChannelCamera({required this.offset, required this.scale});

  // 原构图为 922 × 1000，832 × 1216 的竖图上方留 50，下方留 70。
  static const welcomeZoom = (1000 - 50 - 70) / 1216;

  factory ChannelCamera.welcome(Size viewport) {
    final factor = viewport.width > 0 ? viewport.width / 922 : 1.0;
    return ChannelCamera(
      offset:
          viewport.center(Offset.zero) - Offset(0, (1000 / 2 - 50) * factor),
      scale: welcomeZoom * factor,
    );
  }

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
    this.welcome = false,
    this.stageCenterX,
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

  /// 空态：关闭中央审图走廊退暗，完整呈现字符艺术舞台。
  final bool welcome;

  /// 视觉主舞台中心横坐标（全窗口统一背景时对齐中央画布中轴，留空则取视口中线）。
  final double? stageCenterX;
}

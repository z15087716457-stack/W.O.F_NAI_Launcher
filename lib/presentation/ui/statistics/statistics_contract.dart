/// 统计页 · 界面契约
///
/// 这是新界面和后端之间唯一的接口：
/// - [StatsViewData]：此刻界面要显示的全部数据。由转接层从 provider / service 组装，
///   界面只读不改。
/// - [StatsActions]：用户在界面上能做的全部操作。由转接层接到 provider / service / 路由。
///
/// 界面文件（本目录除本文件外的所有 `statistics_*.dart`）不 import 任何 provider、
/// service、数据库或路由。转接层需要的数据界面里没有字段时，在这里加字段并通知界面方，
/// 不要在界面文件里取数，也不要改界面文件。
///
/// 数据口径（和旧统计页一致，转接层沿用数据源现有查询）：
/// - 只算 `is_deleted = 0` 的图。
/// - 日期按 `date_ymd`（没有时用 `modified_at` 的本地日期）；小时、星期按 `modified_at` 本地时间。
/// - 标了「范围内」的字段：受当前时间范围 [StatsViewData.range] 和仅 NAI
///   [StatsViewData.naiOnly] 两个条件约束。
/// - 标了「全部时间」的字段：不受时间范围约束，但受仅 NAI 约束
///   （日历、产量图、连续天数要看整段历史）。
library;

import 'package:flutter/foundation.dart';

/// 顶栏的时间范围。默认 [all]；用户的选择由转接层持久化（存储键 `statistics_range`）。
enum StatsRange {
  days7(7),
  days30(30),
  days90(90),
  thisYear(null),
  all(null);

  const StatsRange(this.days);

  /// 固定天数的范围；[thisYear] 和 [all] 为 null。
  final int? days;
}

/// 顶栏右侧的同步状态。
enum StatsSyncState {
  /// 显示“更新于 {时间}”。
  idle,

  /// 后台正在重算；有旧结果时继续显示旧结果。
  updating,

  /// 最近一次重算失败，但还有旧结果可显示；顶栏显示“更新失败”。
  failed,
}

/// 界面此刻要显示的全部数据。
@immutable
class StatsViewData {
  const StatsViewData({
    required this.range,
    required this.naiOnly,
    required this.today,
    required this.sync,
    this.updatedAt,
    this.countingImages,
    this.snapshot,
    this.errorMessage,
  });

  /// 当前时间范围。
  final StatsRange range;

  /// “仅 NAI 图片”开关。统计页单独存（存储键 `statistics_nai_only`，默认关），
  /// 不和本地画廊的同名开关联动。
  final bool naiOnly;

  /// 今天（本地日期，时分秒为 0）。所有“近 N 天”都以它为终点。
  final DateTime today;

  final StatsSyncState sync;

  /// 当前结果的计算时间。
  final DateTime? updatedAt;

  /// 首次统计时图库的总张数，用于“正在统计 48,824 张…”；不知道时为 null。
  final int? countingImages;

  /// 统计结果。null 表示还没有任何结果：
  /// - [errorMessage] 也为 null → 显示首次统计中的骨架屏；
  /// - [errorMessage] 不为 null → 显示整页出错状态。
  final StatsSnapshot? snapshot;

  /// 没有任何结果时的错误信息（原样显示给用户）。
  final String? errorMessage;
}

/// 一次统计的结果。
@immutable
class StatsSnapshot {
  const StatsSnapshot({
    required this.libraryTotal,
    required this.images,
    required this.favorites,
    required this.bytes,
    required this.withMetadata,
    required this.weekHour,
    required this.models,
    required this.resolutions,
    required this.samplers,
    required this.steps,
    required this.cfg,
    required this.noiseSchedules,
    required this.sizeBuckets,
    required this.dailyImages,
    required this.dailyModels,
    required this.monthlyBytes,
    required this.dailyAnlas,
    this.artists,
  }) : assert(weekHour.length == 168),
       assert(sizeBuckets.length == 5);

  /// 图库里所有未删除的图片数，**不受**时间范围和仅 NAI 约束。为 0 时界面显示空图库引导。
  final int libraryTotal;

  /// 图片数（范围内）。
  final int images;

  /// 收藏的图片数（范围内）。
  final int favorites;

  /// 文件总字节数（范围内）。
  final int bytes;

  /// 有元数据的图片数（范围内）。
  final int withMetadata;

  /// 星期 × 小时的张数（范围内），长度 168。
  /// 下标 = (星期 - 1) × 24 + 小时；星期按 [DateTime.weekday]（1 = 周一 … 7 = 周日）。
  final List<int> weekHour;

  /// 各模型张数（范围内），键是元数据里的原始模型 id（如 `nai-diffusion-4-5-full`），
  /// 按张数从多到少。没有模型信息的图不计入。
  final List<StatsCount<String>> models;

  /// 各尺寸张数（范围内），按张数从多到少；宽高是真实像素，不约分。
  final List<StatsResolution> resolutions;

  /// 采样器分布（范围内、有元数据），键是原始 id（如 `k_euler_ancestral`），按张数从多到少。
  final List<StatsCount<String>> samplers;

  /// 步数分布（范围内、有元数据），按张数从多到少，至少给前 6 项。
  final List<StatsCount<int>> steps;

  /// CFG 分布（范围内、有元数据），按张数从多到少，至少给前 6 项。
  final List<StatsCount<double>> cfg;

  /// 噪声调度分布（范围内、有元数据），键是原始值（如 `karras`），按张数从多到少。
  final List<StatsCount<String>> noiseSchedules;

  /// 文件大小分档（范围内），固定 5 档，依次为
  /// `< 1 MB`、`1–2 MB`、`2–5 MB`、`5–10 MB`、`≥ 10 MB`（1 MB = 1048576 字节）。
  final List<StatsSizeBucket> sizeBuckets;

  /// 每天的图片数（全部时间）。键是本地日期（时分秒为 0），没有图的日子可以不放。
  final Map<DateTime, int> dailyImages;

  /// 每天每个模型的张数（全部时间），用于产量图按模型堆叠。
  /// 当天总数减去这里的合计 = 没有元数据的张数。
  final List<StatsModelDay> dailyModels;

  /// 每月新增的文件字节数（全部时间）。键是当月 1 日。
  final Map<DateTime, int> monthlyBytes;

  /// 每天的 Anlas 消耗（来自 `AnlasStatisticsService`，只有最近 90 天），
  /// **不受**时间范围和仅 NAI 约束。键是本地日期。
  final Map<DateTime, int> dailyAnlas;

  /// 常用画师（范围内）。后台单独算，还没算好时为 null，界面显示占位。
  final StatsArtists? artists;
}

/// 一项计数。
@immutable
class StatsCount<T> {
  const StatsCount(this.key, this.count);
  final T key;
  final int count;
}

@immutable
class StatsResolution {
  const StatsResolution(this.width, this.height, this.count);
  final int width;
  final int height;
  final int count;
}

@immutable
class StatsSizeBucket {
  const StatsSizeBucket(this.count, this.bytes);
  final int count;
  final int bytes;
}

@immutable
class StatsModelDay {
  const StatsModelDay(this.day, this.model, this.count);

  /// 本地日期。
  final DateTime day;

  /// 原始模型 id。
  final String model;
  final int count;
}

/// 常用画师。从正向提示词里数 `artist:名字`，一张图里写多次只算一次。
@immutable
class StatsArtists {
  const StatsArtists({required this.top, required this.imagesWithArtist});

  /// 前 10 名，按“出现在几张图里”从多到少；名字已规范化（小写、下划线换空格）。
  final List<StatsCount<String>> top;

  /// 写了任意 `artist:` 的图片数（范围内）。
  final int imagesWithArtist;
}

/// 用户能做的全部操作。
@immutable
class StatsActions {
  const StatsActions({
    required this.onRangeChanged,
    required this.onNaiOnlyChanged,
    required this.onRefresh,
    required this.onOpenGallery,
    required this.onGoGenerate,
    required this.onAddGalleryFolder,
  });

  /// 切换时间范围：持久化选择并按新范围重算（有旧结果先显示旧结果）。
  final ValueChanged<StatsRange> onRangeChanged;

  /// 切换仅 NAI 图片：持久化并重算。
  final ValueChanged<bool> onNaiOnlyChanged;

  /// 刷新按钮、出错页的“重试”：清掉缓存强制重算。
  final VoidCallback onRefresh;

  /// 点了某个数字 / 图形：切到本地画廊并带上筛选。
  ///
  /// 转接层在 [filter] 之外再带上：当前仅 NAI 状态；当前时间范围不是“全部”时作为日期筛选
  /// （[StatsDateFilter] 自带日期，覆盖时间范围）。本地画廊要能清除这些筛选。
  final ValueChanged<StatsGalleryFilter> onOpenGallery;

  /// 空图库页“去生图”：切到生图页。
  final VoidCallback onGoGenerate;

  /// 空图库页“添加图库文件夹”：打开本地画廊的添加文件夹流程。
  final VoidCallback onAddGalleryFolder;

  /// 什么都不做，预览和测试用。
  static final none = StatsActions(
    onRangeChanged: (_) {},
    onNaiOnlyChanged: (_) {},
    onRefresh: () {},
    onOpenGallery: (_) {},
    onGoGenerate: () {},
    onAddGalleryFolder: () {},
  );
}

/// 跳本地画廊时带的筛选。转接层把它翻译成本地画廊的 `FilterCriteria`。
@immutable
sealed class StatsGalleryFilter {
  const StatsGalleryFilter();
}

/// 一段日期：[start] 含、[end] 不含，都是本地日期。日历格是一天，产量柱是一天 / 一周 / 一个月。
final class StatsDateFilter extends StatsGalleryFilter {
  const StatsDateFilter(this.start, this.end);
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is StatsDateFilter && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'StatsDateFilter($start, $end)';
}

/// 只看某个模型（原始 id）→ `filterModels: [model]`。
final class StatsModelFilter extends StatsGalleryFilter {
  const StatsModelFilter(this.model);
  final String model;

  @override
  bool operator ==(Object other) =>
      other is StatsModelFilter && other.model == model;
  @override
  int get hashCode => model.hashCode;

  @override
  String toString() => 'StatsModelFilter($model)';
}

/// 只看某个尺寸 → `filterResolutions: ['832x1216']`。
final class StatsResolutionFilter extends StatsGalleryFilter {
  const StatsResolutionFilter(this.width, this.height);
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      other is StatsResolutionFilter &&
      other.width == width &&
      other.height == height;
  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'StatsResolutionFilter($width, $height)';
}

enum StatsOrientation { portrait, landscape, square }

/// 只看某个方向 → `filterOrientation`。
final class StatsOrientationFilter extends StatsGalleryFilter {
  const StatsOrientationFilter(this.orientation);
  final StatsOrientation orientation;

  @override
  bool operator ==(Object other) =>
      other is StatsOrientationFilter && other.orientation == orientation;
  @override
  int get hashCode => orientation.hashCode;

  @override
  String toString() => 'StatsOrientationFilter($orientation)';
}

/// 只看某个采样器（原始 id）→ `filterSamplers: [sampler]`。
final class StatsSamplerFilter extends StatsGalleryFilter {
  const StatsSamplerFilter(this.sampler);
  final String sampler;

  @override
  bool operator ==(Object other) =>
      other is StatsSamplerFilter && other.sampler == sampler;
  @override
  int get hashCode => sampler.hashCode;

  @override
  String toString() => 'StatsSamplerFilter($sampler)';
}

/// 只看某个步数 → `filterMinSteps = filterMaxSteps = steps`。
final class StatsStepsFilter extends StatsGalleryFilter {
  const StatsStepsFilter(this.steps);
  final int steps;

  @override
  bool operator ==(Object other) =>
      other is StatsStepsFilter && other.steps == steps;
  @override
  int get hashCode => steps.hashCode;

  @override
  String toString() => 'StatsStepsFilter($steps)';
}

/// 只看某个 CFG → `filterMinCfg = filterMaxCfg = cfg`。
final class StatsCfgFilter extends StatsGalleryFilter {
  const StatsCfgFilter(this.cfg);
  final double cfg;

  @override
  bool operator ==(Object other) => other is StatsCfgFilter && other.cfg == cfg;
  @override
  int get hashCode => cfg.hashCode;

  @override
  String toString() => 'StatsCfgFilter($cfg)';
}

/// 在本地画廊搜索 `artist:{name}`。
final class StatsArtistFilter extends StatsGalleryFilter {
  const StatsArtistFilter(this.name);
  final String name;

  @override
  bool operator ==(Object other) =>
      other is StatsArtistFilter && other.name == name;
  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'StatsArtistFilter($name)';
}

/// 只看没有元数据的图（等价于 `has_metadata = 0`）。
final class StatsNoMetadataFilter extends StatsGalleryFilter {
  const StatsNoMetadataFilter();

  @override
  bool operator ==(Object other) => other is StatsNoMetadataFilter;
  @override
  int get hashCode => 0;

  @override
  String toString() => 'StatsNoMetadataFilter()';
}

/// 只看文件不小于 [bytes] 的图 → `minFileSize`。
final class StatsMinFileSizeFilter extends StatsGalleryFilter {
  const StatsMinFileSizeFilter(this.bytes);
  final int bytes;

  @override
  bool operator ==(Object other) =>
      other is StatsMinFileSizeFilter && other.bytes == bytes;
  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => 'StatsMinFileSizeFilter($bytes)';
}

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/utils/localization_extension.dart';
import 'online_contract.dart';

/// 卡片墙的排版规则（和原型的 `mas()` 一致）。
abstract final class OnlineLayout {
  static const gap = 12.0;

  /// 墙的内边距：左右 18、上 2、下 18。
  static const padding = EdgeInsets.fromLTRB(18, 2, 18, 18);

  static double targetWidth(OnlineCardSize size) => switch (size) {
    OnlineCardSize.small => 160,
    OnlineCardSize.medium => 210,
    OnlineCardSize.large => 280,
  };

  static int columns(double width, OnlineCardSize size) =>
      math.max(1, ((width + gap) / (targetWidth(size) + gap)).ceil());

  /// 图片高：按原图比例，夹在 80 到 宽 × 2.5 之间。
  static double imageHeight(double width, double aspect) =>
      (width / aspect).clamp(80, width * 2.5).toDouble();

  /// 卡片下面的文字区高：AI TAG 两行（标题 17.5 + 作者 17.25），Danbooru 系一行，小卡片不写。
  static double captionHeight({required bool aiTag, required bool small}) =>
      small ? 0 : (aiTag ? 6 + 17.5 + 17.25 : 6 + 14);

  /// 分列时估算用的文字区高（原型按 44 / 24 估算），只影响放到哪一列。
  static double captionEstimate({required bool aiTag, required bool small}) =>
      small ? 0 : (aiTag ? 44 : 24);

  /// 瀑布流：依次放进当前最矮的一列。返回每列的条目下标。
  static List<List<int>> assign(List<double> estimatedHeights, int columns) {
    final heights = List<double>.filled(columns, 0);
    final out = [for (var i = 0; i < columns; i++) <int>[]];
    for (final (i, h) in estimatedHeights.indexed) {
      var j = 0;
      for (var k = 1; k < columns; k++) {
        if (heights[k] < heights[j]) j = k;
      }
      out[j].add(i);
      heights[j] += h + gap;
    }
    return out;
  }
}

abstract final class OnlineFormat {
  /// 12840 → 12.8k，1000 → 1k，980 → 980。
  static String count(int n) {
    if (n < 1000) return '$n';
    final s = (n / 1000).toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}k';
  }

  static String bytes(int n) {
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(0)} KB';
    return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  static String date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// 时间范围 id → 文案：`all` 全部时间、`y2025` 2025 年、`q2025Q3` 2025 Q3、`older` 更早归档。
  static String timeRange(BuildContext context, String id) {
    final l10n = context.l10n;
    if (id == 'all') return l10n.online_timeAll;
    if (id == 'older') return l10n.online_timeOlder;
    final q = RegExp(r'^q(\d{4})Q([1-4])$').firstMatch(id);
    if (q != null) return '${q[1]} Q${q[2]}';
    final y = RegExp(r'^y(\d{4})$').firstMatch(id);
    if (y != null) return l10n.online_timeYear(y[1]!);
    return id;
  }

  static String model(OnlineModel m) => switch (m) {
    OnlineModel.v3 => 'V3',
    OnlineModel.v4 => 'V4',
    OnlineModel.v45 => 'V4.5',
    OnlineModel.v5 => 'V5',
  };

  static String ratingLetter(OnlineRating r) => switch (r) {
    OnlineRating.general => 'G',
    OnlineRating.sensitive => 'S',
    OnlineRating.questionable => 'Q',
    OnlineRating.explicit => 'E',
  };

  static String ratingLabel(BuildContext context, OnlineRating r) {
    final l10n = context.l10n;
    return switch (r) {
      OnlineRating.general => l10n.online_ratingG,
      OnlineRating.sensitive => l10n.online_ratingS,
      OnlineRating.questionable => l10n.online_ratingQ,
      OnlineRating.explicit => l10n.online_ratingE,
    };
  }

  /// 来源色块里的字。
  static String sourceMark(OnlineSource s) => switch (s) {
    OnlineSource.aiTag => 'AI',
    OnlineSource.danbooru => 'D',
    OnlineSource.safebooru => 'S',
    OnlineSource.gelbooru => 'G',
  };

  static String sourceName(OnlineSource s) => switch (s) {
    OnlineSource.aiTag => 'AI TAG',
    OnlineSource.danbooru => 'Danbooru',
    OnlineSource.safebooru => 'Safebooru',
    OnlineSource.gelbooru => 'Gelbooru',
  };

  /// 提示词按逗号切段，含 `artist:` 的段（画师串）标出来。返回 (文字, 是否画师串)。
  static List<(String, bool)> promptSegments(String prompt) {
    final out = <(String, bool)>[];
    final parts = prompt.split(',');
    for (final (i, part) in parts.indexed) {
      final lead = part.length - part.trimLeft().length;
      if (lead > 0) out.add((part.substring(0, lead), false));
      final body = part.substring(lead);
      out.add((body, body.contains('artist:')));
      if (i < parts.length - 1) out.add((',', false));
    }
    return out;
  }
}

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import 'viewer_contract.dart';

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

/// “1,284”。
String viewerNumber(BuildContext context, int n) =>
    NumberFormat.decimalPattern(_locale(context)).format(n);

/// “1.49 MB” / “820.5 KB”。
String viewerBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '$bytes B';
}

/// “2026-08-31 00:38”。
String viewerDateTime(DateTime t) => DateFormat('yyyy-MM-dd HH:mm').format(t);

/// 胶片条日期分隔“8月28日”。
String viewerDay(BuildContext context, DateTime t) =>
    DateFormat.MMMd(_locale(context)).format(t);

/// “刚刚 / 2 分钟前 / 3 小时前 / 昨天 / 8月28日”。
String viewerAgo(BuildContext context, DateTime t, DateTime now) {
  final l10n = context.l10n;
  final d = now.difference(t);
  if (d.inMinutes < 1) return l10n.imageViewer_justNow;
  if (d.inHours < 1) return l10n.imageViewer_minutesAgo(d.inMinutes);
  if (d.inDays < 1 && now.day == t.day) {
    return l10n.imageViewer_hoursAgo(d.inHours);
  }
  if (d.inDays < 2) return l10n.imageViewer_yesterday;
  return viewerDay(context, t);
}

/// 5 / 4.5 / 0.35：整数不带小数点。
String viewerDecimal(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(3);
  return s.replaceFirst(RegExp(r'0+$'), '');
}

String viewerSortLabel(AppLocalizations l10n, ViewerSort s) => switch (s) {
  ViewerSort.modified => l10n.imageViewer_sortModified,
  ViewerSort.created => l10n.imageViewer_sortCreated,
  ViewerSort.fileName => l10n.imageViewer_sortFileName,
  ViewerSort.fileSize => l10n.imageViewer_sortFileSize,
  ViewerSort.dimensions => l10n.imageViewer_sortDimensions,
};

/// 角色位置（0–1）落在 5 × 5 格里的哪一格：(列, 行)。
(int, int) viewerCell(double? x, double? y) =>
    (((x ?? .5) * 5).floor().clamp(0, 4), ((y ?? .5) * 5).floor().clamp(0, 4));

/// “C3”。
String viewerCellName(double? x, double? y) {
  final (cx, cy) = viewerCell(x, y);
  return '${'ABCDE'[cx]}${cy + 1}';
}

/// 负面按逗号数项数。
int viewerTagCount(String s) =>
    s.split(',').where((t) => t.trim().isNotEmpty).length;

/// 快捷键显示成键帽：`Ctrl R`、`←`、`?`。
List<String> viewerKeyLabels(SingleActivator a) {
  final k = a.trigger;
  final name = switch (k.keyLabel) {
    'Arrow Left' => '←',
    'Arrow Right' => '→',
    'Arrow Up' => '↑',
    'Arrow Down' => '↓',
    'Escape' => 'Esc',
    'Delete' => 'Delete',
    'Numpad Add' => '+',
    'Numpad Subtract' => '−',
    final s => s,
  };
  if (a.shift && name == '/') return const ['?'];
  return [
    if (a.control) 'Ctrl',
    if (a.alt) 'Alt',
    if (a.shift) 'Shift',
    if (a.meta) 'Meta',
    name,
  ];
}

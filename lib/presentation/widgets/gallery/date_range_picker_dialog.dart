import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/localization_extension.dart';

/// 点选式日期范围选择状态（纯状态机，便于单元测试）
///
/// 交互规则（用户要求）：
/// - 无选择时点某天 → 选中该天（单日）
/// - 已选单日时点另一天 → 变成两天之间的范围（含首尾）
/// - 已有完整范围时点任意一天 → 全部取消选择（回到无选择）
@immutable
class DateRangeSelectionState {
  final DateTime? start;
  final DateTime? end;

  const DateRangeSelectionState({this.start, this.end});

  /// 无选择
  bool get hasSelection => start != null;

  /// 单日（start == end）
  bool get isSingleDay => start != null && end != null && start == end;

  /// 完整范围（start < end）
  bool get isRange => start != null && end != null && start != end;

  /// 点击某一天的状态转换
  DateRangeSelectionState tap(DateTime day) {
    if (start == null) {
      return DateRangeSelectionState(start: day, end: day);
    }
    if (!isRange) {
      if (day == start) return this;
      return day.isBefore(start!)
          ? DateRangeSelectionState(start: day, end: start)
          : DateRangeSelectionState(start: start, end: day);
    }
    return const DateRangeSelectionState();
  }

  /// 是否为选中日（单日的头尾或范围的两端）
  bool isSelectedDay(DateTime day) => start == day || end == day;

  /// 是否在已选范围内（含首尾）
  bool isInRange(DateTime day) =>
      hasSelection && !day.isBefore(start!) && !day.isAfter(end!);
}

/// 轻量手搓月视图日历对话框（不用系统 showDatePicker/showDateRangePicker）
///
/// 确定后返回 [DateRangeSelectionState]（单日 = start == end），
/// 取消返回 null。禁选未来日期。
class DateRangePickerDialog extends StatefulWidget {
  /// 初始选择的起始日（可为 null）
  final DateTime? initialStart;

  /// 初始选择的结束日（可为 null）
  final DateTime? initialEnd;

  /// 可选的起始日期（默认 2020-01-01）
  final DateTime? firstDate;

  const DateRangePickerDialog({
    super.key,
    this.initialStart,
    this.initialEnd,
    this.firstDate,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  late DateTime _visibleMonth;
  late DateRangeSelectionState _selection;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    final initial = widget.initialStart ?? _today;
    _visibleMonth = DateTime(initial.year, initial.month);
    _selection = DateRangeSelectionState(
      start: widget.initialStart == null
          ? null
          : _dateOnly(widget.initialStart!),
      end: widget.initialEnd == null ? null : _dateOnly(widget.initialEnd!),
    );
  }

  DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  DateTime get _firstDate => widget.firstDate ?? DateTime(2020);

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  bool _isDisabled(DateTime day) {
    final lastEnabledDay = DateTime(_today.year, _today.month, _today.day);
    return day.month != _visibleMonth.month ||
        day.isAfter(lastEnabledDay) ||
        day.isBefore(_firstDate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final localeName = l10n.localeName;
    final monthTitle = l10n.localGallery_dateRangeYearMonth(
      '${_visibleMonth.year}',
      '${_visibleMonth.month}',
    );
    final weekdayLabels = List.generate(
      7,
      (i) => DateFormat('E', localeName).format(
        DateTime(2026, 1, 5 + i), // 2026-01-05 是周一
      ),
    );

    // 当月首日所在周的周一作为网格起点，固定 6 行
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final gridStart = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));

    return Dialog(
      child: SizedBox(
        width: 336,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 年月标题 + 翻月
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: l10n.localGallery_dateRangePrevMonth,
                    onPressed: () {
                      final target = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                      if (!target.isBefore(DateTime(_firstDate.year, _firstDate.month))) {
                        _changeMonth(-1);
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      monthTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: l10n.localGallery_dateRangeNextMonth,
                    onPressed: _visibleMonth.isBefore(DateTime(_today.year, _today.month))
                        ? () => _changeMonth(1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 星期标题
              Row(
                children: [
                  for (final label in weekdayLabels)
                    Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // 6×7 日期格子
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final day in days) _buildDayCell(theme, day),
                ],
              ),
              const SizedBox(height: 8),
              // 清除 / 取消 / 确定
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 清除：仅当进入对话框时已有日期范围（initialStart/initialEnd
                  // 任一非空）才可用；点击清空选择并关闭，调用方写入空范围
                  TextButton(
                    onPressed: widget.initialStart != null ||
                            widget.initialEnd != null
                        ? () => Navigator.of(context).pop(
                            const DateRangeSelectionState(),
                          )
                        : null,
                    child: Text(l10n.localGallery_dateRangeClear),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.common_cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selection.hasSelection
                        ? () => Navigator.of(context).pop(_selection)
                        : null,
                    child: Text(l10n.common_confirm),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(ThemeData theme, DateTime day) {
    final inCurrentMonth = day.month == _visibleMonth.month;
    final disabled = _isDisabled(day);
    final isToday = day == _today;
    final isSelected = _selection.isSelectedDay(day);
    final inRange = _selection.isInRange(day);

    final textColor = disabled
        ? theme.colorScheme.onSurface.withValues(alpha: 0.2)
        : inCurrentMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.35);

    return Center(
      child: GestureDetector(
        onTap: disabled ? null : () => _onDayTapped(day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? theme.colorScheme.primary
                : inRange
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                : null,
            border: isToday && !isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : textColor,
              fontWeight: isToday || isSelected
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  void _onDayTapped(DateTime day) {
    setState(() {
      _selection = _selection.tap(day);
    });
  }
}

/// 打开日期范围选择对话框
///
/// 返回 null 表示取消；否则为确定后的选择（单日 = start == end）。
Future<DateRangeSelectionState?> showDateRangePickerDialog(
  BuildContext context, {
  DateTime? initialStart,
  DateTime? initialEnd,
  DateTime? firstDate,
}) {
  return showDialog<DateRangeSelectionState>(
    context: context,
    builder: (context) => DateRangePickerDialog(
      initialStart: initialStart,
      initialEnd: initialEnd,
      firstDate: firstDate,
    ),
  );
}

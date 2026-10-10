import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'statistics_contract.dart';
import 'statistics_format.dart';

/// 顶栏：标题 + 副标题；时间范围；仅 NAI 图片；更新状态 + 刷新。高 56。
class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key, required this.data, required this.actions});

  final StatsViewData data;
  final StatsActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final chrome = WindowChromeScope.activeOf(context);
    final status = _statusOf(context, data);
    return WindowHeader(
      dragBackground: true,
      inlineDragWidth: 12,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      // 页面不足约 900 宽（最小窗口 800）时紧凑：不显示副标题，开关只写 NAI，
      // 更新状态收进刷新按钮的提示，只留进度圈 / 失败红点。
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 750;
          return SizedBox(
            height: 55,
            child: Padding(
              padding: EdgeInsets.only(left: 24, right: chrome ? 0 : 24),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.stats_title,
                        style: UiText.sans(
                          16,
                          weight: FontWeight.w600,
                          color: c.ink,
                          height: 1.25,
                        ),
                      ),
                      if (!compact)
                        Text(
                          l10n.stats_subtitle,
                          maxLines: 1,
                          style: UiText.sans(11, color: c.faint, height: 1.25),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // 右侧控件靠右；空间不够时只有更新状态省略（全文在刷新按钮的提示里）。
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        UiSegmented<StatsRange>(
                          key: const Key('stats-range'),
                          values: StatsRange.values,
                          selected: data.range,
                          labelOf: (r) => switch (r) {
                            StatsRange.thisYear => l10n.stats_rangeThisYear,
                            StatsRange.all => l10n.stats_rangeAll,
                            _ => l10n.stats_rangeDays('${r.days}'),
                          },
                          onChanged: actions.onRangeChanged,
                        ),
                        const SizedBox(width: 12),
                        UiChipButton(
                          key: const Key('stats-nai-only'),
                          semanticLabel: l10n.stats_naiOnly,
                          onPressed: () =>
                              actions.onNaiOnlyChanged(!data.naiOnly),
                          children: [
                            compact
                                ? Tooltip(
                                    message: l10n.stats_naiOnly,
                                    child: const Text('NAI'),
                                  )
                                : Text(l10n.stats_naiOnly),
                            UiSwitch(value: data.naiOnly),
                          ],
                        ),
                        if (compact && status?.tone == _Tone.busy) ...[
                          const SizedBox(width: 12),
                          const UiSpinner(),
                        ] else if (compact && status?.tone == _Tone.error) ...[
                          const SizedBox(width: 12),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ] else if (!compact && status != null) ...[
                          const SizedBox(width: 12),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: _SyncStatus(status: status),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  UiIconButton(
                    key: const Key('stats-refresh'),
                    glyph: UiGlyphs.refresh,
                    tooltip: status == null
                        ? l10n.stats_refresh
                        : '${status.text} · ${l10n.stats_refresh}',
                    onPressed: actions.onRefresh,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _Tone { faint, busy, error }

class _Status {
  const _Status(this.text, this.tone);
  final String text;
  final _Tone tone;
}

_Status? _statusOf(BuildContext context, StatsViewData data) {
  final l10n = context.l10n;
  if (data.snapshot == null && data.errorMessage != null) return null;
  if (data.sync == StatsSyncState.updating || data.snapshot == null) {
    final counting = data.snapshot == null && data.countingImages != null;
    return _Status(
      counting
          ? l10n.stats_counting(StatsFormat.count(data.countingImages!))
          : l10n.stats_updating,
      _Tone.busy,
    );
  }
  if (data.sync == StatsSyncState.failed) {
    return _Status(l10n.stats_updateFailed, _Tone.error);
  }
  final at = data.updatedAt;
  if (at == null) return null;
  final sameDay =
      at.year == data.today.year &&
      at.month == data.today.month &&
      at.day == data.today.day;
  final time = sameDay
      ? StatsFormat.time(at)
      : '${StatsFormat.monthDay(context, at)} ${StatsFormat.time(at)}';
  return _Status(l10n.stats_updatedAt(time), _Tone.faint);
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.status});
  final _Status status;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final text = Text(
      status.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.sans(
        12,
        color: switch (status.tone) {
          _Tone.faint => c.faint,
          _Tone.busy => c.muted,
          _Tone.error => c.error,
        },
      ),
    );
    if (status.tone != _Tone.busy) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const UiSpinner(),
        const SizedBox(width: 6),
        Flexible(child: text),
      ],
    );
  }
}

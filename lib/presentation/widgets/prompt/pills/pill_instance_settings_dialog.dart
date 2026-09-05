import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../../l10n/app_localizations.dart';

/// L2 块实例随机设置弹窗（P2.5）：草稿式编辑——确定返回新设置
/// （由调用方 `updateInstanceSettings` 按实例锁定状态决定是否重 roll），取消返回 null。
///
/// 控件全集覆盖五类典型场景（画师串探索/场景串/质量词组/彩蛋块/普通块），
/// 无模式切换成本；离散预设只是左右离散的快捷写入。
class PillInstanceSettingsDialog extends StatefulWidget {
  const PillInstanceSettingsDialog({super.key, required this.initial});

  final PillInstanceSettings initial;

  /// 弹出设置对话框；取消/点外关闭返回 null。
  static Future<PillInstanceSettings?> show(
    BuildContext context,
    PillInstanceSettings initial,
  ) {
    return showDialog<PillInstanceSettings>(
      context: context,
      builder: (_) => PillInstanceSettingsDialog(initial: initial),
    );
  }

  @override
  State<PillInstanceSettingsDialog> createState() =>
      _PillInstanceSettingsDialogState();
}

class _PillInstanceSettingsDialogState
    extends State<PillInstanceSettingsDialog> {
  late PillInstanceSettings _draft = widget.initial;
  bool _advancedExpanded = false;

  /// 离散预设（集中/均衡/发散）→ 左右离散同写。
  static const double _dispersionFocused = 0.15;
  static const double _dispersionBalanced = 0.4;
  static const double _dispersionSpread = 0.85;

  void _update(PillInstanceSettings Function(PillInstanceSettings) change) {
    setState(() => _draft = change(_draft));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isRandom = _draft.mode == PillRollMode.random;

    return AlertDialog(
      title: Text(l10n.pillSettingsTitle),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<PillRollMode>(
                segments: [
                  ButtonSegment(
                    value: PillRollMode.fixed,
                    label: Text(l10n.pillSettingsModeFixed),
                  ),
                  ButtonSegment(
                    value: PillRollMode.random,
                    label: Text(l10n.pillSettingsModeRandom),
                  ),
                ],
                selected: {_draft.mode},
                onSelectionChanged: (selection) =>
                    _update((d) => d.copyWith(mode: selection.first)),
              ),
              if (isRandom) ...[
                const SizedBox(height: 12),
                _buildCountRow(theme, l10n),
                const SizedBox(height: 8),
                _buildOrderRow(l10n),
                const Divider(height: 24),
                _buildWeightSection(theme, l10n),
                const Divider(height: 24),
                _buildTriggerRow(theme, l10n),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.pillSettingsCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_normalized()),
          child: Text(l10n.pillSettingsApply),
        ),
      ],
    );
  }

  /// 数量行：min~max 整数滑杆（0~20，池不足 roll 时截断）。
  Widget _buildCountRow(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.pillSettingsCount}  ${_draft.countMin} ~ ${_draft.countMax}',
          style: theme.textTheme.bodySmall,
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _draft.countMin.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                onChanged: (v) => _update(
                  (d) => d.copyWith(
                    countMin: v.round(),
                    countMax: d.countMax < v.round() ? v.round() : d.countMax,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _draft.countMax.toDouble(),
                min: 0,
                max: 20,
                divisions: 20,
                onChanged: (v) => _update(
                  (d) => d.copyWith(
                    countMax: v.round(),
                    countMin: d.countMin > v.round() ? v.round() : d.countMin,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderRow(AppLocalizations l10n) {
    return Row(
      children: [
        Text(l10n.pillSettingsOrder),
        const SizedBox(width: 12),
        DropdownButton<PillRollOrder>(
          value: _draft.order,
          isDense: true,
          items: [
            DropdownMenuItem(
              value: PillRollOrder.drawn,
              child: Text(l10n.pillSettingsOrderDrawn),
            ),
            DropdownMenuItem(
              value: PillRollOrder.original,
              child: Text(l10n.pillSettingsOrderOriginal),
            ),
          ],
          onChanged: (value) {
            if (value != null) _update((d) => d.copyWith(order: value));
          },
        ),
      ],
    );
  }

  Widget _buildWeightSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.pillSettingsWeight),
            const Spacer(),
            Switch(
              value: _draft.weightEnabled,
              onChanged: (v) => _update((d) => d.copyWith(weightEnabled: v)),
            ),
          ],
        ),
        if (_draft.weightEnabled) ...[
          _weightSlider(
            theme,
            label: l10n.pillSettingsWeightMin,
            value: _draft.weightMin,
            onChanged: (v) => _update((d) => d.copyWith(weightMin: v)),
          ),
          _weightSlider(
            theme,
            label: l10n.pillSettingsWeightMax,
            value: _draft.weightMax,
            onChanged: (v) => _update((d) => d.copyWith(weightMax: v)),
          ),
          _weightSlider(
            theme,
            label: l10n.pillSettingsWeightAverage,
            value: _draft.weightAverage,
            onChanged: (v) => _update((d) => d.copyWith(weightAverage: v)),
          ),
          const SizedBox(height: 4),
          Text(l10n.pillSettingsDispersion, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              _dispersionChip(
                l10n.pillSettingsDispersionFocused,
                _dispersionFocused,
              ),
              _dispersionChip(
                l10n.pillSettingsDispersionBalanced,
                _dispersionBalanced,
              ),
              _dispersionChip(
                l10n.pillSettingsDispersionSpread,
                _dispersionSpread,
              ),
            ],
          ),
          ExpansionTile(
            title: Text(l10n.pillSettingsAdvanced),
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: _advancedExpanded,
            onExpansionChanged: (v) => _advancedExpanded = v,
            children: [
              _unitSlider(
                theme,
                label: l10n.pillSettingsLeftDispersion,
                value: _draft.leftDispersion,
                onChanged: (v) => _update((d) => d.copyWith(leftDispersion: v)),
              ),
              _unitSlider(
                theme,
                label: l10n.pillSettingsRightDispersion,
                value: _draft.rightDispersion,
                onChanged: (v) =>
                    _update((d) => d.copyWith(rightDispersion: v)),
              ),
              Row(
                children: [
                  Text(l10n.pillSettingsSoftBalance),
                  const Spacer(),
                  Switch(
                    value: _draft.softBalance,
                    onChanged: (v) =>
                        _update((d) => d.copyWith(softBalance: v)),
                  ),
                ],
              ),
              if (_draft.softBalance)
                _unitSlider(
                  theme,
                  label: l10n.pillSettingsSoftBalanceStrength,
                  value: _draft.softBalanceStrength,
                  onChanged: (v) =>
                      _update((d) => d.copyWith(softBalanceStrength: v)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTriggerRow(ThemeData theme, AppLocalizations l10n) {
    final percent = (_draft.triggerProbability * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.pillSettingsTriggerProbability}  $percent%',
          style: theme.textTheme.bodySmall,
        ),
        Slider(
          value: _draft.triggerProbability,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (v) => _update((d) => d.copyWith(triggerProbability: v)),
        ),
      ],
    );
  }

  Widget _dispersionChip(String label, double value) {
    final selected =
        (_draft.leftDispersion - value).abs() < 1e-6 &&
        (_draft.rightDispersion - value).abs() < 1e-6;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _update(
        (d) => d.copyWith(leftDispersion: value, rightDispersion: value),
      ),
    );
  }

  /// 权重滑杆：-3.0~3.0，0.1 步进（与引擎离散化网格一致）。
  Widget _weightSlider(
    ThemeData theme, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label ${value.toStringAsFixed(1)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: PillInstanceSettings.weightFloor,
            max: PillInstanceSettings.weightCeiling,
            divisions: 60,
            onChanged: (v) => onChanged((v * 10).roundToDouble() / 10),
          ),
        ),
      ],
    );
  }

  Widget _unitSlider(
    ThemeData theme, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label ${value.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// 应用前归一化：min/max 防倒置、平均夹进范围。
  PillInstanceSettings _normalized() {
    var s = _draft;
    if (s.countMin > s.countMax) {
      s = s.copyWith(countMin: s.countMax, countMax: s.countMin);
    }
    if (s.weightMin > s.weightMax) {
      s = s.copyWith(weightMin: s.weightMax, weightMax: s.weightMin);
    }
    return s.copyWith(
      weightAverage: s.weightAverage.clamp(s.weightMin, s.weightMax),
    );
  }
}

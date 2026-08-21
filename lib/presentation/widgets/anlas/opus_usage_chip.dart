import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/image/image_params.dart';
import '../../../data/models/user/user_subscription.dart';
import '../../../data/services/personal_anlas_counter_service.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/subscription_provider.dart';

/// Opus 免费额度芯片（V5 起）
///
/// V5 模型的 Opus 免费生成按次数配额，额度随时间自动回充。服务端在
/// `/user/subscription` 下发 `usage.percent` / `isNegative` /
/// `timeUntilNextPercent`，见 [OpusUsage]。
///
/// 仅在「当前模型带 `opusUsageLimit` 能力 + 账号有额度数据」时显示，
/// 其余情况（V4 及更早、非 Opus 账号）整体隐藏，不占位。
class OpusUsageChip extends ConsumerWidget {
  /// 紧凑模式（移动端 / 钉底条使用）
  final bool compact;

  /// 外边距。芯片隐藏时不生效，避免在不支持额度的模型下留下空隙。
  final EdgeInsetsGeometry? margin;

  const OpusUsageChip({super.key, this.compact = false, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUsageLimit = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.modelSpec.opusUsageLimit,
      ),
    );
    if (!hasUsageLimit) return const SizedBox.shrink();

    final usage = ref.watch(
      subscriptionNotifierProvider.select(
        (state) => state.subscription?.usage,
      ),
    );
    if (usage == null) return const SizedBox.shrink();

    // 合租账本：账号池是硬约束，我的份额是软约束，任一见底都该变红。
    final personal = ref.watch(personalAnlasCounterProvider);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLow = usage.isLow || personal.isOpusAllowanceExhausted;
    final accent = isLow ? scheme.error : scheme.primary;

    final chip = InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(subscriptionNotifierProvider.notifier).refreshBalance();
      },
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: _tooltip(usage, personal),
        child: compact
            ? Column(
                // 紧凑模式（钉底条）：上「账号总额度」下「我的份额」两格，
                // 与右侧余额/我的点数两格同规格（图标 16/字号 14/行距 4），
                // 合成 2×2 整体；右对齐让两列之间的缝隙上下等宽
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildQuotaCell(
                    scheme,
                    icon: Icons.bolt_outlined,
                    iconColor: isLow ? scheme.error : scheme.primary,
                    text: usage.isNegative
                        ? '0%'
                        : '${_fmtPercent(usage.percent)}%',
                    textColor: isLow ? scheme.error : scheme.onSurfaceVariant,
                    warning: isLow,
                  ),
                  const SizedBox(height: 4),
                  _buildQuotaCell(
                    scheme,
                    icon: Icons.pie_chart_outline,
                    iconColor: personal.isOpusAllowanceExhausted
                        ? scheme.error
                        : scheme.secondary,
                    text: '${_fmtPercent(personal.opusAllowance)}%',
                    textColor: personal.isOpusAllowanceExhausted
                        ? scheme.error
                        : scheme.secondary,
                    warning: personal.isOpusAllowanceExhausted,
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isLow
                      ? scheme.errorContainer.withValues(alpha: 0.3)
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_outlined, size: 16, color: accent),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: usage.displayPercent / 100,
                          minHeight: 5,
                          backgroundColor: scheme.onSurfaceVariant.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      usage.isNegative
                          ? '0%'
                          : '${_fmtPercent(usage.percent)}%',
                      style: TextStyle(
                        color: isLow ? scheme.error : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    // 合租账本：账号池后面跟一个「我的份额」，两个数一眼对照
                    Text(
                      ' · 我 ${_fmtPercent(personal.opusAllowance)}%',
                      style: TextStyle(
                        color: personal.isOpusAllowanceExhausted
                            ? scheme.error
                            : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

    return margin == null ? chip : Padding(padding: margin!, child: chip);
  }

  /// 紧凑模式的单格：与 AnlasBalanceChip/PersonalAnlasChip 完全同规格
  /// （内边距 12/6、图标 16、字号 14、圆角 8），保证 2×2 网格逐行对齐
  Widget _buildQuotaCell(
    ColorScheme scheme, {
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    required bool warning,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warning
            ? scheme.errorContainer.withValues(alpha: 0.3)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 额度百分比格式化：官方 `percent` 是浮点数，带小数就显示一位，整数不拖 `.0`
  static String _fmtPercent(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }

  String _tooltip(OpusUsage usage, PersonalAnlasState personal) {
    final lines = <String>[
      usage.isNegative
          ? '账号免费额度已用尽，V5 生成按 Anlas 计费'
          : '账号免费额度剩余 ${usage.percent.toStringAsFixed(1)}%（含合租他人用量）',
    ];

    lines.add(
      personal.isOpusAllowanceExhausted
          ? '我的份额已用尽（${personal.opusAllowance.toStringAsFixed(1)}%'
                '／上限 ${personal.opusAllowanceCap.toStringAsFixed(0)}%）'
          : '我的份额剩 ${personal.opusAllowance.toStringAsFixed(1)}%'
                '／上限 ${personal.opusAllowanceCap.toStringAsFixed(0)}%',
    );
    lines.add(
      '账号额度涨了按 ${(personal.opusRefillShare * 100).toStringAsFixed(0)}% '
      '分给我，跌了按实测扣',
    );

    lines.add('点击刷新');
    return lines.join('\n');
  }
}

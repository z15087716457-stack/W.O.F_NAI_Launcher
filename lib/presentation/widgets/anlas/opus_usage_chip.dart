import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/image/image_params.dart';
import '../../../data/models/user/user_subscription.dart';
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
///
/// 额度条是动态的：数值刷新时平滑过渡；回充中（`timeUntilNextPercent > 0`）
/// 有一道高光循环扫过，直观表达「池子正在涨」。
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
      subscriptionNotifierProvider.select((state) => state.subscription?.usage),
    );
    if (usage == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLow = usage.isLow;
    final accent = isLow ? scheme.error : scheme.primary;
    final refilling = usage.timeUntilNextPercent > 0;

    final chip = InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(subscriptionNotifierProvider.notifier).refreshBalance();
      },
      borderRadius: BorderRadius.circular(8),
      child: Tooltip(
        message: _tooltip(usage),
        child: compact
            ? _buildQuotaCell(
                scheme,
                text: usage.isNegative
                    ? '0%'
                    : '${_fmtPercent(usage.percent)}%',
                warning: isLow,
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
                    const SizedBox(width: 5),
                    _QuotaBar(
                      value: usage.displayPercent / 100,
                      accent: accent,
                      trackColor: scheme.onSurfaceVariant.withValues(
                        alpha: 0.18,
                      ),
                      refilling: refilling,
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
                  ],
                ),
              ),
      ),
    );

    return margin == null ? chip : Padding(padding: margin!, child: chip);
  }

  /// 紧凑模式的单格：与 AnlasBalanceChip 完全同规格
  /// （内边距 12/6、图标 16、字号 14、圆角 8），保证并排逐行对齐
  Widget _buildQuotaCell(
    ColorScheme scheme, {
    required String text,
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
          Icon(
            Icons.bolt_outlined,
            size: 16,
            color: warning ? scheme.error : scheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: warning ? scheme.error : scheme.onSurfaceVariant,
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

  String _tooltip(OpusUsage usage) {
    final lines = <String>[
      usage.isNegative
          ? '账号免费额度已用尽，V5 生成按 Anlas 计费'
          : '账号免费额度剩余 ${usage.percent.toStringAsFixed(1)}%',
    ];

    lines.add(
      usage.timeUntilNextPercent > 0
          ? '回充中：下一 +1% 还需 ${_fmtCountdown(usage.timeUntilNextPercent)}'
          : '当前不回充（池子在回充阈值之上或已用尽）',
    );

    lines.add('点击刷新');
    return lines.join('\n');
  }

  /// 秒数倒计时格式化：1 小时 23 分 / 5 分 30 秒 / 42 秒
  static String _fmtCountdown(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      return m > 0 ? '$h 小时 $m 分' : '$h 小时';
    }
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '$m 分 $s 秒' : '$m 分';
    }
    return '$seconds 秒';
  }
}

/// 动态额度条
///
/// - 填充段用主色→浅主色横向渐变，数值刷新时经
///   [TweenAnimationBuilder] 平滑过渡（600ms easeOutCubic），
///   服务端每 +1% 回充时条子是滑过去的，不跳变；
/// - [refilling] 为真（服务端回充倒计时在走）时叠加一道白色高光
///   循环扫过，静止时不动画、不重绘。
class _QuotaBar extends StatefulWidget {
  const _QuotaBar({
    required this.value,
    required this.accent,
    required this.trackColor,
    required this.refilling,
  });

  /// 目标进度 (0-1)，越界值会被钳制
  final double value;

  /// 填充主色（低额度时由调用方传 error 色）
  final Color accent;

  /// 轨道底色
  final Color trackColor;

  /// 是否处于回充中（决定扫光动画是否运行）
  final bool refilling;

  @override
  State<_QuotaBar> createState() => _QuotaBarState();
}

class _QuotaBarState extends State<_QuotaBar>
    with SingleTickerProviderStateMixin {
  static const double _barWidth = 64;
  static const double _barHeight = 6;

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.refilling) _sweep.repeat();
  }

  @override
  void didUpdateWidget(covariant _QuotaBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refilling == oldWidget.refilling) return;
    if (widget.refilling) {
      _sweep.repeat();
    } else {
      _sweep
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: _barWidth,
        height: _barHeight,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(_barHeight / 2),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: widget.trackColor),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.lerp(widget.accent, Colors.white, 0.15)!,
                              Color.lerp(widget.accent, Colors.white, 0.45)!,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.refilling)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _sweep,
                        builder: (context, _) {
                          const bandWidth = _barWidth * 0.5;
                          final dx =
                              (_barWidth + bandWidth) * _sweep.value -
                              bandWidth;
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: bandWidth,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/utils/asset_protection_guard.dart';
import 'package:nai_launcher/presentation/widgets/common/app_toast.dart';
import 'package:nai_launcher/presentation/widgets/common/draggable_number_input.dart';
import 'package:nai_launcher/presentation/widgets/generation/auto_save_toggle_chip.dart';
import 'package:nai_launcher/presentation/widgets/anlas/anlas_balance_chip.dart';
import 'package:nai_launcher/presentation/widgets/anlas/opus_usage_chip.dart';
import 'batch_settings_button.dart';
import 'generate_button.dart';

/// 生成控制按钮
class GenerationControls extends ConsumerStatefulWidget {
  /// 紧凑模式：用于官网式布局的钉底控制条——
  /// 强制窄排布、可选批次大小按钮、压低生成按钮高度。
  final bool compact;

  /// 保留给已有调用方的生成调用钩子。
  final void Function()? onGenerateInvoked;

  /// 真实生成入口发出的可等待批次事件。
  final GenerationBatchCallback? onBatchEvent;

  /// 探索页只允许逐张请求，隐藏通用批量控件。
  final bool exploreMode;

  const GenerationControls({
    super.key,
    this.compact = false,
    this.onGenerateInvoked,
    this.onBatchEvent,
    this.exploreMode = false,
  });

  @override
  ConsumerState<GenerationControls> createState() => _GenerationControlsState();
}

class _GenerationControlsState extends ConsumerState<GenerationControls> {
  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(imageGenerationNotifierProvider);
    final cooldownState = ref.watch(generationCooldownProvider);
    final kritaBridgeState = ref.watch(kritaBridgeNotifierProvider);
    final params = ref.watch(generationParamsNotifierProvider);
    final nSamples = params.nSamples;
    final costOverride = widget.exploreMode
        ? ref.watch(estimatedCostForBatchSizeProvider(1))
        : null;
    final isLauncherGenerating = generationState.isGenerating;
    final isGenerating =
        isLauncherGenerating || kritaBridgeState.isBridgeGenerating;

    // 生成中常驻显示取消入口（与移动端一致）
    final showCancel = isLauncherGenerating;

    // 快捷键已由父级 DesktopGenerationLayout 统一处理
    // 这里只负责布局
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = widget.compact || constraints.maxWidth < 500;

        // 生成按钮几何居中：左右两个等宽弹性区吸收其余控件，
        // 按钮位置不随左侧点数块显隐漂移
        final generateButton = GenerateButtonWithCost(
          height: widget.compact ? 40 : 48,
          isGenerating: isGenerating,
          showCancel: showCancel,
          generationState: generationState,
          cooldownRemainingSeconds: cooldownState.remainingSeconds,
          costOverride: costOverride,
          onGenerate: () => unawaited(_handleGenerate(context, ref)),
          onCancel: () =>
              ref.read(imageGenerationNotifierProvider.notifier).cancel(),
          onSkipCurrent: () => ref
              .read(imageGenerationNotifierProvider.notifier)
              .skipCurrentRequest(),
        );

        if (isNarrow) {
          final rightGroup = <Widget>[
            // 紧凑模式生成中隐藏批量调节（此时批量参数不可变更），
            // 为跳过/停止按钮腾出宽度
            if (!(widget.compact && showCancel))
              DraggableNumberInput(
                value: nSamples,
                min: 1,
                prefix: '×',
                onChanged: (value) {
                  ref
                      .read(generationParamsNotifierProvider.notifier)
                      .updateNSamples(value);
                },
              ),
            // 紧凑模式补上第二种批量控制：批次大小（每次请求张数）
            if (widget.compact && !widget.exploreMode && !showCancel) ...[
              const SizedBox(width: 4),
              const BatchSettingsButton(),
            ],
          ];

          if (widget.compact) {
            if (constraints.maxWidth < 360) {
              Widget fit(Widget child) => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              );

              return Wrap(
                key: const Key('generation-controls-compact-wrap'),
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  fit(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const OpusUsageChip(
                          compact: true,
                          margin: EdgeInsets.only(right: 8),
                        ),
                        AnlasBalanceChip(
                          estimatedCostOverride: costOverride,
                        ),
                      ],
                    ),
                  ),
                  fit(generateButton),
                  fit(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...rightGroup,
                        const SizedBox(width: 8),
                        const AutoSaveToggleChip(compact: true),
                      ],
                    ),
                  ),
                ],
              );
            }

            // 官网钉底条：正常宽度保持单行，左右点数组与生成按钮对齐。
            // 极窄宽度在上方分支中改为三组自动换行，避免控件横向溢出。
            return Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 隐藏（V4）时 shrink 不占位，
                          // 与余额芯片的 8 间距随自己的 margin 一起消失
                          const OpusUsageChip(
                            compact: true,
                            margin: EdgeInsets.only(right: 8),
                          ),
                          AnlasBalanceChip(
                            estimatedCostOverride: costOverride,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                generateButton,
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...rightGroup,
                          const SizedBox(width: 8),
                          const AutoSaveToggleChip(compact: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // 经典布局窄宽：单行三段，生成按钮居中
          return Row(
            children: [
              const SizedBox(width: 8),
              generateButton,
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: rightGroup,
                  ),
                ),
              ),
            ],
          );
        }

        // 正常布局 - 自动保存锚最左，点数贴按钮左，批量控件贴按钮右；
        // 左右组空间不足时内部等比缩小，避免溢出叠到生成按钮上
        return Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const AutoSaveToggleChip(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnlasBalanceChip(
                              estimatedCostOverride: costOverride,
                            ),
                            const OpusUsageChip(
                              margin: EdgeInsets.only(left: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            generateButton,
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 12),
                      DraggableNumberInput(
                        value: nSamples,
                        min: 1,
                        prefix: '×',
                        onChanged: (value) {
                          ref
                              .read(generationParamsNotifierProvider.notifier)
                              .updateNSamples(value);
                        },
                      ),
                      if (!widget.exploreMode) ...[
                        const SizedBox(width: 16),
                        const BatchSettingsButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGenerate(BuildContext context, WidgetRef ref) async {
    final params = ref.read(generationParamsNotifierProvider);
    if (params.prompt.isEmpty) {
      AppToast.warning(context, context.l10n.generation_pleaseInputPrompt);
      return;
    }

    final confirmed = await AssetProtectionGuard.confirmHighAnlasCost(
      context: context,
      ref: ref,
      cost: widget.exploreMode
          ? ref.read(estimatedCostForBatchSizeProvider(1))
          : null,
    );
    if (!confirmed || !context.mounted) {
      return;
    }

    // 生成（探索模式在真实批次 start 前完成布防，并强制逐张请求）。
    ref
        .read(imageGenerationNotifierProvider.notifier)
        .generate(
          params,
          onBatchEvent: widget.onBatchEvent,
          imagesPerRequestOverride: widget.exploreMode ? 1 : null,
        );
    widget.onGenerateInvoked?.call();
  }
}

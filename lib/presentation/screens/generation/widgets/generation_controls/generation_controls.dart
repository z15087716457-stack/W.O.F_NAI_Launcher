import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/utils/asset_protection_guard.dart';
import 'package:nai_launcher/presentation/widgets/common/app_toast.dart';
import 'package:nai_launcher/presentation/widgets/generation/auto_save_toggle_chip.dart';
import 'package:nai_launcher/presentation/widgets/anlas/anlas_balance_chip.dart';
import 'package:nai_launcher/presentation/widgets/anlas/opus_usage_chip.dart';
import 'generate_button.dart';
import '../../../../providers/generation/image_workflow_controller.dart';

/// 生成控制按钮
class GenerationControls extends ConsumerStatefulWidget {
  /// 紧凑模式：用于官网式布局的钉底控制条——压低生成按钮高度。
  final bool compact;

  /// 保留给已有调用方的生成调用钩子。
  final void Function()? onGenerateInvoked;

  /// 真实生成入口发出的可等待批次事件。
  final GenerationBatchCallback? onBatchEvent;

  /// 探索页只允许逐张请求，隐藏通用批量控件。
  final bool exploreMode;

  /// 是否显示 Opus 额度 / Anlas 余额芯片。
  /// 生成页左栏把这两个芯片挪到了头部条，传 false 关闭底栏渲染；
  /// 画风探索页等其它调用方保持默认 true。
  final bool showBalanceChips;

  /// 是否显示自动保存开关芯片。
  /// 生成页左栏把它挪到了历史面板标题栏，传 false 关闭底栏渲染。
  final bool showAutoSaveChip;

  const GenerationControls({
    super.key,
    this.compact = false,
    this.onGenerateInvoked,
    this.onBatchEvent,
    this.exploreMode = false,
    this.showBalanceChips = true,
    this.showAutoSaveChip = true,
  });

  @override
  ConsumerState<GenerationControls> createState() => _GenerationControlsState();
}

class _GenerationControlsState extends ConsumerState<GenerationControls> {
  /// 生成按钮文案种子：总数变化 / 一次生成结束时推进，按钮换上新文案
  int _copySeed = 0;
  int _lastImageCount = -1;
  bool _wasGenerating = false;

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(imageGenerationNotifierProvider);
    final cooldownState = ref.watch(generationCooldownProvider);
    final kritaBridgeState = ref.watch(kritaBridgeNotifierProvider);
    final params = ref.watch(generationParamsNotifierProvider);
    final perRequest = ref.watch(imagesPerRequestProvider);
    final costOverride = widget.exploreMode
        ? ref.watch(estimatedCostForBatchSizeProvider(1))
        : null;
    final isLauncherGenerating = generationState.isGenerating;
    // 探索页：runner 会话期间手动生成会与逐张生成互相抢占批次 id、
    // 且 roll 快照与工作区投影分叉——runner 在跑即视为生成中，禁用按钮。
    final exploreRunnerBusy = widget.exploreMode
        ? ref.watch(exploreRunRunnerProvider).isRunning
        : false;
    final isGenerating =
        isLauncherGenerating ||
        ref.watch(
          imageWorkflowControllerProvider.select((w) => w.isToolRunning),
        ) ||
        kritaBridgeState.isBridgeGenerating ||
        exploreRunnerBusy;

    // 生成中常驻显示取消入口（与移动端一致）
    final showCancel = isLauncherGenerating;

    // 探索页强制逐张请求：文案张数只反映请求次数
    final imageCount = widget.exploreMode
        ? params.nSamples
        : params.nSamples * perRequest;
    if (imageCount != _lastImageCount) {
      _lastImageCount = imageCount;
      _copySeed++;
    }
    if (_wasGenerating && !isGenerating) {
      _copySeed++;
    }
    _wasGenerating = isGenerating;

    // 快捷键已由父级 WebStyleGenerationLayout 统一处理
    // 这里只负责布局
    final generateButton = GenerateButtonWithCost(
      labelOverride:
          !widget.exploreMode &&
              ref.watch(
                imageWorkflowControllerProvider.select((w) => w.isEnhance),
              )
          ? context.l10n.img2img_enhanceAction
          : null,
      height: widget.compact ? 40 : 48,
      isGenerating: isGenerating,
      showCancel: showCancel,
      generationState: generationState,
      cooldownRemainingSeconds: cooldownState.remainingSeconds,
      costOverride: costOverride,
      imageCount: imageCount,
      copySeed: _copySeed,
      onGenerate: () => unawaited(_handleGenerate(context, ref)),
      onCancel: () =>
          ref.read(imageGenerationNotifierProvider.notifier).cancel(),
      onSkipCurrent: () => ref
          .read(imageGenerationNotifierProvider.notifier)
          .skipCurrentRequest(),
    );

    final autoSaveChip = widget.showAutoSaveChip
        ? AutoSaveToggleChip(compact: widget.compact)
        : null;

    // 整条官网式单排：可选点数芯片靠左，生成按钮撑满剩余宽度，
    // 可选自动保存芯片靠右；外层 LayoutBuilder 让极窄场景整组等比缩小
    final balanceChips = widget.showBalanceChips
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const OpusUsageChip(
                compact: true,
                margin: EdgeInsets.only(right: 8),
              ),
              AnlasBalanceChip(estimatedCostOverride: costOverride),
            ],
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = Row(
          children: [
            if (balanceChips != null) ...[
              balanceChips,
              const SizedBox(width: 8),
            ],
            Expanded(child: generateButton),
            if (autoSaveChip != null) ...[
              const SizedBox(width: 8),
              autoSaveChip,
            ],
          ],
        );

        // 极窄场景（探索页多栏挤压下主编辑可压到近 0）：整组等比缩小
        // 而不溢出——按钮文案本身还有 Flexible+省略号兜底。
        const minNaturalWidth = 220.0;
        if (constraints.maxWidth >= minNaturalWidth ||
            !constraints.hasBoundedWidth) {
          return inner;
        }
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(width: minNaturalWidth, child: inner),
          ),
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

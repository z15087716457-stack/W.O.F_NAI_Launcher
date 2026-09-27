import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../utils/prompt_block_generation_settings_applier.dart';
import '../../../utils/prompt_block_instance_bundle.dart';
import '../../common/app_toast.dart';
import '../../common/thumbnail_display.dart';
import '../blocks/prompt_block_colors.dart';
import '../blocks/prompt_block_tag_chip.dart';
import 'dna_icon.dart';
import 'pill_instance_settings_dialog.dart';

/// L1 块实例卡（P2.5）：点药丸弹出的点击位置浮卡。
///
/// 内容 = 实例当前提示词（随机/顺序模式显示物化的 currentRoll——即
/// 「L1 显示 = 生成发送 = token 计数」三者同一份；固定模式显示块库实时
/// 内容）+ 按模式分化的操作行（FEAT-46）：固定=设置/启停/删除；
/// 顺序=←→ 逐幕步进/设置/启停/锁定/删除；随机=重抽/设置/启停/遗传/锁定/删除。
/// 设置钮为全模式共有——L2 弹窗的 SegmentedButton 是唯一模式切换入口，
/// 任一模式缺它都会堵死回不去。
///
/// 宿主编辑器用 [buildPillInstanceOverlayEntry] 生成 OverlayEntry 并自行
/// 持有/关闭；实例消失（文本里标记被删）时卡片自动请求关闭。
class PillInstanceCard extends ConsumerStatefulWidget {
  const PillInstanceCard({
    super.key,
    required this.scope,
    required this.marker,
    required this.onDismiss,
    this.allowEvolutionToggle = false,
  });

  final String scope;
  final String marker;
  final VoidCallback onDismiss;

  /// 探索页才渲染遗传开关钮；主生成页不渲染（FEAT-47）。
  final bool allowEvolutionToggle;

  @override
  ConsumerState<PillInstanceCard> createState() => _PillInstanceCardState();
}

class _PillInstanceCardState extends ConsumerState<PillInstanceCard> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scope = widget.scope;
    final marker = widget.marker;
    final counterpart = _counterpartScope(scope);
    if (counterpart != null) ref.watch(pillWorkspaceProvider(counterpart));
    final workspace = ref.watch(pillWorkspaceProvider(scope));
    final workspaceNotifier = ref.read(pillWorkspaceProvider(scope).notifier);
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final instance = workspace.document.instances[marker];

    if (instance == null) {
      // 实例已随文本编辑消失：帧末请求关闭，不留死卡
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDismiss());
      return const SizedBox.shrink();
    }

    final block = library?.blockById(instance.blockId);
    final bundle = readPromptBlockInstanceBundle(ref, scope, marker);
    final color = promptBlockColorFromString(block?.color ?? '#FF607D8B');
    final mode = bundle.isPaired ? bundle.mode : instance.settings.mode;
    final canRoll = bundle.members.any(
      (member) => member.instance.settings.hasRoll && !member.instance.locked,
    );
    final hasRoll = instance.settings.hasRoll;
    final effectiveRoll = workspaceNotifier.effectiveRollFor(marker);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    block?.displayTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (block?.tags.isNotEmpty == true)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: PromptBlockTagStrip(tags: block!.tags),
                  ),
              ],
            ),
            // 有图块：横图 280×120、竖图 280×200，坐标系与块库详情一致
            // （offset/scale 全保真）。
            if (block?.thumbnail != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                key: ValueKey('pill-instance-thumbnail-${block!.id}'),
                borderRadius: BorderRadius.circular(8),
                child: ThumbnailDisplay(
                  imagePath: block.thumbnail!,
                  offsetX: block.thumbnailOffsetX,
                  offsetY: block.thumbnailOffsetY,
                  scale: block.thumbnailScale,
                  width: 280,
                  height: 120,
                  portraitHeight: 200,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _buildPreview(context, block, bundle),
            const SizedBox(height: 4),
            Row(
              children: [
                // FEAT-46：模式专属钮分化——随机=重抽、顺序=←→ 步进；
                // 设置/启停为全模式共有（设置弹窗是唯一模式切换入口）。
                if (mode == PillRollMode.random)
                  _cardButton(
                    key: const Key('pill-reroll'),
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    tooltip: !canRoll
                        ? l10n.pillCardRerollLocked
                        : l10n.pillCardReroll,
                    onPressed: canRoll
                        ? () => rollPromptBlockBundle(ref, scope, marker)
                        : null,
                  ),
                if (mode == PillRollMode.sequential) ...[
                  _cardButton(
                    key: const Key('pill-step-back'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    tooltip: l10n.pillCardStepBack,
                    onPressed: canRoll
                        ? () => rollPromptBlockBundle(
                            ref,
                            scope,
                            marker,
                            direction: -1,
                          )
                        : null,
                  ),
                  _cardButton(
                    key: const Key('pill-step-forward'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    tooltip: l10n.pillCardStepForward,
                    onPressed: canRoll
                        ? () => rollPromptBlockBundle(
                            ref,
                            scope,
                            marker,
                            direction: 1,
                          )
                        : null,
                  ),
                ],
                _cardButton(
                  icon: const Icon(Icons.tune, size: 18),
                  tooltip: l10n.pillCardSettings,
                  onPressed: () => _openSettings(context, ref, instance),
                ),
                _cardButton(
                  icon: Icon(
                    instance.enabled
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  tooltip: instance.enabled
                      ? l10n.pillCardDisable
                      : l10n.pillCardEnable,
                  onPressed: () => workspaceNotifier.toggleEnabled(marker),
                ),
                // FEAT-46/47：遗传钮只出现在探索页的随机块上（顺序块已失
                // 去遗传入口，固定块本无可遗传内容）。
                if (mode == PillRollMode.random && widget.allowEvolutionToggle)
                  Builder(
                    builder: (context) {
                      final evolutionTooltip = !instance.enabled
                          ? l10n.pillCardEvolutionRequiresEnabled
                          : instance.evolutionEnabled
                          ? l10n.pillCardEvolutionDisable
                          : l10n.pillCardEvolutionEnable;
                      return IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        key: const Key('pill-evolution-toggle'),
                        icon: DnaIcon(
                          size: 18,
                          color: instance.enabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.45,
                                ),
                        ),
                        tooltip: evolutionTooltip,
                        onPressed: instance.enabled
                            ? () => workspaceNotifier.toggleEvolution(marker)
                            : null,
                      );
                    },
                  ),
                const Spacer(),
                if (hasRoll)
                  _cardButton(
                    key: const Key('pill-lock-toggle'),
                    icon: Icon(
                      instance.locked
                          ? Icons.lock_outline
                          : Icons.lock_open_outlined,
                      size: 18,
                    ),
                    tooltip: instance.locked
                        ? l10n.pillCardUnlock
                        : l10n.pillCardLock,
                    onPressed: effectiveRoll != null
                        ? () => workspaceNotifier.toggleLocked(marker)
                        : null,
                  ),
                _cardButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: l10n.pillCardDeleteInstance,
                  onPressed: () {
                    removePromptBlockBundle(ref, scope, marker);
                    widget.onDismiss();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _counterpartScope(String scope) {
    if (scope == PillScopes.main) return PillScopes.negative;
    if (scope == PillScopes.negative) return PillScopes.main;
    final positive = RegExp(r'^char:(.+):pos$').firstMatch(scope);
    if (positive != null) return PillScopes.charNeg(positive.group(1)!);
    final negative = RegExp(r'^char:(.+):neg$').firstMatch(scope);
    return negative == null ? null : PillScopes.charPos(negative.group(1)!);
  }

  Widget _buildPreview(
    BuildContext context,
    PromptBlock? block,
    PromptBlockInstanceBundle bundle,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String textFor(BundleMember? member, String fallback) {
      if (member == null) return fallback;
      if (!member.instance.settings.hasRoll) return fallback;
      return ref
              .read(pillWorkspaceProvider(member.scope).notifier)
              .effectiveRollFor(member.marker) ??
          '';
    }

    final positive = textFor(bundle.positive, block?.content ?? '');
    final negative = textFor(bundle.negative, block?.negativeContent ?? '');
    final labels = [
      l10n.promptBlockLibrary_basicPrompt,
      l10n.pillCard_negativeScope,
      l10n.promptBlockLibrary_generationSettings,
    ];
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 3),
            child: Row(
              children: [
                for (var index = 0; index < labels.length; index++)
                  InkWell(
                    key: Key('pill-preview-tab-$index'),
                    onTap: () => setState(() => _tab = index),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _tab == index
                            ? theme.colorScheme.surfaceContainerHigh
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        labels[index],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _tab == index
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
          ),
          if (_tab != 2)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100, maxHeight: 145),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Text(
                  (_tab == 0 ? positive : negative).trim().isEmpty
                      ? l10n.pillCardEmptyRoll
                      : (_tab == 0 ? positive : negative),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            _buildSettingsPreview(block, bundle),
        ],
      ),
    );
  }

  Widget _buildSettingsPreview(
    PromptBlock? block,
    PromptBlockInstanceBundle bundle,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = block?.generationSettings;
    final rows = <(String, String)>[
      if (settings?.model != null)
        (
          l10n.generation_model,
          ImageModels.modelDisplayNames[settings!.model] ?? settings.model!,
        ),
      if (settings?.steps != null)
        (l10n.promptBlockLibrary_stepsLabel, '${settings!.steps}'),
      if (settings?.scale != null) ('PG', '${settings!.scale}'),
      if (settings?.cfgRescale != null) ('PGR', '${settings!.cfgRescale}'),
      if (settings?.sampler != null)
        (
          l10n.generation_sampler,
          Samplers.samplerDisplayNames[settings!.sampler] ?? settings.sampler!,
        ),
      if (settings?.noiseSchedule != null)
        (
          l10n.promptBlockLibrary_noiseScheduleLabel,
          NoiseSchedules.displayNames[settings!.noiseSchedule] ??
              settings.noiseSchedule!,
        ),
    ];
    Widget scopeButton(int bit, String label, bool available) {
      final selected = bundle.mask & bit != 0;
      return InkWell(
        key: Key(bit == 1 ? 'pill-scope-positive' : 'pill-scope-negative'),
        onTap: available && bundle.isPaired
            ? () => updatePromptBlockBundleScope(
                ref,
                widget.scope,
                widget.marker,
                bundle.mask ^ bit,
              )
            : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: .12)
                : null,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: .5)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: available
                  ? (selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant)
                  : theme.disabledColor,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            Text(
              l10n.promptBlockLibrary_noSettings,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 5,
              children: [
                for (final row in rows)
                  SizedBox(
                    width: 126,
                    child: Row(
                      children: [
                        Text(
                          '${row.$1}  ',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: .5),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                l10n.pillCard_rollScope,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              scopeButton(
                1,
                l10n.pillCard_positiveScope,
                bundle.positive != null && block?.content.isNotEmpty == true,
              ),
              const SizedBox(width: 5),
              scopeButton(
                2,
                l10n.pillCard_negativeScope,
                bundle.negative != null &&
                    block?.negativeContent.isNotEmpty == true,
              ),
            ],
          ),
          if (settings != null && !settings.isEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('pill-apply-block-settings'),
                onPressed: () {
                  try {
                    applyPromptBlockGenerationSettings(ref, settings);
                    AppToast.success(
                      context,
                      l10n.promptBlockLibrary_settingsApplied,
                    );
                    widget.onDismiss();
                  } on StateError {
                    AppToast.warning(
                      context,
                      l10n.promptBlockLibrary_settingsIncompatible,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 29),
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  textStyle: theme.textTheme.labelSmall,
                ),
                child: Text(l10n.promptBlockLibrary_applySettings),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 卡内 40×40 紧凑钮的统一外形。
  Widget _cardButton({
    Key? key,
    required Widget icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      key: key,
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Future<void> _openSettings(
    BuildContext context,
    WidgetRef ref,
    PillInstance instance,
  ) async {
    // B1：浮卡条目压在路由条目之上，弹窗打开期间卡的全屏 barrier 会吃掉
    // 弹窗内点击并把卡片销毁；确定后的异步续体再用已销毁的 ref 必抛
    // StateError（静默吞），设置永远不写。故同步发起弹窗（showDialog 立即
    // 解析 Navigator）并捕获存活于 ProviderContainer 的 notifier，随后
    // 显式关卡，结果异步经 notifier 应用。
    final bundle = readPromptBlockInstanceBundle(
      ref,
      widget.scope,
      widget.marker,
    );
    final source = bundle.members.firstWhere(
      (member) => member.instance.settings.hasRoll,
      orElse: () => BundleMember(widget.scope, widget.marker, instance),
    );
    final updates = [
      for (final member in bundle.members)
        (
          ref.read(pillWorkspaceProvider(member.scope).notifier),
          member.marker,
          member.instance.useNegativeContent ? 2 : 1,
        ),
    ];
    final dialogFuture = PillInstanceSettingsDialog.show(
      context,
      source.instance.settings,
    );
    widget.onDismiss();
    final result = await dialogFuture;
    if (result == null) return;
    for (final update in updates) {
      update.$1.updateInstanceSettings(
        update.$2,
        result.copyWith(
          mode: bundle.isPaired && bundle.mask & update.$3 == 0
              ? PillRollMode.fixed
              : result.mode,
        ),
      );
    }
  }
}

/// 生成 L1 浮卡的 OverlayEntry：透明 barrier 点外关闭，卡片定位于点击处
/// 附近（下优先、贴边 clamp、底部越界时翻到上方）。
OverlayEntry buildPillInstanceOverlayEntry({
  required String scope,
  required String marker,
  required Offset globalPosition,
  required VoidCallback onDismiss,
  bool allowEvolutionToggle = false,
}) {
  return OverlayEntry(
    builder: (overlayContext) {
      final overlay = Overlay.of(overlayContext, rootOverlay: true);
      final overlayBox = overlay.context.findRenderObject()! as RenderBox;
      final screen = overlayBox.size;
      final localPosition = overlayBox.globalToLocal(globalPosition);
      const cardWidth = 300.0;
      // 含缩略图条时的估高（无图卡稍高估只会影响贴底翻转阈值，无害）。
      const estimatedHeight = 510.0;
      final left = (localPosition.dx - cardWidth / 2)
          .clamp(8.0, (screen.width - cardWidth - 8).clamp(8.0, screen.width))
          .toDouble();
      final below = localPosition.dy + 10;
      final top = below + estimatedHeight > screen.height
          ? (localPosition.dy - estimatedHeight - 10)
                .clamp(8.0, screen.height)
                .toDouble()
          : below;
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onDismiss,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: cardWidth,
            child: PillInstanceCard(
              scope: scope,
              marker: marker,
              onDismiss: onDismiss,
              allowEvolutionToggle: allowEvolutionToggle,
            ),
          ),
        ],
      );
    },
  );
}

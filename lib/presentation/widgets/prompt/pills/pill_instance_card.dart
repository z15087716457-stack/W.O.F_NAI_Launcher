import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../common/thumbnail_display.dart';
import '../blocks/prompt_block_colors.dart';
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
class PillInstanceCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final workspace = ref.watch(pillWorkspaceProvider(scope));
    final workspaceNotifier = ref.read(pillWorkspaceProvider(scope).notifier);
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final instance = workspace.document.instances[marker];

    if (instance == null) {
      // 实例已随文本编辑消失：帧末请求关闭，不留死卡
      WidgetsBinding.instance.addPostFrameCallback((_) => onDismiss());
      return const SizedBox.shrink();
    }

    final block = library?.blockById(instance.blockId);
    final color = promptBlockColorFromString(block?.color ?? '#FF607D8B');
    final mode = instance.settings.mode;
    final hasRoll = instance.settings.hasRoll;
    final effectiveRoll = workspaceNotifier.effectiveRollFor(marker);
    final content = hasRoll ? (effectiveRoll ?? '') : (block?.content ?? '');

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
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Text(
                  content.trim().isEmpty ? l10n.pillCardEmptyRoll : content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                // FEAT-46：模式专属钮分化——随机=重抽、顺序=←→ 步进；
                // 设置/启停为全模式共有（设置弹窗是唯一模式切换入口）。
                if (mode == PillRollMode.random)
                  _cardButton(
                    key: const Key('pill-reroll'),
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    tooltip: instance.locked
                        ? l10n.pillCardRerollLocked
                        : l10n.pillCardReroll,
                    onPressed: !instance.locked
                        ? () => workspaceNotifier.rollMarker(marker)
                        : null,
                  ),
                if (mode == PillRollMode.sequential) ...[
                  _cardButton(
                    key: const Key('pill-step-back'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    tooltip: l10n.pillCardStepBack,
                    onPressed: !instance.locked
                        ? () => workspaceNotifier.stepSequence(marker, -1)
                        : null,
                  ),
                  _cardButton(
                    key: const Key('pill-step-forward'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    tooltip: l10n.pillCardStepForward,
                    onPressed: !instance.locked
                        ? () => workspaceNotifier.stepSequence(marker, 1)
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
                if (mode == PillRollMode.random && allowEvolutionToggle)
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
                    workspaceNotifier.removeMarker(marker);
                    onDismiss();
                  },
                ),
              ],
            ),
          ],
        ),
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
    final dialogFuture = PillInstanceSettingsDialog.show(
      context,
      instance.settings,
    );
    final notifier = ref.read(pillWorkspaceProvider(scope).notifier);
    onDismiss();
    final result = await dialogFuture;
    if (result == null) return;
    notifier.updateInstanceSettings(marker, result);
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
      final screen = MediaQuery.of(overlayContext).size;
      const cardWidth = 300.0;
      // 含缩略图条时的估高（无图卡稍高估只会影响贴底翻转阈值，无害）。
      const estimatedHeight = 570.0;
      final left = (globalPosition.dx - cardWidth / 2)
          .clamp(8.0, (screen.width - cardWidth - 8).clamp(8.0, screen.width))
          .toDouble();
      final below = globalPosition.dy + 10;
      final top = below + estimatedHeight > screen.height
          ? (globalPosition.dy - estimatedHeight - 10)
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../blocks/prompt_block_colors.dart';
import 'pill_instance_settings_dialog.dart';

/// L1 块实例卡（P2.5）：点药丸弹出的点击位置浮卡。
///
/// 内容 = 实例当前提示词（随机模式显示物化的 currentRoll——即「L1 显示
/// = 生成发送 = token 计数」三者同一份；固定模式显示块库实时内容）+
/// 操作行：🎲 重 roll / ⚙ 进 L2 / 启停 / 删除。
///
/// 宿主编辑器用 [buildPillInstanceOverlayEntry] 生成 OverlayEntry 并自行
/// 持有/关闭；实例消失（文本里标记被删）时卡片自动请求关闭。
class PillInstanceCard extends ConsumerWidget {
  const PillInstanceCard({
    super.key,
    required this.scope,
    required this.marker,
    required this.onDismiss,
  });

  final String scope;
  final String marker;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final workspace = ref.watch(pillWorkspaceProvider(scope));
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final instance = workspace.document.instances[marker];

    if (instance == null) {
      // 实例已随文本编辑消失：帧末请求关闭，不留死卡
      WidgetsBinding.instance.addPostFrameCallback((_) => onDismiss());
      return const SizedBox.shrink();
    }

    final block = library?.blockById(instance.blockId);
    final color = promptBlockColorFromString(block?.color ?? '#FF607D8B');
    final isRandom = instance.settings.isRandom;
    final content = isRandom
        ? (instance.currentRoll ?? '')
        : (block?.content ?? '');

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
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 66),
              child: Text(
                content.trim().isEmpty ? l10n.pillCardEmptyRoll : content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  tooltip: l10n.pillCardReroll,
                  onPressed: isRandom
                      ? () => ref
                            .read(pillWorkspaceProvider(scope).notifier)
                            .rollMarker(marker)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.tune, size: 18),
                  tooltip: l10n.pillCardSettings,
                  onPressed: () => _openSettings(context, ref, instance),
                ),
                IconButton(
                  icon: Icon(
                    instance.enabled
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  tooltip: instance.enabled
                      ? l10n.pillCardDisable
                      : l10n.pillCardEnable,
                  onPressed: () => ref
                      .read(pillWorkspaceProvider(scope).notifier)
                      .toggleEnabled(marker),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: l10n.pillCardDeleteInstance,
                  onPressed: () {
                    ref
                        .read(pillWorkspaceProvider(scope).notifier)
                        .removeMarker(marker);
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
}) {
  return OverlayEntry(
    builder: (overlayContext) {
      final screen = MediaQuery.of(overlayContext).size;
      const cardWidth = 300.0;
      const estimatedHeight = 190.0;
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
            ),
          ),
        ],
      );
    },
  );
}

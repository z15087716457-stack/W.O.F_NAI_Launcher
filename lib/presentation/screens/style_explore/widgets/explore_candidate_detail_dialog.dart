import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import 'explore_candidate_actions.dart';
import 'explore_folder_assign_bar.dart';

/// 候选详情弹窗：大图 + Roll 快照全文（可复制）+ seed + 参数快照 + 归类区
/// + 出口动作（收编为块 / 导入元数据 / 删除候选图）。
///
/// 按 id 实时解析 run 与候选，收藏/归类/删图等写操作后内容自动刷新。
/// 翻页（左右箭头 + ←/→/小键盘）走打开瞬间传入的快照序列，边界停住不循环。
class ExploreCandidateDetailDialog extends ConsumerStatefulWidget {
  const ExploreCandidateDetailDialog({
    super.key,
    required this.runId,
    required this.candidateIds,
    this.initialIndex = 0,
  });

  final String runId;

  /// 翻页序（打开瞬间的筛选快照，按顺序）。
  final List<String> candidateIds;

  final int initialIndex;

  @override
  ConsumerState<ExploreCandidateDetailDialog> createState() =>
      _ExploreCandidateDetailDialogState();
}

class _ExploreCandidateDetailDialogState
    extends ConsumerState<ExploreCandidateDetailDialog> {
  late int _index = widget.initialIndex.clamp(
    0,
    widget.candidateIds.isEmpty ? 0 : widget.candidateIds.length - 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    final candidate = _resolve(run);

    if (run == null || candidate == null) {
      return Dialog(
        key: const Key('explore-candidate-detail'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.styleExplore_candidateMissing,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.common_close),
              ),
            ],
          ),
        ),
      );
    }

    final generation = candidate.generation;
    final snapshot = run.paramsSnapshot;
    final roll = candidate.rollSnapshot;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        key: const Key('explore-candidate-detail'),
        child: ConstrainedBox(
          // 详情弹窗给足图区：窗口随屏取 85%×88%（E2 定稿，网格排版不动）。
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.styleExplore_candidateDetailTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (widget.candidateIds.length > 1)
                      Text(
                        l10n.styleExplore_candidatePosition(
                          _index + 1,
                          widget.candidateIds.length,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    IconButton(
                      tooltip: l10n.common_close,
                      iconSize: 18,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 图:信息 = 7:3（静定）：图区给足，信息列窄排
                    Expanded(
                      flex: 7,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildDetailImage(theme, l10n, candidate),
                          ),
                          if (_canMove(run, -1))
                            Positioned(
                              left: 4,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _buildPagerButton(
                                  key: const Key('explore-candidate-prev'),
                                  icon: Icons.chevron_left,
                                  tooltip: l10n.styleExplore_prevCandidate,
                                  onPressed: () => _move(run, -1),
                                ),
                              ),
                            ),
                          if (_canMove(run, 1))
                            Positioned(
                              right: 4,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: _buildPagerButton(
                                  key: const Key('explore-candidate-next'),
                                  icon: Icons.chevron_right,
                                  tooltip: l10n.styleExplore_nextCandidate,
                                  onPressed: () => _move(run, 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: theme.dividerColor),
                    Expanded(
                      flex: 3,
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                snapshot.model,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '${snapshot.width}×${snapshot.height}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'steps ${snapshot.steps}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'scale ${snapshot.scale}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                snapshot.sampler,
                                style: theme.textTheme.bodySmall,
                              ),
                              if (generation.seed != null)
                                Text(
                                  l10n.styleExplore_seedLabel(
                                    generation.seed.toString(),
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (generation.elapsedMs != null)
                                Text(
                                  '${generation.elapsedMs} ms',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],
                          ),
                          if (generation.error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              generation.error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildExportActions(
                            context,
                            ref,
                            theme,
                            l10n,
                            run,
                            candidate,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                l10n.styleExplore_rollSnapshot,
                                style: theme.textTheme.titleSmall,
                              ),
                              const Spacer(),
                              IconButton(
                                key: const Key(
                                  'explore-candidate-copy-snapshot',
                                ),
                                tooltip: l10n.common_copy,
                                iconSize: 18,
                                onPressed: roll == null
                                    ? null
                                    : () => _copySnapshot(context, roll),
                                icon: const Icon(Icons.copy_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (roll != null) ...[
                            SelectableText(
                              roll.positive,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              roll.negative,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (roll.instanceRolls.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              for (final instance in roll.instanceRolls)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: SelectableText(
                                    '[${instance.lane}] '
                                    '${instance.blockTitle}: '
                                    '${instance.rolledText}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ] else
                            Text(
                              l10n.styleExplore_previewEmpty,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 16),
                          ExploreFolderAssignBar(
                            run: run,
                            candidate: candidate,
                            onAssigned: (folderId) =>
                                _advanceAfterAssign(run, folderId),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 当前位候选；记录已删（详情打开期间）返回 null。
  ExploreCandidate? _resolve(ExploreRun? run) {
    if (run == null || widget.candidateIds.isEmpty) return null;
    return run.candidateById(widget.candidateIds[_index]);
  }

  /// 该方向是否还有可翻的候选（跳过已删记录；边界停住不循环）。
  bool _canMove(ExploreRun run, int delta) {
    var next = _index + delta;
    while (next >= 0 && next < widget.candidateIds.length) {
      if (run.candidateById(widget.candidateIds[next]) != null) return true;
      next += delta;
    }
    return false;
  }

  void _move(ExploreRun run, int delta) {
    var next = _index + delta;
    while (next >= 0 && next < widget.candidateIds.length) {
      if (run.candidateById(widget.candidateIds[next]) != null) {
        setState(() => _index = next);
        return;
      }
      next += delta;
    }
  }

  /// 归档后自动跳到下一张未分类候选（连续归档不打断）；已无则留在原地。
  void _advanceAfterAssign(ExploreRun run, String? folderId) {
    if (folderId == null || !mounted) return;
    for (var next = _index + 1; next < widget.candidateIds.length; next++) {
      final candidate = run.candidateById(widget.candidateIds[next]);
      if (candidate == null) continue;
      if (candidate.folderId == null) {
        setState(() => _index = next);
        return;
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final run = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    if (run == null) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.numpad4) {
      if (_canMove(run, -1)) _move(run, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.numpad6) {
      if (_canMove(run, 1)) _move(run, 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildPagerButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  /// 出口动作行：收编为块 / 导入元数据 / 删除候选图（有副本即可删）。
  Widget _buildExportActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    ExploreCandidate candidate,
  ) {
    final roll = candidate.rollSnapshot;
    final canDeleteImage = candidate.generation.filePath != null;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          key: const Key('explore-candidate-adopt-block'),
          onPressed: roll == null
              ? null
              : () => ExploreCandidateActions.adoptSingle(
                  context,
                  ref,
                  run: run,
                  candidate: candidate,
                ),
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: Text(l10n.styleExplore_adoptAsBlock),
        ),
        OutlinedButton.icon(
          key: const Key('explore-candidate-fixate'),
          onPressed: roll == null
              ? null
              : () => ExploreCandidateActions.fixateAsTemplate(
                  context,
                  ref,
                  candidate: candidate,
                ),
          icon: const Icon(Icons.input_outlined, size: 16),
          label: Text(l10n.styleExplore_fixateAsTemplate),
        ),
        if (canDeleteImage)
          OutlinedButton.icon(
            key: const Key('explore-candidate-delete-image'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => ExploreCandidateActions.deleteImage(
              context,
              ref,
              runId: run.id,
              candidate: candidate,
            ),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: Text(l10n.styleExplore_deleteImage),
          ),
      ],
    );
  }

  Widget _buildDetailImage(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreCandidate candidate,
  ) {
    final filePath = candidate.generation.filePath;
    if (filePath == null) {
      return _ThumbnailPlaceholder(
        icon: Icons.broken_image_outlined,
        tooltip: l10n.styleExplore_candidateMissing,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.file(
        File(filePath),
        fit: BoxFit.contain,
        // 详情大图按图区尺寸解码（原图全尺寸解码是内存尖峰）。
        cacheWidth: 1600,
        errorBuilder: (context, error, stackTrace) => _ThumbnailPlaceholder(
          icon: Icons.broken_image_outlined,
          tooltip: l10n.styleExplore_candidateMissing,
        ),
      ),
    );
  }

  void _copySnapshot(BuildContext context, ExploreRollSnapshot roll) {
    final buffer = StringBuffer()
      ..writeln(roll.positive)
      ..write('---\n')
      ..writeln(roll.negative);
    for (final instance in roll.instanceRolls) {
      buffer.writeln(
        '[${instance.lane}] ${instance.blockTitle}: ${instance.rolledText}',
      );
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.styleExplore_copiedToClipboard),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({required this.icon, this.tooltip});

  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Center(
      child: Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
    );
    final message = tooltip;
    if (message == null || message.isEmpty) return child;
    return Tooltip(message: message, child: child);
  }
}

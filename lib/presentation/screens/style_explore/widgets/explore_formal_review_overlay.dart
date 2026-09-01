import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';

/// 正式筛选全屏覆盖层（阶段 C）。
///
/// 归类目标 = 该 run 全部生成成功（done）候选。键盘/按钮双通道：
/// T=珍宝 / S=特殊 / R=拒绝（打正式标签 `review.label`+`formalReviewedAt`），
/// ←/→ 导航，Backspace 撤销上一张归类（回到它并清标签），Esc 退出
/// （已打标签保留、run 保持 reviewing，可再进入续筛）。
/// 全部归类完成前「完成筛选」禁用；完成 → run 状态 completed。
class ExploreFormalReviewOverlay extends ConsumerStatefulWidget {
  const ExploreFormalReviewOverlay({super.key, required this.runId});

  final String runId;

  /// 以全屏对话框打开；返回 true = 用户点「完成筛选」且 run 已 completed。
  static Future<bool> show(
    BuildContext context, {
    required String runId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Dialog.fullscreen(child: ExploreFormalReviewOverlay(runId: runId)),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ExploreFormalReviewOverlay> createState() =>
      _ExploreFormalReviewOverlayState();
}

class _ExploreFormalReviewOverlayState
    extends ConsumerState<ExploreFormalReviewOverlay> {
  /// 当前位置；null = 未手动定位（自动取第一个未归类）。
  int? _index;

  /// 本次会话打标栈（Backspace 撤销依据，仅存候选 id）。
  final List<String> _undoStack = [];

  /// 标签写盘串行队列：快速连打时逐条落盘，避免读-改-写竞态互相覆盖。
  Future<void> _writeQueue = Future<void>.value();

  void _enqueue(Future<void> Function() action) {
    _writeQueue = _writeQueue.then((_) => action()).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);

    if (run == null) {
      return _FallbackScaffold(
        message: l10n.styleExplore_galleryEmptyHint,
        onClose: () => Navigator.of(context).pop(false),
      );
    }
    final reviewable = run.reviewableCandidates;
    if (reviewable.isEmpty) {
      return _FallbackScaffold(
        message: l10n.styleExplore_galleryEmptyHint,
        onClose: () => Navigator.of(context).pop(false),
      );
    }

    final index = (_index ?? _firstUnlabeled(reviewable)).clamp(
      0,
      reviewable.length - 1,
    );
    final candidate = reviewable[index];
    final labeled = run.formallyReviewedCount;
    final total = reviewable.length;
    final complete = labeled == total;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) =>
            _handleKeyEvent(context, event, reviewable, index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(theme, l10n, run, index, total, labeled, complete),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: _buildMainStage(
                theme,
                l10n,
                candidate,
                index,
                reviewable.length,
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            _buildBottomPanel(theme, l10n, reviewable, index, candidate),
          ],
        ),
      ),
    );
  }

  // ==================== 顶栏 ====================

  Widget _buildTopBar(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreRun run,
    int index,
    int total,
    int labeled,
    bool complete,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('explore-review-exit'),
            tooltip: l10n.styleExplore_reviewExit,
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              run.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.styleExplore_runGeneratingProgress(index + 1, total),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.styleExplore_reviewProgress(labeled, total),
            key: const Key('explore-review-progress'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: complete
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            key: const Key('explore-review-complete'),
            onPressed: complete ? _finish : null,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(l10n.styleExplore_reviewComplete),
          ),
        ],
      ),
    );
  }

  // ==================== 主图区 ====================

  Widget _buildMainStage(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreCandidate candidate,
    int index,
    int total,
  ) {
    final label = candidate.review.label;
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildImage(theme, l10n, candidate),
        ),
        // 当前已归类徽章（右上）。
        if (label != null)
          Positioned(
            right: 20,
            top: 20,
            child: _LabelBadge(label: label, large: true),
          ),
        // 左右导航（与 ←/→ 等价）。
        Positioned(
          left: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton.filledTonal(
              key: const Key('explore-review-prev'),
              tooltip: '←',
              onPressed: index > 0 ? () => _go(index - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
          ),
        ),
        Positioned(
          right: 4,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton.filledTonal(
              key: const Key('explore-review-next'),
              tooltip: '→',
              onPressed: index < total - 1 ? () => _go(index + 1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(
    ThemeData theme,
    AppLocalizations l10n,
    ExploreCandidate candidate,
  ) {
    final filePath = candidate.generation.filePath;
    if (filePath == null) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Image.file(
      File(filePath),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Tooltip(
          message: l10n.styleExplore_candidateMissing,
          child: Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ==================== 底栏：归类按钮 + 缩略图条 ====================

  Widget _buildBottomPanel(
    ThemeData theme,
    AppLocalizations l10n,
    List<ExploreCandidate> reviewable,
    int index,
    ExploreCandidate candidate,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildLabelButton(
                theme,
                l10n,
                label: ExploreReviewLabel.treasure,
                keyName: 'T',
                text: l10n.styleExplore_markTreasure,
                active: candidate.review.label == ExploreReviewLabel.treasure,
              ),
              _buildLabelButton(
                theme,
                l10n,
                label: ExploreReviewLabel.special,
                keyName: 'S',
                text: l10n.styleExplore_markSpecial,
                active: candidate.review.label == ExploreReviewLabel.special,
              ),
              _buildLabelButton(
                theme,
                l10n,
                label: ExploreReviewLabel.reject,
                keyName: 'R',
                text: l10n.styleExplore_markReject,
                active: candidate.review.label == ExploreReviewLabel.reject,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('explore-review-undo'),
                onPressed: _undoStack.isEmpty ? null : _undo,
                icon: const Icon(Icons.undo, size: 18),
                label: Text('${l10n.styleExplore_reviewUndo} (⌫)'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reviewable.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, i) => _buildThumbnail(
                theme,
                reviewable[i],
                selected: i == index,
                onTap: () => _go(i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelButton(
    ThemeData theme,
    AppLocalizations l10n, {
    required ExploreReviewLabel label,
    required String keyName,
    required String text,
    required bool active,
  }) {
    final color = _labelColor(theme, label);
    return FilledButton.tonalIcon(
      key: Key('explore-review-label-${label.name}'),
      onPressed: () => _applyLabel(label),
      icon: Icon(_labelIcon(label), size: 18, color: active ? color : null),
      label: Text('$text ($keyName)'),
      style: active
          ? FilledButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: color,
            )
          : null,
    );
  }

  Widget _buildThumbnail(
    ThemeData theme,
    ExploreCandidate candidate, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final label = candidate.review.label;
    final filePath = candidate.generation.filePath;
    final borderColor = selected
        ? theme.colorScheme.primary
        : (label != null
              ? _labelColor(theme, label)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5));
    return GestureDetector(
      key: Key('explore-review-thumb-${candidate.id}'),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (filePath != null)
              Image.file(
                File(filePath),
                fit: BoxFit.cover,
                cacheWidth: 128,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            if (label != null)
              Positioned(right: 2, bottom: 2, child: _LabelBadge(label: label)),
          ],
        ),
      ),
    );
  }

  // ==================== 键盘与动作 ====================

  KeyEventResult _handleKeyEvent(
    BuildContext context,
    KeyEvent event,
    List<ExploreCandidate> reviewable,
    int index,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyT) {
      _applyLabel(ExploreReviewLabel.treasure);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS) {
      _applyLabel(ExploreReviewLabel.special);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _applyLabel(ExploreReviewLabel.reject);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (index > 0) _go(index - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (index < reviewable.length - 1) _go(index + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      _undo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  int _firstUnlabeled(List<ExploreCandidate> reviewable) {
    for (var i = 0; i < reviewable.length; i++) {
      if (reviewable[i].review.label == null) return i;
    }
    return 0;
  }

  void _go(int index) {
    setState(() => _index = index);
  }

  void _applyLabel(ExploreReviewLabel label) {
    final run = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    if (run == null) return;
    final reviewable = run.reviewableCandidates;
    if (reviewable.isEmpty) return;
    final index = (_index ?? _firstUnlabeled(reviewable)).clamp(
      0,
      reviewable.length - 1,
    );
    final candidate = reviewable[index];
    if (candidate.review.label != label) {
      setState(() => _undoStack.add(candidate.id));
      _enqueue(
        () => ref
            .read(exploreRunListNotifierProvider.notifier)
            .updateReview(
              widget.runId,
              candidate.id,
              label: label,
              formalReviewedAt: DateTime.now(),
            ),
      );
    }
    // 打标后前进一张（末尾停住）。
    if (index < reviewable.length - 1) {
      setState(() => _index = index + 1);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final id = _undoStack.removeLast();
    final run = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    final reviewable = run?.reviewableCandidates ?? const <ExploreCandidate>[];
    final index = reviewable.indexWhere((candidate) => candidate.id == id);
    setState(() {
      if (index >= 0) _index = index;
    });
    _enqueue(
      () => ref
          .read(exploreRunListNotifierProvider.notifier)
          .updateReview(widget.runId, id, clearLabel: true),
    );
  }

  /// 完成筛选：先等打标队列落盘，再做全归类判定。
  Future<void> _finish() async {
    await _writeQueue;
    if (!mounted) return;
    final completed = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .completeReview(widget.runId);
    if (!mounted) return;
    if (completed) {
      Navigator.of(context).pop(true);
    }
  }

  static Color _labelColor(ThemeData theme, ExploreReviewLabel label) {
    switch (label) {
      case ExploreReviewLabel.treasure:
        return Colors.amber.shade700;
      case ExploreReviewLabel.special:
        return Colors.deepPurple;
      case ExploreReviewLabel.reject:
        return theme.colorScheme.error;
    }
  }

  static IconData _labelIcon(ExploreReviewLabel label) {
    switch (label) {
      case ExploreReviewLabel.treasure:
        return Icons.diamond_outlined;
      case ExploreReviewLabel.special:
        return Icons.star_outline;
      case ExploreReviewLabel.reject:
        return Icons.block;
    }
  }
}

/// 归类标签徽章（主图大图与缩略图角标共用）。
class _LabelBadge extends StatelessWidget {
  const _LabelBadge({required this.label, this.large = false});

  final ExploreReviewLabel label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _ExploreFormalReviewOverlayState._labelColor(theme, label);
    final icon = _ExploreFormalReviewOverlayState._labelIcon(label);
    if (!large) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: color),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(switch (label) {
            ExploreReviewLabel.treasure =>
              context.l10n.styleExplore_markTreasure,
            ExploreReviewLabel.special => context.l10n.styleExplore_markSpecial,
            ExploreReviewLabel.reject => context.l10n.styleExplore_markReject,
          }, style: theme.textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _FallbackScaffold extends StatelessWidget {
  const _FallbackScaffold({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onClose,
              child: Text(context.l10n.common_close),
            ),
          ],
        ),
      ),
    );
  }
}

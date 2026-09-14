import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';

/// 父本 A/B 组对照对话框（阶段 D 偏好排序简版）。
///
/// 逐对展示父本原图 + 串，四个选项：左好/右好（胜方 preference +1.0）/
/// 都不好（各 -0.25，下限 0.25）/ 跳过（只记录）。结果即时落盘，
/// 可中途关闭；全部比完自动关窗并提示。
class ExplorePreferenceSortDialog extends ConsumerStatefulWidget {
  const ExplorePreferenceSortDialog({
    super.key,
    required this.runId,
    required this.parentSet,
  });

  final String runId;
  final ExploreParentSet parentSet;

  static Future<void> show(
    BuildContext context, {
    required String runId,
    required ExploreParentSet parentSet,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          ExplorePreferenceSortDialog(runId: runId, parentSet: parentSet),
    );
  }

  @override
  ConsumerState<ExplorePreferenceSortDialog> createState() =>
      _ExplorePreferenceSortDialogState();
}

class _ExplorePreferenceSortDialogState
    extends ConsumerState<ExplorePreferenceSortDialog> {
  late final List<(ExploreParent, ExploreParent)> _pairs;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _pairs = [
      for (var i = 0; i < widget.parentSet.parents.length; i++)
        for (var j = i + 1; j < widget.parentSet.parents.length; j++)
          (widget.parentSet.parents[i], widget.parentSet.parents[j]),
    ];
  }

  /// 父本原图路径：来源候选 → 生成文件（自定义串/无来源/未落图 → null）。
  String? _filePathOf(ExploreRun? run, ExploreParent parent) {
    final sourceId = parent.sourceCandidateId;
    if (run == null || sourceId == null) return null;
    return run.candidateById(sourceId)?.generation.filePath;
  }

  /// 偏好值取最新 run 的父本（对照中落盘即时反映，不是开窗快照）。
  ///
  /// 配对结构仍用 `_pairs` 快照：`recordComparison` 只改偏好、不动父本序。
  double _preferenceOf(ExploreRun? run, ExploreParent parent) {
    final parents = run?.parentSetById(widget.parentSet.id)?.parents;
    if (parents == null) return parent.preference;
    for (final entry in parents) {
      if (entry.id == parent.id) return entry.preference;
    }
    return parent.preference;
  }

  Future<void> _answer(ExploreComparisonResult result) async {
    final (left, right) = _pairs[_index];
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .recordComparison(
          widget.runId,
          widget.parentSet.id,
          leftParentId: left.id,
          rightParentId: right.id,
          result: result,
        );
    if (!mounted) return;
    if (_index + 1 >= _pairs.length) {
      Navigator.of(context).pop();
      AppToast.success(context, context.l10n.styleExplore_sortDone);
    } else {
      setState(() => _index += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (left, right) = _pairs[_index];
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);

    return Dialog(
      key: const Key('explore-preference-sort-dialog'),
      child: ConstrainedBox(
        // 双原图并排：大窗照候选详情弹窗先例（85%×88%）。
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.styleExplore_sortTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    l10n.styleExplore_sortProgress(_index + 1, _pairs.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.styleExplore_sortPrompt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildParentCard(run, left)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildParentCard(run, right)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    key: const Key('explore-sort-neither'),
                    onPressed: () => _answer(ExploreComparisonResult.neither),
                    child: Text(l10n.styleExplore_sortNeither),
                  ),
                  TextButton(
                    key: const Key('explore-sort-skip'),
                    onPressed: () => _answer(ExploreComparisonResult.skip),
                    child: Text(l10n.styleExplore_sortSkip),
                  ),
                  FilledButton.tonal(
                    key: const Key('explore-sort-left'),
                    onPressed: () => _answer(ExploreComparisonResult.left),
                    child: Text(l10n.styleExplore_sortLeft),
                  ),
                  FilledButton.tonal(
                    key: const Key('explore-sort-right'),
                    onPressed: () => _answer(ExploreComparisonResult.right),
                    child: Text(l10n.styleExplore_sortRight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCard(ExploreRun? run, ExploreParent parent) {
    return _ParentCard(
      parent: parent,
      filePath: _filePathOf(run, parent),
      preference: _preferenceOf(run, parent),
    );
  }
}

/// 一侧对照卡：原图（contain 完整不裁剪）+ 串 + 偏好值小字。
class _ParentCard extends StatelessWidget {
  const _ParentCard({
    required this.parent,
    required this.filePath,
    required this.preference,
  });

  final ExploreParent parent;
  final String? filePath;
  final double preference;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildImage(theme, l10n)),
          const SizedBox(height: 8),
          SelectableText(
            parent.artistString,
            maxLines: 3,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.styleExplore_preferenceValue(preference.toStringAsFixed(2)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 原图：无来源/无图/文件缺失都落到同一占位，不阻断对照。
  Widget _buildImage(ThemeData theme, AppLocalizations l10n) {
    final placeholder = _placeholder(theme, l10n);
    final path = filePath;
    if (path == null) return placeholder;
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      // 完整显示不裁剪；解码按图区宽度（避免裸全尺寸的内存尖峰）。
      cacheWidth: 720,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  Widget _placeholder(ThemeData theme, AppLocalizations l10n) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.styleExplore_candidateMissing,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

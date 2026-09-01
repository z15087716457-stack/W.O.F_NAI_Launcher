import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';

/// 父本两两排序对话框（阶段 D 偏好排序简版）。
///
/// 逐对展示父本串，四个选项：左好/右好（胜方 preference +1.0）/
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

    return AlertDialog(
      key: const Key('explore-preference-sort-dialog'),
      title: Row(
        children: [
          Expanded(child: Text(l10n.styleExplore_sortTitle)),
          Text(
            l10n.styleExplore_sortProgress(_index + 1, _pairs.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.styleExplore_sortPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ParentCard(parent: left)),
                const SizedBox(width: 12),
                Expanded(child: _ParentCard(parent: right)),
              ],
            ),
          ],
        ),
      ),
      actions: [
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
    );
  }
}

class _ParentCard extends StatelessWidget {
  const _ParentCard({required this.parent});

  final ExploreParent parent;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            parent.artistString,
            maxLines: 8,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.styleExplore_preferenceValue(
              parent.preference.toStringAsFixed(2),
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';
import 'explore_candidate_card.dart';
import 'explore_artist_text.dart';
import 'explore_dialog_frame.dart';
import 'explore_icon.dart';
import 'explore_style.dart';
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
    // 少于两个父本无可配对（调用方已置灰，双保险防直接调用）。
    if (parentSet.parents.length < 2) return Future<void>.value();
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

  /// 一次作答在飞期间吞掉后续点按（双击连点不重计分、不在已关闭的
  /// context 上二次 pop）。
  var _submitting = false;

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
    if (_submitting || _index >= _pairs.length) return;
    _submitting = true;
    try {
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
    } catch (error) {
      AppLogger.w('Record explore comparison failed: $error', 'StyleExplore');
      if (!mounted) return;
      // 开窗期间 run/父本集被删或落盘失败：提示后收窗，不再推进配对。
      AppToast.error(context, context.l10n.styleExplore_operationFailed);
      Navigator.of(context).pop();
      return;
    } finally {
      _submitting = false;
    }
    if (!mounted) return;
    if (_index + 1 >= _pairs.length) {
      Navigator.of(context).pop();
      AppToast.success(context, context.l10n.styleExplore_sortDone);
    } else {
      setState(() => _index += 1);
    }
  }

  KeyEventResult _key(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null) {
      return KeyEventResult.ignored;
    }
    final result = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => ExploreComparisonResult.left,
      LogicalKeyboardKey.arrowRight => ExploreComparisonResult.right,
      LogicalKeyboardKey.arrowDown => ExploreComparisonResult.neither,
      LogicalKeyboardKey.space => ExploreComparisonResult.skip,
      _ => null,
    };
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (result == null) return KeyEventResult.ignored;
    _answer(result);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        colors = theme.colorScheme,
        l10n = context.l10n;
    if (_pairs.isEmpty || _index >= _pairs.length) {
      return const Dialog(child: SizedBox(width: 240, height: 120));
    }
    final (left, right) = _pairs[_index];
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(widget.runId);
    final narrow = MediaQuery.sizeOf(context).width < 1280;
    final purple = ExploreStyle.evolution(theme);
    return Dialog(
      key: const Key('explore-preference-sort-dialog'),
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) => _key(event),
        child: SizedBox(
          width: 1180,
          height: math.min(888, MediaQuery.sizeOf(context).height - 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 12, 6),
                child: Row(
                  children: [
                    ExploreIcon('sort', size: 20, color: purple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.styleExplore_sortTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.common_close,
                      onPressed: () => Navigator.pop(context),
                      icon: ExploreIcon(
                        'x',
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.styleExplore_sortProgress(_index + 1, _pairs.length),
                      style: StudioTypography.data.copyWith(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(
                        value: (_index + 1) / _pairs.length,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                        color: purple,
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                    Text(
                      l10n.styleExplore_sortLiveSave,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: narrow
                      ? Column(
                          children: [
                            Expanded(child: _comparison(run, left, right)),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 168,
                              child: _ranking(run, below: true),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _comparison(run, left, right)),
                            const SizedBox(width: 18),
                            SizedBox(width: 240, child: _ranking(run)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparison(
    ExploreRun? run,
    ExploreParent left,
    ExploreParent right,
  ) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: _side(run, left, true)),
      const SizedBox(width: 10),
      SizedBox(
        width: 100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _button(
                'explore-sort-neither',
                context.l10n.styleExplore_sortNeither,
                '↓',
                ExploreComparisonResult.neither,
              ),
              const SizedBox(height: 10),
              _button(
                'explore-sort-skip',
                context.l10n.styleExplore_sortSkip,
                context.l10n.styleExplore_sortSpace,
                ExploreComparisonResult.skip,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: _side(run, right, false)),
    ],
  );

  Widget _side(ExploreRun? run, ExploreParent parent, bool left) {
    final colors = Theme.of(context).colorScheme,
        path = _filePathOf(run, parent);
    return Column(
      key: Key(left ? 'explore-sort-side-left' : 'explore-sort-side-right'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 610),
              child: SizedBox.expand(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: colors.surfaceContainerLowest,
                    child: parent.sourceCandidateId == null
                        ? Padding(
                            padding: const EdgeInsets.all(22),
                            child: Center(
                              child: Text(
                                parent.artistString,
                                textAlign: TextAlign.center,
                                style: StudioTypography.data.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                        : path == null
                        ? _missing()
                        : Image.file(
                            File(path),
                            fit: BoxFit.contain,
                            cacheWidth: 1000,
                            errorBuilder: (_, error, stack) => _missing(),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ExploreArtistLine(
          text: parent.artistString,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        _button(
          left ? 'explore-sort-left' : 'explore-sort-right',
          left
              ? context.l10n.styleExplore_sortLeft
              : context.l10n.styleExplore_sortRight,
          left ? '←' : '→',
          left ? ExploreComparisonResult.left : ExploreComparisonResult.right,
        ),
      ],
    );
  }

  Widget _missing() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExploreIcon(
          'img',
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.styleExplore_candidateMissing,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _button(
    String key,
    String label,
    String shortcut,
    ExploreComparisonResult result,
  ) => OutlinedButton(
    key: Key(key),
    onPressed: _submitting ? null : () => _answer(result),
    style: ExploreDialogFrame.buttonStyle(context).copyWith(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
    ),
    child: Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [Text(label), _keycap(shortcut)],
    ),
  );

  Widget _keycap(String value) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          value,
          style: StudioTypography.data.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _ranking(ExploreRun? run, {bool below = false}) {
    final colors = Theme.of(context).colorScheme, l10n = context.l10n;
    final parents = [...widget.parentSet.parents]
      ..sort((a, b) => _preferenceOf(run, b).compareTo(_preferenceOf(run, a)));
    final max = parents.map((p) => _preferenceOf(run, p)).reduce(math.max);
    return Container(
      key: const Key('explore-sort-ranking'),
      padding: EdgeInsets.only(left: below ? 0 : 18, top: below ? 10 : 0),
      decoration: BoxDecoration(
        border: below
            ? Border(top: BorderSide(color: colors.outlineVariant))
            : Border(left: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.styleExplore_sortRanking,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView(
              children: [
                for (final p in parents)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 44,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child:
                                run?.candidateById(p.sourceCandidateId ?? '') !=
                                    null
                                ? ExploreCandidateImage(
                                    candidate: run!.candidateById(
                                      p.sourceCandidateId!,
                                    )!,
                                    sequenceNumber: 1,
                                  )
                                : ColoredBox(
                                    color: ExploreStyle.evolutionBg(
                                      Theme.of(context),
                                    ),
                                    child: Center(
                                      child: ExploreIcon(
                                        'dice',
                                        size: 15,
                                        color: ExploreStyle.evolution(
                                          Theme.of(context),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ExploreArtistLine(
                                text: p.artistString,
                                fontSize: 12,
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: max <= 0
                                    ? 0
                                    : _preferenceOf(run, p) / max,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                                color: ExploreStyle.evolution(
                                  Theme.of(context),
                                ),
                                backgroundColor: colors.surfaceContainerHighest,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _preferenceOf(run, p).toStringAsFixed(2),
                          style: StudioTypography.data.copyWith(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.styleExplore_sortRankingHint,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

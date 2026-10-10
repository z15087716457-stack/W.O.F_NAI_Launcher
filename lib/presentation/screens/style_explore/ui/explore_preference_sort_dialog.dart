import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../themes/studio_typography.dart';
import 'explore_candidate_card.dart';
import 'explore_artist_text.dart';
import 'explore_controls.dart';
import 'explore_text.dart';
import 'explore_icon.dart';
import 'explore_style.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';

part 'explore_comparison_view.dart';

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

abstract class _ExploreComparisonController
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
}

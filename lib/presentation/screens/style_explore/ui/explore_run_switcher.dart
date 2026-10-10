import 'dart:io';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/app_toast.dart';
import '../actions/explore_auto_run_name.dart';
import 'explore_icon.dart';
import 'explore_controls.dart';
import 'explore_style.dart';
import 'explore_text.dart';

import '../actions/explore_run_actions.dart';

part 'explore_run_menu_view.dart';

bool exploreRunMatchesQuery(ExploreRun run, String query) {
  final term = query.trim().toLowerCase();
  return term.isEmpty ||
      run.displayName.toLowerCase().contains(term) ||
      run.candidates.any(
        (candidate) =>
            candidate.rollSnapshot?.instanceRolls.any(
              (roll) => roll.rolledText.toLowerCase().contains(term),
            ) ??
            false,
      );
}

/// 0 today, 1 the current Monday-based week, 2 earlier.
int exploreRunDateGroup(DateTime updatedAt, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  if (!updatedAt.toLocal().isBefore(today)) return 0;
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return updatedAt.toLocal().isBefore(monday) ? 2 : 1;
}

class ExploreRunSwitcher extends ConsumerStatefulWidget {
  const ExploreRunSwitcher({super.key, this.controller});
  final MenuController? controller;
  @override
  ConsumerState<ExploreRunSwitcher> createState() => _ExploreRunSwitcherState();
}

class _ExploreRunMenu extends ConsumerStatefulWidget {
  const _ExploreRunMenu({required this.onSelected});
  final VoidCallback onSelected;
  @override
  ConsumerState<_ExploreRunMenu> createState() => _ExploreRunMenuState();
}

abstract class _ExploreRunMenuController
    extends ConsumerState<_ExploreRunMenu> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  String _query = '';
  String? _editingId, _originalName, _error;
  bool _saving = false, _creating = false;
  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _edit(ExploreRun run) {
    setState(() {
      _editingId = run.id;
      _originalName = run.name;
      _error = null;
      _name.text = run.displayName;
      _name.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _name.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _cancelEdit() => setState(() {
    _editingId = null;
    _error = null;
  });

  Future<void> _saveName() async {
    final id = _editingId;
    if (id == null || _saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.styleExplore_nameRequired);
      return;
    }
    final current = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(id);
    if (current == null || current.name != _originalName) {
      setState(() => _error = context.l10n.styleExplore_operationFailed);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(exploreRunListNotifierProvider.notifier).rename(id, name);
      if (mounted) _cancelEdit();
    } catch (error) {
      if (mounted) {
        setState(() => _error = context.l10n.styleExplore_operationFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _create() async {
    if (_creating) return;
    setState(() => _creating = true);
    final positive = ref.read(pillWorkspaceProvider(PillScopes.main)).document;
    final negative = ref
        .read(pillWorkspaceProvider(PillScopes.negative))
        .document;
    final params = ref.read(generationParamsNotifierProvider);
    final name = exploreAutoRunName(
      document: positive,
      library: ref.read(promptBlockLibraryNotifierProvider).valueOrNull,
      l10n: context.l10n,
    );
    try {
      final run = await ref
          .read(exploreRunListNotifierProvider.notifier)
          .create(
            name: name,
            recipeSnapshot: ExploreRecipeSnapshot(
              positive: positive,
              negative: negative,
            ),
            paramsSnapshot: ExploreParamsSnapshot.fromImageParams(params),
            targetCount: 10,
          );
      if (!mounted) return;
      ref.read(exploreActiveRunIdProvider.notifier).state = run.id;
      _search.clear();
      _query = '';
      _edit(run);
    } catch (error) {
      AppLogger.e('Create explore run failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, context.l10n.styleExplore_operationFailed);
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _more(ExploreRun run, Offset position) async {
    final l10n = context.l10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final point = overlay.globalToLocal(position);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromSize(
        Rect.fromLTWH(point.dx, point.dy, 0, 0),
        overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: ExploreText(l10n.styleExplore_rename),
        ),
        PopupMenuItem(value: 'delete', child: ExploreText(l10n.common_delete)),
      ],
    );
    if (!mounted) return;
    if (action == 'rename') {
      _edit(run);
    } else if (action == 'delete') {
      await ExploreRunActions.delete(context, ref, run);
    }
  }
}

class ExploreRunStatusPill extends ConsumerWidget {
  const ExploreRunStatusPill({super.key, required this.run});
  final ExploreRun run;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme, l10n = context.l10n;
    final runner = ref.watch(exploreRunRunnerProvider);
    final capture = ref.watch(exploreManualCaptureProvider);
    final generation = ref.watch(imageGenerationNotifierProvider);
    final running = runner.isRunning && runner.runId == run.id;
    final manual =
        capture.armed && capture.runId == run.id && generation.isGenerating;
    String? text;
    Color? color;
    double alpha = .12;
    if (running || manual || run.status == ExploreRunStatus.generating) {
      final total = running
          ? runner.totalCount
          : manual
          ? generation.totalImages
          : run.targetCount;
      final done = running
          ? runner.processedCount + 1
          : manual
          ? generation.currentImage
          : run.generatedCount;
      text = total > 0
          ? l10n.styleExplore_generatingBadge(done.clamp(0, total), total)
          : l10n.styleExplore_runStatusGenerating;
      color = scheme.primary;
    } else if (run.status == ExploreRunStatus.paused) {
      text = l10n.styleExplore_runStatusPaused;
      color = ExploreRunActions.statusColor(scheme, run.status);
      alpha = .14;
    } else if (run.status == ExploreRunStatus.cancelled) {
      text = l10n.styleExplore_runStatusCancelled;
      color = scheme.onSurfaceVariant;
    } else if (run.failedCount > 0) {
      text = l10n.styleExplore_failedBadge(run.failedCount);
      color = scheme.error;
      alpha = .1;
    }
    if (text == null) return const SizedBox.shrink();
    return Container(
      key: ValueKey('explore-run-status-${run.id}'),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: ExploreText(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DashedNewRun extends CustomPainter {
  _DashedNewRun(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75),
          const Radius.circular(6),
        ),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 7) {
        canvas.drawPath(
          metric.extractPath(start, (start + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedNewRun oldDelegate) => color != oldDelegate.color;
}

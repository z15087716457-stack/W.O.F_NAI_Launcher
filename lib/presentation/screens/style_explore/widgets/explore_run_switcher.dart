import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../widgets/common/app_toast.dart';
import 'explore_auto_run_name.dart';
import 'explore_icon.dart';
import 'explore_run_actions.dart';

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

class _ExploreRunSwitcherState extends ConsumerState<ExploreRunSwitcher> {
  final _localController = MenuController();
  MenuController get _controller => widget.controller ?? _localController;
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final run = ref.watch(exploreActiveRunProvider);
    final runner = ref.watch(exploreRunRunnerProvider);
    final capture = ref.watch(exploreManualCaptureProvider);
    final generation = ref.watch(
      imageGenerationNotifierProvider.select((s) => s.isGenerating),
    );
    final running =
        run != null &&
        ((runner.isRunning && runner.runId == run.id) ||
            (capture.armed && capture.runId == run.id && generation));
    final color = running
        ? scheme.primary
        : run == null
        ? scheme.outline
        : ExploreRunActions.statusColor(scheme, run.status);
    return MenuAnchor(
      controller: _controller,
      clipBehavior: Clip.none,
      alignmentOffset: const Offset(-12, 3.5),
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
        elevation: WidgetStatePropertyAll(0),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        side: WidgetStatePropertyAll(BorderSide.none),
      ),
      menuChildren: [_ExploreRunMenu(onSelected: () => _controller.close())],
      builder: (context, controller, child) => Tooltip(
        message: run?.displayName ?? context.l10n.styleExplore_newRun,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _open ? scheme.primary : scheme.outlineVariant,
            ),
            boxShadow: _open
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: .15),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: const Key('explore-run-switcher-button'),
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 8, 0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: running
                            ? [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: .2),
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        run?.displayName ?? context.l10n.styleExplore_newRun,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ExploreIcon(
                      'chevD',
                      size: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreRunMenu extends ConsumerStatefulWidget {
  const _ExploreRunMenu({required this.onSelected});
  final VoidCallback onSelected;
  @override
  ConsumerState<_ExploreRunMenu> createState() => _ExploreRunMenuState();
}

class _ExploreRunMenuState extends ConsumerState<_ExploreRunMenu> {
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
        PopupMenuItem(value: 'rename', child: Text(l10n.styleExplore_rename)),
        PopupMenuItem(value: 'delete', child: Text(l10n.common_delete)),
      ],
    );
    if (!mounted) return;
    if (action == 'rename') {
      _edit(run);
    } else if (action == 'delete') {
      await ExploreRunActions.delete(context, ref, run);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final l10n = context.l10n;
    final list = ref.watch(exploreRunListNotifierProvider);
    final active = ref.watch(exploreActiveRunIdProvider);
    final now = DateTime.now();
    final runs =
        list.valueOrNull?.runs
            .where((run) => exploreRunMatchesQuery(run, _query))
            .toList() ??
        [];
    final groups = [
      l10n.styleExplore_today,
      l10n.styleExplore_thisWeek,
      l10n.styleExplore_earlier,
    ];
    return Container(
      key: const Key('explore-run-switcher-menu'),
      width: 420,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? .4 : .14,
            ),
            offset: const Offset(0, 18),
            blurRadius: 48,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    key: const Key('explore-run-search'),
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.styleExplore_searchRuns,
                      hintStyle: TextStyle(
                        color: scheme.onSurfaceVariant.withValues(alpha: .7),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: ExploreIcon(
                          'search',
                          size: 15,
                          color: scheme.onSurfaceVariant.withValues(alpha: .7),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 35),
                      filled: true,
                      fillColor: scheme.surface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: scheme.primary),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  key: const Key('style-explore-new-run'),
                  onTap: _creating ? null : _create,
                  borderRadius: BorderRadius.circular(9),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 58,
                          height: 42,
                          child: CustomPaint(
                            painter: _DashedNewRun(
                              scheme.primary.withValues(alpha: .5),
                            ),
                            child: Center(
                              child: _creating
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.primary,
                                      ),
                                    )
                                  : ExploreIcon(
                                      'plus',
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.styleExplore_newRun,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                              Text(
                                l10n.styleExplore_newRunDescription,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: scheme.primary.withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: list.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextButton(
                          onPressed: () => ref
                              .read(exploreRunListNotifierProvider.notifier)
                              .refresh(),
                          child: Text(l10n.common_retry),
                        ),
                      )
                    : list.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )
                    : SingleChildScrollView(
                        key: const Key('explore-run-switcher-list'),
                        primary: false,
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var group = 0; group < 3; group++)
                              if (runs.any(
                                (run) =>
                                    exploreRunDateGroup(run.updatedAt, now) ==
                                    group,
                              )) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    4,
                                  ),
                                  child: Text(
                                    groups[group],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                for (final run in runs.where(
                                  (run) =>
                                      exploreRunDateGroup(run.updatedAt, now) ==
                                      group,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: _runRow(run, run.id == active),
                                  ),
                              ],
                            if (runs.isEmpty && _query.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  l10n.styleExplore_noMatchingRuns,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ExploreIcon(
                      'info',
                      size: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.styleExplore_runNamingHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
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

  Widget _runRow(ExploreRun run, bool selected) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final l10n = context.l10n;
    final editing = _editingId == run.id;
    final count = run.candidates.length;
    final hearts = run.candidates
        .where((candidate) => candidate.review.heart)
        .length;
    final stats = [
      l10n.styleExplore_imageCount(count),
      if (hearts > 0) l10n.styleExplore_favoriteCount(hearts),
      if (run.families.isNotEmpty)
        l10n.styleExplore_lineCount(run.families.length),
    ];
    return GestureDetector(
      onSecondaryTapDown: (details) => _more(run, details.globalPosition),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: .08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          key: ValueKey('explore-run-${run.id}'),
          borderRadius: BorderRadius.circular(9),
          onTap: editing
              ? null
              : () {
                  ref.read(exploreActiveRunIdProvider.notifier).state = run.id;
                  widget.onSelected();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                ExploreRunMosaic(run: run),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (editing)
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.escape):
                                _cancelEdit,
                          },
                          child: TextField(
                            key: const Key('explore-run-inline-name'),
                            controller: _name,
                            focusNode: _nameFocus,
                            enabled: !_saving,
                            onSubmitted: (_) => _saveName(),
                            textInputAction: TextInputAction.done,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              errorText: _error,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onDoubleTap: () => _edit(run),
                                child: Text(
                                  run.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ExploreRunStatusPill(run: run),
                          ],
                        ),
                      Text(
                        stats.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  ExploreIcon(
                    'check',
                    size: 16,
                    strokeWidth: 2.4,
                    color: scheme.primary,
                  )
                else
                  Builder(
                    builder: (context) => Tooltip(
                      message: l10n.imageMenu_more,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: InkWell(
                          key: ValueKey('explore-run-menu-${run.id}'),
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            final box =
                                context.findRenderObject()! as RenderBox;
                            _more(
                              run,
                              box.localToGlobal(Offset(0, box.size.height)),
                            );
                          },
                          child: Center(
                            child: ExploreIcon(
                              'more',
                              size: 16,
                              strokeWidth: 3,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreRunMosaic extends StatelessWidget {
  const ExploreRunMosaic({super.key, required this.run});
  final ExploreRun run;
  @override
  Widget build(BuildContext context) {
    final paths = run.candidates.reversed
        .map((c) => c.generation.filePath)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .take(3)
        .toList();
    return SizedBox(
      width: 58,
      height: 42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: i >= paths.length
                      ? const SizedBox.expand()
                      : Image.file(
                          File(paths[i]),
                          cacheHeight: 120,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, error, stackTrace) =>
                              const SizedBox.expand(),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
      child: Text(
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

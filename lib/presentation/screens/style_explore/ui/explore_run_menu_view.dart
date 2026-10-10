part of 'explore_run_switcher.dart';

class _ExploreRunSwitcherState extends ConsumerState<ExploreRunSwitcher> {
  final _localController = MenuController();
  MenuController get _controller => widget.controller ?? _localController;
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme;
    final run = ref.watch(exploreActiveRunProvider),
        runner = ref.watch(exploreRunRunnerProvider);
    final capture = ref.watch(exploreManualCaptureProvider);
    final generating = ref.watch(
      imageGenerationNotifierProvider.select((s) => s.isGenerating),
    );
    final running =
        run != null &&
        ((runner.isRunning && runner.runId == run.id) ||
            (capture.armed && capture.runId == run.id && generating));
    final color = running
        ? c.primary
        : run?.status == ExploreRunStatus.paused
        ? Color(t.brightness == Brightness.dark ? 0xfff1a10d : 0xffc27c0e)
        : run?.status == ExploreRunStatus.cancelled
        ? c.onSurfaceVariant
        : ExploreStyle.strong(t);
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
      builder: (context, controller, _) => Tooltip(
        message: run?.displayName ?? context.l10n.styleExplore_newRun,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            color: ExploreStyle.raised(t),
            border: Border.all(color: _open ? c.primary : c.outlineVariant),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _open
                ? [
                    BoxShadow(
                      color: c.primary.withValues(alpha: .15),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ExploreText(
                        run?.displayName ?? context.l10n.styleExplore_newRun,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ExploreIcon('chevD', size: 15, color: c.onSurfaceVariant),
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

class _ExploreRunMenuState extends _ExploreRunMenuController {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), c = t.colorScheme, l = context.l10n;
    final list = ref.watch(exploreRunListNotifierProvider),
        active = ref.watch(exploreActiveRunIdProvider),
        now = DateTime.now();
    final runs =
        list.valueOrNull?.runs
            .where((r) => exploreRunMatchesQuery(r, _query))
            .toList() ??
        [];
    final groups = [
      l.styleExplore_today,
      l.styleExplore_thisWeek,
      l.styleExplore_earlier,
    ];
    return Container(
      key: const Key('explore-run-switcher-menu'),
      width: 420,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      decoration: BoxDecoration(
        color: ExploreStyle.raised(t),
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: t.brightness == Brightness.dark ? .4 : .14,
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
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l.styleExplore_searchRuns,
                      hintStyle: TextStyle(color: ExploreStyle.faint(t)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 35),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: ExploreIcon(
                          'search',
                          size: 15,
                          color: ExploreStyle.faint(t),
                        ),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: c.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: ExploreStyle.strong(t)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: c.primary),
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
                              c.primary.withValues(alpha: .5),
                            ),
                            child: Center(
                              child: _creating
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: c.primary,
                                      ),
                                    )
                                  : ExploreIcon(
                                      'plus',
                                      size: 18,
                                      color: c.primary,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExploreText(
                                l.styleExplore_newRun,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.primary,
                                ),
                              ),
                              ExploreText(
                                l.styleExplore_newRunDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.primary,
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
                        child: ExploreButton(
                          label: l.common_retry,
                          onPressed: () => ref
                              .read(exploreRunListNotifierProvider.notifier)
                              .refresh(),
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
                                (r) =>
                                    exploreRunDateGroup(r.updatedAt, now) ==
                                    group,
                              )) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    4,
                                  ),
                                  child: ExploreText(
                                    groups[group],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                for (final run in runs.where(
                                  (r) =>
                                      exploreRunDateGroup(r.updatedAt, now) ==
                                      group,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: _row(run, run.id == active),
                                  ),
                              ],
                            if (runs.isEmpty && _query.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ExploreText(
                                  l.styleExplore_noMatchingRuns,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.onSurfaceVariant,
                                  ),
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
                  border: Border(top: BorderSide(color: c.outlineVariant)),
                ),
                child: Row(
                  children: [
                    if (ref.watch(exploreActiveRunProvider) == null) ...[
                      ExploreButton(
                        key: const Key('style-explore-inspector-menu-toggle'),
                        label: l.styleExplore_inspectorTitle,
                        icon: const ExploreIcon('panel', size: 15),
                        onPressed: () {
                          ref
                              .read(layoutStateNotifierProvider.notifier)
                              .setStyleExploreInspectorVisible(true);
                          widget.onSelected();
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                    ExploreIcon('info', size: 13, color: c.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ExploreText(
                        l.styleExplore_runNamingHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.onSurfaceVariant,
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

  Widget _row(ExploreRun run, bool selected) {
    final c = Theme.of(context).colorScheme,
        l = context.l10n,
        editing = _editingId == run.id;
    final hearts = run.candidates.where((c) => c.review.heart).length;
    final stats = [
      l.styleExplore_imageCount(run.candidates.length),
      if (hearts > 0) l.styleExplore_favoriteCount(hearts),
      if (run.families.isNotEmpty)
        l.styleExplore_lineCount(run.families.length),
    ];
    return GestureDetector(
      onSecondaryTapDown: (d) => _more(run, d.globalPosition),
      child: Material(
        color: selected ? c.primary.withValues(alpha: .08) : Colors.transparent,
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
                            style: const TextStyle(
                              fontSize: 13,
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
                                child: ExploreText(
                                  run.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ExploreRunStatusPill(run: run),
                          ],
                        ),
                      ExploreText(
                        stats.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  ExploreIcon(
                    'check',
                    size: 16,
                    color: c.primary,
                    strokeWidth: 2.4,
                  )
                else
                  Builder(
                    builder: (context) => ExploreIconButton(
                      'more',
                      key: ValueKey('explore-run-menu-${run.id}'),
                      tooltip: l.imageMenu_more,
                      onPressed: () {
                        final box = context.findRenderObject()! as RenderBox;
                        _more(
                          run,
                          box.localToGlobal(Offset(0, box.size.height)),
                        );
                      },
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
        .where((p) => p.isNotEmpty)
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
                  child: i < paths.length
                      ? Image.file(
                          File(paths[i]),
                          cacheHeight: 120,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, e, s) => const SizedBox.expand(),
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

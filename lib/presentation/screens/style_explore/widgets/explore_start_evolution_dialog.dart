import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import 'explore_candidate_card.dart';
import 'explore_dialog_frame.dart';
import 'explore_icon.dart';
import 'explore_style.dart';

class ExploreStartEvolutionDialog extends ConsumerStatefulWidget {
  const ExploreStartEvolutionDialog({
    super.key,
    required this.run,
    required this.candidates,
    this.hostContext,
  });
  final ExploreRun run;
  final List<ExploreCandidate> candidates;
  final BuildContext? hostContext;

  static Future<bool> show(
    BuildContext context, {
    required ExploreRun run,
    required List<ExploreCandidate> candidates,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => ExploreStartEvolutionDialog(
          run: run,
          candidates: candidates,
          hostContext: context,
        ),
      ) ??
      false;

  @override
  ConsumerState<ExploreStartEvolutionDialog> createState() =>
      _StartEvolutionState();
}

class _StartEvolutionState extends ConsumerState<ExploreStartEvolutionDialog> {
  final _name = TextEditingController();
  final _count = TextEditingController();
  final _custom = <TextEditingController>[];
  late final List<ExploreCandidate> _candidates = [...widget.candidates];
  bool _join = false,
      _submitting = false,
      _countEdited = false,
      _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _count.dispose();
    for (final c in _custom) {
      c.dispose();
    }
    super.dispose();
  }

  ExploreRun get _run =>
      ref
          .watch(exploreRunListNotifierProvider)
          .valueOrNull
          ?.runById(widget.run.id) ??
      widget.run;
  ExploreFamily? _family(ExploreRun run) =>
      run.familyById(ref.read(exploreActiveFamilyIdProvider) ?? '') ??
      run.families.lastOrNull;
  List<({String? sourceCandidateId, String artistString})> get _parents {
    final seen = <String>{};
    return [
      for (final c in _candidates)
        if (exploreParentStringFor(c).trim() case final text
            when text.isNotEmpty && seen.add(text))
          (sourceCandidateId: c.id, artistString: text),
      for (final c in _custom)
        if (c.text.trim() case final text
            when text.isNotEmpty && seen.add(text))
          (sourceCandidateId: null, artistString: text),
    ];
  }

  int _minimum(ExploreRun run, ExploreFamily? family) => {
    if (_join && family != null)
      ...?run
          .parentSetById(family.activeParentSetId)
          ?.parents
          .map((p) => p.artistString.trim()),
    ..._parents.map((p) => p.artistString),
  }.length.clamp(1, 10000);

  bool _hasTarget() {
    final doc = ref.read(pillWorkspaceProvider(PillScopes.main)).document;
    final marker = resolveExploreOverrideMarkerInDocument(doc);
    return marker != null &&
        ref
                .read(promptBlockLibraryNotifierProvider)
                .valueOrNull
                ?.blockById(doc.instances[marker]!.blockId) !=
            null;
  }

  Future<void> _submit(bool generate) async {
    if (_submitting || _parents.isEmpty || !_hasTarget()) return;
    setState(() => _submitting = true);
    final l10n = context.l10n, host = widget.hostContext ?? context;
    try {
      final notifier = ref.read(exploreRunListNotifierProvider.notifier);
      final latest = ref
          .read(exploreRunListNotifierProvider)
          .valueOrNull
          ?.runById(widget.run.id);
      if (latest == null) throw StateError('任务不存在');
      final target = _family(latest);
      final ExploreFamily family;
      final ExploreParentSet set;
      if (_join && target != null) {
        family = target;
        set = await notifier.addParentsToActiveSet(
          latest.id,
          familyId: family.id,
          parents: _parents,
        );
      } else {
        family = await notifier.createFamily(
          latest.id,
          name: _name.text,
          defaultName: l10n.styleExplore_defaultEvolutionName(
            latest.families.length + 1,
          ),
          parents: _parents,
        );
        final created = ref
            .read(exploreRunListNotifierProvider)
            .valueOrNull!
            .runById(latest.id)!;
        set = created.parentSetById(family.rootParentSetId)!;
      }
      if (!mounted) return;
      ref.read(exploreActiveFamilyIdProvider.notifier).state = family.id;
      ref.read(exploreStageTabProvider.notifier).state =
          ExploreStageTab.evolution;
      final count = (int.tryParse(_count.text) ?? set.parents.length + 1).clamp(
        set.parents.length,
        10000,
      );
      final generation = generate
          ? ref
                .read(exploreRunRunnerProvider.notifier)
                .startDeepRound(
                  latest.id,
                  familyId: family.id,
                  parentSetId: set.id,
                  count: count,
                )
          : null;
      Navigator.pop(context, true);
      if (host.mounted) {
        AppToast.success(
          host,
          _join
              ? l10n.styleExplore_evolutionJoined(family.name)
              : l10n.styleExplore_evolutionCreated(family.name),
        );
      }
      if (generation != null) {
        unawaited(
          generation
              .then((ok) {
                if (!ok && host.mounted) {
                  AppToast.warning(host, l10n.styleExplore_runBusy);
                }
              })
              .catchError((Object error) {
                AppLogger.w('Start evolution failed: $error', 'StyleExplore');
                if (host.mounted) {
                  AppToast.error(host, l10n.styleExplore_operationFailed);
                }
              }),
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.warning(
        context,
        error is StateError && error.message.contains('还在生成')
            ? l10n.styleExplore_generationBusy
            : l10n.styleExplore_operationFailed,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        colors = theme.colorScheme,
        l10n = context.l10n;
    ref.watch(exploreActiveFamilyIdProvider);
    final run = _run, family = _family(run);
    if (family == null) _join = false;
    final minimum = _minimum(run, family);
    if (!_initialized) {
      _initialized = true;
      _name.text = l10n.styleExplore_defaultEvolutionName(
        run.families.length + 1,
      );
    }
    if (!_countEdited) _count.text = '${minimum + 1}';
    final doc = ref.watch(pillWorkspaceProvider(PillScopes.main)).document;
    final library = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final marker = resolveExploreOverrideMarkerInDocument(doc);
    final block = marker == null
        ? null
        : library?.blockById(doc.instances[marker]!.blockId);
    final valid = block != null && _parents.isNotEmpty && !_submitting;
    final number = int.tryParse(_count.text) ?? minimum + 1;
    final muted = colors.onSurfaceVariant,
        purple = ExploreStyle.evolution(theme);
    return ExploreDialogFrame(
      key: const Key('explore-start-evolution-dialog'),
      title: l10n.styleExplore_startEvolution,
      icon: 'evo',
      subtitle: l10n.styleExplore_evolutionSubtitle(widget.candidates.length),
      footer: _footer(
        [
          Text(
            l10n.styleExplore_evolutionFirstBatch,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _countButton(
                  'chevL',
                  () => _setCount((number - 1).clamp(minimum, 10000)),
                ),
                SizedBox(
                  width: 34,
                  child: TextField(
                    key: const Key('explore-evolution-count'),
                    controller: _count,
                    enabled: !_submitting,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: StudioTypography.data.copyWith(fontSize: 12),
                    decoration: const InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => setState(() {
                      _countEdited = true;
                    }),
                  ),
                ),
                _countButton(
                  'chevR',
                  () => _setCount((number + 1).clamp(minimum, 10000)),
                ),
              ],
            ),
          ),
          Text(
            l10n.styleExplore_evolutionMinimum(minimum),
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
        [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context, false),
            style: ExploreDialogFrame.buttonStyle(context),
            child: Text(l10n.common_cancel),
          ),
          OutlinedButton(
            key: const Key('explore-evolution-only-create'),
            onPressed: valid ? () => _submit(false) : null,
            style: ExploreDialogFrame.buttonStyle(context),
            child: Text(
              _join
                  ? l10n.styleExplore_evolutionOnlyJoin
                  : l10n.styleExplore_evolutionOnlyCreate,
            ),
          ),
          FilledButton.icon(
            key: const Key('explore-evolution-create-generate'),
            onPressed: valid ? () => _submit(true) : null,
            style: ExploreDialogFrame.buttonStyle(context).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.disabled)
                    ? colors.surfaceContainerHighest
                    : purple,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.disabled)
                    ? muted
                    : ExploreStyle.evolutionForeground(theme),
              ),
            ),
            icon: ExploreIcon(
              'play',
              size: 13,
              color: valid ? ExploreStyle.evolutionForeground(theme) : muted,
            ),
            label: Text(
              _join
                  ? l10n.styleExplore_evolutionJoinGenerate(
                      number.clamp(minimum, 10000),
                    )
                  : l10n.styleExplore_evolutionCreateGenerate(
                      number.clamp(minimum, 10000),
                    ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ExploreStyle.evolutionBg(theme),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: purple,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ExploreStyle.evolutionForeground(theme),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              [
                                l10n.styleExplore_evolutionStepOne,
                                l10n.styleExplore_evolutionStepTwo,
                                l10n.styleExplore_evolutionStepThree,
                              ][i],
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (family != null) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final join in [false, true])
                  OutlinedButton(
                    key: Key(
                      join
                          ? 'explore-evolution-mode-join'
                          : 'explore-evolution-mode-new',
                    ),
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                            _join = join;
                          }),
                    style: ExploreDialogFrame.buttonStyle(context).copyWith(
                      backgroundColor: WidgetStatePropertyAll(
                        join == _join
                            ? ExploreStyle.evolutionBg(theme)
                            : colors.surface,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        join == _join ? purple : muted,
                      ),
                    ),
                    child: Text(
                      join
                          ? l10n.styleExplore_evolutionJoinLine(family.name)
                          : l10n.styleExplore_evolutionNewLine,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (!_join) ...[
            _label(l10n.styleExplore_evolutionName),
            TextField(
              key: const Key('explore-family-name'),
              controller: _name,
              enabled: !_submitting,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: ExploreDialogFrame.inputDecoration(context),
            ),
            const SizedBox(height: 14),
          ],
          _label(l10n.styleExplore_evolutionParents(_parents.length)),
          for (final c in _candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _parentRow(c),
            ),
          for (var i = 0; i < _custom.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: Key('explore-custom-parent-$i'),
                      controller: _custom[i],
                      enabled: !_submitting,
                      minLines: 1,
                      maxLines: 3,
                      decoration: ExploreDialogFrame.inputDecoration(
                        context,
                        hint: l10n.styleExplore_evolutionCustomHint,
                      ),
                      style: StudioTypography.data.copyWith(fontSize: 12),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.common_delete,
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                            _custom.removeAt(i).dispose();
                          }),
                    icon: ExploreIcon('x', size: 14, color: muted),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            key: const Key('explore-add-custom-parent'),
            onPressed: _submitting
                ? null
                : () => setState(() {
                    _custom.add(TextEditingController());
                  }),
            style: ExploreDialogFrame.buttonStyle(context).copyWith(
              alignment: Alignment.centerLeft,
              minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
            ),
            icon: ExploreIcon('plus', size: 15, color: muted),
            label: Text(l10n.styleExplore_evolutionAddCustom),
          ),
          const SizedBox(height: 14),
          Container(
            key: const Key('explore-evolution-target'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ExploreIcon(
                  block == null ? 'warn' : 'dice',
                  size: 15,
                  color: block == null
                      ? colors.error
                      : promptBlockColorFromString(block.color),
                ),
                Text(
                  block == null
                      ? l10n.styleExplore_variablesEmpty
                      : l10n.styleExplore_evolutionTarget,
                  style: TextStyle(
                    fontSize: 12,
                    color: block == null ? colors.error : muted,
                  ),
                ),
                if (block != null)
                  PromptPill(
                    title: block.title,
                    color: promptBlockColorFromString(block.color),
                    appearance: block.appearance,
                    leading: ExploreIcon(
                      'dice',
                      size: 12,
                      color: promptBlockColorFromString(block.color),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(List<Widget> controls, List<Widget> actions) => OverflowBar(
    alignment: MainAxisAlignment.spaceBetween,
    overflowAlignment: OverflowBarAlignment.end,
    spacing: 16,
    overflowSpacing: 10,
    children: [
      for (final widgets in [controls, actions])
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widgets.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              widgets[i],
            ],
          ],
        ),
    ],
  );

  void _setCount(int value) => setState(() {
    _countEdited = true;
    _count.text = '$value';
  });
  Widget _countButton(String icon, VoidCallback onPressed) => SizedBox(
    width: 25,
    height: 28,
    child: IconButton(
      padding: EdgeInsets.zero,
      onPressed: _submitting ? null : onPressed,
      icon: ExploreIcon(
        icon,
        size: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget _label(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      value,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget _parentRow(ExploreCandidate candidate) {
    final colors = Theme.of(context).colorScheme,
        text = exploreParentStringFor(candidate);
    return Container(
      key: Key('explore-evolution-parent-${candidate.id}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 58,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: ExploreCandidateImage(
                candidate: candidate,
                sequenceNumber: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isEmpty
                  ? context.l10n.styleExplore_evolutionParentEmpty
                  : text,
              style: StudioTypography.data.copyWith(
                fontSize: 12,
                color: text.isEmpty ? colors.error : colors.onSurface,
              ),
            ),
          ),
          IconButton(
            key: Key('explore-evolution-remove-${candidate.id}'),
            tooltip: context.l10n.common_delete,
            onPressed: _submitting
                ? null
                : () => setState(() {
                    _candidates.remove(candidate);
                  }),
            icon: ExploreIcon('x', size: 14, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

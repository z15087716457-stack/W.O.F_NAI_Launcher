import 'dart:async';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
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
import '../../../widgets/common/dashed_rounded_border.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import 'explore_candidate_card.dart';
import 'explore_dialog_frame.dart';
import 'explore_icon.dart';
import 'explore_controls.dart';
import 'explore_text.dart';
import 'explore_style.dart';

part 'explore_start_dialog_view.dart';

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

abstract class _StartEvolutionController
    extends ConsumerState<ExploreStartEvolutionDialog> {
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
}

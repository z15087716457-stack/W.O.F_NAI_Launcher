part of 'explore_inspector.dart';

abstract class _ExploreInspectorController
    extends ConsumerState<ExploreInspector> {
  final _scroll = ScrollController();
  bool _expanded = false;
  bool _negativeExpanded = false;
  @override
  void didUpdateWidget(covariant ExploreInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidateId != widget.candidateId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _roundStamp(ExploreRun run, ExploreCandidate candidate) {
    final round = run.roundById(candidate.roundId),
        time = round?.createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${context.l10n.styleExplore_roundNumber(round?.number ?? 1)}${time == null ? '' : ' · ${two(time.hour)}:${two(time.minute)}'}';
  }

  Future<void> _copySnapshot(ExploreRollSnapshot? snapshot) async {
    if (snapshot == null) return;
    final buffer = StringBuffer()
      ..writeln(snapshot.positive)
      ..write('---${String.fromCharCode(10)}')
      ..writeln(snapshot.negative);
    for (final instance in snapshot.instanceRolls) {
      buffer.writeln(
        '[${instance.lane}] ${instance.blockTitle}: ${instance.rolledText}',
      );
    }
    await _copy(buffer.toString());
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) AppToast.success(context, context.l10n.common_copied);
  }

  Future<void> _delete(ExploreRun run, ExploreCandidate candidate) async {
    if (candidate.generation.filePath != null) {
      await ExploreCandidateActions.deleteImage(
        context,
        ref,
        runId: run.id,
        candidate: candidate,
      );
      return;
    }
    final yes = await ThemedConfirmDialog.show(
      context: context,
      title: context.l10n.styleExplore_deleteCandidatesTitle,
      content: context.l10n.styleExplore_deleteCandidatesMessage(1),
      confirmText: context.l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
    );
    if (!yes || !mounted) return;
    final latest = ref
        .read(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(run.id)
        ?.candidateById(candidate.id);
    if (latest != null &&
        latest.generation.status != ExploreCandidateGenerationStatus.pending) {
      await ref.read(exploreRunListNotifierProvider.notifier).removeCandidates(
        run.id,
        [candidate.id],
      );
    }
  }
}

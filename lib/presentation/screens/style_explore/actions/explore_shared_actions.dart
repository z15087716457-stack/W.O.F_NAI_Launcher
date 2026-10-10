import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../ui/explore_candidate_detail_dialog.dart';
import '../ui/explore_start_evolution_dialog.dart';

Future<void> openExploreCandidate(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run,
  ExploreCandidate candidate, {
  List<String>? browsingIds,
}) async {
  final ids =
      browsingIds ??
      ref.read(exploreVisibleCandidatesProvider).map((c) => c.id).toList();
  var index = ids.indexOf(candidate.id);
  if (index < 0) {
    ids
      ..clear()
      ..add(candidate.id);
    index = 0;
  }
  final evolution = await ExploreCandidateDetailDialog.show(
    context,
    runId: run.id,
    candidateIds: ids,
    initialIndex: index,
  );
  if (evolution == null || !context.mounted) return;
  final latest = ref
          .read(exploreRunListNotifierProvider)
          .valueOrNull
          ?.runById(run.id),
      source = latest?.candidateById(evolution);
  if (latest != null && source != null) {
    await startExploreEvolution(context, ref, latest, [source]);
  }
}

Future<bool> startExploreEvolution(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run,
  List<ExploreCandidate> candidates,
) async {
  if (candidates.isEmpty) return false;
  return ExploreStartEvolutionDialog.show(
    context,
    run: run,
    candidates: candidates,
  );
}

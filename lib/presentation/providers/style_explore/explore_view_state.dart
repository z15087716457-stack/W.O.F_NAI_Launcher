import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/style_explore/explore_run.dart';
import 'explore_run_provider.dart';

enum ExploreStageTab { candidates, evolution }

final exploreStageTabProvider = StateProvider<ExploreStageTab>((ref) {
  ref.watch(exploreActiveRunIdProvider);
  return ExploreStageTab.candidates;
});

final exploreRoundOrderNewestFirstProvider = StateProvider<bool>((ref) {
  ref.watch(exploreActiveRunIdProvider);
  return true;
});

String? focusAfterCandidateDeletion(
  ExploreRun? previous,
  ExploreRun? next,
  String? focused,
) {
  if (previous?.id != next?.id || next == null) return null;
  if (focused == null || next.candidateById(focused) != null) return focused;
  final old = previous?.candidateById(focused);
  final ids = previous?.roundById(old?.roundId ?? '')?.candidateIds ?? [];
  final index = ids.indexOf(focused);
  for (var i = index + 1; i < ids.length; i++) {
    if (next.candidateById(ids[i]) != null) return ids[i];
  }
  for (var i = index - 1; i >= 0; i--) {
    if (next.candidateById(ids[i]) != null) return ids[i];
  }
  return null;
}

final StateProvider<String?> exploreFocusedCandidateIdProvider =
    StateProvider<String?>((ref) {
      ref.watch(exploreActiveRunIdProvider);
      ref.listen(exploreActiveRunProvider, (previous, next) {
        final controller = ref.read(exploreFocusedCandidateIdProvider.notifier);
        final focus = focusAfterCandidateDeletion(
          previous,
          next,
          controller.state,
        );
        if (controller.state != focus) controller.state = focus;
      });
      return null;
    });

List<ExploreRound> exploreOrderedRounds(ExploreRun run, bool newestFirst) =>
    newestFirst ? run.rounds.reversed.toList() : run.rounds;

List<ExploreCandidate> exploreRoundCandidates(
  ExploreRun run,
  ExploreRound round,
  ExploreGalleryFilter filter,
) => [
  for (final id in round.candidateIds)
    if (run.candidateById(id) case final candidate?)
      if (exploreCandidateMatchesFilter(candidate, filter)) candidate,
];

List<ExploreCandidate> exploreWallCandidates(
  ExploreRun run,
  ExploreGalleryFilter filter, {
  bool newestFirst = true,
}) => [
  for (final round in exploreOrderedRounds(run, newestFirst))
    ...exploreRoundCandidates(run, round, filter),
];

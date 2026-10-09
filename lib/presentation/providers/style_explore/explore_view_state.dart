import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/style_explore/explore_run.dart';
import 'explore_run_provider.dart';
import 'explore_run_runner.dart';
import 'explore_manual_capture.dart';

enum ExploreStageTab { candidates, evolution }

final exploreSelectionModeProvider = StateProvider<bool>((ref) {
  ref.watch(exploreActiveRunIdProvider);
  ref.watch(exploreStageTabProvider);
  return false;
});

final exploreSelectionProvider =
    NotifierProvider<ExploreSelection, Set<String>>(ExploreSelection.new);

class ExploreSelection extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(exploreActiveRunIdProvider);
    ref.watch(exploreStageTabProvider);
    ref.listen(exploreActiveRunProvider, (_, next) {
      final existing = next?.candidates.map((c) => c.id).toSet() ?? <String>{};
      final kept = state.intersection(existing);
      if (kept.length != state.length) state = kept;
    });
    return {};
  }

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
  void selectRange(String? anchor, String to, List<String> orderedIds) {
    final a = orderedIds.indexOf(anchor ?? to), b = orderedIds.indexOf(to);
    if (a < 0 || b < 0) {
      toggle(to);
      return;
    }
    state = {
      ...state,
      ...orderedIds.sublist(a < b ? a : b, (a > b ? a : b) + 1),
    };
  }

  void selectAll(Iterable<String> ids) => state = ids.toSet();
  void clear() => state = {};
}

final exploreVisibleCandidatesProvider = Provider<List<ExploreCandidate>>((
  ref,
) {
  final run = ref.watch(exploreActiveRunProvider);
  if (run == null) return [];
  if (ref.watch(exploreStageTabProvider) == ExploreStageTab.evolution) {
    final family =
        run.familyById(ref.watch(exploreActiveFamilyIdProvider) ?? '') ??
        run.families.lastOrNull;
    if (family == null) return [];
    return exploreFamilyGenerations(run, family)
            .where((g) => g.parentSet.id == family.activeParentSetId)
            .firstOrNull
            ?.pile ??
        [];
  }
  return exploreWallCandidates(
    run,
    effectiveExploreGalleryFilter(run, ref.watch(exploreGalleryFilterProvider)),
    newestFirst: ref.watch(exploreRoundOrderNewestFirstProvider),
  );
});

/// Moves vertically within a round; crossing a round preserves the closest column.
String? exploreMovedFocus(
  List<ExploreCandidate> visible,
  String? focused,
  int horizontal,
  int vertical,
  int columns,
) {
  if (visible.isEmpty) return null;
  final index = visible.indexWhere((c) => c.id == focused);
  if (index < 0) return visible.first.id;
  if (horizontal != 0) {
    return visible[(index + horizontal).clamp(0, visible.length - 1)].id;
  }
  final groups = <List<ExploreCandidate>>[];
  for (final candidate in visible) {
    if (groups.isEmpty || groups.last.first.roundId != candidate.roundId) {
      groups.add([]);
    }
    groups.last.add(candidate);
  }
  final group = groups.indexWhere((g) => g.any((c) => c.id == focused));
  final local = groups[group].indexWhere((c) => c.id == focused),
      column = local % columns;
  final target = local + vertical * columns;
  if (target >= 0 && target < groups[group].length) {
    return groups[group][target].id;
  }
  if (target >= groups[group].length &&
      local ~/ columns < (groups[group].length - 1) ~/ columns) {
    return groups[group].last.id;
  }
  final adjacent = group + vertical;
  if (adjacent < 0 || adjacent >= groups.length) return focused;
  final next = groups[adjacent];
  final rowStart = vertical > 0 ? 0 : ((next.length - 1) ~/ columns) * columns;
  return next[(rowStart + column).clamp(0, next.length - 1)].id;
}

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

final exploreGeneratingCandidateIdProvider = Provider<String?>((ref) {
  final run = ref.watch(exploreActiveRunProvider);
  if (run == null) return null;
  final runner = ref.watch(exploreRunRunnerProvider),
      manual = ref.watch(exploreManualCaptureProvider);
  if (runner.isRunning && runner.runId == run.id) {
    for (final round in run.rounds.where(
      (r) => r.status == ExploreRoundStatus.generating,
    )) {
      final current =
          exploreRoundCandidates(run, round, const ExploreGalleryFilterAll())
              .where(
                (c) =>
                    c.generation.status ==
                    ExploreCandidateGenerationStatus.pending,
              )
              .firstOrNull;
      if (current != null) return current.id;
    }
  } else if (manual.armed && manual.runId == run.id) {
    return manual.candidateIds
        .where(
          (id) =>
              run.candidateById(id)?.generation.status ==
              ExploreCandidateGenerationStatus.pending,
        )
        .firstOrNull;
  }
  return null;
});

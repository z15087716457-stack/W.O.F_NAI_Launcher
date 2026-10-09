import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../widgets/common/app_toast.dart';
import 'explore_candidate_detail_dialog.dart';
import 'explore_create_family_dialog.dart';

Future<void> openExploreCandidate(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run,
  ExploreCandidate candidate,
) {
  final ids = ref
      .read(exploreVisibleCandidatesProvider)
      .map((c) => c.id)
      .toList();
  var index = ids.indexOf(candidate.id);
  if (index < 0) {
    ids
      ..clear()
      ..add(candidate.id);
    index = 0;
  }
  return showDialog<void>(
    context: context,
    builder: (_) => ExploreCandidateDetailDialog(
      runId: run.id,
      candidateIds: ids,
      initialIndex: index,
    ),
  );
}

Future<bool> startExploreEvolution(
  BuildContext context,
  WidgetRef ref,
  ExploreRun run,
  List<ExploreCandidate> candidates,
) async {
  if (candidates.isEmpty) return false;
  final result = await ExploreCreateFamilyDialog.show(
    context,
    candidates: candidates,
  );
  if (result == null || !context.mounted) return false;
  try {
    final family = await ref
        .read(exploreRunListNotifierProvider.notifier)
        .createFamily(
          run.id,
          name: result.name,
          parents: [
            for (final candidate in candidates)
              (
                sourceCandidateId: candidate.id,
                artistString: exploreParentStringFor(candidate),
              ),
            for (final text in result.customStrings)
              (sourceCandidateId: null, artistString: text),
          ],
        );
    ref.read(exploreActiveFamilyIdProvider.notifier).state = family.id;
    if (context.mounted) {
      AppToast.success(
        context,
        context.l10n.styleExplore_familyCreated(family.name),
      );
    }
    return true;
  } on StateError {
    if (context.mounted) {
      AppToast.warning(context, context.l10n.styleExplore_createFamilyEmpty);
    }
    return false;
  }
}

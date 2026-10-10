import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/pill_workspace_provider.dart';
import '../../../providers/style_explore/explore_roll_capture.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/common/app_toast.dart';
import 'explore_candidate_card.dart';
import 'explore_candidate_hover_preview.dart';
import '../actions/explore_evolution_actions.dart';
import 'explore_icon.dart';
import 'explore_controls.dart';
import 'explore_dialog_frame.dart';
import 'explore_text.dart';
import 'explore_parent_list.dart';
import 'explore_preference_sort_dialog.dart';
import '../actions/explore_shared_actions.dart';
import 'explore_style.dart';
import 'horizontal_edge_fade.dart';

part 'explore_evolution_cards.dart';

ExploreFamily? exploreSelectedFamily(ExploreRun run, String? id) =>
    run.familyById(id ?? '') ?? run.families.lastOrNull;

class ExploreEvolutionView extends ConsumerStatefulWidget {
  const ExploreEvolutionView({
    super.key,
    required this.run,
    required this.cardBuilder,
    this.onGridLayout,
  });
  final ExploreRun run;
  final Widget Function(ExploreCandidate candidate, bool selectable)
  cardBuilder;
  final void Function(int columns, double extent)? onGridLayout;
  @override
  ConsumerState<ExploreEvolutionView> createState() =>
      _ExploreEvolutionViewState();
}

abstract class _ExploreEvolutionController
    extends ConsumerState<ExploreEvolutionView> {
  final _expanded = <String>{};
  final _hover = ExploreCandidateHoverSession();
  bool _submitting = false;
  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExploreEvolutionView old) {
    super.didUpdateWidget(old);
    if (old.run.id != widget.run.id) _expanded.clear();
  }
}

class _DeepRoundControl extends ConsumerStatefulWidget {
  const _DeepRoundControl({
    super.key,
    required this.run,
    required this.family,
    required this.parentSet,
  });
  final ExploreRun run;
  final ExploreFamily family;
  final ExploreParentSet parentSet;
  @override
  ConsumerState<_DeepRoundControl> createState() => _DeepRoundControlState();
}

abstract class _ExploreDeepRoundController
    extends ConsumerState<_DeepRoundControl> {
  int get _min => widget.parentSet.parents.length;
  int get _max => math.max(50, _min);
  late final _count = TextEditingController(text: '${_min + 1}');
  @override
  void dispose() {
    _count.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final l10n = context.l10n, value = int.tryParse(_count.text.trim());
    if (value == null || value < _min) {
      AppToast.warning(context, l10n.styleExplore_deepRoundCountHint(_min));
      return;
    }
    try {
      final started = await ref
          .read(exploreRunRunnerProvider.notifier)
          .startDeepRound(
            widget.run.id,
            familyId: widget.family.id,
            parentSetId: widget.parentSet.id,
            count: value.clamp(_min, _max),
          );
      if (!started && mounted) {
        AppToast.info(context, l10n.styleExplore_runBusy);
      }
    } on ExploreDeepRoundException catch (e) {
      if (!mounted) return;
      AppToast.error(context, switch (e.reason) {
        ExploreDeepRoundRejection.noRandomInstance =>
          l10n.styleExplore_deepRoundNoInstance,
        ExploreDeepRoundRejection.mutationEmpty =>
          l10n.styleExplore_deepRoundEmpty,
        ExploreDeepRoundRejection.invalidParentSet =>
          l10n.styleExplore_operationFailed,
      });
    }
  }
}

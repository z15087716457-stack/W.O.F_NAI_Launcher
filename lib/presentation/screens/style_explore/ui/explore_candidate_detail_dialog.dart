import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/presets/geist_theme.dart';
import '../../../widgets/common/image_detail/components/viewer_stage.dart';
import '../../../widgets/common/image_detail/components/viewer_top_bar.dart';
import '../../../widgets/common/image_detail/components/viewer_filmstrip.dart';
import '../actions/explore_candidate_actions.dart';
import 'explore_controls.dart';
import 'explore_dialog_frame.dart';
import 'explore_inspector.dart';

part '../actions/explore_viewer_controller.dart';
part 'explore_viewer_view.dart';

class ExploreCandidateDetailDialog extends ConsumerStatefulWidget {
  const ExploreCandidateDetailDialog({
    super.key,
    required this.runId,
    required this.candidateIds,
    this.initialIndex = 0,
  });
  final String runId;
  final List<String> candidateIds;
  final int initialIndex;
  static Future<String?> show(
    BuildContext context, {
    required String runId,
    required List<String> candidateIds,
    int initialIndex = 0,
  }) => showDialog<String>(
    context: context,
    useSafeArea: false,
    builder: (_) => ExploreCandidateDetailDialog(
      runId: runId,
      candidateIds: candidateIds,
      initialIndex: initialIndex,
    ),
  );
  @override
  ConsumerState<ExploreCandidateDetailDialog> createState() =>
      _ExploreViewerState();
}

import 'package:flutter/services.dart';
import 'dart:async';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/common/themed_input_dialog.dart';
import '../actions/explore_candidate_actions.dart';
import 'explore_candidate_hover_preview.dart';
import '../actions/explore_shared_actions.dart';
import 'explore_folder_assign_bar.dart';
import 'explore_onboarding.dart';
import 'explore_evolution_view.dart';
import '../actions/explore_evolution_actions.dart';
import 'horizontal_edge_fade.dart';
import '../../../providers/layout_state_provider.dart';
import '../../../providers/style_explore/explore_manual_capture.dart';
import '../../../providers/style_explore/explore_run_runner.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import 'explore_candidate_card.dart';
import 'explore_icon.dart';
import '../actions/explore_run_actions.dart';
import 'explore_selection_bar.dart';
import 'explore_style.dart';
import '../../../widgets/common/dashed_rounded_border.dart';

import 'explore_controls.dart';
import 'explore_text.dart';

part 'explore_wall_controller.dart';
part 'explore_wall_view.dart';

class ExploreCandidateWall extends ConsumerStatefulWidget {
  const ExploreCandidateWall({super.key, this.onGenerate, this.onOpenPrevious});
  final Future<void> Function()? onGenerate;
  final VoidCallback? onOpenPrevious;

  @override
  ConsumerState<ExploreCandidateWall> createState() =>
      _ExploreCandidateWallState();
}

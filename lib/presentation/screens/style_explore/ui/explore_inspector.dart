import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/pill_roll_engine.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../providers/style_explore/explore_run_provider.dart';
import '../../../providers/style_explore/explore_view_state.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../../../widgets/navigation/window_chrome_layout.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/pills/prompt_pill.dart';
import 'explore_artist_text.dart';
import '../actions/explore_candidate_actions.dart';
import 'explore_candidate_card.dart';
import 'explore_folder_assign_bar.dart';
import 'explore_icon.dart';
import '../actions/explore_shared_actions.dart';
import 'explore_style.dart';
import 'explore_highlighted_prompt.dart';
import 'explore_lineage_info.dart';
import 'explore_controls.dart';
import 'explore_text.dart';

part 'explore_inspector_controller.dart';
part 'explore_inspector_view.dart';

class ExploreInspector extends ConsumerStatefulWidget {
  const ExploreInspector({
    super.key,
    this.runId,
    this.candidateId,
    this.viewer = false,
    this.onEvolution,
    this.onAssigned,
    this.onClose,
  });
  final String? runId, candidateId;
  final bool viewer;
  final VoidCallback? onEvolution, onClose;
  final void Function(String?)? onAssigned;
  @override
  ConsumerState<ExploreInspector> createState() => _ExploreInspectorState();
}

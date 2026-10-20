import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/nai_agent/generation_tools.dart';
import '../../providers/nai_agent/nai_agent_gallery_binding.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/style_explore/explore_run_runner.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../providers/generation/cloud_upscale_provider.dart';
import '../../providers/director_tools_notifier.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import 'agent_gallery_card.dart';

/// Independent from Pi's visual/model gate: local UI previews and native undo.
final agentGalleryBindingProvider =
    Provider.family<NaiAgentGalleryBinding, (String, String, String)>((
      ref,
      identity,
    ) {
      var alive = true;
      ref.onDispose(() => alive = false);
      return NaiAgentGalleryBinding(
        ref,
        () => alive,
        workspace: Directory(identity.$1),
        owner: NaiAgentConversationOwner(identity.$2, identity.$3),
        isBusy: () =>
            (ref.exists(imageGenerationNotifierProvider) &&
                ref.read(imageGenerationNotifierProvider).isGenerating) ||
            (ref.exists(exploreRunRunnerProvider) &&
                ref.read(exploreRunRunnerProvider).isRunning) ||
            (ref.exists(imageWorkflowControllerProvider) &&
                ref.read(imageWorkflowControllerProvider).isToolRunning) ||
            (ref.exists(localUpscaleTaskProvider) &&
                ref.read(localUpscaleTaskProvider).running) ||
            (ref.exists(cloudUpscaleTaskProvider) &&
                ref.read(cloudUpscaleTaskProvider).running) ||
            (ref.exists(directorToolsNotifierProvider) &&
                ref.read(directorToolsNotifierProvider).isRunning) ||
            (ref.exists(kritaBridgeNotifierProvider) &&
                ref.read(kritaBridgeNotifierProvider).isBridgeGenerating) ||
            ref
                .read(naiAgentControllerProvider)
                .heldRuntimes
                .any((r) => r.running || r.starting),
      );
    });

class AgentGalleryUndo {
  AgentGalleryUndo(this.binding);
  final NaiAgentGalleryBinding binding;
  Future<bool> restore(AgentGalleryRestore change) => change.undoable
      ? binding.undoManage(change.arguments, change.details)
      : Future.value(false);
}

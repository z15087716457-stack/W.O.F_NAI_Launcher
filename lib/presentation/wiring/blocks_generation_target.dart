import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/image_generation_provider.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import 'blocks_platform.dart';

final blocksGenerationTargetProvider = Provider<BlocksGenerationTarget>(
  (ref) => BlocksGenerationTarget(ref),
);

class BlocksGenerationTarget {
  BlocksGenerationTarget(this.ref);
  final Ref ref;
  bool _writing = false;

  Future<bool> commit(
    void Function() write, {
    required bool Function() alive,
    bool Function()? unchanged,
  }) async {
    if (_writing) return false;
    _writing = true;
    try {
      final params = ref.read(generationParamsNotifierProvider);
      final version = ref.read(bridgeDraftVersionProvider);
      final workflow = ref.read(imageWorkflowControllerProvider);
      void check() {
        if (!alive() ||
            ref.read(generationParamsNotifierProvider) != params ||
            ref.read(bridgeDraftVersionProvider) != version ||
            !identical(workflow, ref.read(imageWorkflowControllerProvider)) ||
            unchanged?.call() == false) {
          throw StateError(currentL10n.bridge_conflict);
        }
        if (ref.read(imageGenerationNotifierProvider).isGenerating ||
            workflow.isToolRunning ||
            (ref.exists(kritaBridgeNotifierProvider) &&
                ref.read(kritaBridgeNotifierProvider).isBridgeGenerating)) {
          throw StateError(currentL10n.networkError_conflict);
        }
      }

      check();
      await ref
          .read(blocksPlatformProvider)
          .backupDraft(
            jsonEncode({
              ...readBridgeDraft(ref).toJson(),
              'generation': params.toJson(),
              'sourceImage': params.sourceImage == null
                  ? null
                  : base64Encode(params.sourceImage!),
              'maskImage': params.maskImage == null
                  ? null
                  : base64Encode(params.maskImage!),
              'vibes': [
                for (final vibe in params.vibeReferencesV4)
                  {
                    ...vibe.toJson(),
                    'rawImageData': vibe.rawImageData == null
                        ? null
                        : base64Encode(vibe.rawImageData!),
                    'thumbnail': vibe.thumbnail == null
                        ? null
                        : base64Encode(vibe.thumbnail!),
                  },
              ],
            }),
          );
      check();
      write();
      return true;
    } finally {
      _writing = false;
    }
  }
}

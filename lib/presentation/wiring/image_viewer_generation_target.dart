import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/image_generation_provider.dart';
import '../providers/krita/bridge_draft_snapshot.dart';
import '../providers/krita/krita_bridge_notifier.dart';
import 'image_viewer_platform.dart';

final imageViewerGenerationTargetProvider =
    Provider<ImageViewerGenerationTarget>(
      (ref) => ImageViewerGenerationTarget(ref),
    );

class ImageViewerGenerationTarget {
  ImageViewerGenerationTarget(this.ref);
  final Ref ref;
  bool _writing = false;

  Future<void> Function(FutureOr<void> Function()) capture({
    required bool Function() alive,
  }) {
    final params = ref.read(generationParamsNotifierProvider);
    final version = ref.read(bridgeDraftVersionProvider);
    final workflow = ref.read(imageWorkflowControllerProvider);
    void check() {
      if (!alive() ||
          ref.read(generationParamsNotifierProvider) != params ||
          ref.read(bridgeDraftVersionProvider) != version ||
          !identical(workflow, ref.read(imageWorkflowControllerProvider))) {
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
    final draft = readBridgeDraft(ref).toJson();
    return (write) async {
      if (_writing) throw StateError(currentL10n.networkError_conflict);
      _writing = true;
      try {
        check();
        await ref
            .read(imageViewerPlatformProvider)
            .backupDraft(
              jsonEncode({
                ...draft,
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
        await write();
      } finally {
        _writing = false;
      }
    };
  }
}

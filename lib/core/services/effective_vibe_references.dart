import '../../data/models/image/image_params.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../constants/model_spec.dart';

/// References effective for this request only. Never mutates the saved draft.
List<VibeReference> effectiveVibeReferences(
  ImageParams params,
  ModelSpec spec,
) {
  if (!spec.vibetransfer ||
      params.action == ImageGenerationAction.infill ||
      (params.isV45Model && params.hasPreciseReferences)) {
    return const [];
  }
  return params.enabledVibeReferencesV4;
}

import '../../../data/models/upscale/local_upscale_models.dart';
import '../../../l10n/app_localizations.dart';

String localUpscaleErrorLabel(
  AppLocalizations l,
  LocalUpscaleError error,
) => switch (error) {
  LocalUpscaleError.unsupportedPlatform => l.localUpscale_unsupportedPlatform,
  LocalUpscaleError.engineMissing => l.localUpscale_engineMissing,
  LocalUpscaleError.integrity => l.localUpscale_integrity,
  LocalUpscaleError.modelMissing => l.localUpscale_modelMissing,
  LocalUpscaleError.invalidModel => l.localUpscale_invalidModel,
  LocalUpscaleError.invalidImage => l.localUpscale_invalidImage,
  LocalUpscaleError.sizeLimit => l.localUpscale_sizeLimit,
  LocalUpscaleError.noVulkan => l.localUpscale_noVulkan,
  LocalUpscaleError.noCuda => l.localUpscale_noCuda,
  LocalUpscaleError.noInt8 => l.localUpscale_noInt8,
  LocalUpscaleError.noRtx => l.localUpscale_noRtx,
  LocalUpscaleError.outOfMemory => l.localUpscale_outOfMemory,
  LocalUpscaleError.processFailed => l.localUpscale_processFailed,
  LocalUpscaleError.modelOperationFailed => l.localUpscale_modelOperationFailed,
  LocalUpscaleError.timeout => l.localUpscale_timeout,
  LocalUpscaleError.busy => l.localUpscale_busy,
  LocalUpscaleError.cancelled => l.localUpscale_cancelled,
};

String localUpscaleInstallPhaseLabel(AppLocalizations l, String phase) =>
    switch (phase) {
      'python' => l.localUpscale_installingPython,
      'runtime' => l.localUpscale_installingRuntime,
      'weights' => l.localUpscale_downloadProgress,
      'checking' => l.localUpscale_checkingComponent,
      _ => l.localUpscale_installingComponent,
    };

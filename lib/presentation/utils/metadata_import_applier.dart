import '../../core/constants/api_constants.dart';
import '../../core/enums/quality_tag_preset.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../data/models/metadata/metadata_import_options.dart';

class MetadataImportTarget {
  const MetadataImportTarget({
    required this.updatePrompt,
    required this.updateNegativePrompt,
    required this.updateSeed,
    required this.updateSteps,
    required this.updateScale,
    required this.updateSize,
    required this.updateSampler,
    required this.updateModel,
    required this.updateSmea,
    required this.updateSmeaDyn,
    required this.updateVarietyPlus,
    required this.updateNoiseSchedule,
    required this.updateCfgRescale,
    required this.updateQualityToggle,
    required this.updateUcPreset,
  });

  final void Function(String value) updatePrompt;
  final void Function(String value) updateNegativePrompt;
  final void Function(int value) updateSeed;
  final void Function(int value) updateSteps;
  final void Function(double value) updateScale;
  final void Function(int width, int height) updateSize;
  final void Function(String value) updateSampler;
  final void Function(String value) updateModel;
  final void Function(bool value) updateSmea;
  final void Function(bool value) updateSmeaDyn;
  final void Function(bool value) updateVarietyPlus;
  final void Function(String value) updateNoiseSchedule;
  final void Function(double value) updateCfgRescale;
  final void Function(bool value) updateQualityToggle;
  final void Function(int value) updateUcPreset;
}

class MetadataImportApplier {
  MetadataImportApplier._();

  /// Only recorded fields can restore a preset. Matching words in the prompt
  /// are not evidence that the user selected one in the source application.
  static QualityTagPreset? recordedQualityPreset(NaiImageMetadata metadata) {
    if (metadata.qualityTagHint != null) {
      return QualityTagPreset.fromTagHintValue(metadata.qualityTagHint);
    }
    final toggle = metadata.qualityToggle;
    return toggle == null
        ? null
        : toggle
        ? QualityTagPreset.standard
        : QualityTagPreset.none;
  }

  static UcPresetType? recordedUcPreset(NaiImageMetadata metadata) {
    if (metadata.ucPresetTagHint != null) {
      return _supportedUcPreset(metadata, switch (metadata.ucPresetTagHint) {
        0 => UcPresetType.none,
        2 => UcPresetType.heavy,
        3 => UcPresetType.light,
        4 => UcPresetType.humanFocus,
        5 => UcPresetType.furryFocus,
        _ => null,
      });
    }
    final rawPreset = metadata.ucPreset;
    if (rawPreset == null) return null;
    final model = resolveImportableModel(metadata);
    if (model == ImageModels.furryDiffusion) {
      return _supportedUcPreset(metadata, switch (rawPreset) {
        UCPresets.lowQuality ||
        UcPresets.lowQualityApiValue => UcPresetType.lowQuality,
        UCPresets.badAnatomy ||
        UcPresets.badAnatomyApiValue => UcPresetType.badAnatomy,
        UcPresets.noneApiValue => UcPresetType.none,
        _ => null,
      });
    }
    return _supportedUcPreset(metadata, switch (rawPreset) {
      UcPresets.heavyApiValue => UcPresetType.heavy,
      UcPresets.lightApiValue => UcPresetType.light,
      UcPresets.humanFocusApiValue => UcPresetType.humanFocus,
      UcPresets.noneApiValue => UcPresetType.none,
      UCPresets.furryFocus => UcPresetType.furryFocus,
      _ => null,
    });
  }

  static UcPresetType? _supportedUcPreset(
    NaiImageMetadata metadata,
    UcPresetType? preset,
  ) {
    if (preset == null) return null;
    final model = resolveImportableModel(metadata);
    return model == null
        ? preset
        : UcPresets.effectiveTypeForModel(model, preset);
  }

  /// When a recorded preset is restored, move its generated suffix out of
  /// the editor so the request builder adds it exactly once. Without a
  /// recorded preset, the complete prompt is left untouched.
  static String resolveImportedPrompt(
    NaiImageMetadata metadata, {
    required bool importQualityPreset,
    required String currentModel,
  }) {
    final prompt = metadata.prompt;
    final preset = recordedQualityPreset(metadata);
    if (!importQualityPreset ||
        preset == null ||
        preset == QualityTagPreset.none) {
      return prompt;
    }
    final model = resolveImportableModel(metadata) ?? currentModel;
    final suffix = QualityTags.getQualityTags(model, preset: preset);
    if (suffix == null || suffix.isEmpty) return prompt;

    final trimmed = prompt.trimRight();
    if (ImageModels.resolveBaseModel(model) == ImageModels.furryDiffusion) {
      if (trimmed == suffix) return '';
      final prefix = '$suffix, ';
      return trimmed.startsWith(prefix)
          ? trimmed.substring(prefix.length)
          : prompt;
    }
    if (trimmed == suffix) return '';
    if (!trimmed.endsWith(suffix)) return prompt;
    final beforeSuffix = trimmed.substring(0, trimmed.length - suffix.length);
    final beforeSeparator = beforeSuffix.trimRight();
    if (!beforeSeparator.endsWith(',')) return prompt;
    return beforeSeparator.substring(0, beforeSeparator.length - 1).trimRight();
  }

  static int applyPromptAndGenerationParams({
    required NaiImageMetadata metadata,
    required MetadataImportOptions options,
    required String currentModel,
    required MetadataImportTarget target,
  }) {
    var count = 0;

    if (options.importPrompt && metadata.prompt.isNotEmpty) {
      target.updatePrompt(metadata.prompt);
      count++;
    }

    if (options.importNegativePrompt &&
        (metadata.negativePrompt.isNotEmpty ||
            (options.importUcPreset && metadata.ucPreset != null))) {
      target.updateNegativePrompt(
        resolveImportedNegativePrompt(
          metadata,
          importUcPreset: options.importUcPreset,
          currentModel: currentModel,
        ),
      );
      count++;
    }

    count += _applyValue<int>(
      options.importSeed,
      metadata.seed,
      target.updateSeed,
    );
    count += _applyValue<int>(
      options.importSteps,
      metadata.steps,
      target.updateSteps,
    );
    count += _applyValue<double>(
      options.importScale,
      metadata.scale,
      target.updateScale,
    );

    if (options.importSize &&
        metadata.width != null &&
        metadata.height != null) {
      target.updateSize(metadata.width!, metadata.height!);
      count++;
    }

    count += _applyValue<String>(
      options.importSampler,
      metadata.sampler,
      target.updateSampler,
    );
    count += _applyValue<String>(
      options.importModel,
      resolveImportableModel(metadata),
      target.updateModel,
    );
    count += _applyValue<bool>(
      options.importSmea,
      metadata.smea,
      target.updateSmea,
    );
    count += _applyValue<bool>(
      options.importSmeaDyn,
      metadata.smeaDyn,
      target.updateSmeaDyn,
    );
    count += _applyValue<bool>(
      options.importVarietyPlus,
      metadata.varietyPlus,
      target.updateVarietyPlus,
    );
    count += _applyValue<String>(
      options.importNoiseSchedule,
      metadata.noiseSchedule,
      target.updateNoiseSchedule,
    );
    count += _applyValue<double>(
      options.importCfgRescale,
      metadata.cfgRescale,
      target.updateCfgRescale,
    );
    count += _applyValue<bool>(
      options.importQualityToggle,
      metadata.qualityToggle,
      target.updateQualityToggle,
    );
    final recordedUc = recordedUcPreset(metadata);
    count += _applyValue<int>(
      options.importUcPreset,
      recordedUc == null ? null : UcPresets.toApiValue(recordedUc),
      target.updateUcPreset,
    );

    return count;
  }

  static String resolveImportedNegativePrompt(
    NaiImageMetadata metadata, {
    required bool importUcPreset,
    required String currentModel,
  }) {
    final baseNegative = metadata.displayNegativePrompt;
    final preset = recordedUcPreset(metadata);
    if (!importUcPreset || preset == null || preset == UcPresetType.none) {
      return baseNegative;
    }

    final model = resolveImportableModel(metadata) ?? currentModel;
    final stripped = UcPresets.stripPreset(baseNegative, model, preset);
    return stripped == baseNegative.trim() ? baseNegative : stripped;
  }

  static String? toImportableModelId(String? model) {
    if (model == null || model.isEmpty) return null;
    return ImageModels.allModels.contains(model) ? model : null;
  }

  static String? resolveImportableModel(NaiImageMetadata metadata) {
    return toImportableModelId(metadata.sourceModel) ??
        toImportableModelId(metadata.model);
  }

  static int _applyValue<T>(
    bool shouldImport,
    T? value,
    void Function(T value) update,
  ) {
    if (!shouldImport || value == null) {
      return 0;
    }
    update(value);
    return 1;
  }
}

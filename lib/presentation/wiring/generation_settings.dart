import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../core/enums/quality_tag_preset.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/character/character_prompt.dart';
import '../../data/models/image/image_params.dart' show ImageParamsExtension;
import '../providers/character_position_canvas_provider.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/layout_state_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../providers/uc_preset_provider.dart';
import '../ui/gen/gen_contract.dart';
import 'generation_backend.dart';

final generationSettingsProvider = Provider<GenerationSettings>(
  GenerationSettings.new,
);

GenLayout generationLayoutView(LayoutState state) => GenLayout(
  leftOpen: state.webLeftPanelExpanded,
  leftWidth: state.webLeftPanelWidth,
  historyOpen: state.rightPanelExpanded,
  historyWidth: state.rightPanelWidth,
  dockOpen: state.blockLibraryPanelExpanded,
);

class GenerationSettings {
  GenerationSettings(this.ref);
  final Ref ref;
  Future<void> _layoutQueue = Future<void>.value();
  GenerationBackend get _backend => ref.read(generationBackendProvider);
  GenerationParamsNotifier get _params =>
      ref.read(generationParamsNotifierProvider.notifier);
  ModelSpec get _spec =>
      ModelSpecs.of(ref.read(generationParamsNotifierProvider).model);

  Future<void> layout(GenLayout value, {required GenLayout previous}) {
    if (!value.leftWidth.isFinite || !value.historyWidth.isFinite) {
      throw const FormatException('Invalid panel width');
    }
    final operation = _layoutQueue.then((_) async {
      final notifier = ref.read(layoutStateNotifierProvider.notifier);
      await Future.wait([
        if (previous.leftOpen != value.leftOpen)
          notifier.setWebLeftPanelExpanded(value.leftOpen),
        if (previous.leftWidth != value.leftWidth)
          notifier.setWebLeftPanelWidth(
            value.leftWidth.clamp(GenLayout.minLeft, GenLayout.maxLeft),
          ),
        if (previous.historyOpen != value.historyOpen)
          notifier.setRightPanelExpanded(value.historyOpen),
        if (previous.historyWidth != value.historyWidth)
          notifier.setRightPanelWidth(
            value.historyWidth.clamp(
              GenLayout.minHistory,
              GenLayout.maxHistory,
            ),
          ),
        if (previous.dockOpen != value.dockOpen)
          notifier.setBlockLibraryPanelExpanded(value.dockOpen),
      ]);
    });
    _layoutQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> model(String value) => _backend.mutate(() {
    if (ImageModels.allModels.contains(value)) _params.updateModel(value);
  });
  Future<void> furry(bool value) => _backend.mutate(() {
    if (_spec.v4Prompts) _params.updateModelMode(value);
  });
  Future<void> transparent(bool value) => _backend.mutate(() {
    if (_spec.transparency) _params.updateTransparentBackground(value);
  });
  Future<void> size(int width, int height) => _backend.mutate(() {
    int aligned(int value) => ((value / 64).round() * 64).clamp(64, 4096);
    _params.updateSize(aligned(width), aligned(height));
  });
  Future<void> count(int value) => _backend.mutate(
    () => ref.read(imagesPerRequestProvider.notifier).set(value.clamp(1, 4)),
  );
  Future<void> repeat(int value) => _backend.mutate(() {
    final current = ref.read(generationParamsNotifierProvider).nSamples;
    _params.updateNSamples(value.clamp(1, current > 99 ? current : 99));
  });
  Future<void> param(GenParam param, double value) {
    if (!value.isFinite) {
      throw const FormatException('Invalid generation parameter');
    }
    return _backend.mutate(() {
      switch (param) {
        case GenParam.steps:
          _params.updateSteps(value.round().clamp(1, 50));
        case GenParam.scale:
          _params.updateScale(value.clamp(0, 10));
        case GenParam.cfgRescale:
          _params.updateCfgRescale(value.clamp(0, 1));
      }
    });
  }

  Future<void> seed(int value) =>
      _backend.mutate(() => _params.updateSeed(value.clamp(0, 4294967295)));
  Future<void> pinSeed(bool value, {int? lastSeed}) => _backend.mutate(() {
    if (!value) {
      _params.randomizeSeed();
    } else if (ref.read(generationParamsNotifierProvider).seed == -1) {
      if (lastSeed != null) {
        _params.updateSeed(lastSeed);
      } else {
        _params.pinRandomSeed();
      }
    }
  });
  Future<void> sampler(String value) => _backend.mutate(() {
    if (Samplers.samplersForModel(
      ref.read(generationParamsNotifierProvider).model,
    ).contains(value)) {
      _params.updateSampler(value);
    }
  });
  Future<void> noise(String value) => _backend.mutate(() {
    if (_spec.noiseSchedule && NoiseSchedules.all.contains(value)) {
      _params.updateNoiseSchedule(value);
    }
  });
  Future<void> variety(bool value) => _backend.mutate(() {
    if (_spec.varietyPlus) _params.updateVarietyPlus(value);
  });
  Future<void> decrisp(bool value) => _backend.mutate(() {
    if (ref.read(generationParamsNotifierProvider).isV3Model) {
      _params.updateDecrisp(value);
    }
  });
  Future<void> smea(GenSmea value) => _backend.mutate(() {
    final params = ref.read(generationParamsNotifierProvider);
    final sampler = params.sampler;
    if (!params.isV3Model ||
        !_spec.smea ||
        sampler == Samplers.ddim ||
        sampler == Samplers.ddimV3) {
      return;
    }
    _params.updateSmeaAuto(value.auto);
    _params.updateSmea(value.smea);
    _params.updateSmeaDyn(value.dyn && value.smea);
  });
  Future<void> quality(String value) => _backend.mutate(() {
    final native = QualityTagPreset.values
        .where((preset) => preset.name == value)
        .firstOrNull;
    if (native != null) {
      _params.updateQualityPreset(native);
    } else if (value.startsWith('block:')) {
      final id = value.substring(6);
      if (ref
              .read(promptBlockLibraryNotifierProvider)
              .valueOrNull
              ?.blockById(id) !=
          null) {
        _params.updateCustomQualityPreset(id);
      }
    }
  });
  Future<void> uc(String value) => _backend.mutate(() {
    final native = UcPresetType.values
        .where((preset) => preset.name == value)
        .firstOrNull;
    if (native != null) {
      _params.updateUcPreset(UcPresets.toApiValue(native));
    } else if (value.startsWith('block:')) {
      final id = value.substring(6);
      if (ref
              .read(promptBlockLibraryNotifierProvider)
              .valueOrNull
              ?.blockById(id) !=
          null) {
        ref.read(ucPresetNotifierProvider.notifier).setCustomEntry(id);
      }
    }
  });

  Future<void> promptTool(GenPromptTool tool, bool value) async {
    final layout = ref.read(layoutStateNotifierProvider.notifier);
    switch (tool) {
      case GenPromptTool.palettePinned:
        await layout.setBlockPaletteToolPinned(value);
      case GenPromptTool.dockPinned:
        await layout.setBlockLibraryPanelToolPinned(value);
      case GenPromptTool.translatePinned:
        if (ref.read(layoutStateNotifierProvider).translationToolPinned !=
            value) {
          await layout.toggleTranslationToolPinned();
        }
      case GenPromptTool.autoFormat:
        ref.read(autoFormatPromptSettingsProvider.notifier).set(value);
      case GenPromptTool.highlight:
        ref.read(highlightEmphasisSettingsProvider.notifier).set(value);
      case GenPromptTool.sdConvert:
        ref.read(sdSyntaxAutoConvertSettingsProvider.notifier).set(value);
      case GenPromptTool.related:
        ref.read(cooccurrenceSettingsProvider.notifier).set(value);
    }
  }

  CharacterPrompt _character(String id) =>
      ref.read(characterPromptNotifierProvider).findCharacterById(id) ??
      (throw StateError(currentL10n.bridge_conflict));
  Future<void> _updateCharacter(
    String id,
    CharacterPrompt Function(CharacterPrompt) update,
  ) => _backend.mutate(() {
    ref
        .read(characterPromptNotifierProvider.notifier)
        .updateCharacter(update(_character(id)));
  });
  Future<void> addCharacter(GenGender gender) => _backend.mutate(() {
    if (ref.read(characterPromptNotifierProvider).characters.length >=
        _spec.maxCharacters) {
      return;
    }
    ref
        .read(characterPromptNotifierProvider.notifier)
        .addCharacter(CharacterGender.values.byName(gender.name));
  });
  Future<void> removeCharacter(String id) => _backend.mutate(() {
    _character(id);
    ref.read(characterPromptNotifierProvider.notifier).removeCharacter(id);
  });
  Future<void> clearCharacters() => _backend.mutate(
    () => ref.read(characterPromptNotifierProvider.notifier).clearAll(),
  );
  Future<void> renameCharacter(String id, String value) => _updateCharacter(
    id,
    (character) => character.copyWith(
      name: value.trim(),
      nameIsCustom: value.trim().isNotEmpty,
    ),
  );
  Future<void> characterEnabled(String id, bool value) =>
      _updateCharacter(id, (character) => character.copyWith(enabled: value));
  Future<void> characterGender(String id, GenGender value) => _updateCharacter(
    id,
    (character) =>
        character.copyWith(gender: CharacterGender.values.byName(value.name)),
  );
  Future<void> moveCharacter(String id, int delta) => _backend.mutate(() {
    final characters = ref.read(characterPromptNotifierProvider).characters;
    final index = characters.indexWhere((character) => character.id == id);
    if (index < 0) throw StateError(currentL10n.bridge_conflict);
    final target = index + delta;
    if (target < 0 || target >= characters.length) return;
    ref
        .read(characterPromptNotifierProvider.notifier)
        .reorderCharacters(index, target > index ? target + 1 : target);
  });
  Future<void> aiPosition(bool value) => _backend.mutate(() {
    if (_spec.characterPrompts) {
      ref
          .read(characterPromptNotifierProvider.notifier)
          .setGlobalAiChoice(value);
    }
  });
  Future<void> characterPosition(String id, Offset value) {
    if (!value.dx.isFinite || !value.dy.isFinite) {
      throw const FormatException('Invalid character position');
    }
    return _backend.mutate(() {
      if (!_spec.characterPrompts) return;
      _character(id);
      double coordinate(double value) => _spec.freeformCharacterPosition
          ? value.clamp(0, 1)
          : ((value.clamp(0, 1) * 5).floor().clamp(0, 4) + .5) / 5;
      final notifier = ref.read(characterPromptNotifierProvider.notifier);
      notifier.setGlobalAiChoice(false);
      notifier.updateCharacter(
        _character(id).copyWith(
          positionMode: CharacterPositionMode.custom,
          customPosition: CharacterPosition(
            mode: CharacterPositionMode.custom,
            column: coordinate(value.dx),
            row: coordinate(value.dy),
          ),
        ),
      );
    });
  }

  Future<void> positioning(bool value) => _backend.mutate(() {
    final notifier = ref.read(characterPositionCanvasProvider.notifier);
    if (value) {
      notifier.open();
    } else {
      notifier.close();
    }
  });
}

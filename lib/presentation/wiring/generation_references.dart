import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as pixels;

import '../../core/constants/model_spec.dart';
import '../../core/enums/precise_ref_type.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/vibe/vibe_library_entry.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/image_generation_provider.dart';
import '../ui/gen/gen_contract.dart';
import 'generation_backend.dart';
import 'generation_reference_identity.dart';

final generationReferencesProvider = Provider<GenerationReferences>(
  GenerationReferences.new,
);
final _blankThumbnail = MemoryImage(
  Uint8List.fromList(
    pixels.encodePng(pixels.Image(width: 1, height: 1, numChannels: 4)),
  ),
);
ImageProvider generationReferenceThumbnail(Uint8List? bytes) =>
    bytes == null || bytes.isEmpty ? _blankThumbnail : MemoryImage(bytes);

GenRefsData generationRefsView(
  ImageParams params,
  ImageWorkflowState workflow,
  GenerationReferenceIdentity identity, {
  bool enabled = true,
  Set<String> encoding = const {},
  List<VibeLibraryEntry> recent = const [],
  GenDropTarget? dropHover,
}) {
  identity.sync(params);
  final spec = ModelSpecs.of(params.model);
  return GenRefsData(
    dropHover: dropHover,
    vibeSuspendedForInpaint: workflow.isInpaint && params.hasVibeReferencesV4,
    img2img: GenImg2Img(
      image: params.sourceImage == null
          ? null
          : MemoryImage(params.sourceImage!),
      width: workflow.sourceImageWidth ?? workflow.sourceWidth ?? 0,
      height: workflow.sourceImageHeight ?? workflow.sourceHeight ?? 0,
      strength: params.strength,
      noise: params.noise,
      enabled: enabled,
      mask: params.maskImage == null ? GenMask.none : GenMask.ready,
      inpaintStrength: params.inpaintStrength,
    ),
    vibes: spec.vibetransfer
        ? GenVibesData(
            normalize: params.normalizeVibeStrength,
            list: [
              for (
                var index = 0;
                index < params.vibeReferencesV4.length;
                index++
              )
                GenVibe(
                  id: identity.vibes[index],
                  thumb: generationReferenceThumbnail(
                    params.vibeReferencesV4[index].thumbnail ??
                        params.vibeReferencesV4[index].rawImageData,
                  ),
                  name: params.vibeReferencesV4[index].displayName,
                  strength: params.vibeReferencesV4[index].strength,
                  info: params.vibeReferencesV4[index].infoExtracted,
                  enabled: params.vibeReferencesV4[index].enabled,
                  state: encoding.contains(identity.vibes[index])
                      ? GenVibeState.encoding
                      : params.vibeReferencesV4[index].needsEncodingForModel(
                          params.model,
                        )
                      ? GenVibeState.pending
                      : GenVibeState.encoded,
                ),
            ],
            recent: [
              for (final entry in recent)
                GenRecentVibe(
                  id: entry.id,
                  name: entry.displayName,
                  thumb: generationReferenceThumbnail(entry.thumbnail),
                ),
            ],
          )
        : null,
    precise: spec.characterReferences
        ? GenPreciseData(
            list: [
              for (
                var index = 0;
                index < params.preciseReferences.length;
                index++
              )
                GenPrecise(
                  id: identity.precise[index],
                  thumb: MemoryImage(params.preciseReferences[index].image),
                  type: switch (params.preciseReferences[index].type) {
                    PreciseRefType.character => GenPreciseType.character,
                    PreciseRefType.style => GenPreciseType.style,
                    PreciseRefType.characterAndStyle => GenPreciseType.both,
                  },
                  strength: params.preciseReferences[index].strength,
                  fidelity: params.preciseReferences[index].fidelity,
                  enabled: params.preciseReferences[index].enabled,
                ),
            ],
          )
        : null,
  );
}

class GenerationReferences {
  GenerationReferences(this.ref);
  final Ref ref;
  GenerationBackend get _backend => ref.read(generationBackendProvider);
  GenerationParamsNotifier get _params =>
      ref.read(generationParamsNotifierProvider.notifier);
  ModelSpec get _spec =>
      ModelSpecs.of(ref.read(generationParamsNotifierProvider).model);
  int _index(String id, {bool precise = false}) {
    final identity = ref.read(generationReferenceIdentityProvider)
      ..sync(ref.read(generationParamsNotifierProvider));
    final index = precise ? identity.preciseIndex(id) : identity.vibeIndex(id);
    if (index < 0) throw StateError(currentL10n.bridge_conflict);
    return index;
  }

  Future<void> img2img(GenImg2Img value, {GenImg2Img? previous}) {
    if (![
      value.strength,
      value.noise,
      value.inpaintStrength,
    ].every((number) => number.isFinite)) {
      throw const FormatException('Invalid image parameters');
    }
    return _backend.mutate(() {
      if (previous == null || value.strength != previous.strength) {
        _params.updateStrength(value.strength.clamp(0, 1));
      }
      if (previous == null || value.noise != previous.noise) {
        _params.updateNoise(value.noise.clamp(0, 1));
      }
      if (previous == null ||
          value.inpaintStrength != previous.inpaintStrength) {
        _params.updateInpaintStrength(value.inpaintStrength.clamp(0, 1));
      }
      if (previous == null || value.enabled != previous.enabled) {
        ref.read(generationImg2ImgEnabledProvider.notifier).set(value.enabled);
      }
    });
  }

  Future<void> vibe(GenVibe value, {GenVibe? previous}) {
    if (!value.strength.isFinite || !value.info.isFinite) {
      throw const FormatException('Invalid reference parameters');
    }
    return _backend.mutate(() {
      if (!_spec.vibetransfer) return;
      _params.updateVibeReference(
        _index(value.id),
        strength: previous == null || value.strength != previous.strength
            ? value.strength
            : null,
        infoExtracted: previous == null || value.info != previous.info
            ? value.info
            : null,
        enabled: previous == null || value.enabled != previous.enabled
            ? value.enabled
            : null,
      );
    });
  }

  Future<void> removeVibe(String id) => _backend.mutate(() {
    if (_spec.vibetransfer) _params.removeVibeReference(_index(id));
  });
  Future<void> clearVibes() => _backend.mutate(() {
    if (_spec.vibetransfer) _params.clearVibeReferences();
  });
  Future<void> normalize(bool value) => _backend.mutate(() {
    if (_spec.vibetransfer) _params.setNormalizeVibeStrength(value);
  });
  Future<void> precise(GenPrecise value, {GenPrecise? previous}) {
    if (!value.strength.isFinite || !value.fidelity.isFinite) {
      throw const FormatException('Invalid reference parameters');
    }
    return _backend.mutate(() {
      if (!_spec.characterReferences) return;
      _params.updatePreciseReference(
        _index(value.id, precise: true),
        type: previous == null || value.type != previous.type
            ? switch (value.type) {
                GenPreciseType.character => PreciseRefType.character,
                GenPreciseType.style => PreciseRefType.style,
                GenPreciseType.both => PreciseRefType.characterAndStyle,
              }
            : null,
        strength: previous == null || value.strength != previous.strength
            ? value.strength
            : null,
        fidelity: previous == null || value.fidelity != previous.fidelity
            ? value.fidelity
            : null,
        enabled: previous == null || value.enabled != previous.enabled
            ? value.enabled
            : null,
      );
    });
  }

  Future<void> removePrecise(String id) => _backend.mutate(() {
    if (_spec.characterReferences) {
      _params.removePreciseReference(_index(id, precise: true));
    }
  });
  Future<void> clearPrecise() => _backend.mutate(() {
    if (_spec.characterReferences) _params.clearPreciseReferences();
  });
}

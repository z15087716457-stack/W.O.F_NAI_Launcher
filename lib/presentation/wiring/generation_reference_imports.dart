import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../core/enums/precise_ref_type.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/nai_api_utils.dart';
import '../../core/utils/nai_resolution_adapter.dart';
import '../../core/utils/vibe_file_parser.dart';
import '../../data/models/image/image_params.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../providers/generation/image_workflow_controller.dart';
import '../providers/image_generation_provider.dart';
import '../ui/gen/gen_contract.dart';
import 'generation_backend.dart';
import 'generation_reference_identity.dart';

class GenerationReferenceFile {
  const GenerationReferenceFile(
    this.name,
    this.bytes, {
    this.type = PreciseRefType.character,
    this.strength = 1,
    this.fidelity = 1,
  });
  final String name;
  final Uint8List bytes;
  final PreciseRefType type;
  final double strength;
  final double fidelity;
}

final generationReferenceDecoderProvider = Provider<GenerationReferenceDecoder>(
  (ref) => const GenerationReferenceDecoder(),
);
final generationReferenceImportsProvider = Provider<GenerationReferenceImports>(
  GenerationReferenceImports.new,
);

class GenerationReferenceDecoder {
  const GenerationReferenceDecoder();
  Future<List<VibeReference>> vibes(GenerationReferenceFile file) =>
      VibeFileParser.parseFile(file.name, file.bytes);
  Future<Uint8List> precise(GenerationReferenceFile file) =>
      NAIApiUtils.ensurePngFormatAsync(file.bytes);
  Future<NaiImportImageInfo?> source(
    GenerationReferenceFile file,
    ImageParams params,
  ) => NaiResolutionAdapter.describeImageForImportAsync(
    file.bytes,
    currentWidth: params.width,
    currentHeight: params.height,
    isStableDiffusionFamily: [
      ImageModels.animeCurated,
      ImageModels.animeFull,
      ImageModels.furry,
    ].contains(ImageModels.resolveBaseModel(params.model)),
  );
}

final generationVibeEncoderProvider =
    Provider<Future<String?> Function(VibeReference, String)>(
      (ref) =>
          (vibe, model) => ref
              .read(generationParamsNotifierProvider.notifier)
              .encodeVibeWithCache(
                vibe.rawImageData!,
                model: model,
                informationExtracted: vibe.infoExtracted,
                vibeName: vibe.displayName,
              ),
    );

class GenerationReferenceImports {
  GenerationReferenceImports(this.ref) {
    ref.onDispose(() => _disposed = true);
  }
  final Ref ref;
  bool _disposed = false;
  int _revision = 0;
  final _tickets = <GenDropTarget, int>{};
  GenerationBackend get _backend => ref.read(generationBackendProvider);
  GenerationParamsNotifier get _params =>
      ref.read(generationParamsNotifierProvider.notifier);
  Future<void> files(
    GenDropTarget target,
    Future<List<GenerationReferenceFile>> Function() load, {
    bool Function()? alive,
    bool Function()? replaceRequested,
    void Function()? onApplied,
  }) async {
    final params = ref.read(generationParamsNotifierProvider);
    final spec = ModelSpecs.of(params.model);
    if (target == GenDropTarget.vibe && !spec.vibetransfer ||
        target == GenDropTarget.precise && !spec.characterReferences) {
      return;
    }
    final ticket = ++_revision;
    _tickets[target] = ticket;
    final write = _backend.captureDraft(
      alive: () =>
          !_disposed && _tickets[target] == ticket && alive?.call() != false,
    );
    final selected = await load();
    if (selected.isEmpty || _disposed || alive?.call() == false) return;
    final decoder = ref.read(generationReferenceDecoderProvider);
    switch (target) {
      case GenDropTarget.vibe:
        final vibes = <VibeReference>[];
        for (final file in selected) {
          vibes.addAll(await decoder.vibes(file));
        }
        if (params.vibeReferencesV4.length + vibes.length > 16) {
          throw StateError(currentL10n.toast_styleReferenceLimit(16));
        }
        if (vibes.isEmpty) return;
        await write(() => _params.addVibeReferences(vibes));
      case GenDropTarget.precise:
        await write(() {
          if (replaceRequested?.call() == true) {
            _params.clearPreciseReferences();
          }
          for (final file in selected) {
            unawaited(
              _params.addPreciseReferenceFromImage(
                file.bytes,
                type: file.type,
                strength: file.strength,
                fidelity: file.fidelity,
                normalize: (_) => decoder.precise(file),
              ),
            );
          }
          onApplied?.call();
        });
      case GenDropTarget.img2img:
        final file = selected.first;
        final info = await decoder.source(file, params);
        if (info == null) throw FormatException(currentL10n.vibeParseFailed);
        await write(() {
          final workflow = ref.read(imageWorkflowControllerProvider.notifier);
          workflow.closeTemporaryTool();
          workflow.enterBaseMode(clearMask: true);
          workflow.replaceSourceImage(
            file.bytes,
            sourceWidth: info.width,
            sourceHeight: info.height,
            autoAdapt: false,
          );
          workflow.setPanelExpanded(true);
          ref.read(generationImg2ImgEnabledProvider.notifier).set(true);
          onApplied?.call();
        });
    }
  }

  Future<void> vibes(
    Future<List<VibeReference>> Function() load, {
    bool replace = false,
    bool appendOnly = false,
    bool Function()? alive,
    bool Function()? replaceRequested,
    void Function()? onApplied,
  }) async {
    final params = ref.read(generationParamsNotifierProvider);
    if (!ModelSpecs.of(params.model).vibetransfer) return;
    final ticket = ++_revision;
    _tickets[GenDropTarget.vibe] = ticket;
    final write = _backend.captureDraft(
      alive: () =>
          !_disposed &&
          _tickets[GenDropTarget.vibe] == ticket &&
          alive?.call() != false,
    );
    final values = await load();
    if (values.isEmpty || _disposed || alive?.call() == false) return;
    final replaceNow = replaceRequested?.call() ?? replace;
    if ((replaceNow ? 0 : params.vibeReferencesV4.length) + values.length >
        16) {
      throw StateError(currentL10n.toast_styleReferenceLimit(16));
    }
    await write(() {
      if (replaceNow || appendOnly) {
        _params.setVibeReferences([
          if (!replaceNow) ...params.vibeReferencesV4,
          ...values,
        ]);
      } else {
        _params.addVibeReferences(values);
      }
      onApplied?.call();
    });
  }

  Future<void> encode(
    String id, {
    required Future<bool> Function(int cost) confirm,
    bool Function()? alive,
  }) async {
    if (_disposed ||
        _backend.busy ||
        ref.read(generationEncodingReferencesProvider).contains(id)) {
      return;
    }
    final params = ref.read(generationParamsNotifierProvider);
    if (!ModelSpecs.of(params.model).vibetransfer) return;
    final ids = ref.read(generationReferenceIdentityProvider)..sync(params);
    final index = ids.vibeIndex(id);
    if (index < 0) throw StateError(currentL10n.bridge_conflict);
    final vibe = params.vibeReferencesV4[index];
    if (!vibe.canReencodeFromRawSource ||
        !vibe.needsEncodingForModel(params.model)) {
      return;
    }
    final commit = _backend.captureDraft(
      alive: () => !_disposed && alive?.call() != false,
    );
    final cached = _params.getCachedVibeEncoding(
      vibe.rawImageData!,
      model: params.model,
      informationExtracted: vibe.infoExtracted,
    );
    ref
        .read(generationEncodingReferencesProvider.notifier)
        .update((values) => {...values, id});
    try {
      if (cached == null && !await confirm(2)) return;
      late Future<String?> result;
      await commit(() {
        result = cached == null
            ? ref.read(generationVibeEncoderProvider)(vibe, params.model)
            : Future.value(cached);
      });
      final encoding = await result;
      if (encoding == null || encoding.isEmpty) {
        throw StateError(currentL10n.vibeParseFailed);
      }
      await commit(() {
        final identity = ref.read(generationReferenceIdentityProvider)
          ..sync(ref.read(generationParamsNotifierProvider));
        final current = identity.vibeIndex(id);
        if (current < 0) throw StateError(currentL10n.bridge_conflict);
        _params.updateVibeReference(current, vibeEncoding: encoding);
      });
    } finally {
      if (!_disposed) {
        ref
            .read(generationEncodingReferencesProvider.notifier)
            .update((values) => Set.of(values)..remove(id));
      }
    }
  }
}

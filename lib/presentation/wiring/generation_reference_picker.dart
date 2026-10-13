import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../core/constants/model_display.dart';
import '../../data/services/precise_ref_library_storage_service.dart';
import '../../data/services/vibe_library_storage_service.dart';
import '../providers/image_generation_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../providers/vibe_library_provider.dart';
import '../providers/vibe_library_category_provider.dart';
import '../ui/refs/refs_contract.dart';
import '../ui/refs/refs_picker.dart';
import '../widgets/common/app_toast.dart';
import 'generation_reference_identity.dart';

final generationLibraryOriginsProvider = StateProvider<Map<String, String>>(
  (ref) => const {},
);

class GenerationReferenceSelection {
  const GenerationReferenceSelection(this.keys, {required this.replace});
  final List<String> keys;
  final bool replace;
}

class GenerationReferenceThumbnail
    extends ImageProvider<GenerationReferenceThumbnail> {
  const GenerationReferenceThumbnail(
    this.owner,
    this.id,
    this.revision,
    this.readBytes,
  );
  final Object owner;
  final String id;
  final Object? revision;
  final Future<Uint8List?> Function() readBytes;
  @override
  Future<GenerationReferenceThumbnail> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    GenerationReferenceThumbnail key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: load(decode), scale: 1);
  Future<ui.Codec> load(ImageDecoderCallback decode) async {
    final bytes = await readBytes();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Reference image unavailable');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is GenerationReferenceThumbnail &&
      identical(owner, other.owner) &&
      id == other.id &&
      revision == other.revision;
  @override
  int get hashCode => Object.hash(identityHashCode(owner), id, revision);
}

class GenerationReferencePicker extends ConsumerStatefulWidget {
  const GenerationReferencePicker({
    super.key,
    required this.kind,
    this.single = false,
  });
  final RefsKind kind;
  final bool single;
  static Future<GenerationReferenceSelection?> show(
    BuildContext context, {
    required RefsKind kind,
    bool single = false,
  }) => showDialog<GenerationReferenceSelection>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GenerationReferencePicker(kind: kind, single: single),
    ),
  );
  @override
  ConsumerState<GenerationReferencePicker> createState() =>
      _GenerationReferencePickerState();
}

class _GenerationReferencePickerState
    extends ConsumerState<GenerationReferencePicker> {
  bool closed = false;
  bool get vibe => widget.kind == RefsKind.vibe;
  void close([GenerationReferenceSelection? selection]) {
    if (!mounted || closed || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    closed = true;
    Navigator.of(context).pop(selection);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        (vibe
                ? ref.read(vibeLibraryNotifierProvider.notifier).initialize()
                : ref
                      .read(preciseRefLibraryNotifierProvider.notifier)
                      .initialize())
            .catchError((Object error) {
              if (mounted) AppToast.error(context, error.toString());
            }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = ref.watch(generationParamsNotifierProvider);
    final spec = ModelSpecs.of(params.model);
    final origins = ref.watch(generationLibraryOriginsProvider);
    final identity = ref.read(generationReferenceIdentityProvider);
    final used = (vibe ? identity.vibes : identity.precise)
        .map((id) => origins[id])
        .whereType<String>()
        .toSet();
    final entries = <RefsEntry>[];
    final categories = <RefsCategory>[];
    if (vibe) {
      final state = ref.watch(vibeLibraryNotifierProvider);
      final storage = ref.watch(vibeLibraryStorageServiceProvider);
      for (final entry in state.entries) {
        final encoded = entry.vibeEncoding.isNotEmpty;
        final hasRaw = entry.canReencodeFromRawSource;
        entries.add(
          RefsEntry(
            key: entry.id,
            name: entry.displayName,
            favorite: entry.isFavorite,
            inGeneration: used.contains(entry.id),
            strength: entry.strength,
            infoExtracted: entry.infoExtracted,
            source:
                RefsVibeSource.values.elementAtOrNull(entry.sourceTypeIndex) ??
                RefsVibeSource.rawImage,
            encodedFor: entry.encodingModel == null
                ? null
                : ModelDisplay.shortNameOf(entry.encodingModel!),
            encoding: entry.isBundle
                ? RefsEncoding.unknown
                : encoded
                ? entry.encodingModel == null
                      ? RefsEncoding.unknown
                      : entry.encodingModel == params.model
                      ? RefsEncoding.ready
                      : hasRaw
                      ? RefsEncoding.reencode
                      : RefsEncoding.unusable
                : hasRaw
                ? RefsEncoding.encodeOnUse
                : RefsEncoding.unknown,
            hasRaw: hasRaw ? true : null,
            bundleCount: entry.bundledVibeCount,
            categoryId: entry.categoryId,
            tags: entry.tags,
            usedCount: entry.usedCount,
            lastUsed: entry.lastUsedAt,
            createdAt: entry.createdAt,
            thumb: GenerationReferenceThumbnail(
              storage,
              entry.id,
              entry,
              () => storage.getDisplayThumbnail(entry.id),
            ),
          ),
        );
      }
      for (final category
          in ref.watch(vibeLibraryCategoryNotifierProvider).categories) {
        categories.add(
          RefsCategory(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
            count: entries
                .where((entry) => entry.categoryId == category.id)
                .length,
          ),
        );
      }
    } else {
      final state = ref.watch(preciseRefLibraryNotifierProvider);
      final storage = ref.watch(preciseRefLibraryStorageServiceProvider);
      for (final entry in state.entries) {
        entries.add(
          RefsEntry(
            key: entry.id,
            name: entry.name,
            favorite: entry.isFavorite,
            inGeneration: used.contains(entry.id),
            strength: entry.strength,
            fidelity: entry.fidelity,
            type: RefsPreciseType.values[entry.type.index],
            hasRaw: true,
            usedCount: entry.usedCount,
            lastUsed: entry.lastUsedAt,
            createdAt: entry.createdAt,
            thumb: GenerationReferenceThumbnail(
              storage,
              entry.id,
              entry.imagePath,
              () => storage.getDisplayThumbnail(entry.id),
            ),
          ),
        );
      }
    }
    entries.sort((a, b) {
      final order = (b.lastUsed ?? DateTime(0)).compareTo(
        a.lastUsed ?? DateTime(0),
      );
      return order == 0 ? a.key.compareTo(b.key) : order;
    });
    return RefsPicker(
      data: RefsPickerData(
        kind: widget.kind,
        now: DateTime.now(),
        model: RefsModel(
          name: ImageModels.modelDisplayNames[params.model] ?? params.model,
          shortName: ImageModels.isV45Model(params.model)
              ? 'V4.5'
              : spec.family == ModelFamily.v5
              ? 'V5'
              : spec.family == ModelFamily.v4
              ? 'V4'
              : 'V3',
          vibeUsable: spec.vibetransfer,
          preciseUsable: spec.characterReferences,
        ),
        costs: const RefsCosts(),
        entries: entries,
        categories: categories,
        recent: entries
            .where((entry) => entry.lastUsed != null)
            .take(7)
            .map((entry) => entry.key)
            .toList(),
        inUse: vibe
            ? params.vibeReferencesV4.length
            : params.preciseReferences.length,
        single: widget.single,
      ),
      actions: RefsPickerActions(
        onClose: close,
        onConfirm: (keys, {required replace}) =>
            close(GenerationReferenceSelection(keys, replace: replace)),
        onOpenLibrary: () {
          if (closed) return;
          close();
          context.go(vibe ? '/vibe-library' : '/precise-ref-library');
        },
      ),
    );
  }
}

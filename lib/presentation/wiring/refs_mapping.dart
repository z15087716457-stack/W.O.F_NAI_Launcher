import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/api_constants.dart';
import '../../core/constants/model_spec.dart';
import '../../core/services/anlas_calculator.dart';
import '../../core/enums/precise_ref_type.dart';
import '../../data/models/precise_ref/precise_ref_library_entry.dart';
import '../../data/models/vibe/vibe_library_category.dart';
import '../../data/models/vibe/vibe_library_entry.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../ui/refs/refs_contract.dart';

String refsBytesFingerprint(Uint8List bytes) =>
    sha256.convert(bytes).toString();

String refsVibeFingerprint(VibeReference vibe) => vibe.canReencodeFromRawSource
    ? 'raw:${refsBytesFingerprint(vibe.rawImageData!)}'
    : 'encoded:${sha256.convert(utf8.encode(vibe.vibeEncoding))}';

class RefsVibeStatus {
  const RefsVibeStatus({
    required this.hasRaw,
    required this.encodings,
    required this.fingerprints,
    this.previews = const [],
  });
  final List<Uint8List> previews;
  final bool hasRaw;
  final List<({bool encoded, bool hasRaw, String? model})> encodings;
  final Set<String> fingerprints;

  factory RefsVibeStatus.fromEntry(VibeLibraryEntry entry) =>
      RefsVibeStatus.fromVibes(
        entry.isBundle ? refsBundleVibes(entry) : [entry.toVibeReference()],
      );

  factory RefsVibeStatus.fromVibes(List<VibeReference> vibes) {
    return RefsVibeStatus(
      hasRaw: vibes.any((v) => v.canReencodeFromRawSource),
      previews: vibes
          .take(3)
          .map((v) => v.thumbnail)
          .whereType<Uint8List>()
          .where((bytes) => bytes.length <= 256 * 1024)
          .toList(),
      encodings: [
        for (final v in vibes)
          (
            encoded: v.hasVibeEncoding,
            hasRaw: v.canReencodeFromRawSource,
            model: v.encodingModel,
          ),
      ],
      fingerprints: {
        for (final v in vibes)
          if (v.hasVibeEncoding || v.canReencodeFromRawSource)
            refsVibeFingerprint(v),
      },
    );
  }

  RefsEncoding encoding(String model) {
    if (!ModelSpecs.of(model).vibetransfer) return RefsEncoding.ready;
    if (encodings.isEmpty) return RefsEncoding.unusable;
    final states = [
      for (final e in encodings)
        !e.encoded
            ? (e.hasRaw ? RefsEncoding.encodeOnUse : RefsEncoding.unusable)
            : e.model == null
            ? RefsEncoding.unknown
            : e.model == model
            ? RefsEncoding.ready
            : e.hasRaw
            ? RefsEncoding.reencode
            : RefsEncoding.unusable,
    ];
    for (final state in [
      RefsEncoding.unusable,
      RefsEncoding.reencode,
      RefsEncoding.encodeOnUse,
      RefsEncoding.unknown,
    ]) {
      if (states.contains(state)) return state;
    }
    return RefsEncoding.ready;
  }

  String? get encodedFor {
    final models = encodings.map((e) => e.model).toSet();
    return models.length == 1 && models.single != null
        ? refsShortModel(models.single!)
        : null;
  }
}

String refsShortModel(String model) => ImageModels.isV45Model(model)
    ? 'V4.5'
    : switch (ModelSpecs.of(model).family) {
        ModelFamily.v5 => 'V5',
        ModelFamily.v4 => 'V4',
        _ => 'V3',
      };

RefsCosts refsCosts() => RefsCosts(
  maxVibes: AnlasCalculator.maximumVibeReferences,
  freeVibes: AnlasCalculator.freeVibeReferences,
  extraPerVibe: AnlasCalculator.extraVibeCost,
  encode: AnlasCalculator.vibeEncodingCost,
  precise: AnlasCalculator.preciseReferenceCost,
);

RefsModel refsModel(String model) {
  final spec = ModelSpecs.of(model);
  return RefsModel(
    name: ImageModels.modelDisplayNames[model] ?? model,
    shortName: refsShortModel(model),
    vibeUsable: spec.vibetransfer,
    preciseUsable: spec.characterReferences,
    switchTarget: !spec.vibetransfer || !spec.characterReferences
        ? ImageModels.modelDisplayNames[ImageModels.animeDiffusionV45Full]
        : null,
  );
}

RefsPreciseType refsPreciseType(PreciseRefType value) => switch (value) {
  PreciseRefType.character => RefsPreciseType.character,
  PreciseRefType.style => RefsPreciseType.style,
  PreciseRefType.characterAndStyle => RefsPreciseType.both,
};

PreciseRefType preciseRefType(RefsPreciseType value) => switch (value) {
  RefsPreciseType.character => PreciseRefType.character,
  RefsPreciseType.style => PreciseRefType.style,
  RefsPreciseType.both => PreciseRefType.characterAndStyle,
};

RefsEntry mapVibeEntry(
  VibeLibraryEntry entry, {
  required String model,
  RefsVibeStatus? status,
  ImageProvider? thumb,
  bool inGeneration = false,
}) => RefsEntry(
  key: entry.id,
  name: entry.displayName,
  thumb: thumb,
  favorite: entry.isFavorite,
  inGeneration: inGeneration,
  strength: entry.strength,
  infoExtracted: entry.infoExtracted,
  source: RefsVibeSource.values[entry.sourceTypeIndex],
  encoding: status?.encoding(model) ?? RefsEncoding.unknown,
  encodedFor: status?.encodedFor,
  hasRaw: status?.hasRaw,
  bundleCount: entry.bundledVibeCount,
  bundleThumbs: [
    for (final bytes in status?.previews.skip(1) ?? <Uint8List>[])
      ResizeImage(MemoryImage(bytes), width: 240),
  ],
  categoryId: entry.categoryId,
  tags: entry.tags,
  usedCount: entry.usedCount,
  lastUsed: entry.lastUsedAt,
  createdAt: entry.createdAt,
  fileName: entry.filePath == null ? null : p.basename(entry.filePath!),
);

RefsEntry mapPreciseEntry(
  PreciseRefLibraryEntry entry, {
  ImageProvider? thumb,
  bool inGeneration = false,
  Size? imageSize,
}) => RefsEntry(
  key: entry.id,
  name: entry.name,
  thumb: thumb,
  favorite: entry.isFavorite,
  inGeneration: inGeneration,
  strength: entry.strength,
  fidelity: entry.fidelity,
  type: refsPreciseType(entry.type),
  hasRaw: true,
  usedCount: entry.usedCount,
  lastUsed: entry.lastUsedAt,
  createdAt: entry.createdAt,
  fileName: p.basename(entry.imagePath),
  imageSize: imageSize,
  imageFormat: p.extension(entry.imagePath).replaceFirst('.', '').toUpperCase(),
);

List<RefsEntry> filterRefsEntries(List<RefsEntry> entries, RefsFilter filter) {
  final query = filter.query.trim().toLowerCase();
  final result = entries.where((e) {
    if (query.isNotEmpty &&
        !e.name.toLowerCase().contains(query) &&
        !e.tags.any((tag) => tag.toLowerCase().contains(query))) {
      return false;
    }
    if (filter.categoryId != null &&
        (e.categoryId ?? '') != filter.categoryId) {
      return false;
    }
    if (filter.source != null && e.source != filter.source) return false;
    if (filter.type != null && e.type != filter.type) return false;
    final view = switch (filter.view) {
      RefsView.all => true,
      RefsView.favorites => e.favorite,
      RefsView.recent => e.lastUsed != null,
      RefsView.inGeneration => e.inGeneration,
    };
    final quick = switch (filter.quick) {
      RefsQuick.all => true,
      RefsQuick.favorites => e.favorite,
      RefsQuick.hasRaw => e.hasRaw == true,
      RefsQuick.needsEncoding =>
        e.encoding == RefsEncoding.encodeOnUse ||
            e.encoding == RefsEncoding.reencode,
      RefsQuick.bundles => e.isBundle,
      RefsQuick.unused => e.usedCount == 0,
    };
    return view && quick;
  }).toList();
  result.sort((a, b) {
    if (filter.sort == RefsSort.lastUsed) {
      if (a.lastUsed == null && b.lastUsed != null) return 1;
      if (b.lastUsed == null && a.lastUsed != null) return -1;
    }
    final order = switch (filter.sort) {
      RefsSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      RefsSort.usedCount => a.usedCount.compareTo(b.usedCount),
      RefsSort.createdAt => (a.createdAt ?? DateTime(0)).compareTo(
        b.createdAt ?? DateTime(0),
      ),
      RefsSort.lastUsed => (a.lastUsed ?? DateTime(0)).compareTo(
        b.lastUsed ?? DateTime(0),
      ),
    };
    return order == 0
        ? a.key.compareTo(b.key)
        : filter.descending
        ? -order
        : order;
  });
  return result;
}

RefsCounts refsCounts(List<RefsEntry> entries) => RefsCounts(
  all: entries.length,
  favorites: entries.where((e) => e.favorite).length,
  inGeneration: entries.where((e) => e.inGeneration).length,
  uncategorized: entries.where((e) => e.categoryId == null).length,
  needsEncoding: entries
      .where(
        (e) =>
            e.encoding == RefsEncoding.encodeOnUse ||
            e.encoding == RefsEncoding.reencode,
      )
      .length,
  sources: {
    for (final source in RefsVibeSource.values)
      source: entries.where((e) => e.source == source).length,
  },
  types: {
    for (final type in RefsPreciseType.values)
      type: entries.where((e) => e.type == type).length,
  },
);

List<RefsCategory> refsCategories(
  List<VibeLibraryCategory> categories,
  List<RefsEntry> entries,
) {
  final result = <RefsCategory>[];
  final seen = <String>{};
  void visit(VibeLibraryCategory category) {
    if (!seen.add(category.id)) return;
    result.add(
      RefsCategory(
        id: category.id,
        name: category.name,
        parentId: category.parentId,
        count: entries.where((e) => e.categoryId == category.id).length,
      ),
    );
    final children = categories.where((c) => c.parentId == category.id).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final child in children) {
      visit(child);
    }
  }

  final roots = categories.where((c) => c.parentId == null).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  for (final root in roots) {
    visit(root);
  }
  for (final category in categories) {
    visit(category);
  }
  return result;
}

List<VibeReference> refsBundleVibes(VibeLibraryEntry entry) => [
  for (var i = 0; i < entry.bundledVibeCount; i++)
    VibeReference(
      displayName: entry.bundledVibeNames![i],
      vibeEncoding: i < (entry.bundledVibeEncodings?.length ?? 0)
          ? entry.bundledVibeEncodings![i]
          : '',
      thumbnail: i < (entry.bundledVibePreviews?.length ?? 0)
          ? entry.bundledVibePreviews![i]
          : null,
      strength: i < (entry.bundledVibeStrengths?.length ?? 0)
          ? entry.bundledVibeStrengths![i]
          : entry.strength,
      infoExtracted: i < (entry.bundledVibeInfoExtracted?.length ?? 0)
          ? entry.bundledVibeInfoExtracted![i]
          : entry.infoExtracted,
      encodingModel: i < (entry.bundledVibeEncodingModels?.length ?? 0)
          ? entry.bundledVibeEncodingModels![i]
          : entry.encodingModel,
      sourceType: VibeSourceType.naiv4vibebundle,
      bundleSource: entry.displayName,
    ),
];

VibeReference refsVibeOverride(VibeReference vibe, RefsSendOverride? value) {
  if (value == null) return vibe;
  final info = VibeReference.sanitizeInfoExtracted(value.infoExtracted);
  final invalidate =
      info != vibe.infoExtracted && vibe.canReencodeFromRawSource;
  return vibe.copyWith(
    strength: VibeReference.sanitizeStrength(value.strength),
    infoExtracted: info,
    vibeEncoding: invalidate ? '' : vibe.vibeEncoding,
    encodingModel: invalidate ? null : vibe.encodingModel,
  );
}

class RefsLazyImage extends ImageProvider<RefsLazyImage> {
  const RefsLazyImage(this.owner, this.id, this.revision, this.readBytes);
  final Object owner;
  final String id;
  final Object? revision;
  final Future<Uint8List?> Function() readBytes;

  @override
  Future<RefsLazyImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    RefsLazyImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await readBytes();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Reference image unavailable');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is RefsLazyImage &&
      identical(owner, other.owner) &&
      id == other.id &&
      revision == other.revision;
  @override
  int get hashCode => Object.hash(identityHashCode(owner), id, revision);
}

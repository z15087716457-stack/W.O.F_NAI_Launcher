import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_category.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';

class _Writer implements BinaryWriter {
  final tokens = <Object?>[];
  @override
  void writeByte(int byte) => tokens.add(byte);
  @override
  void write<T>(T value, {bool writeTypeId = true}) => tokens.add(value);
  Map<int, Object?> get fields => {
    for (var i = 1; i < tokens.length; i += 2) tokens[i] as int: tokens[i + 1],
  };
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LegacyReader implements BinaryReader {
  _LegacyReader(Map<int, Object?> fields)
    : tokens = [
        fields.length,
        for (final entry in fields.entries) ...[entry.key, entry.value],
      ].iterator;
  final Iterator<Object?> tokens;
  Object? _next() {
    if (!tokens.moveNext()) throw StateError('Unexpected adapter read');
    return tokens.current;
  }

  @override
  int readByte() => _next() as int;
  @override
  dynamic read([int? typeId]) => _next();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final date = DateTime.utc(2025, 1, 1);
  const character = CharacterPromptInfo(
    prompt: 'character',
    negativePrompt: 'negative',
    position: 'left',
    centerX: 0.2,
    centerY: 0.7,
  );
  const metadata = NaiImageMetadata(
    prompt: 'prompt',
    negativePrompt: 'uc',
    seed: 17,
    sampler: 'k_euler',
    steps: 28,
    scale: 5.5,
    width: 832,
    height: 1216,
    model: 'nai-diffusion-5-full',
    smea: true,
    smeaDyn: false,
    noiseSchedule: 'native',
    cfgRescale: 0.1,
    ucPreset: 2,
    qualityToggle: true,
    isImg2Img: true,
    strength: 0.4,
    noise: 0.3,
    software: 'NovelAI',
    version: 'test',
    source: 'fixture',
    characterPrompts: ['character'],
    characterNegativePrompts: ['negative'],
    rawJson: '{"test":true}',
    fixedPrefixTags: ['prefix'],
    fixedSuffixTags: ['suffix'],
    qualityTags: ['quality'],
    characterInfos: [character],
    characterUseCoords: true,
    originalPrompt: 'original',
    varietyPlus: true,
    preciseReferenceImages: ['image'],
    preciseReferenceTypes: ['character'],
    preciseReferenceStrengths: [0.8],
    preciseReferenceFidelities: [0.9],
    fixedNegativePrefixTags: ['uc prefix'],
    fixedNegativeSuffixTags: ['uc suffix'],
    qualityTagHint: 1,
    ucPresetTagHint: 2,
  );
  final category = VibeLibraryCategory(
    id: 'category',
    name: 'name',
    parentId: 'parent',
    sortOrder: 3,
    createdAt: date,
  );
  final local = LocalImageRecord(
    path: 'fixture.png',
    size: 23,
    modifiedAt: date,
    metadata: metadata,
    metadataStatus: MetadataStatus.success,
    isFavorite: true,
    tags: ['tag'],
    hasVibeMetadata: true,
    anlasCost: 4,
  );
  final vibe = VibeLibraryEntry(
    id: 'vibe',
    name: 'name',
    vibeDisplayName: 'display',
    vibeEncoding: 'encoded',
    vibeThumbnail: Uint8List.fromList([1, 2]),
    rawImageData: Uint8List.fromList([3]),
    strength: 0.6,
    infoExtracted: 0.7,
    sourceTypeIndex: 3,
    categoryId: 'category',
    tags: ['tag'],
    isFavorite: true,
    usedCount: 7,
    lastUsedAt: date,
    createdAt: date,
    thumbnail: Uint8List.fromList([4]),
    filePath: 'fixture.naiv4vibe',
    bundleId: 'bundle',
    bundledVibeNames: ['name'],
    bundledVibePreviews: [
      Uint8List.fromList([5]),
    ],
    bundledVibeEncodings: ['encoded'],
    bundledVibeStrengths: [0.6],
    bundledVibeInfoExtracted: [0.7],
    encodingModel: 'nai-diffusion-5-full',
    bundledVibeEncodingModels: ['nai-diffusion-5-full', null],
  );
  final precise = PreciseRefLibraryEntry(
    id: 'precise',
    name: 'name',
    imagePath: 'fixture.png',
    typeIndex: 2,
    strength: 0.8,
    fidelity: 0.9,
    isFavorite: true,
    usedCount: 3,
    lastUsedAt: date,
    createdAt: date,
  );

  void verify<T>(
    String name,
    TypeAdapter<T> adapter,
    int typeId,
    T value,
    Map<int, Object?> legacyFields,
  ) {
    test('$name retains its Hive type and field numbers', () {
      expect(adapter.typeId, typeId);
      final writer = _Writer();
      adapter.write(writer, value);
      expect(writer.tokens.first, legacyFields.length);
      expect(writer.fields, legacyFields);
    });
    test('$name reads the existing Hive field layout', () {
      expect(adapter.read(_LegacyReader(legacyFields)), value);
    });
  }

  verify('category', VibeLibraryCategoryAdapter(), 21, category, {
    0: 'category',
    1: 'name',
    2: 'parent',
    3: 3,
    4: date,
  });
  verify('local image', LocalImageRecordAdapter(), 22, local, {
    0: 'fixture.png',
    1: 23,
    2: date,
    3: metadata,
    4: MetadataStatus.success,
    5: true,
    6: ['tag'],
    7: null,
    8: true,
    9: 4,
  });
  verify('vibe', VibeLibraryEntryAdapter(), 23, vibe, {
    0: 'vibe',
    1: 'name',
    2: 'display',
    3: 'encoded',
    4: vibe.vibeThumbnail,
    5: vibe.rawImageData,
    6: 0.6,
    7: 0.7,
    8: 3,
    9: 'category',
    10: ['tag'],
    11: true,
    12: 7,
    13: date,
    14: date,
    15: vibe.thumbnail,
    16: 'fixture.naiv4vibe',
    17: 'bundle',
    18: ['name'],
    19: vibe.bundledVibePreviews,
    20: ['encoded'],
    21: [0.6],
    22: [0.7],
    23: 'nai-diffusion-5-full',
    24: ['nai-diffusion-5-full', null],
  });
  verify('metadata', NaiImageMetadataAdapter(), 24, metadata, {
    0: 'prompt',
    1: 'uc',
    2: 17,
    3: 'k_euler',
    4: 28,
    5: 5.5,
    6: 832,
    7: 1216,
    8: 'nai-diffusion-5-full',
    9: true,
    10: false,
    11: 'native',
    12: 0.1,
    13: 2,
    14: true,
    15: true,
    16: 0.4,
    17: 0.3,
    18: 'NovelAI',
    19: 'test',
    20: 'fixture',
    21: ['character'],
    22: ['negative'],
    23: '{"test":true}',
    24: ['prefix'],
    25: ['suffix'],
    26: ['quality'],
    27: [character],
    37: true,
    28: metadata.vibeReferences,
    29: 'original',
    30: true,
    31: ['image'],
    32: ['character'],
    33: [0.8],
    34: [0.9],
    35: ['uc prefix'],
    36: ['uc suffix'],
    38: 1,
    39: 2,
  });
  verify('character', CharacterPromptInfoAdapter(), 25, character, {
    0: 'character',
    1: 'negative',
    2: 'left',
    3: 0.2,
    4: 0.7,
  });
  verify('precise reference', PreciseRefLibraryEntryAdapter(), 26, precise, {
    0: 'precise',
    1: 'name',
    2: 'fixture.png',
    3: 2,
    4: 0.8,
    5: 0.9,
    6: true,
    7: 3,
    8: date,
    9: date,
  });
}

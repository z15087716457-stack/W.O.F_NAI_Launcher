import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/wiring/refs_mapping.dart';
import 'package:nai_launcher/presentation/wiring/refs_preferences.dart';

class MemorySettings extends LocalStorageService {
  final values = <String, Object?>{};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values.containsKey(key) ? values[key] as T? : defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

VibeLibraryEntry entry({
  String key = 'a',
  String encoding = 'encoded',
  String? model = ImageModels.animeDiffusionV45Full,
  Uint8List? raw,
  VibeSourceType source = VibeSourceType.naiv4vibe,
}) => VibeLibraryEntry(
  id: key,
  name: key,
  vibeDisplayName: key,
  vibeEncoding: encoding,
  rawImageData: raw,
  encodingModel: model,
  sourceTypeIndex: source.index,
  createdAt: DateTime(2026),
);

void main() {
  const current = ImageModels.animeDiffusionV45Full;
  test('encoding states use metadata rather than stripped display entries', () {
    final cases = [
      (entry(), RefsEncoding.ready),
      (
        entry(encoding: '', raw: Uint8List.fromList([1])),
        RefsEncoding.encodeOnUse,
      ),
      (
        entry(
          model: ImageModels.animeDiffusionV4Full,
          raw: Uint8List.fromList([1]),
        ),
        RefsEncoding.reencode,
      ),
      (entry(model: ImageModels.animeDiffusionV4Full), RefsEncoding.unusable),
      (entry(model: null), RefsEncoding.unknown),
    ];
    for (final (value, expected) in cases) {
      final status = RefsVibeStatus.fromEntry(value);
      expect(status.encoding(current), expected);
      expect(
        mapVibeEntry(
          value.toDisplayEntry(),
          model: current,
          status: status,
        ).encoding,
        expected,
      );
    }
  });

  test('model capabilities come from model specs including V5', () {
    final v5 = refsModel(ImageModels.animeDiffusionV5Full);
    expect(v5.vibeUsable, isFalse);
    expect(v5.preciseUsable, isFalse);
    expect(v5.switchTarget, isNotNull);
    expect(refsModel(current).preciseUsable, isTrue);
  });

  test('whole-library counts remain independent of filtering', () {
    final entries = [
      const RefsEntry(
        key: 'a',
        name: 'sky',
        favorite: true,
        inGeneration: true,
        encoding: RefsEncoding.reencode,
      ),
      const RefsEntry(key: 'b', name: 'sea', hasRaw: true),
    ];
    expect(
      filterRefsEntries(
        entries,
        const RefsFilter(view: RefsView.favorites),
      ).map((e) => e.key),
      ['a'],
    );
    final counts = refsCounts(entries);
    expect(counts.all, 2);
    expect(counts.favorites, 1);
    expect(counts.inGeneration, 1);
    expect(counts.needsEncoding, 1);
  });

  test(
    'search matches display names and tags without changing the source list',
    () {
      final entries = [
        const RefsEntry(key: 'a', name: 'A', tags: ['Night Sky']),
        const RefsEntry(key: 'b', name: 'B'),
      ];
      expect(
        filterRefsEntries(entries, const RefsFilter(query: 'SKY')).single.key,
        'a',
      );
      expect(entries.length, 2);
    },
  );

  test('uncategorized and typed filters retain their distinct meanings', () {
    final entries = [
      const RefsEntry(key: 'a', name: 'A', type: RefsPreciseType.character),
      const RefsEntry(key: 'b', name: 'B', categoryId: 'cat'),
    ];
    expect(
      filterRefsEntries(entries, const RefsFilter(categoryId: '')).single.key,
      'a',
    );
    expect(
      filterRefsEntries(
        entries,
        const RefsFilter(type: RefsPreciseType.both),
      ).single.key,
      'b',
    );
  });

  test(
    'recent view excludes never-used entries and last-used sort keeps them last',
    () {
      final entries = [
        const RefsEntry(key: 'a', name: 'A'),
        RefsEntry(key: 'b', name: 'B', lastUsed: DateTime(2026)),
      ];
      expect(
        filterRefsEntries(
          entries,
          const RefsFilter(view: RefsView.recent),
        ).single.key,
        'b',
      );
      expect(
        filterRefsEntries(
          entries,
          const RefsFilter(descending: false),
        ).last.key,
        'a',
      );
    },
  );

  test(
    'temporary information-extraction override invalidates old encoding only when raw exists',
    () {
      final raw = entry(raw: Uint8List.fromList([1])).toVibeReference();
      const override = RefsSendOverride(strength: .9, infoExtracted: .2);
      final adjusted = refsVibeOverride(raw, override);
      expect(adjusted.vibeEncoding, isEmpty);
      expect(adjusted.encodingModel, isNull);
      expect(adjusted.strength, .9);
      expect(raw.vibeEncoding, 'encoded');
      expect(
        refsVibeOverride(entry().toVibeReference(), override).vibeEncoding,
        'encoded',
      );
    },
  );

  test('fingerprints distinguish same-name different content', () {
    final a = entry(raw: Uint8List.fromList([1])).toVibeReference();
    final b = entry(raw: Uint8List.fromList([2])).toVibeReference();
    expect(refsVibeFingerprint(a), isNot(refsVibeFingerprint(b)));
    expect(
      refsVibeFingerprint(a.copyWith(strength: .4)),
      refsVibeFingerprint(a),
    );
  });

  test(
    'new preferences survive recreation and remain separate for each library',
    () async {
      final storage = MemorySettings();
      final vibe = RefsPreferenceStore(storage, RefsKind.vibe);
      await vibe.saveFilter(
        const RefsFilter(
          view: RefsView.favorites,
          quick: RefsQuick.hasRaw,
          sort: RefsSort.name,
          descending: false,
          query: 'not persisted',
          categoryId: 'not persisted',
        ),
      );
      await vibe.saveCardSize(RefsCardSize.large);
      await vibe.saveSidebar(false);
      await vibe.saveInspector(false);
      final restored = RefsPreferenceStore(storage, RefsKind.vibe).read();
      expect(restored.filter.view, RefsView.favorites);
      expect(restored.filter.quick, RefsQuick.hasRaw);
      expect(restored.filter.sort, RefsSort.name);
      expect(restored.filter.descending, isFalse);
      expect(restored.filter.query, isEmpty);
      expect(restored.filter.categoryId, isNull);
      expect(restored.cardSize, RefsCardSize.large);
      expect(restored.sidebarOpen, isFalse);
      expect(restored.inspectorOpen, isFalse);
      expect(
        RefsPreferenceStore(storage, RefsKind.precise).read().cardSize,
        RefsCardSize.medium,
      );
    },
  );

  test('corrupt preference values fall back without breaking the page', () {
    final storage = MemorySettings();
    storage.values['refs_vibe_filter'] = '{broken';
    storage.values['refs_vibe_card_size'] = 'unknown';
    storage.values['refs_vibe_sidebar_open'] = 'wrong type';
    final restored = RefsPreferenceStore(storage, RefsKind.vibe).read();
    expect(restored.filter, const RefsFilter());
    expect(restored.cardSize, RefsCardSize.medium);
    expect(restored.sidebarOpen, isTrue);
  });
}

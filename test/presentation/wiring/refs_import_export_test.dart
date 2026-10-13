import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/utils/novelai_vibe_codec.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/vibe_import_service.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/utils/dropped_file_reader.dart';
import 'package:nai_launcher/presentation/wiring/refs_import_session.dart';
import 'package:nai_launcher/presentation/wiring/refs_exporter.dart';

class Repository implements VibeLibraryImportRepository {
  final entries = <VibeLibraryEntry>[];
  final bundleContents = <List<VibeReference>>[];
  @override
  Future<List<VibeLibraryEntry>> getAllEntries() async => entries;
  @override
  Future<VibeLibraryEntry?> findEntryByName(String name) async => entries
      .where((e) => e.name.toLowerCase() == name.toLowerCase())
      .firstOrNull;
  @override
  Future<VibeLibraryEntry> saveEntry(VibeLibraryEntry entry) async {
    entries.removeWhere((e) => e.id == entry.id);
    entries.add(entry);
    return entry;
  }

  @override
  Future<VibeLibraryEntry> saveBundleEntry(
    List<VibeReference> vibes, {
    required String name,
    String? categoryId,
    List<String>? tags,
    VibeLibraryEntry? replaceEntry,
  }) async {
    bundleContents.add(vibes);
    var entry =
        VibeLibraryEntry.fromVibeReference(
          name: name,
          vibeData: vibes.first,
          categoryId: categoryId,
          tags: tags,
        ).copyWith(
          bundledVibeNames: vibes.map((v) => v.displayName).toList(),
          bundledVibeEncodings: vibes.map((v) => v.vibeEncoding).toList(),
        );
    if (replaceEntry != null) entry = entry.copyWith(id: replaceEntry.id);
    return saveEntry(entry);
  }
}

const model = ImageModels.animeDiffusionV45Full;
VibeReference vibe(String name) => VibeReference(
  displayName: name,
  vibeEncoding: base64Encode(utf8.encode(name)),
  encodingModel: model,
  sourceType: VibeSourceType.naiv4vibe,
);
DroppedFileData file(
  String name,
  List<VibeReference> vibes, {
  bool bundle = false,
}) => DroppedFileData(
  fileName: '$name.${bundle ? 'naiv4vibebundle' : 'naiv4vibe'}',
  bytes: Uint8List.fromList(
    utf8.encode(
      jsonEncode(
        bundle
            ? NovelAiVibeCodec.buildBundleMap(vibes)
            : NovelAiVibeCodec.buildSingleMap(vibes.single),
      ),
    ),
  ),
);

void main() {
  test(
    'file recognition creates a draft without writing to the library',
    () async {
      final session = await RefsImportSession.prepare(
        [
          file('a', [vibe('A')]),
          file('pack', [vibe('A'), vibe('B')], bundle: true),
        ],
        model: model,
        names: {'a'},
      );
      expect(session.draft.rows.map((r) => r.kind), [
        RefsImportKind.vibeFile,
        RefsImportKind.bundle,
      ]);
      expect(session.draft.rows.first.duplicate, isTrue);
      expect(session.draft.rows.last.bundle, hasLength(2));
      expect(session.draft.rows.first.encodedForCurrent, isTrue);
    },
  );

  for (final mode in RefsBundleImport.values) {
    test(
      'bundle $mode imports the requested children and category/tags',
      () async {
        final session = await RefsImportSession.prepare([
          file('pack', [vibe('A'), vibe('B')], bundle: true),
        ], model: model);
        final repository = Repository();
        final result = await session.execute(
          RefsImportPlan(
            rows: [
              RefsImportRowPlan(
                id: session.draft.rows.single.id,
                name: 'renamed',
                bundle: mode,
                picked: const [1],
              ),
            ],
            categoryId: 'category',
            tags: const ['tag'],
          ),
          VibeImportService(repository: repository),
          alive: () => true,
        );
        expect(result.failed, 0);
        expect(
          repository.entries.length,
          mode == RefsBundleImport.split ? 2 : 1,
        );
        expect(
          repository.entries.every(
            (e) => e.categoryId == 'category' && e.tags.single == 'tag',
          ),
          isTrue,
        );
        if (mode == RefsBundleImport.whole) {
          expect(repository.bundleContents.single.map((v) => v.displayName), [
            'A',
            'B',
          ]);
        }
        if (mode == RefsBundleImport.pick) {
          expect(repository.entries.single.vibeDisplayName, 'B');
        }
      },
    );
  }

  for (final duplicate in RefsDuplicate.values) {
    test('duplicate $duplicate uses the selected conflict policy', () async {
      final session = await RefsImportSession.prepare(
        [
          file('a', [vibe('new')]),
        ],
        model: model,
        names: {'a'},
      );
      final repository = Repository();
      final old = VibeLibraryEntry.fromVibeReference(
        name: 'a',
        vibeData: vibe('old'),
      );
      repository.entries.add(old);
      await session.execute(
        RefsImportPlan(
          rows: [
            RefsImportRowPlan(
              id: session.draft.rows.single.id,
              name: 'a',
              duplicate: duplicate,
            ),
          ],
        ),
        VibeImportService(repository: repository),
        alive: () => true,
      );
      expect(
        repository.entries.length,
        duplicate == RefsDuplicate.keepBoth ? 2 : 1,
      );
      if (duplicate == RefsDuplicate.skip) {
        expect(repository.entries.single.vibeDisplayName, 'old');
      }
      if (duplicate == RefsDuplicate.overwrite) {
        expect(repository.entries.single.id, old.id);
        expect(repository.entries.single.vibeDisplayName, 'new');
      }
    });
  }

  test(
    'adding the same filename to a draft preserves the original source identity',
    () async {
      final first = await RefsImportSession.prepare([
        file('same', [vibe('original')]),
      ], model: model);
      final second = await RefsImportSession.prepare([
        file('same', [vibe('new')]),
      ], model: model);
      final merged = RefsImportSession(
        RefsImportDraft(rows: [...first.draft.rows, ...second.draft.rows]),
        {...first.sources, ...second.sources},
      );
      expect(first.draft.rows.single.id, isNot(second.draft.rows.single.id));
      expect(
        merged
            .references(
              RefsImportRowPlan(id: first.draft.rows.single.id, name: 'same'),
            )
            .single
            .displayName,
        'original',
      );
    },
  );

  test(
    'skipping a duplicate raw image never calls the encoding operation',
    () async {
      final session = RefsImportSession(
        const RefsImportDraft(
          rows: [
            RefsImportRow(
              id: 'raw',
              name: 'a',
              ext: '.png',
              kind: RefsImportKind.image,
              duplicate: true,
            ),
          ],
        ),
        {
          'raw': [
            vibe(
              'new',
            ).copyWith(vibeEncoding: '', rawImageData: Uint8List.fromList([1])),
          ],
        },
      );
      final repository = Repository()
        ..entries.add(
          VibeLibraryEntry.fromVibeReference(name: 'a', vibeData: vibe('old')),
        );
      var encoded = 0;
      await session.execute(
        const RefsImportPlan(
          rows: [
            RefsImportRowPlan(
              id: 'raw',
              name: 'a',
              duplicate: RefsDuplicate.skip,
            ),
          ],
          encodeNow: true,
        ),
        VibeImportService(repository: repository),
        alive: () => true,
        encode: (value) async {
          encoded++;
          return value.copyWith(vibeEncoding: 'encoded', encodingModel: model);
        },
      );
      expect(encoded, 0);
      expect(repository.entries.single.vibeDisplayName, 'old');
    },
  );

  test(
    'split bundle duplicate skip excludes the existing child before encoding and costing',
    () async {
      VibeReference raw(String name) => VibeReference(
        displayName: name,
        vibeEncoding: '',
        rawImageData: Uint8List.fromList([name.codeUnitAt(0)]),
      );
      final session = RefsImportSession(
        const RefsImportDraft(
          rows: [
            RefsImportRow(
              id: 'pack',
              name: 'pack',
              ext: '.naiv4vibebundle',
              kind: RefsImportKind.bundle,
              bundle: [
                RefsBundleChild(name: 'A'),
                RefsBundleChild(name: 'B'),
              ],
            ),
          ],
        ),
        {
          'pack': [raw('A'), raw('B')],
        },
      );
      final repository = Repository()
        ..entries.add(
          VibeLibraryEntry.fromVibeReference(
            name: 'pack - A',
            vibeData: vibe('old'),
          ),
        );
      const plan = RefsImportPlan(
        rows: [
          RefsImportRowPlan(
            id: 'pack',
            name: 'pack',
            bundle: RefsBundleImport.split,
            duplicate: RefsDuplicate.skip,
          ),
        ],
        encodeNow: true,
      );
      final importer = VibeImportService(repository: repository);
      final resolved = await session.resolveSkippedRows(plan, importer);
      expect(session.encodingCount(resolved), 1);
      var calls = 0;
      await session.execute(
        plan,
        importer,
        alive: () => true,
        encode: (value) async {
          calls++;
          return value.copyWith(vibeEncoding: 'encoded', encodingModel: model);
        },
      );
      expect(calls, 1);
      expect(repository.entries.map((entry) => entry.name), [
        'pack - A',
        'pack - B',
      ]);
      expect(repository.entries.first.vibeDisplayName, 'old');
    },
  );

  test('cancelled draft never starts import or paid encoding', () async {
    final session = await RefsImportSession.prepare([
      file('a', [vibe('A')]),
    ], model: model);
    final repository = Repository();
    await session.execute(
      RefsImportPlan(
        rows: [RefsImportRowPlan(id: session.draft.rows.single.id, name: 'a')],
        encodeNow: true,
      ),
      VibeImportService(repository: repository),
      alive: () => false,
      encode: (_) => throw StateError('not authorized'),
    );
    expect(repository.entries, isEmpty);
  });

  test(
    'single and bundle export preserve saved parameters and honor ZIP format',
    () async {
      final entries = [
        for (final name in ['A', 'B'])
          VibeLibraryEntry.fromVibeReference(
            name: name,
            vibeData: vibe(name).copyWith(strength: .3, infoExtracted: .4),
          ),
      ];
      final files = await RefsExporter.build(
        entries,
        const RefsExportPlan(
          keys: ['a', 'b'],
          format: RefsExportFormat.vibeFile,
          folder: '',
        ),
        model: model,
      );
      expect(files, hasLength(2));
      expect(
        (jsonDecode(utf8.decode(files.first.bytes))
            as Map)['importInfo']['strength'],
        .3,
      );
      final bundle = await RefsExporter.build(
        entries,
        const RefsExportPlan(
          keys: ['a', 'b'],
          format: RefsExportFormat.bundle,
          folder: '',
          zip: true,
        ),
        model: model,
      );
      final zip = ZipDecoder().decodeBytes(bundle.single.bytes);
      expect(zip.files.single.name.endsWith('.naiv4vibebundle'), isTrue);
      expect(
        (jsonDecode(utf8.decode(zip.files.single.content as List<int>))
            as Map)['vibes'],
        hasLength(2),
      );
    },
  );

  test(
    'export strips thumbnails without losing raw data or encoding model',
    () async {
      final entry = VibeLibraryEntry.fromVibeReference(
        name: 'A',
        vibeData: vibe('A').copyWith(
          thumbnail: Uint8List.fromList([1, 2]),
          rawImageData: Uint8List.fromList([3, 4]),
        ),
      );
      final output = await RefsExporter.build(
        [entry],
        const RefsExportPlan(
          keys: ['a'],
          format: RefsExportFormat.vibeFile,
          folder: '',
          thumbnails: false,
        ),
        model: model,
      );
      final json = jsonDecode(utf8.decode(output.single.bytes)) as Map;
      expect(json.containsKey('thumbnail'), isFalse);
      expect(json['image'], base64Encode([3, 4]));
      expect(json['importInfo']['model'], model);
    },
  );
}

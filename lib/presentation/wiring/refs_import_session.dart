import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/vibe_file_parser.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../../data/services/vibe_import_service.dart';
import '../ui/refs/refs_contract.dart';
import '../utils/dropped_file_reader.dart';
import 'refs_mapping.dart';

class RefsImportSession {
  RefsImportSession(this.draft, this.sources);
  final RefsImportDraft draft;
  final Map<String, List<VibeReference>> sources;
  static var _nextRowId = 0;

  static Future<RefsImportSession> prepare(
    List<DroppedFileData> files, {
    required String model,
    Set<String> names = const {},
    String? categoryId,
    bool Function()? isCurrent,
  }) async {
    final rows = <RefsImportRow>[];
    final sources = <String, List<VibeReference>>{};
    final reserved = {for (final name in names) name.trim().toLowerCase()};
    for (var i = 0; i < files.length; i++) {
      if (isCurrent?.call() == false) break;
      final file = files[i];
      final vibes = await VibeFileParser.parseFile(file.fileName, file.bytes);
      if (isCurrent?.call() == false) break;
      if (vibes.isEmpty) continue;
      final bundle =
          p.extension(file.fileName).toLowerCase() == '.naiv4vibebundle' ||
          vibes.length > 1;
      final name = p.basenameWithoutExtension(file.fileName);
      final models = vibes.map((v) => v.encodingModel).toSet();
      final thumb = vibes.first.thumbnail;
      final id = '${_nextRowId++}:${file.fileName}';
      sources[id] = vibes;
      rows.add(
        RefsImportRow(
          id: id,
          name: name,
          ext: p.extension(file.fileName),
          kind: bundle
              ? RefsImportKind.bundle
              : vibes.first.sourceType == VibeSourceType.rawImage
              ? RefsImportKind.image
              : vibes.first.sourceType == VibeSourceType.png
              ? RefsImportKind.vibePng
              : RefsImportKind.vibeFile,
          thumb: thumb == null
              ? null
              : ResizeImage(MemoryImage(thumb), width: 240),
          encodedFor: models.length == 1 && models.single != null
              ? refsShortModel(models.single!)
              : null,
          encodedForCurrent: vibes.every(
            (v) =>
                !v.hasVibeEncoding ||
                v.encodingModel == null ||
                v.encodingModel == model,
          ),
          duplicate: reserved.contains(name.trim().toLowerCase()),
          bundle: bundle
              ? [
                  for (final v in vibes)
                    RefsBundleChild(
                      name: v.displayName,
                      thumb: v.thumbnail == null
                          ? null
                          : ResizeImage(MemoryImage(v.thumbnail!), width: 240),
                      strength: v.strength,
                      infoExtracted: v.infoExtracted,
                    ),
                ]
              : const [],
        ),
      );
      reserved.add(name.trim().toLowerCase());
    }
    return RefsImportSession(
      RefsImportDraft(rows: rows, categoryId: categoryId),
      sources,
    );
  }

  List<VibeReference> references(RefsImportRowPlan row) {
    final all = sources[row.id];
    if (all == null) throw StateError(currentL10n.bridge_conflict);
    return row.bundle == RefsBundleImport.pick
        ? [
            for (final i in row.picked.toSet())
              if (i >= 0 && i < all.length) all[i],
          ]
        : all;
  }

  Future<RefsImportPlan> resolveSkippedRows(
    RefsImportPlan plan,
    VibeImportService importer,
  ) async {
    final rows = <RefsImportRowPlan>[];
    for (final row in plan.rows) {
      if (row.duplicate != RefsDuplicate.skip) {
        rows.add(row);
        continue;
      }
      final source = draft.rows.where((source) => source.id == row.id).first;
      if (source.kind != RefsImportKind.bundle ||
          row.bundle == RefsBundleImport.whole) {
        if (!await importer.hasEntryNamed(row.name)) rows.add(row);
        continue;
      }
      final all = sources[row.id]!;
      final indexes = row.bundle == RefsBundleImport.pick
          ? row.picked.toSet()
          : List.generate(all.length, (i) => i);
      final keep = <int>[];
      for (final index in indexes) {
        if (index >= 0 &&
            index < all.length &&
            !await importer.hasEntryNamed(
              '${row.name} - ${all[index].displayName}',
            )) {
          keep.add(index);
        }
      }
      if (keep.isNotEmpty) {
        rows.add(
          RefsImportRowPlan(
            id: row.id,
            name: row.name,
            duplicate: row.duplicate,
            bundle: RefsBundleImport.pick,
            picked: keep,
          ),
        );
      }
    }
    return RefsImportPlan(
      rows: rows,
      categoryId: plan.categoryId?.isEmpty == true ? null : plan.categoryId,
      tags: plan.tags,
      encodeNow: plan.encodeNow,
    );
  }

  int encodingCount(RefsImportPlan plan) => !plan.encodeNow
      ? 0
      : [
          for (final row in plan.rows) ...references(row),
        ].where((v) => !v.hasVibeEncoding && v.canReencodeFromRawSource).length;

  Future<({int success, int failed})> execute(
    RefsImportPlan plan,
    VibeImportService importer, {
    required bool Function() alive,
    Future<VibeReference> Function(VibeReference)? encode,
  }) async {
    var success = 0;
    var failed = 0;
    for (final original in plan.rows) {
      if (!alive()) break;
      final resolved = await resolveSkippedRows(
        RefsImportPlan(rows: [original], encodeNow: plan.encodeNow),
        importer,
      );
      if (resolved.rows.isEmpty) continue;
      final row = resolved.rows.single;
      if (!alive()) break;
      var vibes = references(row);
      if (plan.encodeNow &&
          vibes.any((v) => !v.hasVibeEncoding && v.canReencodeFromRawSource) &&
          encode == null) {
        throw StateError(currentL10n.vibe_import_confirmCost);
      }
      if (plan.encodeNow && encode != null) {
        vibes = [
          for (final v in vibes)
            !v.hasVibeEncoding && v.canReencodeFromRawSource
                ? await encode(v)
                : v,
        ];
      }
      if (!alive()) break;
      final source = draft.rows.where((r) => r.id == row.id).first;
      final result = await importer.importPrepared(
        name: row.name,
        references: vibes,
        bundle:
            source.kind == RefsImportKind.bundle &&
            row.bundle == RefsBundleImport.whole,
        splitNames:
            source.kind == RefsImportKind.bundle &&
            row.bundle != RefsBundleImport.whole,
        categoryId: plan.categoryId?.isEmpty == true ? null : plan.categoryId,
        tags: plan.tags,
        conflictResolution: switch (row.duplicate) {
          RefsDuplicate.keepBoth => ConflictResolution.rename,
          RefsDuplicate.overwrite => ConflictResolution.replace,
          RefsDuplicate.skip => ConflictResolution.skip,
        },
      );
      success += result.successCount;
      failed += result.failCount;
    }
    return (success: success, failed: failed);
  }
}

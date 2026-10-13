import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/file_name_sanitizer.dart';
import '../../core/utils/novelai_vibe_codec.dart';
import '../../core/utils/vibe_export_utils.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/models/vibe/vibe_library_entry.dart';
import '../../data/models/vibe/vibe_reference.dart';
import '../../data/services/vibe_file_storage_service.dart';
import '../ui/refs/refs_contract.dart';
import 'refs_mapping.dart';

class RefsExportFile {
  const RefsExportFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class RefsExporter {
  const RefsExporter._();

  static Future<List<VibeReference>> _vibes(VibeLibraryEntry entry) async {
    if (!entry.isBundle) return [entry.toVibeReference()];
    if (entry.filePath == null) return refsBundleVibes(entry);
    final vibes = await VibeFileStorageService().extractVibesFromBundle(
      entry.filePath!,
    );
    if (vibes.isEmpty) {
      throw StateError(currentL10n.vibeLibrary_bundleReadFailed);
    }
    return vibes;
  }

  static Future<List<RefsExportFile>> build(
    List<VibeLibraryEntry> entries,
    RefsExportPlan plan, {
    required String model,
  }) async {
    if (entries.isEmpty) {
      throw StateError(currentL10n.vibeExport_nothingToExport);
    }
    final files = <RefsExportFile>[];
    final names = <String>{};
    String unique(String name, String extension) {
      final base = FileNameSanitizer.sanitize(
        name,
        fallback: 'vibe',
        maxLength: 80,
      );
      var result = '$base.$extension';
      for (var i = 2; !names.add(result.toLowerCase()); i++) {
        result = '$base ($i).$extension';
      }
      return result;
    }

    RefsExportFile jsonFile(String name, String extension, Object json) =>
        RefsExportFile(
          unique(name, extension),
          Uint8List.fromList(
            utf8.encode(const JsonEncoder.withIndent('  ').convert(json)),
          ),
        );
    if (plan.format == RefsExportFormat.bundle) {
      final vibes = <VibeReference>[];
      for (final entry in entries) {
        vibes.addAll(await _vibes(entry));
      }
      files.add(
        jsonFile(
          entries.length == 1 ? entries.single.name : 'vibe-bundle',
          'naiv4vibebundle',
          NovelAiVibeCodec.buildBundleMap(
            vibes,
            fallbackModel: model,
            includeThumbnails: plan.thumbnails,
          ),
        ),
      );
    } else {
      for (final entry in entries) {
        final vibes = await _vibes(entry);
        switch (plan.format) {
          case RefsExportFormat.vibeFile:
            Map<String, dynamic>? original;
            if (entry.filePath != null) {
              final decoded = jsonDecode(
                await File(entry.filePath!).readAsString(),
              );
              if (decoded is Map<String, dynamic>) original = decoded;
            }
            final json =
                original ??
                (entry.isBundle
                    ? NovelAiVibeCodec.buildBundleMap(
                        vibes,
                        fallbackModel: model,
                        includeThumbnails: plan.thumbnails,
                      )
                    : NovelAiVibeCodec.buildSingleMap(
                        vibes.single,
                        name: entry.name,
                        fallbackModel: model,
                        includeThumbnail: plan.thumbnails,
                      ));
            if (!plan.thumbnails) {
              json.remove('thumbnail');
              final children = json['vibes'];
              if (children is List) {
                for (final child in children.whereType<Map>()) {
                  child.remove('thumbnail');
                }
              }
            }
            files.add(
              jsonFile(
                entry.name,
                entry.isBundle ? 'naiv4vibebundle' : 'naiv4vibe',
                json,
              ),
            );
          case RefsExportFormat.png:
            final carrier = VibeExportUtils.selectDefaultImageCandidate(entry);
            if (carrier == null) {
              throw StateError(currentL10n.preciseRefLib_imageMissing);
            }
            final configured = plan.thumbnails
                ? vibes
                : [for (final v in vibes) v.copyWith(thumbnail: null)];
            files.add(
              RefsExportFile(
                unique(entry.name, 'png'),
                await VibeExportUtils.buildEmbeddedPngBytes(
                  vibes: configured,
                  carrierImageBytes: carrier.bytes,
                  defaultModel: model,
                ),
              ),
            );
          case RefsExportFormat.encoded:
            if (vibes.any((v) => !v.hasVibeEncoding)) {
              throw StateError(currentL10n.vibeExport_nothingToExport);
            }
            files.add(
              jsonFile(entry.name, 'json', {
                'vibes': [
                  for (final v in vibes)
                    {
                      'name': v.displayName,
                      'encoding': v.vibeEncoding,
                      'model': v.encodingModel,
                      'strength': v.strength,
                      'information_extracted': v.infoExtracted,
                    },
                ],
              }),
            );
          case RefsExportFormat.bundle:
            break;
        }
      }
    }
    if (!plan.zip) return files;
    final archive = Archive();
    for (final file in files) {
      archive.addFile(ArchiveFile(file.name, file.bytes.length, file.bytes));
    }
    final zip = ZipEncoder().encode(archive);
    if (zip == null) throw StateError(currentL10n.vibeExport_nothingToExport);
    return [RefsExportFile('vibe-export.zip', Uint8List.fromList(zip))];
  }

  static Future<List<String>> export(
    List<VibeLibraryEntry> entries,
    RefsExportPlan plan, {
    required String model,
  }) async {
    if (plan.folder.trim().isEmpty) {
      throw ArgumentError(currentL10n.vibeExport_nothingToExport);
    }
    final files = await build(entries, plan, model: model);
    final directory = Directory(plan.folder);
    await directory.create(recursive: true);
    final paths = <String>[];
    for (final output in files) {
      var path = p.join(directory.path, output.name);
      for (var i = 2; await File(path).exists(); i++) {
        path = p.join(
          directory.path,
          '${p.basenameWithoutExtension(output.name)} ($i)${p.extension(output.name)}',
        );
      }
      await File(path).writeAsBytes(output.bytes, flush: true);
      paths.add(path);
    }
    return paths;
  }
}

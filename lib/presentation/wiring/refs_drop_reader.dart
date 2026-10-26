import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/services/vibe_drop_import_preprocessor.dart';
import '../ui/refs/refs_contract.dart';
import '../utils/dropped_file_reader.dart';
import 'refs_import_session.dart';

class RefsDropReader {
  const RefsDropReader._();

  static const imageExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
    '.bmp',
  };
  static const vibeExtensions = {'.naiv4vibe', '.naiv4vibebundle'};

  static Future<Uri?> _uri(DataReader reader) {
    if (!reader.canProvide(Formats.fileUri)) return Future.value();
    final result = Completer<Uri?>();
    reader.getValue(
      Formats.fileUri,
      (value) {
        if (!result.isCompleted) result.complete(value);
      },
      onError: (error) {
        if (!result.isCompleted) result.completeError(error);
      },
    );
    return result.future.timeout(
      DroppedFileReader.readTimeout,
      onTimeout: () => null,
    );
  }

  static Future<List<String>> paths(String path, RefsKind kind) async {
    bool supports(String file) =>
        imageExtensions.contains(p.extension(file).toLowerCase()) ||
        (kind == RefsKind.vibe &&
            vibeExtensions.contains(p.extension(file).toLowerCase()));
    if (!await FileSystemEntity.isDirectory(path)) {
      return supports(path) ? [path] : [];
    }
    final result = <String>[];
    await for (final entity in Directory(
      path,
    ).list(recursive: true, followLinks: false)) {
      if (entity is File && supports(entity.path)) result.add(entity.path);
    }
    result.sort();
    return result;
  }

  static Future<List<DroppedFileData>> readPaths(List<String> paths) async {
    final result = await VibeDropImportPreprocessor.collectImageItems(
      paths.toSet().toList(),
    );
    if (result.failedCount +
            result.skippedOversizedCount +
            result.skippedTotalLimitCount >
        0) {
      throw StateError(currentL10n.vibe_import_fileSelectionFailed);
    }
    return [
      for (final item in result.items)
        DroppedFileData(fileName: item.source, bytes: item.bytes),
    ];
  }

  static Future<RefsDropSummary?> summarize(
    List<DroppedFileData> files,
    String model, {
    bool Function()? isCurrent,
  }) async {
    if (files.isEmpty) return null;
    final session = await RefsImportSession.prepare(
      files,
      model: model,
      isCurrent: isCurrent,
    );
    var images = 0, pngs = 0, vibes = 0, bundles = 0;
    for (final row in session.draft.rows) {
      switch (row.kind) {
        case RefsImportKind.image:
          images++;
        case RefsImportKind.vibePng:
          pngs++;
        case RefsImportKind.vibeFile:
          vibes++;
        case RefsImportKind.bundle:
          if (row.ext.toLowerCase() == '.png') {
            pngs++;
          } else {
            bundles++;
          }
      }
    }
    return RefsDropSummary(
      images: images,
      vibePngs: pngs,
      vibeFiles: vibes,
      bundles: bundles,
    );
  }

  static Future<List<DroppedFileData>> read(
    List<DataReader> readers,
    RefsKind kind, {
    bool Function()? isCurrent,
  }) async {
    // Start every native request synchronously, before onPerformDrop returns.
    // Only file IO and parsing may continue after the session is disposed.
    final captured = [
      for (final reader in readers)
        (
          uri: _uri(reader),
          data: DroppedFileReader.capture(
            reader,
            readLocalFiles: false,
            allowVibeFiles: kind == RefsKind.vibe,
            allowRemoteImages: false,
          ),
        ),
    ];
    final futures = [
      for (final source in captured)
        () async {
          final uri = await source.uri;
          if (isCurrent?.call() == false) {
            return (paths: <String>[], data: null as DroppedFileData?);
          }
          if (uri != null && uri.scheme == 'file') {
            return (
              paths: await paths(
                uri.toFilePath(windows: Platform.isWindows),
                kind,
              ),
              data: null as DroppedFileData?,
            );
          }
          return (paths: <String>[], data: await source.data);
        }(),
    ];
    final results = await Future.wait(futures);
    if (isCurrent?.call() == false) return [];
    final local = await readPaths([
      for (final result in results) ...result.paths,
    ]);
    return [
      ...local,
      for (final result in results)
        if (result.data != null) result.data!,
    ];
  }
}

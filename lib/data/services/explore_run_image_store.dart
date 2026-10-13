import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../core/utils/app_logger.dart';
import '../repositories/gallery_folder_repository.dart';

/// 探索 Run 候选图的自包含副本存储。
///
/// 候选图复制到 `<图库根>/style_explore_runs/<runId>/<candidateId>.png`
/// （copy，源图不动——铁律 3）；删 Run 时连带删目录。
class ExploreRunImageStore {
  ExploreRunImageStore({Future<String?> Function()? rootPathResolver})
    : _rootPathResolver =
          rootPathResolver ?? GalleryFolderRepository.instance.getRootPath;

  static const String runsDirectoryName = 'style_explore_runs';

  final Future<String?> Function() _rootPathResolver;

  static void _checkId(String id) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id');
    }
  }

  Future<Map<String, String>> planCandidateDeletion({
    required String runId,
    required String deletionId,
    required Iterable<String> paths,
  }) async {
    _checkId(deletionId);
    final directory = await runDirectory(runId);
    if (directory == null) return {};
    final images = <String, String>{};
    for (final path in paths.toSet()) {
      if (!p.isWithin(p.normalize(directory), p.normalize(path))) continue;
      if (!await File(path).exists()) continue;
      final resolvedDirectory = await Directory(
        directory,
      ).resolveSymbolicLinks();
      final resolvedPath = await File(path).resolveSymbolicLinks();
      if (!p.isWithin(resolvedDirectory, resolvedPath) ||
          !await _managedPath(resolvedPath)) {
        throw StateError('Explore image is outside its run');
      }
      final held = p.join(directory, '.deleted', deletionId, p.basename(path));
      if (images.containsValue(held) || await File(held).exists()) {
        throw StateError('Explore deletion destination already exists');
      }
      images[path] = held;
    }
    return images;
  }

  Future<bool> _managedPath(String path) async {
    final root = await _rootPathResolver();
    if (root == null || root.isEmpty) return false;
    final directory = Directory(p.join(root, runsDirectoryName));
    if (!await directory.exists()) return false;
    final resolved = await directory.resolveSymbolicLinks();
    final resolvedRoot = await Directory(root).resolveSymbolicLinks();
    if (!p.isWithin(resolvedRoot, resolved)) return false;
    final file = File(path);
    var ancestor = file.parent;
    while (!await ancestor.exists()) {
      if (p.equals(ancestor.path, ancestor.parent.path)) return false;
      ancestor = ancestor.parent;
    }
    final target = await file.exists()
        ? await file.resolveSymbolicLinks()
        : p.join(
            await ancestor.resolveSymbolicLinks(),
            p.relative(file.path, from: ancestor.path),
          );
    return p.isWithin(resolved, target);
  }

  Future<void> moveCandidateImages(Map<String, String> images) async {
    try {
      for (final entry in images.entries) {
        if (!await _managedPath(entry.key) ||
            !await _managedPath(entry.value)) {
          throw StateError('Explore image is outside managed storage');
        }
        await File(entry.value).parent.create(recursive: true);
        if (await File(entry.value).exists()) {
          throw StateError('Explore deletion destination already exists');
        }
        await File(entry.key).rename(entry.value);
      }
    } catch (_) {
      await restoreCandidateImages(images);
      rethrow;
    }
  }

  Future<Map<String, String>> holdCandidateImages({
    required String runId,
    required String deletionId,
    required Iterable<String> paths,
  }) async {
    final images = await planCandidateDeletion(
      runId: runId,
      deletionId: deletionId,
      paths: paths,
    );
    await moveCandidateImages(images);
    return images;
  }

  Future<void> restoreCandidateImages(Map<String, String> images) async {
    final pending = <MapEntry<String, String>>[];
    for (final entry in images.entries) {
      if (!await File(entry.value).exists()) {
        if (!await File(entry.key).exists()) {
          throw StateError('Held explore image is missing');
        }
        continue;
      }
      if (!await _managedPath(entry.value) ||
          !await _managedPath(entry.key) ||
          !p.split(entry.value).contains('.deleted')) {
        throw StateError('Explore image is outside managed storage');
      }
      if (await File(entry.key).exists()) {
        throw StateError('Refuse to overwrite a newer explore image');
      }
      pending.add(entry);
    }
    for (final entry in pending) {
      await File(entry.value).rename(entry.key);
    }
  }

  Future<void> discardCandidateImages(Map<String, String> images) async {
    for (final path in images.values) {
      if (!await File(path).exists()) continue;
      if (!p.split(path).contains('.deleted') || !await _managedPath(path)) {
        throw StateError('Explore image is outside managed storage');
      }
      await File(path).delete();
    }
  }

  /// Run 目录路径（图库根不可用时为 null）。
  Future<String?> runDirectory(String runId) async {
    _checkId(runId);
    final root = await _rootPathResolver();
    if (root == null || root.isEmpty) return null;
    return p.join(root, runsDirectoryName, runId);
  }

  /// 把候选图存入 run 目录：源文件在则复制（保留嵌入元数据），
  /// 否则用字节直写。返回副本路径；图库根不可用/写失败时返回 null。
  Future<String?> storeCandidateImage({
    required String runId,
    required String candidateId,
    required Uint8List bytes,
    String? sourceFilePath,
  }) async {
    final dirPath = await runDirectory(runId);
    if (dirPath == null) return null;
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final targetPath = p.join(dirPath, '$candidateId.png');
      final source = sourceFilePath;
      if (source != null && await File(source).exists()) {
        await File(source).copy(targetPath);
      } else {
        await File(targetPath).writeAsBytes(bytes, flush: true);
      }
      return targetPath;
    } catch (error) {
      AppLogger.e(
        'Store explore candidate image failed: $error',
        null,
        null,
        'ExploreRunImageStore',
      );
      return null;
    }
  }

  /// 删除整个 run 目录（删 Run 时连带）；不存在时幂等。
  Future<void> deleteRunDir(String runId) async {
    final dirPath = await runDirectory(runId);
    if (dirPath == null) return;
    try {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (error) {
      AppLogger.w(
        'Delete explore run dir failed: $error',
        'ExploreRunImageStore',
      );
    }
  }

  /// 删除单个候选图副本（候选记录保留，仅清文件）。
  /// 仅允许删 `style_explore_runs/` 目录内的文件——历史数据里 filePath
  /// 可能回退写过源图路径，目录外一律拒删，防误删用户原图。
  /// 文件本就不存在视为成功（幂等），返回是否删成。
  Future<bool> deleteCandidateImage(String filePath) async {
    try {
      final root = await _rootPathResolver();
      if (root == null || root.isEmpty) return false;
      final runsDir = p.normalize(p.join(root, runsDirectoryName));
      if (!p.isWithin(runsDir, p.normalize(filePath))) {
        AppLogger.w(
          'Refuse to delete file outside explore runs dir: $filePath',
          'ExploreRunImageStore',
        );
        return false;
      }
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (error) {
      AppLogger.w(
        'Delete explore candidate image failed: $error',
        'ExploreRunImageStore',
      );
      return false;
    }
  }
}

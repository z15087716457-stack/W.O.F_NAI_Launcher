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

  /// Run 目录路径（图库根不可用时为 null）。
  Future<String?> runDirectory(String runId) async {
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
}

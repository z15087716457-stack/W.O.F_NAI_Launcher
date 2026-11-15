import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/file_name_sanitizer.dart';
import '../../core/utils/file_transfer_utils.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../models/gallery/gallery_folder.dart';
import '../services/gallery/gallery_stream_scanner.dart';

/// 画廊文件夹仓库
class GalleryFolderRepository {
  GalleryFolderRepository._();
  static final GalleryFolderRepository instance = GalleryFolderRepository._();

  final _localStorage = LocalStorageService();
  GalleryDataSource get _dataSource => GalleryDataSource();
  final _rootsChanged = StreamController<void>.broadcast();
  Stream<void> get rootsChanged => _rootsChanged.stream;
  void notifyRootsChanged() => _rootsChanged.add(null);

  static const _supportedExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  /// 获取图片保存根路径
  ///
  /// 优先使用用户设置的自定义路径，如果没有设置则返回默认路径
  /// 默认路径：启动器 user-data/images/。
  Future<String?> getRootPath() async {
    // 优先使用用户设置的自定义路径
    final customPath = _localStorage.getImageSavePath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }

    // 使用默认路径
    return getUserAssetPath('images');
  }

  Future<String?> _legacyDefaultPath() async {
    if (_localStorage.getImageSavePath()?.isNotEmpty == true) return null;
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, 'NAI_Launcher', 'images');
    return await Directory(path).exists() ? path : null;
  }

  /// Browse sources are independent of the output folder. Missing v2 settings
  /// retain the old coverage; an explicit empty list means no sources.
  Future<List<String>> getSourcePaths() async {
    final configured = _localStorage.getSetting<List<dynamic>>(
      StorageKeys.gallerySourcePaths,
    );
    if (configured != null) {
      return galleryDistinctRoots(configured.whereType<String>());
    }
    final legacy = _localStorage.getSetting<List<dynamic>>(
      StorageKeys.galleryExtraRoots,
    );
    return galleryDistinctRoots([
      (await getRootPath())!,
      if (await _legacyDefaultPath() case final legacy?) legacy,
      ...?legacy?.whereType<String>(),
    ]);
  }

  /// Existing relative categories and their JSON stay anchored to their original
  /// folder, even after the user changes the output destination.
  Future<String> getCategoryBasePath() async =>
      _localStorage.getSetting<String>(StorageKeys.galleryCategoryBasePath) ??
      await _legacyDefaultPath() ??
      (await getRootPath())!;

  Future<void> ensureSourcesMigrated() async {
    final base = await getCategoryBasePath();
    final sources = await getSourcePaths();
    if (_localStorage.getSetting<String>(StorageKeys.galleryCategoryBasePath) ==
        null) {
      await _localStorage.setSetting(StorageKeys.galleryCategoryBasePath, base);
    }
    if (_localStorage.getSetting<List<dynamic>>(
          StorageKeys.gallerySourcePaths,
        ) ==
        null) {
      await _localStorage.setSetting(StorageKeys.gallerySourcePaths, sources);
    }
  }

  Future<void> setSourcePaths(List<String> paths) async {
    await ensureSourcesMigrated();
    await _localStorage.setSetting(
      StorageKeys.gallerySourcePaths,
      galleryDistinctRoots(paths),
    );
    notifyRootsChanged();
  }

  Future<bool> addSourcePath(String path) async {
    final normalized = normalizeGalleryFilePath(path);
    if (normalized.isEmpty) return false;
    final current = await getSourcePaths();
    if (current.any(
      (root) => galleryPathIsWithin(root, p.normalize(p.absolute(normalized))),
    )) {
      return false;
    }
    await setSourcePaths([...current, normalized]);
    return true;
  }

  Future<bool> removeSourcePath(String path) async {
    final current = await getSourcePaths();
    final updated = current
        .where((root) => !galleryFilePathsEqual(root, path))
        .toList();
    if (updated.length == current.length) return false;
    await setSourcePaths(updated);
    return true;
  }

  /// Moving user-managed output images is not an external-source operation,
  /// including when a browse source is a parent of that folder.
  Future<bool> isExternalPath(String path) async {
    if (galleryPathIsWithin(await getCategoryBasePath(), path)) return false;
    return (await getSourcePaths()).any(
      (root) => galleryPathIsWithin(root, path),
    );
  }

  Future<List<Directory>> getAllRootDirs() async {
    final dirs = <Directory>[];
    for (final path in await getSourcePaths()) {
      final dir = Directory(path);
      if (await dir.exists()) dirs.add(dir);
    }
    return dirs;
  }

  /// 扫描文件夹列表
  Future<List<GalleryFolder>> scanFolders() async {
    final rootPath = await getRootPath();
    if (rootPath == null || rootPath.isEmpty) return [];

    final rootDir = Directory(rootPath);
    if (!await rootDir.exists()) return [];

    final folders = <GalleryFolder>[];

    try {
      await for (final entity in rootDir.list(followLinks: false)) {
        if (entity is Directory) {
          final folder = await _createFolderFromDirectory(entity);
          if (folder != null) folders.add(folder);
        }
      }
      folders.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    } catch (e) {
      AppLogger.e('扫描文件夹失败', e);
    }

    return folders;
  }

  Future<GalleryFolder?> _createFolderFromDirectory(Directory dir) async {
    try {
      final stat = await dir.stat();
      return GalleryFolder(
        id: _generateFolderId(dir.path),
        name: p.basename(dir.path),
        path: dir.path,
        imageCount: await _countImagesInFolder(dir.path),
        createdAt: stat.changed,
        modifiedAt: stat.modified,
      );
    } catch (e) {
      AppLogger.e('创建文件夹对象失败: ${dir.path}', e);
      return null;
    }
  }

  String _generateFolderId(String path) =>
      md5.convert(utf8.encode(path)).toString().substring(0, 16);

  Future<int> _countImagesInFolder(String folderPath) async {
    int count = 0;
    try {
      await for (final entity in Directory(
        folderPath,
      ).list(followLinks: false)) {
        if (entity is File &&
            _supportedExtensions.contains(
              p.extension(entity.path).toLowerCase(),
            )) {
          count++;
        }
      }
    } catch (e) {
      AppLogger.w('Failed to get total image count', 'GalleryFolderRepository');
    }
    return count;
  }

  /// 创建新文件夹
  Future<GalleryFolder?> createFolder(String name) async {
    final rootPath = await getRootPath();
    if (rootPath == null || rootPath.isEmpty) return null;

    final cleanName = _sanitizeFolderName(name);
    if (cleanName.isEmpty) return null;

    final folderPath = p.join(rootPath, cleanName);
    final dir = Directory(folderPath);

    try {
      if (await dir.exists()) {
        AppLogger.w('文件夹已存在: $folderPath');
        return await _createFolderFromDirectory(dir);
      }

      await dir.create(recursive: false);
      AppLogger.i('创建文件夹成功: $folderPath');
      return await _createFolderFromDirectory(dir);
    } catch (e) {
      AppLogger.e('创建文件夹失败: $folderPath', e);
      return null;
    }
  }

  String _sanitizeFolderName(String name) {
    return FileNameSanitizer.sanitize(
      name,
      fallback: '',
      collapseWhitespace: true,
    );
  }

  /// 删除文件夹
  Future<bool> deleteFolder(String folderPath, {bool recursive = false}) async {
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) return true;

      if (!recursive) {
        // 转换为列表检查是否为空
        final items = await dir.list().toList();
        if (items.isNotEmpty) {
          AppLogger.w('文件夹不为空，无法删除: $folderPath');
          return false;
        }
      }

      await dir.delete(recursive: recursive);
      AppLogger.i('删除文件夹成功: $folderPath');
      return true;
    } catch (e) {
      AppLogger.e('删除文件夹失败: $folderPath', e);
      return false;
    }
  }

  /// 重命名文件夹
  Future<GalleryFolder?> renameFolder(String oldPath, String newName) async {
    try {
      final dir = Directory(oldPath);
      if (!await dir.exists()) return null;

      final cleanName = _sanitizeFolderName(newName);
      if (cleanName.isEmpty) return null;

      final newPath = p.join(p.dirname(oldPath), cleanName);
      if (await Directory(newPath).exists()) {
        AppLogger.w('目标文件夹已存在: $newPath');
        return null;
      }

      final newDir = await dir.rename(newPath);
      AppLogger.i('重命名文件夹成功: $oldPath -> $newPath');
      return await _createFolderFromDirectory(newDir);
    } catch (e) {
      AppLogger.e('重命名文件夹失败: $oldPath', e);
      return null;
    }
  }

  /// 移动图片到文件夹
  ///
  /// 源文件不再拦截额外图库源；使用跨卷移动并即时更新 DB 记录
  Future<bool> moveImageToFolder(
    String imagePath,
    String targetFolderPath,
  ) async {
    try {
      return await transferImageToFolder(imagePath, targetFolderPath) != null;
    } catch (error) {
      AppLogger.e('移动图片失败: $imagePath', error);
      return false;
    }
  }

  /// Return the actual collision-safe destination. Existing boolean callers
  /// keep their contract; explicit management can verify the native index.
  Future<String?> transferImageToFolder(
    String imagePath,
    String targetFolderPath, {
    bool copy = false,
    bool updateIndex = true,
    Future<void> Function()? beforeTransfer,
    Future<void> Function(String path)? afterTransfer,
    FileCopyValidator? validator,
  }) => GalleryStreamScanner.instance(dataSource: _dataSource)
      .withFilesystemMutation(
        () => _transferImageToFolder(
          imagePath,
          targetFolderPath,
          copy: copy,
          updateIndex: updateIndex,
          beforeTransfer: beforeTransfer,
          afterTransfer: afterTransfer,
          validator: validator,
        ),
      );

  Future<String?> _transferImageToFolder(
    String imagePath,
    String targetFolderPath, {
    required bool copy,
    required bool updateIndex,
    Future<void> Function()? beforeTransfer,
    Future<void> Function(String path)? afterTransfer,
    FileCopyValidator? validator,
  }) async {
    File? reservation;
    String? result;
    try {
      if (!await File(imagePath).exists() ||
          !await Directory(targetFolderPath).exists()) {
        return null;
      }
      final name = p.basename(imagePath);
      for (var attempt = 0; attempt < 1000; attempt++) {
        final suffix = attempt == 0
            ? ''
            : '_${DateTime.now().microsecondsSinceEpoch}_$attempt';
        final destination = File(
          p.join(
            targetFolderPath,
            '${p.basenameWithoutExtension(name)}$suffix${p.extension(name)}',
          ),
        );
        if (await FileSystemEntity.type(destination.path, followLinks: false) !=
            FileSystemEntityType.notFound) {
          continue;
        }
        try {
          reservation = await destination.create(exclusive: true);
          break;
        } on FileSystemException {
          if (await FileSystemEntity.type(
                destination.path,
                followLinks: false,
              ) ==
              FileSystemEntityType.notFound) {
            rethrow;
          }
        }
      }
      if (reservation == null) return null;
      await beforeTransfer?.call();
      result = copy
          ? await copyFileWithFreshMtime(
              imagePath,
              reservation.path,
              validator: validator,
            )
          : await moveFileCrossVolume(
              imagePath,
              reservation.path,
              validator: validator,
            );
      if (result != null && !copy && updateIndex && _dataSource.isInitialized) {
        try {
          final id = (await _dataSource.getImageIdsByPaths([
            imagePath,
          ]))[imagePath];
          if (id != null) {
            await _dataSource.updateFilePath(
              id,
              result,
              newFileName: p.basename(result),
            );
          }
        } catch (error) {
          AppLogger.w('移动后即时更新DB失败: $imagePath -> $result ($error)');
        }
      }
      if (result != null) await afterTransfer?.call(result);
      return result;
    } finally {
      if (result == null && reservation != null && await reservation.exists()) {
        await reservation.delete();
      }
    }
  }

  /// 批量移动图片到文件夹
  Future<int> moveImagesToFolder(
    List<String> imagePaths,
    String targetFolderPath,
  ) async {
    int successCount = 0;
    for (final imagePath in imagePaths) {
      if (await moveImageToFolder(imagePath, targetFolderPath)) successCount++;
    }
    return successCount;
  }

  /// 复制图片到文件夹
  ///
  /// 不做源只读拦截；同款重名后缀；使用 copyFileWithFreshMtime；不碰 DB
  Future<bool> copyImageToFolder(
    String imagePath,
    String targetFolderPath,
  ) async {
    try {
      return await transferImageToFolder(
            imagePath,
            targetFolderPath,
            copy: true,
          ) !=
          null;
    } catch (error) {
      AppLogger.e('复制图片失败: $imagePath', error);
      return false;
    }
  }

  /// 批量复制图片到文件夹
  Future<int> copyImagesToFolder(
    List<String> imagePaths,
    String targetFolderPath,
  ) async {
    int successCount = 0;
    for (final imagePath in imagePaths) {
      if (await copyImageToFolder(imagePath, targetFolderPath)) successCount++;
    }
    return successCount;
  }

  /// 获取根目录下的图片总数
  Future<int> getTotalImageCount() async {
    final rootPath = await getRootPath();
    if (rootPath == null || rootPath.isEmpty) return 0;

    int count = 0;
    final rootDir = Directory(rootPath);

    try {
      await for (final entity in rootDir.list(followLinks: false)) {
        if (entity is File &&
            _supportedExtensions.contains(
              p.extension(entity.path).toLowerCase(),
            )) {
          count++;
        } else if (entity is Directory) {
          count += await _countImagesInFolder(entity.path);
        }
      }
    } catch (e) {
      AppLogger.e('统计图片总数失败', e);
    }

    return count;
  }
}

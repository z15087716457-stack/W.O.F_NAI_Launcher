import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/gallery_path_utils.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../models/gallery/gallery_category.dart';

/// 画廊分类仓库
class GalleryCategoryRepository {
  GalleryCategoryRepository._();
  static final GalleryCategoryRepository instance =
      GalleryCategoryRepository._();

  final _localStorage = LocalStorageService();

  static const _categoriesFileName = '.gallery_categories.json';
  static const _suppressedCategoriesFileName =
      '.gallery_category_suppressed_paths.json';
  static const _supportedExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

  /// 获取图片保存根路径
  ///
  /// 优先使用用户设置的自定义路径，如果没有设置则返回默认路径
  /// 默认路径：Documents/NAI_Launcher/images/
  Future<String?> getRootPath() async {
    // 优先使用用户设置的自定义路径
    final customPath = _localStorage.getImageSavePath();
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }

    // 使用默认路径
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'NAI_Launcher', 'images');
  }

  Future<String?> _getCategoriesFilePath() async {
    final rootPath = await getRootPath();
    return rootPath != null ? p.join(rootPath, _categoriesFileName) : null;
  }

  Future<String?> _getSuppressedCategoriesFilePath() async {
    final rootPath = await getRootPath();
    return rootPath != null
        ? p.join(rootPath, _suppressedCategoriesFileName)
        : null;
  }

  Future<List<GalleryCategory>> loadCategories() async {
    try {
      final filePath = await _getCategoriesFilePath();
      if (filePath == null) return [];

      final file = File(filePath);
      if (!await file.exists()) return [];

      final jsonList = jsonDecode(await file.readAsString()) as List;
      return jsonList
          .map((j) => GalleryCategory.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e('加载分类配置失败', e);
      return [];
    }
  }

  /// 保存所有分类
  Future<bool> saveCategories(List<GalleryCategory> categories) async {
    try {
      final filePath = await _getCategoriesFilePath();
      if (filePath == null) return false;

      final file = File(filePath);
      final jsonList = categories.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));

      return true;
    } catch (e) {
      AppLogger.e('保存分类配置失败', e);
      return false;
    }
  }

  Future<Set<String>> _loadSuppressedFolderPaths() async {
    try {
      final filePath = await _getSuppressedCategoriesFilePath();
      if (filePath == null) return {};

      final file = File(filePath);
      if (!await file.exists()) return {};

      final jsonList = jsonDecode(await file.readAsString()) as List;
      return jsonList
          .whereType<String>()
          .map(_normalizeCategoryPath)
          .where((path) => path.isNotEmpty)
          .toSet();
    } catch (e) {
      AppLogger.e('加载隐藏分类路径失败', e);
      return {};
    }
  }

  Future<void> _saveSuppressedFolderPaths(Set<String> paths) async {
    try {
      final filePath = await _getSuppressedCategoriesFilePath();
      if (filePath == null) return;

      final file = File(filePath);
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }

      final normalized =
          paths
              .map(_normalizeCategoryPath)
              .where((path) => path.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (normalized.isEmpty) {
        if (await file.exists()) {
          await file.delete();
        }
        return;
      }

      await file.writeAsString(jsonEncode(normalized));
    } catch (e) {
      AppLogger.e('保存隐藏分类路径失败', e);
    }
  }

  Future<void> _suppressCategoryFolderPaths(
    GalleryCategory category,
    List<GalleryCategory> allCategories, {
    required bool recursive,
  }) async {
    final suppressedPaths = await _loadSuppressedFolderPaths();
    final categoryIds = {
      category.id,
      if (recursive) ...allCategories.getDescendantIds(category.id),
    };

    for (final item in allCategories) {
      if (categoryIds.contains(item.id)) {
        suppressedPaths.add(_normalizeCategoryPath(item.folderPath));
      }
    }

    await _saveSuppressedFolderPaths(suppressedPaths);
  }

  Future<void> _unsuppressCategoryFolderPath(String folderPath) async {
    final suppressedPaths = await _loadSuppressedFolderPaths();
    final normalizedPath = _normalizeCategoryPath(folderPath);
    final removed = suppressedPaths.remove(normalizedPath);
    if (removed) {
      await _saveSuppressedFolderPaths(suppressedPaths);
    }
  }

  Future<Set<String>> _pruneSuppressedFolderPaths(
    String rootPath,
    Set<String> suppressedPaths,
  ) async {
    final retained = <String>{};
    for (final relativePath in suppressedPaths) {
      final absolutePath = _absolutePathFromNormalized(rootPath, relativePath);
      if (await Directory(absolutePath).exists()) {
        retained.add(relativePath);
      }
    }

    if (retained.length != suppressedPaths.length) {
      await _saveSuppressedFolderPaths(retained);
    }

    return retained;
  }

  String _normalizeCategoryPath(String pathValue) {
    final normalized = p.normalize(pathValue).replaceAll('\\', '/');
    return normalized == '.' ? '' : normalized.replaceAll(RegExp(r'/+$'), '');
  }

  String _absolutePathFromNormalized(String rootPath, String normalizedPath) {
    // 绝对路径（外部图库源节点）直接使用
    if (isAbsoluteGalleryPath(normalizedPath)) return normalizedPath;
    return p.joinAll([rootPath, ...normalizedPath.split('/')]);
  }

  /// 获取分类对应的绝对文件夹路径
  ///
  /// 外部图库源节点（folderPath 为绝对路径）直接返回自身；
  /// 主源节点按相对根目录拼接
  Future<String> _absoluteCategoryPath(
    String rootPath,
    GalleryCategory category,
  ) async {
    if (category.isExternal) return category.folderPath;
    return p.join(rootPath, category.folderPath);
  }

  /// 分类树中是否存在外部图库源分类（用于禁用外部子树下的操作）
  bool _categoryOrAncestorsExternal(
    GalleryCategory category,
    List<GalleryCategory> allCategories,
  ) {
    if (category.isExternal) return true;
    // 向上找父链
    final visited = <String>{};
    String? parentId = category.parentId;
    while (parentId != null && visited.add(parentId)) {
      final parent = allCategories.findById(parentId);
      if (parent == null) break;
      if (parent.isExternal) return true;
      parentId = parent.parentId;
    }
    return false;
  }

  /// 创建分类（同时创建文件夹）
  ///
  /// 外部图库源子树只读：父分类属于外部源时拒绝创建
  Future<GalleryCategory?> createCategory({
    required String name,
    String? parentId,
    List<GalleryCategory> existingCategories = const [],
  }) async {
    // 外部图库源子树只读
    if (parentId != null) {
      final parent = existingCategories.findById(parentId);
      if (parent != null &&
          _categoryOrAncestorsExternal(parent, existingCategories)) {
        AppLogger.w('外部图库源分类为只读，禁止创建子分类: ${parent.name}');
        return null;
      }
    }

    final rootPath = await getRootPath();
    if (rootPath == null) return null;

    final cleanName = _sanitizeFolderName(name);
    if (cleanName.isEmpty) return null;

    final (relativePath, absolutePath) = parentId == null
        ? (cleanName, p.join(rootPath, cleanName))
        : _buildChildPath(rootPath, cleanName, parentId, existingCategories);

    if (absolutePath.isEmpty) return null;

    final dir = Directory(absolutePath);
    if (await dir.exists()) {
      final suppressedPaths = await _loadSuppressedFolderPaths();
      if (suppressedPaths.contains(_normalizeCategoryPath(relativePath))) {
        final siblings = existingCategories.where(
          (c) => c.parentId == parentId,
        );
        final category = GalleryCategory.create(
          name: name,
          folderPath: relativePath,
          parentId: parentId,
          sortOrder: siblings.length,
        ).updateImageCount(await _countImagesInFolder(absolutePath));
        await _unsuppressCategoryFolderPath(relativePath);
        AppLogger.i('恢复隐藏分类成功: ${category.name} -> $absolutePath');
        return category;
      }

      AppLogger.w('分类文件夹已存在: $absolutePath');
      return null;
    }

    try {
      await dir.create(recursive: true);

      final siblings = existingCategories.where((c) => c.parentId == parentId);
      final category = GalleryCategory.create(
        name: name,
        folderPath: relativePath,
        parentId: parentId,
        sortOrder: siblings.length,
      );

      AppLogger.i('创建分类成功: ${category.name} -> $absolutePath');
      return category;
    } catch (e) {
      AppLogger.e('创建分类文件夹失败: $absolutePath', e);
      return null;
    }
  }

  (String relative, String absolute) _buildChildPath(
    String rootPath,
    String cleanName,
    String parentId,
    List<GalleryCategory> categories,
  ) {
    final parent = categories.findById(parentId);
    if (parent == null) {
      AppLogger.e('父分类不存在: $parentId');
      return ('', '');
    }
    final relativePath = p.join(parent.folderPath, cleanName);
    return (relativePath, p.join(rootPath, relativePath));
  }

  /// 重命名分类（同时重命名文件夹）
  ///
  /// 外部图库源分类只读
  Future<GalleryCategory?> renameCategory(
    GalleryCategory category,
    String newName,
    List<GalleryCategory> allCategories,
  ) async {
    if (_categoryOrAncestorsExternal(category, allCategories)) {
      AppLogger.w('外部图库源分类为只读，禁止重命名: ${category.name}');
      return null;
    }

    final rootPath = await getRootPath();
    if (rootPath == null) return null;

    final cleanName = _sanitizeFolderName(newName);
    if (cleanName.isEmpty) return null;

    final oldPath = p.join(rootPath, category.folderPath);
    final newPath = p.join(p.dirname(oldPath), cleanName);

    try {
      final oldDir = Directory(oldPath);
      if (!await oldDir.exists()) {
        AppLogger.w('原分类文件夹不存在: $oldPath');
        return null;
      }

      if (await Directory(newPath).exists()) {
        AppLogger.w('目标文件夹已存在: $newPath');
        return null;
      }

      await oldDir.rename(newPath);

      AppLogger.i('重命名分类成功: ${category.name} -> $newName');
      return category.copyWith(
        name: newName,
        folderPath: p.relative(newPath, from: rootPath),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.e('重命名分类失败: ${category.name}', e);
      return null;
    }
  }

  /// 更新所有子分类的文件夹路径
  List<GalleryCategory> updateDescendantPaths(
    String oldParentPath,
    String newParentPath,
    List<GalleryCategory> categories,
  ) {
    return categories.map((c) {
      if (c.folderPath.startsWith(oldParentPath)) {
        return c.copyWith(
          folderPath: c.folderPath.replaceFirst(oldParentPath, newParentPath),
          updatedAt: DateTime.now(),
        );
      }
      return c;
    }).toList();
  }

  /// 移动分类到新父级（同时移动文件夹）
  ///
  /// 外部图库源分类只读；目标父分类属于外部源时也拒绝
  Future<GalleryCategory?> moveCategory(
    GalleryCategory category,
    String? newParentId,
    List<GalleryCategory> allCategories,
  ) async {
    if (_categoryOrAncestorsExternal(category, allCategories)) {
      AppLogger.w('外部图库源分类为只读，禁止移动: ${category.name}');
      return null;
    }

    if (newParentId != null) {
      final newParent = allCategories.findById(newParentId);
      if (newParent != null &&
          _categoryOrAncestorsExternal(newParent, allCategories)) {
        AppLogger.w('外部图库源分类为只读，禁止移入: ${newParent.name}');
        return null;
      }
    }

    final rootPath = await getRootPath();
    if (rootPath == null) return null;

    if (newParentId != null &&
        allCategories.wouldCreateCycle(category.id, newParentId)) {
      AppLogger.w('移动会造成循环引用');
      return null;
    }

    final (newRelativePath, newAbsolutePath) = newParentId == null
        ? (
            p.basename(category.folderPath),
            p.join(rootPath, p.basename(category.folderPath)),
          )
        : _buildMovePaths(rootPath, category, newParentId, allCategories);

    if (newAbsolutePath.isEmpty) return null;

    final oldPath = p.join(rootPath, category.folderPath);

    try {
      final oldDir = Directory(oldPath);
      if (!await oldDir.exists()) {
        AppLogger.w('原分类文件夹不存在: $oldPath');
        return null;
      }

      if (await Directory(newAbsolutePath).exists()) {
        AppLogger.w('目标文件夹已存在: $newAbsolutePath');
        return null;
      }

      final newParentDir = Directory(p.dirname(newAbsolutePath));
      if (!await newParentDir.exists()) {
        await newParentDir.create(recursive: true);
      }

      await oldDir.rename(newAbsolutePath);

      AppLogger.i('移动分类成功: ${category.name}');
      return category.copyWith(
        parentId: newParentId,
        folderPath: newRelativePath,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.e('移动分类失败: ${category.name}', e);
      return null;
    }
  }

  (String relative, String absolute) _buildMovePaths(
    String rootPath,
    GalleryCategory category,
    String newParentId,
    List<GalleryCategory> categories,
  ) {
    final newParent = categories.findById(newParentId);
    if (newParent == null) {
      AppLogger.e('目标父分类不存在: $newParentId');
      return ('', '');
    }
    final relativePath = p.join(
      newParent.folderPath,
      p.basename(category.folderPath),
    );
    return (relativePath, p.join(rootPath, relativePath));
  }

  /// 删除分类
  ///
  /// 外部图库源分类只读
  Future<bool> deleteCategory(
    GalleryCategory category,
    List<GalleryCategory> allCategories, {
    bool deleteFolder = true,
    bool recursive = false,
  }) async {
    if (_categoryOrAncestorsExternal(category, allCategories)) {
      AppLogger.w('外部图库源分类为只读，禁止删除: ${category.name}');
      return false;
    }

    final rootPath = await getRootPath();
    if (rootPath == null) return false;

    final children = allCategories.getChildren(category.id);
    if (children.isNotEmpty && !recursive) {
      AppLogger.w('分类包含子分类，无法删除: ${category.name}');
      return false;
    }

    final folderPath = p.join(rootPath, category.folderPath);

    try {
      if (deleteFolder) {
        final dir = Directory(folderPath);
        if (await dir.exists()) {
          if (!recursive && !await _isFolderEmpty(folderPath)) {
            AppLogger.w('文件夹不为空，无法删除: $folderPath');
            return false;
          }
          await dir.delete(recursive: recursive);
        }
      } else {
        await _suppressCategoryFolderPaths(
          category,
          allCategories,
          recursive: recursive,
        );
      }

      AppLogger.i('删除分类成功: ${category.name}');
      return true;
    } catch (e) {
      AppLogger.e('删除分类失败: ${category.name}', e);
      return false;
    }
  }

  /// 移动图片到分类
  ///
  /// 额外图库源文件只读（源文件）；目标分类属于外部图库源时同样拒绝
  Future<String?> moveImageToCategory(
    String imagePath,
    GalleryCategory? targetCategory,
  ) async {
    // 源文件位于额外图库源 → 只读
    if (await GalleryFolderRepository.instance.isExtraRootPath(imagePath)) {
      AppLogger.w('额外图库源文件为只读，禁止移动: $imagePath');
      return null;
    }

    final rootPath = await getRootPath();
    if (rootPath == null) return null;

    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      // 目标分类属于外部图库源 → 只读
      if (targetCategory != null && targetCategory.isExternal) {
        AppLogger.w('外部图库源分类为只读，禁止移入: ${targetCategory.name}');
        return null;
      }

      final fileName = p.basename(imagePath);
      final targetDir = targetCategory == null
          ? rootPath
          : p.join(rootPath, targetCategory.folderPath);

      final dir = Directory(targetDir);
      if (!await dir.exists()) await dir.create(recursive: true);

      var targetPath = p.join(targetDir, fileName);

      if (await File(targetPath).exists()) {
        final baseName = p.basenameWithoutExtension(fileName);
        final ext = p.extension(fileName);
        targetPath = p.join(
          targetDir,
          '${baseName}_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
      }

      await file.rename(targetPath);
      return targetPath;
    } catch (e) {
      AppLogger.e('移动图片失败: $imagePath', e);
      return null;
    }
  }

  /// 批量移动图片到分类
  Future<int> moveImagesToCategory(
    List<String> imagePaths,
    GalleryCategory? targetCategory,
  ) async {
    int successCount = 0;
    for (final imagePath in imagePaths) {
      if (await moveImageToCategory(imagePath, targetCategory) != null) {
        successCount++;
      }
    }
    return successCount;
  }

  /// 统计分类内的图片数量
  Future<int> countImagesInCategory(
    GalleryCategory category, {
    bool includeDescendants = true,
  }) async {
    final rootPath = await getRootPath();
    if (rootPath == null) return 0;

    return _countImagesInFolder(
      await _absoluteCategoryPath(rootPath, category),
      recursive: includeDescendants,
    );
  }

  /// 获取分类对应的绝对文件夹路径
  Future<String?> getCategoryAbsolutePath(GalleryCategory category) async {
    final rootPath = await getRootPath();
    if (rootPath == null) return null;
    return _absoluteCategoryPath(rootPath, category);
  }

  /// 同步分类与文件系统
  ///
  /// 扫描主源 + 全部额外图库源的文件夹，创建缺失的分类、删除不存在的分类
  /// 额外图库源的分类节点 folderPath 存绝对路径（只读，不参与分类编辑）
  Future<List<GalleryCategory>> syncWithFileSystem(
    List<GalleryCategory> existingCategories,
  ) async {
    final rootPath = await getRootPath();
    if (rootPath == null) return existingCategories;

    final updatedCategories = <GalleryCategory>[];
    final existingPaths = existingCategories
        .map((c) => _normalizeCategoryPath(c.folderPath))
        .toSet();
    final suppressedPaths = await _pruneSuppressedFolderPaths(
      rootPath,
      await _loadSuppressedFolderPaths(),
    );

    // 检查现有分类的文件夹是否存在
    for (final category in existingCategories) {
      final folderPath = await _absoluteCategoryPath(rootPath, category);
      if (await Directory(folderPath).exists()) {
        // 更新图片数量
        final imageCount = await _countImagesInFolder(folderPath);
        updatedCategories.add(category.updateImageCount(imageCount));
      }
      // 如果文件夹不存在，则不添加到更新列表（相当于删除）
    }

    // 扫描主源文件系统中的新文件夹
    await _scanAndAddNewFolders(
      rootPath,
      rootPath,
      null,
      existingPaths,
      suppressedPaths,
      updatedCategories,
    );

    // 扫描每个额外图库源：根节点 + 子文件夹（folderPath 为绝对路径）
    for (final extraRoot
        in await GalleryFolderRepository.instance.getExtraRootPaths()) {
      if (!await Directory(extraRoot).exists()) continue;

      final normalizedRoot = _normalizeCategoryPath(extraRoot);
      var rootCategory = updatedCategories.firstWhereOrNull(
        (c) =>
            c.isExternal &&
            c.parentId == null &&
            _normalizeCategoryPath(c.folderPath) == normalizedRoot,
      );
      if (rootCategory == null) {
        rootCategory = GalleryCategory.create(
          name: p.basename(extraRoot),
          folderPath: extraRoot,
          parentId: null,
          sortOrder: updatedCategories.where((c) => c.parentId == null).length,
        );
        existingPaths.add(normalizedRoot);
        updatedCategories.add(rootCategory);
      }

      // 递归扫描外部源的子文件夹
      await _scanAndAddNewFolders(
        extraRoot,
        extraRoot,
        rootCategory.id,
        existingPaths,
        suppressedPaths,
        updatedCategories,
        useAbsolutePaths: true,
      );
    }

    // 计数聚合：各分类的 imageCount 目前是「直系计数」（不含子目录），
    // 父节点需要递归总数，才能与选中后按路径前缀过滤的实际图数一致
    // （例如外部图库源根节点 01_图库 = 其下所有子目录图片之和）。
    return updatedCategories.withAggregatedImageCounts();
  }

  /// 递归扫描并添加新文件夹
  ///
  /// [useAbsolutePaths] 为 true 时（外部图库源）folderPath 存绝对路径，
  /// 否则存相对 [rootPath] 的路径
  Future<void> _scanAndAddNewFolders(
    String rootPath,
    String currentPath,
    String? parentId,
    Set<String> existingPaths,
    Set<String> suppressedPaths,
    List<GalleryCategory> categories, {
    bool useAbsolutePaths = false,
  }) async {
    final dir = Directory(currentPath);
    if (!await dir.exists()) return;

    // 【防卡顿】大目录树（如 2.3 万目录的图库）遍历时分块让出事件循环
    var visited = 0;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        visited++;
        if (visited % 500 == 0) {
          await Future<void>.delayed(Duration.zero);
        }

        if (entity is Directory) {
          final folderName = p.basename(entity.path);
          // 跳过隐藏文件夹
          if (folderName.startsWith('.')) continue;

          final relativePath = useAbsolutePaths
              ? entity.path
              : p.relative(entity.path, from: rootPath);
          final normalizedRelativePath = _normalizeCategoryPath(relativePath);

          if (suppressedPaths.contains(normalizedRelativePath)) {
            continue;
          }

          if (!existingPaths.contains(normalizedRelativePath)) {
            // 新文件夹，创建分类
            final imageCount = await _countImagesInFolder(entity.path);
            final category = GalleryCategory.create(
              name: folderName,
              folderPath: relativePath,
              parentId: parentId,
              sortOrder: categories.where((c) => c.parentId == parentId).length,
            ).updateImageCount(imageCount);

            categories.add(category);
            existingPaths.add(normalizedRelativePath);

            // 递归扫描子文件夹
            await _scanAndAddNewFolders(
              rootPath,
              entity.path,
              category.id,
              existingPaths,
              suppressedPaths,
              categories,
              useAbsolutePaths: useAbsolutePaths,
            );
          } else {
            // 已存在的分类，查找其ID并递归扫描子文件夹
            final existingCategory = categories
                .where(
                  (c) =>
                      _normalizeCategoryPath(c.folderPath) ==
                      normalizedRelativePath,
                )
                .firstOrNull;

            if (existingCategory != null) {
              await _scanAndAddNewFolders(
                rootPath,
                entity.path,
                existingCategory.id,
                existingPaths,
                suppressedPaths,
                categories,
                useAbsolutePaths: useAbsolutePaths,
              );
            }
          }
        }
      }
    } catch (e) {
      AppLogger.e('扫描文件夹失败: $currentPath', e);
    }
  }

  String _sanitizeFolderName(String name) => name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<bool> _isFolderEmpty(String folderPath) async {
    try {
      return await Directory(folderPath).list().isEmpty;
    } catch (_) {
      return true;
    }
  }

  Future<int> _countImagesInFolder(
    String folderPath, {
    bool recursive = false,
  }) async {
    int count = 0;
    try {
      await for (final entity in Directory(
        folderPath,
      ).list(recursive: recursive, followLinks: false)) {
        if (entity is File &&
            _supportedExtensions.contains(
              p.extension(entity.path).toLowerCase(),
            )) {
          count++;
        }
      }
    } catch (e) {
      AppLogger.w(
        'Failed to get total image count',
        'GalleryCategoryRepository',
      );
    }
    return count;
  }
}

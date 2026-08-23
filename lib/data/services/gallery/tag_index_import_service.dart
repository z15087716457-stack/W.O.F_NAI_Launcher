import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/gallery_path_utils.dart';
import '../../repositories/gallery_folder_repository.dart';
import 'scan_state_manager.dart';

/// 标签索引文件约定目录名（图库源根下）
const String tagIndexDirectoryName = '_索引';

/// 标签索引文件约定文件名
const String tagIndexFileName = 'index.jsonl';

/// 查找图库源根下约定位置的标签索引文件：`<源根>\_索引\index.jsonl`
Future<File?> findTagIndexFileForRoot(String rootPath) async {
  try {
    final normalizedRoot = normalizeGalleryFilePath(rootPath);
    final file = File(p.join(normalizedRoot, tagIndexDirectoryName, tagIndexFileName));
    if (await file.exists()) return file;
  } catch (e) {
    AppLogger.w('查找标签索引文件失败: $rootPath, $e', 'TagIndexImport');
  }
  return null;
}

/// 标签索引导入结果统计
class TagIndexImportResult {
  /// 文件总行数
  final int totalLines;

  /// 新建图片记录数
  final int imported;

  /// 更新已有记录数
  final int updated;

  /// 跳过数（路径不在已配置源内 / 非图片文件 / 重复行按更新计，此处仅统计被拒行）
  final int skipped;

  /// 错误数（JSON 解析失败 / 写库失败）
  final int errors;

  /// 错误信息样本（最多保留 10 条）
  final List<String> errorMessages;

  const TagIndexImportResult({
    this.totalLines = 0,
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = 0,
    this.errorMessages = const [],
  });

  /// 是否全部成功（无错误）
  bool get hasErrors => errors > 0;
}

/// 外部 JSONL 标签索引导入器
///
/// 索引文件格式（UTF-8，每行一个 JSON）：
/// ```json
/// {"path":"E:\\A.I\\NovelAI\\01_图库\\NAI 4.5\\x.png","name":"x.png",
///  "size":123,"mtime":1787469000,"width":832,"height":1216,
///  "source":"NovelAI Diffusion V4.5 4BDE2A90","software":"NovelAI",
///  "seed":123,"prompt":"...","uc":"...",
///  "tags":["1girl","solo","rating:nsfw"],"nsfw":true,"track":"alpha"}
/// ```
///
/// 规则：
/// - 只导入 path 位于**当前已配置图库源**（主源或额外源）之内的行，之外的计「跳过」
/// - 已存在记录更新 size/mtime（防过期），不存在的创建（metadata_status=imported）
/// - 标签按名归一（trim + 小写 + 下划线，tags 已是归一化形式直接 trim）
/// - 幂等可重导：同一文件再次导入走更新路径
class TagIndexImportService {
  final GalleryDataSource _dataSource;

  /// 单批写入条数（与任务约定 500/批）
  static const int batchSize = 500;

  /// 全局导入状态标志
  ///
  /// 跨层 guard：导入进行中时扫描器拒绝启动扫描，
  /// 避免导入的记录尚未落库就被扫描器裸解析（导入先行流程的关键保护）
  static bool isImporting = false;

  /// 与扫描器一致的支持扩展名
  static const Set<String> _supportedExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };

  TagIndexImportService(this._dataSource);

  /// 获取当前已配置的图库源根路径（规范化）
  Future<List<String>> _resolveConfiguredRoots() async {
    final dirs = await GalleryFolderRepository.instance.getAllRootDirs();
    return dirs.map((d) => normalizeGalleryFilePath(d.path)).toList();
  }

  /// 流式导入 JSONL 索引文件
  ///
  /// [jsonlPath] 索引文件路径
  /// [rootPaths] 已配置图库源根（规范化路径）；为空时自动从仓库获取
  /// [onProgress] 进度回调 (已处理行数, 总行数)
  Future<TagIndexImportResult> importFromJsonl(
    String jsonlPath, {
    List<String>? rootPaths,
    void Function(int processedLines, int totalLines)? onProgress,
  }) async {
    if (isImporting) {
      AppLogger.w('[TagIndexImport] 已有导入任务进行中，拒绝并发导入', 'TagIndexImport');
      return const TagIndexImportResult(
        errors: 1,
        errorMessages: ['已有标签索引导入任务进行中'],
      );
    }

    // 【双向防护】扫描进行中拒绝导入：扫描器正在裸解析文件并写库，
    // 此时导入会把扫描器刚写下的行再覆盖一遍（且 is_nsfw/收藏等字段
    // 存在互相覆盖窗口），等待扫描完成再导入。
    if (ScanStateManager.instance.isScanning) {
      AppLogger.w(
        '[TagIndexImport] 扫描进行中，拒绝导入（等待扫描完成）',
        'TagIndexImport',
      );
      throw const TagIndexImportBlockedByScanException();
    }

    isImporting = true;
    try {
      return await _importFromJsonlInner(
        jsonlPath,
        rootPaths: rootPaths,
        onProgress: onProgress,
      );
    } finally {
      isImporting = false;
    }
  }

  Future<TagIndexImportResult> _importFromJsonlInner(
    String jsonlPath, {
    List<String>? rootPaths,
    void Function(int processedLines, int totalLines)? onProgress,
  }) async {
    final file = File(jsonlPath);
    if (!await file.exists()) {
      throw FileSystemException('标签索引文件不存在', jsonlPath);
    }

    final roots = rootPaths ?? await _resolveConfiguredRoots();

    // 第一遍：统计总行数（本地文件很快），用于进度显示
    final totalLines = await _countLines(file);
    if (totalLines == 0) {
      AppLogger.w('[TagIndexImport] 空索引文件: $jsonlPath', 'TagIndexImport');
      return const TagIndexImportResult();
    }

    AppLogger.i(
      '[TagIndexImport] 开始导入: $jsonlPath, $totalLines 行, '
      'roots=${roots.join(' | ')}',
      'TagIndexImport',
    );

    var imported = 0;
    var updated = 0;
    var skipped = 0;
    var errors = 0;
    var processed = 0;
    final errorMessages = <String>[];
    final pendingBatch = <TagIndexImportEntry>[];

    Future<void> flushBatch() async {
      if (pendingBatch.isEmpty) return;
      final (created, touched) = await _dataSource.importTagIndexEntries(
        List.of(pendingBatch),
        batchSize: batchSize,
      );
      imported += created;
      updated += touched;
      pendingBatch.clear();
    }

    try {
      final lines = utf8.decoder
          .bind(file.openRead())
          .transform(const LineSplitter());

      await for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          // 空行不计数（与 _countLines 口径一致）
          continue;
        }
        processed++;

        var entry = _parseLine(trimmed);
        if (entry == null) {
          errors++;
          if (errorMessages.length < 10) {
            errorMessages.add('第 $processed 行解析失败: ${_truncate(trimmed)}');
          }
          continue;
        }

        // 路径必须位于某个当前已配置源之内，之外的计「跳过」
        final normalizedPath = normalizeGalleryFilePath(entry.filePath);
        final withinRoot = roots.any(
          (root) => galleryPathIsWithin(root, normalizedPath),
        );
        if (!withinRoot) {
          skipped++;
          continue;
        }

        // 非图片文件不导入（与扫描器支持范围一致）
        final ext = p.extension(normalizedPath).toLowerCase();
        if (!_supportedExtensions.contains(ext)) {
          skipped++;
          continue;
        }

        // JSONL 缺 mtime（≤0）时从文件系统取真实 mtime，避免落 epoch 0
        // （created_at 为 1970 会让日期过滤/排序全部失真）；
        // stat 失败或文件不存在（Windows 上 stat 缺失文件不抛错，
        // 返回 type=notFound）才跳过该行并计数。
        if (entry.modifiedAt.millisecondsSinceEpoch <= 0) {
          try {
            final stat = await File(normalizedPath).stat();
            if (stat.type == FileSystemEntityType.notFound) {
              throw const FileSystemException('File not found');
            }
            entry = entry.copyWith(modifiedAt: stat.modified);
          } catch (e) {
            skipped++;
            if (errorMessages.length < 10) {
              errorMessages.add('第 $processed 行缺少 mtime 且文件不可访问: $e');
            }
            continue;
          }
        }

        pendingBatch.add(entry);

        if (pendingBatch.length >= batchSize) {
          await flushBatch();
        }

        onProgress?.call(processed, totalLines);

        // 让出事件循环，避免阻塞 UI
        if (processed % 1000 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      // 收尾批次
      await flushBatch();
    } catch (e, stack) {
      AppLogger.e('[TagIndexImport] 导入失败', e, stack, 'TagIndexImport');
      errors += pendingBatch.length;
      if (errorMessages.length < 10) {
        errorMessages.add('写库失败: $e');
      }
      throw TagIndexImportException('标签索引导入失败: $e', cause: e);
    }

    final result = TagIndexImportResult(
      totalLines: totalLines,
      imported: imported,
      updated: updated,
      skipped: skipped,
      errors: errors,
      errorMessages: errorMessages,
    );

    AppLogger.i(
      '[TagIndexImport] 完成: total=$totalLines, imported=$imported, '
      'updated=$updated, skipped=$skipped, errors=$errors',
      'TagIndexImport',
    );

    return result;
  }

  /// 统计文件行数（流式）
  Future<int> _countLines(File file) async {
    var count = 0;
    await for (final line in utf8.decoder
        .bind(file.openRead())
        .transform(const LineSplitter())) {
      if (line.trim().isNotEmpty) count++;
    }
    return count;
  }

  /// 解析单行 JSON，失败返回 null
  TagIndexImportEntry? _parseLine(String line) {
    try {
      final json = jsonDecode(line);
      if (json is! Map<String, dynamic>) return null;

      final rawPath = json['path'];
      if (rawPath is! String || rawPath.trim().isEmpty) return null;

      final filePath = normalizeGalleryFilePath(rawPath);
      final name = json['name'] as String?;
      final size = (json['size'] as num?)?.toInt() ?? 0;
      final mtime = (json['mtime'] as num?)?.toInt() ?? 0;
      final width = (json['width'] as num?)?.toInt();
      final height = (json['height'] as num?)?.toInt();
      final source = json['source'] as String?;
      final software = json['software'] as String?;
      final seed = (json['seed'] as num?)?.toInt();
      final prompt = json['prompt'] as String?;
      final uc = json['uc'] as String?;
      final model = json['model'] as String?;
      final sampler = json['sampler'] as String?;
      final steps = (json['steps'] as num?)?.toInt();
      final cfg = (json['cfg'] as num?)?.toDouble() ??
          (json['cfg_scale'] as num?)?.toDouble();
      final noiseSchedule = (json['noise_schedule'] as String?) ??
          (json['noiseSchedule'] as String?);
      final nsfw = json['nsfw'];
      final rawTags = json['tags'];
      final tags = <String>[];
      if (rawTags is List) {
        for (final tag in rawTags) {
          if (tag is String) {
            final trimmed = tag.trim();
            if (trimmed.isNotEmpty) tags.add(trimmed);
          }
        }
      }

      return TagIndexImportEntry(
        filePath: filePath,
        fileName: (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : p.basename(filePath),
        fileSize: size,
        modifiedAt: mtime > 0
            ? DateTime.fromMillisecondsSinceEpoch(mtime * 1000)
            : DateTime.fromMillisecondsSinceEpoch(0),
        width: width,
        height: height,
        source: source,
        software: software,
        seed: seed,
        prompt: prompt,
        negativePrompt: uc,
        tags: tags,
        rawJson: line,
        model: model,
        sampler: sampler,
        steps: steps,
        cfgScale: cfg,
        noiseSchedule: noiseSchedule,
        nsfw: nsfw is bool ? nsfw : null,
      );
    } catch (e) {
      AppLogger.d('[TagIndexImport] 行解析失败: $e', 'TagIndexImport');
      return null;
    }
  }

  String _truncate(String value, {int maxLength = 120}) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}…';
  }
}

/// 标签索引导入异常
class TagIndexImportException implements Exception {
  final String message;
  final Object? cause;

  const TagIndexImportException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// 扫描进行中拒绝导入（UI 层用 i18n 提示，见 settings_importTagIndexBlockedByScan）
class TagIndexImportBlockedByScanException implements Exception {
  const TagIndexImportBlockedByScanException();

  @override
  String toString() => 'Scan is in progress, import rejected';
}

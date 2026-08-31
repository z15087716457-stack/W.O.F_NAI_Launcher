import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/gallery_path_utils.dart';
import '../../models/gallery/local_image_record.dart';
import '../../models/gallery/nai_image_metadata.dart';
import '../image_metadata_service.dart';
import 'scan_config.dart';
import 'scan_state_manager.dart';
import 'tag_index_import_service.dart';

typedef ExistingFileCacheEntry = (int, int, int, MetadataStatus, DateTime?);

/// 文件处理阶段
enum FileProcessingStage {
  discovered, // 发现文件
  indexing, // 索引中（检查是否需要处理）
  extracting, // 提取元数据中
  caching, // 缓存元数据
  completed, // 完成
  skipped, // 跳过（无需处理）
  error, // 错误
}

/// 单文件处理结果
class FileProcessingResult {
  final String path;
  final FileProcessingStage stage;
  final NaiImageMetadata? metadata;
  final bool isNewFile;
  final bool metadataUpdated;
  final String? error;

  FileProcessingResult({
    required this.path,
    required this.stage,
    this.metadata,
    this.isNewFile = false,
    this.metadataUpdated = false,
    this.error,
  });
}

/// 流式扫描统计
class StreamScanStats {
  final int totalDiscovered; // 发现的文件总数
  final int processed; // 已处理数量
  final int skipped; // 跳过数量
  final int withMetadata; // 有元数据的数量
  final int failed; // 失败的数量
  final String currentFile; // 当前处理的文件
  final FileProcessingStage currentStage; // 当前阶段
  final double progress; // 总体进度 (0.0 - 1.0)

  StreamScanStats({
    this.totalDiscovered = 0,
    this.processed = 0,
    this.skipped = 0,
    this.withMetadata = 0,
    this.failed = 0,
    this.currentFile = '',
    this.currentStage = FileProcessingStage.discovered,
    this.progress = 0.0,
  });

  StreamScanStats copyWith({
    int? totalDiscovered,
    int? processed,
    int? skipped,
    int? withMetadata,
    int? failed,
    String? currentFile,
    FileProcessingStage? currentStage,
    double? progress,
  }) {
    return StreamScanStats(
      totalDiscovered: totalDiscovered ?? this.totalDiscovered,
      processed: processed ?? this.processed,
      skipped: skipped ?? this.skipped,
      withMetadata: withMetadata ?? this.withMetadata,
      failed: failed ?? this.failed,
      currentFile: currentFile ?? this.currentFile,
      currentStage: currentStage ?? this.currentStage,
      progress: progress ?? this.progress,
    );
  }

  /// 计算剩余文件数
  int get remaining => totalDiscovered - processed - skipped;

  /// 计算覆盖率
  double get coverage =>
      totalDiscovered > 0 ? withMetadata / totalDiscovered : 0.0;
}

/// 画廊流式扫描器
///
/// 真正的流式处理：发现文件 → 立即处理 → 实时更新
/// 每处理一张图就更新UI，而不是先收集所有文件
///
/// 【单例模式】使用 [instance] 获取全局唯一实例，防止并发扫描
///
/// 【批处理】DB 写入（upsertImage/upsertMetadata）改为收集后每
/// [_flushBatchSize] 个文件一个事务批量刷盘（进度通知同步节流），
/// 避免 UI isolate 被逐文件 SQLite 事务和进度 setState 堵死。
class GalleryStreamScanner {
  // 单例实例
  static GalleryStreamScanner? _instance;

  /// 获取全局唯一实例
  ///
  /// [dataSource] 数据源，仅在首次创建实例时需要
  static GalleryStreamScanner instance({
    GalleryDataSource? dataSource,
    int flushBatchSize = 200,
  }) {
    if (_instance == null) {
      if (dataSource == null) {
        throw StateError('首次创建 GalleryStreamScanner 需要提供 dataSource');
      }
      _instance = GalleryStreamScanner._internal(
        dataSource: dataSource,
        flushBatchSize: flushBatchSize,
      );
    }
    return _instance!;
  }

  /// 重置单例（用于测试）
  static void resetInstance() {
    _instance?._cleanup();
    _instance = null;
  }

  /// 清理资源
  void _cleanup() {
    if (!_statsController.isClosed) {
      _statsController.close();
    }
    if (!_resultController.isClosed) {
      _resultController.close();
    }
  }

  final GalleryDataSource _dataSource;
  final ScanStateManager _stateManager = ScanStateManager.instance;
  final _metadataService = ImageMetadataService();

  /// 批量刷盘大小（测试可注入小值）
  final int _flushBatchSize;

  /// 批处理缓冲：图片记录 + 对齐的元数据（null=无元数据）
  final List<GalleryImageRecord> _pendingImageRecords = [];
  final List<NaiImageMetadata?> _pendingMetadata = [];

  /// 进度通知节流
  DateTime? _lastProgressEmit;
  DateTime? _lastStateEmit;
  static const Duration _progressEmitInterval = Duration(milliseconds: 250);

  // 状态
  bool _isRunning = false;
  bool _shouldCancel = false;

  // 互斥锁，防止并发扫描
  final _scanLock = Lock();

  // 统计
  final _statsController = StreamController<StreamScanStats>.broadcast();
  final _resultController = StreamController<FileProcessingResult>.broadcast();

  // 缓存
  final _existingMap = <String, ExistingFileCacheEntry>{};

  /// 软删路径键集合（DB is_deleted=1）。
  ///
  /// 删除池的文件仍在盘上，扫描发现它们时不能重新索引——
  /// 否则 batchUpsert 会把 is_deleted 复位成 0，DB 软删失效导致复活。
  final Set<String> _deletedPathKeys = {};

  Stream<StreamScanStats> get statsStream => _statsController.stream;
  Stream<FileProcessingResult> get resultStream => _resultController.stream;

  /// 私有构造函数
  GalleryStreamScanner._internal({
    required GalleryDataSource dataSource,
    int flushBatchSize = 200,
  }) : _dataSource = dataSource,
       _flushBatchSize = flushBatchSize;

  /// @deprecated 使用 [instance] 代替
  ///
  /// 公共构造函数（向后兼容）
  ///
  /// ⚠️ 警告：直接创建实例可能导致并发扫描问题。
  /// 请优先使用 [GalleryStreamScanner.instance(dataSource: dataSource)]
  factory GalleryStreamScanner({
    required GalleryDataSource dataSource,
    int flushBatchSize = 200,
  }) {
    return instance(dataSource: dataSource, flushBatchSize: flushBatchSize);
  }

  /// 开始流式扫描（支持多图库源）
  ///
  /// [rootDirs] 图库源目录列表（主源 + 额外源），依次串行扫描，进度按多源累计
  /// [onFileProcessed] - 每个文件处理完成时的回调
  /// [checkConsistency] - 是否在扫描前检查数据一致性（删除不存在的文件记录）
  /// [retryMissingMetadata] - 是否重新尝试历史上标记为无元数据的文件
  /// [retryFailedMetadata] - 是否重新尝试历史上提取失败的文件
  ///
  /// 使用互斥锁保证同一时间只有一个扫描任务在运行
  Future<void> startScanning(
    List<Directory> rootDirs, {
    void Function(FileProcessingResult result, StreamScanStats stats)?
    onFileProcessed,
    bool checkConsistency = true,
    bool retryMissingMetadata = false,
    bool retryFailedMetadata = false,
  }) async {
    // 使用互斥锁防止并发扫描
    await _scanLock.synchronized(() async {
      if (_isRunning) {
        AppLogger.w(
          '[StreamScan] Scanner already running',
          'GalleryStreamScanner',
        );
        return;
      }

      if (rootDirs.isEmpty) {
        AppLogger.w(
          '[StreamScan] No root directories to scan',
          'GalleryStreamScanner',
        );
        return;
      }

      // 【导入先行保护】标签索引导入进行中时拒绝扫描：
      // 导入的记录带 last_scanned_at + size/mtime 签名，扫描走 skip 快进；
      // 若此时扫描会裸解析全部文件，破坏导入先行流程
      if (TagIndexImportService.isImporting) {
        AppLogger.w(
          '[StreamScan] 标签索引导入进行中，跳过本次扫描（导入完成后刷新即可）',
          'GalleryStreamScanner',
        );
        return;
      }

      _isRunning = true;
      _shouldCancel = false;
      _pendingImageRecords.clear();
      _pendingMetadata.clear();
      _lastProgressEmit = null;
      _lastStateEmit = null;

      AppLogger.i(
        '[StreamScan] Starting stream scan: '
            '${rootDirs.map((d) => d.path).join(' | ')}',
        'GalleryStreamScanner',
      );

      try {
        // 1. 预加载数据库记录（只加载一次），获取已有元数据数量
        final existingMetadataCount = await _preloadExistingRecords();

        // 2. 【新增】检查数据一致性：删除数据库中不存在于文件系统的记录
        //    只处理位于当前已配置图库源内的记录，源被移除后其记录不受影响
        if (checkConsistency) {
          await _fixDataConsistency(rootDirs);
        }

        final retryPriorityPaths = buildRetryPriorityPaths(
          _existingMap,
          retryMissingMetadata: retryMissingMetadata,
          retryFailedMetadata: retryFailedMetadata,
        );

        // 3. 【关键修改】先遍历一遍统计总数（让用户看到固定的总进度）
        AppLogger.i(
          '[StreamScan] Counting total files...',
          'GalleryStreamScanner',
        );
        final totalFiles = await _countTotalFiles(rootDirs);
        AppLogger.i(
          '[StreamScan] Total files to scan: $totalFiles',
          'GalleryStreamScanner',
        );

        // 4. 启动扫描状态管理器（使用固定的总文件数）
        // 使用异步版本确保与 ScanStateManager 的状态同步
        final scanStarted = await _stateManager.startScanAsync(
          type: ScanType.incremental,
          rootPath: rootDirs.first.path,
          total: totalFiles, // 【修复】使用固定的总数
          existingInDatabase: _existingMap.length,
          metadataCacheCount: existingMetadataCount,
        );

        if (!scanStarted) {
          AppLogger.w(
            '[StreamScan] Scan start was rejected by ScanStateManager',
            'GalleryStreamScanner',
          );
          return;
        }

        // 5. 流式处理：发现文件 → 立即处理
        // 【修复】使用预统计的总数，让进度显示更直观（如 0/8751 → 8751/8751）
        var stats = StreamScanStats(totalDiscovered: totalFiles);
        var processedCount = 0;
        var skippedCount = 0; // 【调试】统计跳过的文件数

        await for (final file in _scanDirectory(
          rootDirs,
          priorityPaths: retryPriorityPaths,
        )) {
          if (_shouldCancel) break;

          // 立即处理这个文件
          final result = await _processSingleFile(
            file,
            stats,
            retryMissingMetadata: retryMissingMetadata,
            retryFailedMetadata: retryFailedMetadata,
          );

          // 更新统计
          processedCount++;
          final isProcessed =
              result.stage == FileProcessingStage.completed ||
              result.stage == FileProcessingStage.error;
          final isSkipped = result.stage == FileProcessingStage.skipped;
          final isError = result.stage == FileProcessingStage.error;

          if (isSkipped) skippedCount++;

          stats = stats.copyWith(
            processed: isProcessed ? stats.processed + 1 : stats.processed,
            skipped: isSkipped ? stats.skipped + 1 : stats.skipped,
            withMetadata: result.metadata != null && result.metadata!.hasData
                ? stats.withMetadata + 1
                : stats.withMetadata,
            failed: isError ? stats.failed + 1 : stats.failed,
            currentFile: p.basename(file.path),
            // 【修复】不覆盖 currentStage，保留 _processSingleFile 内部设置的阶段
            progress: totalFiles > 0 ? processedCount / totalFiles : 0.0,
          );

          // 【调试】每100个文件打印一次跳过统计
          if (processedCount % 100 == 0) {
            AppLogger.d(
              '[StreamScan] Progress: $processedCount/$totalFiles, '
                  'skipped: $skippedCount (${(skippedCount / processedCount * 100).toStringAsFixed(1)}%)',
              'GalleryStreamScanner',
            );
          }

          // 发送结果（result 流无监听者，保持逐文件；stats 流节流）
          _resultController.add(result);
          _emitProgress(stats);

          // 回调
          onFileProcessed?.call(result, stats);

          // 更新 ScanStateManager（节流，避免每文件 setState）
          _updateScanState(
            processed: processedCount,
            total: totalFiles,
            currentFile: p.basename(file.path),
            phase: _stageToPhase(result.stage),
          );

          // 【批处理】缓冲满一批就事务刷盘，每批发一次真正的 yield
          if (_pendingImageRecords.length >= _flushBatchSize) {
            await _flushBatch();
            await Future.delayed(const Duration(milliseconds: 1));
          } else if (processedCount % 100 == 0) {
            // 批间低频率让出事件循环
            await Future.delayed(Duration.zero);
          }
        }

        // 扫描完成：收尾批次 + 强制最后一次进度通知
        await _flushBatch();
        _emitProgress(stats, force: true);
        _updateScanState(
          processed: processedCount,
          total: totalFiles,
          currentFile: '',
          phase: ScanPhase.completed,
          force: true,
        );
        _stateManager.completeScan();
        AppLogger.i(
          '[StreamScan] Scan completed: ${stats.totalDiscovered} discovered, '
              '${stats.processed} processed, ${stats.withMetadata} with metadata, '
              '${stats.skipped} skipped (${(stats.skipped / stats.totalDiscovered * 100).toStringAsFixed(1)}%)',
          'GalleryStreamScanner',
        );
      } catch (e, stack) {
        AppLogger.e(
          '[StreamScan] Scan failed',
          e,
          stack,
          'GalleryStreamScanner',
        );
        _stateManager.errorScan(e.toString());
      } finally {
        _isRunning = false;
        // 批处理缓冲在异常/取消时丢弃（最多一帧的未落库记录，下次扫描补齐）
        _pendingImageRecords.clear();
        _pendingMetadata.clear();
        // 注意：不要在这里关闭 StreamController，因为它们是广播流
        // 在单例模式下需要保持开放以支持多次扫描
      }
    });
  }

  /// 关闭扫描器并释放资源
  ///
  /// ⚠️ 警告：只有在确定不再使用扫描器时才调用此方法
  /// 单例模式下通常不需要手动关闭
  Future<void> dispose() async {
    await _scanLock.synchronized(() async {
      _shouldCancel = true;
      _isRunning = false;
      if (!_statsController.isClosed) {
        await _statsController.close();
      }
      if (!_resultController.isClosed) {
        await _resultController.close();
      }
    });
  }

  /// 取消扫描
  void cancel() {
    _shouldCancel = true;
    AppLogger.i('[StreamScan] Scan cancelled by user', 'GalleryStreamScanner');
  }

  /// 文件签名到路径的映射（用于检测移动/重命名）
  /// 签名格式: "size:mtime"
  final Map<String, String> _signatureToPath = {};

  /// 路径到文件ID的映射（用于移动检测）
  final Map<String, int> _pathToId = {};

  /// 预加载现有记录
  Future<int> _preloadExistingRecords() async {
    final existingRecords = await _dataSource.getAllImages();
    _existingMap.clear();
    _signatureToPath.clear();
    _pathToId.clear();
    _deletedPathKeys.clear();
    var metadataCount = 0;

    // 软删路径集合：扫描时跳过（文件可能在盘上，但 DB 已标记删除）
    try {
      final deletedPaths = await _dataSource.getDeletedImagePaths();
      _deletedPathKeys
        ..clear()
        ..addAll(deletedPaths.map(galleryFilePathKey));
    } catch (e) {
      AppLogger.w(
        '[StreamScan] Failed to load deleted paths: $e',
        'GalleryStreamScanner',
      );
    }

    for (final img in existingRecords) {
      if (!img.isDeleted && img.id != null) {
        _existingMap[img.filePath] = (
          img.fileSize,
          img.modifiedAt.millisecondsSinceEpoch,
          img.id!,
          img.metadataStatus,
          img.lastScannedAt,
        );
        _pathToId[img.filePath] = img.id!;

        // 建立签名映射（用于检测移动/重命名）
        final signature =
            '${img.fileSize}:${img.modifiedAt.millisecondsSinceEpoch}';
        _signatureToPath[signature] = img.filePath;

        // 统计已有元数据的记录
        if (img.metadataStatus == MetadataStatus.success) {
          metadataCount++;
        }
      }
    }
    AppLogger.i(
      '[StreamScan] Preloaded ${_existingMap.length} existing records, '
          '$metadataCount with metadata',
      'GalleryStreamScanner',
    );
    return metadataCount;
  }

  /// 修复数据一致性
  ///
  /// 检查数据库中所有未删除的记录，如果文件不存在则标记为已删除
  /// 只处理位于当前已配置图库源内的记录——不在任何已配置源下的记录
  /// 一律不动（防止源被移除后记录被清）
  /// 返回被标记为删除的记录数量
  Future<int> _fixDataConsistency(List<Directory> rootDirs) async {
    AppLogger.i(
      '[StreamScan] Checking data consistency...',
      'GalleryStreamScanner',
    );

    final orphanedPaths = <String>[];

    for (final entry in _existingMap.entries) {
      if (_shouldCancel) break;

      final path = entry.key;

      // 只检查位于当前已配置源内的记录
      final isWithinRoots = rootDirs.any(
        (dir) => galleryPathIsWithin(dir.path, path),
      );
      if (!isWithinRoots) {
        AppLogger.d(
          '[StreamScan] Skip orphan check (outside configured roots): $path',
          'GalleryStreamScanner',
        );
        continue;
      }

      final file = File(path);

      if (!await file.exists()) {
        orphanedPaths.add(path);
      }
    }

    if (orphanedPaths.isNotEmpty) {
      await _dataSource.batchMarkAsDeleted(orphanedPaths);
      // 从本地缓存中移除
      for (final path in orphanedPaths) {
        _existingMap.remove(path);
      }
      AppLogger.i(
        '[StreamScan] Marked ${orphanedPaths.length} orphaned records as deleted',
        'GalleryStreamScanner',
      );
    }

    return orphanedPaths.length;
  }

  /// 处理单个文件
  Future<FileProcessingResult> _processSingleFile(
    File file,
    StreamScanStats stats, {
    bool retryMissingMetadata = false,
    bool retryFailedMetadata = false,
  }) async {
    final path = file.path;
    final fileName = p.basename(path);

    // 软删文件跳过：文件仍在盘上（删除池），扫描不得重新索引，
    // 否则 upsert 会复位 is_deleted 导致「已删」图复活。
    if (_deletedPathKeys.contains(galleryFilePathKey(path))) {
      _stateManager.incrementSkippedCount();
      return FileProcessingResult(
        path: path,
        stage: FileProcessingStage.skipped,
      );
    }

    // 【修复】在 try 外获取 existing，确保 catch 块也能访问
    final existing = _existingMap[path];

    try {
      // 阶段1: 索引检查
      _updateStage(stats, FileProcessingStage.indexing, fileName);

      final stat = await file.stat();

      // 【调试日志】打印缓存命中情况
      if (existing != null) {
        final (_, _, _, metadataStatus, lastScannedAt) = existing;
        AppLogger.d(
          '[StreamScan] Cache hit: $fileName, '
              'status=${metadataStatus.name}, lastScannedAt=$lastScannedAt',
          'GalleryStreamScanner',
        );
      } else {
        AppLogger.d(
          '[StreamScan] Cache miss: $fileName',
          'GalleryStreamScanner',
        );
      }

      // 【新增】检测移动/重命名：检查是否有相同签名（size+mtime）的旧记录
      final signature = '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
      final movedFromPath = _signatureToPath[signature];
      final bool isMoved = movedFromPath != null && movedFromPath != path;

      final bool needsUpdate;
      if (existing == null && !isMoved) {
        needsUpdate = true; // 真正的新文件
      } else if (isMoved) {
        needsUpdate = true; // 移动/重命名，需要更新路径
      } else if (existing != null) {
        final (existingSize, existingMtime, _, metadataStatus, lastScannedAt) =
            existing;
        if (stat.size != existingSize ||
            stat.modified.millisecondsSinceEpoch != existingMtime) {
          needsUpdate = true; // 文件已变化
        } else if (lastScannedAt == null) {
          needsUpdate = true; // 从未扫描（迁移后的旧数据）
        } else if (metadataStatus == MetadataStatus.none) {
          needsUpdate = retryMissingMetadata;
          AppLogger.d(
            retryMissingMetadata
                ? '[StreamScan] Retry missing metadata: $fileName, '
                      'last scanned at $lastScannedAt'
                : '[StreamScan] Skip re-scan (no metadata): $fileName, '
                      'last scanned at $lastScannedAt',
            'GalleryStreamScanner',
          );
        } else if (metadataStatus == MetadataStatus.failed) {
          needsUpdate = retryFailedMetadata;
          AppLogger.d(
            retryFailedMetadata
                ? '[StreamScan] Retry failed metadata: $fileName, '
                      'last scanned at $lastScannedAt'
                : '[StreamScan] Skip re-scan (failed metadata): $fileName, '
                      'last scanned at $lastScannedAt',
            'GalleryStreamScanner',
          );
        } else {
          needsUpdate = false; // 无需处理
        }
      } else {
        needsUpdate = false;
      }

      if (!needsUpdate) {
        // 【新增】增加跳过计数
        _stateManager.incrementSkippedCount();
        return FileProcessingResult(
          path: path,
          stage: FileProcessingStage.skipped,
        );
      }

      // 【新增】处理移动/重命名：直接更新路径，不重新提取元数据
      if (isMoved) {
        final oldImageId = _pathToId[movedFromPath];
        // 【修复】检查目标路径是否已存在于数据库中，避免 UNIQUE 约束冲突
        final targetPathExists = _existingMap.containsKey(path);
        if (oldImageId != null && !targetPathExists) {
          AppLogger.d(
            '[StreamScan] Detected move/rename: $movedFromPath -> $path',
            'GalleryStreamScanner',
          );

          // 更新文件路径
          await _dataSource.updateFilePath(
            oldImageId,
            path,
            newFileName: fileName,
          );

          // 更新本地缓存
          final oldRecord = _existingMap.remove(movedFromPath);
          if (oldRecord != null) {
            _existingMap[path] = (
              stat.size,
              stat.modified.millisecondsSinceEpoch,
              oldImageId,
              oldRecord.$4,
              DateTime.now(),
            );
          }
          _pathToId.remove(movedFromPath);
          _pathToId[path] = oldImageId;

          // 清除该签名的映射（避免重复匹配）
          _signatureToPath.remove(signature);

          return FileProcessingResult(
            path: path,
            stage: FileProcessingStage.completed,
            isNewFile: false,
            metadataUpdated: false,
          );
        }
      }

      // 阶段2: 提取元数据（仅对真正的新文件或变更文件）
      // 【隔离解析】走 getMetadataForScan：缓存命中快速路径，
      // 未命中交给 Isolate worker 池（读文件 + PNG 解码 + stealth LSB
      // 提取全部在 worker 内），UI isolate 不再被逐像素解码阻塞
      _updateStage(stats, FileProcessingStage.extracting, fileName);
      final metadata = await _metadataService.getMetadataForScan(file.path);

      // 阶段3: 缓冲写入（不直接落库，攒满一批由 _flushBatch 事务刷盘）
      _updateStage(stats, FileProcessingStage.caching, fileName);

      final isNewFile = existing == null;
      final metadataStatus = metadata != null && metadata.hasData
          ? MetadataStatus.success
          : MetadataStatus.failed;

      // 入批处理缓冲（image_id 在批量刷盘后回填）
      final modifiedAt = stat.modified;
      _pendingImageRecords.add(
        GalleryImageRecord(
          filePath: path,
          fileName: fileName,
          fileSize: stat.size,
          width: metadata?.width,
          height: metadata?.height,
          aspectRatio: _calculateAspectRatio(metadata?.width, metadata?.height),
          createdAt: modifiedAt,
          modifiedAt: modifiedAt,
          indexedAt: DateTime.now(),
          lastScannedAt: DateTime.now(),
          dateYmd:
              modifiedAt.year * 10000 + modifiedAt.month * 100 + modifiedAt.day,
          resolutionKey: metadata?.width != null && metadata?.height != null
              ? '${metadata!.width}x${metadata.height}'
              : null,
          metadataStatus: metadataStatus,
        ),
      );
      _pendingMetadata.add(
        metadata != null && metadata.hasData ? metadata : null,
      );

      // 阶段4: 完成（DB 与内存缓存的落库/回填在 _flushBatch 中完成）
      return FileProcessingResult(
        path: path,
        stage: FileProcessingStage.completed,
        metadata: metadata,
        isNewFile: isNewFile,
        metadataUpdated: metadata != null && metadata.hasData,
      );
    } catch (e) {
      AppLogger.w(
        '[StreamScan] Error processing $fileName: $e',
        'GalleryStreamScanner',
      );

      // 【修复】增加失败计数
      _stateManager.incrementFailedCount();

      // 【修复】即使处理失败，也更新缓存标记为已扫描
      // 避免每次扫描都重复处理有问题的文件
      if (existing != null) {
        final (existingSize, existingMtime, existingId, _, _) = existing;
        _existingMap[path] = (
          existingSize,
          existingMtime,
          existingId,
          MetadataStatus.failed,
          DateTime.now(), // 标记为已扫描，即使失败
        );
      }

      return FileProcessingResult(
        path: path,
        stage: FileProcessingStage.error,
        error: e.toString(),
      );
    }
  }

  /// 更新当前阶段
  ///
  /// 【重要】同时更新 _statsController 和 ScanStateManager，
  /// 确保 UI 能实时看到阶段变化（走 250ms 节流，避免高频 setState）
  void _updateStage(
    StreamScanStats stats,
    FileProcessingStage stage,
    String fileName,
  ) {
    _emitProgress(stats.copyWith(currentStage: stage, currentFile: fileName));

    _updateScanState(currentFile: fileName, phase: _stageToPhase(stage));
  }

  /// 批量刷盘：图片记录 + 元数据 + FTS 一次事务落库（分批 500 条内层）
  ///
  /// 返回的 image_id 顺序与 [_pendingImageRecords] 对齐，
  /// 用于回填 [_existingMap]/[_pathToId]（下次扫描 skip 判定的基础）。
  Future<void> _flushBatch() async {
    if (_pendingImageRecords.isEmpty) return;

    final records = List<GalleryImageRecord>.of(_pendingImageRecords);
    final metadataList = List<NaiImageMetadata?>.of(_pendingMetadata);
    _pendingImageRecords.clear();
    _pendingMetadata.clear();

    final ids = await _dataSource.batchUpsertImages(records);

    // 元数据批量写入（image_id 在刷盘后回填）
    final metadataEntries = <MapEntry<int, NaiImageMetadata>>[];
    final metadataPaths = <String>[];
    for (var i = 0; i < records.length; i++) {
      final metadata = metadataList[i];
      if (metadata != null && metadata.hasData) {
        metadataEntries.add(MapEntry(ids[i], metadata));
        metadataPaths.add(records[i].filePath);
      }
    }
    if (metadataEntries.isNotEmpty) {
      await _dataSource.batchUpsertMetadata(metadataEntries);
      for (var i = 0; i < metadataEntries.length; i++) {
        await _metadataService.cacheMetadata(
          metadataPaths[i],
          metadataEntries[i].value,
        );
        _stateManager.incrementMetadataCacheCount();
      }
    }

    // 回填内存缓存（lastScannedAt 确保下次扫描跳过已处理文件）
    final now = DateTime.now();
    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      final id = ids[i];
      _existingMap[record.filePath] = (
        record.fileSize,
        record.modifiedAt.millisecondsSinceEpoch,
        id,
        record.metadataStatus,
        record.lastScannedAt ?? now,
      );
      _pathToId[record.filePath] = id;
    }

    AppLogger.d(
      '[StreamScan] Flushed batch: ${records.length} records, '
          '${metadataEntries.length} metadata',
      'GalleryStreamScanner',
    );
  }

  /// 进度通知节流（≥250ms 一次；[force] 时强制发送）
  void _emitProgress(StreamScanStats stats, {bool force = false}) {
    if (!force && _lastProgressEmit != null) {
      final elapsed = DateTime.now().difference(_lastProgressEmit!);
      if (elapsed < _progressEmitInterval) return;
    }
    _lastProgressEmit = DateTime.now();
    _statsController.add(stats);
  }

  /// ScanStateManager 进度节流（同上，避免每文件触发 UI setState）
  void _updateScanState({
    int? processed,
    int? total,
    String? currentFile,
    ScanPhase? phase,
    bool force = false,
  }) {
    if (!force && _lastStateEmit != null) {
      final elapsed = DateTime.now().difference(_lastStateEmit!);
      if (elapsed < _progressEmitInterval) return;
    }
    _lastStateEmit = DateTime.now();
    _stateManager.updateProgress(
      processed: processed,
      total: total,
      currentFile: currentFile,
      phase: phase,
    );
  }

  /// 计算宽高比
  double? _calculateAspectRatio(int? width, int? height) {
    if (width != null && height != null && height > 0) {
      return width / height;
    }
    return null;
  }

  /// 扫描目录（支持多图库源，串行遍历）
  Stream<File> _scanDirectory(
    List<Directory> rootDirs, {
    List<String> priorityPaths = const [],
  }) async* {
    const supportedExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
    final emittedKeys = <String>{};

    for (final path in priorityPaths) {
      if (_shouldCancel) break;

      final ext = p.extension(path).toLowerCase();
      if (!supportedExtensions.contains(ext)) {
        continue;
      }

      final file = File(path);
      if (!await file.exists()) {
        continue;
      }

      emittedKeys.add(galleryFilePathKey(path));
      yield file;
    }

    for (final rootDir in rootDirs) {
      if (_shouldCancel) break;

      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (_shouldCancel) break;

        if (entity is File) {
          // 跳过缩略图
          if (entity.path.contains(
                '${Platform.pathSeparator}.thumbs${Platform.pathSeparator}',
              ) ||
              entity.path.contains('.thumb.')) {
            continue;
          }

          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext) &&
              emittedKeys.add(galleryFilePathKey(entity.path))) {
            yield entity;
          }
        }
      }
    }
  }

  /// 统计总文件数（预扫描，多源累计）
  ///
  /// 在开始处理前先遍历一遍目录，统计总文件数
  /// 这样可以让用户看到固定的进度（如 0/8751 → 8751/8751）
  Future<int> _countTotalFiles(List<Directory> rootDirs) async {
    const supportedExtensions = ['.png', '.jpg', '.jpeg', '.webp'];
    var count = 0;
    final countedKeys = <String>{};

    for (final rootDir in rootDirs) {
      if (_shouldCancel) break;

      await for (final entity in rootDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (_shouldCancel) break;

        if (entity is File) {
          // 跳过缩略图
          if (entity.path.contains(
                '${Platform.pathSeparator}.thumbs${Platform.pathSeparator}',
              ) ||
              entity.path.contains('.thumb.')) {
            continue;
          }

          final ext = p.extension(entity.path).toLowerCase();
          if (supportedExtensions.contains(ext) &&
              countedKeys.add(galleryFilePathKey(entity.path))) {
            count++;
          }
        }
      }
    }

    return count;
  }

  /// 转换阶段到 ScanPhase
  ScanPhase _stageToPhase(FileProcessingStage stage) {
    switch (stage) {
      case FileProcessingStage.discovered:
      case FileProcessingStage.indexing:
        return ScanPhase.scanning;
      case FileProcessingStage.extracting:
        return ScanPhase.parsing;
      case FileProcessingStage.caching:
        return ScanPhase.indexing;
      case FileProcessingStage.completed:
      case FileProcessingStage.skipped:
        return ScanPhase.completed;
      case FileProcessingStage.error:
        return ScanPhase.idle;
    }
  }
}

List<String> buildRetryPriorityPaths(
  Map<String, ExistingFileCacheEntry> existingMap, {
  required bool retryMissingMetadata,
  required bool retryFailedMetadata,
}) {
  final candidates =
      existingMap.entries.where((entry) {
        final status = entry.value.$4;
        return (retryMissingMetadata && status == MetadataStatus.none) ||
            (retryFailedMetadata && status == MetadataStatus.failed);
      }).toList()..sort((a, b) {
        final aScannedAt = a.value.$5;
        final bScannedAt = b.value.$5;

        if (aScannedAt == null && bScannedAt == null) {
          return a.key.compareTo(b.key);
        }
        if (aScannedAt == null) return -1;
        if (bScannedAt == null) return 1;

        final compare = aScannedAt.compareTo(bScannedAt);
        if (compare != 0) {
          return compare;
        }

        return a.key.compareTo(b.key);
      });

  return candidates.map((entry) => entry.key).toList(growable: false);
}

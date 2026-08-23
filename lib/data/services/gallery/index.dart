/// 本地画廊服务统一导出文件
library;
///
/// 此文件提供所有画廊相关服务的统一入口，简化导入路径。
///
/// 使用示例:
/// ```dart
/// import 'package:nai_launcher/data/services/gallery/index.dart';
///
/// // 使用流式扫描器
/// final scanner = GalleryStreamScanner(dataSource: dataSource);
///
/// // 使用过滤服务
/// final filterService = GalleryFilterService(dataSource);
/// ```

// 扫描配置和状态
export 'scan_config.dart' show
    ScanPriority,
    ScanConfig,
    ScanType,
    ScanPhase;

// 扫描状态相关
export 'scan_state_manager.dart' show
    ScanStatus,
    ScanProgressInfo;

// 扫描状态管理
export 'scan_state_manager.dart' show
    ScanStateManager,
    ScanStatus,
    ScanProgressCallback,
    ScanProgressInfo;

// 流式扫描器（统一扫描逻辑）
export 'gallery_stream_scanner.dart' show
    GalleryStreamScanner,
    FileProcessingStage,
    FileProcessingResult,
    StreamScanStats;

// 过滤服务
export 'gallery_filter_service.dart' show
    GalleryFilterService,
    FilterCriteria;

// 标签索引导入（外部 JSONL 索引）
export 'tag_index_import_service.dart' show
    TagIndexImportService,
    TagIndexImportResult,
    TagIndexImportException,
    findTagIndexFileForRoot,
    tagIndexDirectoryName,
    tagIndexFileName;

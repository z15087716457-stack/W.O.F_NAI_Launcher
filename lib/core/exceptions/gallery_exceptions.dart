/// 画廊异常体系
///
/// 为本地画廊模块提供统一的异常处理机制
/// 所有异常都包含错误码和本地化消息键，便于 UI 层显示友好错误信息
library;

/// 画廊异常基类
abstract class GalleryException implements Exception {
  /// 错误码
  final String code;

  /// 错误消息（技术详情）
  final String message;

  /// 本地化消息键
  final String? localizationKey;

  /// 原始异常
  final Object? cause;

  const GalleryException({
    required this.code,
    required this.message,
    this.localizationKey,
    this.cause,
  });

  @override
  String toString() {
    if (cause != null) {
      return '$runtimeType [$code]: $message (caused by: $cause)';
    }
    return '$runtimeType [$code]: $message';
  }
}

/// 画廊未初始化异常
///
/// 当尝试使用未初始化的画廊服务时抛出
class GalleryNotInitializedException extends GalleryException {
  const GalleryNotInitializedException({
    super.message = 'Gallery service has not been initialized',
    super.cause,
  }) : super(
         code: 'GALLERY_NOT_INITIALIZED',
         localizationKey: 'gallery_error_not_initialized',
       );
}

/// 画廊权限拒绝异常
///
/// 当无法访问图片文件夹时抛出
class GalleryPermissionDeniedException extends GalleryException {
  /// 被拒绝的路径
  final String? path;

  const GalleryPermissionDeniedException({
    this.path,
    super.message = 'Permission denied to access gallery folder',
    super.cause,
  }) : super(
         code: 'GALLERY_PERMISSION_DENIED',
         localizationKey: 'gallery_error_permission_denied',
       );
}

/// 画廊扫描异常
///
/// 当文件扫描过程中发生错误时抛出
class GalleryScanException extends GalleryException {
  /// 扫描失败的文件路径
  final String? filePath;

  /// 已扫描文件数
  final int? scannedCount;

  /// 总文件数
  final int? totalCount;

  const GalleryScanException({
    this.filePath,
    this.scannedCount,
    this.totalCount,
    required super.message,
    super.cause,
  }) : super(
         code: 'GALLERY_SCAN_ERROR',
         localizationKey: 'gallery_error_scan_failed',
       );

  /// 创建批量扫描错误
  factory GalleryScanException.batch({
    required int errorCount,
    required int totalCount,
    List<String>? sampleErrors,
  }) {
    return GalleryScanException(
      message:
          'Batch scan completed with $errorCount errors out of $totalCount files',
      cause: sampleErrors?.isNotEmpty == true
          ? 'Sample: ${sampleErrors!.first}'
          : null,
    );
  }
}

/// 画廊元数据异常
///
/// 当元数据解析或操作失败时抛出
class GalleryMetadataException extends GalleryException {
  /// 相关的图片路径
  final String? imagePath;

  /// 元数据解析阶段
  final MetadataErrorPhase? phase;

  const GalleryMetadataException({
    this.imagePath,
    this.phase,
    required super.message,
    super.cause,
  }) : super(
         code: 'GALLERY_METADATA_ERROR',
         localizationKey: 'gallery_error_metadata_failed',
       );
}

/// 元数据错误阶段
enum MetadataErrorPhase {
  parsing, // 解析阶段
  caching, // 缓存阶段
  database, // 数据库操作阶段
  serialization, // 序列化阶段
}

/// 画廊过滤异常
///
/// 当过滤操作失败时抛出
class GalleryFilterException extends GalleryException {
  /// 失败的过滤条件
  final String? filterCriteria;

  const GalleryFilterException({
    this.filterCriteria,
    required super.message,
    super.cause,
  }) : super(
         code: 'GALLERY_FILTER_ERROR',
         localizationKey: 'gallery_error_filter_failed',
       );
}

/// 画廊数据库异常
///
/// 当数据库操作失败时抛出
class GalleryDatabaseException extends GalleryException {
  /// 失败的 SQL 操作类型
  final DatabaseOperation? operation;

  const GalleryDatabaseException({
    this.operation,
    required super.message,
    super.cause,
  }) : super(
         code: 'GALLERY_DATABASE_ERROR',
         localizationKey: 'gallery_error_database_failed',
       );
}

/// 数据库操作类型
enum DatabaseOperation { query, insert, update, delete, batch, transaction }

/// 画廊文件系统异常
///
/// 当文件系统操作失败时抛出
class GalleryFileSystemException extends GalleryException {
  /// 失败的文件路径
  final String? path;

  /// 文件系统操作类型
  final FileSystemOperation? operation;

  const GalleryFileSystemException({
    this.path,
    this.operation,
    required super.message,
    super.cause,
  }) : super(
         code: 'GALLERY_FILESYSTEM_ERROR',
         localizationKey: 'gallery_error_filesystem_failed',
       );
}

/// 文件系统操作类型
enum FileSystemOperation { read, write, delete, move, copy, list, stat }

/// 画廊取消操作异常
///
/// 当用户取消长时间运行的操作时抛出
class GalleryCancelledException extends GalleryException {
  /// 已完成的进度（0-1）
  final double? progress;

  const GalleryCancelledException({
    this.progress,
    super.message = 'Operation was cancelled by user',
  }) : super(
         code: 'GALLERY_CANCELLED',
         localizationKey: 'gallery_error_cancelled',
       );
}

/// 异常转换工具
class GalleryExceptionConverter {
  GalleryExceptionConverter._();

  /// 将任意异常转换为 GalleryException
  static GalleryException convert(Object error, {String? context}) {
    if (error is GalleryException) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // 根据错误内容智能识别类型
    if (errorString.contains('permission') ||
        errorString.contains('access denied')) {
      return GalleryPermissionDeniedException(
        path: context,
        message: 'Permission denied${context != null ? ' for $context' : ''}',
        cause: error,
      );
    }

    if (errorString.contains('database') ||
        errorString.contains('sql') ||
        errorString.contains('sqlite')) {
      return GalleryDatabaseException(
        message: 'Database error${context != null ? ' in $context' : ''}',
        cause: error,
      );
    }

    if (errorString.contains('metadata') ||
        errorString.contains('parse') ||
        errorString.contains('json')) {
      return GalleryMetadataException(
        imagePath: context,
        message: 'Metadata error${context != null ? ' for $context' : ''}',
        cause: error,
      );
    }

    if (errorString.contains('cancel') || errorString.contains('abort')) {
      return const GalleryCancelledException();
    }

    // 默认归类为扫描异常
    return GalleryScanException(
      message:
          'Unexpected error${context != null ? ' in $context' : ''}: $error',
      cause: error,
    );
  }
}

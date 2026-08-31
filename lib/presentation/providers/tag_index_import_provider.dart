import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/database/datasources/gallery_data_source.dart';
import '../../core/utils/app_logger.dart';
import '../../data/services/gallery/tag_index_import_service.dart';

/// 标签索引导入进度状态
class TagIndexImportState {
  /// 是否正在导入
  final bool isImporting;

  /// 已处理行数
  final int processedLines;

  /// 总行数（第一遍预统计）
  final int totalLines;

  /// 导入结果（完成后非空）
  final TagIndexImportResult? result;

  /// 错误信息（失败时非空）
  final String? error;

  /// 是否因扫描进行中而被拒绝（UI 显示专门的 i18n 提示）
  final bool blockedByScan;

  const TagIndexImportState({
    this.isImporting = false,
    this.processedLines = 0,
    this.totalLines = 0,
    this.result,
    this.error,
    this.blockedByScan = false,
  });

  /// 当前进度 (0.0 - 1.0)
  double get progress =>
      totalLines > 0 ? (processedLines / totalLines).clamp(0.0, 1.0) : 0.0;

  TagIndexImportState copyWith({
    bool? isImporting,
    int? processedLines,
    int? totalLines,
    TagIndexImportResult? result,
    String? error,
    bool? blockedByScan,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return TagIndexImportState(
      isImporting: isImporting ?? this.isImporting,
      processedLines: processedLines ?? this.processedLines,
      totalLines: totalLines ?? this.totalLines,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      blockedByScan: blockedByScan ?? this.blockedByScan,
    );
  }
}

/// 标签索引导入 Notifier
///
/// 参照 [GalleryScanProgressNotifier] 的模式：StateNotifier + 状态对象，
/// 设置页「图库源管理」卡监听该状态显示进度。
class TagIndexImportNotifier extends StateNotifier<TagIndexImportState> {
  final Ref _ref;

  TagIndexImportNotifier(this._ref) : super(const TagIndexImportState());

  /// 是否正在导入（防止并发导入）
  bool get isImporting => state.isImporting;

  /// 导入指定 JSONL 索引文件
  ///
  /// 返回导入结果；导入被拒绝（已在导入中）或失败时返回 null。
  Future<TagIndexImportResult?> startImport(String jsonlPath) async {
    if (state.isImporting) {
      AppLogger.w('[TagIndexImport] 已有导入任务进行中', 'TagIndexImport');
      return null;
    }

    state = const TagIndexImportState(isImporting: true);

    try {
      final dbManager = await _ref.read(databaseManagerProvider.future);
      final dataSource = dbManager.getDataSource<GalleryDataSource>('gallery');
      if (dataSource == null) {
        throw StateError('GalleryDataSource 不可用');
      }

      final service = TagIndexImportService(dataSource);
      final result = await service.importFromJsonl(
        jsonlPath,
        onProgress: (processed, total) {
          if (mounted) {
            state = state.copyWith(
              processedLines: processed,
              totalLines: total,
            );
          }
        },
      );

      if (!mounted) return result;

      state = state.copyWith(
        isImporting: false,
        processedLines: result.totalLines,
        totalLines: result.totalLines,
        result: result,
        clearError: true,
      );

      return result;
    } on TagIndexImportBlockedByScanException {
      AppLogger.w('[TagIndexImport] 扫描进行中，导入被拒绝', 'TagIndexImport');
      if (mounted) {
        state = state.copyWith(
          isImporting: false,
          blockedByScan: true,
          clearError: true,
        );
      }
      return null;
    } catch (e, stack) {
      AppLogger.e('标签索引导入失败', e, stack, 'TagIndexImport');
      if (mounted) {
        state = state.copyWith(isImporting: false, error: e.toString());
      }
      return null;
    }
  }

  /// 重置状态
  void reset() {
    state = const TagIndexImportState();
  }
}

/// 标签索引导入进度 Provider
final tagIndexImportProvider =
    StateNotifierProvider<TagIndexImportNotifier, TagIndexImportState>(
      (ref) => TagIndexImportNotifier(ref),
    );

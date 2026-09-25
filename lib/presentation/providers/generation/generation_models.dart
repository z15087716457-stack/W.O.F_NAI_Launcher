import 'dart:async';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/models/image/image_stream_chunk.dart';
import '../../../data/models/image/image_operation.dart';
import '../../../data/models/image/image_params.dart';

enum GeneratedImageKind { completed, failedStreamSnapshot }

/// 生成的图像（带唯一ID）
class GeneratedImage {
  final String id;
  final Uint8List bytes;
  final DateTime createdAt;
  final int width;
  final int height;
  final GeneratedImageKind kind;
  final NaiImageMetadata? metadata;
  final ImageOperation? operation;
  final Uint8List? originalBytes;

  /// 已保存的文件路径（如果有）
  /// 当图像被保存到磁盘后，此字段会被填充
  final String? filePath;

  /// 所属生成运行 ID（同一批次分组的依据；外部登记图可为 null）。
  final int? generationRunId;

  /// 批次内槽位序号（0-based，按生成顺序稳定排序）。
  final int? batchIndex;

  GeneratedImage({
    required this.id,
    required this.bytes,
    required this.width,
    required this.height,
    DateTime? createdAt,
    this.kind = GeneratedImageKind.completed,
    this.metadata,
    this.operation,
    this.originalBytes,
    this.filePath,
    this.generationRunId,
    this.batchIndex,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 创建新的生成图像（自动生成ID）
  factory GeneratedImage.create(
    Uint8List bytes, {
    required int width,
    required int height,
    GeneratedImageKind kind = GeneratedImageKind.completed,
    NaiImageMetadata? metadata,
    ImageParams? sourceParams,
    ImageOperation? operation,
    Uint8List? originalBytes,
    int? generationRunId,
    int? batchIndex,
  }) {
    final encodedSize = NaiResolutionAdapter.readImageSize(bytes);
    return GeneratedImage(
      id: const Uuid().v4(),
      bytes: bytes,
      width: encodedSize?.$1 ?? width,
      height: encodedSize?.$2 ?? height,
      kind: kind,
      metadata: metadata,
      operation:
          operation ??
          (sourceParams == null
              ? null
              : ImageOperation.fromParams(sourceParams)),
      originalBytes: originalBytes ?? sourceParams?.sourceImage,
      generationRunId: generationRunId,
      batchIndex: batchIndex,
    );
  }

  /// 创建已保存到文件的图像副本
  GeneratedImage copyWithFilePath(String path) {
    return GeneratedImage(
      id: id,
      bytes: bytes,
      width: width,
      height: height,
      createdAt: createdAt,
      kind: kind,
      metadata: metadata,
      filePath: path,
      operation: operation,
      originalBytes: originalBytes,
      generationRunId: generationRunId,
      batchIndex: batchIndex,
    );
  }

  /// 回填批次归属（生成服务产出的图像由 provider 统一打 runId/batchIndex）。
  GeneratedImage copyWith({int? generationRunId, int? batchIndex}) {
    return GeneratedImage(
      id: id,
      bytes: bytes,
      width: width,
      height: height,
      createdAt: createdAt,
      kind: kind,
      metadata: metadata,
      filePath: filePath,
      operation: operation,
      originalBytes: originalBytes,
      generationRunId: generationRunId ?? this.generationRunId,
      batchIndex: batchIndex ?? this.batchIndex,
    );
  }

  /// 获取宽高比
  double get aspectRatio => width / height;

  bool get isFailedStreamSnapshot =>
      kind == GeneratedImageKind.failedStreamSnapshot;

  bool get canSave => kind == GeneratedImageKind.completed;

  bool get canFavorite => kind == GeneratedImageKind.completed;

  bool get canUseAsGenerationInput => kind == GeneratedImageKind.completed;

  bool get canBulkSelect => kind == GeneratedImageKind.completed;

  bool get canDrag => kind == GeneratedImageKind.completed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedImage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 生成状态
enum GenerationStatus { idle, generating, completed, error, cancelled }

enum GenerationBatchEventKind { start, complete }

class GenerationBatchEvent {
  const GenerationBatchEvent({
    required this.kind,
    this.generationRunId = -1,
    required this.batchIndex,
    required this.slotStart,
    required this.slotCount,
    required this.totalSlots,
    this.images = const [],
    this.error,
    this.elapsedMs,
  });

  final GenerationBatchEventKind kind;
  final int generationRunId;
  final int batchIndex;
  final int slotStart;
  final int slotCount;
  final int totalSlots;
  final List<GeneratedImage> images;
  final Object? error;
  final int? elapsedMs;
}

typedef GenerationBatchCallback =
    FutureOr<void> Function(GenerationBatchEvent event);

/// 探索任务专用单张生成结果（`ImageGenerationNotifier.generateForExplore`）。
///
/// 与主生成链的区别在于能把单张结果带回给调用方（主 `generate()` 返回
/// void）。`filePath` 依赖自动保存开关；`imageBytes` 始终携带，
/// 供探索 run 目录自包含副本直写兜底。
class ExploreGenerationResult {
  const ExploreGenerationResult({
    required this.imageBytes,
    required this.seed,
    required this.elapsedMs,
    required this.imageWidth,
    required this.imageHeight,
    this.filePath,
  });

  final Uint8List imageBytes;
  final String? filePath;
  final int seed;
  final int elapsedMs;
  final int imageWidth;
  final int imageHeight;
}

/// 单个流式预览槽位。
class StreamPreviewSlot {
  const StreamPreviewSlot({
    required this.imageNumber,
    required this.totalImages,
    required this.progress,
    this.previewBytes,
    this.inpaintPreviewPlacement,
  });

  final int imageNumber;
  final int totalImages;
  final double progress;
  final Uint8List? previewBytes;
  final InpaintStreamPreviewPlacement? inpaintPreviewPlacement;

  StreamPreviewSlot copyWith({
    int? imageNumber,
    int? totalImages,
    double? progress,
    Uint8List? previewBytes,
    InpaintStreamPreviewPlacement? inpaintPreviewPlacement,
    bool clearInpaintPreviewPlacement = false,
  }) {
    return StreamPreviewSlot(
      imageNumber: imageNumber ?? this.imageNumber,
      totalImages: totalImages ?? this.totalImages,
      progress: progress ?? this.progress,
      previewBytes: previewBytes ?? this.previewBytes,
      inpaintPreviewPlacement: clearInpaintPreviewPlacement
          ? null
          : (inpaintPreviewPlacement ?? this.inpaintPreviewPlacement),
    );
  }
}

/// 图像生成状态
class ImageGenerationState {
  /// 从点击生成到完成保持不变，连接画布占位、预览帧与最终图片。
  final int? generationRunId;
  final GenerationStatus status;
  final List<GeneratedImage> currentImages;
  final List<GeneratedImage> history;
  final String? errorMessage;
  final double progress;
  final int currentImage; // 当前第几张 (1-based)
  final int totalImages; // 总共几张

  /// 流式预览图像（渐进式生成过程中的最新预览）
  final Uint8List? streamPreview;

  /// Inpaint 当前流式预览在原始图上的覆盖位置。
  final InpaintStreamPreviewPlacement? inpaintPreviewPlacement;

  /// 当前请求中的流式预览槽位（用于一次请求多张时稳定历史位置）。
  final List<StreamPreviewSlot> streamPreviewSlots;

  /// 当前批次的分辨率（点击生成时捕获）
  final int? batchWidth;
  final int? batchHeight;

  /// 中央区域显示的图像（独立于历史记录，清除历史时保留）
  final List<GeneratedImage> displayImages;

  /// 中央区域显示图像的分辨率
  final int? displayWidth;
  final int? displayHeight;

  const ImageGenerationState({
    this.generationRunId,
    this.status = GenerationStatus.idle,
    this.currentImages = const [],
    this.history = const [],
    this.errorMessage,
    this.progress = 0.0,
    this.currentImage = 0,
    this.totalImages = 0,
    this.streamPreview,
    this.inpaintPreviewPlacement,
    this.streamPreviewSlots = const [],
    this.batchWidth,
    this.batchHeight,
    this.displayImages = const [],
    this.displayWidth,
    this.displayHeight,
  });

  ImageGenerationState copyWith({
    int? generationRunId,
    GenerationStatus? status,
    List<GeneratedImage>? currentImages,
    List<GeneratedImage>? history,
    String? errorMessage,
    double? progress,
    int? currentImage,
    int? totalImages,
    Uint8List? streamPreview,
    InpaintStreamPreviewPlacement? inpaintPreviewPlacement,
    List<StreamPreviewSlot>? streamPreviewSlots,
    bool clearStreamPreview = false,
    bool clearInpaintPreviewPlacement = false,
    int? batchWidth,
    int? batchHeight,
    List<GeneratedImage>? displayImages,
    int? displayWidth,
    int? displayHeight,
  }) {
    return ImageGenerationState(
      generationRunId: generationRunId ?? this.generationRunId,
      status: status ?? this.status,
      currentImages: currentImages ?? this.currentImages,
      history: history ?? this.history,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
      currentImage: currentImage ?? this.currentImage,
      totalImages: totalImages ?? this.totalImages,
      streamPreview: clearStreamPreview
          ? null
          : (streamPreview ?? this.streamPreview),
      inpaintPreviewPlacement:
          clearStreamPreview || clearInpaintPreviewPlacement
          ? null
          : (inpaintPreviewPlacement ?? this.inpaintPreviewPlacement),
      streamPreviewSlots: clearStreamPreview
          ? (streamPreviewSlots ?? const [])
          : (streamPreviewSlots ?? this.streamPreviewSlots),
      batchWidth: batchWidth ?? this.batchWidth,
      batchHeight: batchHeight ?? this.batchHeight,
      displayImages: displayImages ?? this.displayImages,
      displayWidth: displayWidth ?? this.displayWidth,
      displayHeight: displayHeight ?? this.displayHeight,
    );
  }

  bool get isGenerating => status == GenerationStatus.generating;
  bool get hasImages => displayImages.isNotEmpty;

  /// 是否有流式预览图像
  bool get hasStreamPreview =>
      (streamPreview != null && streamPreview!.isNotEmpty) ||
      streamPreviewSlots.any((slot) => slot.previewBytes?.isNotEmpty == true);
}

extension ImageGenerationStateImages on ImageGenerationState {
  /// Images in the same order as the history panel: current batch first, then
  /// newest-to-oldest history, with duplicate ids removed.
  List<GeneratedImage> get mergedPanelImages {
    final seen = <String>{};
    return [
      for (final image in [...currentImages, ...history])
        if (seen.add(image.id)) image,
    ];
  }

  List<GeneratedImage> get selectableMergedImages =>
      mergedPanelImages.where((image) => image.canBulkSelect).toList();

  /// Resolves all state-backed drag/preview sources. [displayImages] must be
  /// checked separately because clearing history intentionally preserves it.
  GeneratedImage? findImageById(String? id) {
    if (id == null || id.isEmpty) return null;
    final seen = <String>{};
    for (final image in [...currentImages, ...history, ...displayImages]) {
      if (!seen.add(image.id)) continue;
      if (image.id == id) return image;
    }
    return null;
  }

  List<GeneratedImage> detailSequenceFor(GeneratedImage target) {
    final merged = mergedPanelImages;
    if (merged.any((image) => image.id == target.id)) return merged;

    final display = <GeneratedImage>[];
    final seen = <String>{};
    for (final image in displayImages) {
      if (seen.add(image.id)) display.add(image);
    }
    if (display.any((image) => image.id == target.id)) return display;
    return [target];
  }
}

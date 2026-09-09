import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../core/utils/drag_drop_utils.dart';
import '../../../core/utils/image_share_sanitizer.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../providers/share_image_settings_provider.dart';

Widget _buildGalleryDragFeedback({
  required BuildContext context,
  required WidgetRef ref,
  required LocalImageRecord record,
  required Uint8List? previewBytes,
  required ImageProvider? previewProvider,
  required double width,
  required String hintText,
  required bool enableFeedback,
  required Widget fallbackChild,
  int? selectedCount,
}) {
  final stripMetadata = ref
      .read(shareImageSettingsProvider)
      .effectiveStripMetadataForCopyAndDrag;
  final effectiveHintText = selectedCount != null && selectedCount > 1
      ? context.l10n.galleryDragCount(selectedCount)
      : hintText;

  final Widget baseFeedback;
  if (stripMetadata) {
    baseFeedback = buildProtectedImageDragFeedback(
      Theme.of(context),
      width: width,
      hintText: effectiveHintText,
    );
  } else if (!enableFeedback) {
    baseFeedback = fallbackChild;
  } else {
    baseFeedback = buildImageDragFeedback(
      Theme.of(context),
      ImageDragData.fromRecord(record, previewBytes: previewBytes),
      width: width,
      hintText: effectiveHintText,
      previewProvider: previewProvider,
    );
  }

  if (selectedCount != null && selectedCount > 1) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseFeedback,
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              context.l10n.galleryDragCount(selectedCount),
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  return baseFeedback;
}

/// 可拖拽图像卡片组件
///
/// 基于 super_drag_and_drop 实现，支持将本地图像拖拽到其他应用
/// 支持 PNG 图像数据和文件 URI 格式
class DraggableImageCard extends ConsumerStatefulWidget {
  /// 图像记录数据
  final LocalImageRecord record;

  /// 子组件（实际的卡片 UI）
  final Widget child;

  /// 是否启用拖拽功能
  final bool enabled;

  /// 可选的预览图像数据（字节）
  final Uint8List? previewBytes;

  /// 是否启用拖拽反馈预览
  final bool enableFeedback;

  /// 拖拽预览宽度
  final double feedbackWidth;

  /// 拖拽提示文字
  final String? feedbackHint;

  /// 拖拽时原位置组件的透明度
  final double dragOpacity;

  /// 多选态下的完整选中路径集（若本卡片处于多选集合中）
  final List<String>? selectedPaths;

  const DraggableImageCard({
    super.key,
    required this.record,
    required this.child,
    this.enabled = true,
    this.previewBytes,
    this.enableFeedback = true,
    this.feedbackWidth = 280,
    this.feedbackHint,
    this.dragOpacity = 0.3,
    this.selectedPaths,
  });

  @override
  ConsumerState<DraggableImageCard> createState() => _DraggableImageCardState();

  /// 创建拖拽包装器函数
  static Widget Function(Widget child) createDragWrapper({
    required LocalImageRecord record,
    List<String>? selectedPaths,
    Uint8List? previewBytes,
    bool enableFeedback = true,
    double feedbackWidth = 280,
    String? feedbackHint,
    double dragOpacity = 0.3,
  }) {
    return (Widget child) {
      return _DragWrapper(
        record: record,
        selectedPaths: selectedPaths,
        previewBytes: previewBytes,
        feedbackWidth: feedbackWidth,
        feedbackHint: feedbackHint,
        enableFeedback: enableFeedback,
        dragOpacity: dragOpacity,
        child: child,
      );
    };
  }
}

class _DraggableImageCardState extends ConsumerState<DraggableImageCard> {
  bool _isDragging = false;
  Uint8List? _previewBytes;
  ImageProvider? _previewProvider;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void didUpdateWidget(covariant DraggableImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewBytes != widget.previewBytes ||
        oldWidget.record.path != widget.record.path) {
      _initializePreview();
    }
  }

  void _initializePreview() {
    if (widget.previewBytes != null) {
      _setPreviewBytes(widget.previewBytes!);
      return;
    }

    if (widget.record.path.isNotEmpty) {
      _previewBytes = null;
      _previewProvider = FileImage(File(widget.record.path));
      return;
    }

    _previewBytes = null;
    _previewProvider = null;
  }

  void _setPreviewBytes(Uint8List bytes) {
    final provider = MemoryImage(bytes);
    _previewBytes = bytes;
    _previewProvider = provider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_previewProvider, provider)) return;
      unawaited(precacheImage(provider, context));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) {
        setState(() => _isDragging = true);
      },
      onPointerUp: (_) {
        setState(() => _isDragging = false);
      },
      onPointerCancel: (_) {
        setState(() => _isDragging = false);
      },
      child: DragItemWidget(
        allowedOperations: () => [DropOperation.copy],
        dragItemProvider: (request) => _createDragItem(),
        // 关键修复：每次调用时动态构建，确保使用最新的预览状态
        liftBuilder: (context, child) => _buildGalleryDragFeedback(
          context: context,
          ref: ref,
          record: widget.record,
          previewBytes: _previewBytes,
          previewProvider: _previewProvider,
          width: widget.feedbackWidth,
          hintText:
              widget.feedbackHint ?? context.l10n.localGallery_dragToShare,
          enableFeedback: widget.enableFeedback,
          fallbackChild: child,
          selectedCount: widget.selectedPaths?.length,
        ),
        dragBuilder: (context, child) => _buildGalleryDragFeedback(
          context: context,
          ref: ref,
          record: widget.record,
          previewBytes: _previewBytes,
          previewProvider: _previewProvider,
          width: widget.feedbackWidth,
          hintText:
              widget.feedbackHint ?? context.l10n.localGallery_dragToShare,
          enableFeedback: widget.enableFeedback,
          fallbackChild: child,
          selectedCount: widget.selectedPaths?.length,
        ),
        child: DraggableWidget(
          child: Opacity(
            opacity: _isDragging ? widget.dragOpacity : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Future<DragItem> _createDragItem() async {
    final fileName = widget.record.path.split(RegExp(r'[/\\]')).last;
    final filePath = widget.record.path;
    final stripMetadata = ref
        .read(shareImageSettingsProvider)
        .effectiveStripMetadataForCopyAndDrag;

    final item = DragItem(
      suggestedName: fileName,
      localData: {
        'source': 'gallery_internal',
        'path': filePath,
        if (widget.selectedPaths != null && widget.selectedPaths!.isNotEmpty)
          'paths': widget.selectedPaths!,
        if (stripMetadata) 'externalPayload': 'gallery_sanitized',
      },
    );

    if (stripMetadata) {
      final dragBytes = await _readOriginalBytes(
        filePath: filePath,
        fallbackBytes: widget.previewBytes ?? _previewBytes,
      );
      if (dragBytes == null) {
        throw const ImageSanitizeException('Image bytes are unavailable');
      }
      final sanitized = await ImageShareSanitizer.sanitizeForShare(
        dragBytes,
        fileName: fileName.isEmpty ? 'shared.png' : fileName,
      );
      item.add(Formats.png(sanitized.bytes));

      final tempFile = await ImageShareSanitizer.writeTempShareFile(sanitized);
      item.add(Formats.fileUri(tempFile.uri));
      return item;
    }

    if (filePath.isNotEmpty) {
      try {
        item.add(Formats.fileUri(Uri.file(filePath)));
      } catch (e) {
        debugPrint('Failed to create file URI for drag: $e');
      }
      return item;
    }

    final dragBytes = widget.previewBytes ?? _previewBytes;
    if (dragBytes != null) {
      item.add(Formats.png(dragBytes));
    }

    return item;
  }
}

/// 内部拖拽包装组件
class _DragWrapper extends ConsumerStatefulWidget {
  final LocalImageRecord record;
  final List<String>? selectedPaths;
  final Uint8List? previewBytes;
  final double feedbackWidth;
  final String? feedbackHint;
  final bool enableFeedback;
  final double dragOpacity;
  final Widget child;

  const _DragWrapper({
    required this.record,
    this.selectedPaths,
    required this.previewBytes,
    required this.feedbackWidth,
    required this.feedbackHint,
    required this.enableFeedback,
    required this.dragOpacity,
    required this.child,
  });

  @override
  ConsumerState<_DragWrapper> createState() => _DragWrapperState();
}

class _DragWrapperState extends ConsumerState<_DragWrapper> {
  bool _isDragging = false;
  Uint8List? _previewBytes;
  ImageProvider? _previewProvider;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  @override
  void didUpdateWidget(covariant _DragWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewBytes != widget.previewBytes ||
        oldWidget.record.path != widget.record.path) {
      _initializePreview();
    }
  }

  void _initializePreview() {
    if (widget.previewBytes != null) {
      _setPreviewBytes(widget.previewBytes!);
      return;
    }

    if (widget.record.path.isNotEmpty) {
      _previewBytes = null;
      _previewProvider = FileImage(File(widget.record.path));
      return;
    }

    _previewBytes = null;
    _previewProvider = null;
  }

  void _setPreviewBytes(Uint8List bytes) {
    final provider = MemoryImage(bytes);
    _previewBytes = bytes;
    _previewProvider = provider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_previewProvider, provider)) return;
      unawaited(precacheImage(provider, context));
    });
  }

  Future<DragItem> _createDragItem() async {
    final fileName = widget.record.path.split(RegExp(r'[/\\]')).last;
    final filePath = widget.record.path;
    final stripMetadata = ref
        .read(shareImageSettingsProvider)
        .effectiveStripMetadataForCopyAndDrag;

    final item = DragItem(
      suggestedName: fileName,
      localData: {
        'source': 'gallery_internal',
        'path': filePath,
        if (widget.selectedPaths != null && widget.selectedPaths!.isNotEmpty)
          'paths': widget.selectedPaths!,
        if (stripMetadata) 'externalPayload': 'gallery_sanitized',
      },
    );

    if (stripMetadata) {
      final dragBytes = await _readOriginalBytes(
        filePath: filePath,
        fallbackBytes: widget.previewBytes ?? _previewBytes,
      );
      if (dragBytes == null) {
        throw const ImageSanitizeException('Image bytes are unavailable');
      }
      final sanitized = await ImageShareSanitizer.sanitizeForShare(
        dragBytes,
        fileName: fileName.isEmpty ? 'shared.png' : fileName,
      );
      item.add(Formats.png(sanitized.bytes));

      final tempFile = await ImageShareSanitizer.writeTempShareFile(sanitized);
      item.add(Formats.fileUri(tempFile.uri));
      return item;
    }

    if (filePath.isNotEmpty) {
      try {
        item.add(Formats.fileUri(Uri.file(filePath)));
      } catch (e) {
        debugPrint('Failed to create file URI for drag: $e');
      }
      return item;
    }

    final dragBytes = widget.previewBytes ?? _previewBytes;
    if (dragBytes != null) {
      item.add(Formats.png(dragBytes));
    }

    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _isDragging = true);
      },
      onPointerUp: (_) {
        setState(() => _isDragging = false);
      },
      onPointerCancel: (_) {
        setState(() => _isDragging = false);
      },
      child: DragItemWidget(
        allowedOperations: () => [DropOperation.copy],
        dragItemProvider: (request) => _createDragItem(),
        // 关键修复：每次调用时动态构建，确保使用最新的预览状态
        liftBuilder: (context, child) => _buildGalleryDragFeedback(
          context: context,
          ref: ref,
          record: widget.record,
          previewBytes: _previewBytes,
          previewProvider: _previewProvider,
          width: widget.feedbackWidth,
          hintText:
              widget.feedbackHint ?? context.l10n.localGallery_dragToShare,
          enableFeedback: widget.enableFeedback,
          fallbackChild: child,
          selectedCount: widget.selectedPaths?.length,
        ),
        dragBuilder: (context, child) => _buildGalleryDragFeedback(
          context: context,
          ref: ref,
          record: widget.record,
          previewBytes: _previewBytes,
          previewProvider: _previewProvider,
          width: widget.feedbackWidth,
          hintText:
              widget.feedbackHint ?? context.l10n.localGallery_dragToShare,
          enableFeedback: widget.enableFeedback,
          fallbackChild: child,
          selectedCount: widget.selectedPaths?.length,
        ),
        child: DraggableWidget(
          child: Opacity(
            opacity: _isDragging ? widget.dragOpacity : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

Future<Uint8List?> _readOriginalBytes({
  required String filePath,
  Uint8List? fallbackBytes,
}) async {
  if (filePath.isNotEmpty) {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('Failed to read original image bytes for drag: $e');
    }
  }
  return fallbackBytes;
}

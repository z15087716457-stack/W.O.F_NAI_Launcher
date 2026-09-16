import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/prompt_block_thumbnails.dart';
import '../../../../core/utils/thumbnail_image_normalizer.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/themed_input.dart';
import '../../../widgets/common/thumbnail_display.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';
import '../../tag_library_page/widgets/thumbnail_crop_dialog.dart';
import 'prompt_block_color_picker.dart';

class PromptBlockEditResult {
  const PromptBlockEditResult({
    required this.title,
    required this.content,
    required this.folderId,
    required this.color,
    required this.iconName,
    this.thumbnail,
    this.thumbnailOffsetX = 0.0,
    this.thumbnailOffsetY = 0.0,
    this.thumbnailScale = 1.0,
  });

  final String title;
  final String content;
  final String? folderId;
  final String color;
  final String? iconName;

  /// 应用目录内预览图路径；null = 无图。
  final String? thumbnail;
  final double thumbnailOffsetX;
  final double thumbnailOffsetY;
  final double thumbnailScale;
}

class PromptBlockEditDialog extends StatefulWidget {
  const PromptBlockEditDialog({
    super.key,
    required this.block,
    required this.folders,
    this.initialFolderId,
  });

  final PromptBlock? block;
  final List<PromptBlockFolder> folders;
  final String? initialFolderId;

  static Future<PromptBlockEditResult?> show({
    required BuildContext context,
    PromptBlock? block,
    required List<PromptBlockFolder> folders,
    String? initialFolderId,
  }) {
    return showDialog<PromptBlockEditResult>(
      context: context,
      builder: (context) => PromptBlockEditDialog(
        block: block,
        folders: folders,
        initialFolderId: initialFolderId,
      ),
    );
  }

  @override
  State<PromptBlockEditDialog> createState() => _PromptBlockEditDialogState();
}

class _PromptBlockEditDialogState extends State<PromptBlockEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String? _folderId;
  late Color _selectedColor;
  late String? _selectedIconName;

  /// 预览图当前路径：可能是应用目录内已存路径或本会话新落盘的选取图。
  String? _thumbnailPath;
  double _thumbnailOffsetX = 0.0;
  double _thumbnailOffsetY = 0.0;
  double _thumbnailScale = 1.0;

  /// 本会话选取时已落盘但尚未确认保存的新图；弹窗取消/丢弃时由
  /// [dispose] 统一回收，避免留下孤儿文件。
  final Set<String> _pendingThumbnailPaths = {};

  /// 保存确认后的最终路径；[_pendingThumbnailPaths] 里等于它的文件保留。
  String? _committedThumbnailPath;

  /// 保存进行中（落盘缩略图期间防重复提交）。
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block?.title ?? '');
    _contentController = TextEditingController(
      text: widget.block?.content ?? '',
    );
    _folderId = widget.block?.folderId ?? widget.initialFolderId;
    _selectedColor = promptBlockColorFromString(
      widget.block?.color ?? '#FF607D8B',
    );
    _selectedIconName = widget.block?.iconName;
    _thumbnailPath = widget.block?.thumbnail;
    _thumbnailOffsetX = widget.block?.thumbnailOffsetX ?? 0.0;
    _thumbnailOffsetY = widget.block?.thumbnailOffsetY ?? 0.0;
    _thumbnailScale = widget.block?.thumbnailScale ?? 1.0;
  }

  @override
  void dispose() {
    for (final path in _pendingThumbnailPaths) {
      if (path != _committedThumbnailPath) {
        // 未确认的选取图：取消/放弃弹窗时回收落盘文件。
        unawaited(deletePromptBlockThumbnail(path));
      }
    }
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final folders = widget.folders.toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });

    return AlertDialog(
      title: Text(
        widget.block == null
            ? l10n.promptBlockLibrary_newBlock
            : l10n.promptBlockLibrary_editBlock,
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedInput(
                controller: _titleController,
                autofocus: true,
                hintText: l10n.promptBlockLibrary_titleHint,
                decoration: InputDecoration(
                  labelText: l10n.promptBlockLibrary_blockTitle,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _folderId,
                decoration: InputDecoration(
                  labelText: l10n.promptBlockLibrary_folder,
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(l10n.promptBlockLibrary_rootFolder),
                  ),
                  ...folders.map(
                    (folder) => DropdownMenuItem<String>(
                      value: folder.id,
                      child: Text(
                        _folderLabel(folder, folders),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _folderId = value),
              ),
              const SizedBox(height: 12),
              _buildThumbnailSection(theme, l10n),
              const SizedBox(height: 12),
              Text(
                l10n.promptBlockLibrary_blockContent,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              ThemedInput.multiline(
                controller: _contentController,
                minLines: 9,
                maxLines: 14,
                hintText: l10n.promptBlockLibrary_contentHint,
                contentPadding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.promptBlockLibrary_color,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PromptBlockColorPicker(
                selectedColor: _selectedColor,
                onChanged: (color) => setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.promptBlockLibrary_icon,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              PromptBlockIconPicker(
                selected: _selectedIconName,
                onChanged: (name) => setState(() => _selectedIconName = name),
              ),
              if (widget.block?.sourcePath case final sourcePath?) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${l10n.promptBlockLibrary_sourceFile}: ${_sourceFileName(sourcePath)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (widget.block?.importedAt case final importedAt?)
                  Text(
                    '${l10n.promptBlockLibrary_importedAt}: ${_formatDateTime(importedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.common_save),
        ),
      ],
    );
  }

  // ==================== 预览图区（FEAT-2） ====================

  /// 预览图小区块：无图 = 小横框内「+」提示；有图 = 缩略图 + 选项菜单。
  Widget _buildThumbnailSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tagLibrary_thumbnail, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isSaving
              ? null
              : (_thumbnailPath != null
                    ? _showThumbnailOptions
                    : _selectThumbnail),
          child: Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: _thumbnailPath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: ThumbnailDisplay(
                          imagePath: _thumbnailPath!,
                          offsetX: _thumbnailOffsetX,
                          offsetY: _thumbnailOffsetY,
                          scale: _thumbnailScale,
                          width: 200,
                          height: 80,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton.filled(
                          icon: const Icon(Icons.close, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(24, 24),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _isSaving ? null : _clearThumbnail,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 28,
                      color: theme.colorScheme.outline,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectThumbnail() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedThumbnailImageExtensions,
        allowMultiple: false,
      );
      if (result == null) return;

      final selectedFile = result.files.single;
      final bytes =
          selectedFile.bytes ??
          (selectedFile.path == null
              ? null
              : await File(selectedFile.path!).readAsBytes());
      if (bytes == null) {
        throw const FileSystemException('无法读取所选图像');
      }

      // 归一化为 PNG 后直接落进块缩略图目录（与词库同策略）。
      final savedPath = await savePromptBlockThumbnail(bytes);
      if (!mounted) return;
      // 上一张本会话选取图已被换下 → 立即回收，不等 dispose。
      final replaced = _thumbnailPath;
      if (replaced != null && _pendingThumbnailPaths.contains(replaced)) {
        unawaited(deletePromptBlockThumbnail(replaced));
      }
      _pendingThumbnailPaths.add(savedPath);
      setState(() {
        _thumbnailPath = savedPath;
        _thumbnailOffsetX = 0.0;
        _thumbnailOffsetY = 0.0;
        _thumbnailScale = 1.0;
      });
      // 选完即出裁剪框做四周轻量裁剪。
      await _openCropDialog();
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.imagePicker_fileSelectionFailed(e.toString()),
        );
      }
    }
  }

  void _clearThumbnail() {
    setState(() {
      _thumbnailPath = null;
      _thumbnailOffsetX = 0.0;
      _thumbnailOffsetY = 0.0;
      _thumbnailScale = 1.0;
    });
  }

  void _showThumbnailOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text(context.l10n.tagLibrary_selectNewImage),
              onTap: () {
                Navigator.pop(sheetContext);
                _selectThumbnail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.crop_free),
              title: Text(context.l10n.tagLibrary_adjustDisplayRange),
              onTap: () {
                Navigator.pop(sheetContext);
                _openCropDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.l10n.common_delete),
              onTap: () {
                Navigator.pop(sheetContext);
                _clearThumbnail();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCropDialog() async {
    final path = _thumbnailPath;
    if (path == null) return;
    await showThumbnailCropDialog(
      context: context,
      imagePath: path,
      initialOffsetX: _thumbnailOffsetX,
      initialOffsetY: _thumbnailOffsetY,
      initialScale: _thumbnailScale,
      onConfirm: (result) {
        setState(() {
          _thumbnailOffsetX = result.offsetX;
          _thumbnailOffsetY = result.offsetY;
          _thumbnailScale = result.scale;
        });
      },
    );
  }

  /// 保存：外部新选图已在选取时落进块目录；此处只需清理被替换的旧图。
  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final oldThumbnail = widget.block?.thumbnail;
      if (_thumbnailPath != oldThumbnail) {
        // 新选取图已在 _selectThumbnail 落目录；这里只回收被换下的旧图。
        await deletePromptBlockThumbnail(oldThumbnail);
      }
      _committedThumbnailPath = _thumbnailPath;
      if (!mounted) return;
      Navigator.of(context).pop(
        PromptBlockEditResult(
          title: _titleController.text.trim(),
          // Keep the original text exactly as entered, including whitespace.
          content: _contentController.text,
          folderId: _folderId,
          color: promptBlockColorToHex(_selectedColor),
          iconName: _selectedIconName,
          thumbnail: _thumbnailPath,
          thumbnailOffsetX: _thumbnailOffsetX,
          thumbnailOffsetY: _thumbnailOffsetY,
          thumbnailScale: _thumbnailScale,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _sourceFileName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty);
    return segments.isEmpty ? sourcePath : segments.last;
  }

  String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _folderLabel(
    PromptBlockFolder folder,
    List<PromptBlockFolder> folders,
  ) {
    var depth = 0;
    final byId = <String, PromptBlockFolder>{
      for (final item in folders) item.id: item,
    };
    final visited = <String>{};
    String? parentId = folder.parentId;
    while (parentId != null && visited.add(parentId)) {
      depth++;
      parentId = byId[parentId]?.parentId;
    }
    final name = folder.name.isEmpty
        ? context.l10n.promptBlockLibrary_unnamedFolder
        : folder.name;
    return '${'  ' * depth}$name';
  }
}

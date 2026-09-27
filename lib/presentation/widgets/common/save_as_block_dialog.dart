import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/prompt_block_thumbnails.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../providers/prompt_block_library_provider.dart';
import 'image_detail/image_detail_data.dart';
import 'app_toast.dart';

/// 保存为块对话框
///
/// 将图片元数据的正面与负面提示词保存为同一个块。
/// 仅负面块默认使用调色板红色便于识别。
/// 传入 [image] 时顺带把当前图片存为块预览图（FEAT-2）。
class SaveAsBlockDialog extends ConsumerStatefulWidget {
  /// 要保存的元数据
  final NaiImageMetadata metadata;

  /// 可选：详情页当前图片，保存成功后作为块预览图。
  final ImageDetailData? image;

  const SaveAsBlockDialog({super.key, required this.metadata, this.image});

  /// 显示对话框
  static Future<bool> show(
    BuildContext context, {
    required NaiImageMetadata metadata,
    ImageDetailData? image,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveAsBlockDialog(metadata: metadata, image: image),
    );
    return result ?? false;
  }

  @override
  ConsumerState<SaveAsBlockDialog> createState() => _SaveAsBlockDialogState();
}

class _SaveAsBlockDialogState extends ConsumerState<SaveAsBlockDialog> {
  late final TextEditingController _nameController;

  late bool _includePositive;
  late bool _includeNegative;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 默认名称：提示词前几个词 + 种子
    final tags = widget.metadata.prompt
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .join(', ');
    final seed = widget.metadata.seed;
    final defaultName = tags.isEmpty
        ? ''
        : (seed != null ? '$tags · $seed' : tags);
    _nameController = TextEditingController(text: defaultName);
    _includePositive = widget.metadata.prompt.trim().isNotEmpty;
    _includeNegative = widget.metadata.negativePrompt.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.warning(context, l10n.saveBlock_nameRequired);
      return;
    }
    if (!_includePositive && !_includeNegative) {
      AppToast.warning(context, l10n.saveBlock_selectContent);
      return;
    }

    setState(() => _isSaving = true);
    String? thumbnail;
    try {
      final notifier = ref.read(promptBlockLibraryNotifierProvider.notifier);
      // 预览图归这一个块所有。
      if (widget.image != null) {
        try {
          thumbnail = await savePromptBlockThumbnail(
            await widget.image!.getImageBytes(),
          );
        } catch (_) {
          thumbnail = null; // 读图/归一化失败不阻断存块本身
        }
      }
      await notifier.createBlock(
        title: _includePositive
            ? name
            : '$name · ${l10n.saveBlock_negativeSuffix}',
        content: _includePositive ? widget.metadata.prompt : '',
        negativeContent: _includeNegative ? widget.metadata.negativePrompt : '',
        color: _includePositive ? '#FF607D8B' : '#FFE53935',
        thumbnail: thumbnail,
      );
      thumbnail = null;
      if (mounted) {
        AppToast.success(context, l10n.saveBlock_saved);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      // 存块中途失败：回收未归属任何块的预览图，避免孤儿文件。
      await deletePromptBlockThumbnail(thumbnail);
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPositive = widget.metadata.prompt.trim().isNotEmpty;
    final hasNegative = widget.metadata.negativePrompt.trim().isNotEmpty;

    return AlertDialog(
      title: Text(l10n.saveBlock_title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 100,
              decoration: InputDecoration(
                labelText: l10n.saveBlock_nameLabel,
                hintText: l10n.saveBlock_nameHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _includePositive = hasPositive;
                      _includeNegative = hasNegative;
                    });
                  },
                  child: Text(l10n.common_selectAll),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _includePositive = false;
                      _includeNegative = false;
                    });
                  },
                  child: Text(l10n.common_clear),
                ),
              ],
            ),
            if (hasPositive)
              CheckboxListTile(
                value: _includePositive,
                onChanged: (v) => setState(() => _includePositive = v ?? false),
                title: Text(
                  l10n.metadataImport_mainPrompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.metadata.prompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            if (hasNegative)
              CheckboxListTile(
                value: _includeNegative,
                onChanged: (v) => setState(() => _includeNegative = v ?? false),
                title: Text(
                  l10n.prompt_negativePrompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.metadata.negativePrompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
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
}

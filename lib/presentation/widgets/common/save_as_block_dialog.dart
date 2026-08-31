import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../providers/prompt_block_library_provider.dart';
import 'app_toast.dart';

/// 保存为块对话框
///
/// 将图片元数据的 Prompt 原文保存为块库纯文本块。
/// 正向 / 负向各自独立成块，负向块默认使用调色板红色便于识别。
class SaveAsBlockDialog extends ConsumerStatefulWidget {
  /// 要保存的元数据
  final NaiImageMetadata metadata;

  const SaveAsBlockDialog({super.key, required this.metadata});

  /// 显示对话框
  static Future<bool> show(
    BuildContext context, {
    required NaiImageMetadata metadata,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SaveAsBlockDialog(metadata: metadata),
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
    try {
      final notifier = ref.read(promptBlockLibraryNotifierProvider.notifier);
      if (_includePositive) {
        await notifier.createBlock(
          title: name,
          content: widget.metadata.prompt,
        );
      }
      if (_includeNegative) {
        await notifier.createBlock(
          title: '$name · ${l10n.saveBlock_negativeSuffix}',
          content: widget.metadata.negativePrompt,
          color: '#FFE53935',
        );
      }
      if (mounted) {
        AppToast.success(context, l10n.saveBlock_saved);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
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

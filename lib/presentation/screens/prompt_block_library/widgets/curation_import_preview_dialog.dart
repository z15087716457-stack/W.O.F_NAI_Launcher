import 'package:flutter/material.dart';

import '../../../../core/utils/prompt_block_exchange.dart';
import '../../../../core/utils/localization_extension.dart';

/// 用户在策展导入预览中的决定。
class CurationImportDecision {
  const CurationImportDecision({required this.updateChanged});

  /// 是否用文件内容覆盖已变更的块。
  final bool updateChanged;
}

/// 策展目录导入预览：透明列出每个将导入的来源文件与三态分类，
/// 由用户显式决定是否更新已变更块。
class CurationImportPreviewDialog extends StatefulWidget {
  const CurationImportPreviewDialog({
    super.key,
    required this.rootPath,
    required this.plan,
  });

  final String rootPath;
  final PromptBlockExchangePlan plan;

  static Future<CurationImportDecision?> show({
    required BuildContext context,
    required String rootPath,
    required PromptBlockExchangePlan plan,
  }) {
    return showDialog<CurationImportDecision>(
      context: context,
      builder: (context) =>
          CurationImportPreviewDialog(rootPath: rootPath, plan: plan),
    );
  }

  @override
  State<CurationImportPreviewDialog> createState() =>
      _CurationImportPreviewDialogState();
}

class _CurationImportPreviewDialogState
    extends State<CurationImportPreviewDialog> {
  bool _updateChanged = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final plan = widget.plan;

    return AlertDialog(
      title: Text(l10n.promptBlockLibrary_curationTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rootPath,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.promptBlockLibrary_curationSummary(
                plan.items.length,
                plan.createCount,
                plan.skipCount,
                plan.updateCount,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: plan.items.length,
                    itemBuilder: (context, index) {
                      final item = plan.items[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          item.file.path.replaceFirst(widget.rootPath, ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: _actionChip(context, item),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (plan.updateCount > 0) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                value: _updateChanged,
                onChanged: (value) => setState(() => _updateChanged = value),
                title: Text(
                  l10n.promptBlockLibrary_curationUpdateChanged,
                  style: theme.textTheme.bodyMedium,
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (plan.localModifiedCount > 0)
                Text(
                  l10n.promptBlockLibrary_curationLocalModifiedHint(
                    plan.localModifiedCount,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(CurationImportDecision(updateChanged: _updateChanged)),
          child: Text(l10n.common_import),
        ),
      ],
    );
  }

  Widget _actionChip(BuildContext context, PromptBlockExchangeItem item) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final (label, color) = switch (item.action) {
      PromptBlockExchangeAction.create => (
        l10n.promptBlockLibrary_curationNew,
        theme.colorScheme.primary,
      ),
      PromptBlockExchangeAction.skipUnchanged => (
        l10n.promptBlockLibrary_curationUnchanged,
        theme.colorScheme.onSurfaceVariant,
      ),
      PromptBlockExchangeAction.update => (
        item.localModified
            ? l10n.promptBlockLibrary_curationLocalModified
            : l10n.promptBlockLibrary_curationChanged,
        theme.colorScheme.error,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

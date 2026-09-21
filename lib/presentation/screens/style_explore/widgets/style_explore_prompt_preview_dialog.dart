import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/app_logger.dart';

/// 画风探索 Recipe 的纯文本 Prompt 预览。
///
/// 只展示纯文本投影；块标题与颜色不出现在这里。
class StyleExplorePromptPreviewDialog extends StatelessWidget {
  const StyleExplorePromptPreviewDialog({
    super.key,
    required this.positiveText,
    required this.negativeText,
  });

  final String positiveText;
  final String negativeText;

  static Future<void> show(
    BuildContext context, {
    required String positiveText,
    required String negativeText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => StyleExplorePromptPreviewDialog(
        positiveText: positiveText,
        negativeText: negativeText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.styleExplore_previewTitle),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              context,
              theme,
              title: l10n.styleExplore_positive,
              text: positiveText,
              copyButtonKey: const Key('style-explore-preview-copy-positive'),
            ),
            const SizedBox(height: 12),
            _buildSection(
              context,
              theme,
              title: l10n.styleExplore_negative,
              text: negativeText,
              copyButtonKey: const Key('style-explore-preview-copy-negative'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required String text,
    required Key copyButtonKey,
  }) {
    final l10n = context.l10n;
    final isEmpty = text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              key: copyButtonKey,
              onPressed: isEmpty ? null : () => _copy(context, text),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(
                title == l10n.styleExplore_positive
                    ? l10n.styleExplore_copyPositive
                    : l10n.styleExplore_copyNegative,
              ),
            ),
          ],
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              isEmpty ? l10n.styleExplore_previewEmpty : text,
              style: isEmpty
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    final l10n = context.l10n;
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(l10n.styleExplore_copiedToClipboard),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    } catch (error) {
      AppLogger.w('Copy prompt preview failed: $error', 'StyleExplore');
    }
  }
}

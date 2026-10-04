import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import '../../app_toast.dart';
import 'detail_prompt_section.dart';
export 'detail_prompt_section.dart';

/// 角色提示词卡片组件
class CharacterPromptCard extends StatelessWidget {
  final int index;
  final String prompt;
  final String? negativePrompt;
  final String? position;
  final VoidCallback? onCopy;

  const CharacterPromptCard({
    super.key,
    required this.index,
    required this.prompt,
    this.negativePrompt,
    this.position,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colorScheme, theme),
          const SizedBox(height: 8),
          PromptSection(
            title: context.l10n.prompt_positivePrompt,
            icon: Icons.text_fields,
            content: prompt,
            initiallyExpanded: true,
          ),
          if (negativePrompt?.isNotEmpty == true)
            _buildNegativePrompt(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            context.l10n.character_number(index + 1),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (position?.isNotEmpty == true) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.location_on_outlined,
            size: 12,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            position!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        IconButton(
          onPressed: () {
            final textToCopy = negativePrompt?.isNotEmpty == true
                ? '${context.l10n.prompt_positivePrompt}: $prompt\n'
                      '${context.l10n.prompt_negativePrompt}: $negativePrompt'
                : prompt;
            Clipboard.setData(ClipboardData(text: textToCopy));
            AppToast.success(context, context.l10n.toast_characterPromptCopied);
            onCopy?.call();
          },
          icon: Icon(Icons.copy, size: 16, color: colorScheme.onSurfaceVariant),
          tooltip: context.l10n.detail_copyCharacterPrompt,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(24, 24),
          ),
        ),
      ],
    );
  }

  Widget _buildNegativePrompt(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: PromptSection(
        title: context.l10n.prompt_negativePrompt,
        icon: Icons.block,
        content: negativePrompt!,
        initiallyExpanded: true,
        contentColor: colorScheme.error,
      ),
    );
  }
}

/// 角色提示词分组组件
class CharacterPromptSection extends StatelessWidget {
  final String title;
  final List<({String prompt, String? negativePrompt, String? position})>
  characters;
  final bool initiallyExpanded;

  const CharacterPromptSection({
    super.key,
    required this.title,
    required this.characters,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return PromptSection(
      title: title,
      icon: Icons.people_outline,
      content: characters.map((c) => c.prompt).join(', '),
      initiallyExpanded: initiallyExpanded,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_prompt_provider.dart';
import '../../providers/image_generation_provider.dart';
import 'character_position_canvas.dart';
import 'inline_character_card.dart';
import 'inline_character_editor.dart';

/// 内联角色区块（官网布局左栏用，竖排）
///
/// 位于主提示词正下方，与主提示词同屏对照编辑：
/// - 官网式小节头：`Character Prompts` 标题 + 副题，右端单枚 `+`
///   弹出 girl/boy/other 菜单，旁边一枚清空全部
/// - `Position` 行：`Position` 标签 + AI's Choice/Custom 分段 + 网格画布钮
/// - 角色卡竖排（内容常显，点击即编辑）
///
/// 仅 V4+ 模型显示（多角色为 V4 专属能力）。
class InlineCharacterSection extends ConsumerWidget {
  const InlineCharacterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isV4Model = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => ImageModels.isV4Model(params.model),
      ),
    );
    if (!isV4Model) {
      return const SizedBox.shrink();
    }

    final config = ref.watch(characterPromptNotifierProvider);
    final characters = config.characters;
    final hasCharacters = characters.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 官网式小节头：标题 + 副题，右端清空全部 + 添加 `+`
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.generation_sectionCharacters,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l10n.generation_sectionCharactersSub,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hasCharacters)
              Tooltip(
                message: l10n.characterEditor_clearAll,
                waitDuration: const Duration(milliseconds: 500),
                child: InkWell(
                  onTap: () => confirmClearAllCharacters(context, ref),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_sweep,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            _AddCharacterMenu(theme: theme, l10n: l10n),
          ],
        ),
        // 官网 Position 行：标签 + AI's Choice/Custom 分段 + 网格画布钮
        if (hasCharacters) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.character_positionLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const CharacterPositionModeSegments(),
            ],
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 8),
        for (var i = 0; i < characters.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InlineCharacterCard(
              key: ValueKey(characters[i].id),
              character: characters[i],
              index: i,
              total: characters.length,
            ),
          ),
      ],
    );
  }
}

/// 官网式单枚 `+`：点击弹出 girl/boy/other 菜单，选中即按性别预填提示词。
class _AddCharacterMenu extends ConsumerWidget {
  const _AddCharacterMenu({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<CharacterGender>(
      tooltip: l10n.character_addCharacter,
      iconSize: 20,
      offset: const Offset(0, 30),
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (gender) => ref
          .read(characterPromptNotifierProvider.notifier)
          .addCharacter(gender),
      itemBuilder: (context) => [
        _item(CharacterGender.female, l10n.characterEditor_addFemale),
        _item(CharacterGender.male, l10n.characterEditor_addMale),
        _item(CharacterGender.other, l10n.characterEditor_addOther),
      ],
      icon: SvgPicture.asset(
        'assets/icons/nai-icon-rounded-plus.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          theme.colorScheme.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  PopupMenuItem<CharacterGender> _item(CharacterGender gender, String label) {
    return PopupMenuItem<CharacterGender>(
      value: gender,
      height: 36,
      child: Row(
        children: [
          Icon(_genderIcon(gender), size: 16, color: _genderColor(gender)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  static IconData _genderIcon(CharacterGender gender) {
    return switch (gender) {
      CharacterGender.female => Icons.female,
      CharacterGender.male => Icons.male,
      CharacterGender.other => Icons.transgender,
    };
  }

  static Color _genderColor(CharacterGender gender) {
    return switch (gender) {
      CharacterGender.female => const Color(0xFFEC4899),
      CharacterGender.male => const Color(0xFF3B82F6),
      CharacterGender.other => const Color(0xFF8B5CF6),
    };
  }
}

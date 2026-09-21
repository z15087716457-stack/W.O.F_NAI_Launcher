import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_prompt_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../screens/generation/widgets/generation_sidebar_style.dart';
import 'character_position_canvas.dart';
import 'inline_character_card.dart';
import 'inline_character_editor.dart';

/// The section header stays compact until a character has been added.
class InlineCharacterSection extends ConsumerWidget {
  const InlineCharacterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final model = ref.watch(
      generationParamsNotifierProvider.select((p) => p.model),
    );
    if (!ImageModels.isV4Model(model)) return const SizedBox.shrink();
    final characters = ref.watch(characterPromptNotifierProvider).characters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('character-section-header'),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: GenSidebarStyle.border(theme)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.generation_sectionCharacters,
                          style: GenSidebarStyle.sectionTitle(theme),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.generation_sectionCharactersSub,
                          style: GenSidebarStyle.sectionSubtitle(theme),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _AddCharacterMenu(hasCharacters: characters.isNotEmpty),
                ],
              ),
              if (characters.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      l10n.character_positionLabel,
                      style: GenSidebarStyle.fieldLabel(theme),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: CharacterPositionModeSegments(expanded: true),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        for (var i = 0; i < characters.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 12),
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

enum _AddAction { female, male, other, clear }

class _AddCharacterMenu extends ConsumerWidget {
  const _AddCharacterMenu({required this.hasCharacters});
  final bool hasCharacters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_AddAction>(
      key: const ValueKey('add-character-menu'),
      tooltip: l10n.character_addCharacter,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
        maximumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        backgroundColor: GenSidebarStyle.selectedSurface(theme),
        hoverColor: theme.colorScheme.onSurface.withValues(alpha: .09),
        focusColor: theme.colorScheme.onSurface.withValues(alpha: .12),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: .16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      onSelected: (action) {
        if (action == _AddAction.clear) {
          confirmClearAllCharacters(context, ref);
          return;
        }
        ref.read(characterPromptNotifierProvider.notifier).addCharacter(
          switch (action) {
            _AddAction.female => CharacterGender.female,
            _AddAction.male => CharacterGender.male,
            _ => CharacterGender.other,
          },
        );
      },
      itemBuilder: (_) => [
        _item(
          _AddAction.female,
          Icons.female,
          l10n.characterEditor_genderFemale,
        ),
        _item(_AddAction.male, Icons.male, l10n.characterEditor_genderMale),
        _item(
          _AddAction.other,
          Icons.circle_outlined,
          l10n.characterEditor_genderOther,
        ),
        if (hasCharacters) ...[
          const PopupMenuDivider(),
          _item(
            _AddAction.clear,
            Icons.delete_sweep_outlined,
            l10n.characterEditor_clearAll,
          ),
        ],
      ],
      icon: StudioIcon(Icons.add, size: 24, color: theme.colorScheme.onSurface),
    );
  }

  PopupMenuItem<_AddAction> _item(
    _AddAction action,
    IconData icon,
    String label,
  ) => PopupMenuItem(
    value: action,
    height: 36,
    child: Row(
      children: [
        StudioIcon(icon, size: 16),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}

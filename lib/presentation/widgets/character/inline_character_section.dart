import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';

import '../../../core/constants/api_constants.dart';
import '../../../data/models/character/character_prompt.dart';
import '../../providers/character_prompt_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../screens/generation/widgets/generation_sidebar_style.dart';
import '../../screens/generation/widgets/generation_module_card.dart';
import '../common/uiux_prototype_icon.dart';
import 'character_module_scope.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        double textWidth(String text, TextStyle style) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width;
        }

        final labelStyle = GenSidebarStyle.fieldLabel(
          theme,
        ).copyWith(fontSize: 12);
        final trackStyle = GenSidebarStyle.segmentLabel(
          theme,
          selected: true,
          enabled: true,
        );
        final badgeWidth =
            (textWidth(
                      '${characters.length}',
                      GenSidebarStyle.moduleCountBadge(theme),
                    ) +
                    10)
                .clamp(18.0, double.infinity);
        final requiredWidth =
            2 +
            12 +
            6 +
            textWidth(
              l10n.generation_sectionCharacters,
              GenSidebarStyle.moduleTitle(theme),
            ) +
            6 +
            badgeWidth +
            textWidth(l10n.character_positionLabel, labelStyle) +
            textWidth(l10n.characterCanvas_aiChoice, trackStyle) +
            textWidth(l10n.characterCanvas_custom, trackStyle) +
            4 * GenSidebarStyle.segmentDenseHorizontalPadding +
            2 * GenSidebarStyle.segmentTrackInset +
            GenSidebarStyle.segmentGap +
            28 +
            6 +
            28 +
            3 * GenSidebarStyle.moduleActionGap;
        final inlinePosition =
            characters.isNotEmpty && constraints.maxWidth >= requiredWidth;
        return GenerationModuleCard(
          title: l10n.generation_sectionCharacters,
          titleTooltip: l10n.generation_sectionCharactersSub,
          count: characters.length,
          headerKey: const ValueKey('character-section-header'),
          actions: [
            if (inlinePosition) ...[
              Text(l10n.character_positionLabel, style: labelStyle),
              const CharacterPositionModeSegments(moduleHeader: true),
            ],
            _AddCharacterMenu(hasCharacters: characters.isNotEmpty),
          ],
          children: [
            if (characters.isNotEmpty && !inlinePosition)
              Padding(
                key: const ValueKey('character-position-row'),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    Text(l10n.character_positionLabel, style: labelStyle),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: CharacterPositionModeSegments(
                        moduleHeader: true,
                        expanded: true,
                      ),
                    ),
                  ],
                ),
              ),
            CharacterModuleScope(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < characters.length; i++)
                    InlineCharacterCard(
                      key: ValueKey(characters[i].id),
                      character: characters[i],
                      index: i,
                      total: characters.length,
                    ),
                ],
              ),
            ),
          ],
        );
      },
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
        fixedSize: const Size(28, 28),
        minimumSize: const Size(28, 28),
        maximumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        backgroundColor: Colors.transparent,
        hoverColor: theme.colorScheme.surfaceContainerHigh,
        focusColor: theme.colorScheme.onSurface.withValues(alpha: .12),
        highlightColor: theme.colorScheme.onSurface.withValues(alpha: .16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      icon: UiuxPrototypeIcon(
        Icons.add,
        size: 18,
        strokeWidth: 2.1,
        source: UiuxPrototypeIconSource.generation,
        color: theme.colorScheme.onSurface,
      ),
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
      children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(label)],
    ),
  );
}

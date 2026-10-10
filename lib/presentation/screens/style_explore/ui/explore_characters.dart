import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/character/character_prompt.dart';
import '../../../providers/character_prompt_provider.dart';
import '../../../providers/character_position_canvas_provider.dart';
import '../../../widgets/character/inline_character_card.dart';
import '../../../widgets/prompt/nai_syntax_controller.dart';
import '../../../themes/studio_typography.dart';
import 'explore_controls.dart';
import 'explore_icon.dart';
import 'explore_text.dart';

class ExploreCharacters extends ConsumerWidget {
  const ExploreCharacters({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(characterPromptNotifierProvider),
        c = Theme.of(context).colorScheme,
        l = context.l10n;
    return ExploreSection(
      title: l.generation_sectionCharacters,
      count: config.characters.length,
      actions: [
        PopupMenuButton<bool>(
          tooltip: l.character_positionLabel,
          onSelected: (value) {
            ref
                .read(characterPromptNotifierProvider.notifier)
                .setGlobalAiChoice(value);
            if (!value) {
              ref.read(characterPositionCanvasProvider.notifier).open();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: true,
              child: ExploreText(l.characterCanvas_aiChoice),
            ),
            PopupMenuItem(
              value: false,
              child: ExploreText(l.characterCanvas_custom),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExploreText(
                config.globalAiChoice
                    ? l.characterCanvas_aiChoice
                    : l.characterCanvas_custom,
                style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
              ),
              SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: ExploreIcon(
                    'chevD',
                    size: 15,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<CharacterGender>(
          key: const ValueKey('add-character-menu'),
          tooltip: l.character_addCharacter,
          onSelected: (gender) => ref
              .read(characterPromptNotifierProvider.notifier)
              .addCharacter(gender),
          itemBuilder: (_) => [
            for (final gender in CharacterGender.values)
              PopupMenuItem(
                value: gender,
                child: ExploreText(switch (gender) {
                  CharacterGender.female => l.characterEditor_genderFemale,
                  CharacterGender.male => l.characterEditor_genderMale,
                  _ => l.characterEditor_genderOther,
                }),
              ),
          ],
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: ExploreIcon(
                'plus',
                size: 17,
                strokeWidth: 2.1,
                color: c.onSurface,
              ),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < config.characters.length; i++)
            InkWell(
              key: ValueKey(config.characters[i].id),
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => Dialog(
                  child: SizedBox(
                    width: 650,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: ExploreIconButton(
                                'x',
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                            ),
                            Consumer(
                              builder: (context, ref, _) {
                                final latest = ref
                                    .watch(characterPromptNotifierProvider)
                                    .characters;
                                final index = latest.indexWhere(
                                  (char) => char.id == config.characters[i].id,
                                );
                                if (index < 0) return const SizedBox.shrink();
                                return InlineCharacterCard(
                                  character: latest[index],
                                  index: index,
                                  total: latest.length,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.outlineVariant)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
                child: _Preview(prompt: config.characters[i].prompt),
              ),
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.prompt});
  final String prompt;
  @override
  Widget build(BuildContext context) {
    final controller = NaiSyntaxController(text: prompt);
    final span = controller.buildTextSpan(
      context: context,
      style: StudioTypography.body.copyWith(
        fontSize: 12.5,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      withComposing: false,
    );
    controller.dispose();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 62),
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, .55, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: RichText(text: span, maxLines: 3, overflow: TextOverflow.clip),
      ),
    );
  }
}

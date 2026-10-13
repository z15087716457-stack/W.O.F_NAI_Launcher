import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../../data/models/prompt_block/pill_document.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import 'prompt_block_colors.dart';
import 'prompt_block_appearance.dart';
import 'prompt_block_icons.dart';
import '../nai_syntax_controller.dart';
import '../pills/translation_tag_span.dart';
import '../pills/prompt_pill.dart';
import '../../common/translation_icon.dart';
import '../../common/uiux_prototype_icon.dart';

class PromptBlockPill extends StatelessWidget {
  const PromptBlockPill({
    super.key,
    required this.block,
    required this.displayTitle,
    required this.maxWidth,
    required this.onTap,
    this.selected = false,
    this.multiSelected = false,
    this.onSecondaryTap,
    this.paletteStyle = false,
    this.highlightEnabled = true,
    this.numericEmphasisEnabled = true,
  });

  final PromptBlock block;
  final String displayTitle;
  final double maxWidth;
  final VoidCallback onTap;
  final bool selected;

  /// 多选模式下属于选中集合（叠加勾选角标；描边复用 [selected]）。
  final bool multiSelected;

  /// 右键菜单入口（secondary tap）。
  final void Function(TapUpDetails details)? onSecondaryTap;

  /// The floating palette shows full text at a smaller, prompt-like size.
  final bool paletteStyle;
  final bool highlightEnabled;
  final bool numericEmphasisEnabled;

  TextSpan _paletteTextSpan(
    BuildContext context,
    TextStyle? style,
    List<TranslationTagMark> marks,
  ) {
    final controller = NaiSyntaxController(
      text: displayTitle,
      highlightEnabled: highlightEnabled,
      numericEmphasisEnabled: numericEmphasisEnabled,
    );
    try {
      return TranslationTagSpan.annotate(
        context,
        controller.buildTextSpan(
          context: context,
          style: style,
          withComposing: false,
        ),
        displayTitle,
        marks,
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = promptBlockColorFromString(block.color);
    final translated =
        paletteStyle &&
        (block.readingTranslationZh != null ||
            block.appearance == PromptBlockAppearance.translation);
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 12,
      height: 1.25,
      fontWeight: FontWeight.w500,
      color: PromptBlockAppearance.text(
        block.appearance,
        blockColor,
        theme.colorScheme.onSurface,
        dark: theme.brightness == Brightness.dark,
      ),
    );
    final marks =
        translated &&
            block.readingTranslationZh == displayTitle &&
            block.readingTranslationMarks?.isNotEmpty == true
        ? TranslationPill.fromJson({
            'zh': displayTitle,
            'marks': block.readingTranslationMarks,
          }).marks
        : const <TranslationTagMark>[];
    return GestureDetector(
      onSecondaryTapUp: onSecondaryTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: ValueKey('prompt-block-pill-body-${block.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(PromptPillSize.regular.radius),
            child: PromptPill(
              title: displayTitle,
              color: blockColor,
              appearance: block.appearance,
              icon: promptBlockIconFromName(block.iconName),
              focused: selected,
              multiline: translated,
              leading: translated
                  ? const TranslationIcon(
                      size: 12,
                      style: TranslationIconStyle.pill,
                    )
                  : null,
              label: translated
                  ? Text.rich(
                      _paletteTextSpan(context, titleStyle, marks),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: titleStyle,
                    )
                  : null,
              trailing: multiSelected
                  ? UiuxPrototypeIcon(
                      Icons.check_circle,
                      size: 12,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

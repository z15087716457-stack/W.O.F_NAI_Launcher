import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../../core/autocomplete/completion_models.dart';
import '../../../../data/models/prompt_block/pill_document.dart';
import '../../autocomplete/tag_category_visuals.dart';

/// Adds visual Danbooru cues without changing either the reading or source.
abstract final class TranslationTagSpan {
  static TextSpan annotate(
    BuildContext context,
    TextSpan syntax,
    String reading,
    List<TranslationTagMark> marks,
  ) {
    if (marks.isEmpty || syntax.children == null) return syntax;
    final valid = <({TranslationTagMark mark, TagCategory category})>[];
    for (final mark in marks) {
      final category = TagCategory.values
          .where((candidate) => candidate.name == mark.iconId)
          .firstOrNull;
      if (category == null ||
          category == TagCategory.general ||
          mark.start < 0 ||
          mark.end > reading.length ||
          mark.end <= mark.start ||
          (valid.isNotEmpty && mark.start < valid.last.mark.end)) {
        continue;
      }
      valid.add((mark: mark, category: category));
    }
    if (valid.isEmpty) return syntax;

    final output = <InlineSpan>[];
    var absolute = 0;
    var markIndex = 0;
    for (final child in syntax.children!) {
      if (child is! TextSpan || child.text == null) return syntax;
      final value = child.text!;
      var local = 0;
      while (local < value.length) {
        final position = absolute + local;
        while (markIndex < valid.length &&
            valid[markIndex].mark.end <= position) {
          markIndex++;
        }
        final current = markIndex < valid.length ? valid[markIndex] : null;
        final marked = current != null && current.mark.start <= position;
        final next = current == null
            ? absolute + value.length
            : marked
            ? current.mark.end
            : current.mark.start;
        final localEnd = (next - absolute).clamp(local + 1, value.length);
        final color = marked
            ? TagCategoryVisuals.color(context, current.category)
            : null;
        output.add(
          TextSpan(
            text: value.substring(local, localEnd),
            style: color == null
                ? child.style
                : (child.style ?? const TextStyle()).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                    decorationThickness: 1.4,
                  ),
          ),
        );
        local = localEnd;
        if (marked && absolute + local == current.mark.end) {
          output.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ExcludeSemantics(
                child: Transform.translate(
                  offset: const Offset(0, -4),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Icon(
                      TagCategoryVisuals.icon(current.category),
                      size: 9,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
      absolute += value.length;
    }
    return TextSpan(style: syntax.style, children: output);
  }
}

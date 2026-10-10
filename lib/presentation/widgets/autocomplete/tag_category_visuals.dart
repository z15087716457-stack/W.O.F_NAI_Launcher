import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

import '../../../core/autocomplete/completion_models.dart';
import '../../../core/utils/localization_extension.dart';

/// Shared category cues for both tag pickers.
abstract final class TagCategoryVisuals {
  static IconData icon(TagCategory category) => switch (category) {
    TagCategory.general => Icons.sell_rounded,
    TagCategory.artist => Icons.brush_rounded,
    TagCategory.copyright => Icons.copyright_rounded,
    TagCategory.character => Icons.person_rounded,
    TagCategory.meta => Icons.tune_rounded,
    TagCategory.contributor => Icons.badge_rounded,
    TagCategory.species => Icons.pets_rounded,
    TagCategory.lore => Icons.auto_stories_rounded,
    TagCategory.library => Icons.collections_bookmark_rounded,
  };

  static String label(BuildContext context, TagCategory category) =>
      switch (category) {
        TagCategory.general => context.l10n.autocomplete_categoryGeneral,
        TagCategory.artist => context.l10n.autocomplete_categoryArtist,
        TagCategory.copyright => context.l10n.autocomplete_categoryCopyright,
        TagCategory.character => context.l10n.autocomplete_categoryCharacter,
        TagCategory.meta => context.l10n.autocomplete_categoryMeta,
        TagCategory.contributor =>
          context.l10n.autocomplete_categoryContributor,
        TagCategory.species => context.l10n.autocomplete_categorySpecies,
        TagCategory.lore => context.l10n.autocomplete_categoryLore,
        TagCategory.library => context.l10n.autocomplete_categoryLibrary,
      };

  static Color color(BuildContext context, TagCategory category) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch ((category, dark)) {
      (TagCategory.general, true) => const Color(0xff62b9f0),
      (TagCategory.general, false) => const Color(0xff176d9f),
      (TagCategory.artist, true) => const Color(0xffff7b78),
      (TagCategory.artist, false) => const Color(0xffb52c2a),
      (TagCategory.copyright, true) => const Color(0xffd083e0),
      (TagCategory.copyright, false) => const Color(0xff7b4389),
      (TagCategory.character, true) => const Color(0xff7bd27e),
      (TagCategory.character, false) => const Color(0xff2b7834),
      (TagCategory.meta, true) => const Color(0xffffb85c),
      (TagCategory.meta, false) => const Color(0xff925b08),
      (TagCategory.contributor, true) => const Color(0xffff9d66),
      (TagCategory.contributor, false) => const Color(0xffa84f1d),
      (TagCategory.species, true) => const Color(0xff5ed6c4),
      (TagCategory.species, false) => const Color(0xff167568),
      (TagCategory.lore, true) => const Color(0xff9fa8ff),
      (TagCategory.lore, false) => const Color(0xff4d56a8),
      (TagCategory.library, true) => const Color(0xff64d4c5),
      (TagCategory.library, false) => const Color(0xff167568),
    };
  }
}

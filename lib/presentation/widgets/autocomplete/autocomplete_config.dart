/// Presentation options kept for compatibility with existing prompt fields.
/// User-level autocomplete settings take precedence where explicitly set.
class AutocompleteConfig {
  const AutocompleteConfig({
    this.maxSuggestions,
    this.showTranslation = true,
    this.showCategory = true,
    this.showCount = true,
    this.autoInsertComma = true,
    this.treatSpacesAsSeparators = false,
  });

  /// Overrides the user-level result count only for space-constrained fields.
  final int? maxSuggestions;
  final bool showTranslation;
  final bool showCategory;
  final bool showCount;
  final bool autoInsertComma;

  /// Search fields split on spaces and must insert canonical underscore tags.
  final bool treatSpacesAsSeparators;
}

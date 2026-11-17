/// Per-call tag retrieval controls; omitted fields use the reference defaults.
class RagTagSearchOptions {
  const RagTagSearchOptions({
    this.topK,
    this.popularityWeight,
    this.useSegmentation,
    this.targetLayers,
    this.targetCategories,
  });

  final int? topK;
  final double? popularityWeight;
  final bool? useSegmentation;
  final List<String>? targetLayers, targetCategories;

  static RagTagSearchOptions parse(
    Map<String, dynamic> values,
    Never Function(String) invalid,
  ) {
    const keys = {
      'top_k',
      'popularity_weight',
      'use_segmentation',
      'target_layers',
      'target_categories',
    };
    if (values.keys.any((key) => !keys.contains(key))) {
      invalid('Unknown tag_options field');
    }
    final topK = values['top_k'];
    if (values.containsKey('top_k') &&
        (topK is! int || topK < 1 || topK > 80)) {
      invalid('Expected tag_options.top_k 1..80');
    }
    final popularity = values['popularity_weight'];
    if (values.containsKey('popularity_weight') &&
        (popularity is! num ||
            !popularity.isFinite ||
            popularity < 0 ||
            popularity > 1)) {
      invalid('Expected tag_options.popularity_weight 0..1');
    }
    final segmentation = values['use_segmentation'];
    if (values.containsKey('use_segmentation') && segmentation is! bool) {
      invalid('Expected boolean tag_options.use_segmentation');
    }
    List<String>? choices(String key, Set<String> allowed) {
      if (!values.containsKey(key)) return null;
      final value = values[key];
      if (value is! List ||
          value.isEmpty ||
          value.length > allowed.length ||
          value.any((item) => !allowed.contains(item))) {
        invalid('Invalid tag_options.$key');
      }
      return List<String>.unmodifiable(value.cast<String>());
    }

    return RagTagSearchOptions(
      topK: topK as int?,
      popularityWeight: (popularity as num?)?.toDouble(),
      useSegmentation: segmentation as bool?,
      targetLayers: choices('target_layers', {
        'name',
        'synonyms',
        'meaning',
        'core',
      }),
      targetCategories: choices('target_categories', {
        'General',
        'Artist',
        'Copyright',
        'Character',
        'Meta',
        'Other',
      }),
    );
  }

  Map<String, dynamic> toJson({required int limit}) => {
    'top_k': topK ?? limit,
    if (popularityWeight != null) 'popularity_weight': popularityWeight,
    if (useSegmentation != null) 'use_segmentation': useSegmentation,
    if (targetLayers != null) 'target_layers': targetLayers,
    if (targetCategories != null) 'target_categories': targetCategories,
  };
}

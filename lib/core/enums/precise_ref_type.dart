import '../constants/model_spec.dart';

/// Precise reference type for Character Reference feature
///
/// Defines what aspects of the reference image to use:
/// - [character]: Use character appearance only
/// - [style]: Use art style only
/// - [characterAndStyle]: Use both character and style
/// - [outfit]: Use clothing only
enum PreciseRefType {
  /// Use character appearance only
  character,

  /// Use art style only
  style,

  /// Use both character and style
  characterAndStyle,

  /// Use clothing only
  outfit,
}

/// Extension methods for [PreciseRefType]
extension PreciseRefTypeExtension on PreciseRefType {
  bool get supportsPreferSameOutfit =>
      this == PreciseRefType.character ||
      this == PreciseRefType.characterAndStyle;

  bool get defaultPreferSameOutfit => this == PreciseRefType.characterAndStyle;

  String toApiString({bool? preferSameOutfit}) {
    final sameOutfit = preferSameOutfit ?? defaultPreferSameOutfit;
    return switch (this) {
      PreciseRefType.character =>
        sameOutfit ? 'character_mainoutfit' : 'character',
      PreciseRefType.style => 'style',
      PreciseRefType.characterAndStyle =>
        sameOutfit ? 'character&style' : 'character&style_anyoutfit',
      PreciseRefType.outfit => 'costume',
    };
  }

  String toApiStringForModel(ModelSpec spec, {bool? preferSameOutfit}) =>
      toApiString(
        preferSameOutfit: spec.outfitReferences ? preferSameOutfit : null,
      );

  static ({PreciseRefType type, bool? preferSameOutfit}) parseApiCaption(
    String? raw,
  ) => switch (raw?.trim().toLowerCase()) {
    'style' => (type: PreciseRefType.style, preferSameOutfit: null),
    'costume' ||
    'outfit' => (type: PreciseRefType.outfit, preferSameOutfit: null),
    'character&style' || 'character_and_style' || 'character and style' => (
      type: PreciseRefType.characterAndStyle,
      preferSameOutfit: true,
    ),
    'character&style_anyoutfit' => (
      type: PreciseRefType.characterAndStyle,
      preferSameOutfit: false,
    ),
    'character_mainoutfit' => (
      type: PreciseRefType.character,
      preferSameOutfit: true,
    ),
    'character' => (type: PreciseRefType.character, preferSameOutfit: false),
    _ => (type: PreciseRefType.character, preferSameOutfit: null),
  };

  /// Display name key for localization
  /// Use with context.l10n.preciseRef_typeCharacter, etc.
  String get displayNameKey {
    return switch (this) {
      PreciseRefType.character => 'preciseRef_typeCharacter',
      PreciseRefType.style => 'preciseRef_typeStyle',
      PreciseRefType.characterAndStyle => 'preciseRef_typeCharacterAndStyle',
      PreciseRefType.outfit => 'preciseRef_typeOutfit',
    };
  }
}

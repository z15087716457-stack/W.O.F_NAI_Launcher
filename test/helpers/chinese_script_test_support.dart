import 'dart:convert';
import 'dart:io';

Set<int>? _simplifiedOnly;

String _dictionary(String name) => utf8.decode(
  gzip.decode(File('tool/l10n/opencc/$name.txt.gz').readAsBytesSync()),
);

/// Characters that only exist in Simplified Chinese: OpenCC maps them to
/// Traditional characters and never keeps them (unlike shared ones such as
/// 后, 里 or 干), excluding Taiwan-standard forms such as 群 and 峰.
Set<int> simplifiedOnlyCharacters() {
  if (_simplifiedOnly case final cached?) return cached;
  Iterable<List<String>> entries(String name) => const LineSplitter()
      .convert(_dictionary(name))
      .map((line) => line.split('\t'))
      .where((parts) => parts.length == 2);
  final taiwanForms = {
    for (final [_, values] in entries('TWVariants'))
      ...values.split(' ').expand((value) => value.runes),
  };
  return _simplifiedOnly = {
    for (final [key, values] in entries('STCharacters'))
      if (key.runes.length == 1 &&
          !values.split(' ').contains(key) &&
          !taiwanForms.contains(key.runes.single))
        key.runes.single,
  };
}

/// Texts in [texts] that contain a Simplified-only character.
List<String> simplifiedOnlyTexts(Iterable<String> texts) {
  final simplified = simplifiedOnlyCharacters();
  return [
    for (final text in texts)
      if (text.runes.any(simplified.contains)) text,
  ];
}

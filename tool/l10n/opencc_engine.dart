import 'dart:convert';
import 'dart:math' as math;

/// Pure-Dart port of the OpenCC 1.4.2 maximum-match conversion, used at
/// development time with the dictionaries in `tool/l10n/opencc` to generate the
/// Traditional Chinese (Taiwan) resources. Its output matches the official
/// `s2twp` converter; the app itself ships only the generated text.
final class OpenccMatch {
  const OpenccMatch(this.length, this.value);

  /// Matched key length in UTF-16 code units.
  final int length;
  final String value;
}

abstract interface class OpenccMatcher {
  OpenccMatch? match(String text, int start);
}

/// Text dictionary in OpenCC's `key<TAB>value [alternatives]` format. Only the
/// first value is used, as OpenCC does when converting.
final class OpenccDictionary implements OpenccMatcher {
  OpenccDictionary(Map<String, String> entries) : _entries = Map.of(entries) {
    for (final key in _entries.keys) {
      final first = key.codeUnitAt(0);
      _maxLengthByFirstUnit[first] = math.max(
        _maxLengthByFirstUnit[first] ?? 0,
        key.length,
      );
    }
  }

  factory OpenccDictionary.parse(String text) {
    final entries = <String, String>{};
    for (final line in const LineSplitter().convert(text)) {
      final tab = line.indexOf('\t');
      if (tab <= 0) continue;
      final values = line.substring(tab + 1).trim();
      final space = values.indexOf(' ');
      final value = space < 0 ? values : values.substring(0, space);
      if (value.isNotEmpty) {
        entries.putIfAbsent(line.substring(0, tab), () => value);
      }
    }
    return OpenccDictionary(entries);
  }

  final Map<String, String> _entries;
  final Map<int, int> _maxLengthByFirstUnit = {};

  Map<String, String> get entries => _entries;

  @override
  OpenccMatch? match(String text, int start) {
    final limit = _maxLengthByFirstUnit[text.codeUnitAt(start)];
    if (limit == null) return null;
    for (
      var length = math.min(limit, text.length - start);
      length > 0;
      length--
    ) {
      final value = _entries[text.substring(start, start + length)];
      if (value != null) return OpenccMatch(length, value);
    }
    return null;
  }
}

/// The first dictionary with any match wins (OpenCC `short_circuit`).
final class OpenccShortCircuitGroup implements OpenccMatcher {
  const OpenccShortCircuitGroup(this.dictionaries);

  final List<OpenccMatcher> dictionaries;

  @override
  OpenccMatch? match(String text, int start) {
    for (final dictionary in dictionaries) {
      if (dictionary.match(text, start) case final match?) return match;
    }
    return null;
  }
}

/// The longest match across dictionaries wins; ties keep the earlier one
/// (OpenCC `union`).
final class OpenccUnionGroup implements OpenccMatcher {
  const OpenccUnionGroup(this.dictionaries);

  final List<OpenccMatcher> dictionaries;

  @override
  OpenccMatch? match(String text, int start) {
    OpenccMatch? best;
    for (final dictionary in dictionaries) {
      final match = dictionary.match(text, start);
      if (match != null && (best == null || match.length > best.length)) {
        best = match;
      }
    }
    return best;
  }
}

int _charLength(String text, int index) {
  final unit = text.codeUnitAt(index);
  return unit >= 0xD800 &&
          unit <= 0xDBFF &&
          index + 1 < text.length &&
          (text.codeUnitAt(index + 1) & 0xFC00) == 0xDC00
      ? 2
      : 1;
}

/// Replaces every longest dictionary match from left to right.
String openccConvert(String text, OpenccMatcher dictionary) {
  final output = StringBuffer();
  var unmatchedStart = 0;
  var index = 0;
  while (index < text.length) {
    final match = dictionary.match(text, index);
    if (match == null) {
      index += _charLength(text, index);
      continue;
    }
    output
      ..write(text.substring(unmatchedStart, index))
      ..write(match.value);
    index += match.length;
    unmatchedStart = index;
  }
  if (unmatchedStart == 0) return text;
  output.write(text.substring(unmatchedStart));
  return output.toString();
}

/// OpenCC maximum-match segmentation: every match is a segment and the text
/// between matches is grouped into one segment.
List<String> openccSegment(String text, OpenccMatcher dictionary) {
  final segments = <String>[];
  var unmatchedStart = 0;
  var index = 0;
  while (index < text.length) {
    final match = dictionary.match(text, index);
    if (match == null) {
      index += _charLength(text, index);
      continue;
    }
    if (unmatchedStart < index) {
      segments.add(text.substring(unmatchedStart, index));
    }
    segments.add(text.substring(index, index + match.length));
    index += match.length;
    unmatchedStart = index;
  }
  if (unmatchedStart < text.length) {
    segments.add(text.substring(unmatchedStart));
  }
  return segments;
}

/// Text without CJK characters cannot match any bundled dictionary key.
bool openccMayConvert(String text) {
  for (var index = 0; index < text.length; index++) {
    if (text.codeUnitAt(index) >= 0x2E80) return true;
  }
  return false;
}

/// Simplified Chinese to Traditional Chinese (Taiwan standard, with Taiwan
/// phrases): OpenCC's `s2twp` configuration. [terms] are exact Simplified
/// segments with a fixed Taiwan rendering that take part in segmentation.
final class OpenccTaiwanConverter {
  OpenccTaiwanConverter({
    required OpenccDictionary compatibilityIdeographs,
    required OpenccDictionary phrases,
    required OpenccDictionary regionalPhrases,
    required OpenccDictionary characters,
    required OpenccDictionary taiwanPhrases,
    required OpenccDictionary taiwanVariantPhrases,
    required OpenccDictionary taiwanVariants,
    Map<String, String> terms = const {},
  }) : this._(
         compatibilityIdeographs,
         [phrases, regionalPhrases],
         [
           OpenccShortCircuitGroup([
             OpenccUnionGroup([phrases, regionalPhrases]),
             characters,
           ]),
           OpenccShortCircuitGroup([
             taiwanPhrases,
             taiwanVariantPhrases,
             taiwanVariants,
           ]),
         ],
         OpenccDictionary(terms),
       );

  OpenccTaiwanConverter._(
    this._normalization,
    this._phrases,
    this._chain,
    this._terms,
  ) : _segmentation = OpenccUnionGroup([_terms, ..._phrases]);

  /// [texts] maps the bundled dictionary names to their text content.
  factory OpenccTaiwanConverter.fromTexts(
    Map<String, String> texts, {
    Map<String, String> terms = const {},
  }) {
    OpenccDictionary dictionary(String name) =>
        OpenccDictionary.parse(texts[name] ?? (throw ArgumentError(name)));
    return OpenccTaiwanConverter(
      compatibilityIdeographs: dictionary('CJK_Compatibility_Ideographs'),
      phrases: dictionary('STPhrases'),
      regionalPhrases: dictionary('STPhrases_GeneratedFromRegionalPhrases'),
      characters: dictionary('STCharacters'),
      taiwanPhrases: dictionary('TWPhrases'),
      taiwanVariantPhrases: dictionary('TWVariantsPhrases'),
      taiwanVariants: dictionary('TWVariants'),
      terms: terms,
    );
  }

  static const dictionaryNames = [
    'CJK_Compatibility_Ideographs',
    'STPhrases',
    'STPhrases_GeneratedFromRegionalPhrases',
    'STCharacters',
    'TWPhrases',
    'TWVariantsPhrases',
    'TWVariants',
  ];

  final OpenccDictionary _normalization;
  final List<OpenccDictionary> _phrases;
  final List<OpenccMatcher> _chain;
  final OpenccDictionary _terms;
  final OpenccMatcher _segmentation;

  /// Shares the loaded dictionaries with a different set of fixed terms.
  OpenccTaiwanConverter withTerms(Map<String, String> terms) =>
      OpenccTaiwanConverter._(
        _normalization,
        _phrases,
        _chain,
        OpenccDictionary(terms),
      );

  String convert(String text) {
    if (!openccMayConvert(text)) return text;
    final output = StringBuffer();
    for (final segment in openccSegment(
      openccConvert(text, _normalization),
      _segmentation,
    )) {
      final term = _terms.entries[segment];
      if (term != null) {
        output.write(term);
        continue;
      }
      var converted = segment;
      for (final step in _chain) {
        converted = openccConvert(converted, step);
      }
      output.write(converted);
    }
    return output.toString();
  }
}

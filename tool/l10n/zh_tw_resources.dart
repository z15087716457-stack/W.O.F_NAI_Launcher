import 'dart:convert';
import 'dart:io';

import 'opencc_engine.dart';
import 'zh_tw_terms.dart';

/// Traditional Chinese (Taiwan) resources generated from the Simplified
/// sources with OpenCC 1.4.2 `s2twp` and the product terms. The app ships only
/// the generated text. Regenerate after changing app_zh.arb or a curated label
/// list:
///
///   UPDATE_ZH_TW=1 flutter test test/l10n/zh_tw_resources_test.dart
const zhArbPath = 'lib/l10n/app_zh.arb';
const zhTwArbPath = 'lib/l10n/app_zh_TW.arb';
const zhTwLabelsPath = 'lib/l10n/zh_tw_labels.dart';
const zhTwOverridesPath = 'tool/l10n/zh_tw_overrides.json';

OpenccTaiwanConverter zhTwConverter([String root = '.']) =>
    OpenccTaiwanConverter.fromTexts({
      for (final name in OpenccTaiwanConverter.dictionaryNames)
        name: utf8.decode(
          gzip.decode(
            File('$root/tool/l10n/opencc/$name.txt.gz').readAsBytesSync(),
          ),
        ),
    }, terms: zhTwInterfaceTerms);

/// Whole-message corrections reviewed by hand, keyed by ARB message.
Map<String, String> readZhTwOverrides([String root = '.']) {
  final file = File('$root/$zhTwOverridesPath');
  if (!file.existsSync()) return const {};
  return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>).map(
    (key, value) => MapEntry(key, value as String),
  );
}

/// app_zh_TW.arb from app_zh.arb; metadata is copied unchanged.
String generateZhTwArb({
  required String zhArb,
  required OpenccTaiwanConverter converter,
  Map<String, String> overrides = const {},
}) {
  final source = jsonDecode(zhArb) as Map<String, dynamic>;
  final unknown = overrides.keys.where((key) => source[key] is! String);
  if (unknown.isNotEmpty) {
    throw StateError('Overrides for unknown messages: ${unknown.join(', ')}');
  }
  final output = <String, Object?>{'@@locale': 'zh_TW'};
  for (final entry in source.entries) {
    if (entry.key == '@@locale') continue;
    output[entry.key] = entry.key.startsWith('@')
        ? entry.value
        : overrides[entry.key] ?? converter.convert(entry.value as String);
  }
  return '${const JsonEncoder.withIndent('  ').convert(output)}\n';
}

/// A Dart table of the Traditional forms of curated Simplified labels that
/// live in code (Wiki directory, tag groups and categories, button copy).
String generateZhTwLabels({
  required Iterable<String> labels,
  required OpenccTaiwanConverter converter,
}) {
  final entries = <String, String>{
    for (final label in labels.toSet().toList()..sort())
      if (converter.convert(label) case final traditional
          when traditional != label)
        label: traditional,
  };
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE. Do not edit by hand.')
    ..writeln(
      '// Regenerate: UPDATE_ZH_TW=1 flutter test '
      'test/l10n/zh_tw_resources_test.dart',
    )
    ..writeln()
    ..writeln(
      '/// Traditional Chinese (Taiwan) forms of curated Simplified labels,',
    )
    ..writeln('/// converted with OpenCC 1.4.2 s2twp and the product terms in')
    ..writeln(
      '/// tool/l10n. Labels that read the same in both scripts are omitted.',
    )
    ..writeln('const Map<String, String> zhTwLabels = {');
  for (final entry in entries.entries) {
    buffer.writeln('  ${_literal(entry.key)}: ${_literal(entry.value)},');
  }
  buffer.writeln('};');
  return buffer.toString();
}

String _literal(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$').replaceAll('\n', r'\n')}'";

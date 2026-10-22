import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Report 3.1/3.2 plus fixture artist pools. Word boundaries avoid matching
/// short artist names inside unrelated UI words (e.g. `umi` in `luminous`).
final forbidden = <String>{
  ...('sincos|asteroid_ill|ciloranko|yoneyama mai|rella|raoem|mika pikazo|fuzichoco|kantoku|atdan|modare|ningen mame|nardack|tiv|akakura|airfish|wlop|hiten|mignon|kaname rana|shion(mirudakemann)|lobelia (saclia)|bkub|doremi|mx2j|yutokamizu|hwansang|soeyumi|hennnachoco|child (isoliya)|mimitoke|homura subaru|ratatatat74|wanaata|momisan|k-suwabe|miv4t|kuroblood|liduke|demizu posuka|muchi maro|xinzoruo|milkpanda|kurukurumagical|sonao|healthyman|sparrowl|wagashi|freng|parsley|kanzarin|lunch|gaou|lakilolom|rurudo|bm94199|wo_jiushi_kanbudong|nixeu|slash_(slash-soft)|billyhhyb|ruanjia|shal.e|mizumi_zumi|void_0|reoen|possummachine|fkey|yamamoto_souichirou|honnryou_hanaru|shycocoa|quasarcake|ogipote|toosaka asagi|kawacy|namie|torino aqua|houk1se1|ke-ta|wanke|ask (askzy)|momoko (momopoco)|aoi mizuki|kuro neko (studio)|hanabira|tsukishiro|mori no oto|yuzu|shirokane (artist)|kagerou|umi|sakuya hoshino|reverse:1999|1999|nero claudius (fate)|blue archive|shiroko|砂狼白子|zani|wuthering waves|loli|child|nsfw')
      .split('|'),
  r'E:\A.I',
  'PieDriver',
  r'C:\Users\Pie',
  '鹈鹕',
  'pelican',
  'しろいろ',
};

String normalize(String s) => s.toLowerCase().replaceAll('_', ' ');

void loadFixtureBlacklist() {
  for (final file in Directory(
    'lib/presentation/ui',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.contains('fixture') || !file.path.endsWith('.dart')) {
      continue;
    }
    final source = file.readAsStringSync();
    for (final pool in RegExp(
      r'static const _(artists|ar) = \[([\s\S]*?)\];',
    ).allMatches(source)) {
      for (final name in RegExp("'([^']+)'").allMatches(pool.group(2)!)) {
        forbidden.add(name.group(1)!);
      }
    }
    for (final match in RegExp(
      r'artist:([a-zA-Z][a-zA-Z0-9_ .()/-]*?)(?=::|,|\}|\x27|\n)',
    ).allMatches(source)) {
      final name = match.group(1)!.trim();
      if (!name.startsWith('sample_') && !{'example', '名字'}.contains(name)) {
        forbidden.add(name);
      }
    }
  }
}

String? forbiddenMatch(String text) {
  final value = normalize(text);
  for (final word in forbidden) {
    final n = normalize(word);
    final pattern = RegExp('(^|[^a-z0-9])${RegExp.escape(n)}(\$|[^a-z0-9])');
    if (pattern.hasMatch(value)) return word;
  }
  return null;
}

List<String> scanText(WidgetTester tester, String scene) {
  final texts = <String>{};
  for (final element
      in find.byWidgetPredicate((_) => true, skipOffstage: false).evaluate()) {
    final w = element.widget;
    if (w is Text) texts.add(w.data ?? w.textSpan?.toPlainText() ?? '');
    if (w is RichText) texts.add(w.text.toPlainText());
    if (w is EditableText) texts.add(w.controller.text);
  }
  for (final text in texts) {
    final word = forbiddenMatch(text);
    expect(word, isNull, reason: '$scene: forbidden [$word] in "$text"');
  }
  return texts.toList()..sort();
}

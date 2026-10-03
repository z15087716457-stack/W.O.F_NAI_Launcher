import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_directory_labels.dart';
import 'package:nai_launcher/data/models/prompt/tag_category.dart';
import 'package:nai_launcher/data/models/prompt/tag_group.dart';
import 'package:nai_launcher/l10n/zh_tw_labels.dart';

import '../../tool/l10n/opencc_engine.dart';
import '../../tool/l10n/zh_tw_resources.dart';
import '../helpers/chinese_script_test_support.dart';

/// Simplified labels kept in code whose Traditional forms are generated.
Iterable<String> _curatedLabels() => [
  ...WikiDirectoryLabels.chinese.values,
  ...TagGroup.chineseNames.values,
  ...TagSubCategoryHelper.chineseNames.values,
];

void main() {
  final update = Platform.environment['UPDATE_ZH_TW'] == '1';
  late final OpenccTaiwanConverter converter;

  setUpAll(() => converter = zhTwConverter());

  void expectGenerated(String path, String generated) {
    final file = File(path);
    String current() => file.existsSync()
        ? file.readAsStringSync().replaceAll('\r\n', '\n')
        : '';
    if (update && current() != generated) file.writeAsStringSync(generated);
    expect(
      current(),
      generated,
      reason:
          'Run UPDATE_ZH_TW=1 flutter test test/l10n/zh_tw_resources_test.dart '
          'and then flutter gen-l10n',
    );
  }

  test('app_zh_TW.arb is generated from app_zh.arb', () {
    expectGenerated(
      zhTwArbPath,
      generateZhTwArb(
        zhArb: File(zhArbPath).readAsStringSync(),
        converter: converter,
        overrides: readZhTwOverrides(),
      ),
    );
  });

  test('the label table is generated from the curated Simplified lists', () {
    expectGenerated(
      zhTwLabelsPath,
      generateZhTwLabels(labels: _curatedLabels(), converter: converter),
    );
  });

  test('generated Traditional text has no Simplified-only characters', () {
    final arb =
        jsonDecode(File(zhTwArbPath).readAsStringSync())
            as Map<String, dynamic>;
    expect(
      simplifiedOnlyTexts([
        for (final entry in arb.entries)
          if (!entry.key.startsWith('@')) entry.value as String,
        ...zhTwLabels.values,
      ]),
      isEmpty,
    );
    for (final label in _curatedLabels()) {
      expect(
        simplifiedOnlyTexts([zhTwLabels[label] ?? label]),
        isEmpty,
        reason: label,
      );
    }
  });

  test('the engine reproduces OpenCC s2twp and the product terms', () {
    final plain = OpenccTaiwanConverter.fromTexts({
      for (final name in OpenccTaiwanConverter.dictionaryNames)
        name: utf8.decode(
          gzip.decode(File('tool/l10n/opencc/$name.txt.gz').readAsBytesSync()),
        ),
    });
    // Reference output of the official OpenCC 1.4.2 s2twp converter.
    expect(plain.convert('设置默认文件夹，视频软件里的鼠标和网络'), '設定預設資料夾，影片軟體裡的滑鼠和網路');
    expect(plain.convert('长发，头发，发色'), '長髮，頭髮，髮色');
    expect(plain.convert('本地图库'), '本地相簿');
    // Product terms fix OpenCC's IT wording and phrase boundaries.
    expect(converter.convert('本地图库'), '本地圖庫');
    expect(converter.convert('来源文件'), '來源檔案');
    expect(converter.convert('最小化到托盘'), '最小化到系統匣');
    // Placeholders, ICU syntax, ASCII and supplementary characters survive.
    expect(
      converter.convert('{count, plural, =0{没有图片} other{{count} 张图片}}'),
      '{count, plural, =0{沒有圖片} other{{count} 張圖片}}',
    );
    expect(converter.convert('blue_eyes 𠮷'), 'blue_eyes 𠮷');
  });
}

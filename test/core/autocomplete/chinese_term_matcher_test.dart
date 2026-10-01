import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/chinese_term_matcher.dart';

void main() {
  final matcher = ChineseTermMatcher([
    {'name': 'hair', 'cn_name': '头发', 'category': 0, 'post_count': 100},
    {'name': 'long_hair', 'cn_name': '长发；长头发', 'category': 0, 'post_count': 50},
    {'name': 'blue_eyes', 'cn_name': '蓝眼睛', 'category': 0, 'post_count': 80},
    {'name': 'kagamine_rin', 'cn_name': '镜音铃', 'category': 4, 'post_count': 20},
    {'name': 'rin_other', 'cn_name': '镜音铃', 'category': 4, 'post_count': 10},
    {'name': 'white', 'cn_name': '白', 'category': 0, 'post_count': 20},
  ]);
  test('find complete definitions inside prose, longest overlap wins', () {
    const text = '把她改成长头发，保留蓝眼睛，不要镜音铃';
    final hits = matcher.match(text);
    expect(hits.map((h) => h.candidate.canonicalTag), [
      'long_hair',
      'blue_eyes',
      'kagamine_rin',
      'rin_other',
    ]);
    expect(hits.map((h) => text.substring(h.start, h.end)), [
      '长头发',
      '蓝眼睛',
      '镜音铃',
      '镜音铃',
    ]);
    expect(text, '把她改成长头发，保留蓝眼睛，不要镜音铃');
  });
  test(
    'one-character meanings require their own token and limits are bounded',
    () {
      expect(matcher.match('白裙，白').map((h) => h.start), [3]);
      expect(matcher.match('镜音铃，长发', limit: 1), hasLength(1));
      expect(matcher.match('蓝眼睛', limit: 0), isEmpty);
      expect(matcher.match('陌生词语'), isEmpty);
    },
  );
}

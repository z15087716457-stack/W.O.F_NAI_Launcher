import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_bilingual.dart';

void main() {
  group('alignWikiBlocks', () {
    test('pairs identical block structures one to one', () {
      const translated = '介绍段落。\n\n## 标题\n\n第二段。';
      const original = 'Intro paragraph.\n\n## Heading\n\nSecond paragraph.';
      final blocks = alignWikiBlocks(translated, original)!;
      expect(blocks, hasLength(3));
      expect(blocks[0].translated, '介绍段落。');
      expect(blocks[0].original, 'Intro paragraph.');
      expect(blocks[0].heading, isFalse);
      expect(blocks[1].heading, isTrue);
      expect(blocks[1].original, '## Heading');
      expect(blocks[2].translated, '第二段。');
    });

    test('merges compact lists and indented continuations into one block', () {
      const translated = '- [a](wof-tag:a)\n  缩进续行\n- [b](wof-tag:b)\n\n段落';
      const original =
          '- [a](wof-tag:a)\n  continued line\n- [b](wof-tag:b)\n\nParagraph';
      final blocks = alignWikiBlocks(translated, original)!;
      expect(blocks, hasLength(2));
      expect(blocks[0].translated, contains('缩进续行'));
      expect(blocks[0].heading, isFalse);
      expect(blocks[1].original, 'Paragraph');
    });

    test('falls back to section pairing when block counts differ', () {
      const translated = '开头\n\n## 章节\n\n甲\n\n乙';
      const original = 'Intro\n\n## Section\n\nOne\n\nTwo\n\nThree';
      final blocks = alignWikiBlocks(translated, original)!;
      expect(blocks, hasLength(2));
      expect(blocks[0].heading, isFalse);
      expect(blocks[0].original, 'Intro');
      expect(blocks[1].heading, isFalse);
      expect(blocks[1].translated, '## 章节\n\n甲\n\n乙');
      expect(blocks[1].original, '## Section\n\nOne\n\nTwo\n\nThree');
    });

    test('returns null when heading levels differ', () {
      const translated = '段落\n\n## 二级';
      const original = 'Paragraph\n\n### Third level';
      expect(alignWikiBlocks(translated, original), isNull);
    });

    test('returns null when section counts differ', () {
      const translated = '## 一\n\nA\n\n## 二\n\nB';
      const original = '## One\n\nA';
      expect(alignWikiBlocks(translated, original), isNull);
    });

    test('ignores leading and trailing blank lines', () {
      const translated = '\n\n  \n段落。\n\n\n';
      const original = '\nParagraph.\n\n';
      final blocks = alignWikiBlocks(translated, original)!;
      expect(blocks, hasLength(1));
      expect(blocks[0].translated, '段落。');
      expect(blocks[0].original, 'Paragraph.');
    });

    test('returns null for an empty side', () {
      expect(alignWikiBlocks('', 'text'), isNull);
      expect(alignWikiBlocks('text', '   \n  '), isNull);
    });

    test('numbered and starred list markers count as list lines', () {
      const translated = '1. 第一项\n2. 第二项\n\n* 项目';
      const original = '1. First\n2. Second\n\n* Item';
      final blocks = alignWikiBlocks(translated, original)!;
      expect(blocks, hasLength(2));
      expect(blocks[0].translated, '1. 第一项\n2. 第二项');
    });
  });
}

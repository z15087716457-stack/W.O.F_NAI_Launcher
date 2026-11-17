import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_image_document.dart';

void main() {
  test(
    'invalid placeholders stay in prose and disambiguated labels stay clean',
    () {
      const body = '* !asset #0: unavailable\n* !post #3A5906908: invalid ID';
      final doc = WikiImageDocument.parse(body);
      expect(doc.references, isEmpty);
      expect(doc.project(body).body, body);
      expect(
        wikiImageCaptionText('[[Hatsune Miku (Append)|Append]]'),
        'Append',
      );
    },
  );
  test(
    'all source sections, typed identities and duplicate meanings survive',
    () {
      const body = '''
* !asset #1: no heading
h4. Appearance
* !post #1: [b]Default[/b][br]New design
h5. Costumes
* !asset #1: [[alternate_costume|Another outfit]]
h4. Examples
* !post #2: good
h5. Non-examples
* !post #3: bad
''';
      final refs = WikiImageDocument.parse(body).references;
      expect(refs.map((r) => r.key), [
        'asset:1',
        'post:1',
        'asset:1',
        'post:2',
        'post:3',
      ]);
      expect(refs[1].captionText, 'Default New design');
      expect(refs[2].section, ['Appearance', 'Costumes']);
      expect(refs[2].captionText, 'Another outfit');
      expect(refs[0].occurrenceKey, isNot(refs[2].occurrenceKey));
      expect(WikiExampleReference.parse(body).map((r) => r.id), [2]);
    },
  );

  test('code literals do not become images', () {
    const body = '''
[code]!post #10[/code]
```text
!asset #20
```
Use `!post #30` for an image.
* !asset #40
''';
    final doc = WikiImageDocument.parse(body);
    expect(doc.references.map((r) => r.id), [40]);
    final projected = doc.project(body).body;
    expect(projected, contains('!post #10'));
    expect(projected, contains('!asset #20'));
    expect(projected, contains('!post #30'));
    expect(projected, isNot(contains('!asset #40')));
  });

  test(
    'only explicit image rows and fully moved headings leave the display',
    () {
      const body = '''
h4. Definition
An ordinary post #1 explains the rule.
* !post #1: illustration
Keep this explanation on the next line.
h4. Examples
* !asset #2:
h4. See also
* [[solo]]
''';
      final doc = WikiImageDocument.parse(body);
      final projected = doc.project(body).body;
      expect(projected, contains('An ordinary post #1 explains the rule.'));
      expect(projected, contains('Keep this explanation on the next line.'));
      expect(projected, contains('h4. Definition'));
      expect(projected, contains('h4. See also'));
      expect(projected, isNot(contains('h4. Examples')));
      expect(projected, isNot(contains('!post')));
      expect(projected, isNot(contains('!asset')));
      expect(doc.body, body);
    },
  );

  test(
    'plain translated references align by source ID and preserve section identity',
    () {
      const source =
          'h4. Appearance\n* !post #10: default\nh5. Costumes\n* !asset #11: new outfit';
      const translated =
          '## 外观\n* post #10：默认形象\n### 服装\n* asset #11：新服装\n\n不要删除的说明。';
      final projection = WikiImageDocument.parse(source).project(translated);
      expect(projection.references.map((r) => r.caption), ['默认形象', '新服装']);
      expect(projection.references[1].section, ['外观', '服装']);
      expect(projection.body, '## 外观\n### 服装\n\n不要删除的说明。');
    },
  );

  test(
    'ambiguous repeated IDs, mixed prose and tables remain in the article',
    () {
      const source = 'h4. Examples\n* !post #1: one';
      const translated = '## 示例\n* post #1：一\n* post #1：另一处引用';
      expect(
        WikiImageDocument.parse(source).project(translated).body,
        translated,
      );
      const mixed =
          'h4. Definition\nA comparison with !post #1: keep this sentence\n<td>!asset #2: keep this table</td>';
      expect(WikiImageDocument.parse(mixed).project(mixed).body, mixed);
    },
  );

  test('long captions and large articles are not silently truncated', () {
    final caption = 'A full illustration description. ' * 20;
    final body =
        'h4. Costumes\n${List.generate(130, (i) => '* !asset #${i + 1}: $caption').join('\n')}';
    final doc = WikiImageDocument.parse(body);
    expect(doc.references, hasLength(130));
    expect(doc.references.first.caption, caption.trim());
    expect(doc.project(body).body, isEmpty);
  });
}

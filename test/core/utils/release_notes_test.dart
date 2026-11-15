import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/release_notes.dart';

void main() {
  test('published 2.3.4 yields only its ten actual changes', () {
    final raw = File(
      'test/fixtures/release_notes/v2.3.4.md',
    ).readAsStringSync();
    final markdown = updateNotesMarkdown(raw);
    final items = updateNoteItems(raw);
    expect(items, hasLength(10));
    expect(items.first, startsWith('外部 Agent 收起通知'));
    expect(items.last, startsWith('在线画廊大图页'));
    for (final noise in [
      '按系统下载',
      'OS | Download',
      'shields.io',
      'checksums.txt',
      '文件校验',
    ]) {
      expect(markdown, isNot(contains(noise)));
      expect(items.join('\n'), isNot(contains(noise)));
    }
    expect(
      items.any((item) => item.startsWith('-') || item.startsWith('#')),
      isFalse,
    );
  });

  test(
    'plain items preserve wrapping and text while removing inline markup',
    () {
      const raw = '''
## What's new
- **Safe** rollback with [details](https://example.com).
  Wrapped continuation and `code` & text.
### Fixes
- - Duplicate bullets.
## Checksums
private download instructions
''';
      expect(updateNoteItems(raw), [
        'Safe rollback with details. Wrapped continuation and code & text.',
        'Duplicate bullets.',
      ]);
      expect(updateNotesMarkdown(raw), contains('### Fixes'));
    },
  );

  test('fenced examples do not create section boundaries', () {
    const raw = '''
```
## 更新内容
fake section
```
## 📝 更新內容
- Actual change.
```
## example
```
## 文件校验
checksum
''';
    expect(updateNoteItems(raw), ['Actual change.']);
    expect(updateNotesMarkdown(raw), contains('## example'));
    expect(updateNotesMarkdown(raw), isNot(contains('fake section')));
  });

  test(
    'legacy notes retain actual changes and exclude operational sections',
    () {
      const raw = '''
# Release
## Download
- installer link
## 修复下载
- Fixed downloads.
## 新功能
Feature description.
## 文件校验
SHA256
''';
      expect(updateNoteItems(raw), [
        'Fixed downloads.',
        'Feature description.',
      ]);
      expect(
        updateNoteItems(List.generate(35, (i) => '- Change $i').join('\n')),
        hasLength(35),
      );
    },
  );

  test('empty changes never fall back to the whole release page', () {
    expect(updateNoteItems(null), isEmpty);
    expect(updateNotesMarkdown('   '), isEmpty);
    expect(updateNotesMarkdown('## 更新内容\n\n## 下载\nlink'), isEmpty);
  });
}

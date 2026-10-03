import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/retired_dictionary_cleanup.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('retired_dictionary_');
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test('removes only the retired ffdkj folder', () async {
    final dictionary = Directory(p.join(support.path, 'autocomplete', 'ffdkj'));
    await dictionary.create(recursive: true);
    await File(p.join(dictionary.path, 'tag.sqlite')).writeAsString('db');
    final cache = File(p.join(support.path, 'autocomplete', 'cache.db'));
    await cache.writeAsString('cache');

    expect(
      await removeRetiredZhDictionary(supportDirectory: () async => support),
      isTrue,
    );
    expect(await dictionary.exists(), isFalse);
    expect(await cache.readAsString(), 'cache');
    expect(
      await removeRetiredZhDictionary(supportDirectory: () async => support),
      isFalse,
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/codegen_scope.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('codegen_scope_');
  });
  tearDown(() => directory.delete(recursive: true));

  Future<void> source(String path, String contents) async {
    final file = File('${directory.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  test(
    'collects every declared business output but never locked UI or outputs',
    () async {
      await source(
        'lib/data/model.dart',
        "part 'model.freezed.dart';\npart 'model.g.dart';\n@freezed\nclass Model {}",
      );
      await source(
        'lib/presentation/providers/example.dart',
        "part 'example.g.dart';\n@riverpod\nclass Example {}",
      );
      await source(
        'test/fixture.dart',
        "part 'fixture.g.dart';\n@riverpod\nclass Fixture {}",
      );
      await source('lib/data/model.freezed.dart', "part 'accidental.g.dart';");
      await source(
        'lib/presentation/ui/page.dart',
        "@freezed\nfinal example = [?optional];",
      );
      await source(
        'test/presentation/ui/harness.dart',
        "@riverpod\nfinal example = [?optional];",
      );
      await source('lib/plain.dart', 'void main() {}');
      expect(
        await discoverInputs(
          ['lib', 'test'],
          ['lib/presentation/ui/', 'test/presentation/ui/'],
          directory: directory.path,
        ),
        [
          'lib/data/model.dart',
          'lib/presentation/providers/example.dart',
          'test/fixture.dart',
        ],
      );
    },
  );

  test('rejects an annotated input whose generated part is missing', () async {
    await source('lib/missing.dart', '@riverpod\nclass Missing {}');
    await expectLater(
      discoverInputs(['lib'], [], directory: directory.path),
      throwsStateError,
    );
  });

  test(
    'rejects an empty generation scope rather than reporting false success',
    () async {
      await source('lib/plain.dart', 'void main() {}');
      await expectLater(
        discoverInputs(['lib'], [], directory: directory.path),
        throwsStateError,
      );
    },
  );
}

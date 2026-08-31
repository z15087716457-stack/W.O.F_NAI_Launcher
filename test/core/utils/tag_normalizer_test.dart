import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/tag_normalizer.dart';

void main() {
  group('TagNormalizer', () {
    test('normalizes gallery tags for containment matching', () {
      expect(
        TagNormalizer.normalizeTagForMatch('1.25::{{Blue_Eyes}}'),
        equals('blue eyes'),
      );
    });

    test('keeps underscores for database delimited variants', () {
      expect(
        TagNormalizer.normalizeDelimitedSearchSegment('Sweet_One|Shycocoa'),
        equals('sweet_one shycocoa'),
      );
    });

    test(
      'strips autocomplete weight and leading brackets without lowercasing',
      () {
        expect(
          TagNormalizer.normalizeAutocompleteTag('-0.5::{{Blue_Eyes'),
          equals('Blue_Eyes'),
        );
      },
    );

    test('parses comma separated search segments', () {
      expect(
        TagNormalizer.parseDelimitedSearchSegments(' sweetone, shycocoa， '),
        equals(['sweetone', 'shycocoa']),
      );
    });
  });
}

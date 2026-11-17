import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/tag_normalizer.dart';

void main() {
  group('TagNormalizer', () {
    test(
      'gallery terms share weights, whitespace and literal phrase boundaries',
      () {
        expect(
          TagNormalizer.normalizeGalleryQuery('+1.3::blue  eyes::'),
          'blue eyes',
        );
        expect(
          TagNormalizer.normalizeGalleryQuery('silver_hair::'),
          'silver hair',
        );
        expect(TagNormalizer.parseGalleryQuery('-1.5::chibi, dolls, comic::'), [
          'chibi',
          'dolls',
          'comic',
        ]);
        expect(TagNormalizer.parseGalleryQuery('blue  eyes\r\n silver_hair'), [
          'blue eyes',
          'silver hair',
        ]);
        expect(
          TagNormalizer.parseGalleryQuery(
            'hero_(game, version), said "warm, light"',
          ),
          ['hero (game, version)', 'said "warm, light"'],
        );
        expect(
          TagNormalizer.parseGalleryQuery('said "warm\nlight", blue eyes'),
          ['said "warm light"', 'blue eyes'],
        );
        expect(TagNormalizer.parseGalleryQuery(',, ::, {{ }},'), isEmpty);
        expect(
          TagNormalizer.containsGalleryTag(
            '1.2::silver_hair, blue_eyes::',
            'blue eyes',
          ),
          isTrue,
        );
      },
    );
    test('normalizes gallery tags for containment matching', () {
      expect(
        TagNormalizer.normalizeTagForMatch('1.25::{{Blue_Eyes}}'),
        equals('blue eyes'),
      );
    });

    test(
      'gallery query keeps literal punctuation but strips weight syntax',
      () {
        expect(
          TagNormalizer.normalizeGalleryQuery(' 1.25::{{Blue_Eyes}}:: '),
          'blue eyes',
        );
        expect(
          TagNormalizer.normalizeGalleryQuery(' hero_(game) '),
          'hero (game)',
        );
        expect(
          TagNormalizer.normalizeGalleryQuery('a/b\\\\c|d::e;100%'),
          'a/b\\\\c|d::e;100%',
        );
        expect(
          TagNormalizer.containsGalleryTag(
            'blue eyes shadow, solo',
            'blue eyes',
          ),
          isFalse,
        );
        expect(
          TagNormalizer.containsGalleryTag(
            '1.2::blue_eyes::, solo',
            'blue eyes',
          ),
          isTrue,
        );
      },
    );

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

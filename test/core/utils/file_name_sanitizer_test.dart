import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/file_name_sanitizer.dart';

void main() {
  group('FileNameSanitizer', () {
    test('replaces filesystem-invalid and control characters', () {
      expect(
        FileNameSanitizer.sanitize('bad<name>\x00:part?.png'),
        'bad_name___part_.png',
      );
    });

    test('can collapse whitespace for display names', () {
      expect(
        FileNameSanitizer.sanitize(
          '  bad   folder\tname  ',
          collapseWhitespace: true,
        ),
        'bad folder name',
      );
    });

    test('uses fallback after trimming an empty result', () {
      expect(FileNameSanitizer.sanitize('   ', fallback: 'vibe'), 'vibe');
    });

    test('truncates after sanitizing', () {
      expect(FileNameSanitizer.sanitize('abcdef', maxLength: 3), 'abc');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';

void main() {
  test('merge deduplicates whole weighted groups, not their inner tags', () {
    expect(
      mergeExploreRollPositives([
        '0.8::artist:a, artist:b::, solo',
        '0.8::artist:a, artist:b::, 1.2::artist:a, artist:c::, solo',
      ]),
      '0.8::artist:a, artist:b::, solo, 1.2::artist:a, artist:c::',
    );
  });
  test(
    'merge preserves alias, brackets, pipes, quotes, escapes and markers',
    () {
      const syntax = '<alias:x, y>, (a, b), ||a,b|c||, "a,b", a\\,b, \uE000';
      expect(mergeExploreRollPositives([syntax, syntax]), syntax);
    },
  );
  test('merge retains independent implicit numeric boundaries', () {
    expect(
      mergeExploreRollPositives(['2::A, B, 1.5::C::', 'D']),
      '2::A, B, 1.5::C::, D',
    );
  });
  test('merge does not remove an implicit chain terminator as a duplicate', () {
    expect(
      mergeExploreRollPositives(['2::A, 1.5::B::', '3::C, 1.5::B::', 'D']),
      '2::A, 1.5::B::, 3::C, 1.5::B::, D',
    );
  });
  test('merge keeps spaces and existing underscores with Chinese commas', () {
    expect(
      mergeExploreRollPositives(['girl，blue dress', 'blue_eyes, girl']),
      'girl, blue dress, blue_eyes',
    );
  });
  test('merge leaves unclosed syntax intact within an individual positive', () {
    expect(mergeExploreRollPositives(['a, <alias:x, y']), 'a, <alias:x, y');
  });
}

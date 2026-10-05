import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_language.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';
import 'package:nai_launcher/core/wiki/wiki_directory_labels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled official directory resolves nested tag groups', () async {
    final directory = await WikiDirectory.load();
    expect(directory.roots, isNotEmpty);
    expect(directory.groups.containsKey('tag_group:hair'), isTrue);
    expect(directory.tagsForGroup('tag_group:hair'), contains('short_hair'));
  });

  test('every bundled directory label has a Chinese display name', () async {
    final directory = await WikiDirectory.load();
    final labels = <String>{};

    void collect(WikiDirectoryNode node) {
      labels.add(node.label);
      for (final child in node.children) {
        collect(child);
      }
    }

    for (final root in directory.roots) {
      collect(root);
    }
    expect(
      labels.difference(WikiDirectoryLabels.chinese.keys.toSet()),
      isEmpty,
    );
    expect(
      WikiDirectoryLabels.display(
        'Visual characteristics',
        AppLanguage.simplifiedChinese,
      ),
      '视觉特征',
    );
    expect(
      WikiDirectoryLabels.display(
        'Visual characteristics',
        AppLanguage.english,
      ),
      'Visual characteristics',
    );
  });

  test('pathsForTag returns deepest directory paths for real tags', () async {
    final directory = await WikiDirectory.load();
    final stopwatch = Stopwatch()..start();
    final paths = directory.pathsForTag('short_hair');
    stopwatch.stop();
    // Reported to the reviewer; the first call builds the reverse index.
    // ignore: avoid_print
    print('pathsForTag first build: ${stopwatch.elapsedMilliseconds}ms');
    expect(paths, isNotEmpty);
    expect(paths.length, lessThanOrEqualTo(4));
    for (final path in paths) {
      expect(path.length, greaterThanOrEqualTo(2));
      expect(directory.roots, contains(path.first));
      expect(directory.tagsForNode(path.last), contains('short_hair'));
      // Only the deepest containing node is reported.
      for (final child in path.last.children) {
        expect(directory.tagsForNode(child), isNot(contains('short_hair')));
      }
    }
    expect(directory.pathsForTag('short hair'), paths);
    expect(directory.pathsForTag(''), isEmpty);
    expect(directory.pathsForTag('definitely_not_a_real_tag'), isEmpty);
    final repeat = Stopwatch()..start();
    directory.pathsForTag('long_hair');
    repeat.stop();
    expect(repeat.elapsedMilliseconds, lessThan(50));
  });

  test('Traditional Chinese shows generated names without editing the map', () {
    expect(
      WikiDirectoryLabels.display(
        'Visual characteristics',
        AppLanguage.traditionalChinese,
      ),
      '視覺特徵',
    );
    expect(
      WikiDirectoryLabels.display(
        'Hair Styles',
        AppLanguage.traditionalChinese,
      ),
      '髮型',
    );
    expect(WikiDirectoryLabels.chinese['Hair Styles'], '发型');
  });
}

import 'package:flutter_test/flutter_test.dart';
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
    expect(WikiDirectoryLabels.display('Visual characteristics', 'zh'), '视觉特征');
    expect(
      WikiDirectoryLabels.display('Visual characteristics', 'en'),
      'Visual characteristics',
    );
  });
}

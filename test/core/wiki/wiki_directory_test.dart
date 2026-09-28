import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_directory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled official directory resolves nested tag groups', () async {
    final directory = await WikiDirectory.load();
    expect(directory.roots, isNotEmpty);
    expect(directory.groups.containsKey('tag_group:hair'), isTrue);
    expect(directory.tagsForGroup('tag_group:hair'), contains('short_hair'));
  });
}

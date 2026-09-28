import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/wiki_bookmark_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nested collections keep references to canonical tags', () async {
    final store = WikiBookmarkStore();
    await store.load();
    final parent = await store.createCollection('Hair');
    final child = await store.createCollection('Colors', parentId: parent.id);
    await store.addToCollection('Blue Hair', child.id);
    expect(store.contains('blue_hair'), isTrue);
    expect(store.tagsIn(parent.id), {'blue_hair'});
    expect(store.tagsIn(child.id), {'blue_hair'});

    final restored = WikiBookmarkStore();
    await restored.load();
    expect(restored.tagsIn(parent.id), {'blue_hair'});
    await restored.deleteCollection(parent.id);
    expect(restored.collections, isEmpty);
    expect(restored.contains('blue_hair'), isTrue);
    await restored.toggle('blue_hair');
    expect(restored.contains('blue_hair'), isFalse);
  });
}

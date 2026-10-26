import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/settings/settings_preferences_service.dart';
import 'package:nai_launcher/data/services/gallery/gallery_search_history_store.dart';
import 'package:nai_launcher/presentation/wiring/gallery_search_history.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'trim, ignore blank, deduplicate, promote, cap and reload text only',
    () async {
      final store = GallerySearchHistoryStore();
      for (var i = 0; i < 15; i++) {
        await store.add(' q$i ');
      }
      await store.add('  ');
      expect(store.items.length, 12);
      await store.add('q5');
      expect(store.items.first, 'q5');
      expect(store.items.toSet().length, 12);
      expect(await GallerySearchHistoryStore().load(), store.items);
      await store.remove(' q5 ');
      expect(store.items, isNot(contains('q5')));
      await store.clear();
      expect(store.items, isEmpty);
      expect(await GallerySearchHistoryStore().load(), isEmpty);
    },
  );
  test(
    'dirty values are tolerated without casts, duplicate and empty entries',
    () async {
      for (final value in [
        42,
        'bad',
        [' a ', '', 'a', 'b'],
      ]) {
        SharedPreferences.setMockInitialValues({
          StorageKeys.localGallerySearchHistory: value,
        });
        expect(
          await GallerySearchHistoryStore().load(),
          value is List ? ['a', 'b'] : isEmpty,
        );
      }
    },
  );
  test(
    'late add and load cannot resurrect history cleared afterwards',
    () async {
      final gate = Completer<SharedPreferences>();
      final prefs = await SharedPreferences.getInstance();
      final store = GallerySearchHistoryStore(preferences: () => gate.future);
      final add = store.add('old');
      final clear = store.clear();
      gate.complete(prefs);
      await Future.wait([add, clear]);
      expect(store.items, isEmpty);
      expect(await GallerySearchHistoryStore().load(), isEmpty);
      await store.add('new');
      expect(store.items, ['new']);
    },
  );
  test('failed preferences read does not poison the serial queue', () async {
    final prefs = await SharedPreferences.getInstance();
    var fail = true;
    final store = GallerySearchHistoryStore(
      preferences: () async {
        if (fail) throw StateError('fixture read failure');
        return prefs;
      },
    );
    await expectLater(store.add('lost'), throwsStateError);
    fail = false;
    await store.add('saved');
    expect(store.items, ['saved']);
    await store.clear();
    expect(await GallerySearchHistoryStore().load(), isEmpty);
  });

  test('sensitive history is not a public preference export key', () {
    expect(
      SettingsPreferencesService.keys,
      isNot(contains(StorageKeys.localGallerySearchHistory)),
    );
  });
  test('provider exposes serialized items/add/remove/clear', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(gallerySearchHistoryProvider.future);
    final history = container.read(gallerySearchHistoryProvider.notifier);
    await Future.wait([
      history.add('one'),
      history.add('two'),
      history.clear(),
    ]);
    expect(history.items, isEmpty);
    await history.add('three');
    expect(history.items, ['three']);
    await history.remove('three');
    expect(container.read(gallerySearchHistoryProvider).requireValue, isEmpty);
  });
}

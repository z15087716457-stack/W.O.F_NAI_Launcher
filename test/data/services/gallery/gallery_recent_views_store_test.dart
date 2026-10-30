import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/data/services/gallery/gallery_recent_views_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_delete_pool_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_trash_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'concurrent views persist the latest 300 distinct paths across instances',
    () async {
      final store = GalleryRecentViewsStore();
      await Future.wait([
        for (var i = 0; i < 320; i++)
          store.record('C:/gallery/$i.png', at: DateTime(2026, 10, 30, 0, i)),
      ]);
      var restored = await GalleryRecentViewsStore().load();
      expect(restored.length, 300);
      expect(restored.first.path, 'C:/gallery/319.png');
      expect(restored.last.path, 'C:/gallery/20.png');
      await store.record('C:/gallery/20.png', at: DateTime(2026, 11));
      restored = await GalleryRecentViewsStore().load();
      expect(restored.length, 300);
      expect(restored.first.path, 'C:/gallery/20.png');
      expect(restored.first.viewedAt, DateTime(2026, 11));
    },
  );

  test(
    'invalid history is ignored and recording does not change image bytes',
    () async {
      SharedPreferences.setMockInitialValues({
        GalleryRecentViewsStore.key: '{broken',
      });
      final temp = await Directory.systemTemp.createTemp('recent-view-');
      addTearDown(() => temp.delete(recursive: true));
      final image = File('${temp.path}/a.png');
      await image.writeAsBytes([1, 2, 3]);
      final store = GalleryRecentViewsStore();
      expect(await store.load(), isEmpty);
      await store.record(image.path);
      expect(await image.readAsBytes(), [1, 2, 3]);
    },
  );

  test(
    'restore and purge target only pool members and preserve other files',
    () async {
      final temp = await Directory.systemTemp.createTemp('trash-scope-');
      addTearDown(() => temp.delete(recursive: true));
      final a = File('${temp.path}/a.png')..writeAsBytesSync([1]);
      final b = File('${temp.path}/b.png')..writeAsBytesSync([2]);
      final c = File('${temp.path}/c.png')..writeAsBytesSync([3]);
      const pool = GalleryDeletePoolStore();
      await pool.addAll([a.path, b.path]);
      final restored = <String>[];
      final trash = GalleryTrashService(
        restoreIndex: (paths) async => restored.addAll(paths),
      );
      expect(await trash.restore([a.path, c.path]), [a.path]);
      expect(restored, [a.path]);
      expect(await trash.purge([a.path, b.path, c.path]), [b.path]);
      expect(await pool.load(), isEmpty);
      expect(a.existsSync(), isTrue);
      expect(b.existsSync(), isFalse);
      expect(c.existsSync(), isTrue);
    },
  );

  test(
    'failed restore keeps the files pending in the existing delete pool',
    () async {
      const pool = GalleryDeletePoolStore();
      await pool.addAll(['C:/gallery/a.png']);
      final trash = GalleryTrashService(
        restoreIndex: (_) async => throw StateError('fixture database failure'),
      );
      await expectLater(trash.restore(['C:/gallery/a.png']), throwsStateError);
      expect(await pool.load(), ['C:/gallery/a.png']);
    },
  );
}

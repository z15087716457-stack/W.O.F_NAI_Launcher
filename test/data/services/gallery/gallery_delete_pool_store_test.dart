import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/data/services/gallery/gallery_delete_pool_store.dart';

/// 删除池 store 单元测试（SharedPreferences mock + 真实临时文件）
void main() {
  const store = GalleryDeletePoolStore();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load returns empty list when nothing stored', () async {
    expect(await store.load(), isEmpty);
  });

  test('addAll persists paths and deduplicates', () async {
    await store.addAll(['a.png', 'b.png']);
    await store.addAll(['b.png', 'c.png']);

    final paths = await store.load();
    expect(paths, ['a.png', 'b.png', 'c.png']);
  });

  test('removeAll is idempotent and removes only requested paths', () async {
    await store.addAll(['a.png', 'b.png', 'c.png']);

    await store.removeAll(['b.png', 'missing.png']);
    expect(await store.load(), ['a.png', 'c.png']);

    // 幂等：再删一次无变化
    await store.removeAll(['b.png']);
    expect(await store.load(), ['a.png', 'c.png']);
  });

  test('clear empties the pool', () async {
    await store.addAll(['a.png']);
    await store.clear();
    expect(await store.load(), isEmpty);
  });

  test('corrupted stored value degrades to empty pool', () async {
    SharedPreferences.setMockInitialValues({
      'gallery_delete_pool_v1': 'not-json[',
    });
    expect(await store.load(), isEmpty);
  });

  test('cleanupPendingFiles deletes existing files and keeps failures', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'gallery_delete_pool_store_',
    );
    RandomAccessFile? raf;
    try {
      final existing = File('${tempDir.path}/existing.png');
      await existing.writeAsBytes([1, 2, 3]);

      // 打开中的文件在 Windows 上无法删除 → 应保留在池中下次再试
      final locked = File('${tempDir.path}/locked.png');
      await locked.writeAsBytes([1]);
      raf = await locked.open(mode: FileMode.write);

      await store.addAll([
        existing.path,
        '${tempDir.path}/missing.png', // 不存在 = 成功
        locked.path, // 占用 → 失败保留
      ]);

      final deleted = await store.cleanupPendingFiles();

      expect(deleted, 2); // existing + missing
      expect(await existing.exists(), isFalse);
      // locked 保留在池中，下次再试
      expect(await store.load(), [locked.path]);

      // 占用解除后再次清理成功，池清空
      await raf.close();
      raf = null;
      expect(await store.cleanupPendingFiles(), 1);
      expect(await store.load(), isEmpty);
    } finally {
      await raf?.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}

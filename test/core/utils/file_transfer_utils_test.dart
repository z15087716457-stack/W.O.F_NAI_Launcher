import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/file_transfer_utils.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_transfer_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('moveFileCrossVolume', () {
    test('move 正常路径：源消失、目标到位、mtime 保留', () async {
      final src = p.join(tempDir.path, 'source.txt');
      final dst = p.join(tempDir.path, 'sub', 'target.txt');

      final srcFile = File(src);
      await srcFile.writeAsString('test content for move');
      final originalMtime = DateTime.now().subtract(
        const Duration(minutes: 10),
      );
      await srcFile.setLastModified(originalMtime);

      final result = await moveFileCrossVolume(src, dst);

      expect(result, dst);
      expect(await srcFile.exists(), isFalse);
      final dstFile = File(dst);
      expect(await dstFile.exists(), isTrue);
      expect(await dstFile.readAsString(), 'test content for move');
      // rename 应当保留原本的 mtime
      final dstMtime = await dstFile.lastModified();
      expect(
        dstMtime.difference(originalMtime).inSeconds.abs(),
        lessThanOrEqualTo(2),
      );
    });

    test('源不存在时返回 null 且不创建目标', () async {
      final src = p.join(tempDir.path, 'non_existent.txt');
      final dst = p.join(tempDir.path, 'target.txt');

      final result = await moveFileCrossVolume(src, dst);

      expect(result, isNull);
      expect(await File(dst).exists(), isFalse);
    });

    test('回退分支 moveFileCrossVolumeFallback 成功：源消失、目标到位、mtime 保留', () async {
      final src = p.join(tempDir.path, 'fallback_src.txt');
      final dst = p.join(tempDir.path, 'nested', 'fallback_dst.txt');

      final srcFile = File(src);
      await srcFile.writeAsString('fallback content');
      final originalMtime = DateTime.now().subtract(const Duration(hours: 2));
      await srcFile.setLastModified(originalMtime);

      final dstFile = File(dst);
      final result = await moveFileCrossVolumeFallback(srcFile, dstFile);

      expect(result, dst);
      expect(await srcFile.exists(), isFalse);
      expect(await dstFile.exists(), isTrue);
      expect(await dstFile.readAsString(), 'fallback content');
      final dstMtime = await dstFile.lastModified();
      expect(
        dstMtime.difference(originalMtime).inSeconds.abs(),
        lessThanOrEqualTo(2),
      );
    });

    test('注入失败校验器时回退不删源且清理目标副本', () async {
      final src = p.join(tempDir.path, 'protected_src.txt');
      final dst = p.join(tempDir.path, 'failed_dst.txt');

      final srcFile = File(src);
      await srcFile.writeAsString('crucial user data');
      final dstFile = File(dst);

      // 强制校验失败
      final result = await moveFileCrossVolumeFallback(
        srcFile,
        dstFile,
        validator: (s, d) async => false,
      );

      expect(result, isNull);
      // 源文件完好无损！
      expect(await srcFile.exists(), isTrue);
      expect(await srcFile.readAsString(), 'crucial user data');
      // 残留副本已被清理
      expect(await dstFile.exists(), isFalse);
    });
  });

  group('copyFileWithFreshMtime', () {
    test('copy 新 mtime：字节一致、mtime 变新、源保留', () async {
      final src = p.join(tempDir.path, 'copy_src.txt');
      final dst = p.join(tempDir.path, 'sub', 'copy_dst.txt');

      final srcFile = File(src);
      await srcFile.writeAsString('copy content payload');
      final oldMtime = DateTime.now().subtract(const Duration(days: 1));
      await srcFile.setLastModified(oldMtime);

      final beforeCopy = DateTime.now().subtract(const Duration(seconds: 1));
      final result = await copyFileWithFreshMtime(src, dst);
      final afterCopy = DateTime.now().add(const Duration(seconds: 1));

      expect(result, dst);
      expect(await srcFile.exists(), isTrue);
      final dstFile = File(dst);
      expect(await dstFile.exists(), isTrue);
      expect(await dstFile.readAsString(), 'copy content payload');

      final dstMtime = await dstFile.lastModified();
      // 确认 mtime 明显新于 oldMtime，且位于执行窗口内
      expect(dstMtime.isAfter(oldMtime), isTrue);
      expect(dstMtime.isAfter(beforeCopy), isTrue);
      expect(dstMtime.isBefore(afterCopy), isTrue);
    });

    test('源不存在时 copy 返回 null 且不创建目标', () async {
      final src = p.join(tempDir.path, 'no_such_file.txt');
      final dst = p.join(tempDir.path, 'copy_target.txt');

      final result = await copyFileWithFreshMtime(src, dst);

      expect(result, isNull);
      expect(await File(dst).exists(), isFalse);
    });

    test('校验器失败时 copy 终止、清理副本并保留源', () async {
      final src = p.join(tempDir.path, 'copy_validate_src.txt');
      final dst = p.join(tempDir.path, 'copy_validate_dst.txt');

      final srcFile = File(src);
      await srcFile.writeAsString('content');

      final result = await copyFileWithFreshMtime(
        src,
        dst,
        validator: (s, d) async => false,
      );

      expect(result, isNull);
      expect(await srcFile.exists(), isTrue);
      expect(await File(dst).exists(), isFalse);
    });
  });
}

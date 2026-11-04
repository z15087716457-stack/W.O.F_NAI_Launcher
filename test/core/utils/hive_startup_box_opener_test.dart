import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/hive_startup_box_opener.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('nai_hive_startup_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  for (final code in [13, 35]) {
    test(
      'OS open failure $code leaves the box and its lock in place',
      () async {
        final box = File(p.join(hiveDir.path, 'settings.hive'));
        final lock = File(p.join(hiveDir.path, 'settings.lock'));
        await box.writeAsBytes([11, 22, 33]);
        await lock.writeAsBytes([44]);
        final error = FileSystemException(
          'Cannot lock file',
          lock.path,
          OSError('test', code),
        );
        var attempts = 0;
        await expectLater(
          HiveStartupBoxOpener.openBox(
            'settings',
            hivePath: hiveDir.path,
            openBoxOverride: () async {
              attempts++;
              throw error;
            },
          ),
          throwsA(same(error)),
        );
        expect(attempts, 1);
        expect(await box.readAsBytes(), [11, 22, 33]);
        expect(await lock.readAsBytes(), [44]);
        expect(
          await Directory(
            p.join(
              hiveDir.path,
              HiveStartupBoxOpener.recoveryBackupDirectoryName,
            ),
          ).exists(),
          false,
        );
      },
    );
  }

  test(
    'recovers a failed startup box by backing it up and opening a new box',
    () async {
      final staleBoxFile = File(
        p.join(hiveDir.path, '${StorageKeys.historyBox}.hive'),
      );
      await staleBoxFile.writeAsBytes(List<int>.generate(128, (i) => i));

      var attempts = 0;

      final result = await HiveStartupBoxOpener.openBox(
        StorageKeys.historyBox,
        hivePath: hiveDir.path,
        openBoxOverride: () async {
          attempts++;
          if (attempts == 1) {
            throw HiveError('injected startup open failure');
          }
          await Hive.openBox(StorageKeys.historyBox);
        },
      );

      expect(attempts, 2);
      expect(result.recovered, isTrue);
      expect(Hive.isBoxOpen(StorageKeys.historyBox), isTrue);

      final box = Hive.box(StorageKeys.historyBox);
      await box.put('probe', 'ok');
      expect(box.get('probe'), 'ok');

      final backupRoot = Directory(
        p.join(hiveDir.path, HiveStartupBoxOpener.recoveryBackupDirectoryName),
      );
      final backedUpHiveFiles = await backupRoot
          .list(recursive: true)
          .where(
            (entity) =>
                entity is File &&
                p.basename(entity.path) == '${StorageKeys.historyBox}.hive',
          )
          .toList();

      expect(backedUpHiveFiles, hasLength(1));
      expect(
        await (backedUpHiveFiles.single as File).readAsBytes(),
        List<int>.generate(128, (i) => i),
      );
    },
  );
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/hive_storage_helper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../helpers/app_logger_test_isolation.dart';

class MigrationPaths extends PathProviderPlatform {
  MigrationPaths(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => '$root/documents';
  @override
  Future<String?> getApplicationSupportPath() async =>
      '$root/roaming/com.example/nai_launcher';
}

class CopyFaultFile implements File {
  CopyFaultFile(this.inner, this.mode, this.nativeZone);
  final File inner;
  final String mode;
  final Zone nativeZone;
  @override
  String get path => inner.path;
  @override
  Future<bool> exists() => inner.exists();
  @override
  FileStat statSync() => inner.statSync();
  @override
  Future<int> length() => inner.length();
  @override
  Stream<List<int>> openRead([int? start, int? end]) =>
      inner.openRead(start, end);
  @override
  Future<File> copy(String target) async {
    final file = nativeZone.run(() => File(target));
    await file.writeAsBytes([0]);
    if (mode == 'partial') {
      throw const FileSystemException('injected partial copy');
    }
    return file; // Silent corruption must also fail validation.
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      inner.delete(recursive: recursive);
  @override
  dynamic noSuchMethod(Invocation call) => super.noSuchMethod(call);
}

class SourceDirectory implements Directory {
  SourceDirectory(this.inner, this.sourcePath, this.mode, this.nativeZone);
  final Directory inner;
  final String sourcePath, mode;
  final Zone nativeZone;
  @override
  String get path => inner.path;
  @override
  Future<bool> exists() => inner.exists();
  @override
  Future<Directory> create({bool recursive = false}) =>
      inner.create(recursive: recursive);
  @override
  Future<Directory> createTemp([String? prefix]) => inner.createTemp(prefix);
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      inner.delete(recursive: recursive);
  @override
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => inner
      .list(recursive: recursive, followLinks: followLinks)
      .map(
        (entity) => entity is File && p.equals(entity.path, sourcePath)
            ? CopyFaultFile(entity, mode, nativeZone)
            : entity,
      );
  @override
  dynamic noSuchMethod(Invocation call) => super.noSuchMethod(call);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  for (final mode in ['partial', 'corrupt', 'success']) {
    test(
      'Hive migration preserves source and publishes only verified copy: $mode',
      () async {
        final root = await Directory.systemTemp.createTemp('hive_migration_');
        final previous = PathProviderPlatform.instance;
        try {
          final docs = await Directory('${root.path}/documents').create();
          final target = await Directory('${root.path}/target').create();
          final old = await File(
            '${docs.path}/settings.hive',
          ).writeAsBytes(List.filled(5000, 7));
          await File('${docs.path}/settings.lock').writeAsBytes([8]);
          await File('${docs.path}/settings.crc').writeAsBytes([9]);
          final destination = await File(
            '${target.path}/settings.hive',
          ).writeAsBytes([2, 3]);
          PathProviderPlatform.instance = MigrationPaths(root.path);
          final nativeZone = Zone.current;
          if (mode == 'success') {
            await HiveStorageHelper.instance.migrateFromOldLocation(
              target.path,
            );
          } else {
            await IOOverrides.runZoned(
              () => HiveStorageHelper.instance.migrateFromOldLocation(
                target.path,
              ),
              createDirectory: (path) => SourceDirectory(
                nativeZone.run(() => Directory(path)),
                old.path,
                mode,
                nativeZone,
              ),
            );
          }
          expect(await old.readAsBytes(), List.filled(5000, 7));
          expect(await File('${docs.path}/settings.lock').readAsBytes(), [8]);
          expect(await File('${docs.path}/settings.crc').readAsBytes(), [9]);
          expect(
            await destination.readAsBytes(),
            mode == 'success' ? List.filled(5000, 7) : [2, 3],
          );
          expect(
            await target.list().where((e) => e is Directory).toList(),
            isEmpty,
          );
        } finally {
          PathProviderPlatform.instance = previous;
          await root.delete(recursive: true);
        }
      },
    );
  }
}

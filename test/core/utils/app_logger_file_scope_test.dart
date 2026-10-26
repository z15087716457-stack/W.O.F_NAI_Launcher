import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory directory;

  setUp(() async {
    await AppLogger.initialize(enableFileLogging: false);
    AppLoggerTestIsolation.setUp();
    directory = Directory(AppLogger.debugLogDirectoryOverride!);
    AppLogger.debugLogDirectoryOverride = null;
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await AppLoggerTestIsolation.tearDown();
  });

  Future<File> file(String name, {bool oversized = false}) async {
    final result = File(p.join(directory.path, name));
    await result.parent.create(recursive: true);
    await result.writeAsString('fixture');
    if (oversized) {
      final handle = await result.open(mode: FileMode.append);
      await handle.truncate(100 * 1024 * 1024 + 1);
      await handle.close();
    }
    await result.setLastModified(DateTime.utc(2025, 1, 1));
    return result;
  }

  test('Documents failure keeps logs in an app subdirectory of temp', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'fixture_documents_unavailable');
    });
    final rootFiles = [
      await file('app_fixture_notes.txt'),
      await file('app_20250101_120000.log'),
      await file('test_20250102_120000.log'),
      await file('app_20250103_120000.log'),
    ];
    await IOOverrides.runZoned(() async {
      await AppLogger.setFileLoggingEnabled(true);
      await AppLogger.flush();
    }, getSystemTempDirectory: () => directory);
    expect(
      AppLogger.logDirectory,
      p.join(directory.path, 'NAI_Launcher', 'logs'),
    );
    for (final item in rootFiles) {
      expect(await item.readAsString(), 'fixture');
    }
    expect(
      AppLogger.currentLogFile,
      startsWith('${AppLogger.logDirectory}${p.separator}'),
    );
  });

  test('cleanup and listing recognize only complete app log names', () async {
    AppLogger.debugLogDirectoryOverride = directory.path;
    final unrelated = [
      await file('app_notes.txt', oversized: true),
      await file('test_20250101_120000.log.backup'),
      await file('app_20250101_120000.log.txt'),
      await file('app_unknown.log'),
      await file('other_20250101_120000.log'),
    ];
    for (var i = 1; i <= 4; i++) {
      final log = await file('app_2025010${i}_120000.log');
      await log.setLastModified(DateTime.utc(2025, 1, i));
    }
    final oversized = await file('test_20240101_120000.log', oversized: true);
    await AppLogger.setFileLoggingEnabled(true);
    await AppLogger.flush();
    expect(await oversized.exists(), isFalse);
    final names = (await AppLogger.getLogFiles())
        .map((f) => p.basename(f.path))
        .toList();
    expect(names, hasLength(3));
    expect(names.skip(1), [
      'app_20250104_120000.log',
      'app_20250103_120000.log',
    ]);
    expect(names.first, p.basename(AppLogger.currentLogFile!));
    for (final item in unrelated) {
      expect(await item.exists(), isTrue, reason: item.path);
    }
    expect(await unrelated.first.length(), 100 * 1024 * 1024 + 1);
  });
}

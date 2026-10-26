import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/utils/dropped_file_reader.dart';
import 'package:nai_launcher/presentation/wiring/refs_drop_reader.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../helpers/agent_data_reader.dart';
import '../../helpers/app_logger_test_isolation.dart';

class _UriReader extends AgentFixtureDataReader {
  _UriReader(Uri uri) : super(fileUri: uri);
  bool returned = false;
  int uriReads = 0;
  @override
  ReadProgress? getValue<T extends Object>(
    ValueFormat<T> value,
    AsyncValueChanged<T?> onValue, {
    ValueChanged<Object>? onError,
  }) {
    if (returned) throw StateError('native reader expired');
    uriReads++;
    return super.getValue(value, onValue, onError: onError);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('refs-drop-reader-');
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'file URI capture starts before callback returns and needs no live reader for file IO',
    () async {
      final file = await File(
        '${directory.path}/test.png',
      ).writeAsBytes([1, 2, 3]);
      final reader = _UriReader(file.uri);
      final pending = DroppedFileReader.capture(reader);
      expect(reader.uriReads, 1);
      reader.returned = true;
      final data = await pending;
      expect(data!.fileName, 'test.png');
      expect(data.bytes, [1, 2, 3]);
      expect(data.sourcePath, file.uri.toFilePath());
      expect(reader.fileReads, 0);
    },
  );

  test(
    'library drop captures all file URIs before async directory reading, deduplicates paths',
    () async {
      final a = await File('${directory.path}/a.png').writeAsBytes([1]);
      final b = await File('${directory.path}/b.naiv4vibe').writeAsBytes([2]);
      final readers = [_UriReader(a.uri), _UriReader(b.uri), _UriReader(a.uri)];
      final pending = RefsDropReader.read(readers, RefsKind.vibe);
      expect(readers.map((r) => r.uriReads), [1, 1, 1]);
      for (final reader in readers) {
        reader.returned = true;
      }
      final files = await pending;
      expect(files.map((f) => f.fileName), ['a.png', 'b.naiv4vibe']);
      expect(files.map((f) => f.bytes), [
        Uint8List.fromList([1]),
        Uint8List.fromList([2]),
      ]);
      expect(readers.every((r) => r.fileReads == 0), isTrue);
    },
  );

  test(
    'hover cancelled before URI completion does not read the local file',
    () async {
      final reader = _UriReader(Uri.file('${directory.path}/missing.png'));
      var current = true;
      final pending = RefsDropReader.read(
        [reader],
        RefsKind.vibe,
        isCurrent: () => current,
      );
      current = false;
      expect(await pending, isEmpty);
    },
  );
}

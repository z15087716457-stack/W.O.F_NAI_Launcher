import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/utils/dropped_file_reader.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  group('DroppedFileReader', () {
    test('skips remote URL lookup when remote images are disabled', () async {
      final reader = _PlainTextDataReader(
        'https://cdn.example.test/images/copied.png',
      );

      final result = await DroppedFileReader.read(
        reader,
        allowRemoteImages: false,
      );

      expect(result, isNull);
    });

    for (final contentType in ['image/png', 'application/octet-stream']) {
      for (final (encoded, expected) in [
        ('ordinary.png', 'ordinary.png'),
        ('100%25nice.png', '100%nice.png'),
        ('literal%2541.png', 'literal%41.png'),
        ('%E7%94%BB%E5%9B%BE.png', '画图.png'),
      ]) {
        test(
          'remote $encoded with $contentType keeps its once-decoded filename',
          () async {
            final png = base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+j3ioAAAAASUVORK5CYII=',
            );
            final server = await HttpServer.bind(
              InternetAddress.loopbackIPv4,
              0,
            );
            final subscription = server.listen((request) async {
              request.response.headers.set('content-type', contentType);
              request.response.add(png);
              await request.response.close();
            });
            addTearDown(() async {
              await server.close(force: true);
              await subscription.cancel();
            });
            final result = await DroppedFileReader.read(
              _PlainTextDataReader('http://127.0.0.1:${server.port}/$encoded'),
            );
            expect(result, isNotNull);
            expect(result!.fileName, expected);
            expect(result.bytes, png);
          },
        );
      }
    }

    test(
      'Content-Disposition UTF-8 filename still decodes its encoded field once',
      () {
        expect(
          DroppedFileReader.inferFileNameFromUri(
            Uri.parse('http://fixture.invalid/blob'),
            contentType: 'image/png',
            contentDisposition: "attachment; filename*=UTF-8''100%25nice.png",
          ),
          '100%nice.png',
        );
      },
    );

    test(
      'a plain Content-Disposition filename preserves its literal percent',
      () {
        expect(
          DroppedFileReader.inferFileNameFromUri(
            Uri.parse('http://fixture.invalid/blob'),
            contentType: 'image/png',
            contentDisposition: 'attachment; filename="literal%41.png"',
          ),
          'literal%41.png',
        );
      },
    );
  });
}

class _PlainTextDataReader extends DataReader {
  _PlainTextDataReader(this.text);

  final String text;

  @override
  bool canProvide(DataFormat format) => format == Formats.plainText;

  @override
  List<DataFormat> getFormats(List<DataFormat> allFormats) {
    return allFormats
        .where((format) => format == Formats.plainText)
        .toList(growable: false);
  }

  @override
  ReadProgress? getValue<T extends Object>(
    ValueFormat<T> format,
    AsyncValueChanged<T?> onValue, {
    ValueChanged<Object>? onError,
  }) {
    if (!identical(format, Formats.plainText)) {
      return null;
    }
    Future<void>.microtask(() async {
      await onValue(text as T);
    });
    return _CompletedReadProgress();
  }

  @override
  ReadProgress? getFile(
    FileFormat? format,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    return null;
  }

  @override
  bool isSynthesized(DataFormat format) => false;

  @override
  bool isVirtual(DataFormat format) => false;

  @override
  Future<String?> getSuggestedName() async => null;

  @override
  Future<VirtualFileReceiver?> getVirtualFileReceiver({
    FileFormat? format,
  }) async {
    return null;
  }

  @override
  List<PlatformFormat> get platformFormats => const [];
}

class _CompletedReadProgress extends ReadProgress {
  final ValueNotifier<double?> _fraction = ValueNotifier<double?>(1);
  final ValueNotifier<bool> _cancellable = ValueNotifier<bool>(false);

  @override
  ValueListenable<double?> get fraction => _fraction;

  @override
  ValueListenable<bool> get cancellable => _cancellable;

  @override
  void cancel() {}
}

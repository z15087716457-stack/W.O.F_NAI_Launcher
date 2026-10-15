import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/rag/rag_model_download.dart';

class FixtureAdapter implements HttpClientAdapter {
  FixtureAdapter(this.response);
  final ResponseBody Function(RequestOptions) response;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return response(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory directory;
  const revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final bytes = utf8.encode('verified-small-model-fixture');
  late Map<String, dynamic> manifest;
  late FixtureAdapter adapter;
  late RagModelDownloader downloader;
  File target([String suffix = '']) => File(
    p.join(
      directory.path,
      'models',
      'embedding',
      revision,
      'model.safetensors$suffix',
    ),
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rag-model-');
    manifest = {
      'version': 1,
      'models': [
        {
          'id': 'embedding',
          'repository': 'google/embeddinggemma-2',
          'revision': revision,
          'files': [
            {
              'path': 'model.safetensors',
              'bytes': bytes.length,
              'sha256': sha256.convert(bytes).toString(),
            },
          ],
        },
      ],
    };
    adapter = FixtureAdapter((_) => ResponseBody.fromBytes(bytes, 200));
    final dio = Dio()..httpClientAdapter = adapter;
    downloader = RagModelDownloader(
      directory,
      dio: dio,
      manifestLoader: () async => jsonEncode(manifest),
    );
  });
  tearDown(() async {
    downloader.dispose();
    await directory.delete(recursive: true);
  });
  test(
    'downloads pinned files, publishes receipt and reuses verified files',
    () async {
      final progress = <RagModelDownloadProgress>[];
      final path = await downloader.install('embedding', progress.add);
      expect(await target().readAsBytes(), bytes);
      expect(await File(p.join(path, 'model-receipt.json')).exists(), isTrue);
      expect(adapter.requests.single.uri.path, contains('/resolve/$revision/'));
      expect(progress.last.fraction, 1);
      await downloader.install('embedding', progress.add);
      expect(adapter.requests, hasLength(1));
    },
  );
  test('resumes a verified range without downloading existing bytes', () async {
    await target('.part').parent.create(recursive: true);
    await target('.part').writeAsBytes(bytes.take(5).toList());
    adapter = FixtureAdapter((r) {
      expect(r.headers['Range'], 'bytes=5-');
      return ResponseBody.fromBytes(
        bytes.sublist(5),
        206,
        headers: {
          'content-range': ['bytes 5-${bytes.length - 1}/${bytes.length}'],
        },
      );
    });
    downloader.dispose();
    downloader = RagModelDownloader(
      directory,
      dio: Dio()..httpClientAdapter = adapter,
      manifestLoader: () async => jsonEncode(manifest),
    );
    await downloader.install('embedding', (_) {});
    expect(await target().readAsBytes(), bytes);
  });
  test(
    'a server ignoring Range restarts rather than appending the whole file',
    () async {
      await target('.part').parent.create(recursive: true);
      await target('.part').writeAsBytes(bytes.take(5).toList());
      await downloader.install('embedding', (_) {});
      expect(await target().readAsBytes(), bytes);
    },
  );
  test('corrupt bytes never produce an installed receipt', () async {
    (manifest['models'][0]['files'][0] as Map)['sha256'] = '0' * 64;
    await expectLater(
      downloader.install('embedding', (_) {}),
      throwsA(predicate((e) => e.toString().contains('model_integrity'))),
    );
    expect(await target().exists(), isFalse);
    expect(await target('.part').exists(), isFalse);
  });
  test(
    'cancellation retains partial bytes and leaves final path unpublished',
    () async {
      await expectLater(
        downloader.install('embedding', (_) => downloader.cancel()),
        throwsA(predicate((e) => e.toString().contains('cancel'))),
      );
      expect(await target().exists(), isFalse);
      expect(await target('.part').exists(), isTrue);
      expect(
        await File(p.join(target().parent.path, 'model-receipt.json')).exists(),
        isFalse,
      );
    },
  );
  test('rejects traversal paths in the manifest', () async {
    manifest['models'][0]['files'][0]['path'] = '../outside';
    await expectLater(
      downloader.install('embedding', (_) {}),
      throwsA(anything),
    );
    expect(adapter.requests, isEmpty);
  });
  test(
    'repairs only an invalid managed file after successful verification',
    () async {
      await target().parent.create(recursive: true);
      await target().writeAsString('bad');
      await downloader.install('embedding', (_) {});
      expect(await target().readAsBytes(), bytes);
    },
  );
}

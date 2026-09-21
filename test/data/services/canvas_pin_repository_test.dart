import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';

/// 纯内存存储，绕开真实 Hive（getSetting/setSetting 是仓库唯一依赖面）。
class _MemoryStorage extends LocalStorageService {
  final Map<String, Object?> values = {};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values.containsKey(key) ? values[key] : defaultValue) as T?;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

void main() {
  late Directory tempRoot;
  late Directory pinDir;
  late _MemoryStorage storage;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('canvas_pin_repo_test_');
    pinDir = Directory('${tempRoot.path}/canvas_pins');
    storage = _MemoryStorage();
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  CanvasPinRepository repo({
    int maxPins = CanvasPinRepository.defaultMaxPins,
  }) => CanvasPinRepository(
    storage: storage,
    directory: pinDir,
    maxPins: maxPins,
  );

  GeneratedImage image(
    String id,
    List<int> bytes, {
    int width = 64,
    int height = 32,
    int? createdAtMs,
    NaiImageMetadata? metadata,
  }) => GeneratedImage(
    id: id,
    bytes: Uint8List.fromList(bytes),
    width: width,
    height: height,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      createdAtMs ?? 1700000000000,
    ),
    generationRunId: 7,
    batchIndex: 0,
    metadata: metadata,
  );

  Map<String, dynamic> storedManifest() =>
      jsonDecode(storage.values[CanvasPinRepository.manifestKey] as String)
          as Map<String, dynamic>;

  test('pin persists bytes and survives a "restart" via loadAll', () async {
    final created = image('img-a', [1, 2, 3, 4], createdAtMs: 1699999999000);
    final pinned = await repo().addPin(created);

    // 私有副本不能使下载按钮误以为图片已经存入图库。
    expect(pinned.id, 'img-a');
    expect(pinned.generationRunId, isNull);
    expect(pinned.batchIndex, isNull);
    expect(pinned.filePath, isNull);

    // “重启”：全新仓库实例，同一 storage + 目录。
    final restored = await repo().loadAll();
    expect(restored, hasLength(1));
    final back = restored.single;
    expect(back.id, 'img-a');
    expect(back.bytes, created.bytes);
    expect(back.width, 64);
    expect(back.height, 32);
    expect(back.createdAt.millisecondsSinceEpoch, 1699999999000);
    expect(back.kind, GeneratedImageKind.completed);
    expect(back.generationRunId, isNull);
  });

  test('fileNameForBytes is deterministic, hex-only, and path-safe', () {
    final a = CanvasPinRepository.fileNameForBytes(Uint8List.fromList([1, 2]));
    final b = CanvasPinRepository.fileNameForBytes(Uint8List.fromList([3]));
    expect(a, matches(RegExp(r'^[0-9a-f]{64}\.png$')));
    expect(a, isNot(contains('..')));
    expect(a, isNot(contains('/')));
    expect(a, isNot(contains(r'\')));
    expect(a, isNot(b));
    // 同名输入幂等。
    expect(CanvasPinRepository.fileNameForBytes(Uint8List.fromList([1, 2])), a);
  });

  test(
    'object-only metadata survives restart without changing image bytes',
    () async {
      final original = image(
        'metadata',
        [1, 2, 3],
        metadata: const NaiImageMetadata(
          prompt: 'original',
          seed: 123,
          characterInfos: [
            CharacterPromptInfo(prompt: 'person', centerX: .2, centerY: .8),
          ],
        ),
      );
      await repo().addPin(original);
      final restored = (await repo().loadAll()).single;
      expect(restored.bytes, original.bytes);
      expect(restored.metadata, original.metadata);
    },
  );

  test('malformed numeric records cannot abort manifest restoration', () {
    for (final value in [double.nan, double.infinity, 1e30]) {
      expect(
        CanvasPinRecord.tryParse({
          'id': 'bad',
          'file': 'x.png',
          'width': 1,
          'height': 1,
          'createdAt': value,
        }),
        isNull,
      );
    }
  });

  test('identical pixels under multiple pin ids share one copy', () async {
    final repository = repo();
    await repository.addPin(image('pin-1', [9, 9, 9]));
    await repository.addPin(image('pin-2', [9, 9, 9]));

    expect(repository.readManifest().map((r) => r.imageId), ['pin-1', 'pin-2']);
    // 内容寻址：相同字节共用一份文件。
    final files = await pinDir.list().toList();
    expect(files, hasLength(1));

    final restored = await repo().loadAll();
    expect(restored.map((i) => i.id), ['pin-1', 'pin-2']);
    expect(restored[0].bytes, restored[1].bytes);
  });

  test('missing and corrupt entries are skipped, healthy ones kept', () async {
    final repository = repo();
    await repository.addPin(image('keep', [1]));
    await repository.addPin(image('gone', [2]));
    await repository.addPin(image('rotten', [3]));

    final records = repository.readManifest();
    // 文件缺失。
    await File(
      '${pinDir.path}/${records.firstWhere((r) => r.imageId == 'gone').fileName}',
    ).delete();
    // 内容被篡改：字节与哈希文件名不匹配。
    await File(
      '${pinDir.path}/${records.firstWhere((r) => r.imageId == 'rotten').fileName}',
    ).writeAsBytes([255]);

    final restored = await repo().loadAll();
    expect(restored.map((i) => i.id), ['keep']);
  });

  test('manifest entries escaping the pin dir are never read', () async {
    // 目录外放一个"机密"文件，manifest 用 ../ 与绝对路径去指它。
    final outside = File('${tempRoot.path}/secret.bin');
    await outside.writeAsBytes([7, 7, 7]);
    storage.values[CanvasPinRepository.manifestKey] = jsonEncode({
      'version': 1,
      'records': [
        {
          'id': 'evil-rel',
          'file': '../secret.bin',
          'width': 1,
          'height': 1,
          'createdAt': 0,
        },
        {
          'id': 'evil-abs',
          'file': outside.path,
          'width': 1,
          'height': 1,
          'createdAt': 0,
        },
      ],
    });

    expect(await repo().loadAll(), isEmpty);
    expect(await outside.readAsBytes(), [7, 7, 7]);
  });

  test(
    'malformed manifest records are skipped without dropping good ones',
    () async {
      final repository = repo();
      await repository.addPin(image('good', [5, 6]));
      final manifest = storedManifest();
      (manifest['records'] as List).addAll([
        'not-a-map',
        {'id': '', 'file': 'x.png', 'width': 1, 'height': 1},
        {'id': 'no-file', 'width': 1, 'height': 1},
        {'id': 'bad-dims', 'file': 'x.png', 'width': 0, 'height': 1},
        // 重复 id：首个 wins，第二个跳过。
        {
          'id': 'good',
          'file': 'deadbeef.png',
          'width': 2,
          'height': 2,
          'createdAt': 1,
        },
      ]);
      storage.values[CanvasPinRepository.manifestKey] = jsonEncode(manifest);

      final records = repo().readManifest();
      expect(records.map((r) => r.imageId), ['good']);
      expect(await repo().loadAll(), hasLength(1));
    },
  );

  test(
    'completely garbled manifest restores nothing but does not throw',
    () async {
      storage.values[CanvasPinRepository.manifestKey] = '{not json';
      expect(repo().readManifest(), isEmpty);
      expect(await repo().loadAll(), isEmpty);
    },
  );

  test('no manifest means zero filesystem I/O', () async {
    expect(await repo().loadAll(), isEmpty);
    expect(await pinDir.exists(), isFalse);
    expect(storage.values.containsKey('canvas_pinned_images'), isFalse);
  });

  test(
    'removePin drops manifest membership but keeps the copy on disk',
    () async {
      final repository = repo();
      await repository.addPin(image('stay', [1]));
      await repository.addPin(image('leave', [2]));
      final leaveName = repository
          .readManifest()
          .firstWhere((r) => r.imageId == 'leave')
          .fileName;
      final leaveFile = File('${pinDir.path}/$leaveName');

      await repository.removePin('leave');

      expect(repo().readManifest().map((r) => r.imageId), ['stay']);
      expect(await leaveFile.exists(), isTrue);
      expect((await repo().loadAll()).map((i) => i.id), ['stay']);
    },
  );

  test(
    'pin count is bounded: beyond maxPins addPin throws, manifest intact',
    () async {
      final repository = repo(maxPins: 1);
      await repository.addPin(image('first', [1]));
      await expectLater(
        repository.addPin(image('second', [2])),
        throwsA(isA<StateError>()),
      );
      expect(repository.readManifest().map((r) => r.imageId), ['first']);
      // 超限写未落盘：pin 目录里仍只有一份副本。
      expect(await pinDir.list().toList(), hasLength(1));
    },
  );
}

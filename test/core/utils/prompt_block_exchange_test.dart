import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_block_exchange.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'prompt_block_exchange_test_',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  PromptBlockLibraryData libraryOf({
    List<PromptBlock> blocks = const [],
    List<PromptBlockFolder> folders = const [],
  }) => PromptBlockLibraryData(blocks: blocks, folders: folders);

  group('contentHash', () {
    test('is stable and content-sensitive', () {
      final a = PromptBlockExchange.contentHash('artist-a, artist-b');
      expect(a, PromptBlockExchange.contentHash('artist-a, artist-b'));
      expect(a, isNot(PromptBlockExchange.contentHash('artist-a, artist-c')));
      expect(a, hasLength(64));
    });
  });

  group('readTxtFiles', () {
    test('reads content as-is and strips a UTF-8 BOM', () async {
      final plain = await File(
        '${tempDir.path}${Platform.pathSeparator}plain.txt',
      ).writeAsString('line 1\nline 2', flush: true);
      final bombed = File('${tempDir.path}${Platform.pathSeparator}bom.txt');
      await bombed.writeAsBytes([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('带 BOM 的内容'),
      ], flush: true);

      final files = await PromptBlockExchange.readTxtFiles([
        plain.path,
        bombed.path,
      ]);

      expect(files[0].content, 'line 1\nline 2');
      expect(files[1].content, '带 BOM 的内容');
      expect(files[1].hash, PromptBlockExchange.contentHash('带 BOM 的内容'));
    });

    test('throws for a missing source file', () async {
      expect(
        () => PromptBlockExchange.readTxtFiles([
          '${tempDir.path}${Platform.pathSeparator}missing.txt',
        ]),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('scanTxtDirectory', () {
    test(
      'recursively collects txt files case-insensitively and sorted',
      () async {
        final root = Directory(
          '${tempDir.path}${Platform.pathSeparator}curation',
        );
        await Directory(
          '${root.path}${Platform.pathSeparator}sub',
        ).create(recursive: true);
        await File(
          '${root.path}${Platform.pathSeparator}b.txt',
        ).writeAsString('b');
        await File(
          '${root.path}${Platform.pathSeparator}a.TXT',
        ).writeAsString('a');
        await File(
          '${root.path}${Platform.pathSeparator}sub${Platform.pathSeparator}c.txt',
        ).writeAsString('c');
        await File(
          '${root.path}${Platform.pathSeparator}d.md',
        ).writeAsString('not txt');

        final files = await PromptBlockExchange.scanTxtDirectory(root.path);

        expect(files.map((f) => f.title).toList(), ['a', 'b', 'c']);
        expect(files[2].path, contains('sub'));
      },
    );

    test('throws for a missing directory', () async {
      expect(
        () => PromptBlockExchange.scanTxtDirectory(
          '${tempDir.path}${Platform.pathSeparator}missing',
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('curationFolderChain', () {
    test('mirrors root name plus relative directory segments', () {
      final root = Directory('${tempDir.path}${Platform.pathSeparator}画师策展');
      final nested = File(
        '${root.path}${Platform.pathSeparator}外部池${Platform.pathSeparator}a.txt',
      );
      final direct = File('${root.path}${Platform.pathSeparator}b.txt');

      expect(
        PromptBlockExchange.curationFolderChain(
          PromptBlockExchangeFile(path: nested.path, content: ''),
          root.path,
        ),
        ['画师策展', '外部池'],
      );
      expect(
        PromptBlockExchange.curationFolderChain(
          PromptBlockExchangeFile(path: direct.path, content: ''),
          root.path,
        ),
        ['画师策展'],
      );
    });
  });

  group('buildPlan', () {
    test('classifies create / skipUnchanged / update with localModified', () {
      const contentV1 = 'v1';
      const contentV2 = 'v2';
      final hashV1 = PromptBlockExchange.contentHash(contentV1);
      const pathA = '/src/a.txt';
      const pathB = '/src/B.TXT';
      const pathC = '/src/c.txt';

      final library = libraryOf(
        blocks: [
          // b 未变更;c 来源文件已变化,且块正文与上次导入记录一致。
          PromptBlock.create(
            id: 'b1',
            title: 'b',
            content: contentV1,
            sourcePath: '/src/b.txt',
            sourceHash: hashV1,
          ),
          PromptBlock.create(
            id: 'c1',
            title: 'c',
            content: contentV1,
            sourcePath: pathC,
            sourceHash: hashV1,
          ),
          PromptBlock.create(
            id: 'd1',
            title: 'd',
            content: '手动改过',
            sourcePath: '/src/d.txt',
            sourceHash: hashV1,
          ),
        ],
      );

      final files = [
        PromptBlockExchangeFile(path: pathA, content: contentV2),
        PromptBlockExchangeFile(path: pathB, content: contentV1),
        PromptBlockExchangeFile(path: pathC, content: contentV2),
        PromptBlockExchangeFile(path: '/src/d.txt', content: contentV2),
      ];
      final plan = PromptBlockExchange.buildPlan(
        files: files,
        library: library,
        folderChainOf: (file) => ['根'],
      );

      expect(plan.createCount, 1);
      expect(plan.skipCount, 1);
      expect(plan.updateCount, 2);

      final byPath = {for (final item in plan.items) item.file.path: item};
      // Windows 来源路径大小写不敏感匹配（/src/B.TXT 命中 /src/b.txt）。
      expect(byPath[pathB]!.action, PromptBlockExchangeAction.skipUnchanged);
      expect(byPath[pathC]!.existingBlock?.id, 'c1');
      expect(byPath[pathC]!.localModified, isFalse);
      // d 块正文相对上次导入记录被手动改过 → localModified。
      expect(byPath['/src/d.txt']!.localModified, isTrue);
    });
  });

  group('library backup', () {
    test(
      'exports and re-imports with same-id skipping and dangling repair',
      () {
        final blocks = [
          PromptBlock.create(
            id: 'keep',
            title: '保留',
            content: '既有块',
            folderId: 'exists-folder',
          ),
          PromptBlock.create(
            id: 'new-block',
            title: '新块',
            content: '带来源',
            sourcePath: '/src/x.txt',
            sourceHash: 'h',
          ),
        ];
        final folders = [
          PromptBlockFolder.create(id: 'exists-folder', name: '已有夹'),
          PromptBlockFolder.create(id: 'new-folder', name: '新夹'),
          PromptBlockFolder.create(
            id: 'dangling',
            name: '悬空',
            parentId: 'nope',
          ),
        ];
        final json = PromptBlockExchange.exportLibraryJson(
          blocks: blocks,
          folders: folders,
        );
        expect(json['schemaVersion'], 1);
        expect((json['blocks'] as List).length, 2);

        final library = libraryOf(
          blocks: [
            PromptBlock.create(id: 'keep', title: '保留', content: '库里已有'),
          ],
          folders: [
            PromptBlockFolder.create(id: 'exists-folder', name: '库里已有夹'),
          ],
        );

        final plan = PromptBlockExchange.planLibraryImport(
          json: Map<String, dynamic>.from(json),
          library: library,
        );
        expect(plan.skippedBlocks, 1);
        expect(plan.skippedFolders, 1);
        expect(plan.blocks.map((b) => b.id), ['new-block']);
        expect(plan.blocks.first.sourcePath, '/src/x.txt');
        // 悬空 parentId / folderId 回根目录,不挂空。
        expect(
          plan.folders.firstWhere((f) => f.id == 'dangling').parentId,
          isNull,
        );
      },
    );

    test('rejects invalid backup payloads', () {
      final library = libraryOf();
      expect(
        () => PromptBlockExchange.planLibraryImport(
          json: {'folders': [], 'blocks': []},
          library: library,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => PromptBlockExchange.planLibraryImport(
          json: {
            'schemaVersion': 1,
            'folders': [
              {'oops': true},
            ],
            'blocks': [],
          },
          library: library,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

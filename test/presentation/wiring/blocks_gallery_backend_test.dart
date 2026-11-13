import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/utils/prompt_block_exchange.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/wiring/blocks_library_backend.dart';
import 'package:nai_launcher/presentation/wiring/blocks_mapping.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late PromptBlockStorage storage;
  late ProviderContainer container;
  late BlocksLibraryBackend backend;
  late PathProviderPlatform previousPaths;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('blocks_gallery_backend_');
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.path);
    Hive.init('${root.path}/hive');
    storage = PromptBlockStorage();
    await storage.init();
    container = ProviderContainer(
      overrides: [promptBlockStorageProvider.overrideWithValue(storage)],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    backend = container.read(blocksLibraryBackendProvider);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    PathProviderPlatform.instance = previousPaths;
    await root.delete(recursive: true);
  });

  Future<PromptBlock> saveGallery() async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 48)),
    );
    final platform = container.read(blocksPlatformProvider);
    final images = [
      for (var i = 0; i < 3; i++) platform.prepareThumbnail(bytes),
    ];
    return backend.save(
      BlockDraft(
        title: 'Gallery',
        atoms: const ['a'],
        thumb: BlockThumb(
          images[0].image,
          pickToken: images[0].token,
          offsetY: -.5,
          scale: 1.5,
        ),
        additionalThumbs: [
          BlockThumb(
            images[1].image,
            pickToken: images[1].token,
            offsetX: .4,
            scale: 2,
          ),
          BlockThumb(images[2].image, pickToken: images[2].token, offsetY: .7),
        ],
      ),
    );
  }

  test(
    'all managed previews survive storage and library JSON export',
    () async {
      final block = await saveGallery();
      final loaded = (await storage.getBlock(block.id))!;
      expect(loaded.thumbnails, hasLength(3));
      expect(loaded.additionalThumbnails[0].offsetX, .4);
      expect(loaded.additionalThumbnails[0].scale, 2);
      for (final image in loaded.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
      final backup = PromptBlockExchange.exportLibraryJson(
        blocks: [loaded],
        folders: [],
      );
      final imported = PromptBlockExchange.planLibraryImport(
        json: backup,
        library: PromptBlockLibraryData(blocks: [], folders: []),
      );
      expect(imported.blocks.single.thumbnails, loaded.thumbnails);
      final mapped = blockDataOf(loaded, backend.library);
      expect(
        BlockDraft.of(mapped).thumbs.map((image) => image.path),
        loaded.thumbnails.map((image) => image.path),
      );
    },
  );

  test(
    'removing the first preview promotes its successor and only reclaims the removed file',
    () async {
      final before = await saveGallery();
      final remaining = before.thumbnails.skip(1).map(blockThumbOf).toList();
      final edited = await backend.save(
        BlockDraft(
          title: before.title,
          atoms: const ['a'],
          thumb: remaining.first,
          additionalThumbs: remaining.skip(1).toList(),
        ),
        id: before.id,
        expected: before,
      );
      expect(edited.thumbnail, before.thumbnails[1].path);
      expect(edited.thumbnailOffsetX, .4);
      expect(edited.thumbnailScale, 2);
      expect(await File(before.thumbnail!).exists(), isFalse);
      for (final image in edited.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
      final metadataOnly = await backend.save(
        const BlockDraft(title: 'Renamed', atoms: ['a']),
        id: edited.id,
      );
      expect(metadataOnly.thumbnails, edited.thumbnails);
      final cleared = await backend.save(
        const BlockDraft(title: 'Cleared', atoms: ['a'], clearThumb: true),
        id: edited.id,
      );
      expect(cleared.thumbnails, isEmpty);
      for (final image in edited.thumbnails) {
        expect(await File(image.path).exists(), isFalse);
      }
    },
  );

  test(
    'duplicates own every image and deletion undo restores the whole gallery',
    () async {
      final before = await saveGallery();
      final duplicate = await backend.duplicate(before.id);
      expect(duplicate.thumbnails, hasLength(3));
      expect(
        duplicate.thumbnails
            .map((image) => image.path)
            .toSet()
            .intersection(before.thumbnails.map((image) => image.path).toSet()),
        isEmpty,
      );
      final deletion = await backend.delete([before.id]);
      for (final image in before.thumbnails) {
        expect(await File(image.path).exists(), isFalse);
      }
      for (final image in duplicate.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
      await backend.undo(deletion);
      final restored = backend.requireBlock(before.id);
      expect(
        restored.thumbnails.map((image) => image.copyWith(path: '')),
        before.thumbnails.map((image) => image.copyWith(path: '')),
      );
      for (final image in restored.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
      await backend.notifier.deleteBlock(duplicate.id);
      for (final image in duplicate.thumbnails) {
        expect(await File(image.path).exists(), isFalse);
      }
      for (final image in restored.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
    },
  );

  test(
    'a shared extra image is retained when another referencing block is deleted',
    () async {
      final first = await saveGallery();
      final shared = await backend.notifier.createBlock(
        title: 'Shared',
        content: 'b',
        thumbnail: first.thumbnail,
        additionalThumbnails: first.additionalThumbnails,
      );
      await backend.notifier.deleteBlocks([first.id]);
      for (final image in shared.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
      await backend.notifier.deleteBlock(shared.id);
      for (final image in shared.thumbnails) {
        expect(await File(image.path).exists(), isFalse);
      }
    },
  );

  test(
    'copying to another folder copies every image with its framing',
    () async {
      final first = await saveGallery();
      final folder = await backend.notifier.createFolder(name: 'Destination');
      await backend.notifier.transferBlocks(
        [first.id],
        PromptBlockTransferTarget(PromptBlockTransferKind.folder, folder.id),
        PromptBlockTransferMode.copy,
      );
      final copied = backend.library.blocks.singleWhere(
        (block) => block.folderId == folder.id,
      );
      expect(copied.thumbnails, hasLength(3));
      expect(
        copied.thumbnails.map((image) => image.copyWith(path: '')),
        first.thumbnails.map((image) => image.copyWith(path: '')),
      );
      expect(
        copied.thumbnails
            .map((image) => image.path)
            .toSet()
            .intersection(first.thumbnails.map((image) => image.path).toSet()),
        isEmpty,
      );
      for (final image in copied.thumbnails) {
        expect(await File(image.path).exists(), isTrue);
      }
    },
  );

  test('a failed multi-image duplicate reclaims its partial copies', () async {
    final block = await saveGallery();
    await File(block.thumbnails[1].path).delete();
    final directory = File(block.thumbnail!).parent;
    final before = (await directory.list().toList())
        .map((entry) => entry.path)
        .toSet();
    await expectLater(
      backend.duplicate(block.id),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      (await directory.list().toList()).map((entry) => entry.path).toSet(),
      before,
    );
    expect(backend.library.blocks, hasLength(1));
  });
}

import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_files.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery/gallery_delete_pool_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_gallery_binding.dart';
import '../../../helpers/fake_local_gallery_service.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/repositories/gallery_category_repository.dart';
import 'package:nai_launcher/data/repositories/gallery_folder_repository.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/data/services/gallery/gallery_stream_scanner.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import '../krita/agent_bridge_draft_test.dart' show MemoryDraftSettings;

class _History extends ImageGenerationNotifier {
  _History(this.path);
  final String path;
  @override
  ImageGenerationState build() {
    GeneratedImage image(String id) => GeneratedImage(
      id: id,
      filePath: path,
      width: 7,
      height: 5,
      bytes: Uint8List.fromList(img.encodePng(img.Image(width: 7, height: 5))),
      originalBytes: Uint8List.fromList(
        img.encodePng(img.Image(width: 3, height: 2)),
      ),
    );
    final current = image('current'), other = image('other');
    return ImageGenerationState(
      currentImages: [current],
      history: [current, other],
      displayImages: [current],
    );
  }
}

class _AfterExport extends AgentWorkspaceFiles {
  _AfterExport(super.root, this.after);
  final Future<void> Function() after;
  @override
  Future<String> export(
    String name,
    Uint8List bytes,
    void Function() check, {
    Map<String, Uint8List> companions = const {},
  }) async {
    final result = await super.export(
      name,
      bytes,
      check,
      companions: companions,
    );
    await after();
    return result;
  }
}

class _BatchDeleteRepository extends GalleryCategoryRepository {
  _BatchDeleteRepository({this.afterDelete}) : super.forTesting();
  final Future<void> Function(String id)? afterDelete;
  int saves = 0;
  @override
  Future<bool> saveCategories(List<GalleryCategory> categories) async {
    saves++;
    return super.saveCategories(categories);
  }

  @override
  Future<bool> deleteCategory(
    GalleryCategory category,
    List<GalleryCategory> allCategories, {
    bool deleteFolder = true,
    bool recursive = false,
  }) async {
    final result = await super.deleteCategory(
      category,
      allCategories,
      deleteFolder: deleteFolder,
      recursive: recursive,
    );
    if (result) await afterDelete?.call(category.id);
    return result;
  }
}

class _RejectPreferences extends InMemorySharedPreferencesStore {
  _RejectPreferences(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async => false;
}

class _AfterRenameRepository extends GalleryCategoryRepository {
  _AfterRenameRepository(this.after) : super.forTesting();
  final Future<void> Function() after;
  @override
  Future<GalleryCategory?> renameCategory(
    GalleryCategory category,
    String newName,
    List<GalleryCategory> allCategories, {
    Future<void> Function()? beforeRelocate,
  }) async {
    final result = await super.renameCategory(
      category,
      newName,
      allCategories,
      beforeRelocate: beforeRelocate,
    );
    if (result != null) await after();
    return result;
  }
}

void main() {
  late Directory temp, root, workspace;
  late GalleryDataSource source;
  late LocalGalleryServiceImpl service;
  late ProviderContainer container;
  late NaiAgentGalleryBinding binding;
  late File image;
  late int id;
  late bool alive, busy;
  const pool = GalleryDeletePoolStore();
  Matcher error(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> params, {
    NaiAgentCancellation? token,
  }) async => Map<String, dynamic>.from(
    (await binding.manage(params, token ?? NaiAgentCancellation()))['details']
        as Map,
  );
  Future<Map<String, dynamic>> read({
    String scope = 'library',
    String? imageId,
  }) => run({
    'action': 'read',
    'scope': scope,
    'image_id': imageId ?? 'gallery:$id',
  });
  Future<Map<String, dynamic>> change(
    String action, {
    Map<String, dynamic>? changes,
    String scope = 'library',
    String? imageId,
  }) async => run({
    'action': action,
    'scope': scope,
    'image_id': imageId ?? 'gallery:$id',
    'expected_image_version': (await read(
      scope: scope,
      imageId: imageId,
    ))['image_version'],
    if (changes != null) 'changes': changes,
  });
  Future<int> backups() async =>
      await Directory('${workspace.path}/.W.O.F/outputs').exists()
      ? await Directory('${workspace.path}/.W.O.F/outputs').list().length
      : 0;
  Future<Map<String, dynamic>> collections() =>
      run({'action': 'collections', 'limit': 100});
  Future<Map<String, dynamic>> organize(
    String action,
    Map<String, dynamic> params,
  ) async => run({
    'action': action,
    'expected_collection_version': (await collections())['collection_version'],
    ...params,
  });
  NaiAgentGalleryBinding hooked(Future<void> Function() after) =>
      container.read(
        Provider(
          (ref) => NaiAgentGalleryBinding(
            ref,
            () => alive,
            workspace: workspace,
            owner: const NaiAgentConversationOwner(
              'test-workspace',
              'test-chat',
            ),
            isBusy: () => busy,
            workspaceFiles: _AfterExport(workspace, after),
          ),
        ),
      );
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppLogger.initialize(isTestEnvironment: true);
  });
  setUp(() async {
    alive = true;
    busy = false;
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp(
      'nai-agent-gallery-management-',
    );
    root = await Directory(p.join(temp.path, 'gallery')).create();
    workspace = await Directory(p.join(temp.path, 'workspace')).create();
    Hive.init('${temp.path}/hive');
    final settings = await Hive.openBox(StorageKeys.settingsBox);
    await settings.put(StorageKeys.imageSavePath, root.path);
    await ConnectionPoolHolder.initialize(
      dbPath: '${temp.path}/gallery.db',
      maxConnections: 2,
    );
    source = GalleryDataSource();
    await source.initialize();
    image = File(p.join(root.path, 'original.png'));
    await image.writeAsBytes(img.encodePng(img.Image(width: 16, height: 12)));
    final date = DateTime(2026, 8, 1);
    id = await source.upsertImage(
      filePath: image.path,
      fileName: 'original.png',
      fileSize: await image.length(),
      width: 16,
      height: 12,
      createdAt: date,
      modifiedAt: date,
    );
    await source.setImageTags(id, ['original']);
    service = LocalGalleryServiceImpl(
      dataSource: source,
      filterService: GalleryFilterService(source),
    );
    await service.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWith(
          () => FakeGalleryServiceNotifier(service),
        ),
        naiAgentGalleryDataSourceProvider.overrideWithValue(source),
        imageGenerationNotifierProvider.overrideWith(
          () => _History(image.path),
        ),
        localStorageServiceProvider.overrideWithValue(
          MemoryDraftSettings()
            ..values[StorageKeys.protectionConfirmDangerousActions] = false,
        ),
      ],
    );
    binding = container.read(
      Provider(
        (ref) => NaiAgentGalleryBinding(
          ref,
          () => alive,
          workspace: workspace,
          owner: const NaiAgentConversationOwner('test-workspace', 'test-chat'),
          isBusy: () => busy,
        ),
      ),
    );
  });
  tearDown(() async {
    alive = false;
    container.dispose();
    await service.dispose();
    await source.dispose();
    await ConnectionPoolHolder.dispose();
    await Hive.close();
    await temp.delete(recursive: true);
  });

  Future<Map<String, dynamic>> folders() =>
      run({'action': 'folders', 'limit': 100});
  Future<Map<String, dynamic>> folderAction(
    String action,
    Map<String, dynamic> fields,
  ) async => run({
    'action': action,
    'expected_folder_version': (await folders())['folder_version'],
    ...fields,
  });
  Future<Map<String, dynamic>> createFolder(String name, {String? parent}) =>
      folderAction('folder_create', {
        'changes': {'name': name},
        if (parent != null) 'parent_id': parent,
      });
  Future<Map<String, dynamic>> transfer(
    String action,
    String destination, {
    NaiAgentCancellation? token,
  }) async => run({
    'action': action,
    'image_id': 'gallery:$id',
    'expected_image_version': (await read())['image_version'],
    'target_folder': destination,
  }, token: token);
  Future<AgentQuestionRequest> question({String? excluding}) async {
    for (var i = 0; i < 100; i++) {
      final rows = container
          .read(naiAgentQuestionsProvider)
          .forChat('test-chat');
      final fresh = rows.where((row) => row.id != excluding).toList();
      if (fresh.isNotEmpty) return fresh.single;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw StateError('No actual UI question');
  }

  Future<int> indexFile(File file) => source.upsertImage(
    filePath: file.path,
    fileName: p.basename(file.path),
    fileSize: file.lengthSync(),
    width: 16,
    height: 12,
    createdAt: DateTime(2026),
    modifiedAt: DateTime(2026),
  );

  Future<List<String>> batchImages(int count, {Directory? external}) async {
    final ids = ['gallery:$id'];
    for (var i = 1; i < count; i++) {
      final file = await image.copy(
        p.join((external ?? root).path, 'batch-$i.png'),
      );
      ids.add('gallery:${await indexFile(file)}');
    }
    return ids;
  }

  Future<Map<String, dynamic>> batchParams(
    String action,
    List<String> ids,
    String target,
  ) async => {
    'action': action,
    'image_ids': ids,
    'expected_image_versions': {
      for (final id in ids) id: (await read(imageId: id))['image_version'],
    },
    'target_folder': target,
  };

  Future<void> protect() => container
      .read(shareImageSettingsProvider.notifier)
      .setConfirmDangerousActions(true);
  void answer(AgentQuestionRequest request, {bool confirm = true}) =>
      container.read(naiAgentQuestionsProvider).answer(request.id, {
        'gallery_change': confirm
            ? currentL10n.common_confirm
            : currentL10n.common_cancel,
      });
  void noQuestions() => expect(
    container.read(naiAgentQuestionsProvider).forChat('test-chat'),
    isEmpty,
  );

  test(
    'batch internal move confirms once, decline is inert, and preserves native data',
    () async {
      final ids = await batchImages(3);
      final target = await Directory(
        p.join(root.path, 'batch-target'),
      ).create();
      final collection = await source.createCollection('Batch members');
      for (final imageId in ids) {
        final native = int.parse(imageId.split(':').last);
        await source.setImageTags(native, ['kept']);
        await source.addFavorite(native);
        await source.addImageToCollection(collection, native);
      }
      await protect();
      final params = await batchParams('move_file', ids, target.path);
      final declined = run(params);
      final declineError = expectLater(declined, error('declined'));
      final first = await question();
      expect(
        first.questions.single.text,
        contains(currentL10n.localGallery_protectedBulkMoveContent(3)),
      );
      expect(
        container.read(naiAgentQuestionsProvider).forChat('test-chat'),
        hasLength(1),
      );
      expect(await backups(), 0);
      answer(first, confirm: false);
      await declineError;
      expect(await target.list().length, 0);
      for (final imageId in ids) {
        expect((await read(imageId: imageId))['file_missing'], false);
      }
      final request = run(params);
      answer(await question());
      final result = await request.timeout(const Duration(seconds: 10));
      noQuestions();
      expect(result['ok'], true);
      expect(result['action'], 'move_file');
      expect(result['scope'], 'library');
      expect(result['target_folder'], await target.resolveSymbolicLinks());
      expect(result['count'], 3);
      expect(result['image_ids'], ids);
      expect(result['source_image_ids'], ids);
      expect(result['unchanged_ids'], isEmpty);
      expect(result['indexing_ids'], isEmpty);
      expect(result['image_versions'], hasLength(3));
      expect(result['applied_fields'], ['file_moved', 'index_updated']);
      expect(result['backups'], hasLength(3));
      expect(await backups(), 3);
      for (final imageId in ids) {
        final native = int.parse(imageId.split(':').last);
        expect(await source.getImageTags(native), ['kept']);
        expect(await source.isFavorite(native), true);
        expect(
          await source.getCollectionIdsForImage(native),
          contains(collection),
        );
        expect(
          await File(
            (result['source_paths'] as Map)[imageId] as String,
          ).exists(),
          false,
        );
        final actual = (result['file_paths'] as Map)[imageId] as String;
        expect(p.dirname(actual), await target.resolveSymbolicLinks());
        expect(
          (await read(imageId: imageId))['image_version'],
          (result['image_versions'] as Map)[imageId],
        );
        final backup = (result['backups'] as List).cast<Map>().singleWhere(
          (b) => b['image_id'] == imageId,
        );
        expect(
          await File(
            p.join(workspace.path, backup['path'] as String),
          ).readAsBytes(),
          await File(actual).readAsBytes(),
        );
      }
    },
  );

  test(
    'batch external source warning uses real count and one question with protection off',
    () async {
      final external = await Directory(
        p.join(temp.path, 'ExternalBatch'),
      ).create();
      await Hive.box(
        StorageKeys.settingsBox,
      ).put(StorageKeys.galleryExtraRoots, [external.path]);
      final ids = await batchImages(2);
      final externalFile = await image.copy(
        p.join(external.path, 'external.png'),
      );
      ids.add('gallery:${await indexFile(externalFile)}');
      final target = await Directory(
        p.join(root.path, 'ExternalTarget'),
      ).create();
      final request = run(await batchParams('move_file', ids, target.path));
      final pending = await question();
      expect(
        pending.questions.single.text,
        startsWith(
          currentL10n.localGallery_externalSourceMoveConfirmContent(3),
        ),
      );
      answer(pending);
      expect((await request.timeout(const Duration(seconds: 10)))['count'], 3);
      noQuestions();
    },
  );

  test(
    'batch transfer preflight version conflict on second ID never asks or changes files',
    () async {
      final ids = await batchImages(3);
      final target = await Directory(p.join(root.path, 'Conflict')).create();
      final params = await batchParams('move_file', ids, target.path);
      (params['expected_image_versions'] as Map)[ids[1]] = 'old';
      await protect();
      await expectLater(run(params), error('image_conflict'));
      noQuestions();
      expect(await target.list().length, 0);
      expect(await backups(), 0);
      for (final id in ids) {
        expect((await read(imageId: id))['file_missing'], false);
      }
    },
  );

  test(
    'batch second source edited during confirmation stops after first, reporting partial',
    () async {
      final ids = await batchImages(3);
      final second = File(
        (await read(imageId: ids[1]))['resolved_path'] as String,
      );
      final target = await Directory(
        p.join(root.path, 'PartialBatch'),
      ).create();
      final params = await batchParams('move_file', ids, target.path);
      await protect();
      final request = run(params);
      final pending = await question();
      await second.writeAsString('edited during confirmation');
      answer(pending);
      final result = await request;
      expect(result['ok'], false);
      expect(result['error'], 'image_conflict');
      expect(result['failed_image_id'], ids[1]);
      expect(result['remaining_image_ids'], [ids[2]]);
      final completed = result['completed'] as Map;
      expect(completed['count'], 1);
      expect(completed['image_ids'], [ids[0]]);
      expect(completed['backups'], hasLength(1));
      expect(result['backups'], hasLength(2));
      expect(await target.list().length, 1);
      expect(await second.readAsString(), 'edited during confirmation');
      expect((await read(imageId: ids[2]))['file_missing'], false);
      noQuestions();
    },
  );

  test(
    'batch native index failure reports physical application and stops later files',
    () async {
      final ids = await batchImages(3);
      final target = await Directory(p.join(root.path, 'IndexBatch')).create();
      await source.execute(
        'inject batch failure',
        (db) => db.execute('''
      CREATE TRIGGER reject_batch_update BEFORE UPDATE OF file_path ON gallery_images
      WHEN OLD.id = ${ids[1].split(':').last}
      BEGIN SELECT RAISE(ABORT, 'batch injected failure'); END
    '''),
      );
      final result = await run(
        await batchParams('move_file', ids, target.path),
      );
      expect(result['ok'], false);
      expect(result['failed_image_id'], ids[1]);
      expect(result['remaining_image_ids'], [ids[2]]);
      expect((result['completed'] as Map)['count'], 2);
      expect((result['completed'] as Map)['file_paths'], hasLength(2));
      expect((result['completed'] as Map)['image_versions'], hasLength(1));
      expect(await target.list().length, 2);
      expect((await read(imageId: ids[2]))['file_missing'], false);
    },
  );

  test(
    'batch skips unchanged items; all unchanged never asks or backs up',
    () async {
      final ids = await batchImages(3);
      await protect();
      final unchanged = await run(
        await batchParams('move_file', ids, root.path),
      );
      expect(unchanged['ok'], true);
      expect(unchanged['unchanged'], true);
      expect(unchanged['count'], 0);
      expect(unchanged['image_ids'], isEmpty);
      expect(unchanged['unchanged_ids'], ids);
      expect(await backups(), 0);
      noQuestions();
      await container
          .read(shareImageSettingsProvider.notifier)
          .setConfirmDangerousActions(false);
      final target = await Directory(p.join(root.path, 'Skip')).create();
      final first = await run(
        await batchParams('move_file', [ids.first], target.path),
      );
      await protect();
      final request = run(await batchParams('move_file', ids, target.path));
      final pending = await question();
      expect(
        pending.questions.single.text,
        contains(currentL10n.localGallery_protectedBulkMoveContent(2)),
      );
      answer(pending);
      final result = await request;
      expect(result['count'], 2);
      expect(result['unchanged_ids'], [ids.first]);
      expect(result['image_ids'], ids.skip(1).toList());
      expect(
        (await read(imageId: ids.first))['image_version'],
        (first['image_versions'] as Map)[ids.first],
      );
      noQuestions();
    },
  );

  test('batch copy confirms once and retains all sources', () async {
    final ids = await batchImages(2);
    final target = await Directory(p.join(root.path, 'BatchCopies')).create();
    await protect();
    final request = run(await batchParams('copy_file', ids, target.path));
    final pending = await question();
    expect(
      pending.questions.single.text,
      startsWith(currentL10n.localGallery_confirmCopyContent),
    );
    answer(pending);
    final result = await request.timeout(const Duration(seconds: 10));
    expect(result['ok'], true);
    expect(result['count'], 2);
    expect(result['source_image_ids'], ids);
    expect(result['image_versions'], isNull);
    expect(
      (result['image_ids'] as List).length +
          (result['indexing_ids'] as List).length,
      2,
    );
    expect(result['backups'], hasLength(2));
    expect(await target.list().length, 2);
    for (final id in ids) {
      expect((await read(imageId: id))['file_missing'], false);
      expect(
        await File((result['file_paths'] as Map)[id] as String).exists(),
        true,
      );
    }
    noQuestions();
  });

  test(
    'batch confirmation truncates filenames to five and uses remainder line',
    () async {
      final ids = await batchImages(7);
      final target = await Directory(p.join(root.path, 'Many')).create();
      await protect();
      final request = run(await batchParams('move_file', ids, target.path));
      final rejected = expectLater(request, error('declined'));
      final pending = await question();
      final text = pending.questions.single.text;
      expect(' → '.allMatches(text), hasLength(5));
      expect(text, contains(currentL10n.naiAgent_galleryMoreItems(2)));
      expect(text, endsWith(await target.resolveSymbolicLinks()));
      answer(pending, confirm: false);
      await rejected;
      noQuestions();
    },
  );

  test(
    'batch move undo groups original folders and rejects any stale or occupied original before changes',
    () async {
      final original = await Directory(
        p.join(root.path, 'other-original'),
      ).create();
      final ids = await batchImages(3, external: original);
      final target = await Directory(p.join(root.path, 'UndoBatch')).create();
      var moved = await run(await batchParams('move_file', ids, target.path));
      await protect();
      final undo = binding.undoManage({'action': 'move_file'}, moved);
      final first = await question();
      answer(first);
      final second = await question(excluding: first.id);
      expect(second.id, isNot(first.id));
      answer(second);
      expect(await undo.timeout(const Duration(seconds: 10)), true);
      expect(await image.exists(), true);
      expect(await original.list().length, 2);
      noQuestions();
      await container
          .read(shareImageSettingsProvider.notifier)
          .setConfirmDangerousActions(false);
      moved = await run(await batchParams('move_file', ids, target.path));
      await source.setImageTags(int.parse(ids.last.split(':').last), ['newer']);
      expect(await binding.undoManage({'action': 'move_file'}, moved), false);
      expect(await target.list().length, 3);
      expect(await image.exists(), false);
      // Fresh versions, but one occupied original path still blocks every group.
      final versions = moved['image_versions'] as Map;
      versions[ids.last] = (await read(imageId: ids.last))['image_version'];
      await image.writeAsString('new unrelated file');
      expect(await binding.undoManage({'action': 'move_file'}, moved), false);
      expect(await target.list().length, 3);
      expect(await image.readAsString(), 'new unrelated file');
      noQuestions();
    },
  );

  test('batch transfer strict argument validation and 50 item limit', () async {
    final ids = await batchImages(2);
    final params = await batchParams('move_file', ids, root.path);
    for (final invalid in [
      {...params, 'image_id': ids.first},
      {...params, 'expected_image_version': 'smuggled'},
      {
        ...params,
        'expected_image_versions': {ids.first: 'v'},
      },
      {
        ...params,
        'expected_image_versions': {ids.first: 1, ids.last: 'v'},
      },
      {
        ...params,
        'image_ids': [ids.first, ids.first],
      },
      {...params, 'image_ids': <String>[]},
      {...params, 'image_ids': List.generate(51, (i) => 'gallery:${i + 1}')},
      {...params, 'authorized': true},
    ]) {
      await expectLater(run(invalid), error('invalid_gallery'));
    }
    noQuestions();
    expect(await backups(), 0);
    // 50 is accepted structurally and reaches real preflight, not a 20-item cap.
    await expectLater(
      run({
        ...params,
        'image_ids': List.generate(50, (i) => 'gallery:${i + 1}'),
        'expected_image_versions': {
          for (var i = 1; i <= 50; i++) 'gallery:$i': 'stale',
        },
      }),
      error('image_conflict'),
    );
  });

  test(
    'batch empty parent and selected child delete deepest-first with one confirmation, backup and catalog save',
    () async {
      final parent = await createFolder('ParentBatch');
      final child = await createFolder(
        'ChildBatch',
        parent: parent['folder_id'] as String,
      );
      final repo = _BatchDeleteRepository();
      binding = container.read(
        Provider(
          (ref) => NaiAgentGalleryBinding(
            ref,
            () => alive,
            workspace: workspace,
            owner: const NaiAgentConversationOwner(
              'test-workspace',
              'test-chat',
            ),
            categoryRepository: repo,
          ),
        ),
      );
      await protect();
      final request = folderAction('folder_delete_empty', {
        'folder_ids': [parent['folder_id'], child['folder_id']],
      });
      final pending = await question();
      expect(
        pending.questions.single.text,
        currentL10n.naiAgent_galleryDeleteEmptyFoldersConfirm(
          2,
          '${await Directory(parent['file_path'] as String).resolveSymbolicLinks()}\n${await Directory(child['file_path'] as String).resolveSymbolicLinks()}',
        ),
      );
      answer(pending);
      final result = await request.timeout(const Duration(seconds: 10));
      expect(result['ok'], true);
      expect(result['deleted'], true);
      expect(result['count'], 2);
      expect(result['folder_ids'], [child['folder_id'], parent['folder_id']]);
      expect(repo.saves, 1);
      expect(await Directory(parent['file_path'] as String).exists(), false);
      final record =
          jsonDecode(
                await File(
                  p.join(workspace.path, result['backup'] as String),
                ).readAsString(),
              )
              as Map;
      expect(record['folders'], hasLength(2));
      expect(
        (record['categories'] as List).map((c) => c['id']),
        containsAll([parent['folder_id'], child['folder_id']]),
      );
      expect(record['delete_pool'], isEmpty);
      expect(
        ((await folders())['folders'] as List).map((f) => f['folder_id']),
        isNot(contains(anyOf(parent['folder_id'], child['folder_id']))),
      );
      noQuestions();
    },
  );

  test(
    'batch folder preflight rejects unselected child, visible/hidden files and unmanaged dirs without asking',
    () async {
      final parent = await createFolder('NonemptyParent');
      final child = await createFolder(
        'Child',
        parent: parent['folder_id'] as String,
      );
      await protect();
      await expectLater(
        folderAction('folder_delete_empty', {
          'folder_ids': [parent['folder_id']],
        }),
        error('folder_not_empty'),
      );
      final path = parent['file_path'] as String;
      for (final name in ['file.txt', '.hidden']) {
        final file = await File(p.join(path, name)).writeAsString('keep');
        await expectLater(
          folderAction('folder_delete_empty', {
            'folder_ids': [parent['folder_id'], child['folder_id']],
          }),
          error('folder_not_empty'),
        );
        await file.delete();
      }
      final unselected = await Directory(p.join(path, 'unmanaged')).create();
      await expectLater(
        folderAction('folder_delete_empty', {
          'folder_ids': [parent['folder_id'], child['folder_id']],
        }),
        error('folder_not_empty'),
      );
      expect(await unselected.exists(), true);
      expect(await Directory(child['file_path'] as String).exists(), true);
      expect(await backups(), 2); // only the two folder creations
      noQuestions();
    },
  );

  test(
    'batch folder deletion persists completed catalog after listing conflict',
    () async {
      final parent = await createFolder('PartialParent');
      final child = await createFolder(
        'Child',
        parent: parent['folder_id'] as String,
      );
      final repo = _BatchDeleteRepository(
        afterDelete: (_) async {
          await File(
            p.join(parent['file_path'] as String, 'arrived.txt'),
          ).writeAsString('concurrent');
        },
      );
      binding = container.read(
        Provider(
          (ref) => NaiAgentGalleryBinding(
            ref,
            () => alive,
            workspace: workspace,
            categoryRepository: repo,
          ),
        ),
      );
      final result = await folderAction('folder_delete_empty', {
        'folder_ids': [parent['folder_id'], child['folder_id']],
      });
      expect(result['ok'], false);
      expect(result['error'], 'folder_conflict');
      expect(result['deleted_folder_ids'], [child['folder_id']]);
      expect(result['failed_folder_id'], parent['folder_id']);
      expect(result['remaining_folder_ids'], [parent['folder_id']]);
      expect(repo.saves, 1);
      expect(result['applied_fields'], contains('catalog_saved'));
      expect(
        ((await folders())['folders'] as List).map((f) => f['folder_id']),
        contains(parent['folder_id']),
      );
      expect(
        ((await folders())['folders'] as List).map((f) => f['folder_id']),
        isNot(contains(child['folder_id'])),
      );
      expect(await Directory(child['file_path'] as String).exists(), false);
      expect(
        await File(
          p.join(parent['file_path'] as String, 'arrived.txt'),
        ).exists(),
        true,
      );
    },
  );

  test(
    'batch folder deletion retains concurrent catalog edits while removing completed IDs',
    () async {
      final parent = await createFolder('ConcurrentParent');
      final child = await createFolder(
        'Child',
        parent: parent['folder_id'] as String,
      );
      final unrelated = await createFolder('Unrelated');
      final repo = _BatchDeleteRepository(
        afterDelete: (_) async {
          final categories = await GalleryCategoryRepository.instance
              .loadCategories();
          await GalleryCategoryRepository.instance.saveCategories(
            categories
                .map(
                  (c) => c.id == unrelated['folder_id']
                      ? c.copyWith(name: 'newer edit')
                      : c,
                )
                .toList(),
          );
        },
      );
      binding = container.read(
        Provider(
          (ref) => NaiAgentGalleryBinding(
            ref,
            () => alive,
            workspace: workspace,
            categoryRepository: repo,
          ),
        ),
      );
      final result = await folderAction('folder_delete_empty', {
        'folder_ids': [parent['folder_id'], child['folder_id']],
      });
      expect(result['ok'], false);
      expect(result['error'], 'folder_conflict');
      expect(result['deleted_folder_ids'], [child['folder_id']]);
      expect(repo.saves, 1);
      final categories = await repo.loadCategories();
      expect(categories.findById(child['folder_id'] as String), isNull);
      expect(
        categories.findById(unrelated['folder_id'] as String)!.name,
        'newer edit',
      );
      expect(await Directory(parent['file_path'] as String).exists(), true);
    },
  );

  test(
    'batch folder backup freshness and argument validation reject before deletion',
    () async {
      final folder = await createFolder('FreshBatch');
      final params = {
        'action': 'folder_delete_empty',
        'folder_ids': [folder['folder_id']],
        'expected_folder_version': (await folders())['folder_version'],
      };
      for (final invalid in [
        {...params, 'folder_id': folder['folder_id']},
        {
          ...params,
          'folder_ids': [folder['folder_id'], folder['folder_id']],
        },
        {...params, 'folder_ids': <String>[]},
        {...params, 'folder_ids': List.generate(51, (i) => '$i')},
        {...params, 'recursive': true},
      ]) {
        await expectLater(run(invalid), error('invalid_gallery'));
      }
      binding = hooked(
        () => File(
          p.join(folder['file_path'] as String, 'after-backup'),
        ).writeAsString('keep'),
      );
      await expectLater(run(params), error('folder_conflict'));
      expect(await Directory(folder['file_path'] as String).exists(), true);
      noQuestions();
    },
  );

  test(
    'batch folder confirmation truncates paths and decline leaves every folder',
    () async {
      final entries = <Map<String, dynamic>>[];
      for (var i = 0; i < 7; i++) {
        entries.add(await createFolder('ManyFolders-$i'));
      }
      await protect();
      final request = folderAction('folder_delete_empty', {
        'folder_ids': entries.map((entry) => entry['folder_id']).toList(),
      });
      final rejected = expectLater(request, error('declined'));
      final pending = await question();
      final paths = [
        for (final entry in entries)
          await Directory(entry['file_path'] as String).resolveSymbolicLinks(),
      ];
      expect(
        pending.questions.single.text,
        currentL10n.naiAgent_galleryDeleteEmptyFoldersConfirm(
          7,
          '${paths.take(5).join('\n')}\n${currentL10n.naiAgent_galleryMoreItems(2)}',
        ),
      );
      answer(pending, confirm: false);
      await rejected;
      for (final path in paths) {
        expect(await Directory(path).exists(), true);
      }
      expect(await backups(), 7); // folder creations only
      noQuestions();
    },
  );

  test(
    'batch folders reject root and external category trees in preflight',
    () async {
      final external = await Directory(
        p.join(temp.path, 'ExternalFolders'),
      ).create();
      final externalChild = await Directory(
        p.join(external.path, 'Child'),
      ).create();
      await Hive.box(
        StorageKeys.settingsBox,
      ).put(StorageKeys.galleryExtraRoots, [external.path]);
      await folders();
      final categories = await GalleryCategoryRepository.instance
          .loadCategories();
      final now = DateTime(2026);
      await GalleryCategoryRepository.instance.saveCategories([
        ...categories,
        GalleryCategory(
          id: 'fake-root',
          name: 'root',
          folderPath: '.',
          createdAt: now,
          updatedAt: now,
        ),
        GalleryCategory(
          id: 'external',
          name: 'external',
          folderPath: external.path,
          createdAt: now,
          updatedAt: now,
        ),
        GalleryCategory(
          id: 'external-child',
          name: 'child',
          folderPath: externalChild.path,
          parentId: 'external',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      await protect();
      for (final folderId in [
        'fake-root',
        'external',
        'external-child',
        'unknown',
      ]) {
        await expectLater(
          folderAction('folder_delete_empty', {
            'folder_ids': [folderId],
          }),
          error('invalid_folder'),
        );
      }
      expect(await external.exists(), true);
      expect(await externalChild.exists(), true);
      expect(await root.exists(), true);
      noQuestions();
    },
  );

  test(
    'batch folder cleanup saves deleted IDs even after binding closes',
    () async {
      final parent = await createFolder('ClosedParent');
      final child = await createFolder(
        'Child',
        parent: parent['folder_id'] as String,
      );
      final repo = _BatchDeleteRepository(
        afterDelete: (_) async {
          alive = false;
        },
      );
      binding = container.read(
        Provider(
          (ref) => NaiAgentGalleryBinding(
            ref,
            () => alive,
            workspace: workspace,
            categoryRepository: repo,
          ),
        ),
      );
      final result = await folderAction('folder_delete_empty', {
        'folder_ids': [parent['folder_id'], child['folder_id']],
      });
      expect(result['ok'], false);
      expect(result['error'], 'closed');
      expect(result['deleted_folder_ids'], [child['folder_id']]);
      expect(result['failed_folder_id'], parent['folder_id']);
      expect(repo.saves, 1);
      final categories = await repo.loadCategories();
      expect(categories.findById(child['folder_id'] as String), isNull);
      expect(categories.findById(parent['folder_id'] as String), isNotNull);
      expect(await Directory(parent['file_path'] as String).exists(), true);
    },
  );

  test(
    'physical file move preserves native ID, custom tags, favorite and collection, with exact backup',
    () async {
      final directory = await createFolder('Move target');
      final collection = await source.createCollection('Kept membership');
      await source.addFavorite(id);
      await source.addImageToCollection(collection, id);
      final pixels = await image.readAsBytes();
      final result = await transfer(
        'move_file',
        directory['file_path'] as String,
      );
      expect(result['ok'], true);
      expect(result['image_id'], 'gallery:$id');
      expect(await image.exists(), false);
      final moved = File(result['file_path'] as String);
      expect(await moved.readAsBytes(), pixels);
      expect((await source.readImageForManagement(id))!.filePath, moved.path);
      expect(await source.getImageTags(id), ['original']);
      expect(await source.isFavorite(id), true);
      expect(await source.getCollectionIdsForImage(id), contains(collection));
      expect(
        await File(
          p.join(workspace.path, (result['backup'] as Map)['path'] as String),
        ).readAsBytes(),
        pixels,
      );
      expect(await pool.load(), isEmpty);
    },
  );

  test(
    'repeated native copies preserve source and do not overwrite colliding files',
    () async {
      final directory = await createFolder('Copies');
      final target = directory['file_path'] as String;
      final collision = File(p.join(target, p.basename(image.path)));
      await collision.writeAsString('Keep unrelated original');
      final copies = <String>{};
      for (var i = 0; i < 4; i++) {
        final result = await transfer('copy_file', target);
        expect(result['ok'], true);
        expect(result['source_retained'], true);
        expect(copies.add(result['file_path'] as String), true);
        expect(
          await File(result['file_path'] as String).readAsBytes(),
          await image.readAsBytes(),
        );
      }
      expect(await collision.readAsString(), 'Keep unrelated original');
      expect(await image.exists(), true);
      expect((await source.readImageForManagement(id))!.filePath, image.path);
    },
  );

  test(
    'native reservation is removed if source changed after backup or cancellation',
    () async {
      final target = await Directory(p.join(root.path, 'Target')).create();
      final version = (await read())['image_version'];
      binding = hooked(() => image.writeAsString('User edited original'));
      await expectLater(
        run({
          'action': 'copy_file',
          'image_id': 'gallery:$id',
          'expected_image_version': version,
          'target_folder': target.path,
        }),
        error('image_conflict'),
      );
      expect(await target.list().length, 0);
      expect(await image.readAsString(), 'User edited original');
      final token = NaiAgentCancellation();
      binding = hooked(() async {
        token.cancel();
      });
      await expectLater(
        transfer('copy_file', target.path, token: token),
        error('cancelled'),
      );
      expect(await target.list().length, 0);
    },
  );

  test(
    'native transfer cleans only its reserved placeholder on precommit failure',
    () async {
      final target = await Directory(p.join(root.path, 'Reserved')).create();
      final kept = File(p.join(target.path, 'original.png'));
      await kept.writeAsString('Kept');
      await expectLater(
        GalleryFolderRepository.instance.transferImageToFolder(
          image.path,
          target.path,
          beforeTransfer: () async {
            throw StateError('Changed');
          },
        ),
        throwsStateError,
      );
      expect(await kept.readAsString(), 'Kept');
      expect(await target.list().length, 1);
      expect(await image.exists(), true);
    },
  );

  test(
    'physical nested rename keeps IDs, tags, favorites, membership and pending deletion without prefix-sibling corruption',
    () async {
      final parent = await createFolder('A');
      final child = await createFolder(
        'Nested',
        parent: parent['folder_id'] as String,
      );
      final sibling = await createFolder('AB');
      final kept = File(p.join(child['file_path'] as String, 'kept.png'));
      await image.copy(kept.path);
      final keptId = await indexFile(kept);
      final gone = File(p.join(child['file_path'] as String, 'deleted.png'));
      await image.copy(gone.path);
      final deletedId = await indexFile(gone);
      final prefix = File(p.join(sibling['file_path'] as String, 'prefix.png'));
      await image.copy(prefix.path);
      final prefixId = await indexFile(prefix);
      await source.addFavorite(keptId);
      await source.setImageTags(keptId, ['kept custom']);
      final collection = await source.createCollection('Kept');
      await source.addImageToCollection(collection, keptId);
      await source.batchMarkAsDeleted([gone.path]);
      await pool.addAll([gone.path]);
      final result = await folderAction('folder_rename', {
        'folder_id': parent['folder_id'],
        'changes': {'name': 'Renamed'},
      });
      expect(result['ok'], true);
      final moved = p.join(
        await root.resolveSymbolicLinks(),
        'Renamed',
        'Nested',
        'kept.png',
      );
      final movedDeleted = p.join(
        await root.resolveSymbolicLinks(),
        'Renamed',
        'Nested',
        'deleted.png',
      );
      expect((await source.readImageForManagement(keptId))!.filePath, moved);
      expect(
        (await source.readImageForManagement(deletedId))!.filePath,
        movedDeleted,
      );
      expect((await source.readImageForManagement(deletedId))!.isDeleted, true);
      expect(await pool.load(), [movedDeleted]);
      expect(await source.isFavorite(keptId), true);
      expect(await source.getImageTags(keptId), ['kept custom']);
      expect(
        await source.getCollectionIdsForImage(keptId),
        contains(collection),
      );
      expect(
        (await source.readImageForManagement(prefixId))!.filePath,
        prefix.path,
      );
      final rows = (await folders())['folders'] as List;
      expect(
        rows.singleWhere(
          (f) => f['folder_id'] == child['folder_id'],
        )['file_path'],
        p.dirname(moved),
      );
      expect(
        rows.singleWhere(
          (f) => f['folder_id'] == sibling['folder_id'],
        )['file_path'],
        sibling['file_path'],
      );
      expect(await File(moved).exists(), true);
    },
  );

  test(
    'folder move reuses native hierarchy and IDs; cycles and occupied destinations are refused',
    () async {
      final parent = await createFolder('Parent');
      final child = await createFolder(
        'Child',
        parent: parent['folder_id'] as String,
      );
      await expectLater(
        folderAction('folder_move', {
          'folder_id': parent['folder_id'],
          'parent_id': child['folder_id'],
        }),
        error('invalid_folder'),
      );
      final result = await folderAction('folder_move', {
        'folder_id': child['folder_id'],
        'parent_id': null,
      });
      expect(result['ok'], true);
      expect(result['folder_id'], child['folder_id']);
      expect(await Directory(p.join(root.path, 'Child')).exists(), true);
      final occupied = await Directory(
        p.join(parent['file_path'] as String, 'Child'),
      ).create();
      await expectLater(
        folderAction('folder_move', {
          'folder_id': child['folder_id'],
          'parent_id': parent['folder_id'],
        }),
        error('folder_exists'),
      );
      expect(await occupied.exists(), true);
    },
  );

  test(
    'empty-folder deletion refuses contents and only removes the requested physical directory',
    () async {
      final entry = await createFolder('Empty');
      final path = entry['file_path'] as String;
      final keep = File(p.join(path, 'keep.txt'));
      await keep.writeAsString('Keep');
      await expectLater(
        folderAction('folder_delete_empty', {'folder_id': entry['folder_id']}),
        error('folder_not_empty'),
      );
      expect(await keep.exists(), true);
      await keep.delete();
      final result = await folderAction('folder_delete_empty', {
        'folder_id': entry['folder_id'],
      });
      expect(result['ok'], true);
      expect(await Directory(path).exists(), false);
      expect(await image.exists(), true);
      expect(
        ((await folders())['folders'] as List).map((f) => f['folder_id']),
        isNot(contains(entry['folder_id'])),
      );
    },
  );

  test(
    'folder backup rechecks catalog, directory contents, busy and Stop',
    () async {
      final entry = await createFolder('Guarded');
      final path = entry['file_path'] as String;
      final version = (await folders())['folder_version'];
      binding = hooked(
        () => File(p.join(path, 'user.txt')).writeAsString('New content'),
      );
      await expectLater(
        run({
          'action': 'folder_rename',
          'folder_id': entry['folder_id'],
          'changes': {'name': 'Renamed'},
          'expected_folder_version': version,
        }),
        error('folder_conflict'),
      );
      expect(await Directory(path).exists(), true);
      expect(await Directory(p.join(root.path, 'Renamed')).exists(), false);
      binding = hooked(() async {
        busy = true;
      });
      await expectLater(
        folderAction('folder_rename', {
          'folder_id': entry['folder_id'],
          'changes': {'name': 'Renamed'},
        }),
        error('busy'),
      );
      busy = false;
      await File(p.join(path, 'user.txt')).delete();
      final token = NaiAgentCancellation();
      binding = hooked(() async {
        token.cancel();
      });
      await expectLater(
        run({
          'action': 'folder_delete_empty',
          'folder_id': entry['folder_id'],
          'expected_folder_version': version,
        }, token: token),
        error('cancelled'),
      );
      expect(await Directory(path).exists(), true);
    },
  );

  test(
    'external move waits for real broker submission; decline retains originals, approval preserves ID',
    () async {
      final external = await Directory(p.join(temp.path, 'External')).create();
      await Hive.box(
        StorageKeys.settingsBox,
      ).put(StorageKeys.galleryExtraRoots, [external.path]);
      final first = transfer('move_file', external.path);
      final firstQuestion = await question();
      expect(await image.exists(), true);
      expect(await external.list().length, 0);
      container.read(naiAgentQuestionsProvider).answer(firstQuestion.id, {
        'gallery_change': currentL10n.common_cancel,
      });
      await expectLater(first, error('declined'));
      expect(await image.exists(), true);
      final approved = transfer('move_file', external.path);
      final secondQuestion = await question();
      container.read(naiAgentQuestionsProvider).answer(secondQuestion.id, {
        'gallery_change': currentL10n.common_confirm,
      });
      final result = await approved;
      expect(result['ok'], true);
      expect(result['image_id'], 'gallery:$id');
      expect(await image.exists(), false);
      expect(await File(result['file_path'] as String).exists(), true);
    },
  );

  test(
    'protection confirmation stays pending and source edits during it invalidate the transfer',
    () async {
      await container
          .read(shareImageSettingsProvider.notifier)
          .setConfirmDangerousActions(true);
      final target = await Directory(p.join(root.path, 'Protected')).create();
      final request = transfer('copy_file', target.path);
      final pending = await question();
      await image.writeAsString('Edited while confirming');
      container.read(naiAgentQuestionsProvider).answer(pending.id, {
        'gallery_change': currentL10n.common_confirm,
      });
      await expectLater(request, error('image_conflict'));
      expect(await image.readAsString(), 'Edited while confirming');
      expect(await target.list().length, 0);
    },
  );

  test(
    'tool arguments cannot smuggle authorization, overwrite, external directories or recursive deletion',
    () async {
      final version = (await read())['image_version'];
      for (final invalid in [
        'authorized',
        'approved',
        'overwrite',
        'recursive',
      ]) {
        await expectLater(
          run({
            'action': 'move_file',
            'image_id': 'gallery:$id',
            'expected_image_version': version,
            'target_folder': root.path,
            invalid: true,
          }),
          error('invalid_gallery'),
        );
      }
      await expectLater(
        transfer('copy_file', workspace.path),
        error('image_outside_library'),
      );
      final entry = await createFolder('Safe');
      await expectLater(
        folderAction('folder_delete_empty', {
          'folder_id': entry['folder_id'],
          'recursive': true,
        }),
        error('invalid_gallery'),
      );
      await expectLater(
        folderAction('folder_rename', {
          'folder_id': entry['folder_id'],
          'changes': {'name': '../Outside'},
        }),
        error('invalid_folder'),
      );
      await expectLater(
        run({
          'action': 'folder_create',
          'changes': {'name': 'Stale'},
          'expected_folder_version': 'old',
        }),
        error('folder_conflict'),
      );
      expect(await image.exists(), true);
    },
  );

  test(
    'native directory rename rolls pixels and index back when delete-pool persistence fails',
    () async {
      final entry = await createFolder('Rollback');
      final original = File(
        p.join(entry['file_path'] as String, 'deleted.png'),
      );
      await image.copy(original.path);
      final number = await indexFile(original);
      await source.batchMarkAsDeleted([original.path]);
      await pool.addAll([original.path]);
      final platform = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance = _RejectPreferences({
        'flutter.${StorageKeys.galleryDeletePool}': jsonEncode([original.path]),
      });
      SharedPreferences.resetStatic();
      try {
        final result = await folderAction('folder_rename', {
          'folder_id': entry['folder_id'],
          'changes': {'name': 'Failed'},
        });
        expect(result['ok'], false);
        expect(await original.exists(), true);
        expect(
          (await source.readImageForManagement(number))!.filePath,
          original.path,
        );
        expect((await source.readImageForManagement(number))!.isDeleted, true);
        expect(await Directory(p.join(root.path, 'Failed')).exists(), false);
        expect(
          (await GalleryCategoryRepository.instance.loadCategories())
              .findById(entry['folder_id'] as String)!
              .name,
          'Rollback',
        );
      } finally {
        SharedPreferencesStorePlatform.instance = platform;
        SharedPreferences.resetStatic();
      }
    },
  );

  test(
    'a queued file mutation rechecks Stop after waiting for the real scan mutex',
    () async {
      final target = await Directory(p.join(root.path, 'Locked')).create();
      final entered = Completer<void>(), release = Completer<void>();
      final scanner = GalleryStreamScanner.instance(dataSource: source);
      final holding = scanner.withFilesystemMutation(() async {
        entered.complete();
        await release.future;
      });
      await entered.future;
      final token = NaiAgentCancellation();
      final pending = transfer('move_file', target.path, token: token);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(await target.list().length, 0);
      token.cancel();
      release.complete();
      await holding;
      await expectLater(pending, error('cancelled'));
      expect(await image.exists(), true);
      expect(await target.list().length, 0);
    },
  );

  test(
    'directory relocation keeps the current category identity and other filters',
    () async {
      final entry = await createFolder('Selected');
      await service.applyFilter(
        FilterCriteria(
          categoryId: entry['folder_id'] as String,
          categoryFolderPath: 'Selected',
          searchQuery: 'user search',
          showFavoritesOnly: true,
        ),
      );
      final result = await folderAction('folder_rename', {
        'folder_id': entry['folder_id'],
        'changes': {'name': 'Followed'},
      });
      expect(result['ok'], true);
      expect(service.currentFilter.categoryId, entry['folder_id']);
      expect(service.currentFilter.categoryFolderPath, 'Followed');
      expect(service.currentFilter.searchQuery, 'user search');
      expect(service.currentFilter.showFavoritesOnly, true);
    },
  );

  test(
    'file transfer reports actual path and backup when native index update fails',
    () async {
      final target = await Directory(p.join(root.path, 'Partial')).create();
      await source.execute(
        'inject move failure',
        (db) => db.execute('''
      CREATE TRIGGER reject_agent_path_update BEFORE UPDATE OF file_path ON gallery_images
      BEGIN SELECT RAISE(ABORT, 'injected path persistence failure'); END
    '''),
      );
      try {
        final result = await transfer('move_file', target.path);
        expect(result['ok'], false);
        expect(result['applied_fields'], ['file_moved']);
        expect(result['file_path'], isA<String>());
        expect(await File(result['file_path'] as String).exists(), true);
        expect(await image.exists(), false);
        expect(
          await File(
            p.join(workspace.path, (result['backup'] as Map)['path'] as String),
          ).exists(),
          true,
        );
      } finally {
        await source.execute(
          'remove move failure',
          (db) => db.execute('DROP TRIGGER reject_agent_path_update'),
        );
      }
    },
  );

  test(
    'explicit native folder sync discovers on-disk changes and backs up the existing catalog',
    () async {
      await createFolder('Known');
      final added = await Directory(
        p.join(root.path, 'Outside UI', 'Nested'),
      ).create(recursive: true);
      final before = (await folders())['folders'] as List;
      expect(before.map((f) => f['name']), contains('Known'));
      final result = await folderAction('folder_sync', {});
      expect(result['ok'], true);
      final rows = (await folders())['folders'] as List;
      expect(rows, hasLength(before.length + 2));
      expect(
        rows.any((f) => f['file_path'] == added.resolveSymbolicLinksSync()),
        true,
      );
      final backup =
          jsonDecode(
                await File(
                  p.join(workspace.path, result['backup'] as String),
                ).readAsString(),
              )
              as List;
      expect(backup, hasLength(before.length));
      expect(backup.map((c) => c['name']), contains('Known'));
      expect(await image.exists(), true);
    },
  );

  test(
    'invalid native folder catalog is retained rather than silently rebuilt',
    () async {
      final config = File(p.join(root.path, '.gallery_categories.json'));
      await config.writeAsString('{broken user catalog');
      await expectLater(folders(), error('folder_catalog_failed'));
      expect(await config.readAsString(), '{broken user catalog');
      expect(await image.exists(), true);
    },
  );

  test(
    'physical folder writes wait for the native index to protect existing associations',
    () async {
      final entry = await createFolder('Wait for index');
      await source.dispose();
      try {
        await expectLater(
          folderAction('folder_rename', {
            'folder_id': entry['folder_id'],
            'changes': {'name': 'Should not move'},
          }),
          error('gallery_unavailable'),
        );
        expect(await Directory(entry['file_path'] as String).exists(), true);
        expect(
          await Directory(p.join(root.path, 'Should not move')).exists(),
          false,
        );
        expect(await image.exists(), true);
      } finally {
        await source.initialize();
      }
    },
  );

  test(
    'a newer native category edit after physical relocation is retained with honest partial feedback',
    () async {
      final entry = await createFolder('Original');
      final repo = _AfterRenameRepository(() async {
        final categories = await GalleryCategoryRepository.instance
            .loadCategories();
        await GalleryCategoryRepository.instance.saveCategories([
          for (final category in categories)
            category.id == entry['folder_id']
                ? category.copyWith(name: 'User just edited this label')
                : category,
        ]);
      });
      binding = container.read(
        Provider(
          (ref) => NaiAgentGalleryBinding(
            ref,
            () => alive,
            workspace: workspace,
            isBusy: () => busy,
            categoryRepository: repo,
          ),
        ),
      );
      final result = await folderAction('folder_rename', {
        'folder_id': entry['folder_id'],
        'changes': {'name': 'Moved'},
      });
      expect(result['ok'], false);
      expect(result['error'], 'folder_conflict');
      expect(result['applied_fields'], [
        'index_and_delete_pool_relocated',
        'filesystem_changed',
      ]);
      expect(await Directory(p.join(root.path, 'Moved')).exists(), true);
      expect(
        (await repo.loadCategories())
            .findById(entry['folder_id'] as String)!
            .name,
        'User just edited this label',
      );
      expect(
        await File(p.join(workspace.path, result['backup'] as String)).exists(),
        true,
      );
    },
  );

  test(
    'card undo favorite/tags restores exact state and rejects newer image edits',
    () async {
      final args = {
        'action': 'update',
        'changes': {
          'favorite': true,
          'tags': ['new'],
        },
      };
      final updated = await change(
        'update',
        changes: {
          'favorite': true,
          'tags': ['new'],
        },
      );
      expect(updated['before'], isA<Map>());
      expect(updated['image_version'], (await read())['image_version']);
      expect(await binding.undoManage(args, updated), true);
      expect((await read())['favorite'], false);
      expect((await read())['tags'], isNot(contains('new')));
      final again = await change('update', changes: {'favorite': true});
      await source.setImageTags(id, ['user edit']);
      expect(
        await binding.undoManage({
          'action': 'update',
          'changes': {'favorite': true},
        }, again),
        false,
      );
      expect((await read())['favorite'], true);
    },
  );

  test('card undo delete restores native index and pool', () async {
    final deleted = await change('delete');
    expect(await binding.undoManage({'action': 'delete'}, deleted), true);
    expect((await read())['deleted'], false);
    expect(await pool.load(), isNot(contains(image.path)));
    expect(await image.exists(), true);
  });

  test(
    'card undo move returns to original folder and refuses newer edits',
    () async {
      final target = await Directory(p.join(root.path, 'undo-target')).create();
      final moved = await transfer('move_file', target.path);
      expect(await binding.undoManage({'action': 'move_file'}, moved), true);
      expect((await read())['file_path'], await image.resolveSymbolicLinks());
      expect(await image.exists(), true);
      final again = await transfer('move_file', target.path);
      await source.setImageTags(id, ['newer']);
      expect(await binding.undoManage({'action': 'move_file'}, again), false);
      expect((await read())['file_path'], again['file_path']);
    },
  );

  test(
    'card undo unfavorite restores removed memberships; collection add reverses favorite side effect',
    () async {
      final collection = (await organize('collection_create', {
        'changes': {'name': 'undo'},
      }))['collection_id'];
      await organize('collection_add', {
        'collection_id': collection,
        'image_ids': ['gallery:$id'],
      });
      final unfavorite = await change('update', changes: {'favorite': false});
      expect(
        await binding.undoManage({
          'action': 'update',
          'changes': {'favorite': false},
        }, unfavorite),
        true,
      );
      expect((await read())['collection_ids'], contains(collection));
      await change('update', changes: {'favorite': false});
      final added = await organize('collection_add', {
        'collection_id': collection,
        'image_ids': ['gallery:$id'],
      });
      expect(
        await binding.undoManage({'action': 'collection_add'}, added),
        true,
      );
      expect((await read())['collection_ids'], isNot(contains(collection)));
      expect((await read())['favorite'], false);
    },
  );

  test(
    'read and update use native tags/favorites/membership with exact original backup',
    () async {
      final collection = await source.createCollection(
        'Native favorite subset',
      );
      await source.addFavorite(id);
      await source.addImageToCollection(collection, id);
      // Management must use the native ID even when an existing row has a
      // path alias that differs from the service's normalized file list.
      await source.updateFilePath(id, '${root.path}/original.png');
      await source.upsertMetadata(
        id,
        const NaiImageMetadata(
          prompt: '1girl',
          rawJson: '{"private_reference_encoding":"disk-only"}',
        ),
      );
      final before = await read();
      expect(jsonEncode(before), isNot(contains('disk-only')));
      expect(before['favorite'], true);
      expect(before['collection_ids'], [collection]);
      final state = container.read(imageGenerationNotifierProvider);
      final result = await change(
        'update',
        changes: {
          'favorite': false,
          'tags': [' new ', 'new', 'solo'],
        },
      );
      expect(result['ok'], true);
      expect(result['unfavorite_removes_collection_membership'], true);
      expect(await source.getCollectionIdsForImage(id), isEmpty);
      expect((await read())['tags'], ['new', 'solo']);
      expect(await source.isFavorite(id), false);
      final backup = result['backup'] as Map;
      expect(
        await File(
          p.join(workspace.path, backup['path'] as String),
        ).readAsBytes(),
        await image.readAsBytes(),
      );
      final record =
          jsonDecode(
                await File(
                  p.join(workspace.path, backup['record_path'] as String),
                ).readAsString(),
              )
              as Map;
      expect(record['collection_ids'], [collection]);
      expect(record['metadata']['raw_json'], contains('disk-only'));
      expect(record['tags'], ['original']);
      expect(
        await change('update', changes: {'favorite': false}),
        containsPair('ok', true),
      );
      expect(container.read(imageGenerationNotifierProvider), same(state));
      expect(container.exists(localGalleryNotifierProvider), false);
    },
  );

  test(
    'history export preserves pixels/source/metadata and history deletion removes native pin and selection only',
    () async {
      final state = container.read(imageGenerationNotifierProvider);
      final current = state.currentImages.single;
      final pins = container.read(canvasPinnedNotifierProvider.notifier);
      pins.debugRepository = CanvasPinRepository(
        storage: container.read(localStorageServiceProvider),
        directory: Directory('${temp.path}/pins'),
      );
      await pins.toggle(current);
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select('current');
      final exported = await change(
        'export',
        scope: 'history',
        imageId: 'selected',
      );
      final export = exported['export'] as Map;
      expect(
        await File(
          p.join(workspace.path, export['path'] as String),
        ).readAsBytes(),
        current.bytes,
      );
      expect(
        await File(
          p.join(workspace.path, export['original_path'] as String),
        ).readAsBytes(),
        current.originalBytes,
      );
      expect(container.read(imageGenerationNotifierProvider), same(state));
      final result = await change(
        'delete',
        scope: 'history',
        imageId: 'current',
      );
      expect(result['saved_files_deleted'], false);
      expect(result['ok'], true);
      expect(container.read(canvasPinnedNotifierProvider), isEmpty);
      expect(container.read(generationPreviewSelectionProvider), isNull);
      final after = container.read(imageGenerationNotifierProvider);
      expect(after.currentImages, isEmpty);
      expect(after.displayImages, isEmpty);
      expect(after.history.map((i) => i.id), ['other']);
      expect(await image.exists(), true);
      expect(await source.getImageById(id), isNotNull);
      expect(await pool.load(), isEmpty);
    },
  );

  test(
    'library delete/trash/restore use native index and pool without deleting pixels or history',
    () async {
      final history = container.read(imageGenerationNotifierProvider);
      expect((await change('delete'))['ok'], true);
      expect(await source.getImageById(id), isNull);
      expect((await source.readImageForManagement(id))!.isDeleted, true);
      expect(await pool.load(), [image.path]);
      expect(await image.exists(), true);
      expect(
        (await binding.query({
          'scope': 'library',
        }, NaiAgentCancellation()))['details']['images'],
        isEmpty,
      );
      final trash = await run({
        'action': 'trash',
        'scope': 'library',
        'limit': 1,
      });
      expect((trash['images'] as List).single['image_id'], 'gallery:$id');
      expect((await read())['deleted'], true);
      expect((await change('restore'))['ok'], true);
      expect(await pool.load(), isEmpty);
      expect(await source.getImageById(id), isNotNull);
      expect(
        (await binding.query({
          'scope': 'library',
        }, NaiAgentCancellation()))['details']['images'],
        hasLength(1),
      );
      expect(container.read(imageGenerationNotifierProvider), same(history));
      expect(await backups(), 2);
    },
  );

  test(
    'missing deleted pixels cannot be restored; actual previous backup remains recoverable',
    () async {
      final deleted = await change('delete');
      await image.delete();
      expect((await read())['file_missing'], true);
      await expectLater(change('restore'), error('image_missing'));
      expect(await pool.load(), [image.path]);
      expect(await backups(), 1);
      final backup = deleted['backup'] as Map;
      expect(
        await File(p.join(workspace.path, backup['path'] as String)).exists(),
        true,
      );
    },
  );

  test(
    'versions, busy, invalid fields and closed binding reject before backup',
    () async {
      final old = (await read())['image_version'];
      await source.setImageTags(id, ['manual-edit']);
      await expectLater(
        run({
          'action': 'delete',
          'scope': 'library',
          'image_id': 'gallery:$id',
          'expected_image_version': old,
        }),
        error('image_conflict'),
      );
      await expectLater(
        run({
          'action': 'delete',
          'scope': 'library',
          'image_id': 'gallery:$id',
        }),
        error('image_conflict'),
      );
      await expectLater(
        change('update', changes: {'invented': true}),
        error('invalid_gallery'),
      );
      busy = true;
      await expectLater(change('delete'), error('busy'));
      busy = false;
      alive = false;
      await expectLater(read(), error('closed'));
      alive = true;
      expect(await backups(), 0);
      expect(await source.getImageById(id), isNotNull);
    },
  );

  test(
    'actual backup IO followed by manual pixel edit prevents native deletion',
    () async {
      final before = await read();
      final original = await image.readAsBytes();
      final mutated = img.encodePng(img.Image(width: 19, height: 13));
      final tool = hooked(() async => image.writeAsBytes(mutated));
      await expectLater(
        tool.manage({
          'action': 'delete',
          'scope': 'library',
          'image_id': 'gallery:$id',
          'expected_image_version': before['image_version'],
        }, NaiAgentCancellation()),
        error('image_conflict'),
      );
      expect(await pool.load(), isEmpty);
      expect(await source.getImageById(id), isNotNull);
      final dirs = await Directory(
        '${workspace.path}/.W.O.F/outputs',
      ).list().toList();
      expect(
        await File('${dirs.single.path}/image.png').readAsBytes(),
        original,
      );
      expect(await image.readAsBytes(), mutated);
    },
  );

  for (final condition in ['stop', 'closed', 'busy']) {
    test(
      '$condition after actual backup prevents native library mutation',
      () async {
        final before = await read(), token = NaiAgentCancellation();
        final tool = hooked(() async {
          if (condition == 'stop') token.cancel();
          if (condition == 'closed') alive = false;
          if (condition == 'busy') busy = true;
        });
        await expectLater(
          tool.manage({
            'action': 'delete',
            'scope': 'library',
            'image_id': 'gallery:$id',
            'expected_image_version': before['image_version'],
          }, token),
          error(condition == 'stop' ? 'cancelled' : condition),
        );
        expect(await source.getImageById(id), isNotNull);
        expect(await pool.load(), isEmpty);
        expect(await backups(), 1);
      },
    );
  }

  test(
    'changed roots reject management of stale rows; trash also excludes them',
    () async {
      final replacement = await Directory('${temp.path}/replacement').create();
      await Hive.box(
        StorageKeys.settingsBox,
      ).put(StorageKeys.imageSavePath, replacement.path);
      await expectLater(read(), error('image_outside_library'));
      await source.batchMarkAsDeleted([image.path]);
      expect(
        (await run({'action': 'trash', 'scope': 'library'}))['images'],
        isEmpty,
      );
      expect(await backups(), 0);
    },
  );

  test(
    'native visible tag filter refresh preserves dataset and current criteria',
    () async {
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setSelectedTags(['original']);
      final before = container.read(localGalleryNotifierProvider);
      expect(before.timeline.entries, hasLength(1));
      expect(
        (await change(
          'update',
          changes: {
            'tags': ['new'],
          },
        ))['ok'],
        true,
      );
      final after = container.read(localGalleryNotifierProvider);
      expect(after.filterCriteria, before.filterCriteria);
      expect(after.timeline.datasetId, before.timeline.datasetId);
      expect(after.timeline.entries, isEmpty);
      expect(after.contentRevision, greaterThan(before.contentRevision));
    },
  );

  test(
    'official Pi manages the actual native gallery through local SSE and preserves backups',
    () async {
      final requests = <Map<String, dynamic>>[],
          events = <Map<String, dynamic>>[];
      final server = await bindFetchTestServer();
      Map<String, dynamic> call(
        int turn,
        String name,
        Map<String, dynamic> arguments,
      ) => {
        'role': 'assistant',
        'tool_calls': [
          {
            'index': 0,
            'id': 'call-$turn',
            'type': 'function',
            'function': {
              'name':
                  [
                    'read',
                    'write',
                    'edit',
                    'bash',
                    'studio_context',
                    'ask_user',
                  ].contains(name)
                  ? name
                  : 'mcp__nai_studio__$name',
              'arguments': jsonEncode(arguments),
            },
          },
        ],
      };
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1) {
          final content = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          previous =
              jsonDecode(content is String ? content : content[0]['text'])
                  as Map;
        }
        final base = {'scope': 'library', 'image_id': 'gallery:$id'};
        final delta = switch (turn) {
          1 ||
          3 ||
          5 ||
          8 => call(turn, 'gallery_manage', {'action': 'read', ...base}),
          2 => call(turn, 'gallery_manage', {
            'action': 'update',
            ...base,
            'expected_image_version': previous!['image_version'],
            'changes': {
              'favorite': true,
              'tags': ['Pi-native'],
            },
          }),
          4 => call(turn, 'gallery_manage', {
            'action': 'export',
            ...base,
            'expected_image_version': previous!['image_version'],
          }),
          6 => call(turn, 'gallery_manage', {
            'action': 'delete',
            ...base,
            'expected_image_version': previous!['image_version'],
          }),
          7 => call(turn, 'gallery_manage', {
            'action': 'trash',
            'scope': 'library',
          }),
          9 => call(turn, 'gallery_manage', {
            'action': 'restore',
            ...base,
            'expected_image_version': previous!['image_version'],
          }),
          10 => call(turn, 'gallery_query', {
            'scope': 'library',
            'favorites': true,
          }),
          _ => {'content': '图库已整理，图片恢复，备份保留。'},
        };
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        for (final choice in [
          {'index': 0, 'delta': delta, 'finish_reason': null},
          {
            'index': 0,
            'delta': {},
            'finish_reason': turn < 11 ? 'tool_calls' : 'stop',
          },
        ]) {
          request.response.write(
            'data: ${jsonEncode({
              'id': 'synthetic',
              'object': 'chat.completion.chunk',
              'model': 'synthetic',
              'choices': [choice],
            })}\n\n',
          );
        }
        request.response.write('data: [DONE]\n\n');
        await request.response.close();
      });
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? subscription;
      final original = await image.readAsBytes();
      final history = container.read(imageGenerationNotifierProvider);
      try {
        client = await PiHostClient.start(
          mcp: const {'builtinExposure': 'direct'},
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'native-gallery-management',
          workspaceDirectory: workspace,
          agentDirectory: Directory('${workspace.path}/.W.O.F'),
          systemPrompt: 'NAI Agent uses actual native gallery tools.',
          privateModelConfig: {
            'providerId': 'local',
            'modelId': 'synthetic',
            'protocol': 'openaiChatCompletions',
            'baseUrl': 'http://127.0.0.1:${server.port}',
            'apiKey': 'synthetic-private-key',
            'tools': true,
            'vision': true,
            'maxConcurrentRequests': 1,
          },
          extraToolNames: ['gallery_query', 'gallery_manage'],
          executeTool: (name, params, token) async {
            if (name == '_nai_extension_ui' &&
                params['kind'] == 'tool_approval') {
              return {
                'content': [
                  {
                    'type': 'text',
                    'text': jsonEncode({
                      'status': 'answered',
                      'value': (params['options'] as List).first,
                    }),
                  },
                ],
              };
            }
            return name == 'gallery_manage'
                ? binding.manage(params, token)
                : binding.query(params, token);
          },
        );
        subscription = client.events.listen(events.add);
        await client
            .prompt('整理收藏和标签，导出，删除后恢复。')
            .timeout(const Duration(seconds: 30));
        expect(requests, hasLength(11));
        final ends = events
            .where((event) => event['event']?['type'] == 'tool_execution_end')
            .toList();
        expect(ends, hasLength(10));
        expect(ends.every((event) => event['event']['isError'] == false), true);
        expect(
          ends.every(
            (event) =>
                event['event']['result']?['structuredContent']?['structuredContent']?['ok'] !=
                false,
          ),
          true,
        );
        expect(await source.getImageTags(id), ['Pi-native']);
        expect(await source.isFavorite(id), true);
        expect((await source.readImageForManagement(id))!.isDeleted, false);
        expect(await pool.load(), isEmpty);
        expect(await image.readAsBytes(), original);
        expect(container.read(imageGenerationNotifierProvider), same(history));
        final directories = await Directory(
          '${workspace.path}/.W.O.F/outputs',
        ).list().toList();
        expect(directories, hasLength(4));
        for (final directory in directories) {
          expect(
            await File('${directory.path}/image.png').readAsBytes(),
            original,
          );
        }
        expect(jsonEncode(requests), isNot(contains('synthetic-private-key')));
      } finally {
        await subscription?.cancel();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );

  test(
    'actual directory link outside current library roots rejects management',
    () async {
      final outside = await Directory(p.join(temp.path, 'outside')).create();
      final external = File(p.join(outside.path, 'outside.png'));
      await external.writeAsBytes(await image.readAsBytes());
      final link = Directory(p.join(root.path, 'linked'));
      if (Platform.isWindows) {
        final result = await Process.run('cmd.exe', [
          '/c',
          'mklink',
          '/J',
          link.path,
          outside.path,
        ]);
        expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
      } else {
        await Link(link.path).create(outside.path);
      }
      final path = p.join(link.path, 'outside.png'),
          date = DateTime(2026, 8, 1);
      final linkedId = await source.upsertImage(
        filePath: path,
        fileName: 'outside.png',
        fileSize: await external.length(),
        createdAt: date,
        modifiedAt: date,
      );
      await expectLater(
        read(imageId: 'gallery:$linkedId'),
        error('image_outside_library'),
      );
      expect(await external.exists(), true);
      expect(await backups(), 0);
    },
  );

  test(
    'delete-pool persistence rejection reports partial delete; restore rejection keeps index deleted',
    () async {
      SharedPreferencesStorePlatform.instance = _RejectPreferences({});
      final result = await change('delete');
      expect(result['ok'], false);
      expect(result['applied_fields'], ['index_deleted']);
      expect((await source.readImageForManagement(id))!.isDeleted, true);
      expect(await image.exists(), true);
      SharedPreferences.setMockInitialValues({
        StorageKeys.galleryDeletePool: jsonEncode([image.path]),
      });
      SharedPreferencesStorePlatform.instance = _RejectPreferences({
        'flutter.${StorageKeys.galleryDeletePool}': jsonEncode([image.path]),
      });
      final restored = await change('restore');
      expect(restored['ok'], false);
      expect(restored['applied_fields'], isEmpty);
      expect((await source.readImageForManagement(id))!.isDeleted, true);
    },
  );

  test(
    'native collection tree lifecycle keeps pixels and favorite semantics',
    () async {
      final original = await image.readAsBytes();
      final history = container.read(imageGenerationNotifierProvider);
      final folder =
          (await organize('collection_create', {
                'changes': {'name': 'Studies', 'is_folder': true},
              }))['collection_id']
              as String;
      final leaf =
          (await organize('collection_create', {
                'changes': {'name': 'Blue', 'parent_id': folder},
              }))['collection_id']
              as String;
      final other = await source.createCollection('Green', parentId: folder);
      final add = {
        'collection_id': leaf,
        'image_ids': ['gallery:$id'],
      };
      expect((await organize('collection_add', add))['ok'], true);
      expect((await organize('collection_add', add))['ok'], true);
      await organize('collection_add', {...add, 'collection_id': other});
      final tree = await collections();
      final rows = (tree['collections'] as List).cast<Map>();
      expect(rows.singleWhere((row) => row['id'] == folder)['image_count'], 1);
      expect(rows.singleWhere((row) => row['id'] == folder)['is_folder'], true);
      final members = await run({
        'action': 'collection_members',
        'collection_id': folder,
        'limit': 1,
      });
      expect(members['images'], hasLength(1));
      expect(members['total'], 1);
      expect(members['next_offset'], null);
      expect(
        (await run({'action': 'collections', 'query': 'blue'}))['total'],
        1,
      );
      expect(
        (await run({'action': 'collections', 'limit': 1}))['next_offset'],
        1,
      );
      final count = await backups();
      await expectLater(
        organize('collection_delete', {'collection_id': folder}),
        error('collection_not_empty'),
      );
      expect(await backups(), count);
      await organize('collection_remove', add);
      expect(await source.isFavorite(id), true);
      expect(await source.getCollectionIdsForImage(id), {other});
      await organize('collection_update', {
        'collection_id': leaf,
        'changes': {'name': 'Renamed', 'parent_id': null},
      });
      await organize('collection_reorder', {
        'ordered_collection_ids': [leaf, folder],
      });
      final roots = ((await collections())['collections'] as List)
          .where((row) => row['parent_id'] == null)
          .map((row) => row['id'])
          .toList();
      expect(roots, [leaf, folder]);
      await organize('collection_delete', {'collection_id': leaf});
      await organize('collection_delete', {'collection_id': other});
      await organize('collection_delete', {'collection_id': folder});
      expect((await collections())['collections'], isEmpty);
      expect(await source.isFavorite(id), true);
      expect(await source.getCollectionIdsForImage(id), isEmpty);
      expect(await image.readAsBytes(), original);
      expect(container.read(imageGenerationNotifierProvider), same(history));
      expect(container.exists(localGalleryNotifierProvider), false);
      final exports = await Directory(
        '${workspace.path}/.W.O.F/outputs',
      ).list().toList();
      for (final directory in exports) {
        final entries = await Directory(directory.path).list().toList();
        expect(entries.map((entry) => p.basename(entry.path)), [
          'gallery-collections.json',
        ]);
        final snapshot =
            jsonDecode(await File(entries.single.path).readAsString()) as Map;
        expect(snapshot['collections'], isA<List>());
        expect(snapshot['members'], isA<List>());
        expect(snapshot['collection_version'], isA<String>());
      }
    },
  );

  test(
    'invalid collection mutations reject before backup or native writes',
    () async {
      final folder = await source.createCollection('Folder', isFolder: true);
      final child = await source.createCollection(
        'Child',
        parentId: folder,
        isFolder: true,
      );
      final leaf = await source.createCollection('Leaf', parentId: folder);
      final before = await source.readCollectionManagementState();
      final invalid = <Map<String, dynamic>>[
        {
          'action': 'collection_create',
          'scope': 'history',
          'changes': {'name': 'x'},
        },
        {
          'action': 'collection_create',
          'changes': {'name': 'x', 'parent_id': leaf},
        },
        {
          'action': 'collection_update',
          'collection_id': leaf,
          'changes': {'is_folder': true},
        },
        {
          'action': 'collection_add',
          'collection_id': folder,
          'image_ids': ['gallery:$id'],
        },
        {
          'action': 'collection_add',
          'collection_id': leaf,
          'image_ids': ['gallery:$id', 'gallery:$id'],
        },
        {
          'action': 'collection_reorder',
          'parent_id': folder,
          'ordered_collection_ids': [child],
        },
        {
          'action': 'collection_reorder',
          'ordered_collection_ids': [folder, leaf],
        },
        {
          'action': 'collection_create',
          'changes': {'name': '  '},
        },
      ];
      for (final params in invalid) {
        await expectLater(
          run({
            'expected_collection_version':
                (await collections())['collection_version'],
            ...params,
          }),
          error('invalid_collection'),
        );
      }
      for (final parent in [folder, child]) {
        await expectLater(
          organize('collection_update', {
            'collection_id': folder,
            'changes': {'parent_id': parent},
          }),
          error('collection_cycle'),
        );
      }
      await expectLater(
        run({'action': 'collection_delete', 'collection_id': leaf}),
        error('collection_conflict'),
      );
      expect(await source.readCollectionManagementState(), before);
      expect(await backups(), 0);
    },
  );

  test(
    'collection changes during real backup and stale versions preserve latest edits',
    () async {
      final leaf = await source.createCollection('Original');
      final before = await collections();
      await source.renameCollection(leaf, 'User edit');
      await expectLater(
        run({
          'action': 'collection_update',
          'collection_id': leaf,
          'expected_collection_version': before['collection_version'],
          'changes': {'name': 'stale'},
        }),
        error('collection_conflict'),
      );
      expect(await backups(), 0);
      final version = (await collections())['collection_version'];
      await expectLater(
        hooked(() async {
          await source.renameCollection(leaf, 'New user edit');
        }).manage({
          'action': 'collection_update',
          'collection_id': leaf,
          'expected_collection_version': version,
          'changes': {'name': 'agent'},
        }, NaiAgentCancellation()),
        error('collection_conflict'),
      );
      final rows =
          (await source.readCollectionManagementState())['collections'] as List;
      expect(rows.single['name'], 'New user edit');
      expect(await backups(), 1);
      final output = (await Directory(
        '${workspace.path}/.W.O.F/outputs',
      ).list().toList()).single;
      final saved =
          jsonDecode(
                await File(
                  '${output.path}/gallery-collections.json',
                ).readAsString(),
              )
              as Map;
      expect((saved['collections'] as List).single['name'], 'User edit');
    },
  );

  for (final condition in ['stop', 'closed', 'busy']) {
    test('$condition after real collection backup prevents mutation', () async {
      final leaf = await source.createCollection('Original');
      final version = (await collections())['collection_version'];
      final token = NaiAgentCancellation();
      await expectLater(
        hooked(() async {
          if (condition == 'stop') token.cancel();
          if (condition == 'closed') alive = false;
          if (condition == 'busy') busy = true;
        }).manage({
          'action': 'collection_update',
          'collection_id': leaf,
          'expected_collection_version': version,
          'changes': {'name': 'agent'},
        }, token),
        error(condition == 'stop' ? 'cancelled' : condition),
      );
      final rows =
          (await source.readCollectionManagementState())['collections'] as List;
      expect(rows.single['name'], 'Original');
      expect(await backups(), 1);
    });
  }

  test(
    'collection membership rechecks actual files and current roots after backup',
    () async {
      final leaf = await source.createCollection('Original');
      final version = (await collections())['collection_version'];
      await expectLater(
        hooked(() async => image.delete()).manage({
          'action': 'collection_add',
          'collection_id': leaf,
          'image_ids': ['gallery:$id'],
          'expected_collection_version': version,
        }, NaiAgentCancellation()),
        error('image_missing'),
      );
      expect(await source.isFavorite(id), false);
      expect(await source.getCollectionIdsForImage(id), isEmpty);
      await source.addFavorite(id);
      await source.addImageToCollection(leaf, id);
      expect(
        (await run({
          'action': 'collection_members',
          'collection_id': leaf,
        }))['images'].single['file_missing'],
        true,
      );
      expect(
        (await organize('collection_remove', {
          'collection_id': leaf,
          'image_ids': ['gallery:$id'],
        }))['ok'],
        true,
      );
      expect(await source.isFavorite(id), true);
      await image.writeAsBytes(img.encodePng(img.Image(width: 16, height: 12)));
      final fresh = (await collections())['collection_version'];
      await expectLater(
        hooked(() async {
          final replacement = await Directory(
            p.join(temp.path, 'replacement'),
          ).create();
          await Hive.box(
            StorageKeys.settingsBox,
          ).put(StorageKeys.imageSavePath, replacement.path);
        }).manage({
          'action': 'collection_add',
          'collection_id': leaf,
          'image_ids': ['gallery:$id'],
          'expected_collection_version': fresh,
        }, NaiAgentCancellation()),
        error('image_outside_library'),
      );
      expect(await source.getCollectionIdsForImage(id), isEmpty);
    },
  );

  test(
    'native collection filters refresh membership and only clear the deleted current filter',
    () async {
      final leaf = await source.createCollection('One');
      final other = await source.createCollection('Two');
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.setSelectedCollection(leaf);
      final before = container.read(localGalleryNotifierProvider);
      expect(before.timeline.entries, isEmpty);
      await organize('collection_add', {
        'collection_id': leaf,
        'image_ids': ['gallery:$id'],
      });
      final after = container.read(localGalleryNotifierProvider);
      expect(after.filterCriteria, before.filterCriteria);
      expect(after.timeline.datasetId, before.timeline.datasetId);
      expect(after.timeline.entries, hasLength(1));
      final version = (await collections())['collection_version'];
      await hooked(() => notifier.setSelectedCollection(other)).manage({
        'action': 'collection_delete',
        'collection_id': leaf,
        'expected_collection_version': version,
      }, NaiAgentCancellation());
      expect(
        container
            .read(localGalleryNotifierProvider)
            .filterCriteria
            .collectionId,
        other,
      );
      await organize('collection_delete', {'collection_id': other});
      expect(
        container
            .read(localGalleryNotifierProvider)
            .filterCriteria
            .collectionId,
        null,
      );
      expect(await source.isFavorite(id), true);
      expect(await image.exists(), true);
    },
  );

  test(
    'native rename followed by failed move reports the actual partial commit',
    () async {
      final folder = await source.createCollection('Folder', isFolder: true);
      final leaf = await source.createCollection('Original');
      await container.read(collectionNotifierProvider.notifier).initialize();
      await source.execute(
        'injectMoveFailure',
        (db) => db.execute('''
      CREATE TRIGGER reject_collection_move BEFORE UPDATE OF parent_id ON gallery_collections
      BEGIN SELECT RAISE(ABORT, 'injected native move failure'); END
    '''),
      );
      final result = await organize('collection_update', {
        'collection_id': leaf,
        'changes': {'name': 'Renamed', 'parent_id': folder},
      });
      expect(result['ok'], false);
      expect(result['applied_fields'], ['name']);
      final rows =
          (await source.readCollectionManagementState())['collections'] as List;
      final current = rows.singleWhere((row) => row['id'] == leaf);
      expect(current['name'], 'Renamed');
      expect(current['parent_id'], null);
      expect(
        container
            .read(collectionNotifierProvider)
            .collections
            .singleWhere((entry) => entry.id == leaf)
            .name,
        'Renamed',
      );
      final saved =
          jsonDecode(
                await File(
                  '${workspace.path}/${result['backup']}',
                ).readAsString(),
              )
              as Map;
      expect(
        (saved['collections'] as List).singleWhere(
          (row) => row['id'] == leaf,
        )['name'],
        'Original',
      );
      expect(await image.exists(), true);
    },
  );

  test(
    'official Pi organizes native collections using serialized JSON arrays',
    () async {
      final requests = <Map<String, dynamic>>[],
          events = <Map<String, dynamic>>[];
      String? folder, leaf;
      final original = await image.readAsBytes();
      final history = container.read(imageGenerationNotifierProvider);
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1) {
          final content = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          previous =
              jsonDecode(content is String ? content : content[0]['text'])
                  as Map;
        }
        if (turn == 3) folder = previous!['collection_id'] as String;
        if (turn == 4) leaf = previous!['collection_id'] as String;
        final arguments = switch (turn) {
          1 || 7 || 12 => {'action': 'collections'},
          2 => {
            'action': 'collection_create',
            'changes': {'name': 'Pi folder', 'is_folder': true},
          },
          3 => {
            'action': 'collection_create',
            'changes': {'name': 'Pi leaf', 'parent_id': folder},
          },
          4 => {
            'action': 'collection_add',
            'collection_id': leaf,
            'image_ids': ['gallery:$id'],
          },
          5 => {'action': 'collection_members', 'collection_id': folder},
          6 => {
            'action': 'collection_update',
            'collection_id': leaf,
            'changes': {'name': 'Renamed', 'parent_id': null},
          },
          8 => {
            'action': 'collection_reorder',
            'ordered_collection_ids': [leaf, folder],
          },
          9 => {
            'action': 'collection_remove',
            'collection_id': leaf,
            'image_ids': ['gallery:$id'],
          },
          10 => {'action': 'collection_delete', 'collection_id': leaf},
          11 => {'action': 'collection_delete', 'collection_id': folder},
          _ => <String, Object?>{},
        };
        if (turn < 13 && ![1, 5, 7, 12].contains(turn)) {
          arguments['expected_collection_version'] =
              previous!['collection_version'];
        }
        final delta = turn == 13
            ? {'content': '收藏集整理完成。'}
            : {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call-$turn',
                    'type': 'function',
                    'function': {
                      'name': 'mcp__nai_studio__gallery_manage',
                      'arguments': jsonEncode(arguments),
                    },
                  },
                ],
              };
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        for (final choice in [
          {'index': 0, 'delta': delta, 'finish_reason': null},
          {
            'index': 0,
            'delta': {},
            'finish_reason': turn < 13 ? 'tool_calls' : 'stop',
          },
        ]) {
          request.response.write(
            'data: ${jsonEncode({
              'id': 'synthetic',
              'object': 'chat.completion.chunk',
              'model': 'synthetic',
              'choices': [choice],
            })}\n\n',
          );
        }
        request.response.write('data: [DONE]\n\n');
        await request.response.close();
      });
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? subscription;
      try {
        client = await PiHostClient.start(
          mcp: const {'builtinExposure': 'direct'},
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'native-collection-management',
          workspaceDirectory: workspace,
          agentDirectory: Directory('${workspace.path}/.W.O.F'),
          systemPrompt: 'Use actual native collection tools.',
          privateModelConfig: {
            'providerId': 'local',
            'modelId': 'synthetic',
            'protocol': 'openaiChatCompletions',
            'baseUrl': 'http://127.0.0.1:${server.port}',
            'apiKey': 'synthetic-private-key',
            'tools': true,
            'vision': true,
            'maxConcurrentRequests': 1,
          },
          extraToolNames: ['gallery_manage'],
          executeTool: (name, params, token) async {
            if (name == '_nai_extension_ui' &&
                params['kind'] == 'tool_approval') {
              return {
                'content': [
                  {
                    'type': 'text',
                    'text': jsonEncode({
                      'status': 'answered',
                      'value': (params['options'] as List).first,
                    }),
                  },
                ],
              };
            }
            return binding.manage(params, token);
          },
        );
        subscription = client.events.listen(events.add);
        await client
            .prompt('创建目录和收藏集，添加图片，移到根目录并排序，随后移除并清理集合。')
            .timeout(const Duration(seconds: 30));
        expect(requests, hasLength(13));
        final ends = events
            .where((event) => event['event']?['type'] == 'tool_execution_end')
            .toList();
        expect(ends, hasLength(12));
        expect(ends.every((event) => event['event']['isError'] == false), true);
        expect(
          ends.every(
            (event) => event['event']['result']?['details']?['ok'] != false,
          ),
          true,
        );
        final results = ends
            .map(
              (event) =>
                  event['event']['result']['structuredContent']['structuredContent']
                      as Map,
            )
            .toList();
        expect(results[4]['images'].single['image_id'], 'gallery:$id');
        expect(results[11]['collections'], isEmpty);
        expect(await source.getCollectionIdsForImage(id), isEmpty);
        expect(await source.isFavorite(id), true);
        expect(await image.readAsBytes(), original);
        expect(container.read(imageGenerationNotifierProvider), same(history));
        expect(await backups(), 8);
        for (final directory in await Directory(
          '${workspace.path}/.W.O.F/outputs',
        ).list().toList()) {
          expect(await Directory(directory.path).list().length, 1);
          expect(
            await File('${directory.path}/gallery-collections.json').exists(),
            true,
          );
        }
        expect(jsonEncode(requests), isNot(contains('synthetic-private-key')));
      } finally {
        await subscription?.cancel();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}

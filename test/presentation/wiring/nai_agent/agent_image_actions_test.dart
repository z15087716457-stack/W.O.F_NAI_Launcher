import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/metadata/metadata_import_options.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_generation_target.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_platform.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_image_actions.dart';

class _Backup extends ImageViewerPlatform {
  final snapshots = <String>[];
  bool fail = false;
  @override
  Future<void> backupDraft(String snapshot) async {
    if (fail) throw StateError('backup failed');
    snapshots.add(snapshot);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProviderContainer container;
  late _Backup backup;
  late AgentImageActions actions;
  late Uint8List png;
  late AgentImage image;
  late bool alive;
  late List<String> revealed;
  setUpAll(() async {
    root = await Directory.systemTemp.createTemp('agent-image-actions-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = _Backup();
    alive = true;
    revealed = [];
    container = ProviderContainer(
      overrides: [imageViewerPlatformProvider.overrideWithValue(backup)],
    );
    png = img.encodePng(img.Image(width: 4, height: 3));
    image = AgentImage(id: 'pixels', image: MemoryImage(png));
    actions = AgentImageActions(
      read: container.read,
      alive: () => alive,
      capture: () => container
          .read(imageViewerGenerationTargetProvider)
          .capture(alive: () => alive),
      chooseReferenceType: () async => PreciseRefType.character,
      chooseImportSelection: (_, _, _) async =>
          const OfficialMetadataImportSelection(
            importPrompt: true,
            importGenerationParams: true,
            importSeed: true,
          ),
      revealFile: (path) async => revealed.add(path),
    );
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.box(StorageKeys.settingsBox).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'folder requires nonblank path; no draft/provider initialization',
    () async {
      for (final path in [null, '', ' ']) {
        expect(
          await actions.perform(
            AgentImage(id: 'folder', image: image.image, path: path),
            AgentImageAction.folder,
          ),
          false,
        );
      }
      final file = AgentImage(
        id: 'folder',
        image: image.image,
        path: '${root.path}/original.png',
      );
      expect(await actions.perform(file, AgentImageAction.folder), true);
      expect(revealed, [file.path]);
      expect(container.exists(generationParamsNotifierProvider), false);
      expect(backup.snapshots, isEmpty);
    },
  );

  test(
    'memory/history/file resolution preserves bytes without network',
    () async {
      expect(await agentImageBytes(image), same(png));
      final file = File('${root.path}/read.png');
      await file.writeAsBytes(png);
      expect(
        await agentImageBytes(AgentImage(id: 'file', image: FileImage(file))),
        png,
      );
      const history = AgentImage(
        id: 'history',
        image: AssetImage('never-load'),
        historyId: 'h',
      );
      expect(
        await agentImageBytes(
          history,
          historyBytes: (id) => id == 'h' ? png : null,
        ),
        same(png),
      );
      expect(await agentImageBytes(history), isNull);
      expect(
        await agentImageBytes(
          null,
          fallbackHistoryId: 'h',
          historyBytes: (_) => png,
        ),
        same(png),
      );
      await file.delete();
    },
  );

  test(
    'params without metadata returns false and never backs up or writes',
    () async {
      expect(await actions.perform(image, AgentImageAction.params), false);
      expect(backup.snapshots, isEmpty);
      expect(container.read(generationParamsNotifierProvider).prompt, isEmpty);
    },
  );

  test(
    'Vibe only stages raw bytes; precise uses chosen type; never generates',
    () async {
      expect(await actions.perform(image, AgentImageAction.vibe), true);
      final vibe = container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single;
      expect(vibe.rawImageData, png);
      expect(vibe.vibeEncoding, isEmpty);
      expect(await actions.perform(image, AgentImageAction.reference), true);
      final precise = container
          .read(generationParamsNotifierProvider)
          .preciseReferences
          .single;
      expect(precise.image, png);
      expect(precise.type, PreciseRefType.character);
      expect(backup.snapshots, hasLength(2));
      expect(
        container.read(imageGenerationNotifierProvider).isGenerating,
        false,
      );
    },
  );

  test('metadata selection writes through coordinator after backup', () async {
    actions = AgentImageActions(
      read: container.read,
      alive: () => true,
      capture: () => container
          .read(imageViewerGenerationTargetProvider)
          .capture(alive: () => true),
      chooseReferenceType: () async => null,
      readMetadata: (_) async =>
          const NaiImageMetadata(prompt: 'imported', steps: 19, seed: 77),
      chooseImportSelection: (_, _, _) async =>
          const OfficialMetadataImportSelection(
            importPrompt: true,
            importGenerationParams: true,
            importSeed: true,
          ),
    );
    expect(await actions.perform(image, AgentImageAction.params), true);
    final params = container.read(generationParamsNotifierProvider);
    expect(params.prompt, 'imported');
    expect(params.steps, 19);
    expect(params.seed, 77);
    expect(backup.snapshots, hasLength(1));
  });

  test(
    'missing image, dead caller, unreadable file and backup failure are false',
    () async {
      expect(await actions.perform(null, AgentImageAction.vibe), false);
      expect(
        await actions.perform(
          AgentImage(
            id: 'missing',
            image: FileImage(File('${root.path}/missing.png')),
          ),
          AgentImageAction.vibe,
        ),
        false,
      );
      backup.fail = true;
      expect(await actions.perform(image, AgentImageAction.vibe), false);
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        isEmpty,
      );
      alive = false;
      expect(await actions.perform(image, AgentImageAction.vibe), false);
    },
  );

  test('edit while reference chooser is open is not overwritten', () async {
    final choice = Completer<PreciseRefType?>();
    actions = AgentImageActions(
      read: container.read,
      alive: () => true,
      capture: () => container
          .read(imageViewerGenerationTargetProvider)
          .capture(alive: () => true),
      chooseReferenceType: () => choice.future,
      chooseImportSelection: (_, _, _) async => null,
    );
    final pending = actions.perform(image, AgentImageAction.reference);
    await Future<void>.delayed(Duration.zero);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new edit');
    choice.complete(PreciseRefType.character);
    expect(await pending, false);
    expect(
      container.read(generationParamsNotifierProvider).preciseReferences,
      isEmpty,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, 'new edit');
    expect(backup.snapshots, isEmpty);
  });
}

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_binding.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_library_binding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProviderContainer container;
  late NaiAgentReferenceBinding draft;
  late NaiAgentReferenceLibraryBinding library;
  late PreciseRefLibraryStorageService precise;
  final pixels = img.encodePng(img.Image(width: 16, height: 16));

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-precise-backend-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    precise = PreciseRefLibraryStorageService(
      overrideDirectory: '${root.path}/references',
    );
    container = ProviderContainer(
      overrides: [
        preciseRefLibraryStorageServiceProvider.overrideWithValue(precise),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          _MemoryGenerationState(),
        ),
      ],
    );
    Future<NaiAgentImage> load(
      Map<String, dynamic> _,
      NaiAgentCancellation cancellation,
    ) async => NaiAgentImage(id: 'image.png', bytes: pixels);
    final bindings = Provider((ref) {
      final draft = NaiAgentReferenceBinding(
        ref,
        root,
        load,
        () => false,
        () => true,
      );
      final library = NaiAgentReferenceLibraryBinding(
        ref,
        root,
        draft,
        load,
        () => false,
        () => true,
      );
      return (draft, library);
    });
    (draft, library) = container.read(bindings);
    await File('${root.path}/image.png').writeAsBytes(pixels);
  });

  GenerationParamsNotifier writer() =>
      container.read(generationParamsNotifierProvider.notifier);
  ImageParams read() => container.read(generationParamsNotifierProvider);
  Matcher failure(String code) => throwsA(
    isA<NaiAgentToolError>().having((error) => error.code, 'code', code),
  );
  Future<Map<String, dynamic>> edit(
    String action,
    Map<String, dynamic> fields,
  ) => draft.execute({
    'action': action,
    'expected_draft_version': draft.summary()['draft_version'],
    ...fields,
  }, NaiAgentCancellation());
  Future<Map> useLibrary(Map<String, dynamic> fields) async =>
      (await library.execute({
            'kind': 'precise',
            ...fields,
          }, NaiAgentCancellation()))['details']
          as Map;

  tearDown(() async {
    await writer().saveGenerationState();
    container.dispose();
    await precise.close();
    await Hive.close();
    await root.delete(recursive: true);
  });

  test(
    'draft V5 references retain raw pixels and report active restrictions',
    () async {
      writer().updateModel(ImageModels.animeDiffusionV5FullMedium);
      await edit('add_precise', {
        'path': 'image.png',
        'type': 'characterAndStyle',
        'strength': 5,
        'prefer_same_outfit': false,
      });
      expect(read().model, ImageModels.animeDiffusionV5Full);
      expect(read().preciseReferences.single.image, pixels);
      expect(read().preciseReferences.single.preferSameOutfit, isFalse);
      expect(draft.summary(), containsPair('strength_max', 5.0));
      expect(draft.summary(), containsPair('outfit_references', true));
      expect(draft.summary(), containsPair('fidelity_supported', false));
      expect(draft.summary(), containsPair('char_ref_inpainting', false));
      await edit('update_precise', {'index': 0, 'preferSameOutfit': true});
      expect(read().preciseReferences.single.preferSameOutfit, isTrue);
      await expectLater(
        edit('update_precise', {'index': 0, 'strength': 5.1}),
        failure('invalid_reference'),
      );
      await expectLater(
        edit('update_precise', {'index': 0, 'fidelity': 0.5}),
        failure('reference_unsupported'),
      );
      writer().updateAction(ImageGenerationAction.infill);
      expect(
        (draft.summary()['precise'] as List).single,
        containsPair('inactive_reason', 'inpainting_excludes_precise'),
      );
      await expectLater(
        edit('add_precise', {'path': 'image.png'}),
        failure('reference_unsupported'),
      );
    },
  );

  test(
    'library import, update and apply preserve preference and model compatibility',
    () async {
      writer().updateModel(ImageModels.animeDiffusionV45Full);
      final imported =
          (await useLibrary({
                'action': 'import',
                'path': 'image.png',
                'type': 'outfit',
                'strength': 4.2,
              }))['saved']
              as Map;
      final id = imported['id'];
      Future<Map> apply() async {
        final entry = await useLibrary({'action': 'read', 'id': id});
        return useLibrary({
          'action': 'apply',
          'id': id,
          'expected_entry_version': entry['entry_version'],
          'expected_draft_version': draft.summary()['draft_version'],
        });
      }

      await expectLater(apply(), failure('reference_unsupported'));
      writer().updateModel(ImageModels.animeDiffusionV5Curated);
      await apply();
      expect(read().preciseReferences.single.type, PreciseRefType.outfit);
      expect(read().preciseReferences.single.image, pixels);

      final entry = await useLibrary({'action': 'read', 'id': id});
      await useLibrary({
        'action': 'update',
        'id': id,
        'expected_entry_version': entry['entry_version'],
        'changes': {'type': 'character', 'preferSameOutfit': true},
      });
      await apply();
      expect(read().preciseReferences.last.preferSameOutfit, isTrue);
      expect(read().preciseReferences.last.type, PreciseRefType.character);
    },
  );
}

class _MemoryGenerationState extends VibeLibraryStorageService {
  String? value;

  @override
  Future<String?> loadGenerationStateJson() async => value;

  @override
  Future<void> saveGenerationStateJson(String stateJson) async {
    value = stateJson;
  }
}

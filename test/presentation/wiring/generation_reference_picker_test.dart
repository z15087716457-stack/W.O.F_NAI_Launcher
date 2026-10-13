import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_category_provider.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_picker.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import 'generation_data_wiring_test.dart' show DataGeneration;
import '../../helpers/studio_capture_fonts.dart';
import 'generation_reference_imports_test.dart' show ImportStorage;
import 'generation_backend_test.dart' show MemoryGenerationPlatform;
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_operations.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';

class PickerVibes extends VibeLibraryNotifier {
  PickerVibes(this.entries);
  final List<VibeLibraryEntry> entries;
  @override
  VibeLibraryState build() => VibeLibraryState(entries: entries);
  @override
  Future<void> initialize() async {}
  final used = <String>[];
  @override
  Future<VibeLibraryEntry?> recordUsage(String id) async {
    used.add(id);
    return entries.where((entry) => entry.id == id).firstOrNull;
  }
}

class PickerPrecise extends PreciseRefLibraryNotifier {
  PickerPrecise(this.entries);
  final List<PreciseRefLibraryEntry> entries;
  @override
  PreciseRefLibraryState build() => PreciseRefLibraryState(entries: entries);
  @override
  Future<void> initialize() async {}
}

class PickerCategories extends VibeLibraryCategoryNotifier {
  @override
  VibeLibraryCategoryState build() => const VibeLibraryCategoryState();
}

class PickerVibeStorage extends ImportStorage {
  PickerVibeStorage(this.libraryEntries);
  final List<VibeLibraryEntry> libraryEntries;
  @override
  Future<VibeLibraryEntry?> getEntry(String id) async =>
      libraryEntries.where((entry) => entry.id == id).firstOrNull;
  @override
  Future<Uint8List?> getDisplayThumbnail(String id) async =>
      img.encodePng(img.Image(width: 64, height: 64));
}

class PickerPreciseStorage extends PreciseRefLibraryStorageService {
  @override
  Future<Uint8List?> getDisplayThumbnail(String id) async =>
      img.encodePng(img.Image(width: 64, height: 64));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  late Directory directory;
  late ProviderContainer container;
  final vibes = <VibeLibraryEntry>[];
  final precise = <PreciseRefLibraryEntry>[];
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-picker-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    vibes.clear();
    precise.clear();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        generationPlatformProvider.overrideWithValue(
          MemoryGenerationPlatform(),
        ),
        vibeLibraryNotifierProvider.overrideWith(() => PickerVibes(vibes)),
        preciseRefLibraryNotifierProvider.overrideWith(
          () => PickerPrecise(precise),
        ),
        vibeLibraryCategoryNotifierProvider.overrideWith(PickerCategories.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          PickerVibeStorage(vibes),
        ),
        preciseRefLibraryStorageServiceProvider.overrideWithValue(
          PickerPreciseStorage(),
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateModel(ImageModels.animeDiffusionV45Full);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<RefsPicker> pump(WidgetTester tester, RefsKind kind) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: GenerationReferencePicker(kind: kind)),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.widget<RefsPicker>(find.byType(RefsPicker));
  }

  testWidgets('选择器显示完整库而非管理页筛选结果，旧编码类型安全回退', (tester) async {
    vibes.add(
      VibeLibraryEntry(
        id: 'legacy',
        name: 'legacy',
        vibeDisplayName: 'legacy',
        vibeEncoding: 'offline',
        sourceTypeIndex: 99,
        createdAt: DateTime(2026, 10, 12),
      ),
    );
    final picker = await pump(tester, RefsKind.vibe);
    expect(picker.data.entries.single.key, 'legacy');
    expect(picker.data.entries.single.source, RefsVibeSource.rawImage);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('精准库旧类型安全回退并保留真实强度和保真度', (tester) async {
    precise.add(
      PreciseRefLibraryEntry(
        id: 'precise',
        name: 'precise',
        imagePath: 'offline.png',
        typeIndex: 99,
        strength: .4,
        fidelity: .8,
        createdAt: DateTime(2026, 10, 12),
      ),
    );
    final picker = await pump(tester, RefsKind.precise);
    final entry = picker.data.entries.single;
    expect(entry.type, RefsPreciseType.both);
    expect(entry.strength, .4);
    expect(entry.fidelity, .8);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('从真实选择器追加、重复确认和替换保留参考实例与用户新强度', (tester) async {
    vibes.add(
      VibeLibraryEntry(
        id: 'library-vibe',
        name: 'library-vibe',
        vibeDisplayName: 'library-vibe',
        vibeEncoding: 'offline',
        encodingModel: ImageModels.animeDiffusionV45Full,
        sourceTypeIndex: 999,
        createdAt: DateTime(2026, 10, 12),
      ),
    );
    Future<void>? pending;
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => pending = GenerationOperations(
                  ref,
                  context,
                  () => context.mounted,
                ).library(GenDropTarget.vibe),
                child: const Text('open-picker'),
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> choose({bool replace = false}) async {
      await tester.tap(find.text('open-picker'));
      await tester.pumpAndSettle();
      final picker = tester.widget<RefsPicker>(find.byType(RefsPicker));
      picker.actions.onConfirm(['library-vibe'], replace: replace);
      await tester.pumpAndSettle();
      await tester.runAsync(() => pending!);
      await tester.pumpAndSettle();
    }

    await choose();
    var params = container.read(generationParamsNotifierProvider);
    expect(params.vibeReferencesV4, hasLength(1));
    expect(params.vibeReferencesV4.single.sourceType, VibeSourceType.rawImage);
    expect(
      params.vibeReferencesV4.single.encodingModel,
      ImageModels.animeDiffusionV45Full,
    );
    expect(params.vibeReferencesV4.single.vibeEncoding, 'offline');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateVibeReference(0, strength: .2);
    final original = container
        .read(generationParamsNotifierProvider)
        .vibeReferencesV4
        .single;
    await choose();
    params = container.read(generationParamsNotifierProvider);
    expect(params.vibeReferencesV4.single.strength, .2);
    expect(identical(params.vibeReferencesV4.single, original), isTrue);
    expect(
      (container.read(vibeLibraryNotifierProvider.notifier) as PickerVibes)
          .used,
      ['library-vibe'],
    );
    await choose(replace: true);
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .strength,
      .6,
    );
    expect(
      (container.read(generationPlatformProvider) as MemoryGenerationPlatform)
          .backups,
      hasLength(2),
    );
    expect(
      container.read(imageGenerationNotifierProvider).isGenerating,
      isFalse,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('Vibe 编码模型说明和模型友好短名不丢失', (tester) async {
    vibes.add(
      VibeLibraryEntry(
        id: 'old-model',
        name: 'old-model',
        vibeDisplayName: 'old-model',
        vibeEncoding: 'offline',
        encodingModel: ImageModels.animeDiffusionV4Full,
        createdAt: DateTime(2026, 10, 12),
      ),
    );
    final picker = await pump(tester, RefsKind.vibe);
    expect(picker.data.entries.single.encoding, RefsEncoding.unusable);
    expect(picker.data.entries.single.encodedFor, isNotNull);
    expect(picker.data.model.shortName, 'V4.5');
    await tester.pumpWidget(const SizedBox());
  });
}

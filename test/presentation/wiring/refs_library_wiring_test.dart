import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_category.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_category_provider.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_page.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';
import 'package:nai_launcher/presentation/utils/dropped_file_reader.dart';
import 'package:nai_launcher/presentation/wiring/refs_library_wiring.dart';
import 'package:nai_launcher/presentation/wiring/refs_picker_wiring.dart';
import 'package:nai_launcher/presentation/wiring/refs_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
);

class Settings extends LocalStorageService {
  final data = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      data[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    data[key] = value;
  }
}

class Library extends VibeLibraryNotifier {
  final List<VibeLibraryEntry> entries;
  final String? error;
  Library(this.entries, {this.error});
  @override
  VibeLibraryState build() => VibeLibraryState(entries: entries, error: error);
  @override
  Future<void> initialize() async {}
}

class Categories extends VibeLibraryCategoryNotifier {
  @override
  VibeLibraryCategoryState build() => VibeLibraryCategoryState(
    categories: [
      VibeLibraryCategory(
        id: 'child',
        name: 'child',
        parentId: 'root',
        createdAt: DateTime(2026),
      ),
      VibeLibraryCategory(id: 'root', name: 'root', createdAt: DateTime(2026)),
    ],
  );
}

class Storage extends VibeLibraryStorageService {
  final List<VibeLibraryEntry> entries;
  final waits = <String, Completer<void>>{};
  var fullReads = 0;
  Storage(this.entries);
  @override
  Future<VibeLibraryEntry?> getEntrySnapshot(String id) async =>
      entries.where((e) => e.id == id).firstOrNull;
  @override
  Future<VibeLibraryEntry?> getEntry(String id) async {
    fullReads++;
    await waits[id]?.future;
    return getEntrySnapshot(id);
  }

  @override
  Future<Uint8List?> getDisplayThumbnail(String id) async => png;
}

class Platform extends RefsPlatform {
  final errors = <Object>[];
  @override
  Future<String> libraryFolder() async => 'temporary-library';
  @override
  void error(BuildContext context, Object error) {
    errors.add(error);
  }

  @override
  Future<List<DroppedFileData>> pickFiles(
    RefsKind kind,
    RefsImportSource source,
  ) async => [DroppedFileData(fileName: 'new.png', bytes: png)];
}

void main() {
  late Settings settings;
  late List<VibeLibraryEntry> entries;
  late Storage storage;
  late Platform platform;
  late ProviderContainer container;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    settings = Settings();
    entries = [
      for (final id in ['a', 'b'])
        VibeLibraryEntry(
          id: id,
          name: id,
          vibeDisplayName: id,
          vibeEncoding: id,
          encodingModel: ImageModels.animeDiffusionV45Full,
          createdAt: DateTime(2026),
          isFavorite: id == 'a',
          thumbnail: png,
        ),
    ];
    storage = Storage(entries);
    platform = Platform();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(settings),
        vibeLibraryNotifierProvider.overrideWith(() => Library(entries)),
        vibeLibraryCategoryNotifierProvider.overrideWith(Categories.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(storage),
        refsPlatformProvider.overrideWithValue(platform),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> mount(
    WidgetTester tester, {
    Widget child = const VibeLibraryWiring(),
  }) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  RefsLibraryPage page(WidgetTester tester) =>
      tester.widget(find.byType(RefsLibraryPage));

  testWidgets('whole-library counts and category preorder survive filtering', (
    tester,
  ) async {
    await mount(tester);
    expect(page(tester).data.counts.all, 2);
    expect(page(tester).data.categories.map((c) => c.id), ['root', 'child']);
    page(
      tester,
    ).actions.onFilterChanged(const RefsFilter(view: RefsView.favorites));
    await tester.pumpAndSettle();
    expect(page(tester).data.entries.single.key, 'a');
    expect(page(tester).data.counts.all, 2);
    expect(page(tester).data.counts.favorites, 1);
    expect(platform.errors, isEmpty);
  });

  testWidgets('card size and panel preferences restore after remount', (
    tester,
  ) async {
    await mount(tester);
    page(tester).actions.onCardSizeChanged(RefsCardSize.large);
    page(tester).actions.onSidebarChanged(false);
    page(tester).actions.onInspectorChanged(false);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await mount(tester);
    expect(page(tester).data.cardSize, RefsCardSize.large);
    expect(page(tester).data.sidebarOpen, isFalse);
    expect(page(tester).data.inspectorOpen, isFalse);
  });

  testWidgets('older detail load cannot replace a newer selection', (
    tester,
  ) async {
    await mount(tester);
    storage.waits['a'] = Completer<void>();
    page(tester).actions.onSelect('a');
    await tester.pump();
    expect(page(tester).data.detail!.loading, isTrue);
    page(tester).actions.onSelect('b');
    await tester.pumpAndSettle();
    expect(page(tester).data.detail!.key, 'b');
    storage.waits['a']!.complete();
    await tester.pumpAndSettle();
    expect(page(tester).data.selectedKey, 'b');
    expect(page(tester).data.detail!.key, 'b');
  });

  testWidgets(
    'file import opens a cancellable draft without importing automatically',
    (tester) async {
      await mount(tester);
      await tester.runAsync(() async {
        page(tester).actions.onImport(RefsImportSource.files);
        for (var i = 0; i < 100 && platform.errors.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          if (page(tester).data.importDraft != null) break;
        }
      });
      await tester.pumpAndSettle();
      expect(platform.errors, isEmpty);
      expect(
        page(tester).data.importDraft!.rows.single.kind,
        RefsImportKind.image,
      );
      page(tester).actions.onImportCancel();
      await tester.pumpAndSettle();
      expect(page(tester).data.importDraft, isNull);
      expect(entries, hasLength(2));
    },
  );

  testWidgets(
    'repeated picker confirmation cannot pop the generation page underneath',
    (tester) async {
      RefsPickerSelection? selection;
      await mount(
        tester,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async =>
                        selection = await RefsPickerWiring.show(
                          context,
                          kind: RefsKind.vibe,
                        ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
            child: const Text('enter'),
          ),
        ),
      );
      await tester.tap(find.text('enter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final picker = tester.widget<RefsPicker>(find.byType(RefsPicker));
      picker.actions.onConfirm(['a'], replace: true);
      picker.actions.onConfirm(['b'], replace: false);
      picker.actions.onClose();
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      expect(selection!.keys, ['a']);
      expect(selection!.replace, isTrue);
    },
  );

  testWidgets(
    'picker returns its append/replace policy without touching the draft',
    (tester) async {
      RefsPickerSelection? selection;
      await mount(
        tester,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => selection = await RefsPickerWiring.show(
              context,
              kind: RefsKind.vibe,
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final picker = tester.widget<RefsPicker>(find.byType(RefsPicker));
      expect(picker.data.entries, hasLength(2));
      expect(picker.data.categories.map((c) => c.id), ['root', 'child']);
      picker.actions.onConfirm(['a'], replace: true);
      await tester.pumpAndSettle();
      expect(find.byType(RefsPicker), findsNothing);
      expect(selection!.keys, ['a']);
      expect(selection!.replace, isTrue);
      expect(storage.fullReads, 0);
      expect(entries.every((entry) => entry.usedCount == 0), isTrue);
    },
  );
}

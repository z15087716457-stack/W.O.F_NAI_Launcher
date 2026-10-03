import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_organizer_popover.dart';

import '../../../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/core/utils/app_language.dart';

class _OrganizerNotifier extends PromptBlockLibraryNotifier {
  _OrganizerNotifier(this.initial);

  final PromptBlockLibraryState initial;
  List<String>? folderOrder;
  List<String>? collectionOrder;

  @override
  Future<PromptBlockLibraryState> build() async => initial;

  @override
  Future<void> reorderFolders(String? parentId, List<String> orderedIds) async {
    folderOrder = List.of(orderedIds);
    final current = state.requireValue;
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks,
        folders: [
          for (final folder in current.folders)
            folder.parentId == parentId
                ? folder.copyWith(sortOrder: orderedIds.indexOf(folder.id))
                : folder,
        ],
        collections: current.collections,
      ),
    );
  }

  @override
  Future<void> reorderCollections(
    String? parentId,
    List<String> orderedIds,
  ) async {
    collectionOrder = List.of(orderedIds);
    final current = state.requireValue;
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: current.blocks,
        folders: current.folders,
        collections: [
          for (final node in current.collections)
            node.parentId == parentId
                ? node.copyWith(sortOrder: orderedIds.indexOf(node.id))
                : node,
        ],
      ),
    );
  }
}

void main() {
  Future<void> openPopover(
    WidgetTester tester,
    _OrganizerNotifier notifier,
    BlockOrganizerPage page, {
    Locale? locale,
  }) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          theme: locale == null
              ? null
              : AppTheme.getTheme(AppStyle.geist, Brightness.light),
          locale: locale,
          localizationsDelegates: locale == null
              ? null
              : AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showBlockOrganizerPopover(
                  context,
                  blockIds: const ['block'],
                  anchor: const Offset(40, 40),
                  page: page,
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
  }

  Future<void> dragHandle(
    WidgetTester tester,
    String kind,
    String from,
    String to,
  ) async {
    final handle = find.byKey(ValueKey('organizer-reorder-handle-$kind-$from'));
    final target = find.byKey(ValueKey('organizer-reorder-target-$kind-$to'));
    final gesture = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('folder dots click manages, drag reorders siblings', (
    tester,
  ) async {
    final notifier = _OrganizerNotifier(
      PromptBlockLibraryState(
        blocks: const [],
        folders: [
          PromptBlockFolder.create(id: 'f1', name: '甲', sortOrder: 0),
          PromptBlockFolder.create(id: 'f2', name: '乙', sortOrder: 1),
          PromptBlockFolder.create(id: 'f3', name: '丙', sortOrder: 2),
        ],
      ),
    );
    await openPopover(tester, notifier, BlockOrganizerPage.folders);

    await tester.tap(
      find.byKey(const ValueKey('organizer-reorder-handle-folder-f1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('重命名'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('上移'), findsNothing);
    expect(find.text('下移'), findsNothing);
    await tester.tapAt(const Offset(700, 700));
    await tester.pumpAndSettle();

    await dragHandle(tester, 'folder', 'f1', 'f3');
    expect(notifier.folderOrder, ['f2', 'f3', 'f1']);
    expect(find.text('重命名'), findsNothing);
  });

  testWidgets('collection dots reorder mixed sibling nodes', (tester) async {
    final notifier = _OrganizerNotifier(
      PromptBlockLibraryState(
        blocks: const [],
        folders: const [],
        collections: [
          PromptBlockCollection.create(id: 'c1', name: '收藏集甲', sortOrder: 0),
          PromptBlockCollection.create(
            id: 'c2',
            name: '收藏文件夹',
            isFolder: true,
            sortOrder: 1,
          ),
          PromptBlockCollection.create(id: 'c3', name: '收藏集丙', sortOrder: 2),
        ],
      ),
    );
    await openPopover(tester, notifier, BlockOrganizerPage.favorites);

    await dragHandle(tester, 'collection', 'c3', 'c1');
    expect(notifier.collectionOrder, ['c3', 'c1', 'c2']);
    expect(notifier.folderOrder, isNull);
  });

  testWidgets('dragging onto a different level does not reorder folders', (
    tester,
  ) async {
    final notifier = _OrganizerNotifier(
      PromptBlockLibraryState(
        blocks: const [],
        folders: [
          PromptBlockFolder.create(id: 'parent', name: '父级', sortOrder: 0),
          PromptBlockFolder.create(id: 'child', name: '子级', parentId: 'parent'),
          PromptBlockFolder.create(id: 'other', name: '同级', sortOrder: 1),
        ],
      ),
    );
    await openPopover(tester, notifier, BlockOrganizerPage.folders);
    await tester.tap(
      find.descendant(
        of: find.byKey(
          const ValueKey('organizer-reorder-target-folder-parent'),
        ),
        matching: find.byTooltip('展开'),
      ),
    );
    await tester.pump();

    await dragHandle(tester, 'folder', 'other', 'child');
    expect(notifier.folderOrder, isNull);
  });

  for (final code in ['en', 'ja', 'zh_TW']) {
    testWidgets('organizer pages follow the $code interface', (tester) async {
      // Declared last: real fonts stay loaded for the rest of the file.
      await tester.runAsync(loadStudioCaptureFonts);
      final locale = AppLanguage.fromStorage(code).locale;
      final l10n = lookupAppLocalizations(locale);
      for (final (page, title) in [
        (BlockOrganizerPage.favorites, l10n.blockOrganizer_titleFavorites),
        (BlockOrganizerPage.folders, l10n.blockOrganizer_titleFolders),
        (BlockOrganizerPage.tags, l10n.promptBlockLibrary_addTag),
      ]) {
        final notifier = _OrganizerNotifier(
          PromptBlockLibraryState(
            blocks: const [],
            folders: [
              PromptBlockFolder.create(id: 'f1', name: 'Alpha', sortOrder: 0),
            ],
          ),
        );
        await openPopover(tester, notifier, page, locale: locale);
        expect(find.text(title), findsOneWidget);
        expect(find.text(l10n.blockOrganizer_itemCount(1)), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(880, 780));
        await tester.pumpAndSettle();
      }
    });
  }
}

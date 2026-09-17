import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/prompt_block_library/widgets/prompt_block_folder_tree.dart';

void main() {
  PromptBlock makeBlock(String id, {String? folderId, bool fav = false}) {
    return PromptBlock.create(
      id: id,
      title: id,
      content: 'c',
      folderId: folderId,
      isFavorite: fav,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  PromptBlockFolder makeFolder(String id, {String? parentId}) {
    return PromptBlockFolder.create(
      id: id,
      name: '夹$id',
      parentId: parentId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  PromptBlockCollection makeCollection(
    String id, {
    String? parentId,
    bool isFolder = false,
    List<String> blockIds = const [],
  }) {
    return PromptBlockCollection.create(
      id: id,
      name: '集$id',
      parentId: parentId,
      isFolder: isFolder,
      blockIds: blockIds,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  Widget wrap(
    Widget child, {
    double height = 700,
  }) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SizedBox(height: height, child: child)),
    );
  }

  testWidgets('two panes render: fixed rows + collections + folders', (
    tester,
  ) async {
    var favoritesTapped = false;
    String? selectedCollection;
    String? selectedFolder;

    await tester.pumpWidget(
      wrap(
        PromptBlockFolderTree(
          blocks: [makeBlock('b1', fav: true)],
          folders: [makeFolder('f1')],
          collections: [
            makeCollection('col1', blockIds: ['b1']),
            makeCollection('cf1', isFolder: true),
          ],
          allSelected: true,
          rootSelected: false,
          selectedFolderId: null,
          onSelectAll: () {},
          onSelectRoot: () {},
          onSelectFavorites: () => favoritesTapped = true,
          onSelectFolder: (id) => selectedFolder = id,
          onSelectCollection: (id) => selectedCollection = id,
          onCreateFolder: (_) {},
          onRenameFolder: (_) {},
          onMoveFolderToRoot: (_) {},
          onDeleteFolder: (_) {},
          onReorderFolders: (_, __) {},
        ),
      ),
    );
    await tester.pump();

    // 上区固定三行
    expect(find.text('全部块'), findsOneWidget);
    expect(find.text('根目录 / 未分类'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    // 收藏集树（含收藏文件夹）
    expect(find.text('集col1'), findsOneWidget);
    expect(find.text('集cf1'), findsOneWidget);
    // 下区文件夹树
    expect(find.text('夹f1'), findsOneWidget);
    // 拖拽分割手柄
    expect(
      find.byKey(const Key('prompt-block-sidebar-resize-handle')),
      findsOneWidget,
    );

    await tester.tap(find.text('收藏'));
    expect(favoritesTapped, isTrue);
    await tester.tap(find.text('集col1'));
    expect(selectedCollection, 'col1');
    await tester.tap(find.text('夹f1'));
    expect(selectedFolder, 'f1');
  });

  testWidgets('empty collections show hint inside top pane', (tester) async {
    await tester.pumpWidget(
      wrap(
        PromptBlockFolderTree(
          blocks: const [],
          folders: const [],
          allSelected: true,
          rootSelected: false,
          selectedFolderId: null,
          onSelectAll: () {},
          onSelectRoot: () {},
          onSelectFavorites: () {},
          onSelectFolder: (_) {},
          onCreateFolder: (_) {},
          onRenameFolder: (_) {},
          onMoveFolderToRoot: (_) {},
          onDeleteFolder: (_) {},
          onReorderFolders: (_, __) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('还没有收藏集'), findsOneWidget);
    expect(find.textContaining('还没有文件夹'), findsOneWidget);

    // 提示在上区分区内垂直居中，而不是顶格贴着「收藏」行
    final paneTop = tester.getBottomLeft(find.text('收藏')).dy;
    final paneBottom = tester
        .getTopLeft(
          find.byKey(const Key('prompt-block-sidebar-resize-handle')),
        )
        .dy;
    final hintCenter = tester
        .getCenter(find.textContaining('还没有收藏集'))
        .dy;
    expect(
      hintCenter,
      moreOrLessEquals((paneTop + paneBottom) / 2, epsilon: 10),
    );
  });

  testWidgets('resize handle can be pushed up near the hint row', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        height: 600,
        PromptBlockFolderTree(
          blocks: const [],
          folders: [makeFolder('f1'), makeFolder('f2')],
          collections: const [],
          allSelected: true,
          rootSelected: false,
          selectedFolderId: null,
          onSelectAll: () {},
          onSelectRoot: () {},
          onSelectFavorites: () {},
          onSelectFolder: (_) {},
          onCreateFolder: (_) {},
          onRenameFolder: (_) {},
          onMoveFolderToRoot: (_) {},
          onDeleteFolder: (_) {},
          onReorderFolders: (_, __) {},
        ),
      ),
    );
    await tester.pump();

    final handle = find.byKey(const Key('prompt-block-sidebar-resize-handle'));
    expect(handle, findsOneWidget);
    await tester.drag(handle, const Offset(0, -400));
    await tester.pump();

    final handleTop = tester.getTopLeft(handle).dy;
    // 固定三行（116）下方 + 上区最小一行（44）+ 手柄本身（10）余量；
    // 即能推到提示行正下方，但不会越过固定行区。
    expect(handleTop, greaterThanOrEqualTo(116));
    expect(handleTop, lessThanOrEqualTo(116 + 44 + 10 + 2));
  });

  testWidgets('collection row + button opens create menu', (tester) async {
    String? createdParent;
    bool? createdIsFolder;

    await tester.pumpWidget(
      wrap(
        PromptBlockFolderTree(
          blocks: const [],
          folders: const [],
          collections: const [],
          allSelected: true,
          rootSelected: false,
          selectedFolderId: null,
          onSelectAll: () {},
          onSelectRoot: () {},
          onSelectFavorites: () {},
          onSelectFolder: (_) {},
          onCreateFolder: (_) {},
          onRenameFolder: (_) {},
          onMoveFolderToRoot: (_) {},
          onDeleteFolder: (_) {},
          onReorderFolders: (_, __) {},
          onCreateCollection: (parentId, isFolder) {
            createdParent = parentId;
            createdIsFolder = isFolder;
          },
        ),
      ),
    );
    await tester.pump();

    // 「收藏」行尾列 + 钮 → 菜单
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('新建收藏集'), findsOneWidget);
    expect(find.text('新建收藏文件夹'), findsOneWidget);

    await tester.tap(find.text('新建收藏集'));
    await tester.pump();
    expect(createdParent, isNull);
    expect(createdIsFolder, isFalse);
  });
}

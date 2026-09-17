import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/block_library_panel.dart';

class _FakePromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakePromptBlockLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

class _TestLocalStorageService extends LocalStorageService {
  final values = <String, Object?>{};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] as T?) ?? defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

void main() {
  PromptBlock makeBlock(int index) => PromptBlock.create(
    id: 'block-$index',
    title: '块 $index',
    content: 'content $index',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Widget buildPanel(
    List<PromptBlock> blocks, {
    List<PromptBlockFolder> folders = const [],
    LocalStorageService? storage,
  }) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => storage ?? _TestLocalStorageService(),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakePromptBlockLibraryNotifier(
            PromptBlockLibraryState(blocks: blocks, folders: folders),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(width: 320, height: 800, child: BlockLibraryPanel()),
        ),
      ),
    );
  }

  Future<void> pumpPanel(
    WidgetTester tester,
    List<PromptBlock> blocks, {
    List<PromptBlockFolder> folders = const [],
    LocalStorageService? storage,
  }) async {
    await tester.pumpWidget(
      buildPanel(blocks, folders: folders, storage: storage),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  double blockAreaHeight(WidgetTester tester) => tester
      .getSize(find.byKey(const Key('block-library-panel-block-area')))
      .height;

  testWidgets('few blocks keep the upper area compact', (tester) async {
    await pumpPanel(tester, [makeBlock(1), makeBlock(2)]);

    final blocksHeight = tester
        .getSize(find.byKey(const Key('block-library-panel-block-area')))
        .height;
    final foldersHeight = tester
        .getSize(find.byKey(const Key('block-library-panel-folder-area')))
        .height;

    expect(blocksHeight, lessThan(160));
    expect(blocksHeight, lessThan(foldersHeight));
    expect(find.byKey(const Key('block-library-panel-blocks')), findsOneWidget);
  });

  testWidgets('many blocks still get a scrollable upper area', (tester) async {
    await pumpPanel(tester, [for (var i = 0; i < 80; i++) makeBlock(i)]);

    final blocksHeight = tester
        .getSize(find.byKey(const Key('block-library-panel-block-area')))
        .height;

    // 默认估算封顶 60% 可用高（约 251），仍足够高且内部可滚动
    expect(blocksHeight, greaterThan(200));
    expect(find.byKey(const Key('block-library-panel-blocks')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical split handle still resizes the block area', (
    tester,
  ) async {
    await pumpPanel(tester, [makeBlock(1), makeBlock(2)]);

    final before = tester
        .getSize(find.byKey(const Key('block-library-panel-block-area')))
        .height;
    await tester.drag(
      find.byKey(const Key('block-library-panel-split-handle')),
      const Offset(0, 100),
    );
    await tester.pump();

    final after = tester
        .getSize(find.byKey(const Key('block-library-panel-block-area')))
        .height;
    expect(after, greaterThan(before));
  });

  testWidgets('undragged split height locks after first estimate (BUG-4)', (
    tester,
  ) async {
    final folderA = PromptBlockFolder.create(id: 'folder-a', name: 'A');
    final folderB = PromptBlockFolder.create(id: 'folder-b', name: 'B');
    final blocks = [
      makeBlock(1).copyWith(folderId: 'folder-a'),
      makeBlock(2).copyWith(folderId: 'folder-a'),
      makeBlock(3).copyWith(folderId: 'folder-a'),
    ];
    await pumpPanel(tester, blocks, folders: [folderA, folderB]);

    final locked = blockAreaHeight(tester);
    expect(locked, greaterThan(0));

    // 切到空文件夹（旧逻辑会压到 ≤96 → BUG-4 跳变）。
    await tester.tap(
      find.byKey(const Key('prompt-block-folder-item-folder-b')),
    );
    await tester.pump();
    expect(blockAreaHeight(tester), locked, reason: '切空文件夹不得跳变');

    // 切回多块文件夹同样不得重算。
    await tester.tap(
      find.byKey(const Key('prompt-block-folder-item-folder-a')),
    );
    await tester.pump();
    expect(blockAreaHeight(tester), locked, reason: '切回多块文件夹不得跳变');

    // 搜索过滤同样不得触发重算。
    await tester.enterText(
      find.byKey(const Key('block-library-panel-search')),
      'zzz',
    );
    await tester.pump();
    expect(blockAreaHeight(tester), locked, reason: '搜索过滤不得跳变');
    await tester.enterText(
      find.byKey(const Key('block-library-panel-search')),
      '',
    );
    await tester.pump();
    expect(blockAreaHeight(tester), locked);

    // 拖拽后仍走手动值（旧行为不变）。
    await tester.drag(
      find.byKey(const Key('block-library-panel-split-handle')),
      const Offset(0, 100),
    );
    await tester.pump();
    expect(blockAreaHeight(tester), greaterThan(locked));
  });

  testWidgets('selecting a folder shows subtree blocks, not just direct', (
    tester,
  ) async {
    final parent = PromptBlockFolder.create(id: 'pf', name: '父夹');
    final child = PromptBlockFolder.create(
      id: 'cf',
      name: '子夹',
      parentId: 'pf',
    );
    // 父夹零直属块，块全在子夹里
    final blocks = [makeBlock(1).copyWith(folderId: 'cf')];
    await pumpPanel(tester, blocks, folders: [parent, child]);

    await tester.tap(find.byKey(const Key('prompt-block-folder-item-pf')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 与管理页同口径：文件夹范围 = 子树并集，而不是「此文件夹为空」
    expect(find.text('块 1'), findsOneWidget);
    expect(find.textContaining('此文件夹为空'), findsNothing);
  });

  testWidgets('many blocks cap the default upper area so folders stay usable', (
    tester,
  ) async {
    // 300 块估算远超可用高：默认应封顶 ~60%，文件夹区不被挤没
    await pumpPanel(tester, [for (var i = 0; i < 300; i++) makeBlock(i)]);

    final blocksHeight = blockAreaHeight(tester);
    final foldersHeight = tester
        .getSize(find.byKey(const Key('block-library-panel-folder-area')))
        .height;
    final available = blocksHeight + foldersHeight;

    expect(blocksHeight, lessThanOrEqualTo(available * 0.6 + 0.5));
    expect(foldersHeight, greaterThan(0));
  });

  testWidgets('dragged split ratio persists across panel rebuilds', (
    tester,
  ) async {
    final storage = _TestLocalStorageService();
    await pumpPanel(tester, [makeBlock(1), makeBlock(2)], storage: storage);

    await tester.drag(
      find.byKey(const Key('block-library-panel-split-handle')),
      const Offset(0, 100),
    );
    await tester.pump();
    final dragged = blockAreaHeight(tester);
    expect(dragged, greaterThan(160));

    // 页面切换/重开面板 = 新 State；应从持久化比例恢复而不是重新估算
    await pumpPanel(tester, [makeBlock(1), makeBlock(2)], storage: storage);
    expect(blockAreaHeight(tester), closeTo(dragged, 1.0));
  });
}

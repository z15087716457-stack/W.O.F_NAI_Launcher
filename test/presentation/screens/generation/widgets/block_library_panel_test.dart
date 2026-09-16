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
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async {}
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
  }) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
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
  }) async {
    await tester.pumpWidget(buildPanel(blocks, folders: folders));
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

    expect(blocksHeight, greaterThan(300));
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
}

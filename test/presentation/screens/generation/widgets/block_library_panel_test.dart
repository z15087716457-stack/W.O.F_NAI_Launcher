import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
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

  Widget buildPanel(List<PromptBlock> blocks) {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakePromptBlockLibraryNotifier(
            PromptBlockLibraryState(blocks: blocks, folders: const []),
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

  Future<void> pumpPanel(WidgetTester tester, List<PromptBlock> blocks) async {
    await tester.pumpWidget(buildPanel(blocks));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_block_composer.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_workspace_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_chip.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drawer.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_text_segment.dart';
import 'package:nai_launcher/presentation/widgets/prompt/nai_syntax_controller.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';

void main() {
  testWidgets(
    'drawer keeps root direct children, enters folders, and searches',
    (tester) async {
      final folder = _folder('folder', 'Folder');
      final root = _block('root', 'Root block', 'root body');
      final nested = _block(
        'nested',
        'Nested block',
        'nested body',
        folderId: folder.id,
      );

      await tester.pumpWidget(
        _app(
          PromptBlockDrawer(compact: true, onInsertBlock: (_) {}),
          libraryState: PromptBlockLibraryState(
            blocks: [root, nested],
            folders: [folder],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Root block'), findsOneWidget);
      expect(find.text('Nested block'), findsNothing);

      await tester.tap(find.byKey(const Key('prompt-block-folder-folder')));
      await tester.pump();
      expect(find.text('Nested block'), findsOneWidget);
      expect(find.text('Root block'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('prompt-block-drawer-search')),
        'root body',
      );
      await tester.pump();
      expect(find.text('Root block'), findsOneWidget);
      expect(find.text('Nested block'), findsNothing);
    },
  );

  testWidgets('wide drawer Draggable carries only the block ID', (
    tester,
  ) async {
    final block = _block('only-id', 'Only title', 'private body');
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          height: 480,
          child: PromptBlockDrawer(compact: false, onInsertBlock: (_) {}),
        ),
        libraryState: PromptBlockLibraryState(
          blocks: [block],
          folders: const [],
        ),
      ),
    );
    await tester.pump();

    final draggable = tester.widget<Draggable<PromptBlockDragData>>(
      find.byKey(const Key('prompt-block-draggable-only-id')),
    );
    expect(draggable.data!.blockId, 'only-id');
    expect(draggable.data, isNot(isA<PromptBlock>()));
  });

  testWidgets(
    'wide editor starts with a side tab and toggles its overlay drawer',
    (tester) async {
      final originalSize = tester.view.physicalSize;
      final originalDevicePixelRatio = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalDevicePixelRatio;
      });
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 960,
            height: 360,
            child: PromptBlockEditor(
              lane: PromptBlockLane.positive,
              config: UnifiedPromptConfig(
                enableAutocomplete: false,
                enableSyntaxHighlight: false,
                enableAutoFormat: false,
                enableRegexReplace: false,
              ),
            ),
          ),
          libraryState: PromptBlockLibraryState(blocks: [], folders: []),
        ),
      );
      await tester.pump();

      expect(find.byType(PromptBlockDrawer), findsNothing);
      expect(find.byKey(const Key('prompt-block-open-drawer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('prompt-block-open-drawer')));
      await tester.pump();
      expect(
        find.byKey(const Key('prompt-block-drawer-overlay')),
        findsOneWidget,
      );
      expect(find.byType(PromptBlockDrawer), findsOneWidget);

      await tester.tap(find.byKey(const Key('prompt-block-drawer-close')));
      await tester.pump();
      expect(
        find.byKey(const Key('prompt-block-drawer-overlay')),
        findsNothing,
      );
      expect(find.byType(PromptBlockDrawer), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('500px editor keeps a modal side tab without a resident drawer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 500,
          height: 360,
          child: PromptBlockEditor(
            lane: PromptBlockLane.positive,
            config: UnifiedPromptConfig(
              enableAutocomplete: false,
              enableSyntaxHighlight: false,
              enableAutoFormat: false,
              enableRegexReplace: false,
            ),
          ),
        ),
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      ),
    );
    await tester.pump();

    final tab = tester.getRect(
      find.byKey(const Key('prompt-block-open-drawer')),
    );
    final textField = tester.getRect(find.byType(TextField).first);
    expect(tab.left, greaterThanOrEqualTo(textField.right - 1));
    expect(find.byType(PromptBlockDrawer), findsNothing);

    await tester.tap(find.byKey(const Key('prompt-block-open-drawer')));
    await tester.pump();
    expect(find.byType(PromptBlockDrawer), findsOneWidget);
    expect(find.byKey(const Key('prompt-block-drawer-overlay')), findsNothing);

    await tester.tap(find.byKey(const Key('prompt-block-drawer-close')));
    await tester.pump();
    expect(find.byType(PromptBlockDrawer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer uses the localized fallback for an empty English title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PromptBlockDrawer(compact: true, onInsertBlock: (_) {}),
        libraryState: PromptBlockLibraryState(
          blocks: [_block('empty-title', '  ', 'body')],
          folders: const [],
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();

    expect(find.text('Untitled block'), findsOneWidget);
    expect(find.text('未命名块'), findsNothing);
  });

  testWidgets(
    'clicking a block inserts at the active caret and preserves text segments',
    (tester) async {
      final block = _block('insert', 'Insert block', 'BLOCK');
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 700,
            height: 400,
            child: PromptBlockEditor(
              lane: PromptBlockLane.positive,
              config: UnifiedPromptConfig(
                enableAutocomplete: false,
                enableSyntaxHighlight: false,
                enableAutoFormat: false,
                enableRegexReplace: false,
              ),
            ),
          ),
          libraryState: PromptBlockLibraryState(
            blocks: [block],
            folders: const [],
          ),
        ),
      );
      await tester.pump();

      final field = find.byType(TextField).first;
      await tester.tap(field);
      await tester.enterText(field, 'AB');
      await tester.pump();
      await tester.tap(find.byKey(const Key('prompt-block-open-drawer')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byType(PromptBlockDrawer), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('prompt-block-drawer-block-insert')),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PromptBlockEditor)),
      );
      final workspace = container.read(promptBlockWorkspaceNotifierProvider);
      final document = workspace.positiveDocument;
      expect(
        container
            .read(promptBlockWorkspaceNotifierProvider.notifier)
            .plainTextFor(PromptBlockLane.positive),
        'ABBLOCK',
      );
      expect(document.segments, hasLength(3));
      expect(document.segments[0], isA<TextSegment>());
      expect(document.segments[1], isA<BlockSegment>());
      expect(document.segments[2], isA<TextSegment>());
    },
  );

  testWidgets('programmatic controller writes sync the matching text segment', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 700,
          height: 420,
          child: PromptBlockEditor(
            lane: PromptBlockLane.positive,
            config: UnifiedPromptConfig(
              enableAutocomplete: false,
              enableSyntaxHighlight: false,
              enableAutoFormat: false,
              enableRegexReplace: false,
            ),
          ),
        ),
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PromptBlockEditor)),
    );
    final notifier = container.read(
      promptBlockWorkspaceNotifierProvider.notifier,
    );
    notifier.replaceDocument(
      PromptBlockLane.positive,
      PromptBlockDocument(
        documentId: 'programmatic-doc',
        segments: const [
          TextSegment(id: 'text-a', text: 'A'),
          TextSegment(id: 'text-b', text: 'B'),
        ],
        updatedAt: DateTime(2026, 8, 30),
      ),
    );
    await tester.pump();

    final editables = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    final firstController = editables
        .singleWhere((editable) => editable.controller.text == 'A')
        .controller;
    final secondController = editables
        .singleWhere((editable) => editable.controller.text == 'B')
        .controller;
    expect(firstController, isA<NaiSyntaxController>());
    expect(secondController, isA<NaiSyntaxController>());

    firstController.text = 'A-programmatic';
    await tester.pump();
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'A-programmaticB');
    expect(
      container
          .read(promptBlockWorkspaceNotifierProvider)
          .positiveDocument
          .segments
          .map((segment) => segment.id),
      ['text-a', 'text-b'],
    );
    expect(secondController.text, 'B');

    secondController.text = 'B-programmatic';
    await tester.pump();
    expect(
      notifier.plainTextFor(PromptBlockLane.positive),
      'A-programmaticB-programmatic',
    );
  });

  testWidgets(
    'chip menu supports preview, toggle, expand, and delete callbacks',
    (tester) async {
      var toggled = false;
      var expanded = false;
      var deleted = false;
      const segment = BlockSegment(
        id: 'segment',
        titleSnapshot: 'Snapshot title',
        colorSnapshot: '#FF123456',
        contentSnapshot: 'snapshot body',
      );

      await tester.pumpWidget(
        _app(
          PromptBlockChip(
            segment: segment,
            onToggleEnabled: () => toggled = true,
            onExpand: () => expanded = true,
            onDelete: () => deleted = true,
          ),
          libraryState: PromptBlockLibraryState(blocks: [], folders: []),
        ),
      );

      await tester.tap(find.byKey(const Key('prompt-block-chip-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('预览正文'));
      await tester.pump();
      expect(find.byType(SelectableText), findsOneWidget);
      expect(find.text('snapshot body'), findsOneWidget);
      await tester.tap(find.text('关闭'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('prompt-block-chip-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('禁用块'));
      await tester.pump();
      expect(toggled, isTrue);

      await tester.tap(find.byKey(const Key('prompt-block-chip-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('展开'));
      await tester.pump();
      expect(expanded, isTrue);

      await tester.tap(find.byKey(const Key('prompt-block-chip-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pump();
      expect(deleted, isTrue);
    },
  );

  testWidgets('only the active text segment enables the Prompt Assistant', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 760,
          height: 420,
          child: PromptBlockEditor(
            lane: PromptBlockLane.positive,
            config: UnifiedPromptConfig(
              enableAutocomplete: false,
              enableSyntaxHighlight: false,
              enableAutoFormat: false,
              enableRegexReplace: false,
            ),
          ),
        ),
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PromptBlockEditor)),
    );
    container
        .read(promptBlockWorkspaceNotifierProvider.notifier)
        .replaceDocument(
          PromptBlockLane.positive,
          PromptBlockDocument(
            documentId: 'assistant-doc',
            segments: const [
              TextSegment(id: 'text-a', text: 'A'),
              TextSegment(id: 'text-b', text: 'B'),
            ],
            updatedAt: DateTime(2026, 8, 30),
          ),
        );
    await tester.pump();

    List<UnifiedPromptInput> inputs() => tester
        .widgetList<UnifiedPromptInput>(find.byType(UnifiedPromptInput))
        .toList();
    expect(inputs().where((input) => input.enableAssistant), hasLength(1));
    expect(inputs().where((input) => !input.enableAssistant), hasLength(1));

    await tester.tap(find.byType(TextField).at(1));
    await tester.pump();
    expect(inputs().where((input) => input.enableAssistant), hasLength(1));
    expect(inputs().where((input) => !input.enableAssistant), hasLength(1));
  });

  testWidgets(
    'workspace lanes stay isolated and reorder uses complete stable IDs',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 760,
            height: 360,
            child: PromptBlockEditor(
              lane: PromptBlockLane.positive,
              config: UnifiedPromptConfig(
                enableAutocomplete: false,
                enableSyntaxHighlight: false,
                enableAutoFormat: false,
                enableRegexReplace: false,
              ),
            ),
          ),
          libraryState: PromptBlockLibraryState(blocks: [], folders: []),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PromptBlockEditor)),
      );
      final notifier = container.read(
        promptBlockWorkspaceNotifierProvider.notifier,
      );
      notifier.replaceDocument(
        PromptBlockLane.positive,
        PromptBlockDocument(
          documentId: 'positive',
          segments: const [
            TextSegment(id: 'text-a', text: 'A'),
            BlockSegment(
              id: 'block-b',
              titleSnapshot: 'B',
              colorSnapshot: '#FF607D8B',
              contentSnapshot: 'B',
            ),
            TextSegment(id: 'text-c', text: 'C'),
          ],
          updatedAt: DateTime(2026, 8, 30),
        ),
      );
      notifier.replacePlainText(PromptBlockLane.negative, 'NEGATIVE');
      await tester.pump();

      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
      expect(find.byType(PromptBlockTextSegment), findsNWidgets(2));

      final list = tester.widget<ReorderableListView>(
        find.byKey(const Key('prompt-block-editor-segments')),
      );
      list.onReorderItem!(0, 2);
      await tester.pump();

      final state = container.read(promptBlockWorkspaceNotifierProvider);
      expect(state.positiveDocument.segments.map((segment) => segment.id), [
        'block-b',
        'text-c',
        'text-a',
      ]);
      expect(notifier.plainTextFor(PromptBlockLane.negative), 'NEGATIVE');
    },
  );

  testWidgets('compact editor fits without overflow', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 280,
          height: 72,
          child: PromptBlockEditor(
            lane: PromptBlockLane.positive,
            compact: true,
            config: UnifiedPromptConfig(
              enableAutocomplete: false,
              enableSyntaxHighlight: false,
              enableAutoFormat: false,
              enableRegexReplace: false,
            ),
          ),
        ),
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('prompt-block-open-drawer')), findsOneWidget);
  });
}

Widget _app(
  Widget child, {
  required PromptBlockLibraryState libraryState,
  Locale locale = const Locale('zh'),
}) {
  var nextId = 0;
  final composer = PromptBlockComposer(
    uuidGenerator: () => 'test-${nextId++}',
    clock: () => DateTime(2026, 8, 30),
  );
  return ProviderScope(
    overrides: [
      promptBlockComposerProvider.overrideWithValue(composer),
      promptBlockLibraryNotifierProvider.overrideWith(
        () => _FakePromptBlockLibraryNotifier(libraryState),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

class _FakePromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakePromptBlockLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

PromptBlock _block(
  String id,
  String title,
  String content, {
  String? folderId,
}) {
  return PromptBlock(
    id: id,
    title: title,
    content: content,
    folderId: folderId,
    createdAt: DateTime(2026, 8, 30),
    updatedAt: DateTime(2026, 8, 30),
  );
}

PromptBlockFolder _folder(String id, String name) {
  return PromptBlockFolder(
    id: id,
    name: name,
    createdAt: DateTime(2026, 8, 30),
    updatedAt: DateTime(2026, 8, 30),
  );
}

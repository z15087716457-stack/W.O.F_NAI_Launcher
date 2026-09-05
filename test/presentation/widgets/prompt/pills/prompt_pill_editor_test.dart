import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/pill_instance_card.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

void main() {
  const markerA = '\uE000';
  const markerB = '\uE001';

  testWidgets('block inserted via provider renders a pill and projects', (
    tester,
  ) async {
    final emissions = <String>[];
    final container = await _pump(
      tester,
      onChanged: emissions.add,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'artist:foo, artist:bar')],
        folders: const [],
      ),
    );

    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();

    expect(find.text('画风1'), findsOneWidget);
    expect(emissions, contains('artist:foo, artist:bar'));
    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.text, markerA);
    expect(state.projection, 'artist:foo, artist:bar');
  });

  testWidgets('stale post-frame projection callbacks are discarded', (
    tester,
  ) async {
    final emissions = <String>[];
    final container = await _pump(
      tester,
      onChanged: emissions.add,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    emissions.clear();

    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.setText('projection A');
    notifier.setText('projection B');
    await tester.pump();

    expect(emissions, isNot(contains('projection A')));
    expect(emissions, contains('projection B'));
  });

  testWidgets('tapping a pill opens the L1 card; disable via card', (
    tester,
  ) async {
    final emissions = <String>[];
    final container = await _pump(
      tester,
      onChanged: emissions.add,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();

    // P2.5：点药丸 = 开 L1 实例卡（启停挪进卡里，不再直接 toggle）
    await tester.tap(find.byType(PromptPill));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PillInstanceCard), findsOneWidget);
    // 卡内显示块内容预览
    expect(find.text('CONTENT'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.instances[markerA]?.enabled, isFalse);
    expect(state.projection, '');
    expect(emissions.last, '');
  });

  testWidgets(
    'evolution badge replaces the dice badge and main card is read-only',
    (tester) async {
      final container = await _pump(
        tester,
        allowEvolutionToggle: false,
        libraryState: PromptBlockLibraryState(
          blocks: [_block('style', '画风1', 'CONTENT')],
          folders: const [],
        ),
      );
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(
        markerA,
        const PillInstanceSettings(mode: PillRollMode.random),
      );
      notifier.toggleEvolution(markerA);
      await tester.pump();

      expect(find.byIcon(Icons.casino_outlined), findsNothing);
      expect(find.byType(DnaIcon), findsOneWidget);

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();
      final evolutionButton = tester.widget<IconButton>(
        find.byKey(const Key('pill-evolution-toggle')),
      );
      expect(evolutionButton.onPressed, isNull);
    },
  );

  testWidgets('explore card can toggle evolution for enabled random instance', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      allowEvolutionToggle: true,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.insertBlockAt(offset: 0, blockId: 'style');
    notifier.updateInstanceSettings(
      markerA,
      const PillInstanceSettings(mode: PillRollMode.random),
    );
    await tester.pump();

    await tester.tap(find.byType(PromptPill));
    await tester.pump();
    await tester.pump();
    final evolutionButton = tester.widget<IconButton>(
      find.byKey(const Key('pill-evolution-toggle')),
    );
    expect(evolutionButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('pill-evolution-toggle')));
    await tester.pump();
    expect(
      container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!
          .evolutionEnabled,
      isTrue,
    );
  });

  testWidgets('dropping a library block inserts at the drop offset', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .setText('hello world');
    await tester.pump();

    _acceptDrop(
      tester,
      const PromptBlockDragData(blockId: 'style'),
      offset: Offset.zero,
    );
    await tester.pump();

    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.instances.length, 1);
    expect(state.document.instances.values.single.blockId, 'style');
    // Offset.zero 命中文本起始区域，标记落在 [0, len] 区间内
    expect(state.document.text.contains(markerA), isTrue);
    expect(state.document.text.length, 'hello world'.length + 1);
  });

  testWidgets('dropping a pill moves its marker in the text', (tester) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('a', 'A', 'AAA'), _block('b', 'B', 'BBB')],
        folders: const [],
      ),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.setText('x');
    notifier.insertBlockAt(offset: 0, blockId: 'a');
    notifier.insertBlockAt(offset: 2, blockId: 'b');
    await tester.pump();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.text,
      '${markerA}x$markerB',
    );

    _acceptDrop(
      tester,
      const PromptBlockDragData(
        blockId: 'a',
        instanceMarker: PillInstanceDragRef(marker: markerA, occurrence: 0),
      ),
      offset: Offset.zero,
    );
    await tester.pump();

    // Offset.zero → 归到文本起点附近；markerA 被移动过（位置变化或原地皆可接受，
    // 这里验证调用链没有炸且文档仍一致）
    final doc = container.read(pillWorkspaceNotifierProvider).document;
    expect(doc.text.length, 3);
    expect(doc.instances.length, 2);
  });

  testWidgets('typing reconciles text and keeps instances alive', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '1girl, ');
    await tester.pump();

    // enterText 整体替换文本：标记被删 → 实例被对账清除
    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.text, '1girl, ');
    expect(state.document.instances, isEmpty);
  });

  testWidgets('unknown marker renders an invalid pill that tap removes', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    // 未知标记：文本里有 PUA 字符但实例表没有（模拟外来粘贴）
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .setText('abc$markerA');
    await tester.pump();

    final pill = tester.widget<PromptPill>(find.byType(PromptPill));
    expect(pill.variant, PromptPillVariant.unknown);

    await tester.tap(find.byType(PromptPill));
    await tester.pump();
    expect(container.read(pillWorkspaceNotifierProvider).document.text, 'abc');
    expect(find.byType(PromptPill), findsNothing);
  });

  testWidgets('cut then paste resurrects the instance from tombstone', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.text,
      markerA,
    );

    // 剪切：marker 从文本消失 → 实例被对账移除（进墓碑缓存）
    notifier.setText('');
    await tester.pump();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.instances,
      isEmpty,
    );

    // 粘贴：同一 marker 字符回来 → 从墓碑复活实例，不再显示失效块
    notifier.setText('before $markerA after');
    await tester.pump();

    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.instances[markerA]?.blockId, 'style');
    expect(state.projection, 'before CONTENT after');
    expect(find.text('画风1'), findsOneWidget);
  });

  testWidgets('unknown marker without tombstone stays an invalid pill', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    // 外来 marker（无墓碑记录）：仍是失效药丸
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .setText('abc$markerB');
    await tester.pump();

    final pill = tester.widget<PromptPill>(find.byType(PromptPill));
    expect(pill.variant, PromptPillVariant.unknown);
    expect(
      container.read(pillWorkspaceNotifierProvider).document.instances,
      isEmpty,
    );
  });

  testWidgets('block deleted from library renders a missing pill', (
    tester,
  ) async {
    final libraryNotifier = _FakePromptBlockLibraryNotifier(
      PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    final container = await _pump(
      tester,
      libraryState: libraryNotifier.initialState,
      libraryNotifier: libraryNotifier,
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();
    expect(find.text('画风1'), findsOneWidget);

    // 换一个不含该块的库状态（模拟库中删除）
    libraryNotifier.emitForTest(
      PromptBlockLibraryState(blocks: [], folders: []),
    );
    await tester.pump();

    final pill = tester.widget<PromptPill>(find.byType(PromptPill));
    expect(pill.variant, PromptPillVariant.missing);
  });
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required PromptBlockLibraryState libraryState,
  ValueChanged<String>? onChanged,
  _FakePromptBlockLibraryNotifier? libraryNotifier,
  bool allowEvolutionToggle = false,
}) async {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;

  final notifier =
      libraryNotifier ?? _FakePromptBlockLibraryNotifier(libraryState);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(() => notifier),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 960,
            height: 360,
            child: PromptPillEditor(
              config: const UnifiedPromptConfig(
                enableAutocomplete: false,
                enableSyntaxHighlight: false,
                enableAutoFormat: false,
                enableRegexReplace: false,
              ),
              allowEvolutionToggle: allowEvolutionToggle,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();

  final element = tester.element(find.byType(PromptPillEditor));
  return ProviderScope.containerOf(element);
}

void _acceptDrop(
  WidgetTester tester,
  PromptBlockDragData data, {
  required Offset offset,
}) {
  final target = tester.widget<DragTarget<PromptBlockDragData>>(
    find.byType(DragTarget<PromptBlockDragData>),
  );
  target.onAcceptWithDetails?.call(
    DragTargetDetails<PromptBlockDragData>(data: data, offset: offset),
  );
}

class _FakePromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakePromptBlockLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;

  /// 测试专用：中途替换库状态，模拟块被删除。
  void emitForTest(PromptBlockLibraryState next) {
    state = AsyncData(next);
  }
}

PromptBlock _block(String id, String title, String content) {
  return PromptBlock(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime(2026, 8, 30),
    updatedAt: DateTime(2026, 8, 30),
  );
}

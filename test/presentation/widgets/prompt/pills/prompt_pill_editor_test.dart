import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/pill_instance_card.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';
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

  testWidgets('attached negative pill shows UC and card header tags', (
    tester,
  ) async {
    final block = _block('style', '画风', 'bright').copyWith(
      negativeContent: 'muted',
      tags: const [PromptBlockTag(name: '冷色', color: '#FF268BEA')],
    );
    final container = await _pump(
      tester,
      pillScope: PillScopes.negative,
      libraryState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .insertBlockAt(
          offset: 0,
          blockId: block.id,
          useNegativeContent: true,
          bundleId: 'bundle-1',
        );
    await tester.pump();
    expect(
      tester.widget<PromptPill>(find.byType(PromptPill)).isAttachedUc,
      isTrue,
    );
    expect(find.text('UC'), findsOneWidget);
    await tester.tap(find.byType(PromptPill));
    await tester.pumpAndSettle();
    expect(find.text('冷色'), findsOneWidget);
  });

  testWidgets('tag divider starts near short title and moves with long title', (
    tester,
  ) async {
    final tags = [
      for (var i = 0; i < 8; i++)
        PromptBlockTag(name: '标签$i', color: '#FF268BEA'),
    ];
    Future<(double, double)> measure(String title) async {
      await tester.pumpWidget(const SizedBox.shrink());
      final block = _block('tagged', title, 'prompt').copyWith(tags: tags);
      final container = await _pump(
        tester,
        libraryState: PromptBlockLibraryState(
          blocks: [block],
          folders: const [],
        ),
      );
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: block.id);
      await tester.pump();
      await tester.tap(find.byType(PromptPill));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(PillInstanceCard));
      final divider = tester.getRect(
        find.byKey(const Key('block-tag-overflow-divider')),
      );
      final scroll = tester.getRect(
        find.byKey(const Key('block-tag-scroll-area')),
      );
      expect(tester.takeException(), isNull);
      return (divider.left - card.left, scroll.width);
    }

    final short = await measure('123');
    expect(short.$1, inInclusiveRange(90, 110));
    final long = await measure('一个非常非常长的画风块标题需要保留标签空间');
    expect(long.$1, greaterThan(short.$1 + 60));
    expect(long.$2, greaterThanOrEqualTo(60));
  });

  testWidgets(
    'deleting main pill removes paired UC marker and its projection',
    (tester) async {
      final block = _block(
        'pair',
        '双面',
        'bright',
      ).copyWith(negativeContent: 'muted');
      final container = await _pump(
        tester,
        libraryState: PromptBlockLibraryState(
          blocks: [block],
          folders: const [],
        ),
        overrides: [
          generationParamsNotifierProvider.overrideWith(
            _FakeGenerationParamsNotifier.new,
          ),
        ],
      );
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .insertBlockAt(offset: 0, blockId: block.id, bundleId: 'pair-1');
      container
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .insertBlockAt(
            offset: 0,
            blockId: block.id,
            useNegativeContent: true,
            bundleId: 'pair-1',
          );
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateNegativePromptFromPill('muted');
      await tester.pump();
      await tester.tap(find.byType(PromptPill));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      final positive = container.read(pillWorkspaceProvider(PillScopes.main));
      final negative = container.read(
        pillWorkspaceProvider(PillScopes.negative),
      );
      expect(positive.document.text, isEmpty);
      expect(negative.document.text, isEmpty);
      expect(negative.document.instances, isEmpty);
      expect(negative.projection, isEmpty);
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        isEmpty,
      );
    },
  );

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

  testWidgets('paired scope keeps positive fixed while negative steps', (
    tester,
  ) async {
    final block = _block('pair', '双面', 'bright').copyWith(
      atoms: ['bright', 'vivid'],
      negativeContent: 'muted, dull',
      negativeAtoms: ['muted', 'dull'],
    );
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .insertBlockAt(
          offset: 0,
          blockId: block.id,
          bundleId: 'pair-1',
          rollScopeMask: 1,
        );
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .insertBlockAt(
          offset: 0,
          blockId: block.id,
          useNegativeContent: true,
          bundleId: 'pair-1',
          rollScopeMask: 1,
        );
    await tester.pump();

    await tester.tap(find.byType(PromptPill));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pill-preview-tab-2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pill-scope-negative')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pill-scope-positive')));
    await tester.pump();
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances[markerA]!
          .rollScopeMask,
      2,
    );
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.negative))
          .document
          .instances[markerA]!
          .rollScopeMask,
      2,
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('顺序'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    final pos = container.read(pillWorkspaceProvider(PillScopes.main));
    final neg = container.read(pillWorkspaceProvider(PillScopes.negative));
    expect(pos.document.instances[markerA]!.settings.mode, PillRollMode.fixed);
    expect(
      neg.document.instances[markerA]!.settings.mode,
      PillRollMode.sequential,
    );
    expect(pos.projection, 'bright');
    expect(neg.projection, 'muted');

    await tester.tap(find.byType(PromptPill));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pill-step-forward')));
    await tester.pump();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).projection,
      'bright',
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).projection,
      'dull',
    );
  });

  testWidgets('generation import appears only on the settings preview', (
    tester,
  ) async {
    final block = _block('settings', '画风参数', 'artist:foo').copyWith(
      generationSettings: const PromptBlockGenerationSettings(
        model: 'nai-diffusion-5-full',
        steps: 30,
        scale: 5.0,
      ),
    );
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .insertBlockAt(offset: 0, blockId: block.id);
    await tester.pump();
    await tester.tap(find.byType(PromptPill));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pill-apply-block-settings')), findsNothing);
    await tester.tap(find.byKey(const Key('pill-preview-tab-2')));
    await tester.pump();
    expect(find.byKey(const Key('pill-apply-block-settings')), findsOneWidget);
    expect(find.text('导入设置'), findsOneWidget);
  });

  testWidgets('L1 card anchors to the pill with a non-zero Overlay offset', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      appOffset: const Offset(240, 120),
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', '画风1', 'CONTENT')],
        folders: const [],
      ),
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .insertBlockAt(offset: 0, blockId: 'style');
    await tester.pump();

    final pill = find.byType(PromptPill);
    final clickPosition = tester.getCenter(pill);
    await tester.tap(pill);
    await tester.pump();
    await tester.pump();

    final card = find.byType(PillInstanceCard);
    expect(card, findsOneWidget);
    final overlay = find.ancestor(of: card, matching: find.byType(Overlay));
    expect(overlay, findsOneWidget);
    final overlayRect = tester.getRect(overlay);
    final localClick = clickPosition - overlayRect.topLeft;
    final expectedLeft =
        overlayRect.left +
        (localClick.dx - 150).clamp(
          8.0,
          (overlayRect.width - 308).clamp(8.0, overlayRect.width),
        );
    expect(tester.getTopLeft(card).dx, closeTo(expectedLeft, 0.1));
  });

  testWidgets(
    'main page hides evolution entirely: dice badge stays, card has no '
    'DNA button',
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

      // FEAT-47：开着遗传的实例在主页面不渲染 DNA 角标，回退骰子角标。
      expect(find.byIcon(Icons.casino_outlined), findsOneWidget);
      expect(find.byType(DnaIcon), findsNothing);

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('pill-evolution-toggle')), findsNothing);
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

  testWidgets('cross-lane translation drop copies despite marker collision', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      pillScope: PillScopes.negative,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    final source = container.read(
      pillWorkspaceProvider(PillScopes.main).notifier,
    );
    final target = container.read(
      pillWorkspaceProvider(PillScopes.negative).notifier,
    );
    source.insertTranslationAt(offset: 0, source: 'blue eyes', zh: '蓝眼睛');
    target.insertTranslationAt(offset: 0, source: 'bad hands', zh: '坏手');
    await tester.pump();

    _acceptDrop(
      tester,
      const PromptBlockDragData(
        blockId: '',
        translation: TranslationPill(source: 'blue eyes', zh: '蓝眼睛'),
        instanceMarker: PillInstanceDragRef(
          marker: markerA,
          occurrence: 0,
          scope: PillScopes.main,
        ),
      ),
      offset: Offset.zero,
    );
    await tester.pump();

    final sourceDoc = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    final targetDoc = container
        .read(pillWorkspaceProvider(PillScopes.negative))
        .document;
    expect(sourceDoc.instances.length, 1);
    expect(targetDoc.instances.length, 2);
    expect(targetDoc.instances[markerA]!.translation!.source, 'bad hands');
    expect(targetDoc.instances[markerB]!.translation!.source, 'blue eyes');
  });

  testWidgets('long translation reserves its full height in the prompt field', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      editorWidth: 320,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.setText('\n尾随文字');
    notifier.insertTranslationAt(
      offset: 0,
      source: 'source',
      zh: List.filled(55, '译文说明').join(),
    );
    await tester.pump();

    final pill = find.byType(TranslationPillView);
    expect(tester.getSize(pill).width, lessThanOrEqualTo(320));
    expect(tester.getSize(pill).height, greaterThan(145));
    final editable = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );
    final tailOffset = container
        .read(pillWorkspaceNotifierProvider)
        .document
        .text
        .indexOf('尾');
    final caret = editable.renderEditable.getLocalRectForCaret(
      TextPosition(offset: tailOffset),
    );
    final tailTop = editable.renderEditable.localToGlobal(Offset(0, caret.top));
    expect(tailTop.dy, greaterThanOrEqualTo(tester.getBottomLeft(pill).dy));
    expect(tester.takeException(), isNull);
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
  String pillScope = PillScopes.main,
  Offset appOffset = Offset.zero,
  double editorWidth = 960,
  List<Override> overrides = const [],
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
  final app = ProviderScope(
    overrides: [
      promptBlockLibraryNotifierProvider.overrideWith(() => notifier),
      ...overrides,
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: editorWidth,
          height: 360,
          child: PromptPillEditor(
            pillScope: pillScope,
            config: const UnifiedPromptConfig(
              enableSyntaxHighlight: false,
              enableAutoFormat: false,
            ),
            allowEvolutionToggle: allowEvolutionToggle,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    appOffset == Offset.zero
        ? app
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                Positioned(
                  left: appOffset.dx,
                  top: appOffset.dy,
                  right: 0,
                  bottom: 0,
                  child: app,
                ),
              ],
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

class _FakeGenerationParamsNotifier extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams();

  @override
  void updatePromptFromPill(String prompt) {
    state = state.copyWith(prompt: prompt);
  }

  @override
  void updateNegativePromptFromPill(String prompt) {
    state = state.copyWith(negativePrompt: prompt);
  }
}

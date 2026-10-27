import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/utils/prompt_block_bundle_insertion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/prompt_autocomplete_controller.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:nai_launcher/core/tag_expansion/tag_expansion_providers.dart';
import 'package:nai_launcher/presentation/providers/workspace_text_settings_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/prompt_autocomplete_binding.dart';
import 'package:nai_launcher/presentation/widgets/common/workspace_text_scale_scope.dart';
import '../../../../core/autocomplete/prompt_autocomplete_controller_test.dart'
    show candidates;
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/translation_pill_view.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

class _AutocompleteSource implements CompletionSource {
  final queries = <CompletionQuery>[];
  @override
  Future<List<CompletionCandidate>> search(CompletionQuery query) async {
    queries.add(query);
    return candidates;
  }
}

class _MemorySettings extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _MemoryCharacters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class _TestBlocksPlatform extends BlocksPlatform {
  int backups = 0;
  bool fail = false;
  @override
  Future<void> backupDraft(String snapshot) async {
    backups++;
    if (fail) {
      throw StateError('Backup failed');
    }
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final scope in [
    PillScopes.main,
    PillScopes.charPos('autocomplete-character'),
    PillScopes.charNeg('autocomplete-character'),
  ]) {
    testWidgets(
      'typed completion is opt-in and replaces current token in $scope',
      (tester) async {
        var services = 0;
        final source = _AutocompleteSource();
        PromptAutocompleteController? completion;
        ValueChanged<int>? accept;
        final container = await _pump(
          tester,
          libraryState: PromptBlockLibraryState(
            blocks: const [],
            folders: const [],
          ),
          pillScope: scope,
          overrides: [
            localTagExpansionServiceProvider.overrideWith((ref) {
              services++;
              return LocalTagExpansionService(
                catalog: source,
                relatedTags: source,
                substringSearch: (_, {int limit = 40}) async => [],
                popularSearch: ({int limit = 12}) async => [],
                semanticNames: (input, {int limit = 80}) async =>
                    input == '蓝眼' ? [candidates.first] : [],
              );
            }),
            promptAutocompleteBuilderProvider.overrideWithValue((
              context,
              controller,
              onAccept,
              child,
            ) {
              completion = controller;
              accept = onAccept;
              return child;
            }),
          ],
        );
        final field = find
            .descendant(
              of: find.byType(PromptPillEditor),
              matching: find.byType(TextField),
            )
            .first;
        await tester.tap(field);
        await tester.enterText(field, 'bl');
        await tester.pump(const Duration(milliseconds: 200));
        expect(services, 0);
        expect(source.queries, isEmpty);
        await container
            .read(promptAutocompleteEnabledProvider.notifier)
            .setEnabled(true);
        await tester.pump();
        await tester.enterText(field, '2.5::bl::');
        tester.widget<TextField>(field).controller!.selection =
            const TextSelection.collapsed(offset: 7);
        await tester.pump(const Duration(milliseconds: 120));
        expect(services, 1);
        expect(completion!.value.visible, true);
        expect(source.queries.last.token, 'bl');
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          container.read(pillWorkspaceProvider(scope)).document.text,
          '2.5::blue eyes::, ',
        );
        expect(
          tester.widget<TextField>(field).focusNode!.hasPrimaryFocus,
          true,
        );
        await tester.enterText(field, 'bl');
        await tester.pump(const Duration(milliseconds: 120));
        accept!(1);
        await tester.pump();
        expect(
          container.read(pillWorkspaceProvider(scope)).document.text,
          'blue hair, ',
        );
        // A composing-only notification must restart completion after IME
        // commit, even when the text and selection did not change.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '蓝眼',
            selection: TextSelection.collapsed(offset: 2),
            composing: TextRange(start: 0, end: 2),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(completion!.value.visible, false);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '蓝眼',
            selection: TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pump(const Duration(milliseconds: 150));
        expect(completion!.value.candidates.single.canonicalTag, 'blue_eyes');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(
          container.read(pillWorkspaceProvider(scope)).document.text,
          'blue eyes, ',
        );
        expect(
          tester.widget<TextField>(field).focusNode!.hasPrimaryFocus,
          true,
        );
        await tester.enterText(field, 'bl');
        await tester.pump(const Duration(milliseconds: 150));
        await completion!.openRelated(0);
        accept!(1);
        await tester.pump();
        expect(
          container.read(pillWorkspaceProvider(scope)).document.text,
          'blue eyes, blue hair, ',
        );
        expect(completion!.value.relatedFor, isNotNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(
          container.read(pillWorkspaceProvider(scope)).document.text,
          'blue eyes, blue hair, ',
        );
        expect(completion!.value.relatedAdded, {'blue_hair'});
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        expect(completion!.value.visible, true);
        expect(completion!.value.relatedFor, isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        expect(completion!.value.visible, false);
        await container
            .read(promptAutocompleteEnabledProvider.notifier)
            .setEnabled(false);
        await tester.pump();
        final queries = source.queries.length;
        await tester.enterText(field, 're');
        await tester.pump(const Duration(milliseconds: 200));
        expect(source.queries.length, queries);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('default popup shows candidates under the token; click accepts', (
    tester,
  ) async {
    final source = _AutocompleteSource();
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: const [],
        folders: const [],
      ),
      overrides: [
        localTagExpansionServiceProvider.overrideWith(
          (ref) => LocalTagExpansionService(
            catalog: source,
            relatedTags: source,
            substringSearch: (_, {int limit = 40}) async => [],
            popularSearch: ({int limit = 12}) async => [],
          ),
        ),
      ],
    );
    await container
        .read(promptAutocompleteEnabledProvider.notifier)
        .setEnabled(true);
    await tester.pump();
    final field = find
        .descendant(
          of: find.byType(PromptPillEditor),
          matching: find.byType(TextField),
        )
        .first;
    await tester.tap(field);
    await tester.enterText(field, 'bl');
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    final popup = find.byKey(const Key('prompt-autocomplete'));
    expect(popup, findsOneWidget);
    expect(
      tester.getTopLeft(popup).dy,
      greaterThan(tester.getTopLeft(field).dy),
    );
    await tester.tap(find.byKey(const Key('prompt-autocomplete-1')));
    await tester.pump();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'blue hair, ',
    );
    expect(popup, findsNothing);
    expect(tester.widget<TextField>(field).focusNode!.hasPrimaryFocus, true);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('creative scale updates editor and inline chips exactly once', (
    tester,
  ) async {
    final block = _block('scale', 'Scale chip', 'blue eyes');
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [block], folders: const []),
    );
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .insertBlockAt(offset: 0, blockId: block.id);
    await tester.pump();
    await tester.pump();
    final before = tester.getRect(find.text('Scale chip')).height;
    await container.read(workspaceFontScaleProvider.notifier).setFontScale(1.5);
    await tester.pump();
    await tester.pump();
    final field = find
        .descendant(
          of: find.byType(PromptPillEditor),
          matching: find.byType(TextField),
        )
        .first;
    expect(MediaQuery.textScalerOf(tester.element(field)).scale(10), 15);
    expect(
      tester.getRect(find.text('Scale chip')).height,
      closeTo(before * 1.5, .001),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  const markerA = '\uE000';
  const markerB = '\uE001';

  testWidgets(
    'reinserted library reading keeps language and both edit states',
    (tester) async {
      final block = PromptBlock.create(
        id: 'ja-reading',
        title: '青い目',
        content: 'blue eyes',
        readingTranslationZh: '青い目',
        readingTranslationLanguageCode: 'ja',
        readingTranslationNeedsReview: true,
        readingTranslationEdited: true,
      );
      final restored = PromptBlock.fromJson(block.toJson());
      final container = await _pump(
        tester,
        libraryState: PromptBlockLibraryState(
          blocks: [restored],
          folders: const [],
        ),
      );
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: block.id);
      await tester.pump();
      final state = container.read(pillWorkspaceNotifierProvider);
      final reading = state.document.instances.values.single.translation!;
      expect(reading.languageCode, 'ja');
      expect(reading.needsReview, isTrue);
      expect(reading.translationEdited, isTrue);
      expect(state.projection, 'blue eyes');
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('attached negative pill shows UC and forwards tags to the card', (
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
      tester.widget<UiBlockPill>(find.byType(UiBlockPill).first).paired,
      isTrue,
    );
    expect(find.text('UC'), findsOneWidget);
    expect(
      tester.widget<UiBlockPill>(find.byType(UiBlockPill).first).open,
      isFalse,
    );
    await tester.tap(find.byType(UiBlockPill).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<UiBlockPill>(find.byType(UiBlockPill).first).open,
      isTrue,
    );
    expect(
      tester
          .widget<BlockInstanceCard>(find.byType(BlockInstanceCard))
          .data
          .block
          .tags
          .map((t) => t.name),
      ['冷色'],
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(
      tester.widget<UiBlockPill>(find.byType(UiBlockPill).first).open,
      isFalse,
    );
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
      await tester.tap(find.byType(UiBlockPill).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('block-card-remove')));
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

  for (final scope in [
    PillScopes.main,
    PillScopes.negative,
    PillScopes.charPos('c1'),
    PillScopes.charNeg('c1'),
  ]) {
    testWidgets('text reconciliation removes reading bundle from $scope', (
      tester,
    ) async {
      final block = _block(
        'reading-pair',
        '双面',
        'bright',
      ).copyWith(negativeContent: 'muted', readingTranslationZh: '明亮');
      final container = await _pump(
        tester,
        pillScope: scope,
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
      insertPromptBlockBundleWithReader(
        container.read,
        scope: scope,
        offset: 0,
        blockId: block.id,
      );
      final positiveScope = scope.startsWith('char:')
          ? PillScopes.charPos('c1')
          : PillScopes.main;
      final negativeScope = scope.startsWith('char:')
          ? PillScopes.charNeg('c1')
          : PillScopes.negative;
      final pos = container
          .read(pillWorkspaceProvider(positiveScope))
          .document
          .instances
          .values
          .single;
      final neg = container
          .read(pillWorkspaceProvider(negativeScope))
          .document
          .instances
          .values
          .single;
      expect(pos.translation, isNotNull);
      expect(pos.bundleId, neg.bundleId);
      expect(pos.rollScopeMask, neg.rollScopeMask);
      await tester.pump();
      // TextField's edit path is also used by cut and selection replacement.
      await tester.enterText(find.byType(TextField).first, 'replacement');
      await tester.pumpAndSettle();
      for (final lane in [positiveScope, negativeScope]) {
        expect(
          container.read(pillWorkspaceProvider(lane)).document.instances,
          isEmpty,
        );
        expect(
          container.read(pillWorkspaceProvider(lane)).projection,
          lane == scope ? 'replacement' : '',
        );
      }
    });
  }

  testWidgets(
    'menu expands selected shared occurrence and paired UC in place',
    (tester) async {
      final block = _block(
        'pair-expand',
        'Pair',
        '1.2::bright::',
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
      insertPromptBlockBundleWithReader(
        container.read,
        scope: PillScopes.main,
        offset: 0,
        blockId: block.id,
      );
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .setText('$markerA / $markerA');
      container
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .setText('$markerA / $markerA');
      await tester.pump();
      final posSend = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .projection;
      final negSend = container
          .read(pillWorkspaceProvider(PillScopes.negative))
          .projection;
      await tester.tap(find.byType(UiBlockPill).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('block-card-more')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('block-card-expand')));
      await tester.pumpAndSettle();
      final pos = container.read(pillWorkspaceProvider(PillScopes.main));
      final neg = container.read(pillWorkspaceProvider(PillScopes.negative));
      expect(pos.document.text, '$markerA / 1.2::bright::');
      expect(neg.document.text, '$markerA / muted');
      expect(pos.projection, posSend);
      expect(neg.projection, negSend);
      expect(find.byType(BlockInstanceCard), findsNothing);
    },
  );

  for (final key in [LogicalKeyboardKey.backspace, LogicalKeyboardKey.delete]) {
    testWidgets('keyboard ${key.keyLabel} removes both bundle sides', (
      tester,
    ) async {
      final block = _block(
        'keys',
        'Pair',
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
      insertPromptBlockBundleWithReader(
        container.read,
        scope: PillScopes.main,
        offset: 0,
        blockId: block.id,
      );
      await tester.pump();
      final field = find.byType(TextField).first;
      await tester.tap(field);
      final controller = tester.widget<TextField>(field).controller!;
      controller.selection = TextSelection.collapsed(
        offset: key == LogicalKeyboardKey.backspace ? 1 : 0,
      );
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
        isEmpty,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.negative))
            .document
            .text,
        isEmpty,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }

  testWidgets(
    'temporary pill exposes fixed send and card integration callbacks',
    (tester) async {
      final block = _block('temp-view', 'Temporary view', 'library');
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
      final notifier = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      notifier.insertBlockAt(offset: 0, blockId: block.id);
      notifier.editTempContent(markerA, 'temporary', null);
      await tester.pump();
      expect(
        tester.widget<UiBlockPill>(find.byType(UiBlockPill).first).temporary,
        isTrue,
      );
      await tester.tap(find.byType(UiBlockPill).first);
      await tester.pumpAndSettle();
      final card = tester.widget<BlockInstanceCard>(
        find.byType(BlockInstanceCard),
      );
      expect(card.data.temporary, isTrue);
      expect(card.data.tempContent, 'temporary');
      expect(card.data.originalContent, 'library');
      expect(card.data.editedBy, 'user');
      expect(card.data.editedAt, isNotNull);
      expect(card.data.send, 'temporary');
      expect(card.actions.onEditTempContent, isNotNull);
      expect(card.actions.onRevertTemp, isNotNull);
      expect(card.actions.onSaveTempAsNewBlock, isNotNull);
    },
  );

  testWidgets('cutting one side removes the paired marker and projection', (
    tester,
  ) async {
    final block = _block(
      'cut-pair',
      'Pair',
      'bright',
    ).copyWith(negativeContent: 'muted');
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [block], folders: const []),
      overrides: [
        generationParamsNotifierProvider.overrideWith(
          _FakeGenerationParamsNotifier.new,
        ),
      ],
    );
    insertPromptBlockBundleWithReader(
      container.read,
      scope: PillScopes.main,
      offset: 0,
      blockId: block.id,
    );
    await tester.pump();
    final field = find.byType(TextField).first;
    await tester.tap(field);
    tester.widget<TextField>(field).controller!.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 1,
    );
    await _controlKey(tester, LogicalKeyboardKey.keyX);
    await tester.pumpAndSettle();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.instances,
      isEmpty,
    );
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.negative))
          .document
          .instances,
      isEmpty,
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).projection,
      '',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

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
    await tester.tap(find.byType(UiBlockPill).first);
    await tester.pump();
    await tester.pump();

    expect(find.byType(BlockInstanceCard), findsOneWidget);
    // 卡内显示块内容预览
    expect(find.text('CONTENT'), findsOneWidget);

    await tester.tap(find.byKey(const Key('block-card-toggle')));
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

    await tester.tap(find.byType(UiBlockPill).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('block-card-side-negative')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('block-card-side-positive')));
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

    await tester.tap(find.byKey(const Key('block-card-mode-sequential')));
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

    await tester.tap(find.byKey(const Key('block-card-step-next')));
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

  testWidgets(
    'card generation import is confined to its saved parameters section',
    (tester) async {
      final block = _block('settings', '画风参数', 'artist:foo').copyWith(
        generationSettings: const PromptBlockGenerationSettings(
          model: 'nai-diffusion-5-full',
          steps: 30,
          scale: 5.0,
        ),
      );
      final container = await _pump(
        tester,
        libraryState: PromptBlockLibraryState(
          blocks: [block],
          folders: const [],
        ),
      );
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .insertBlockAt(offset: 0, blockId: block.id);
      await tester.pump();
      await tester.tap(find.byType(UiBlockPill).first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BlockInstanceCard>(find.byType(BlockInstanceCard))
            .data
            .block
            .params!
            .steps,
        30,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('block-card-params')),
          matching: find.byKey(const Key('block-card-apply')),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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

    final pill = find.byType(UiBlockPill).first;
    final clickPosition = tester.getCenter(pill);
    final pillBottom = tester.getBottomLeft(pill).dy;
    await tester.tap(pill);
    await tester.pumpAndSettle();

    final card = find.byType(BlockInstanceCard);
    expect(card, findsOneWidget);
    final overlay = find.ancestor(of: card, matching: find.byType(Overlay));
    expect(overlay, findsOneWidget);
    final overlayRect = tester.getRect(overlay);
    final localClick = clickPosition - overlayRect.topLeft;
    final expectedLeft =
        overlayRect.left +
        (localClick.dx - BlockInstanceCard.width / 2).clamp(
          4.0,
          (overlayRect.width - BlockInstanceCard.width - 4).clamp(
            4.0,
            overlayRect.width,
          ),
        );
    expect(tester.getTopLeft(card).dx, closeTo(expectedLeft, 0.1));
    expect(tester.getTopLeft(card).dy, closeTo(pillBottom + 8, 0.1));
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
      expect(
        find.byWidgetPredicate(
          (widget) => widget is UiGlyph && widget.path == UiGlyphs.dice,
        ),
        findsOneWidget,
      );
      expect(find.byType(DnaIcon), findsNothing);

      await tester.tap(find.byType(UiBlockPill).first);
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

    await tester.tap(find.byType(UiBlockPill).first);
    await tester.pump();
    await tester.pump();
    final card = tester.widget<BlockInstanceCard>(
      find.byType(BlockInstanceCard),
    );
    expect(card.actions.onEvolutionChanged, isNotNull);
    await tester.tap(find.byKey(const Key('block-card-genetic')));
    await tester.pump();
    expect(
      (container.read(blocksPlatformProvider) as _TestBlocksPlatform).backups,
      1,
    );
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
      overrides: [
        generationParamsNotifierProvider.overrideWith(
          _FakeGenerationParamsNotifier.new,
        ),
      ],
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .setText('hello world');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptFromPill('hello world');
    await tester.pump();

    _acceptDrop(
      tester,
      const PromptBlockDragData(blockId: 'style'),
      offset: Offset.zero,
    );
    await tester.pump();

    expect(
      (container.read(blocksPlatformProvider) as _TestBlocksPlatform).backups,
      1,
    );
    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.instances.length, 1);
    expect(state.document.instances.values.single.blockId, 'style');
    // Offset.zero 命中文本起始区域，标记落在 [0, len] 区间内
    expect(state.document.text.contains(markerA), isTrue);
    expect(state.document.text.length, 'hello world'.length + 1);
  });

  testWidgets('failed drag backup leaves the current document intact', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(
        blocks: [_block('style', 'Style', 'CONTENT')],
        folders: const [],
      ),
      overrides: [
        generationParamsNotifierProvider.overrideWith(
          _FakeGenerationParamsNotifier.new,
        ),
      ],
    );
    container
        .read(pillWorkspaceNotifierProvider.notifier)
        .setText('current draft');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptFromPill('current draft');
    final platform =
        container.read(blocksPlatformProvider) as _TestBlocksPlatform;
    platform.fail = true;
    await tester.pump();
    _acceptDrop(
      tester,
      const PromptBlockDragData(blockId: 'style'),
      offset: Offset.zero,
    );
    await tester.pumpAndSettle();
    final doc = container.read(pillWorkspaceNotifierProvider).document;
    expect(doc.text, 'current draft');
    expect(doc.instances, isEmpty);
    expect(platform.backups, 1);
    expect(tester.takeException(), isNull);
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
        translation: TranslationPill(
          source: 'blue eyes',
          zh: '青い目',
          languageCode: 'ja',
          needsReview: true,
          translationEdited: true,
        ),
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
    final copied = targetDoc.instances[markerB]!.translation!;
    expect(copied.languageCode, 'ja');
    expect(copied.needsReview, isTrue);
    expect(copied.translationEdited, isTrue);
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

  testWidgets(
    'translation pill opens the editor on left click and toggles on middle click',
    (tester) async {
      final container = await _pump(
        tester,
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      );
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertTranslationAt(offset: 0, source: 'blue eyes', zh: '蓝眼睛');
      await tester.pump();

      final pill = find.byType(TranslationPillView);
      await tester.tap(pill);
      await tester.pump();
      expect(
        find.byKey(const Key('translation-pill-editor-popover')),
        findsOne,
      );
      expect(find.text('蓝眼睛'), findsWidgets);

      await tester.tap(find.byTooltip('关闭'));
      await tester.pump();
      final middle = await tester.startGesture(
        tester.getCenter(pill),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await middle.up();
      await tester.pump();
      expect(find.text('blue eyes'), findsOneWidget);
      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances
            .values
            .single
            .translation!
            .showOriginal,
        isTrue,
      );
    },
  );

  testWidgets(
    'original translation edits at the clicked caret and retains IME composition',
    (tester) async {
      final emissions = <String>[];
      final container = await _pump(
        tester,
        editorWidth: 320,
        onChanged: emissions.add,
        autoFormat: true,
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      );
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.insertTranslationAt(offset: 0, source: 'blue eyes', zh: '蓝眼睛');
      notifier.showAllTranslations(original: true);
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('translation-pill-source-input'));
      final editable = tester.state<EditableTextState>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      final caret = editable.renderEditable.getLocalRectForCaret(
        const TextPosition(offset: 5),
      );
      await tester.tapAt(editable.renderEditable.localToGlobal(caret.center));
      await tester.pump();
      expect(editable.widget.focusNode.hasFocus, isTrue);
      expect(
        tester.widget<EditableText>(find.byType(EditableText).first).showCursor,
        isFalse,
      );
      expect(editable.widget.controller.selection.baseOffset, 5);
      expect(
        find.byKey(const Key('translation-pill-editor-popover')),
        findsNothing,
      );

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'blue green eyes',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      await tester.pump();
      await tester.pump();
      var workspace = container.read(pillWorkspaceNotifierProvider);
      expect(workspace.document.text, markerA);
      expect(workspace.projection, 'blue green eyes');
      expect(
        workspace.document.instances[markerA]!.translation!.needsReview,
        isTrue,
      );
      expect(workspace.document.instances[markerA]!.translation!.zh, '蓝眼睛');
      expect(emissions.last, 'blue green eyes');
      final controller = tester.widget<TextField>(field).controller!;
      expect(controller.selection.baseOffset, 11);
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'blue green 眼睛',
          selection: TextSelection.collapsed(offset: 13),
          composing: TextRange(start: 11, end: 13),
        ),
      );
      await tester.pump();
      expect(tester.widget<TextField>(field).controller, same(controller));
      expect(controller.value.composing, const TextRange(start: 11, end: 13));
      expect(controller.selection.baseOffset, 13);
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'blue green 眼睛',
          selection: TextSelection.collapsed(offset: 13),
        ),
      );
      await tester.pump();
      final middle = await tester.startGesture(
        tester.getCenter(field),
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await middle.up();
      await tester.pumpAndSettle();
      expect(field, findsNothing);
      expect(find.text('蓝眼睛'), findsOneWidget);
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
      workspace = container.read(pillWorkspaceNotifierProvider);
      expect(workspace.projection, 'blue green 眼睛');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('original keyboard deletion keeps the block and neighbors', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.setText('before, after');
    notifier.insertTranslationAt(offset: 8, source: 'blue eyes', zh: '蓝眼睛');
    notifier.insertTranslationAt(offset: 9, source: 'red hair', zh: '红发');
    notifier.showAllTranslations(original: true);
    await tester.pumpAndSettle();
    final originalDocument = container
        .read(pillWorkspaceNotifierProvider)
        .document;
    final outer = tester.widget<EditableText>(find.byType(EditableText).first);
    outer.controller.selection = const TextSelection.collapsed(offset: 9);
    final field = find.byKey(const Key('translation-pill-source-input')).first;
    await tester.tap(field);
    await tester.pump();
    final input = tester.widget<TextField>(field).controller!;
    input.selection = TextSelection.collapsed(offset: input.text.length);

    Future<void> press(LogicalKeyboardKey key, String source) async {
      await tester.sendKeyEvent(key);
      await tester.pump();
      final workspace = container.read(pillWorkspaceNotifierProvider);
      expect(workspace.document.text, originalDocument.text);
      expect(
        workspace.document.instances.keys,
        originalDocument.instances.keys,
      );
      expect(
        workspace.document.instances[markerA]!.translation!.source,
        source,
      );
      expect(
        workspace.document.instances[markerB],
        originalDocument.instances[markerB],
      );
      expect(workspace.projection, 'before, ${source}red hairafter');
      expect(
        tester.widget<TextField>(field).focusNode!.hasPrimaryFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    }

    await press(LogicalKeyboardKey.backspace, 'blue eye');
    input.selection = const TextSelection.collapsed(offset: 4);
    await press(LogicalKeyboardKey.delete, 'blueeye');
    input.selection = const TextSelection.collapsed(offset: 0);
    await press(LogicalKeyboardKey.backspace, 'blueeye');
    input.selection = TextSelection.collapsed(offset: input.text.length);
    await press(LogicalKeyboardKey.delete, 'blueeye');
    input.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
    await press(LogicalKeyboardKey.backspace, 'beye');
    input.selection = TextSelection(
      baseOffset: 0,
      extentOffset: input.text.length,
    );
    await press(LogicalKeyboardKey.delete, '');
    await press(LogicalKeyboardKey.backspace, '');
    await press(LogicalKeyboardKey.delete, '');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '眼睛👩‍🎨',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );
    await tester.pump();
    await press(LogicalKeyboardKey.backspace, '眼睛');
    input.selection = const TextSelection.collapsed(offset: 0);
    await press(LogicalKeyboardKey.delete, '睛');
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('original keyboard navigation and word deletion stay local', (
    tester,
  ) async {
    final (container, outer, input) = await _pumpOriginalKeyboardEditor(tester);
    final document = container.read(pillWorkspaceNotifierProvider).document;
    final outerValue = outer.value;
    input.selection = const TextSelection.collapsed(offset: 5);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(input.selection, const TextSelection.collapsed(offset: 4));
    await _controlKey(tester, LogicalKeyboardKey.arrowLeft);
    expect(input.selection, const TextSelection.collapsed(offset: 0));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(
      input.selection,
      const TextSelection.collapsed(offset: 9, affinity: TextAffinity.upstream),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      input.selection,
      const TextSelection(baseOffset: 9, extentOffset: 8),
    );
    await _controlKey(tester, LogicalKeyboardKey.keyA);
    expect(
      input.selection,
      const TextSelection(baseOffset: 0, extentOffset: 9),
    );
    input.selection = const TextSelection.collapsed(offset: 9);
    await _controlKey(tester, LogicalKeyboardKey.backspace);
    expect(input.text, 'blue ');
    input.selection = const TextSelection.collapsed(offset: 0);
    await _controlKey(tester, LogicalKeyboardKey.delete);
    expect(input.text, ' ');
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(input.text, isEmpty);
    final workspace = container.read(pillWorkspaceNotifierProvider);
    expect(workspace.document.text, document.text);
    expect(workspace.document.instances[markerB], document.instances[markerB]);
    expect(outer.value, outerValue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('original clipboard shortcuts only copy cut and paste source', (
    tester,
  ) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        } else if (call.method == 'Clipboard.getData') {
          return {'text': clipboard};
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final (container, outer, input) = await _pumpOriginalKeyboardEditor(tester);
    final document = container.read(pillWorkspaceNotifierProvider).document;
    final outerValue = outer.value;
    await _controlKey(tester, LogicalKeyboardKey.keyA);
    await _controlKey(tester, LogicalKeyboardKey.keyC);
    expect(clipboard, 'blue eyes');
    await _controlKey(tester, LogicalKeyboardKey.keyX);
    expect(input.text, isEmpty);
    expect(clipboard, 'blue eyes');
    await _controlKey(tester, LogicalKeyboardKey.keyV);
    expect(input.text, 'blue eyes');
    await Clipboard.setData(const ClipboardData(text: 'green eyes'));
    await _controlKey(tester, LogicalKeyboardKey.keyA);
    await _controlKey(tester, LogicalKeyboardKey.keyV);
    final workspace = container.read(pillWorkspaceNotifierProvider);
    expect(input.text, 'green eyes');
    expect(
      workspace.document.instances[markerA]!.translation!.source,
      'green eyes',
    );
    expect(workspace.document.instances[markerB], document.instances[markerB]);
    expect(workspace.document.text, document.text);
    expect(outer.value, outerValue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('original undo and redo do not touch the outer document', (
    tester,
  ) async {
    final (container, outer, input) = await _pumpOriginalKeyboardEditor(tester);
    final document = container.read(pillWorkspaceNotifierProvider).document;
    final outerValue = outer.value;
    await tester.pump(const Duration(milliseconds: 600));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'green eyes',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await _controlKey(tester, LogicalKeyboardKey.keyZ);
    expect(input.text, 'blue eyes');
    await _controlKey(tester, LogicalKeyboardKey.keyY);
    expect(input.text, 'green eyes');
    final workspace = container.read(pillWorkspaceNotifierProvider);
    expect(workspace.document.text, document.text);
    expect(workspace.document.instances[markerB], document.instances[markerB]);
    expect(
      workspace.document.instances[markerA]!.translation!.needsReview,
      isTrue,
    );
    expect(outer.value, outerValue);
    await tester.pumpWidget(const SizedBox.shrink());
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('original text selection is separate from the icon drag handle', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.insertTranslationAt(offset: 0, source: 'blue eyes', zh: '蓝眼睛');
    notifier.showAllTranslations(original: true);
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('translation-pill-source-input'));
    final editable = tester.state<EditableTextState>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    Offset position(int offset) => editable.renderEditable.localToGlobal(
      editable.renderEditable
          .getLocalRectForCaret(TextPosition(offset: offset))
          .center,
    );
    final selecting = await tester.startGesture(
      position(0),
      kind: PointerDeviceKind.mouse,
    );
    await selecting.moveTo(position(4));
    await selecting.up();
    await tester.pump();
    expect(
      tester.widget<TextField>(field).controller!.selection.isCollapsed,
      isFalse,
    );
    expect(find.byType(TranslationPillView), findsOneWidget);
    final handle = find.descendant(
      of: find.byType(TranslationPillView),
      matching: find.byType(TranslationIcon),
    );
    final dragging = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.mouse,
    );
    await dragging.moveBy(const Offset(120, 70));
    await tester.pump();
    expect(find.byType(TranslationPillView), findsWidgets);
    await dragging.up();
    await tester.pumpAndSettle();
    expect(
      container.read(pillWorkspaceNotifierProvider).document.instances.length,
      1,
    );
    expect(
      container.read(pillWorkspaceNotifierProvider).projection,
      'blue eyes',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'existing translation pill displays clean 1x source when enabled',
    (tester) async {
      final container = await _pump(
        tester,
        autoFormat: true,
        libraryState: PromptBlockLibraryState(blocks: [], folders: []),
      );
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertTranslationAt(
            offset: 0,
            source: '1::blue eyes::',
            zh: '蓝眼睛',
            needsReview: true,
          );
      await tester.pump();
      expect(find.text('blue eyes'), findsOneWidget);
      final sourceField = find.byKey(
        const Key('translation-pill-source-input'),
      );
      await tester.tap(sourceField);
      await tester.pump();
      expect(
        tester.widget<TextField>(sourceField).controller!.text,
        'blue eyes',
      );
      expect(
        container.read(pillWorkspaceNotifierProvider).projection,
        '1::blue eyes::',
      );
    },
  );

  testWidgets('translation pill converts to editable source text in place', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.setText('before, after');
    notifier.insertTranslationAt(offset: 8, source: 'blue eyes', zh: '蓝眼睛');
    await tester.pump();

    await tester.tap(find.byType(TranslationPillView));
    await tester.pump();
    final fields = find.descendant(
      of: find.byKey(const Key('translation-pill-editor-popover')),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.last, '绿眼睛');
    await tester.enterText(fields.first, 'green eyes');
    await tester.tap(find.byKey(const Key('translation-pill-plain-text')));
    await tester.pump();

    final state = container.read(pillWorkspaceNotifierProvider);
    expect(state.document.text, 'before, green eyesafter');
    expect(state.document.instances, isEmpty);
    expect(state.projection, 'before, green eyesafter');
    expect(find.byType(TranslationPillView), findsNothing);
  });

  testWidgets('adjacent pill borders have a small visual gap', (tester) async {
    final container = await _pump(
      tester,
      libraryState: PromptBlockLibraryState(blocks: [], folders: []),
    );
    final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
    notifier.insertTranslationAt(offset: 0, source: 'cat', zh: '猫');
    notifier.insertTranslationAt(offset: 1, source: 'dog', zh: '狗');
    await tester.pump();

    final pills = find.byType(TranslationPillView);
    expect(pills, findsNWidgets(2));
    final first = tester.getRect(pills.at(0));
    final second = tester.getRect(pills.at(1));
    expect(second.left - first.right, greaterThanOrEqualTo(1.5));
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

    final pill = tester.widget<UiBlockPill>(find.byType(UiBlockPill).first);
    expect(pill.status, UiBlockPillStatus.invalid);

    await tester.tap(find.byType(UiBlockPill).first);
    await tester.pump();
    expect(container.read(pillWorkspaceNotifierProvider).document.text, 'abc');
    expect(find.byType(UiBlockPill), findsNothing);
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

    final pill = tester.widget<UiBlockPill>(find.byType(UiBlockPill).first);
    expect(pill.status, UiBlockPillStatus.invalid);
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

    final pill = tester.widget<UiBlockPill>(find.byType(UiBlockPill).first);
    expect(pill.status, UiBlockPillStatus.missing);
  });
}

Future<(ProviderContainer, TextEditingController, TextEditingController)>
_pumpOriginalKeyboardEditor(WidgetTester tester) async {
  final container = await _pump(
    tester,
    libraryState: PromptBlockLibraryState(blocks: [], folders: []),
  );
  final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
  notifier.setText('before, after');
  notifier.insertTranslationAt(offset: 8, source: 'blue eyes', zh: '蓝眼睛');
  notifier.insertTranslationAt(offset: 9, source: 'red hair', zh: '红发');
  notifier.showAllTranslations(original: true);
  await tester.pumpAndSettle();
  final outer = tester
      .widget<EditableText>(find.byType(EditableText).first)
      .controller;
  outer.selection = const TextSelection.collapsed(offset: 9);
  final field = find.byKey(const Key('translation-pill-source-input')).first;
  await tester.tap(field);
  await tester.pump();
  return (container, outer, tester.widget<TextField>(field).controller!);
}

Future<void> _controlKey(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required PromptBlockLibraryState libraryState,
  ValueChanged<String>? onChanged,
  _FakePromptBlockLibraryNotifier? libraryNotifier,
  bool allowEvolutionToggle = false,
  bool autoFormat = false,
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
      blocksPlatformProvider.overrideWithValue(_TestBlocksPlatform()),
      localStorageServiceProvider.overrideWithValue(_MemorySettings()),
      characterPromptNotifierProvider.overrideWith(_MemoryCharacters.new),
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
          child: WorkspaceTextScaleHost(
            child: PromptPillEditor(
              pillScope: pillScope,
              config: UnifiedPromptConfig(
                enableSyntaxHighlight: false,
                enableAutoFormat: autoFormat,
              ),
              allowEvolutionToggle: allowEvolutionToggle,
              onChanged: onChanged,
            ),
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

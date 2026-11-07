import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_palette_provider.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_palette.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';

import '../../helpers/studio_capture_fonts.dart';
import 'blocks_wiring_test.dart'
    show MemoryBlockStorage, MemorySettings, MemoryCharacters, TestPlatform;

void main() {
  setUpAll(loadStudioCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final libraryBacked in [false, true]) {
    testWidgets(
      'temp round trip through palette stays temporary (library=$libraryBacked)',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final storage = MemoryBlockStorage();
        final platform = TestPlatform();
        final original = PromptBlock.create(
          id: 'original',
          title: 'Source block',
          content: 'old library content',
          color: '#FF248C65',
          iconName: 'user',
        );
        if (libraryBacked) storage.blocks[original.id] = original;
        final container = ProviderContainer(
          overrides: [
            promptBlockStorageProvider.overrideWithValue(storage),
            localStorageServiceProvider.overrideWithValue(MemorySettings()),
            characterPromptNotifierProvider.overrideWith(MemoryCharacters.new),
            blocksPlatformProvider.overrideWithValue(platform),
          ],
        );
        addTearDown(container.dispose);
        Future<void> unmount() async {
          PromptBlockPaletteButton.closeFloating();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }

        addTearDown(unmount);
        await container.read(promptBlockLibraryNotifierProvider.future);
        await container.read(promptBlockPaletteNotifierProvider.future);
        final content = PillTempContent(
          title: 'Temporary portrait',
          color: '#FFB4B641',
          iconName: 'star',
          content: 'blue eyes,\nblack hair',
          negativeContent: 'blur',
          originalContent: original.content,
          editedAt: DateTime.utc(2026),
          editedBy: 'user',
          translations: const [TranslationPill(source: 'blue eyes', zh: '蓝眼睛')],
          negativeTranslations: const [
            TranslationPill(source: 'blur', zh: '模糊'),
          ],
        );
        final source = container.read(
          pillWorkspaceProvider(PillScopes.main).notifier,
        );
        source.restoreDocument(
          PillDocument(
            text: '\uE000',
            instances: {
              '\uE000': PillInstance(
                blockId: libraryBacked ? original.id : '',
                temp: content,
              ),
            },
          ),
        );
        const config = UnifiedPromptConfig(
          enableSyntaxHighlight: false,
          enableAutoFormat: false,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: GeistTheme.light,
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 30,
                      top: 40,
                      width: 540,
                      height: 220,
                      child: PromptPillEditor(
                        key: Key('source'),
                        config: config,
                      ),
                    ),
                    Positioned(
                      left: 30,
                      top: 530,
                      width: 540,
                      height: 220,
                      child: PromptPillEditor(
                        key: Key('target'),
                        config: config,
                        pillScope: 'target',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await PromptBlockPaletteButton.showAt(
          tester.element(find.byKey(const Key('source'))),
          const Rect.fromLTWH(690, 100, 20, 20),
        );
        await tester.pumpAndSettle();

        Future<void> drag(Finder finder, Offset target) async {
          final gesture = await tester.startGesture(
            tester.getCenter(finder),
            kind: PointerDeviceKind.mouse,
          );
          await gesture.moveBy(const Offset(15, 0));
          await tester.pump();
          await gesture.moveTo(target);
          await tester.pumpAndSettle();
          await gesture.up();
          await tester.pumpAndSettle();
        }

        final sourcePill = find.byWidgetPredicate(
          (widget) =>
              widget is Draggable<PromptBlockDragData> &&
              widget.data?.instanceMarker?.scope == PillScopes.main,
        );
        final dropPoint =
            tester.getTopLeft(
              find.byKey(const Key('prompt-block-palette-card')),
            ) +
            const Offset(80, 115);
        expect(
          tester.widget<Draggable<PromptBlockDragData>>(sourcePill).data!.temp,
          isNotNull,
        );
        await drag(sourcePill, dropPoint);
        expect(
          storage.palette,
          isNotEmpty,
          reason:
              'The drop must write the temp snapshot before resolving the palette.',
        );
        var palette = await container.read(
          promptBlockPaletteNotifierProvider.future,
        );
        final id = palette.blocks.single.id;
        final snapshot = palette.temporary[id]!;
        expect(snapshot.content, content.content);
        expect(snapshot.negativeContent, content.negativeContent);
        expect(snapshot.translations, content.translations);
        expect(snapshot.negativeTranslations, content.negativeTranslations);
        expect(snapshot.title, libraryBacked ? original.title : content.title);
        expect(snapshot.color, libraryBacked ? original.color : content.color);
        expect(
          snapshot.iconName,
          libraryBacked ? original.iconName : content.iconName,
        );
        expect(source.state.document.instances['\uE000']!.temp, content);
        source.removeMarker('\uE000');
        if (libraryBacked) {
          await container
              .read(promptBlockLibraryNotifierProvider.notifier)
              .deleteBlock(original.id);
        }
        await tester.pumpAndSettle();

        final chip = find.byKey(ValueKey('prompt-block-pill-body-$id'));
        expect(
          tester
              .widget<UiBlockPill>(
                find.descendant(of: chip, matching: find.byType(UiBlockPill)),
              )
              .temporary,
          isTrue,
        );
        for (var i = 0; i < 2; i++) {
          container.read(pillActiveEditorTargetProvider.notifier).state = (
            scope: PillScopes.main,
            caret: source.state.document.text.length,
          );
          await tester.tap(chip);
          await tester.pumpAndSettle();
        }
        final inserted = source.state.document.instances.entries.toList();
        expect(inserted, hasLength(2));
        expect(
          inserted.every(
            (entry) => entry.value.temporary && entry.value.blockId.isEmpty,
          ),
          isTrue,
        );
        expect(
          inserted.first.value.bundleId,
          isNot(inserted.last.value.bundleId),
        );
        final negative = container.read(
          pillWorkspaceProvider(PillScopes.negative),
        );
        expect(negative.document.instances, hasLength(2));
        expect(
          negative.document.instances.values.every(
            (instance) => instance.temporary && instance.useNegativeContent,
          ),
          isTrue,
        );
        source.editTempContent(inserted.first.key, 'changed copy', null);
        expect(
          source.state.document.instances[inserted.last.key]!.temp,
          snapshot,
        );
        palette = container
            .read(promptBlockPaletteNotifierProvider)
            .requireValue;
        expect(palette.temporary[id], snapshot);

        await drag(
          chip,
          tester.getTopLeft(find.byKey(const Key('target'))) +
              const Offset(80, 35),
        );
        final target = container.read(pillWorkspaceProvider('target'));
        expect(target.document.instances, hasLength(1));
        expect(target.document.instances.values.single.temporary, isTrue);
        expect(target.document.instances.values.single.blockId, isEmpty);
        expect(target.document.instances.values.single.temp, snapshot);
        expect(storage.blocks, isEmpty);
        expect(platform.backups, hasLength(3));
        await unmount();
      },
    );
  }
}

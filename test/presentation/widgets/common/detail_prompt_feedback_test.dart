import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/utils/translation_palette_drop.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_dialog.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_context_menu.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_section.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_translation.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import '../../../helpers/studio_capture_fonts.dart';

class _Storage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
}

const original =
    '1.5::blue eyes, white hair ::,\nAn entire ruined city caught mid-explosion, (floating towers:1.2)';
PillDocument translated(PillDocument doc) => PillDocument(
  text: '\uE000',
  instances: {
    '\uE000': PillInstance(
      blockId: '',
      translation: TranslationPill(
        source: doc.text,
        zh: '1.5::蓝眼睛、白发 ::，\n爆炸中的整座废墟城市与悬浮高楼',
        languageCode: 'zh',
      ),
    ),
  },
);

Widget app({
  required String content,
  required Future<PillDocument> Function(PillDocument, String) translator,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
  GlobalKey? captureKey,
  WidgetBuilder? bodyBuilder,
  PromptBlockStorage? blockStorage,
  bool inspectorStyle = false,
  bool captureOverlay = false,
}) => ProviderScope(
  overrides: [
    localStorageServiceProvider.overrideWithValue(_Storage()),
    detailPromptTranslatorProvider.overrideWithValue(translator),
    if (blockStorage != null)
      promptBlockStorageProvider.overrideWithValue(blockStorage),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.getTheme(AppStyle.geist, brightness),
    builder: bodyBuilder == null && !captureOverlay
        ? null
        : (_, child) => RepaintBoundary(key: captureKey, child: child!),
    home: Scaffold(
      body: bodyBuilder != null
          ? Builder(builder: bodyBuilder)
          : Center(
              child: SizedBox(
                width: inspectorStyle ? 340 : 320,
                child: RepaintBoundary(
                  key: captureOverlay ? null : captureKey,
                  child: Material(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Builder(
                        builder: (context) => PromptSection(
                          title: AppLocalizations.of(
                            context,
                          )!.metadataImport_mainPrompt,
                          icon: Icons.text_fields,
                          content: content,
                          initiallyExpanded: true,
                          inspectorStyle: inspectorStyle,
                          contentStyle: inspectorStyle
                              ? StudioTypography.data
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    ),
  ),
);

void main() {
  testWidgets(
    'detail block storage retains exact source and reading metadata',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('detail_block_store_');
      Hive.init(folder.path);
      final storage = PromptBlockStorage();
      await tester.runAsync(() async {
        await storage.init();
        await storage.putMeta('fixedTagMigrationDone', '1');
        await storage.putMeta('tagLibraryMigrationDone', '1');
      });
      late WidgetRef libraryRef;
      await tester.pumpWidget(
        app(
          content: original,
          translator: (doc, _) async => translated(doc),
          blockStorage: storage,
          bodyBuilder: (_) => Consumer(
            builder: (_, ref, _) {
              libraryRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pill = translated(
        const PillDocument(text: original, instances: {}),
      ).instances.values.single.translation!;
      await tester.runAsync(() async {
        await libraryRef.read(promptBlockLibraryNotifierProvider.future);
        await saveTranslationToBlockLibrary(libraryRef, pill);
        final blocks = await storage.getBlocks();
        expect(blocks, hasLength(1));
        expect(blocks.single.content, original);
        expect(blocks.single.readingTranslationZh, pill.zh);
        expect(blocks.single.appearance, 'translation');
        expect(blocks.single.readingTranslationLanguageCode, 'zh');
        expect(await storage.getPaletteBlockIds(), isEmpty);
      });
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await storage.close();
        await Hive.close();
        folder.deleteSync(recursive: true);
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'details preserves original text and syntax; translation is explicit and draggable',
    (tester) async {
      var requests = 0;
      await tester.pumpWidget(
        app(
          content: original,
          translator: (doc, _) async {
            requests++;
            expect(doc.text, original);
            return translated(doc);
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, 0);
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(UnifiedPromptInput),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(field.readOnly, isTrue);
      expect(field.controller!.text, original);
      expect(find.byTooltip('收藏到词库'), findsNothing);
      await tester.tap(find.byKey(const Key('detail-prompt-translate')));
      await tester.pumpAndSettle();
      expect(requests, 1);
      final draggable = tester.widget<Draggable<PromptBlockDragData>>(
        find.byWidgetPredicate((w) => w is Draggable<PromptBlockDragData>),
      );
      expect(draggable.data!.translation!.source, original);
      expect(find.textContaining('废墟城市'), findsOneWidget);
      await tester.tap(find.textContaining('废墟城市'));
      await tester.pumpAndSettle();
      expect(find.text('存入积木'), findsOneWidget);
      expect(find.byIcon(StudioIcons.promptBlockPalette), findsOneWidget);
      expect(tester.getSize(find.byType(MenuItemButton)).width, lessThan(190));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-prompt-translate')));
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(field.controller!.text, original);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('gallery translation only appears in the hovered prompt region', (
    tester,
  ) async {
    final translateButton = find
        .byKey(const Key('detail-prompt-translate'))
        .hitTestable();
    final requests = <String>[];
    Future<PillDocument> convert(PillDocument doc, String _) async {
      requests.add(doc.text);
      return translated(doc);
    }

    await tester.pumpWidget(
      app(
        content: original,
        translator: convert,
        bodyBuilder: (_) => const SizedBox(),
      ),
    );
    await tester.pumpWidget(
      app(
        content: original,
        translator: convert,
        bodyBuilder: (_) => const Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PromptSection(
                  key: Key('gallery-positive'),
                  title: 'Positive',
                  icon: Icons.text_fields,
                  content: original,
                  inspectorStyle: true,
                ),
                PromptSection(
                  key: Key('gallery-negative'),
                  title: 'Negative',
                  icon: Icons.block,
                  content: 'negative source',
                  inspectorStyle: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(translateButton, findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('gallery-positive'))),
    );
    await tester.pumpAndSettle();
    expect(translateButton, findsOneWidget);
    await tester.tap(translateButton);
    await tester.pumpAndSettle();
    expect(requests, [original]);
    expect(find.text('negative source'), findsOneWidget);
    final block = find.byWidgetPredicate(
      (w) => w is Draggable<PromptBlockDragData>,
    );
    expect(
      tester
          .widget<Draggable<PromptBlockDragData>>(block)
          .data!
          .translation!
          .source,
      original,
    );
    final point = tester.getCenter(find.textContaining('废墟城市'));
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    final action = tester.getRect(find.byType(MenuItemButton));
    expect(action.width, lessThan(190));
    expect(action.left, closeTo(point.dx + 6, 1));
    expect(find.byIcon(StudioIcons.promptBlockPalette), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('gallery-negative'))),
    );
    await tester.pumpAndSettle();
    expect(translateButton, findsOneWidget);
    await tester.tap(translateButton);
    await tester.pumpAndSettle();
    expect(requests, [original, 'negative source']);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(translateButton, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late translation cannot replace a newer image prompt', (
    tester,
  ) async {
    final pending = Completer<PillDocument>();
    Future<PillDocument> convert(PillDocument doc, String _) => pending.future;
    await tester.pumpWidget(app(content: original, translator: convert));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('detail-prompt-translate')));
    await tester.pump();
    await tester.pumpWidget(
      app(content: 'new image prompt', translator: convert),
    );
    await tester.pump();
    pending.complete(
      translated(const PillDocument(text: original, instances: {})),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find
          .descendant(
            of: find.byType(UnifiedPromptInput),
            matching: find.byType(TextField),
          )
          .first,
    );
    expect(field.controller!.text, 'new image prompt');
    expect(find.textContaining('废墟城市'), findsNothing);
  });

  for (final confirm in [false, true]) {
    testWidgets(
      'Anlas dialog returns the explicit ${confirm ? 'continue' : 'cancel'} choice',
      (tester) async {
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async => result = await AnlasCostDialog.show(
                    context,
                    cost: 60,
                    threshold: 50,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('60 Anlas'), findsOneWidget);
        expect(find.text('50 Anlas'), findsOneWidget);
        await tester.tap(find.text(confirm ? 'Continue Generation' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(result, confirm);
      },
    );
  }

  if (Platform.environment['CAPTURE_GALLERY_PROMPTS'] == '1') {
    testWidgets('real-font hovered gallery prompts and compact store menu', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await loadStudioCaptureFonts();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      await tester.binding.setSurfaceSize(const Size(640, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = oldShadows);
      final folder = Directory('.dart_tool/gallery-feedback-captures')
        ..createSync(recursive: true);
      Future<void> capture(GlobalKey key, String name) async {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final rendered = await boundary.toImage(pixelRatio: 2);
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          File(
            '${folder.path}/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
      }

      for (final locale in const [
        Locale('zh'),
        Locale('zh', 'TW'),
        Locale('en'),
        Locale('ja'),
        Locale('ko'),
      ]) {
        for (final brightness in Brightness.values) {
          final key = GlobalKey();
          final name = 'inspector-${locale.toLanguageTag()}-${brightness.name}';
          await tester.pumpWidget(
            app(
              content: original,
              translator: (doc, _) async => translated(doc),
              locale: locale,
              brightness: brightness,
              inspectorStyle: true,
              captureKey: key,
              captureOverlay: true,
            ),
          );
          await tester.pumpAndSettle();
          await capture(key, '$name-original');
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          await mouse.moveTo(tester.getCenter(find.byType(PromptSection)));
          await tester.pumpAndSettle();
          await capture(key, '$name-hover');
          await tester.tap(
            find.byKey(const Key('detail-prompt-translate')).hitTestable(),
          );
          await tester.pumpAndSettle();
          await capture(key, '$name-blocks');
          await tester.tap(find.textContaining('废墟城市'));
          await tester.pumpAndSettle();
          await capture(key, '$name-store');
          expect(
            tester.getSize(find.byType(MenuItemButton)).width,
            lessThan(250),
          );
          expect(tester.takeException(), isNull);
          await mouse.removePointer();
          await tester.pumpWidget(const SizedBox());
        }
      }
      debugDisableShadows = oldShadows;
    });
  }

  if (Platform.environment['CAPTURE_FEEDBACK_UI'] == '1') {
    testWidgets('real-font detail rendering in all locales and both themes', (
      tester,
    ) async {
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = oldShadows);
      await tester.runAsync(() async {
        await loadStudioCaptureFonts();
        final icons = File(
          'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        await (FontLoader(
          'MaterialIcons',
        )..addFont(icons.readAsBytes().then(ByteData.sublistView))).load();
      });
      await tester.binding.setSurfaceSize(const Size(760, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final folder = Directory('.dart_tool/feedback-ui-captures')
        ..createSync(recursive: true);
      Future<void> capture(GlobalKey key, String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${folder.path}/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      for (final locale in const [
        Locale('zh'),
        Locale('zh', 'TW'),
        Locale('en'),
        Locale('ja'),
        Locale('ko'),
      ]) {
        for (final brightness in Brightness.values) {
          final key = GlobalKey();
          await tester.pumpWidget(
            app(
              content: original,
              translator: (doc, _) async => translated(doc),
              locale: locale,
              brightness: brightness,
              captureKey: key,
            ),
          );
          await tester.pumpAndSettle();
          await capture(
            key,
            'detail-original-${locale.toLanguageTag()}-${brightness.name}',
          );
          await tester.tap(find.byKey(const Key('detail-prompt-translate')));
          await tester.pumpAndSettle();
          await capture(
            key,
            'detail-${locale.toLanguageTag()}-${brightness.name}',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          for (final size in const [Size(760, 740), Size(360, 640)]) {
            await tester.binding.setSurfaceSize(size);
            for (final dialog in [false, true]) {
              final overlayKey = GlobalKey();
              await tester.pumpWidget(
                app(
                  content: original,
                  translator: (doc, _) async => translated(doc),
                  locale: locale,
                  brightness: brightness,
                  captureKey: overlayKey,
                  bodyBuilder: (context) => TextButton(
                    onPressed: () => dialog
                        ? AnlasCostDialog.show(context, cost: 60, threshold: 50)
                        : LocalImageContextMenu.show(
                            context,
                            position: const Offset(24, 64),
                            hasImportableMetadata: true,
                            hasPrompt: true,
                            hasSeed: true,
                            isKritaConnected: false,
                          ),
                    child: const Text('Open'),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              await tester.tap(find.text('Open'));
              await tester.pumpAndSettle();
              await capture(
                overlayKey,
                '${dialog ? 'anlas' : 'gallery'}-${locale.toLanguageTag()}-${brightness.name}-${size.width.toInt()}',
              );
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
            }
          }
          await tester.binding.setSurfaceSize(const Size(760, 740));
        }
      }
      debugDisableShadows = oldShadows;
    });
  }
}

import '../../../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_welcome.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/right_panel.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/branding/brand_entry_scene.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// The drag/drop plugin exposes its test transport through this dependency.
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/web_left_panel.dart';
import 'package:nai_launcher/presentation/widgets/anlas/anlas_balance_chip.dart';
import 'package:nai_launcher/presentation/widgets/character/inline_character_card.dart';
import 'package:nai_launcher/presentation/widgets/common/inset_shadow_container.dart';
import 'package:nai_launcher/presentation/widgets/prompt/transparent_background_chip.dart';
import '../../../../helpers/light_theme_contrast.dart';
import '../../../../helpers/official_ui_capture_fonts.dart';

class _Storage extends InMemoryLocalStorageService {
  @override
  String getDefaultModel() => 'nai-diffusion-5-full';
  @override
  bool getEnableAutocomplete() => false;
  @override
  bool getEnableCooccurrenceRecommendation() => false;
  @override
  String getLastPrompt() => 'city lights, scenery, no humans, very aesthetic';
}

class _TokenEncoder implements PromptTokenEncoder {
  @override
  Future<int> countTokens(String text) async => text.split(' ').length;
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Characters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() {
    super.build();
    return const CharacterPromptConfig().addCharacter(
      gender: CharacterGender.female,
      prompt: 'blue eyes, white hair',
    );
  }
}

class _CharacterRepository extends CharacterPromptRepository {
  @override
  CharacterPromptConfig load() => const CharacterPromptConfig();
  @override
  Future<bool> save(CharacterPromptConfig config) async => true;
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

class _Subscription extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(fixedTrainingStepsLeft: 1000),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dragContext = MockMessageChannelContext()
    ..registerMockMethodCallHandler('DropManager', (_) async => null)
    ..registerMockMethodCallHandler('DragManager', (_) async => null);
  setContextOverride(dragContext);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );
  setUpAll(loadOfficialUiCaptureFonts);
  setUp(() async {
    await setUpTemporaryHive();
    await Hive.openBox(StorageKeys.settingsBox);
  });
  for (final dark in [false, true]) {
    testWidgets(
      'borderless generation has usable model header and stable welcome, dark=$dark',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1400, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final mode = ValueNotifier(false);
        addTearDown(mode.dispose);
        final container = createStorageFreeContainer(
          overrides: [
            localStorageServiceProvider.overrideWithValue(_Storage()),
            characterPromptRepositoryProvider.overrideWithValue(
              _CharacterRepository(),
            ),
            promptTokenCounterServiceProvider.overrideWith(
              (ref) async =>
                  PromptTokenCounterService(encoder: _TokenEncoder()),
            ),
            imageGenerationNotifierProvider.overrideWith(_Generation.new),
            characterPromptNotifierProvider.overrideWith(_Characters.new),
            promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
            subscriptionNotifierProvider.overrideWith(_Subscription.new),
            tipEpochProvider.overrideWith((ref) => Stream.value(0)),
            tipDeckProvider.overrideWithValue(TipDeck(seed: 1)),
            for (final target in PromptTokenCountTarget.values)
              promptTokenUsageProvider(target).overrideWith(
                (ref) async =>
                    const PromptTokenUsage(usedTokens: 12, limit: 512),
              ),
          ],
        );
        addTearDown(container.dispose);
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setWebLeftPanelWidth(400);
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setRightPanelExpanded(true);
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setRightPanelWidth(220);
        await tester.runAsync(() async {
          await loadStudioCaptureFonts();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
          await (FontLoader('Harmony')..addFont(
                rootBundle.load('assets/fonts/HarmonyOS_Sans_SC_Regular.ttf'),
              ))
              .load();
          await (FontLoader(
            'StudioIcons',
          )..addFont(rootBundle.load('assets/fonts/StudioIcons.ttf'))).load();
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: (dark ? GeistTheme.dark : GeistTheme.light).copyWith(
                textTheme: (dark ? GeistTheme.dark : GeistTheme.light).textTheme
                    .apply(fontFamily: 'Harmony'),
              ),
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RepaintBoundary(
                key: key,
                child: IntegratedTitleBarShell(
                  child: Scaffold(
                    body: Row(
                      children: [
                        WebLeftPanel(negativeModeNotifier: mode),
                        const Expanded(child: GenerationWelcome()),
                        const RightPanel(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/images/wof_logo_full.png'),
            tester.element(find.byType(BrandLogo)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byType(WebLeftPanel)).dy, 0);
        expect(find.byKey(const Key('tip-welcome-label')), findsOneWidget);
        final welcome = find.byType(GenerationWelcome);
        expect(tester.getTopLeft(welcome).dy, 0);
        final tipBefore = tester
            .widgetList<Text>(
              find.descendant(of: welcome, matching: find.byType(Text)),
            )
            .last
            .data;
        for (final expanded in [true, false]) {
          await container
              .read(layoutStateNotifierProvider.notifier)
              .setRightPanelExpanded(expanded);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester
                .widgetList<Text>(
                  find.descendant(of: welcome, matching: find.byType(Text)),
                )
                .last
                .data,
            tipBefore,
          );
          if (Platform.environment['CAPTURE_BORDERLESS'] == '1') {
            await tester.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 1.25);
              final bytes = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!.buffer.asUint8List();
              File(
                '.dart_tool/borderless-generation-${dark ? 'dark' : 'light'}-${expanded ? 'open' : 'closed'}.png',
              ).writeAsBytesSync(bytes);
              image.dispose();
            });
          }
        }
      },
    );
  }
  for (final width in [320.0, 400.0]) {
    for (final language in ['zh', 'en']) {
      testWidgets(
        'official sidebar renders unified cards and compact controls at $width in $language',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1250));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final mode = ValueNotifier(false);
          addTearDown(mode.dispose);
          final container = createStorageFreeContainer(
            overrides: [
              localStorageServiceProvider.overrideWithValue(_Storage()),
              characterPromptRepositoryProvider.overrideWithValue(
                _CharacterRepository(),
              ),
              promptTokenCounterServiceProvider.overrideWith(
                (ref) async =>
                    PromptTokenCounterService(encoder: _TokenEncoder()),
              ),
              imageGenerationNotifierProvider.overrideWith(_Generation.new),
              characterPromptNotifierProvider.overrideWith(_Characters.new),
              promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
              subscriptionNotifierProvider.overrideWith(_Subscription.new),
              tipEpochProvider.overrideWith((ref) => Stream.value(0)),
              tipDeckProvider.overrideWithValue(TipDeck(seed: 1)),
              for (final target in PromptTokenCountTarget.values)
                promptTokenUsageProvider(target).overrideWith(
                  (ref) async =>
                      const PromptTokenUsage(usedTokens: 12, limit: 512),
                ),
            ],
          );
          await container
              .read(layoutStateNotifierProvider.notifier)
              .setWebLeftPanelWidth(width);
          addTearDown(container.dispose);
          final boundary = GlobalKey();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(
                key: boundary,
                child: MaterialApp(
                  theme: officialUiCaptureTheme(),
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: WebLeftPanel(negativeModeNotifier: mode),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          expect(
            container.read(generationParamsNotifierProvider).prompt,
            'city lights, scenery, no humans, very aesthetic',
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(WebLeftPanel)),
          )!;
          final title = tester.widget<Text>(
            find.text(l10n.generation_moduleImage),
          );
          expect(title.style!.fontSize, 13);
          expect(title.style!.fontWeight, FontWeight.w600);
          expect(find.text(l10n.generation_imageSize), findsNothing);
          expect(find.text(l10n.generation_perRequestLabel), findsOneWidget);
          expect(find.byIcon(Icons.more_horiz), findsWidgets);
          final promptCard = find.byKey(const ValueKey('main-prompt-card'));
          expect(
            find.descendant(
              of: promptCard,
              matching: find.byType(InsetShadowContainer),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(InlineCharacterCard),
              matching: find.byType(InsetShadowContainer),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(TransparentBackgroundChip),
              matching: find.byType(Text),
            ),
            findsNothing,
          );
          // 一体式提示词卡最低高度随宽度走，接近方框
          final cardSize = tester.getSize(promptCard);
          expect(cardSize.height / cardSize.width, inInclusiveRange(.6, 1.1));
          expect(find.text('12 / 512'), findsNothing);
          expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
          // 额度胶囊：与 Model / Mode 选择框同款的灰底描边壳
          final theme = Theme.of(tester.element(find.byType(WebLeftPanel)));
          final capsule =
              tester
                      .widget<Container>(
                        find
                            .ancestor(
                              of: find.byType(AnlasBalanceChip),
                              matching: find.byType(Container),
                            )
                            .first,
                      )
                      .decoration!
                  as BoxDecoration;
          expect(capsule.color, theme.colorScheme.surfaceContainerLowest);
          expect(
            (capsule.border! as Border).top.color,
            theme.colorScheme.outline.withValues(alpha: 0.4),
          );
          if (Platform.environment['CAPTURE_OFFICIAL_UI'] == '1') {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '.dart_tool/official-ui-captures/sidebar-$language-$width.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          if (width == 400 && language == 'zh') {
            final add = find.byKey(const ValueKey('add-character-menu'));
            final sample = tester.getTopLeft(add) + const Offset(8, 8);
            Future<int> redAtButton() async => (await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()
                          as RenderRepaintBoundary)
                      .toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              final red = data!.getUint8(
                (sample.dy.toInt() * image.width + sample.dx.toInt()) * 4,
              );
              image.dispose();
              return red;
            }))!;
            final normal = await redAtButton();
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            await mouse.moveTo(tester.getCenter(add));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 250));
            expect(
              await redAtButton(),
              officialUiCaptureTheme().brightness == Brightness.dark
                  ? greaterThan(normal)
                  : lessThan(normal),
            );
            await tester.pump(const Duration(seconds: 2));
            expect(find.text(l10n.character_addCharacter), findsOneWidget);
            if (Platform.environment['CAPTURE_OFFICIAL_UI'] == '1') {
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '.dart_tool/official-ui-captures/sidebar-add-hover.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                image.dispose();
              });
            }
            await mouse.removePointer();
            await tester.pumpAndSettle();
            container
                .read(characterPromptNotifierProvider.notifier)
                .clearAllCharacters();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(InlineCharacterCard), findsNothing);
            expect(find.text(l10n.character_positionLabel), findsNothing);
            await tester.tap(find.byKey(const ValueKey('add-character-menu')));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            expect(
              find.text(l10n.characterEditor_genderFemale),
              findsOneWidget,
            );
            expect(find.text(l10n.characterEditor_genderMale), findsOneWidget);
            expect(find.text(l10n.characterEditor_genderOther), findsOneWidget);
            await tester.tap(find.text(l10n.characterEditor_genderFemale));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            final character = container
                .read(characterPromptNotifierProvider)
                .characters
                .single;
            expect(character.gender, CharacterGender.female);
            expect(find.byType(InlineCharacterCard), findsOneWidget);
            expect(find.text(l10n.character_positionLabel), findsOneWidget);
            final editor = find.descendant(
              of: find.byKey(
                ValueKey('character-pill-char:${character.id}:pos'),
              ),
              matching: find.byType(TextField),
            );
            await tester.enterText(editor, 'blue eyes, white hair');
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 350));
            expect(
              container
                  .read(characterPromptNotifierProvider)
                  .characters
                  .single
                  .prompt,
              'blue eyes, white hair',
            );
            final counted = container
                .read(
                  characterPromptTokenUsageProvider((
                    characterId: character.id,
                    negative: false,
                  )),
                )
                .valueOrNull;
            expect(counted?.usedTokens, 4);
            expect(
              container.read(generationParamsNotifierProvider).prompt,
              'city lights, scenery, no humans, very aesthetic',
            );
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        },
      );
    }
  }
}

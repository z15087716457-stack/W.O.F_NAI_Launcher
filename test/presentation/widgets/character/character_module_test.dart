import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_module_card.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/character/inline_character_section.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/light_theme_contrast.dart';

const prototypeCharacterPrompt =
    'girl, 1.5::loli,child::, 1.4::silver hair::, 1.3::long hair::,\n0.3::fluffy hair, messy hair::, pale skin, hair between eyes, blue eyes, blush,  black capelet, blue butterfly brooch, white blouse, ruffled shirt, long sleeves, frilled cuffs, collar bow, black bow, high-waist skirt, black pinstripe skirt, pleated skirt, frilled hem, 2::black pantyhose::, black mary janes, -1::twintails, headpiece, headdress::';

class _Storage extends InMemoryLocalStorageService {
  @override
  String getDefaultModel() => 'nai-diffusion-5-full';
  @override
  bool getEnableAutocomplete() => false;
  @override
  bool getEnableCooccurrenceRecommendation() => false;
}

class _Repository extends CharacterPromptRepository {
  _Repository(this.value);
  CharacterPromptConfig value;
  @override
  CharacterPromptConfig load() => value;
  @override
  Future<bool> save(CharacterPromptConfig next) async {
    value = next;
    return true;
  }
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [], folders: []);
}

class _Tokens implements PromptTokenEncoder {
  @override
  Future<int> countTokens(String text) async => 46;
}

ProviderContainer characterModuleContainer(int count, {bool mixed = false}) {
  final repository = _Repository(
    CharacterPromptConfig(
      characters: [
        for (var i = 0; i < count; i++)
          CharacterPrompt(
            id: 'char-$i',
            name: '',
            prompt: prototypeCharacterPrompt,
            enabled: !mixed || i != 1,
            thumbnailPath: mixed && i == 2
                ? '${Directory.current.path}/../../mockups/generation/assets/g07.jpg'
                : null,
          ),
      ],
    ),
  );
  return createStorageFreeContainer(
    overrides: [
      localStorageServiceProvider.overrideWithValue(_Storage()),
      characterPromptRepositoryProvider.overrideWithValue(repository),
      promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
      promptTokenCounterServiceProvider.overrideWith(
        (ref) async => PromptTokenCounterService(encoder: _Tokens()),
      ),
      tipEpochProvider.overrideWith((ref) => Stream.value(0)),
      tipDeckProvider.overrideWithValue(TipDeck(seed: 1)),
    ],
  );
}

Widget characterModuleShell(
  ProviderContainer container, {
  double width = 420,
  String language = 'zh',
  bool dark = false,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    key: ValueKey('$width-$language-$dark'),
    theme: dark ? GeistTheme.dark : GeistTheme.light,
    themeAnimationDuration: Duration.zero,
    locale: Locale(language),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RepaintBoundary(
        key: const Key('capture'),
        child: ColoredBox(
          color: dark
              ? GeistTheme.dark.colorScheme.surface
              : GeistTheme.light.colorScheme.surface,
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: dark
                            ? GeistTheme.dark.dividerColor
                            : GeistTheme.light.dividerColor,
                      ),
                    ),
                  ),
                  child: const InlineCharacterSection(),
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
  setUpAll(loadStudioCaptureFonts);
  setUp(setUpTemporaryHive);
  testWidgets(
    'module count, tooltip, measured wrap and V5 additions over six',
    (tester) async {
      final container = characterModuleContainer(7);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        characterModuleShell(container, width: 352, language: 'en'),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('character-position-row')),
        findsOneWidget,
      );
      final card = tester.widget<GenerationModuleCard>(
        find.byType(GenerationModuleCard),
      );
      expect(card.count, 7);
      expect(card.titleTooltip, isNotEmpty);
      await tester.tap(find.byKey(const ValueKey('add-character-menu')));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(InlineCharacterSection)),
      )!;
      await tester.tap(find.text(l10n.characterEditor_genderFemale));
      await tester.pumpAndSettle();
      expect(
        container.read(characterPromptNotifierProvider).characters.length,
        8,
      );
      expect(
        tester
            .widget<GenerationModuleCard>(find.byType(GenerationModuleCard))
            .count,
        8,
      );
      await tester.pumpWidget(characterModuleShell(container, width: 560));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('character-position-row')),
        findsNothing,
      );
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel('nai-diffusion-3', persist: false);
      await tester.pumpAndSettle();
      expect(find.byType(GenerationModuleCard), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'editing uses a whole-card tint and disabled characters remain 48 percent',
    (tester) async {
      final container = characterModuleContainer(3, mixed: true);
      addTearDown(container.dispose);
      container.read(selectedCharacterIdProvider.notifier).select('char-0');
      await tester.pumpWidget(characterModuleShell(container, width: 420));
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('char-0'));
      final decoration =
          tester
                  .widget<AnimatedContainer>(
                    find
                        .descendant(
                          of: first,
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.borderRadius, isNull);
      expect(
        decoration.color,
        GeistTheme.light.colorScheme.onSurface.withValues(alpha: .03),
      );
      final second = find.byKey(const ValueKey('char-1'));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find
                  .descendant(
                    of: second,
                    matching: find.byType(AnimatedOpacity),
                  )
                  .first,
            )
            .opacity,
        .48,
      );
      expect(tester.takeException(), isNull);
    },
  );
  if (Platform.environment['CAPTURE_UIUX_CHARACTER'] == '1') {
    testWidgets(
      'capture 0, 1 and 3 roles in four languages and three sidebar widths',
      (tester) async {
        final root = Directory('.dart_tool/uiux-task04/captures')
          ..createSync(recursive: true);
        final measurements = <Map<String, Object?>>[];
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        for (final language in ['zh', 'en', 'ja', 'ko']) {
          for (final dark in [false, true]) {
            for (final width in [352.0, 420.0, 560.0]) {
              for (final count in [0, 1, 3]) {
                tester.view.physicalSize = Size(width, 2400);
                final container = characterModuleContainer(
                  count,
                  mixed: count == 3,
                );
                if (count == 3) {
                  container
                      .read(selectedCharacterIdProvider.notifier)
                      .select('char-0');
                }
                if (count == 3) {
                  await tester.runAsync(
                    () => precacheImage(
                      ResizeImage.resizeIfNeeded(
                        (width - 27).round(),
                        null,
                        FileImage(
                          File(
                            '${Directory.current.path}/../../mockups/generation/assets/g07.jpg',
                          ),
                        ),
                      ),
                      tester.element(find.byType(SizedBox).first),
                    ).timeout(const Duration(seconds: 5)),
                  );
                }
                await tester.pumpWidget(
                  characterModuleShell(
                    container,
                    width: width,
                    language: language,
                    dark: dark,
                  ),
                );
                await tester.pumpAndSettle();
                if (count == 3) {
                  await tester.runAsync(
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 100)),
                  );
                  await tester.pump();
                  await tester.runAsync(
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 50)),
                  );
                  await tester.pump();
                  expect(
                    tester.widget<RawImage>(find.byType(RawImage)).image,
                    isNotNull,
                  );
                }
                expect(tester.takeException(), isNull);
                final rect = tester.getRect(find.byType(GenerationModuleCard));
                final name =
                    'character-$count-$language-${dark ? 'dark' : 'light'}-${width.toInt()}';
                measurements.add({
                  'name': name,
                  'locale': language,
                  'dark': dark,
                  'count': count,
                  'secondRow': find
                      .byKey(const ValueKey('character-position-row'))
                      .evaluate()
                      .isNotEmpty,
                  'module': {
                    'x': rect.left,
                    'y': rect.top,
                    'width': rect.width,
                    'height': rect.height,
                  },
                });
                await tester.runAsync(() async {
                  final image = await tester
                      .renderObject<RenderRepaintBoundary>(
                        find.byKey(const Key('capture')),
                      )
                      .toImage(pixelRatio: 1);
                  try {
                    final data = await image.toByteData(
                      format: ui.ImageByteFormat.png,
                    );
                    File(
                      '${root.path}/$name.png',
                    ).writeAsBytesSync(data!.buffer.asUint8List());
                  } finally {
                    image.dispose();
                  }
                });
                await tester.pumpWidget(const SizedBox());
                await tester.pumpAndSettle();
                container.dispose();
              }
            }
          }
        }
        File(
          '.dart_tool/uiux-task04/capture-measurements.json',
        ).writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(measurements),
        );
      },
    );
  }
}

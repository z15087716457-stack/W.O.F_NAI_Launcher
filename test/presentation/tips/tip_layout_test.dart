import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_welcome.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/web_left_panel.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/themes/studio_typography.dart';
import 'package:nai_launcher/presentation/widgets/branding/brand_entry_scene.dart';

import '../../helpers/light_theme_contrast.dart';
import '../../helpers/studio_capture_fonts.dart';

class _Storage extends InMemoryLocalStorageService {
  @override
  String getDefaultModel() => 'nai-diffusion-5-full';
  @override
  bool getEnableAutocomplete() => false;
  @override
  bool getEnableCooccurrenceRecommendation() => false;
  @override
  String getLastPrompt() => '';
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
      prompt: '',
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

/// Shows exactly the forced tip wherever a surface asks for one.
class _FixedDeck extends TipDeck {
  _FixedDeck(this.forced) : super(seed: 1);
  final Map<TipSurface, Tip> forced;

  @override
  Tip tipAt(
    TipSurface surface,
    int index, {
    DateTime? now,
    bool shortOnly = false,
    TipKind? kind,
  }) =>
      forced[surface] ??
      super.tipAt(surface, index, now: now, shortOnly: shortOnly, kind: kind);
}

final _forced = StateProvider<Map<TipSurface, Tip>>((ref) => const {});

ThemeData _theme() => GeistTheme.light.copyWith(
  textTheme: GeistTheme.light.textTheme.apply(
    fontFamily: StudioTypography.sans,
    fontFamilyFallback: StudioTypography.fallback,
  ),
);

int _lines(String text, TextStyle style, double width) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(
        fontFamily: StudioTypography.sans,
        fontFamilyFallback: StudioTypography.fallback,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final lines = painter.computeLineMetrics().length;
  painter.dispose();
  return lines;
}

final _captureKey = GlobalKey();

/// CAPTURE_TIPS=1 时把画面存到 .dart_tool/tips-captures/ 供人工核对。
Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_TIPS'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.25);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/tips-captures/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Tip _longest(TipSurface surface, AppLocalizations l10n) => tipsFor(
  surface,
).reduce((a, b) => a.text(l10n).length >= b.text(l10n).length ? a : b);

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
  setUp(() async {
    await setUpTemporaryHive();
    await Hive.openBox(StorageKeys.settingsBox);
  });

  Future<void> loadFonts(WidgetTester tester) => tester.runAsync(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('prompt and character boxes hold every tip without growing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await loadFonts(tester);
    final container = createStorageFreeContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(_Storage()),
        characterPromptRepositoryProvider.overrideWithValue(
          _CharacterRepository(),
        ),
        promptTokenCounterServiceProvider.overrideWith(
          (ref) async => PromptTokenCounterService(encoder: _TokenEncoder()),
        ),
        imageGenerationNotifierProvider.overrideWith(_Generation.new),
        characterPromptNotifierProvider.overrideWith(_Characters.new),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        subscriptionNotifierProvider.overrideWith(_Subscription.new),
        tipEpochProvider.overrideWith((ref) => Stream.value(0)),
        tipDeckProvider.overrideWith((ref) => _FixedDeck(ref.watch(_forced))),
        for (final target in PromptTokenCountTarget.values)
          promptTokenUsageProvider(target).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setWebLeftPanelWidth(400);
    final mode = ValueNotifier(false);
    addTearDown(mode.dispose);
    final locale = StateProvider((ref) => const Locale('zh'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: _theme(),
            locale: ref.watch(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RepaintBoundary(
              key: _captureKey,
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: WebLeftPanel(negativeModeNotifier: mode),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('main-prompt-card'));
    final cardSize = tester.getSize(card);
    // 一体式布局：提示词卡接近方框（截图口径高 ≈ 0.7 × 宽）
    expect(cardSize.height / cardSize.width, inInclusiveRange(.62, .8));

    final characterField = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'character-pill-char:',
          ) &&
          (widget.key! as ValueKey<String>).value.endsWith(':pos'),
    );
    expect(characterField, findsOneWidget);

    final heights = <TipSurface, Map<double, String>>{
      TipSurface.prompt: {},
      TipSurface.character: {},
    };
    for (final value in AppLocalizations.supportedLocales) {
      container.read(locale.notifier).state = value;
      final l10n = lookupAppLocalizations(value);
      for (final surface in heights.keys) {
        final field = surface == TipSurface.prompt ? card : characterField;
        for (final tip in tipsFor(surface)) {
          container.read(_forced.notifier).state = {surface: tip};
          await tester.pump();
          expect(tester.takeException(), isNull);
          heights[surface]![tester.getSize(field).height] =
              '$value ${tip.hint(l10n)}';
        }
      }
    }
    // 每条贴士都放得下：框的高度从不因为贴士变长而改变
    expect(heights[TipSurface.prompt]!.keys, [cardSize.height]);
    expect(heights[TipSurface.character], hasLength(1));

    for (final value in const [Locale('zh'), Locale('en'), Locale('ko')]) {
      final l10n = lookupAppLocalizations(value);
      container.read(locale.notifier).state = value;
      container.read(_forced.notifier).state = {
        TipSurface.prompt: _longest(TipSurface.prompt, l10n),
        TipSurface.character: _longest(TipSurface.character, l10n),
      };
      await tester.pump();
      await _capture(tester, 'prompt-${value.toLanguageTag()}');
    }
  });

  testWidgets('STUDIO welcome keeps its logo still', (tester) async {
    await tester.binding.setSurfaceSize(const Size(780, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await loadFonts(tester);
    final container = ProviderContainer(
      overrides: [
        tipDeckProvider.overrideWith((ref) => _FixedDeck(ref.watch(_forced))),
      ],
    );
    addTearDown(container.dispose);
    const surface = TipSurface.studio;
    final logo = find.byType(BrandLogo);

    Future<Rect> show(Locale locale, Tip tip, Size size) async {
      await tester.binding.setSurfaceSize(size);
      container.read(_forced.notifier).state = {surface: tip};
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: _theme(),
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RepaintBoundary(
              key: _captureKey,
              child: Scaffold(
                body: KeyedSubtree(
                  // 每条贴士重新挂载一次欢迎页，模拟再次进入
                  key: ValueKey('$locale-${tip.hashCode}'),
                  child: const GenerationWelcome(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      return tester.getRect(logo);
    }

    final shortest = tipsFor(surface).first;
    final reference = await show(
      const Locale('zh'),
      shortest,
      const Size(780, 900),
    );
    for (final locale in AppLocalizations.supportedLocales) {
      for (final tip in tipsFor(surface)) {
        final rect = await show(locale, tip, const Size(780, 900));
        expect(
          (rect.topLeft - reference.topLeft).distance,
          lessThan(.01),
          reason: '$locale logo moved',
        );
        final text = find.byKey(const Key('tip-welcome-text'));
        expect(
          tester.getRect(text).bottom,
          lessThanOrEqualTo(900),
          reason: '$locale ${tip.text(lookupAppLocalizations(locale))}',
        );
        // 矮窗口：Logo 不缩小，内容改为滚动
        final short = await show(locale, tip, const Size(780, 420));
        expect(short.width, closeTo(reference.width, .01));
        expect(short.height, closeTo(reference.height, .01));
      }
      final l10n = lookupAppLocalizations(locale);
      await show(locale, _longest(surface, l10n), const Size(780, 900));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/wof_logo_full.png'),
          tester.element(find.byType(Scaffold)),
        ),
      );
      await tester.pump();
      await _capture(tester, 'studio-${locale.toLanguageTag()}');
    }
  });

  testWidgets('splash and single-line tips fit their slots', (tester) async {
    await loadFonts(tester);
    final offenders = <String>[];
    void check(bool fits, String what) {
      if (!fits) offenders.add(what);
    }

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      for (final tip in tipsFor(TipSurface.splash)) {
        check(
          _lines(
                tip.hint(l10n),
                const TextStyle(fontSize: 12, height: 1.45),
                340,
              ) <=
              2,
          'splash $locale ${tip.hint(l10n)}',
        );
      }
      // 搜索框扣掉前后图标后的可写宽度：块库侧栏默认 320px 宽。
      for (final (surface, width) in [
        (TipSurface.gallerySearch, 300.0),
        (TipSurface.onlineSearch, 320.0),
        (TipSurface.blockSearch, 250.0),
      ]) {
        for (final tip in tipsFor(surface)) {
          check(
            _lines(tip.hint(l10n), const TextStyle(fontSize: 13), width) == 1,
            '$surface $locale ${tip.hint(l10n)}',
          );
        }
      }
      for (final tip in tipsFor(TipSurface.generating)) {
        check(
          _lines(tip.text(l10n), const TextStyle(fontSize: 14), 300) <= 2,
          'generating $locale ${tip.text(l10n)}',
        );
      }
    }
    for (final offender in offenders) {
      debugPrint('TOO LONG: $offender');
    }
    expect(offenders, isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/services/danbooru_tags_lazy_service.dart';
import 'package:nai_launcher/core/services/smart_tag_recommendation_service.dart';
import 'package:nai_launcher/data/models/tag/local_tag.dart';
import 'package:nai_launcher/data/models/tag/tag_suggestion.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/danbooru_suggestion_provider.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/autocomplete_config.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/autocomplete_utils.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/generic_suggestion_tile.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/strategies/cooccurrence_strategy.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/strategies/danbooru_strategy.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/strategies/local_tag_strategy.dart';

class _WidgetRef extends Mock implements WidgetRef {}

class _TagService extends Mock implements DanbooruTagsLazyService {}

class _RelatedService extends Mock implements SmartTagRecommendationService {}

class _Subscription extends Mock
    implements ProviderSubscription<TagSuggestionState> {}

class _DanbooruNotifier extends Mock implements DanbooruSuggestionNotifier {}

void main() {
  late _WidgetRef ref;
  late _TagService tags;
  late _DanbooruNotifier notifier;

  setUpAll(() {
    registerFallbackValue(
      (TagSuggestionState? previous, TagSuggestionState next) {},
    );
  });
  setUp(() {
    ref = _WidgetRef();
    tags = _TagService();
    notifier = _DanbooruNotifier();
    when(
      () => ref.read(danbooruTagsLazyServiceProvider.future),
    ).thenAnswer((_) async => tags);
    when(
      () => ref.watch(smartTagRecommendationServiceProvider.future),
    ).thenAnswer((_) async => _RelatedService());
    when(
      () => ref.listenManual<TagSuggestionState>(
        danbooruSuggestionNotifierProvider,
        any(),
      ),
    ).thenReturn(_Subscription());
    when(
      () => ref.read(danbooruSuggestionNotifierProvider),
    ).thenReturn(const TagSuggestionState());
    when(
      () => ref.read(danbooruSuggestionNotifierProvider.notifier),
    ).thenReturn(notifier);
  });

  test('local strategy uses canonical queries and space insertion', () async {
    final strategy = await LocalTagStrategy.create(
      ref,
      const AutocompleteConfig(),
    );
    addTearDown(strategy.dispose);
    when(
      () => tags.searchTags('long_ha', limit: 20),
    ).thenAnswer((_) async => [const LocalTag(tag: 'long_hair')]);
    const text = '1.2::artist:a, long_ha::, old_tag';
    final cursor = text.indexOf('long_ha') + 7;
    await strategy.search(text, cursor, immediate: true);
    verify(() => tags.searchTags('long_ha', limit: 20)).called(1);
    final suggestion = strategy.suggestions.single;
    expect(strategy.toSuggestionData(suggestion).tag, 'long_hair');
    expect(
      strategy.applySuggestion(suggestion, text, cursor).$1,
      '1.2::artist:a, long hair::, old_tag',
    );
  });

  test('local strategy respects explicit search semantics', () async {
    final strategy = await LocalTagStrategy.create(
      ref,
      const AutocompleteConfig(
        treatSpacesAsSeparators: true,
        autoInsertComma: false,
        replaceUnderscoreWithSpace: true,
      ),
    );
    addTearDown(strategy.dispose);
    expect(
      strategy
          .applySuggestion(
            const LocalTag(tag: 'long_hair'),
            'foot_focus lo -comic',
            13,
          )
          .$1,
      'foot_focus long_hair -comic',
    );
  });

  test('legacy range and wrappers survive numeric closures', () {
    for (final entry in {
      '{2::blu}': '{2::feet 2 ::}, ',
      '2::{blu}': '2::{feet 2}::, ',
      '2::blu::': '2::feet 2 ::, ',
      '2::blu ::': '2::feet 2 ::, ',
      '1.2::artist:a, 1girl::, blu': '1.2::artist:a, 1girl::, feet 2, ',
    }.entries) {
      final cursor = entry.key.indexOf('blu') + 3;
      final range = AutocompleteUtils.findTagRange(entry.key, cursor);
      expect(entry.key.substring(range.$1, range.$2), 'blu');
      expect(AutocompleteUtils.getCurrentTag(entry.key, cursor), 'blu');
      expect(
        AutocompleteUtils.applySuggestion(
          text: entry.key,
          cursorPosition: cursor,
          suggestion: const LocalTag(tag: 'feet_2'),
          config: const AutocompleteConfig(),
        ).$1,
        entry.value,
      );
    }
  });

  test('Danbooru prompt mode shares precise weighted completion', () async {
    final strategy = DanbooruStrategy.create(ref, promptMode: true);
    addTearDown(strategy.dispose);
    const text = '1.2::artist:a, blu::, old_tag';
    final cursor = text.indexOf('blu') + 3;
    await strategy.search(text, cursor, immediate: true);
    verify(() => notifier.search('blu', immediate: true)).called(1);
    expect(
      strategy
          .applySuggestion(const TagSuggestion(tag: 'feet_2'), text, cursor)
          .$1,
      '1.2::artist:a, feet 2 ::, old_tag',
    );
    expect(
      strategy
          .applySuggestion(
            const TagSuggestion(tag: 'blue_eyes'),
            '<my_preset,other>',
            5,
          )
          .$1,
      '<my_preset,other>',
    );
  });

  test(
    'Danbooru search preserves canonical tags and other separators',
    () async {
      final strategy = DanbooruStrategy.create(ref, separator: ',');
      addTearDown(strategy.dispose);
      const text = 'rating:g  foot_focus, lo\t-comic';
      final cursor = text.indexOf('lo') + 2;
      await strategy.search(text, cursor, immediate: true);
      verify(() => notifier.search('lo', immediate: true)).called(1);
      expect(
        strategy
            .applySuggestion(
              const TagSuggestion(tag: 'long_hair'),
              text,
              cursor,
            )
            .$1,
        'rating:g  foot_focus, long_hair\t-comic',
      );
    },
  );

  test(
    'Danbooru caret inside separators never combines adjacent tags',
    () async {
      final strategy = DanbooruStrategy.create(ref, separator: ',');
      addTearDown(strategy.dispose);
      const text = 'foot_focus  -comic';
      final cursor = text.indexOf('  ') + 1;
      await strategy.search(text, cursor, immediate: true);
      verify(() => notifier.clear()).called(1);
      expect(
        strategy
            .applySuggestion(
              const TagSuggestion(tag: 'long_hair'),
              text,
              cursor,
            )
            .$1,
        'foot_focus long_hair -comic',
      );
    },
  );

  test(
    'cooccurrence inserts display tags without changing original weights',
    () {
      final strategy = CooccurrenceStrategy.create(
        ref,
        const AutocompleteConfig(autoInsertComma: false),
      );
      addTearDown(strategy.dispose);
      const item = RecommendedTag(tag: 'long_hair', score: 1, cooccurrence: 10);
      const text = '1.2::blue_hair, old_tag::';
      expect(strategy.toSuggestionData(item).tag, 'long_hair');
      expect(
        strategy.applySuggestion(item, text, text.indexOf(',') + 2).$1,
        '1.2::blue_hair, long hair, old_tag::',
      );
      const empty = '1.2::blue_hair, ::';
      expect(
        strategy
            .applySuggestion(
              const RecommendedTag(tag: 'feet_2', score: 1, cooccurrence: 10),
              empty,
              empty.indexOf(',') + 2,
            )
            .$1,
        '1.2::blue_hair, feet 2 ::',
      );
    },
  );

  testWidgets('legacy tiles display spaces but keep library names intact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              GenericSuggestionTile(
                data: const SuggestionData(
                  tag: 'long_hair',
                  category: 0,
                  count: 1,
                ),
                isSelected: false,
                onTap: () {},
                config: const AutocompleteConfig(),
              ),
              GenericSuggestionTile(
                data: const SuggestionData(
                  tag: 'my_preset',
                  category: SuggestionData.categoryLibrary,
                  count: 1,
                ),
                isSelected: false,
                onTap: () {},
                config: const AutocompleteConfig(),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('long hair', findRichText: true), findsOneWidget);
    expect(find.text('my_preset', findRichText: true), findsOneWidget);
    expect(find.text('my preset', findRichText: true), findsNothing);
  });
}

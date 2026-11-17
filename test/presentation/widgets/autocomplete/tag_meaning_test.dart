import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_category_visuals.dart';
import 'package:nai_launcher/presentation/widgets/autocomplete/tag_meaning.dart';

import '../../../helpers/tag_meaning_fixtures.dart';

const _candidate = CompletionCandidate(
  canonicalTag: 'underwear',
  category: TagCategory.general,
  postCount: 100,
  matchKind: CompletionMatchKind.englishExact,
  sources: {CompletionSourceKind.base},
);

class _Repository extends TagSemanticsRepository {
  _Repository() : super(() async => 'unused');
  TagSemanticProfile? profile = meaningFixture('underwear');
  final reads = <String>[];
  @override
  Future<TagSemanticProfile?> find(String tag) async {
    reads.add(tag);
    return profile;
  }
}

class _Queue extends ChangeNotifier implements AutoTagTranslationController {
  String? definition;
  @override
  String? definitionFor(String tag) => definition;
  @override
  TagTranslationActivity? activityFor(String tag, {bool wiki = false}) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('local reference refreshes after the existing queue fills it', () async {
    final queue = _Queue();
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        autoTagTranslationProvider.overrideWith((_) => queue),
        tagSemanticsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final provider = tagMeaningProfileProvider('underwear');
    final subscription = container.listen(provider, (_, next) {});
    addTearDown(subscription.close);
    expect(
      (await container.read(provider.future))!.summaryZh,
      repository.profile!.summaryZh,
    );
    repository.profile = meaningFixture('underwear', summary: '已有翻译队列补缺后的释义');
    queue.definition = repository.profile!.summaryZh;
    queue.notifyListeners();
    expect(
      (await container.read(provider.future))!.summaryZh,
      queue.definition,
    );
    expect(repository.reads, ['underwear', 'underwear']);
    // No observe/enqueue method is implemented: a second queue would fail.
  });

  for (final compact in [false, true]) {
    testWidgets('meaning content compact=$compact', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tagMeaningProfileProvider.overrideWith(
              (_, tag) async => meaningFixture(tag),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 260,
                child: TagMeaning(candidate: _candidate, compact: compact),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('穿在衣服下面的衣物，通常直接接触皮肤。'), findsOneWidget);
      expect(find.text('内衣、贴身衣物、内裤'), findsOneWidget);
      expect(find.text('同义词'), compact ? findsNothing : findsOneWidget);
      final context = tester.element(find.byType(TagMeaning));
      expect(
        find.text(TagCategoryVisuals.label(context, TagCategory.general)),
        compact ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('missing compact meaning leaves no blank row', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagMeaningProfileProvider.overrideWith((_, tag) async => null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: TagMeaning(candidate: _candidate, compact: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(TagMeaning)), Size.zero);
    expect(tester.takeException(), isNull);
  });
}

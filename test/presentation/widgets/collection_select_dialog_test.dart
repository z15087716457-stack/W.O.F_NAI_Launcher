import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/repositories/collection_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/widgets/collection_select_dialog.dart';

class _MockCollectionRepository extends Mock implements CollectionRepository {}

void main() {
  late _MockCollectionRepository repository;

  setUp(() {
    repository = _MockCollectionRepository();
    when(
      () => repository.getAllCollections(),
    ).thenAnswer((_) async => <ImageCollection>[]);
    when(
      () => repository.countMembershipByPaths(any()),
    ).thenAnswer((_) async => <String, int>{});
  });

  Future<void> pumpAndOpen(
    WidgetTester tester, {
    bool isRemoveMode = false,
    int favoriteCountInSelection = 0,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [collectionRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Center(
                child: Builder(
                  builder: (context) => FilledButton(
                    onPressed: () {
                      CollectionSelectDialog.show(
                        context,
                        theme: Theme.of(context),
                        isRemoveMode: isRemoveMode,
                        selectedImagePaths: isRemoveMode
                            ? const ['a.png', 'b.png']
                            : const [],
                        favoriteCountInSelection: favoriteCountInSelection,
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('remove mode shows favorites root entry with member count', (
    tester,
  ) async {
    await pumpAndOpen(tester, isRemoveMode: true, favoriteCountInSelection: 3);

    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('选中 3 张在此收藏'), findsOneWidget);
  });

  testWidgets('tapping favorites root pops with isFavoriteRoot result', (
    tester,
  ) async {
    CollectionSelectResult? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [collectionRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await CollectionSelectDialog.show(
                      context,
                      theme: Theme.of(context),
                      isRemoveMode: true,
                      selectedImagePaths: const ['a.png'],
                      favoriteCountInSelection: 1,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.isFavoriteRoot, isTrue);
    expect(result!.collectionName, '收藏');
  });

  testWidgets('favorites root entry respects search filter', (tester) async {
    await pumpAndOpen(tester, isRemoveMode: true, favoriteCountInSelection: 1);

    await tester.enterText(find.byType(TextField), '不存在');
    await tester.pump();

    expect(find.text('收藏'), findsNothing);
  });

  testWidgets('add mode does not show favorites root entry', (tester) async {
    await pumpAndOpen(tester);
    expect(find.text('收藏'), findsNothing);
  });
}

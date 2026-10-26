import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/repositories/collection_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_favorite_menu.dart';

import '../../../helpers/app_logger_test_isolation.dart';

class _Repository extends Mock implements CollectionRepository {}

class _Gallery extends LocalGalleryNotifier {
  var favoriteCalls = 0, syncCalls = 0;
  @override
  LocalGalleryState build() => const LocalGalleryState();
  @override
  Future<bool> toggleFavorite(String filePath) async {
    favoriteCalls++;
    return true;
  }

  @override
  Future<bool?> syncFavoriteStatus(String filePath) async {
    syncCalls++;
    return true;
  }
}

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late _Repository repository;
  late _Gallery gallery;
  late Set<String> members;
  var readFails = false, immutable = false, addFails = false;
  Completer<void>? addGate;
  setUp(() {
    repository = _Repository();
    gallery = _Gallery();
    members = {};
    readFails = false;
    immutable = false;
    addFails = false;
    addGate = null;
    when(() => repository.getAllCollections()).thenAnswer(
      (_) async => [
        ImageCollection(
          id: 'c1',
          name: 'Fixture collection',
          createdAt: DateTime(2026),
        ),
      ],
    );
    when(() => repository.getCollectionIdsForImage(any())).thenAnswer((
      _,
    ) async {
      if (readFails) throw StateError('Fixture membership query failure');
      return immutable
          ? Set<String>.unmodifiable(members)
          : Set<String>.of(members);
    });
    when(() => repository.getImageIdByPath(any())).thenAnswer((_) async => 7);
    when(
      () => repository.getCollectionImageIds('c1'),
    ).thenAnswer((_) async => members.contains('c1') ? [7] : []);
    when(() => repository.addImagesToCollection('c1', any())).thenAnswer((
      _,
    ) async {
      await addGate?.future;
      if (addFails) return (added: 0, alreadyIn: 0, unresolved: 1);
      members.add('c1');
      return (added: 1, alreadyIn: 0, unresolved: 0);
    });
    when(() => repository.removeImagesFromCollection('c1', any())).thenAnswer((
      _,
    ) async {
      members.remove('c1');
      return 1;
    });
  });

  Future<void> open(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1200, 900);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(repository),
          localGalleryNotifierProvider.overrideWith(() => gallery),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showGalleryFavoriteMenu(
                  context,
                  ref: ref,
                  record: LocalImageRecord(
                    path: 'fixture.png',
                    size: 68,
                    modifiedAt: DateTime(2026),
                  ),
                  anchor: const Offset(300, 80),
                ),
                child: const Text('open-menu'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open-menu'));
    await t.pumpAndSettle();
  }

  Finder row() => find
      .ancestor(
        of: find.text('Fixture collection'),
        matching: find.byType(InkWell),
      )
      .first;
  bool checked(WidgetTester t) => find
      .descendant(of: row(), matching: find.byIcon(StudioIcons.gallerySelect))
      .evaluate()
      .isNotEmpty;

  testWidgets(
    'failed membership lookup keeps Favorite without fabricating collection membership',
    (t) async {
      readFails = true;
      await open(t);
      expect(find.text('Fixture collection'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await t.tap(find.text('Favorite'));
      await t.pumpAndSettle();
      expect(gallery.favoriteCalls, 1);
      verifyNever(() => repository.getImageIdByPath(any()));
      expect(t.takeException(), isNull);
    },
  );

  for (final initiallyMember in [false, true]) {
    testWidgets(
      'immutable membership snapshot can be toggled from $initiallyMember',
      (t) async {
        if (initiallyMember) members.add('c1');
        immutable = true;
        await open(t);
        expect(checked(t), initiallyMember);
        await t.tap(find.text('Fixture collection'));
        await t.pumpAndSettle();
        expect(members.contains('c1'), !initiallyMember);
        expect(checked(t), !initiallyMember);
        expect(t.widget<InkWell>(row()).onTap, isNotNull);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'an unsuccessful add restores the actual membership and allows a retry',
    (t) async {
      addFails = true;
      await open(t);
      await t.tap(find.text('Fixture collection'));
      await t.pumpAndSettle();
      expect(members, isEmpty);
      expect(checked(t), isFalse);
      expect(t.widget<InkWell>(row()).onTap, isNotNull);
      addFails = false;
      await t.tap(find.text('Fixture collection'));
      await t.pumpAndSettle();
      expect(members, {'c1'});
      expect(checked(t), isTrue);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'reopening after a query failure reads membership again normally',
    (t) async {
      readFails = true;
      await open(t);
      await t.tapAt(const Offset(900, 700));
      await t.pumpAndSettle();
      readFails = false;
      immutable = true;
      await t.tap(find.text('open-menu'));
      await t.pumpAndSettle();
      expect(find.text('Fixture collection'), findsOneWidget);
      await t.tap(find.text('Fixture collection'));
      await t.pumpAndSettle();
      expect(members, {'c1'});
      expect(checked(t), isTrue);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('late membership mutation does not access the closed menu ref', (
    t,
  ) async {
    addGate = Completer<void>();
    await open(t);
    await t.tap(find.text('Fixture collection'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(900, 700));
    await t.pumpAndSettle();
    addGate!.complete();
    await t.pumpAndSettle();
    expect(members, {'c1'});
    expect(gallery.syncCalls, 0);
    expect(t.takeException(), isNull);
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart';
import 'package:nai_launcher/presentation/widgets/online_gallery/online_favorites_browser.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late OnlineFavoritesRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('online_fav_browser_test_');
    repository = OnlineFavoritesRepository.forTesting(
      '${tempDir.path}/favorites.db',
    );
    await repository.initialize();
    await repository.addFavorite(_authorEightWork);
    await repository.toggleAuthor(GallerySourceId.aiTag, 7, 'author 7');
  });

  tearDown(() async {
    await repository.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
      if (condition()) return;
    }
    throw TestFailure('Timed out waiting for the online favorites browser');
  }

  Future<void> pumpBrowser(
    WidgetTester tester, {
    required void Function(GalleryItem item) onOpenItem,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onlineFavoritesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: OnlineFavoritesBrowser(
              columnWidth: 200,
              onOpenItem: onOpenItem,
            ),
          ),
        ),
      ),
    );
    await pumpUntil(
      tester,
      () =>
          find.text('author 7').evaluate().isNotEmpty &&
          find.text('author 8 work').evaluate().isNotEmpty,
    );
  }

  Future<void> disposeBrowser(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('零作品作者可从卡片直接取消且不触发卡片筛选', (tester) async {
    var openCount = 0;
    await pumpBrowser(tester, onOpenItem: (_) => openCount++);

    expect(find.text('author 7'), findsOneWidget);
    expect(find.text('author 8 work'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('online-favorite-author-remove-7')),
    );
    await pumpUntil(
      tester,
      () =>
          find.text('author 7').evaluate().isEmpty &&
          find.text('author 8 work').evaluate().isNotEmpty,
    );

    expect(find.text('author 7'), findsNothing);
    expect(
      await tester.runAsync(
        () => repository.listAuthors(GallerySourceId.aiTag),
      ),
      isEmpty,
    );
    expect(find.text('author 8 work'), findsOneWidget);
    expect(openCount, 0);

    await disposeBrowser(tester);
  });

  testWidgets('移除当前作者筛选后恢复原全部收藏范围', (tester) async {
    var openCount = 0;
    await pumpBrowser(tester, onOpenItem: (_) => openCount++);

    await tester.tap(find.text('author 7'));
    await pumpUntil(
      tester,
      () =>
          find.text('author 8 work').evaluate().isEmpty &&
          find.text('No favorited works yet').evaluate().isNotEmpty,
    );
    expect(find.text('author 8 work'), findsNothing);
    expect(find.text('No favorited works yet'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('online-favorite-author-remove-7')),
    );
    await pumpUntil(
      tester,
      () =>
          find.text('author 7').evaluate().isEmpty &&
          find.text('author 8 work').evaluate().isNotEmpty,
    );

    expect(find.text('author 7'), findsNothing);
    expect(
      await tester.runAsync(
        () => repository.listAuthors(GallerySourceId.aiTag),
      ),
      isEmpty,
    );
    expect(find.text('author 8 work'), findsOneWidget);
    expect(openCount, 0);

    await disposeBrowser(tester);
  });
}

const _authorEightWork = GalleryItem(
  id: 80,
  sourceId: GallerySourceId.aiTag,
  title: 'author 8 work',
  author: 'author 8',
  uploaderId: 8,
  cover: GalleryMedia(id: 'author-8-cover'),
);

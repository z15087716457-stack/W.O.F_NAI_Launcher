import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';

void main() {
  testWidgets(
    'selection toolbar separates current page and all result actions',
    (tester) async {
      await _pumpToolbar(tester);

      expect(find.byTooltip('选择本页'), findsOneWidget);
      expect(find.byTooltip('选择全部'), findsOneWidget);
      expect(find.byTooltip('全选'), findsNothing);
    },
  );

  testWidgets('select current page only selects visible page paths', (
    tester,
  ) async {
    final container = await _pumpToolbar(tester);

    await tester.tap(find.byTooltip('选择本页'));
    await tester.pump();

    expect(container.read(localGallerySelectionNotifierProvider).selectedIds, {
      r'C:\gallery\page-1.png',
      r'C:\gallery\page-2.png',
    });
    expect(find.byTooltip('取消本页'), findsOneWidget);
    expect(find.byTooltip('选择全部'), findsOneWidget);
  });

  testWidgets('select all replaces selection with all filtered result paths', (
    tester,
  ) async {
    final container = await _pumpToolbar(
      tester,
      initialSelectedIds: {r'C:\gallery\stale.png'},
    );

    await tester.tap(find.byTooltip('选择全部'));
    await tester.pumpAndSettle();

    expect(container.read(localGallerySelectionNotifierProvider).selectedIds, {
      r'C:\gallery\page-1.png',
      r'C:\gallery\page-2.png',
      r'C:\gallery\result-3.png',
      r'C:\gallery\result-4.png',
      r'C:\gallery\result-5.png',
    });
    expect(find.byTooltip('取消全部'), findsOneWidget);
  });

  testWidgets(
    'bulk action bar shows move and copy to actions and triggers callbacks',
    (tester) async {
      var moveCalled = false;
      var copyCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localGalleryNotifierProvider.overrideWith(
              () => _ToolbarGalleryNotifier(
                LocalGalleryState(
                  currentImages: [_record(r'C:\gallery\page-1.png')],
                  filteredCount: 1,
                  totalCount: 1,
                  totalPages: 1,
                  isInitialized: true,
                ),
                filteredPaths: const [r'C:\gallery\page-1.png'],
              ),
            ),
            localGallerySelectionNotifierProvider.overrideWith(
              () => _ActiveSelectionNotifier({r'C:\gallery\page-1.png'}),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LocalGalleryToolbar(
                onMoveToFolder: () => moveCalled = true,
                onCopyToFolder: () => copyCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byTooltip('移动'), findsOneWidget);
      expect(find.byTooltip('复制到…'), findsOneWidget);

      await tester.tap(find.byTooltip('移动'));
      expect(moveCalled, isTrue);

      await tester.tap(find.byTooltip('复制到…'));
      expect(copyCalled, isTrue);
    },
  );

  testWidgets(
    'bulk action bar disables remove from collection when onRemoveFromCollection is null',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localGalleryNotifierProvider.overrideWith(
              () => _ToolbarGalleryNotifier(
                LocalGalleryState(
                  currentImages: [_record(r'C:\gallery\page-1.png')],
                  filteredCount: 1,
                  totalCount: 1,
                  totalPages: 1,
                  isInitialized: true,
                ),
                filteredPaths: const [r'C:\gallery\page-1.png'],
              ),
            ),
            localGallerySelectionNotifierProvider.overrideWith(
              () => _ActiveSelectionNotifier({r'C:\gallery\page-1.png'}),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LocalGalleryToolbar(onRemoveFromCollection: null),
            ),
          ),
        ),
      );

      final removeBtnFinder = find.byTooltip('移出集合');
      expect(removeBtnFinder, findsOneWidget);

      await tester.tap(removeBtnFinder);
      await tester.pump();
    },
  );

  testWidgets(
    'bulk action bar enables remove from collection when onRemoveFromCollection is provided',
    (tester) async {
      var removeCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localGalleryNotifierProvider.overrideWith(
              () => _ToolbarGalleryNotifier(
                LocalGalleryState(
                  currentImages: [_record(r'C:\gallery\page-1.png')],
                  filteredCount: 1,
                  totalCount: 1,
                  totalPages: 1,
                  isInitialized: true,
                ),
                filteredPaths: const [r'C:\gallery\page-1.png'],
              ),
            ),
            localGallerySelectionNotifierProvider.overrideWith(
              () => _ActiveSelectionNotifier({r'C:\gallery\page-1.png'}),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: LocalGalleryToolbar(
                onRemoveFromCollection: () => removeCalled = true,
              ),
            ),
          ),
        ),
      );

      final removeBtnFinder = find.byTooltip('移出集合');
      expect(removeBtnFinder, findsOneWidget);

      await tester.tap(removeBtnFinder);
      expect(removeCalled, isTrue);
    },
  );
}

Future<ProviderContainer> _pumpToolbar(
  WidgetTester tester, {
  Set<String> initialSelectedIds = const {},
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localGalleryNotifierProvider.overrideWith(
          () => _ToolbarGalleryNotifier(
            LocalGalleryState(
              currentImages: [
                _record(r'C:\gallery\page-1.png'),
                _record(r'C:\gallery\page-2.png'),
              ],
              filteredCount: 5,
              totalCount: 5,
              totalPages: 3,
              isInitialized: true,
            ),
            filteredPaths: const [
              r'C:\gallery\page-1.png',
              r'C:\gallery\page-2.png',
              r'C:\gallery\result-3.png',
              r'C:\gallery\result-4.png',
              r'C:\gallery\result-5.png',
            ],
          ),
        ),
        localGallerySelectionNotifierProvider.overrideWith(
          () => _ActiveSelectionNotifier(initialSelectedIds),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LocalGalleryToolbar()),
      ),
    ),
  );

  return ProviderScope.containerOf(
    tester.element(find.byType(LocalGalleryToolbar)),
  );
}

LocalImageRecord _record(String path) {
  return LocalImageRecord(path: path, size: 1, modifiedAt: DateTime(2026));
}

class _ToolbarGalleryNotifier extends LocalGalleryNotifier {
  _ToolbarGalleryNotifier(this._initialState, {required this.filteredPaths});

  final LocalGalleryState _initialState;
  final List<String> filteredPaths;

  @override
  LocalGalleryState build() => _initialState;

  @override
  Future<List<String>> getFilteredImagePaths() async => filteredPaths;
}

class _ActiveSelectionNotifier extends LocalGallerySelectionNotifier {
  _ActiveSelectionNotifier(this._initialSelectedIds);

  final Set<String> _initialSelectedIds;

  @override
  SelectionModeState build() {
    return SelectionModeState(isActive: true, selectedIds: _initialSelectedIds);
  }
}

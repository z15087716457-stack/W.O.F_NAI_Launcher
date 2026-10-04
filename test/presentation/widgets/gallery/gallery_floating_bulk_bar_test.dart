import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_floating_bulk_bar.dart';

class _CountNotifier extends LocalGalleryNotifier {
  @override
  LocalGalleryState build() =>
      const LocalGalleryState(isInitialized: true, totalCount: 3);
}

void main() {
  Future<ProviderContainer> pumpBar(
    WidgetTester tester, {
    double width = 1200,
    VoidCallback? onRemoveFromCollection,
    required Map<String, int> calls,
  }) async {
    tester.view.physicalSize = Size(width, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [
        localGalleryNotifierProvider.overrideWith(_CountNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    void count(String key) => calls[key] = (calls[key] ?? 0) + 1;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: GalleryFloatingBulkBar(
                onSelectAllResults: () async => count('selectAll'),
                onMove: () => count('move'),
                onCopy: () => count('copy'),
                onPack: () => count('pack'),
                onEditMetadata: () => count('edit'),
                onAddToCollection: () => count('collection'),
                onRemoveFromCollection: onRemoveFromCollection,
                onDelete: () => count('delete'),
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('hidden until selection mode starts, then shows the count', (
    tester,
  ) async {
    final calls = <String, int>{};
    final container = await pumpBar(tester, calls: calls);
    expect(find.byKey(const Key('gallery-floating-bulk-bar')), findsNothing);

    container
        .read(localGallerySelectionNotifierProvider.notifier)
        .enterAndSelect('a.png');
    await tester.pump();
    expect(find.text('已选 1 张'), findsOneWidget);
    expect(find.text('移出集合'), findsNothing);

    await tester.tap(find.byKey(const Key('gallery-bulk-select-all')));
    await tester.tap(find.byKey(const Key('gallery-bulk-delete')));
    await tester.tap(find.text('移动'));
    await tester.pump();
    expect(calls, {'selectAll': 1, 'delete': 1, 'move': 1});

    await tester.tap(find.byKey(const Key('gallery-bulk-exit')));
    await tester.pump();
    expect(find.byKey(const Key('gallery-floating-bulk-bar')), findsNothing);
  });

  testWidgets('all results selected offers deselect; actions need selection', (
    tester,
  ) async {
    final calls = <String, int>{};
    final container = await pumpBar(
      tester,
      calls: calls,
      onRemoveFromCollection: () => calls['remove'] = 1,
    );
    final notifier = container.read(
      localGallerySelectionNotifierProvider.notifier,
    );
    notifier.enter();
    notifier.replaceSelection(['a.png', 'b.png', 'c.png']);
    await tester.pump();
    expect(find.text('取消全部'), findsOneWidget);
    expect(find.text('移出集合'), findsOneWidget);

    await tester.tap(find.text('取消全部'));
    await tester.pump();
    expect(
      container.read(localGallerySelectionNotifierProvider).isActive,
      true,
    );
    expect(find.text('已选 0 张'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gallery-bulk-delete')));
    await tester.pump();
    expect(calls.containsKey('delete'), isFalse);
  });

  testWidgets('narrow content collapses actions to icons without overflow', (
    tester,
  ) async {
    final container = await pumpBar(tester, width: 700, calls: {});
    container
        .read(localGallerySelectionNotifierProvider.notifier)
        .enterAndSelect('a.png');
    await tester.pump();
    expect(find.text('移动'), findsNothing);
    expect(find.byTooltip('移动'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

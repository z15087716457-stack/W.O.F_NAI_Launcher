import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'migrates legacy sorting and view without writing legacy keys',
    () async {
      SharedPreferences.setMockInitialValues({
        StorageKeys.promptBlockLibrarySortField: 'title',
        StorageKeys.promptBlockLibrarySortDescending: false,
        StorageKeys.promptBlockLibraryViewMode: 'list',
        StorageKeys.promptBlockLibraryCardWidth: 220.0,
      });
      final prefs = await SharedPreferences.getInstance();
      final state = BlocksPreferences.read(prefs);
      expect(state.sort, BlocksSort.title);
      expect(state.descending, isFalse);
      expect(state.view, BlocksView.list);
      await state.save(prefs);
      expect(prefs.getString(StorageKeys.promptBlockLibrarySortField), 'title');
      expect(BlocksPreferences.read(prefs).cardSize, closeTo(1 / 3, .001));
    },
  );

  test(
    'masonry becomes the default; old grid choice moves to masonry',
    () async {
      expect(
        BlocksPreferences.read(await SharedPreferences.getInstance()).view,
        BlocksView.masonry,
      );
      SharedPreferences.setMockInitialValues({'blocks_view': 'grid'});
      var prefs = await SharedPreferences.getInstance();
      expect(BlocksPreferences.read(prefs).view, BlocksView.masonry);
      SharedPreferences.setMockInitialValues({'blocks_view': 'list'});
      prefs = await SharedPreferences.getInstance();
      expect(BlocksPreferences.read(prefs).view, BlocksView.list);

      final state = BlocksPreferences.read(
        prefs,
      ).copyWith(view: BlocksView.grid, groupByFolder: true);
      await state.save(prefs);
      final restored = BlocksPreferences.read(prefs);
      expect(restored.view, BlocksView.grid);
      expect(restored.groupByFolder, isTrue);
    },
  );

  test(
    'persists scope, panels, expanded folders and dock collapsed groups',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(blocksPreferencesProvider.future);
      await container
          .read(blocksPreferencesProvider.notifier)
          .change(
            (p) => p.copyWith(
              scope: const BlocksScope.folder('folder'),
              sidebarOpen: false,
              inspectorOpen: false,
              expanded: {'folder'},
              collapsed: {'group'},
              cardSize: .8,
            ),
          );
      final restored = BlocksPreferences.read(
        await SharedPreferences.getInstance(),
      );
      expect(restored.scope, const BlocksScope.folder('folder'));
      expect(restored.sidebarOpen, isFalse);
      expect(restored.inspectorOpen, isFalse);
      expect(restored.expanded, {'folder'});
      expect(restored.collapsed, {'group'});
      expect(restored.cardSize, .8);
    },
  );

  test(
    'concurrent changes merge against current state and latest write wins',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(blocksPreferencesProvider.future);
      final notifier = container.read(blocksPreferencesProvider.notifier);
      await Future.wait([
        notifier.change((p) => p.copyWith(sidebarOpen: false)),
        notifier.change((p) => p.copyWith(inspectorOpen: false)),
        notifier.recordUse('a'),
        notifier.recordUse('b'),
        notifier.recordUse('a'),
      ]);
      final restored = BlocksPreferences.read(
        await SharedPreferences.getInstance(),
      );
      expect(restored.sidebarOpen, isFalse);
      expect(restored.inspectorOpen, isFalse);
      expect(restored.recentIds, ['a', 'b']);
    },
  );

  test('corrupt scope and nonfinite size fall back safely', () async {
    SharedPreferences.setMockInitialValues({
      'blocks_scope': '[]',
      'blocks_card_size': double.infinity,
    });
    final prefs = BlocksPreferences.read(await SharedPreferences.getInstance());
    expect(prefs.scope, const BlocksScope.all());
    expect(prefs.cardSize, .5);
  });
}

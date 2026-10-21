import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../ui/blocks/blocks_contract.dart';

final blocksSharedPreferencesProvider = Provider<Future<SharedPreferences>>(
  (ref) => SharedPreferences.getInstance(),
);
final blocksPreferencesProvider =
    AsyncNotifierProvider<BlocksPreferencesNotifier, BlocksPreferences>(
      BlocksPreferencesNotifier.new,
    );

class BlocksPreferences {
  const BlocksPreferences({
    this.scope = const BlocksScope.all(),
    this.sort = BlocksSort.updated,
    this.descending = true,
    this.view = BlocksView.masonry,
    this.groupByFolder = false,
    this.cardSize = .5,
    this.sidebarOpen = true,
    this.inspectorOpen = true,
    this.expanded = const {},
    this.collapsed = const {},
    this.recentIds = const [],
    this.quickColor = 0xFF8E24AA,
    this.replaceSelection = true,
  });

  final BlocksScope scope;
  final BlocksSort sort;
  final bool descending;
  final BlocksView view;
  final bool groupByFolder;
  final double cardSize;
  final bool sidebarOpen;
  final bool inspectorOpen;
  final Set<String> expanded;
  final Set<String> collapsed;
  final List<String> recentIds;
  final int quickColor;
  final bool replaceSelection;

  factory BlocksPreferences.read(SharedPreferences prefs) {
    BlocksScope scope = const BlocksScope.all();
    try {
      final value = jsonDecode(prefs.getString('blocks_scope') ?? '{}');
      final id = value['id'];
      scope = switch (value['kind']) {
        'recent' => const BlocksScope.recent(),
        'favorites' => const BlocksScope.favorites(),
        'uncategorized' => const BlocksScope.uncategorized(),
        'folder' when id is String => BlocksScope.folder(id),
        'collection' when id is String => BlocksScope.collection(id),
        'tag' when id is String => BlocksScope.tag(id),
        _ => const BlocksScope.all(),
      };
    } on Object {
      scope = const BlocksScope.all();
    }
    final oldSort = prefs.getString(StorageKeys.promptBlockLibrarySortField);
    final size =
        prefs.getDouble('blocks_card_size') ??
        ((prefs.getDouble(StorageKeys.promptBlockLibraryCardWidth) ?? 240) -
                180) /
            120;
    return BlocksPreferences(
      scope: scope,
      sort:
          BlocksSort.values.asNameMap()[prefs.getString('blocks_sort') ??
              oldSort] ??
          BlocksSort.updated,
      descending:
          prefs.getBool('blocks_descending') ??
          prefs.getBool(StorageKeys.promptBlockLibrarySortDescending) ??
          true,
      // 瀑布流成为默认视图：新键 blocks_view_v2；旧值只保留“列表”，其余进瀑布流。
      view:
          BlocksView.values.asNameMap()[prefs.getString('blocks_view_v2')] ??
          ((prefs.getString('blocks_view') ??
                      prefs.getString(
                        StorageKeys.promptBlockLibraryViewMode,
                      )) ==
                  'list'
              ? BlocksView.list
              : BlocksView.masonry),
      groupByFolder: prefs.getBool('blocks_group_folders') ?? false,
      cardSize: size.isFinite ? size.clamp(0.0, 1.0) : .5,
      sidebarOpen: prefs.getBool('blocks_sidebar_open') ?? true,
      inspectorOpen: prefs.getBool('blocks_inspector_open') ?? true,
      expanded: (prefs.getStringList('blocks_folder_expanded') ?? []).toSet(),
      collapsed: (prefs.getStringList('blocks_dock_collapsed') ?? []).toSet(),
      recentIds: prefs.getStringList('blocks_recent_ids') ?? [],
      quickColor: prefs.getInt('blocks_quick_color') ?? 0xFF8E24AA,
      replaceSelection: prefs.getBool('blocks_quick_replace') ?? true,
    );
  }

  BlocksPreferences copyWith({
    BlocksScope? scope,
    BlocksSort? sort,
    bool? descending,
    BlocksView? view,
    bool? groupByFolder,
    double? cardSize,
    bool? sidebarOpen,
    bool? inspectorOpen,
    Set<String>? expanded,
    Set<String>? collapsed,
    List<String>? recentIds,
    int? quickColor,
    bool? replaceSelection,
  }) => BlocksPreferences(
    scope: scope ?? this.scope,
    sort: sort ?? this.sort,
    descending: descending ?? this.descending,
    view: view ?? this.view,
    groupByFolder: groupByFolder ?? this.groupByFolder,
    cardSize: cardSize ?? this.cardSize,
    sidebarOpen: sidebarOpen ?? this.sidebarOpen,
    inspectorOpen: inspectorOpen ?? this.inspectorOpen,
    expanded: expanded ?? this.expanded,
    collapsed: collapsed ?? this.collapsed,
    recentIds: recentIds ?? this.recentIds,
    quickColor: quickColor ?? this.quickColor,
    replaceSelection: replaceSelection ?? this.replaceSelection,
  );

  Future<void> save(SharedPreferences prefs) async {
    final results = await Future.wait([
      prefs.setString(
        'blocks_scope',
        jsonEncode({'kind': scope.kind.name, 'id': scope.id}),
      ),
      prefs.setString('blocks_sort', sort.name),
      prefs.setBool('blocks_descending', descending),
      prefs.setString('blocks_view_v2', view.name),
      prefs.setBool('blocks_group_folders', groupByFolder),
      prefs.setDouble('blocks_card_size', cardSize),
      prefs.setBool('blocks_sidebar_open', sidebarOpen),
      prefs.setBool('blocks_inspector_open', inspectorOpen),
      prefs.setStringList('blocks_folder_expanded', expanded.toList()),
      prefs.setStringList('blocks_dock_collapsed', collapsed.toList()),
      prefs.setStringList('blocks_recent_ids', recentIds),
      prefs.setInt('blocks_quick_color', quickColor),
      prefs.setBool('blocks_quick_replace', replaceSelection),
    ]);
    if (results.any((saved) => !saved)) {
      throw StateError('Cannot persist block preferences');
    }
  }
}

class BlocksPreferencesNotifier extends AsyncNotifier<BlocksPreferences> {
  late SharedPreferences _prefs;
  Future<void> _pending = Future.value();
  bool _alive = true;

  @override
  Future<BlocksPreferences> build() async {
    ref.onDispose(() => _alive = false);
    _prefs = await ref.read(blocksSharedPreferencesProvider);
    return BlocksPreferences.read(_prefs);
  }

  Future<void> change(
    BlocksPreferences Function(BlocksPreferences) change,
  ) async {
    await future;
    if (!_alive) return;
    final next = change(state.requireValue);
    state = AsyncData(next);
    final write = _pending.then((_) => next.save(_prefs));
    _pending = write.then((_) {}, onError: (Object _, StackTrace __) {});
    await write;
  }

  Future<void> recordUse(String id) => change(
    (p) => p.copyWith(
      recentIds: [
        id,
        ...p.recentIds.where((old) => old != id),
      ].take(20).toList(),
    ),
  );
}

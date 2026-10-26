import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/gallery/gallery_search_history_store.dart';

final gallerySearchHistoryStoreProvider = Provider(
  (ref) => GallerySearchHistoryStore(),
);
final gallerySearchHistoryProvider =
    AsyncNotifierProvider<GallerySearchHistory, List<String>>(
      GallerySearchHistory.new,
    );

class GallerySearchHistory extends AsyncNotifier<List<String>> {
  Future<void> _tail = Future.value();
  @override
  Future<List<String>> build() =>
      ref.read(gallerySearchHistoryStoreProvider).load();

  List<String> get items => state.valueOrNull ?? const [];
  Future<void> _change(
    Future<List<String>> Function(GallerySearchHistoryStore) action,
  ) {
    final result = _tail.then((_) async {
      await future;
      final items = await action(ref.read(gallerySearchHistoryStoreProvider));
      state = AsyncData(items);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> add(String query) => _change((store) => store.add(query));
  Future<void> remove(String query) => _change((store) => store.remove(query));
  Future<void> clear() => _change((store) => store.clear());
}

/// UI hand-off only: first five visible, remaining entries may scroll.
/// The host owns the popup and must close it when [tagExpansionActive] is true.
class GallerySearchHistoryViewData {
  const GallerySearchHistoryViewData({
    required this.items,
    required this.select,
    required this.remove,
    required this.clear,
    required this.tagExpansionActive,
    required this.setPopupOpen,
  });
  static const visibleItems = 5;
  final List<String> items;
  final void Function(String) select;
  final Future<void> Function(String) remove;
  final Future<void> Function() clear;
  final bool tagExpansionActive;

  /// Opening history disables/closes Ctrl-tag expansion until history closes.
  final void Function(bool) setPopupOpen;
}

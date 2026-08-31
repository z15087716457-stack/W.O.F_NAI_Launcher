import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/online_gallery/gallery_item.dart';
import '../../data/models/online_gallery/gallery_source.dart';
import '../../data/repositories/online_favorites_repository.dart';

/// 在线收藏状态：心形标记 + 子集 + 收藏作者（按源隔离）
class OnlineFavoritesState {
  const OnlineFavoritesState({
    this.sourceKey,
    this.favoritedWorkIds = const {},
    this.collections = const [],
    this.authors = const [],
    this.loading = false,
  });

  final String? sourceKey;
  final Set<int> favoritedWorkIds;
  final List<OnlineCollectionInfo> collections;
  final List<OnlineFavoriteAuthor> authors;
  final bool loading;

  bool isFavorite(GallerySourceId source, int workId) =>
      sourceKey == source.key && favoritedWorkIds.contains(workId);

  OnlineFavoritesState copyWith({
    String? sourceKey,
    Set<int>? favoritedWorkIds,
    List<OnlineCollectionInfo>? collections,
    List<OnlineFavoriteAuthor>? authors,
    bool? loading,
  }) {
    return OnlineFavoritesState(
      sourceKey: sourceKey ?? this.sourceKey,
      favoritedWorkIds: favoritedWorkIds ?? this.favoritedWorkIds,
      collections: collections ?? this.collections,
      authors: authors ?? this.authors,
      loading: loading ?? this.loading,
    );
  }
}

class OnlineFavoritesNotifier extends StateNotifier<OnlineFavoritesState> {
  OnlineFavoritesNotifier(this._repository)
    : super(const OnlineFavoritesState());

  final OnlineFavoritesRepository _repository;

  GallerySourceId? _source;

  /// 切换数据源时刷新整份状态
  Future<void> bindSource(GallerySourceId source) async {
    if (_source == source && state.sourceKey == source.key) return;
    _source = source;
    await _reload();
  }

  Future<void> _reload() async {
    final source = _source;
    if (source == null) return;
    state = state.copyWith(sourceKey: source.key, loading: true);
    try {
      await _repository.initialize();
      final ids = await _repository.favoritedWorkIds(source);
      final collections = await _repository.listCollectionsWithCounts(source);
      final authors = await _repository.listAuthors(source);
      state = state.copyWith(
        favoritedWorkIds: ids,
        collections: collections,
        authors: authors,
        loading: false,
      );
    } catch (e) {
      AppLogger.e('Online favorites reload failed', e, null, 'OnlineFav');
      state = state.copyWith(loading: false);
    }
  }

  /// 切换作品收藏态；返回切换后是否已收藏
  Future<bool> toggleFavorite(GalleryItem item) async {
    final source = item.sourceId;
    // 调用方未必先 bindSource（如详情对话框），此处兜底
    if (_source != source) await bindSource(source);
    final wasFavorite = state.favoritedWorkIds.contains(item.id);
    try {
      if (wasFavorite) {
        await _repository.removeFavorite(source, item.id);
      } else {
        await _repository.addFavorite(item);
      }
      final ids = Set<int>.of(state.favoritedWorkIds);
      wasFavorite ? ids.remove(item.id) : ids.add(item.id);
      state = state.copyWith(favoritedWorkIds: ids);
      return !wasFavorite;
    } catch (e) {
      AppLogger.e('Online favorite toggle failed', e, null, 'OnlineFav');
      return wasFavorite;
    }
  }

  /// 移动已收藏作品到子集（null = 根收藏）
  Future<void> moveToCollection(int workId, String? collectionId) async {
    final source = _source;
    if (source == null) return;
    try {
      final entries = await _repository.listFavorites(source, includeAll: true);
      final entry = entries.where((e) => e.item.id == workId).firstOrNull;
      if (entry == null) return;
      await _repository.addFavorite(entry.item, collectionId: collectionId);
      await _reload();
    } catch (e) {
      AppLogger.e('Online favorite move failed', e, null, 'OnlineFav');
    }
  }

  /// 从收藏列表删除并刷新状态
  Future<void> removeFavorite(GalleryItem item) async {
    await toggleFavorite(item);
  }

  Future<String> createCollection(String name) async {
    final id = await _repository.createCollection(name);
    await _reload();
    return id;
  }

  Future<void> renameCollection(String id, String newName) async {
    await _repository.renameCollection(id, newName);
    await _reload();
  }

  Future<void> deleteCollection(String id) async {
    await _repository.deleteCollection(id);
    await _reload();
  }

  /// 切换作者收藏态；返回切换后是否已收藏
  Future<bool> toggleAuthor(int authorId, String authorName) async {
    final source = _source;
    if (source == null) {
      await bindSource(GallerySourceId.aiTag);
      return toggleAuthor(authorId, authorName);
    }
    final nowFavorite = await _repository.toggleAuthor(
      source,
      authorId,
      authorName,
    );
    final authors = await _repository.listAuthors(source);
    state = state.copyWith(authors: authors);
    return nowFavorite;
  }

  /// 显式取消作者收藏；返回是否实际删除
  Future<bool> removeAuthor(int authorId) async {
    final source = _source;
    if (source == null) {
      await bindSource(GallerySourceId.aiTag);
      return removeAuthor(authorId);
    }
    final removed = await _repository.removeAuthor(source, authorId);
    final authors = await _repository.listAuthors(source);
    state = state.copyWith(authors: authors);
    return removed;
  }
}

final onlineFavoritesRepositoryProvider = Provider<OnlineFavoritesRepository>(
  (ref) => OnlineFavoritesRepository.instance,
);

final onlineFavoritesNotifierProvider =
    StateNotifierProvider<OnlineFavoritesNotifier, OnlineFavoritesState>(
      (ref) =>
          OnlineFavoritesNotifier(ref.read(onlineFavoritesRepositoryProvider)),
    );

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/danbooru_api_service.dart';
import 'package:nai_launcher/data/models/danbooru/danbooru_user.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/services/danbooru_auth_service.dart';
import 'package:nai_launcher/presentation/providers/online_gallery_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_logger_test_isolation.dart';
import 'krita/agent_bridge_draft_test.dart' show MemoryDraftSettings;

typedef _Page = ({List<GalleryItem> posts, int rawCount});

class _Auth extends DanbooruAuth {
  @override
  DanbooruAuthState build() => DanbooruAuthState(
    credentials: const DanbooruCredentials(
      username: 'fixture',
      apiKey: 'unused',
    ),
    user: const DanbooruUser(id: 9, name: 'fixture'),
    lastVerifiedAt: DateTime.now(),
  );
  @override
  Future<void> ensureInitialized() async {}
}

class _Favorites extends DanbooruApiService {
  _Favorites() : super(Dio());
  final requested = <int>[];
  final responses = <int, _Page>{};
  @override
  Future<_Page> getFavorites({
    int? userId,
    dynamic page = 1,
    int limit = 20,
  }) async {
    requested.add(page as int);
    return responses[page]!;
  }
}

_Page _page(int first, {int count = 40, String rating = 'g'}) => (
  posts: [
    for (var i = 0; i < count; i++)
      GalleryItem(id: first + i, rating: rating, tagString: 'fixture'),
  ],
  rawCount: count,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late ProviderContainer container;
  late OnlineGalleryNotifier notifier;
  late _Favorites api;
  late ProviderSubscription<OnlineGalleryState> subscription;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = _Favorites();
    api.responses.addAll({
      1: _page(1),
      2: _page(41, rating: 's'),
      3: _page(81, count: 10),
    });
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        danbooruAuthProvider.overrideWith(_Auth.new),
        danbooruApiServiceProvider.overrideWithValue(api),
      ],
    );
    subscription = container.listen(onlineGalleryNotifierProvider, (_, __) {});
    notifier = container.read(onlineGalleryNotifierProvider.notifier);
    await notifier.switchToFavorites();
    await notifier.setFavoritesSource('danbooru');
    await notifier.setRatings({'g'});
    api.requested.clear();
  });
  tearDown(() {
    subscription.close();
    container.dispose();
  });
  OnlineGalleryState getState() =>
      container.read(onlineGalleryNotifierProvider);
  test('fully filtered page keeps the next page reachable', () async {
    await notifier.loadMore();
    expect(getState().posts, hasLength(40));
    expect(getState().hasMore, isTrue);
    expect(getState().currentCache.endedByDuplicatePage, isFalse);
    await notifier.loadMore();
    expect(api.requested, [2, 3]);
    expect(getState().posts, hasLength(50));
    expect(getState().posts.last.id, 90);
    expect(getState().hasMore, isFalse);
  });
  test(
    'a page with raw rows but no parseable items also keeps its cursor',
    () async {
      api.responses[2] = (posts: [], rawCount: 40);
      await notifier.loadMore();
      expect(getState().hasMore, isTrue);
      await notifier.loadMore();
      expect(api.requested, [2, 3]);
      expect(getState().posts.last.id, 90);
    },
  );
  test(
    'partial raw overlap with filtered new identities is not a duplicate page',
    () async {
      api.responses[2] = (
        posts: [
          ..._page(1, count: 30).posts,
          ..._page(41, count: 10, rating: 's').posts,
        ],
        rawCount: 40,
      );
      await notifier.loadMore();
      expect(getState().posts, hasLength(40));
      expect(getState().hasMore, isTrue);
      await notifier.loadMore();
      expect(getState().posts, hasLength(50));
    },
  );
  test('an actual repeat of a hidden raw page terminates pagination', () async {
    api.responses[3] = api.responses[2]!;
    await notifier.loadMore();
    expect(getState().hasMore, isTrue);
    await notifier.loadMore();
    expect(api.requested, [2, 3]);
    expect(getState().hasMore, isFalse);
    expect(getState().currentCache.endedByDuplicatePage, isTrue);
  });
  test('an actual repeat of a visible raw page still terminates', () async {
    api.responses[2] = api.responses[1]!;
    await notifier.loadMore();
    expect(getState().hasMore, isFalse);
    expect(getState().currentCache.endedByDuplicatePage, isTrue);
    expect(getState().posts, hasLength(40));
  });
  test('refresh resets the loaded raw identities', () async {
    api.responses[3] = api.responses[2]!;
    await notifier.loadMore();
    await notifier.loadMore();
    await notifier.refresh();
    api.requested.clear();
    await notifier.loadMore();
    expect(api.requested, [2]);
    expect(getState().hasMore, isTrue);
    expect(getState().currentCache.endedByDuplicatePage, isFalse);
  });
  test('a filtered first page can be followed by a visible page', () async {
    api.responses[1] = _page(1, rating: 's');
    api.responses[2] = _page(41, count: 10);
    await notifier.refresh();
    expect(getState().posts, isEmpty);
    expect(getState().hasMore, isTrue);
    await notifier.loadMore();
    expect(getState().posts.first.id, 41);
    expect(getState().posts, hasLength(10));
  });
}

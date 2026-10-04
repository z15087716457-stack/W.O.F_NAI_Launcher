import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/repositories/collection_repository.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_favorite_menu.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

/// 收藏菜单首行「收藏」的即时反馈回归：
///
/// 旧实现等 `toggleFavorite` 整个返回（落库 + 取消收藏时的集合刷新 + 过滤
/// 视图重载）才 `setState`，菜单里点一下要愣一拍才见勾选/红心变化。现在先
/// 就地翻转、落库结果回来再以服务端口径校准——本用例用「落库永不完成」的
/// 服务把校准挡在门外，只验证那一帧内的即时翻转。
class _MockGalleryService extends Mock implements LocalGalleryService {}

class _MockCollectionRepository extends Mock implements CollectionRepository {}

class _InjectedGalleryService extends GalleryService {
  _InjectedGalleryService(this.service);

  final LocalGalleryService service;

  @override
  LocalGalleryService build() => service;
}

void main() {
  late _MockGalleryService galleryService;
  late _MockCollectionRepository collectionRepository;

  setUp(() {
    galleryService = _MockGalleryService();
    collectionRepository = _MockCollectionRepository();
    when(() => galleryService.isInitialized).thenReturn(true);
    when(
      () => galleryService.getPage(any(), pageSize: any(named: 'pageSize')),
    ).thenAnswer((_) async => const <LocalImageRecord>[]);
    when(() => collectionRepository.getAllCollections()).thenAnswer(
      (_) async => [
        ImageCollection(
          id: 'c1',
          name: '测试收藏集',
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );
    when(
      () => collectionRepository.getCollectionIdsForImage(any()),
    ).thenAnswer((_) async => <String>{});
  });

  testWidgets('首行「收藏」点击后当帧翻转勾选，不等落库返回', (tester) async {
    // 落库永远不完成：任何依赖它的 UI 更新都不会到达
    final pending = Completer<bool>();
    when(
      () => galleryService.toggleFavorite(any()),
    ).thenAnswer((_) => pending.future);

    final record = LocalImageRecord(
      path: r'C:\gallery\a.png',
      size: 100,
      modifiedAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => _InjectedGalleryService(galleryService),
          ),
          collectionRepositoryProvider.overrideWithValue(collectionRepository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () => showGalleryFavoriteMenu(
                    context,
                    ref: ref,
                    record: record,
                    anchor: const Offset(120, 120),
                  ),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 初始未收藏：首行未勾选，且收藏集行也未勾选
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.byIcon(StudioIcons.gallerySelect), findsNothing);

    await tester.tap(find.text('Favorite'));
    await tester.pump();

    // 落库尚未返回，勾选与文案已经翻转
    expect(
      find.byIcon(StudioIcons.gallerySelect),
      findsOneWidget,
      reason: '点击后当帧即应显示已收藏，不等落库返回',
    );
    expect(find.text('Remove Favorite'), findsOneWidget);

    // 收尾：放掉落库请求，避免测试结束时挂着未完成 Future
    pending.complete(true);
    await tester.pumpAndSettle();
  });
}

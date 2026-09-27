import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/gallery_thumbnail_quality_settings_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: GalleryThumbnailQualitySettingsTile()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('无偏好时默认高清', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpTile(tester, container);

    expect(
      container.read(localGalleryNotifierProvider).thumbnailQuality,
      GalleryThumbnailQuality.hd,
    );
    final control = tester.widget<SegmentedButton<GalleryThumbnailQuality>>(
      find.byKey(const Key('gallery-thumbnail-quality-setting')),
    );
    expect(control.selected, {GalleryThumbnailQuality.hd});
  });

  testWidgets('读取已有标清偏好，并从设置切换回高清', (tester) async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.localGalleryThumbnailQuality: GalleryThumbnailQuality.sd.name,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await pumpTile(tester, container);

    expect(
      container.read(localGalleryNotifierProvider).thumbnailQuality,
      GalleryThumbnailQuality.sd,
    );
    await tester.tap(find.text('高清'));
    await tester.pumpAndSettle();

    expect(
      container.read(localGalleryNotifierProvider).thumbnailQuality,
      GalleryThumbnailQuality.hd,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(StorageKeys.localGalleryThumbnailQuality),
      GalleryThumbnailQuality.hd.name,
    );
  });
}

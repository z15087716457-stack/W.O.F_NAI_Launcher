import 'settings_tile.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/thumbnail_cache_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/services/gallery/gallery_thumbnail_quality_store.dart';
import '../../../providers/local_gallery_provider.dart';

/// 本地画廊缩略图清晰度。与画廊共用同一状态及持久化偏好。
class GalleryThumbnailQualitySettingsTile extends ConsumerStatefulWidget {
  const GalleryThumbnailQualitySettingsTile({super.key});

  @override
  ConsumerState<GalleryThumbnailQualitySettingsTile> createState() =>
      _GalleryThumbnailQualitySettingsTileState();
}

class _GalleryThumbnailQualitySettingsTileState
    extends ConsumerState<GalleryThumbnailQualitySettingsTile> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreQuality();
  }

  Future<void> _restoreQuality() async {
    try {
      final quality = await const GalleryThumbnailQualityStore().load();
      if (!mounted) return;
      await ref
          .read(localGalleryNotifierProvider.notifier)
          .setThumbnailQuality(quality);
    } catch (error) {
      AppLogger.w('Failed to load gallery thumbnail quality: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = ref.watch(
      localGalleryNotifierProvider.select((state) => state.thumbnailQuality),
    );

    return SettingsTile(
      hoverFeedback: !_isLoading,
      leading: const Icon(Icons.image_outlined),
      title: Text(context.l10n.settings_galleryThumbnailQuality),
      subtitle: Text(context.l10n.settings_galleryThumbnailQualitySubtitle),
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : SegmentedButton<GalleryThumbnailQuality>(
              key: const Key('gallery-thumbnail-quality-setting'),
              showSelectedIcon: false,
              selected: {quality},
              segments: [
                ButtonSegment(
                  value: GalleryThumbnailQuality.sd,
                  label: Text(context.l10n.localGallery_thumbnailQualitySd),
                ),
                ButtonSegment(
                  value: GalleryThumbnailQuality.hd,
                  label: Text(context.l10n.localGallery_thumbnailQualityHd),
                ),
              ],
              onSelectionChanged: (selection) async {
                await ref
                    .read(localGalleryNotifierProvider.notifier)
                    .setThumbnailQuality(selection.single);
              },
            ),
    );
  }
}

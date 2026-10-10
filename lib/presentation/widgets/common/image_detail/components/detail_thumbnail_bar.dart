import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../image_detail_data.dart';
import 'viewer_filmstrip.dart';

/// Compatibility adapter; common stage consumers use ViewerFilmstrip directly.
class DetailThumbnailBar extends StatelessWidget {
  const DetailThumbnailBar({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.scrollController,
    required this.onTap,
  });
  final List<ImageDetailData> images;
  final int currentIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onTap;
  @override
  Widget build(BuildContext context) => ViewerFilmstrip(
    items: [
      for (final image in images)
        ViewerFilmstripItem(
          thumbnail: image.getImageProvider(),
          aspectRatio: image.aspectRatio,
          groupDate: image.groupDate,
        ),
    ],
    currentIndex: currentIndex,
    scrollController: scrollController,
    onTap: onTap,
  );
}

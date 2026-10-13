import '../widgets/common/image_detail/image_detail_data.dart';

class ImageViewerCallbacks {
  const ImageViewerCallbacks({this.onSave});
  final Future<void> Function(ImageDetailData image)? onSave;
}

import '../../data/services/gallery/gallery_filter_service.dart';

class GalleryNavigationRequest {
  GalleryNavigationRequest({this.criteria, this.addFolder = false});

  final FilterCriteria? criteria;
  final bool addFolder;
}

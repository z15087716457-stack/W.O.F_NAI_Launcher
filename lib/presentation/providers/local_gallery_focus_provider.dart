import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_gallery_focus_provider.g.dart';

/// 本地画廊当前查看的图片（单击设定，右侧详情面板与空格大图都读它）。
///
/// 与多选集合分开：普通单击只改变查看对象，不进入多选；
/// Ctrl/Cmd 单击只切换点击图；Shift 单击可用查看对象作为范围锚点。
@Riverpod(keepAlive: true)
class LocalGalleryFocusNotifier extends _$LocalGalleryFocusNotifier {
  @override
  String? build() => null;

  void focus(String? path) {
    if (state == path) return;
    state = path;
  }

  void clear() => focus(null);
}

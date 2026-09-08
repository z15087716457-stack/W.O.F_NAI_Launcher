/// 本地画廊视图模式。
///
/// 序列化直接用枚举自带的 `Enum.name`（grid/masonry/justified/mosaic）。
/// V2：工具栏循环 grid/masonry/justified/mosaic 四档；新装默认 mosaic。
enum GalleryViewMode {
  /// 固定方格
  grid,

  /// 瀑布流
  masonry,

  /// 火车流（justified 等高行）
  justified,

  /// 混排（mosaic 模板拼块墙，默认）
  mosaic;

  /// 反序列化；未知值返回 null（由调用方落默认值）
  static GalleryViewMode? tryParse(String value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

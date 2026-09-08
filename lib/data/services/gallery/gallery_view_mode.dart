/// 本地画廊视图模式。
///
/// 序列化直接用枚举自带的 `Enum.name`（grid/masonry/justified/mosaic）。
/// V1：工具栏只循环 grid/masonry/justified 三档；mosaic 仅定义占位，
/// 不进循环、无实现。
enum GalleryViewMode {
  /// 固定方格
  grid,

  /// 瀑布流（默认）
  masonry,

  /// 火车流（justified 等高行）
  justified,

  /// 马赛克拼图（预留，未实现）
  mosaic;

  /// 反序列化；未知值返回 null（由调用方落默认值）
  static GalleryViewMode? tryParse(String value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

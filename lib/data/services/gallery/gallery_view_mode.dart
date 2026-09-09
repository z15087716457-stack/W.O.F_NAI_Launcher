/// 本地画廊视图模式。
///
/// 序列化直接用枚举自带的 `Enum.name`（grid/masonry/justified）。
/// V3：工具栏循环 grid/masonry/justified 三档；新装默认 justified。
/// 历史沿革：V2 曾有 mosaic 档（混排），V3 复验后删除——遗留持久化
/// 字符串 'mosaic' 反序列化不到枚举（tryParse 返回 null），由调用方
/// 落默认值 justified，静默兼容不丢档。
enum GalleryViewMode {
  /// 固定方格
  grid,

  /// 瀑布流
  masonry,

  /// 火车流（面积均衡等高行 + 两级填充，默认）
  justified;

  /// 反序列化；未知值（含已删除的 'mosaic'）返回 null（由调用方落默认值）
  static GalleryViewMode? tryParse(String value) {
    for (final mode in values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

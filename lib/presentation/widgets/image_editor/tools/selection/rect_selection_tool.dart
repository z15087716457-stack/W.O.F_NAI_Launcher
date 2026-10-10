import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

import 'base_selection_tool.dart';

/// 矩形选区工具
class RectSelectionTool extends ShapeSelectionTool {
  @override
  String get id => 'rect_selection';

  @override
  String get name => 'Rectangle Selection';

  @override
  IconData get icon => Icons.crop_square;

  @override
  LogicalKeyboardKey get shortcutKey => LogicalKeyboardKey.keyS;

  @override
  Path createShapePath(Rect rect) {
    return Path()..addRect(rect);
  }
}

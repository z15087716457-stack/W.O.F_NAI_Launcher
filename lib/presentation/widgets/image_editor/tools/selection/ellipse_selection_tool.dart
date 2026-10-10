import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';

import 'base_selection_tool.dart';

/// 椭圆选区工具
class EllipseSelectionTool extends ShapeSelectionTool {
  @override
  String get id => 'ellipse_selection';

  @override
  String get name => 'Ellipse Selection';

  @override
  IconData get icon => Icons.circle_outlined;

  @override
  LogicalKeyboardKey get shortcutKey => LogicalKeyboardKey.keyU;

  @override
  Path createShapePath(Rect rect) {
    return Path()..addOval(rect);
  }
}

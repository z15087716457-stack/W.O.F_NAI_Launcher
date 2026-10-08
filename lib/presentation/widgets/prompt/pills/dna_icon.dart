import 'package:flutter/material.dart';

import '../../common/studio_icons.dart';
import '../../common/uiux_prototype_icon.dart';

/// The selected prototype's helix for inheritance actions and pill markers.
class DnaIcon extends StatelessWidget {
  const DnaIcon({
    super.key,
    this.size = 16,
    required this.color,
    this.trigger = 0,
  });

  final double size;
  // Kept for caller compatibility; prototype artwork has no trigger animation.
  final int trigger;
  final Color color;

  @override
  Widget build(BuildContext context) => UiuxPrototypeIcon(
    StudioIcons.inherit,
    prototypeName: 'evo',
    strokeWidth: 2.2,
    size: size,
    color: color,
  );
}

import 'package:flutter/material.dart';

import '../../common/studio_icons.dart';
import '../../common/studio_animated_icon.dart';

/// The shared double-helix symbol for block inheritance actions and markers.
class DnaIcon extends StatelessWidget {
  const DnaIcon({
    super.key,
    this.size = 16,
    required this.color,
    this.trigger = 0,
  });

  final double size;
  final int trigger;
  final Color color;

  @override
  Widget build(BuildContext context) => StudioAnimatedIcon(
    icon: StudioIcons.inherit,
    trigger: trigger,
    size: size,
    color: color,
  );
}

import 'package:flutter/material.dart';

import '../../common/studio_icons.dart';

/// The shared double-helix symbol for block inheritance actions and markers.
class DnaIcon extends StatelessWidget {
  const DnaIcon({super.key, this.size = 16, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(StudioIcons.inherit, size: size, color: color);
}

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';

class LibraryStatusColors {
  LibraryStatusColors(ThemeData theme)
    : ok = theme.brightness == Brightness.dark
          ? Colors.green.shade300
          : Colors.green.shade700,
      warn = theme.brightness == Brightness.dark
          ? Colors.orange.shade300
          : Colors.orange.shade800,
      error = theme.colorScheme.error,
      favorite = Colors.amber.shade700,
      character = theme.brightness == Brightness.dark
          ? Colors.blue.shade300
          : Colors.blue.shade600,
      style = theme.brightness == Brightness.dark
          ? Colors.pink.shade200
          : Colors.pink.shade400,
      both = theme.brightness == Brightness.dark
          ? Colors.purple.shade200
          : Colors.purple.shade400;
  final Color ok, warn, error, favorite, character, style, both;
}

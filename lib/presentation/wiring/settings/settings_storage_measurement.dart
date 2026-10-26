import 'package:path/path.dart' as p;

import '../../ui/settings/settings_contract.dart';
import 'settings_inventory.dart';

/// Aggregate measured physical files once, preferring registered resource kinds
/// over incidental files in a containing directory. Vibe enumeration is shallow.
List<SettingsStorageSlice> settingsClassifyStorage({
  required Map<String, SettingsDirectoryMeasurement> galleries,
  required Map<SettingsStorageKind, Map<String, SettingsDirectoryMeasurement>>
  categories,
}) {
  final assigned = <String, (SettingsStorageKind, int, int)>{};
  final paths = <SettingsStorageKind, Set<String>>{};
  final incomplete = <SettingsStorageKind>{};
  void include(
    String root,
    SettingsDirectoryMeasurement measurement,
    SettingsStorageKind kind, {
    bool gallery = false,
  }) {
    paths.putIfAbsent(kind, () => {}).add(root);
    if (measurement.incomplete) {
      incomplete.add(kind);
      if (gallery) incomplete.add(SettingsStorageKind.thumbnails);
      if (gallery || kind == SettingsStorageKind.vibes) {
        incomplete.add(SettingsStorageKind.other);
      }
    }
    final canonicalRoot = measurement.rootPath;
    for (final entry in measurement.files.entries) {
      final file = entry.value;
      var owner = kind;
      var priority = 20;
      if (kind == SettingsStorageKind.vibes) {
        final extension = p.extension(file.path).toLowerCase();
        final isVibe =
            canonicalRoot != null &&
            p.equals(p.dirname(file.path), canonicalRoot) &&
            (extension == '.naiv4vibe' || extension == '.naiv4vibebundle');
        owner = isVibe ? SettingsStorageKind.vibes : SettingsStorageKind.other;
        // A Vibe library is more specific than its enclosing image root.
        // Its non-library files are Other, never relabelled as gallery images.
        priority = isVibe ? 100 : 70;
      } else if (gallery) {
        owner = file.thumbnail
            ? SettingsStorageKind.thumbnails
            : file.image
            ? SettingsStorageKind.images
            : SettingsStorageKind.other;
        priority = file.thumbnail
            ? 90
            : file.image
            ? 50
            : 1;
      }
      paths.putIfAbsent(owner, () => {}).add(root);
      final previous = assigned[entry.key];
      if (previous == null || priority > previous.$3) {
        assigned[entry.key] = (owner, file.bytes, priority);
      }
    }
  }

  for (final entry in galleries.entries) {
    include(entry.key, entry.value, SettingsStorageKind.images, gallery: true);
  }
  for (final category in categories.entries) {
    for (final entry in category.value.entries) {
      include(entry.key, entry.value, category.key);
    }
  }
  return [
    for (final kind in SettingsStorageKind.values)
      SettingsStorageSlice(
        kind,
        assigned.values
            .where((v) => v.$1 == kind)
            .fold<int>(0, (sum, v) => sum + v.$2),
        paths: (paths[kind] ?? {}).toList(),
        incomplete: incomplete.contains(kind),
      ),
  ];
}

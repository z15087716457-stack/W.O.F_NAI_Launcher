import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as system_paths;

import '../services/adjacent_app_data_migration.dart';

export 'package:path_provider/path_provider.dart'
    hide getApplicationSupportDirectory, getTemporaryDirectory;

Future<Directory>? _applicationSupportDirectory;

bool get _usesAdjacentData =>
    Platform.isWindows && Platform.environment['FLUTTER_TEST'] != 'true';

/// Windows internal state belongs to the executable, never the current working
/// directory. Tests retain the injected path_provider implementation.
Future<Directory> getApplicationSupportDirectory() {
  if (!_usesAdjacentData) return system_paths.getApplicationSupportDirectory();
  return _applicationSupportDirectory ??= _prepareAdjacentData();
}

Future<Directory> _prepareAdjacentData() async {
  final destination = Directory(
    p.join(p.dirname(Platform.resolvedExecutable), 'user-data'),
  );
  return AdjacentAppDataMigration(
    legacy: await getLegacyApplicationSupportDirectory(),
    destination: destination,
  ).prepare();
}

/// Only historical migration code may use the original Windows directory.
Future<Directory> getLegacyApplicationSupportDirectory() =>
    system_paths.getApplicationSupportDirectory();

Future<Directory> getTemporaryDirectory() async {
  if (!_usesAdjacentData) return system_paths.getTemporaryDirectory();
  return Directory(
    p.join((await getApplicationSupportDirectory()).path, 'temp'),
  ).create(recursive: true);
}

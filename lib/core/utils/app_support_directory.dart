import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as system_paths;

import '../services/adjacent_app_data_migration.dart';
import 'studio_sandbox.dart';

export 'package:path_provider/path_provider.dart'
    hide
        getApplicationSupportDirectory,
        getTemporaryDirectory,
        getApplicationDocumentsDirectory;

final _applicationSupportDirectory = ApplicationSupportDirectoryResolver(
  _prepareAdjacentData,
);

/// Share in-flight preparation, but allow recovery UI to retry a failed attempt.
class ApplicationSupportDirectoryResolver {
  ApplicationSupportDirectoryResolver(this.prepare);
  final Future<Directory> Function() prepare;
  Future<Directory>? _resolved;

  Future<Directory> resolve() => _resolved ??= Future<Directory>.sync(prepare)
      .onError<Object>((error, stackTrace) {
        _resolved = null;
        Error.throwWithStackTrace(error, stackTrace);
      });
}

bool get _usesAdjacentData =>
    Platform.isWindows && Platform.environment['FLUTTER_TEST'] != 'true';

/// Windows internal state belongs to the executable, never the current working
/// directory. Tests retain the injected path_provider implementation.
Future<Directory> getApplicationSupportDirectory() {
  final sandbox = studioSandboxRoot();
  if (sandbox != null) {
    return Directory(p.join(sandbox, 'user-data')).create(recursive: true);
  }
  if (!_usesAdjacentData) return system_paths.getApplicationSupportDirectory();
  return _applicationSupportDirectory.resolve();
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
Future<Directory> getLegacyApplicationSupportDirectory() {
  if (studioSandboxRoot() != null) return getApplicationSupportDirectory();
  return system_paths.getApplicationSupportDirectory();
}

Future<Directory> getApplicationDocumentsDirectory() {
  final sandbox = studioSandboxRoot();
  if (sandbox == null) return system_paths.getApplicationDocumentsDirectory();
  return Directory(p.join(sandbox, 'documents')).create(recursive: true);
}

Future<Directory> getTemporaryDirectory() async {
  if (!_usesAdjacentData && studioSandboxRoot() == null) {
    return system_paths.getTemporaryDirectory();
  }
  return Directory(
    p.join((await getApplicationSupportDirectory()).path, 'temp'),
  ).create(recursive: true);
}

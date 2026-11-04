import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as system_paths;

import '../services/adjacent_app_data_migration.dart';
import '../services/legacy_preferences_import.dart';
import '../services/mac_legacy_data_import.dart';
import 'app_logger.dart';
import '../storage/application_storage.dart';
import 'studio_sandbox.dart';

export 'package:path_provider/path_provider.dart'
    hide
        getApplicationSupportDirectory,
        getTemporaryDirectory,
        getApplicationDocumentsDirectory;

final _applicationSupportDirectory = ApplicationSupportDirectoryResolver(
  _prepareAdjacentData,
);
final _macApplicationSupportDirectory = ApplicationSupportDirectoryResolver(
  _prepareMacData,
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

/// Bundle id of the previous macOS app whose data is copied on first launch
/// (W.O.F 1.x and the upstream NAI Launcher). A build can name another app
/// with `--dart-define=MAC_LEGACY_BUNDLE_ID=<bundle id>`; an empty value
/// turns the copy off.
const macLegacyBundleId = String.fromEnvironment(
  'MAC_LEGACY_BUNDLE_ID',
  defaultValue: 'com.aaalice.naiLauncher',
);

/// Name of the previous macOS app in the copy screen and Settings, as its
/// Dock icon shows it. A build that sets `MAC_LEGACY_BUNDLE_ID` to another
/// app names that app with `--dart-define=MAC_LEGACY_APP_NAME=<name>`.
const macLegacyAppName = String.fromEnvironment(
  'MAC_LEGACY_APP_NAME',
  defaultValue: 'Aaalice NAI Launcher',
);

/// Shows the first-launch copy (and a requested sync or undo) in the window.
/// main() sets it before the first call; without it a running previous
/// version stops startup.
MacLegacyDataImportPresenter? macLegacyDataImportPresenter;

enum SupportDirectoryLayout {
  /// path_provider's folder, used as is (tests, Linux, macOS without a
  /// previous app).
  system,

  /// Windows: `user-data/` beside the executable, see
  /// [AdjacentAppDataMigration].
  executableAdjacent,

  /// macOS: path_provider's folder, filled once from the previous app, see
  /// [MacLegacyDataImport].
  macLegacyImport,
}

@visibleForTesting
SupportDirectoryLayout supportDirectoryLayoutFor({
  required bool isWindows,
  required bool isMacOS,
  required bool isTest,
  String legacyBundleId = macLegacyBundleId,
}) {
  if (isTest) return SupportDirectoryLayout.system;
  if (isWindows) return SupportDirectoryLayout.executableAdjacent;
  if (isMacOS && _isBundleId(legacyBundleId)) {
    return SupportDirectoryLayout.macLegacyImport;
  }
  return SupportDirectoryLayout.system;
}

/// Settings offer "Sync from previous version" only where the first-launch
/// copy applies: macOS with a previous app, and never in a sandbox, which
/// must not read or replace real data.
@visibleForTesting
bool macLegacySyncOffered({
  required SupportDirectoryLayout layout,
  required String? sandboxRoot,
}) => sandboxRoot == null && layout == SupportDirectoryLayout.macLegacyImport;

/// The previous-version data step for this install, or null where it does
/// not apply (other platforms, tests, sandbox, no previous app configured).
Future<MacLegacyDataImport?> locateMacLegacyData() async {
  if (!macLegacySyncOffered(
    layout: _layout,
    sandboxRoot: studioSandboxRoot(),
  )) {
    return null;
  }
  final destination = await system_paths.getApplicationSupportDirectory();
  final legacy = Directory(p.join(destination.parent.path, macLegacyBundleId));
  if (p.equals(legacy.path, destination.path)) return null;
  return MacLegacyDataImport(
    legacy: legacy,
    destination: destination,
    preferences: LegacyPreferencesImport.macOS(macLegacyBundleId).copyMissing,
  );
}

bool _isBundleId(String value) =>
    value.isNotEmpty && !value.contains('/') && value != '.' && value != '..';

SupportDirectoryLayout get _layout => supportDirectoryLayoutFor(
  isWindows: Platform.isWindows,
  isMacOS: Platform.isMacOS,
  isTest: Platform.environment['FLUTTER_TEST'] == 'true',
);

bool get _usesAdjacentData =>
    _layout == SupportDirectoryLayout.executableAdjacent;

final _macProfileLock = MacProfileLock();

/// Acquire before first-launch import, sync/undo, Hive or SQLite. The lock
/// is a sibling of the movable profile, including in a sandbox.
Future<Directory> prepareApplicationSupportForStartup() async {
  if (Platform.isMacOS) {
    final sandbox = studioSandboxRoot();
    final profile = sandbox == null
        ? await system_paths.getApplicationSupportDirectory()
        : Directory(p.join(sandbox, 'user-data'));
    await _macProfileLock.acquire(profile);
  }
  return getApplicationSupportDirectory();
}

/// Windows internal state belongs to the executable, never the current working
/// directory. macOS copies the previous app's data in once before anything
/// opens. A sandbox keeps everything in its own `user-data` and never copies
/// real data. Tests retain the injected path_provider implementation.
Future<Directory> getApplicationSupportDirectory() {
  final sandbox = studioSandboxRoot();
  if (sandbox != null) {
    return Directory(p.join(sandbox, 'user-data')).create(recursive: true);
  }
  return switch (_layout) {
    SupportDirectoryLayout.executableAdjacent =>
      _applicationSupportDirectory.resolve(),
    SupportDirectoryLayout.macLegacyImport =>
      _macApplicationSupportDirectory.resolve(),
    SupportDirectoryLayout.system =>
      system_paths.getApplicationSupportDirectory(),
  };
}

Future<Directory> _prepareAdjacentData() async {
  final destination = Directory(
    p.join(p.dirname(Platform.resolvedExecutable), 'user-data'),
  );
  final directory = await AdjacentAppDataMigration(
    legacy: await getLegacyApplicationSupportDirectory(),
    destination: destination,
  ).prepare();
  initializeApplicationStorage(directory);
  return directory;
}

Future<Directory> _prepareMacData() async {
  final import = await locateMacLegacyData();
  if (import == null) return system_paths.getApplicationSupportDirectory();
  final state = await runMacLegacyDataImport(
    import,
    presenter: macLegacyDataImportPresenter,
  );
  AppLogger.i('Previous macOS app data: ${state.name}', 'Storage');
  return import.destination;
}

/// Only historical migration code may use the original Windows directory.
Future<Directory> getLegacyApplicationSupportDirectory() async {
  if (studioSandboxRoot() != null) return getApplicationSupportDirectory();
  if (!_usesAdjacentData) return system_paths.getApplicationSupportDirectory();
  // Resolve without creating AppData or going through the redirected provider.
  final roaming = Platform.environment['APPDATA'];
  if (roaming == null || roaming.isEmpty) {
    throw const FileSystemException('Cannot locate legacy application data');
  }
  return Directory(p.join(roaming, 'com.example', 'nai_launcher'));
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

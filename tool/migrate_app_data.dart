import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:nai_launcher/core/services/adjacent_app_data_migration.dart';

/// Explicit maintenance entry point; never launches or stops the application.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 3 || arguments.last != '--apply') {
    stderr.writeln(
      'Usage: dart run tool/migrate_app_data.dart LEGACY_DIRECTORY EXECUTABLE --apply',
    );
    exitCode = 64;
    return;
  }
  final legacy = Directory(arguments[0]).absolute;
  final executable = File(arguments[1]).absolute;
  if (p.basename(executable.path).toLowerCase() != 'nai_launcher.exe' ||
      !await executable.exists()) {
    throw const FileSystemException('Expected an existing nai_launcher.exe');
  }
  final running = await Process.run('powershell.exe', [
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    r"if (Get-Process -Name nai_launcher -ErrorAction SilentlyContinue) { exit 3 }; exit 0",
  ]);
  if (running.exitCode != 0) {
    stderr.writeln(
      'Exit NAI Studio from the system tray before migrating data.',
    );
    exitCode = 3;
    return;
  }
  final destination = Directory(p.join(executable.parent.path, 'user-data'));
  await AdjacentAppDataMigration(
    legacy: legacy,
    destination: destination,
    onPhase: stderr.writeln,
  ).prepare();
  stdout.writeln(
    jsonEncode({
      'success': true,
      'dataDirectory': destination.path,
      'legacyDirectory': legacy.path,
      'legacyResolvesTo': await legacy.resolveSymbolicLinks(),
      'backup': jsonDecode(
        await File(
          p.join(destination.path, AdjacentAppDataMigration.markerName),
        ).readAsString(),
      )['backup'],
    }),
  );
}

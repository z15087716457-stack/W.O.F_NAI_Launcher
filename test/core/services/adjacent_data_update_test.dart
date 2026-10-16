import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/windows_update_script.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final scenario in ['success', 'rollback', 'private-package']) {
    test('adjacent application data survives update: $scenario', () async {
      final root = await Directory.systemTemp.createTemp(
        'adjacent-update-test-',
      );
      final app = Directory(p.join(root.path, 'app'));
      final source = Directory(p.join(root.path, 'source'));
      Future<void> write(
        Directory directory,
        String relative,
        String data,
      ) async {
        final file = File(p.join(directory.path, relative));
        await file.parent.create(recursive: true);
        await file.writeAsString(data);
      }

      try {
        await write(app, 'nai_launcher.exe', 'old program');
        await write(app, 'user-data/draft.txt', 'original draft');
        await write(app, 'agent-data/chat.txt', 'agent session');
        await write(
          app,
          '.studio-data-backup-fixture/backup.txt',
          'backup data',
        );
        await write(source, 'nai_launcher.exe', 'new program');
        if (scenario == 'private-package') {
          await write(source, 'user-data/draft.txt', 'publisher private data');
        }
        final zip = p.join(root.path, 'update.zip');
        final packed = await Process.run(
          'powershell.exe',
          [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            r"Compress-Archive -Path (Join-Path $env:STUDIO_SOURCE '*') -DestinationPath $env:STUDIO_ZIP",
          ],
          environment: {'STUDIO_SOURCE': source.path, 'STUDIO_ZIP': zip},
        );
        expect(packed.exitCode, 0, reason: packed.stderr.toString());
        final resultPath = p.join(root.path, 'result.json');
        final scriptPath = p.join(root.path, 'update.ps1');
        final generated = WindowsUpdateScript.buildPortableScript(
          appPid: 2147483647,
          version: 'synthetic',
          zipPath: zip,
          appDirectory: app.path,
          executableName: 'nai_launcher.exe',
          extractDirectory: p.join(root.path, 'extract'),
          backupDirectory: p.join(root.path, 'rollback'),
          resultPath: resultPath,
          pendingMetadataPath: p.join(root.path, 'pending.json'),
          logPath: p.join(root.path, 'update.log'),
        );
        // Only generated maintenance code executes. The fake executable is
        // never started; simulate the update's launch success/failure instead.
        const mockedLaunch = r'''
$script:MockStarts = 0
function Start-Sleep {}
function Start-Process {
  param([string]$FilePath, [switch]$PassThru)
  $script:MockStarts++
  if ($env:STUDIO_SCENARIO -eq 'rollback' -and $script:MockStarts -eq 1) {
    [IO.File]::WriteAllText((Join-Path $env:STUDIO_APP 'user-data/draft.txt'), 'newest draft')
    return [PSCustomObject]@{ HasExited = $true; ExitCode = 7 }
  }
  return [PSCustomObject]@{ HasExited = $false; ExitCode = 0 }
}
''';
        await File(scriptPath).writeAsString(mockedLaunch + generated);
        final process = await Process.run(
          'powershell.exe',
          [
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            scriptPath,
          ],
          environment: {'STUDIO_SCENARIO': scenario, 'STUDIO_APP': app.path},
        );
        expect(
          process.exitCode,
          scenario == 'success' ? 0 : 1,
          reason: '${process.stdout}${process.stderr}',
        );
        final result = jsonDecode(await File(resultPath).readAsString()) as Map;
        expect(result['success'], scenario == 'success');
        expect(
          await File(p.join(app.path, 'nai_launcher.exe')).readAsString(),
          scenario == 'success' ? 'new program' : 'old program',
        );
        expect(
          await File(p.join(app.path, 'user-data/draft.txt')).readAsString(),
          scenario == 'rollback' ? 'newest draft' : 'original draft',
        );
        expect(
          await File(p.join(app.path, 'agent-data/chat.txt')).readAsString(),
          'agent session',
        );
        expect(
          await File(
            p.join(app.path, '.studio-data-backup-fixture/backup.txt'),
          ).readAsString(),
          'backup data',
        );
      } finally {
        await root.delete(recursive: true);
      }
    }, skip: !Platform.isWindows);
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/windows_update_script.dart';

void main() {
  for (final scenario in [
    'swap',
    'rollback',
    'data',
    'existing-backup',
    'success',
  ]) {
    test('portable update preserves private data: $scenario', () async {
      final root = await Directory.systemTemp.createTemp('portable_rollback_');
      final app = Directory('${root.path}/app');
      final backup = Directory('${root.path}/backup');
      final extract = Directory('${root.path}/extract');
      final result = File('${root.path}/result.json');
      try {
        await Directory('${app.path}/user-data').create(recursive: true);
        await File('${app.path}/nai_launcher.exe').writeAsString('old-program');
        await File(
          '${app.path}/user-data/keep.txt',
        ).writeAsString('private-data');
        if (scenario == 'existing-backup') {
          await backup.create();
          await File(
            '${backup.path}/previous.txt',
          ).writeAsString('previous-backup');
        }
        final zip = File('${root.path}/package.zip');
        await zip.writeAsBytes(
          ZipEncoder().encode(
            Archive()
              ..addFile(ArchiveFile.string('nai_launcher.exe', 'new-program')),
          )!,
        );
        final launches = File('${root.path}/launches.txt');
        String ps(String value) => value.replaceAll("'", "''");
        final preamble =
            r'''
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$script:AppMoves = 0
function Start-Sleep { param($Seconds, $Milliseconds) }
function Start-Process {
  param($FilePath, [switch]$PassThru, $ErrorAction)
  Add-Content -LiteralPath 'LAUNCHES' -Value $FilePath
  return [pscustomobject]@{ HasExited = $false; ExitCode = 0 }
}
function Move-Item {
  [CmdletBinding()] param([string]$LiteralPath, [string]$Destination)
  $toApp = [IO.Path]::GetFullPath($Destination) -eq [IO.Path]::GetFullPath('APP')
  if ($toApp) {
    $script:AppMoves++
    if (('SCENARIO' -in @('swap', 'rollback') -and $script:AppMoves -eq 1) -or
        ('SCENARIO' -eq 'rollback' -and $script:AppMoves -eq 2)) {
      throw 'Injected directory move failure'
    }
  }
  Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
  if ('SCENARIO' -eq 'data' -and
      [IO.Path]::GetFullPath($Destination) -eq [IO.Path]::GetFullPath('APP/user-data')) {
    throw 'Injected failure after protected data moved'
  }
}
'''
                .replaceAll('LAUNCHES', ps(launches.path))
                .replaceAll('APP', ps(app.path))
                .replaceAll('SCENARIO', scenario);
        final script = WindowsUpdateScript.buildPortableScript(
          appPid: 2147483647,
          version: 'test',
          zipPath: zip.path,
          appDirectory: app.path,
          executableName: 'nai_launcher.exe',
          extractDirectory: extract.path,
          backupDirectory: backup.path,
          resultPath: result.path,
          pendingMetadataPath: '${root.path}/pending.json',
          logPath: '${root.path}/update.log',
        );
        final runner = File('${root.path}/run.ps1');
        await runner.writeAsBytes([
          0xef,
          0xbb,
          0xbf,
          ...utf8.encode(preamble + script),
        ]);
        final process = await Process.run(
          'powershell.exe',
          [
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            runner.path,
          ],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
        expect(
          process.exitCode,
          scenario == 'success' ? 0 : 1,
          reason: '${process.stdout}\n${process.stderr}',
        );
        expect(
          await result.exists(),
          isTrue,
          reason:
              'Every failure, including rollback failure, must write its result',
        );
        final outcome =
            jsonDecode(await result.readAsString()) as Map<String, dynamic>;
        expect(outcome['success'], scenario == 'success');
        final dataHome = scenario == 'rollback' ? backup : app;
        expect(
          await File('${dataHome.path}/user-data/keep.txt').readAsString(),
          'private-data',
        );
        expect(
          await File('${dataHome.path}/nai_launcher.exe').readAsString(),
          scenario == 'success' ? 'new-program' : 'old-program',
        );
        expect(await extract.exists(), isFalse);
        if (scenario == 'rollback') {
          expect(await app.exists(), isFalse);
          expect(await launches.exists(), isFalse);
          expect(outcome['message'], contains(backup.path));
        } else if (scenario == 'existing-backup') {
          expect(
            await File('${backup.path}/previous.txt').readAsString(),
            'previous-backup',
          );
        } else {
          expect(await backup.exists(), isFalse);
        }
      } finally {
        // All mutations are under this suite's freshly created root.
        expect(root.absolute.path.contains('portable_rollback_'), isTrue);
        await root.delete(recursive: true);
      }
    }, skip: !Platform.isWindows);
  }
}

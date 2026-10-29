import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final folder in ['ascii', "中文 path's; \$name"]) {
    test(
      'update helper survives parent exit and releases app directory: $folder',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'update_launch_test_',
        );
        try {
          final scriptDirectory = await Directory(
            p.join(root.path, folder),
          ).create();
          final marker = File(p.join(root.path, 'completed.txt'));
          final app = await Directory(p.join(root.path, 'app')).create();
          expect(app.parent.absolute.path, root.absolute.path);
          expect(
            Directory('${app.path}.old').parent.absolute.path,
            root.absolute.path,
          );
          await File(
            p.join(app.path, 'keep.txt'),
          ).writeAsString('old app fixture');
          // flutter_tester lives in bin/cache/artifacts/engine/windows-x64/.
          final dart = File.fromUri(
            File(
              Platform.resolvedExecutable,
            ).parent.uri.resolve('../../../dart-sdk/bin/dart.exe'),
          );
          expect(await dart.exists(), isTrue);
          final parent = await Process.run(
            dart.path,
            [
              File(
                'test/fixtures/windows_update_launch_parent.dart',
              ).absolute.path,
              p.join(scriptDirectory.path, 'update.ps1'),
              marker.path,
              app.path,
            ],
            workingDirectory: app.path,
            stdoutEncoding: utf8,
            stderrEncoding: utf8,
          ).timeout(const Duration(seconds: 20));
          expect(
            parent.exitCode,
            0,
            reason: '${parent.stdout}\n${parent.stderr}',
          );
          final deadline = DateTime.now().add(const Duration(seconds: 10));
          while (!await marker.exists() && DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          expect(await marker.exists(), isTrue);
          expect(await marker.readAsString(), '父进程退出后仍完成');
          expect(await app.exists(), isFalse);
          expect(
            await File(p.join('${app.path}.old', 'keep.txt')).readAsString(),
            'old app fixture',
          );
        } finally {
          expect(root.parent.absolute.path, Directory.systemTemp.absolute.path);
          expect(p.basename(root.path), startsWith('update_launch_test_'));
          await root.delete(recursive: true);
        }
      },
      skip: !Platform.isWindows,
    );
  }
}

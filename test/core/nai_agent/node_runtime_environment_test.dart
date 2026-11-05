import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/node_runtime_environment.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'Finder-launched helpers find the bundled npm before system tools',
    () async {
      final root = await Directory.systemTemp.createTemp('agent node runtime ');
      addTearDown(() => root.delete(recursive: true));
      final npm = File(p.join(root.path, 'npm'));
      await npm.writeAsString('#!/bin/sh\nprintf bundled-npm');
      final chmod = await Process.run('/bin/chmod', ['755', npm.path]);
      expect(chmod.exitCode, 0);
      final result = await Process.run(
        '/bin/sh',
        ['-c', 'npm --version'],
        environment:
            nodeRuntimeEnvironment(
              p.join(root.path, 'node'),
              isMacOS: true,
              inheritedPath: '/usr/bin:/bin',
            ) ??
            {'PATH': '/usr/bin:/bin'},
        includeParentEnvironment: false,
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, 'bundled-npm');
    },
    skip: Platform.isWindows,
  );

  test(
    'missing PATH keeps system commands without adding the current directory',
    () {
      expect(
        nodeRuntimeEnvironment(
          '/App/工具/node',
          isMacOS: true,
          inheritedPath: '',
        ),
        {'PATH': '/App/工具:/usr/bin:/bin:/usr/sbin:/sbin'},
      );
    },
  );

  test('other platforms preserve their existing process environment', () {
    expect(nodeRuntimeEnvironment('C:\\app\\node.exe', isMacOS: false), isNull);
  });
}

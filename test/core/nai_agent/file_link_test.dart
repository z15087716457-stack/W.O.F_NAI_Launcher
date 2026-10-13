import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/utils/nai_agent_file_link.dart';

void main() {
  test(
    'workspace output links resolve locally; parent traversal and outside files are rejected',
    () async {
      final root = await Directory.systemTemp.createTemp('nai-file-links-');
      try {
        final workspace = await Directory('${root.path}/workspace').create();
        final output = File('${workspace.path}/说明.md');
        await output.writeAsString('工作区输出');
        final outside = File('${root.path}/outside.txt');
        await outside.writeAsString('其他文件');
        expect(
          await resolveAgentFileLink(workspace, Uri(path: '说明.md')),
          Uri.file(await output.resolveSymbolicLinks()),
        );
        expect(
          await resolveAgentFileLink(workspace, Uri(path: '../outside.txt')),
          isNull,
        );
        expect(
          await resolveAgentFileLink(
            workspace,
            Uri.parse('%2e%2e/outside.txt'),
          ),
          isNull,
        );
        expect(
          await resolveAgentFileLink(workspace, Uri.file(outside.path)),
          isNull,
        );
        expect(
          await resolveAgentFileLink(
            workspace,
            Uri.parse('https://example.test/image.png'),
          ),
          isNull,
        );
        expect(
          await resolveAgentFileLink(workspace, Uri(path: 'missing.md')),
          isNull,
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
  );
}

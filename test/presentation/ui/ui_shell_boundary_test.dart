import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 新界面（lib/presentation/ui/）只认契约：不准 import 状态管理、服务、数据库、路由或旧界面。
/// 接线写在 lib/presentation/wiring/，那里才可以读 provider。
void main() {
  test('lib/presentation/ui 不依赖后端和旧界面', () {
    const banned = [
      'riverpod',
      'go_router',
      '/providers/',
      '/screens/',
      '/router/',
      '/wiring/',
      'data/services/',
      'data/repositories/',
      'core/database/',
      'core/storage/',
      'core/network/',
    ];
    final violations = <String>[];
    for (final f in Directory(
      'lib/presentation/ui',
    ).listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      for (final (i, line) in f.readAsLinesSync().indexed) {
        if (!line.startsWith('import ')) continue;
        for (final b in banned) {
          if (line.contains(b)) violations.add('${f.path}:${i + 1}  $line');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}

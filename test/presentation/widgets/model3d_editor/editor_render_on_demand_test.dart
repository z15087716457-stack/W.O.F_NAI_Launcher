// 3D 模型图层编辑器是网页（assets/model3d_editor/editor.js），它的按需渲染测试用 Node 跑
// （js/editor_render_on_demand.test.mjs）；这里在 flutter test 里代跑。没装 Node 20.6+ 时跳过。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _script =
    'test/presentation/widgets/model3d_editor/js/editor_render_on_demand.test.mjs';

/// 能跑 ES 模块加载钩子的 Node（20.6 起）；没有时返回原因。
String? _nodeUnavailable() {
  try {
    final result = Process.runSync('node', ['--version']);
    if (result.exitCode != 0) return '没装 Node';
    final version = (result.stdout as String).trim();
    final parts = version.replaceFirst('v', '').split('.');
    final major = int.tryParse(parts.first) ?? 0;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    if (major > 20 || (major == 20 && minor >= 6)) return null;
    return '要 Node 20.6+，现在是 $version';
  } on ProcessException {
    return '没装 Node';
  }
}

void main() {
  final unavailable = _nodeUnavailable();
  test('3D 编辑器只在有变化时画一帧，静止时不画', () async {
    final result = await Process.run('node', ['--test', _script]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, skip: unavailable ?? false);
}

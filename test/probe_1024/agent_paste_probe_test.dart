// R07 / R08 探针：Agent 输入框粘贴路径。
//
// R08：确认「粘贴一张图片提示正在添加两张」的确切调用链——是导入预约计数被当成
// 张数，还是剪贴板真的被读成两份。
// R07：确认剪贴板里是非图片文件（.txt/.json 等）时走哪条路、哪里开始报错。
//
// 运行：
//   flutter test --no-pub test/probe_1024/agent_paste_probe_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';

import '../helpers/agent_data_reader.dart';
import '../presentation/wiring/nai_agent/agent_wiring_harness.dart';

/// 记录 importImages（导入预约）调用次数与并发峰值。
class _CountingController extends AgentTestController {
  _CountingController(super.store);
  int importCalls = 0;
  int maxConcurrent = 0;
  int maxAttachments = 0;

  @override
  Future<T> importImages<T>(
    AgentChatRuntime runtime,
    Future<T> Function() action,
  ) {
    importCalls++;
    maxConcurrent = math.max(maxConcurrent, runtime.importingImages + 1);
    return super.importImages(runtime, action);
  }

  @override
  Future<void> attach(
    String name,
    Uint8List bytes,
    String mimeType, {
    AgentChatRuntime? target,
  }) async {
    await super.attach(name, bytes, mimeType, target: target);
    maxAttachments = math.max(
      maxAttachments,
      (target ?? selected)!.composer.attachments.length,
    );
  }
}

void main() {
  late AgentWiringHarness h;
  late _CountingController c;

  setUp(() async {
    h = AgentWiringHarness();
    await h.init(controller: (store) {
      c = _CountingController(store);
      return c;
    });
  });

  tearDown(() => h.dispose());

  Uint8List pngBytes() =>
      img.encodePng(img.Image(width: 3, height: 2), level: 0);

  testWidgets('R08a 粘贴单张图片（剪贴板一个 reader）', (tester) async {
    h.clipboard = () async => [AgentFixtureDataReader(bytes: pngBytes())];
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('agent-input')), 'keep text');
    await h.paste(tester);
    await h.finishFiles(tester);
    await tester.pumpAndSettle();

    debugPrint(
      'R08a importImages 调用次数=${c.importCalls} 预约并发峰值=${c.maxConcurrent} '
      '附件数=${c.selected!.composer.attachments.length} '
      '峰值附件数=${c.maxAttachments} '
      '粘贴后输入框文本="${c.selected!.composer.text}"',
    );
    // 期望：一次粘贴只预约一次，计数不该被当成张数
    expect(c.maxConcurrent, 1, reason: '导入预约计数被当成张数（界面显示「正在添加 N 张」）');
    expect(c.selected!.composer.attachments, hasLength(1));
  });

  testWidgets('R08b 剪贴板给出两个 reader（模拟文件列表 + 位图各一份）', (tester) async {
    h.clipboard = () async => [
      AgentFixtureDataReader(bytes: pngBytes(), fileName: 'one.png'),
      AgentFixtureDataReader(bytes: pngBytes(), fileName: 'clipboard.png'),
    ];
    await h.pump(tester);
    await tester.tap(find.byKey(const Key('agent-input')));
    await tester.pump();
    await h.paste(tester);
    await h.finishFiles(tester);
    await tester.pumpAndSettle();

    debugPrint(
      'R08b 预约并发峰值=${c.maxConcurrent} '
      '附件数=${c.selected!.composer.attachments.length} '
      '名称=${c.selected!.composer.attachments.map((a) => a.name).toList()}',
    );
    expect(
      c.selected!.composer.attachments,
      hasLength(1),
      reason: '剪贴板同一张图给出两个 reader 时会真的加两张附件',
    );
  });

  testWidgets('R07a 剪贴板内容不是图片（按 PNG 格式给出的文本字节）', (tester) async {
    h.clipboard = () async => [
      AgentFixtureDataReader(
        bytes: Uint8List.fromList('hello prompt'.codeUnits),
        fileName: 'notes.txt',
      ),
    ];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': 'C:/tmp/notes.txt'}
          : call.method == 'Clipboard.hasStrings'
          ? {'value': true}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('agent-input')), 'prefix ');
    await h.paste(tester);
    await h.finishFiles(tester);
    await tester.pumpAndSettle();

    debugPrint(
      'R07a 预约并发峰值=${c.maxConcurrent} '
      '附件数=${c.selected!.composer.attachments.length} '
      '输入框文本="${c.selected!.composer.text}" '
      '（期望：插入文件路径，不加附件）',
    );
    expect(
      c.selected!.composer.text,
      contains('C:/tmp/notes.txt'),
      reason: '非图片内容应走文本回退，把路径/文本插入光标处',
    );
    expect(c.selected!.composer.attachments, isEmpty);
  });

  testWidgets('R07b 图片与非图片混合（两个 reader）', (tester) async {
    h.clipboard = () async => [
      AgentFixtureDataReader(
        bytes: Uint8List.fromList('notes'.codeUnits),
        fileName: 'a.txt',
      ),
      AgentFixtureDataReader(bytes: pngBytes(), fileName: 'b.png'),
    ];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': 'a.txt\nb.png'}
          : call.method == 'Clipboard.hasStrings'
          ? {'value': true}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await h.pump(tester);
    await tester.enterText(find.byKey(const Key('agent-input')), 'prefix ');
    await h.paste(tester);
    await h.finishFiles(tester);
    await tester.pumpAndSettle();

    debugPrint(
      'R07b 附件数=${c.selected!.composer.attachments.length} '
      '输入框文本="${c.selected!.composer.text}"',
    );
    expect(c.selected!.composer.attachments, hasLength(1));
    expect(c.selected!.composer.text, contains('a.txt'));
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/nai_agent/attachment_image.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/nai_agent/windows_clipboard_image.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/utils/dropped_file_reader.dart';
import 'package:nai_launcher/presentation/utils/nai_agent_image_reader.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_input.dart';
import '../../helpers/agent_data_reader.dart';

Uint8List metadataPng() => img.encodePng(
  img.Image(
    width: 3,
    height: 2,
    textData: {
      'Software': 'NovelAI',
      'Description': '1girl, original prompt',
      'Comment': jsonEncode({
        'prompt': '1girl, original prompt',
        'uc': 'blur',
        'seed': 123456,
        'steps': 28,
        'sampler': 'k_euler',
        'width': 3,
        'height': 2,
      }),
    },
  ),
);

void main() {
  late Directory root;
  late NaiAgentWorkspaceController controller;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-input-unit-');
    controller = NaiAgentWorkspaceController(
      store: AgentWorkspaceStore(root),
      initialWorkspaceName: 'test',
      initialChatName: 'test',
      startClient: (_, _, _, _, _) => throw StateError('No model requests'),
    );
    await controller.initialize(restoreHistory: false);
  });
  tearDown(() async {
    await controller.close();
    controller.dispose();
    await root.delete(recursive: true);
  });

  test(
    'native DIB wrapping preserves pixels and rejects oversized headers',
    () async {
      final original = img.encodeBmp(
        img.Image(width: 4, height: 3)..setPixelRgb(1, 1, 20, 30, 40),
      );
      final dib = Uint8List.fromList(original.sublist(14));
      final bmp = agentBitmapFromDib(dib);
      expect(img.decodeBmp(bmp)!.getPixel(1, 1).r, 20);
      expect((await inspectAgentAttachment(bmp)).metadata, isNull);
      final forged = Uint8List.fromList(dib);
      ByteData.sublistView(forged).setInt32(4, 100000, Endian.little);
      ByteData.sublistView(forged).setInt32(8, 100000, Endian.little);
      expect(
        () => agentBitmapFromDib(forged),
        throwsA(isA<AgentImageInputException>()),
      );
    },
  );
  test(
    'original PNG and parsed NAI metadata survive storage and reopening',
    () async {
      final bytes = metadataPng();
      // Reopening persistence applies to sent/saved chats; new drafts stay in memory.
      final selected = controller.selected!;
      selected.chat = await controller.store.saveDraftChat(selected.chat);
      await controller.attach('原图.png', bytes, 'image/png');
      final runtime = controller.selected!;
      final attachment = runtime.composer.attachments.single;
      expect(
        await controller.store.readAttachment(runtime.workspace.id, attachment),
        bytes,
      );
      expect(attachment.width, 3);
      expect(attachment.height, 2);
      expect(attachment.metadata?['prompt'], '1girl, original prompt');
      expect(attachment.metadata?['seed'], 123456);
      final restored = await AgentWorkspaceStore(
        root,
      ).readComposer(runtime.workspace.id, runtime.chat.id);
      expect(restored.attachments.single.toJson(), attachment.toJson());
      expect(await agentAttachmentVisualBytes(bytes, 'image/png'), same(bytes));
    },
  );

  test(
    'ordinary images and non-NAI parameters have no automatic metadata payload',
    () async {
      final ordinary = img.encodePng(
        img.Image(
          width: 2,
          height: 2,
          textData: {
            'Software': 'Photoshop',
            'Description': 'photo EXIF',
            'Comment': jsonEncode({'prompt': 'not NAI', 'seed': 1}),
          },
        ),
      );
      final info = await inspectAgentAttachment(ordinary);
      expect(info.metadata, isNull);
      expect(
        (await inspectAgentAttachment(
          img.encodeJpg(img.Image(width: 2, height: 2)),
        )).metadata,
        isNull,
      );
      await controller.attach('ordinary.png', ordinary, 'image/png');
      expect(controller.selected!.composer.attachments.single.metadata, isNull);
      expect(
        controller.selected!.composer.attachments.single.toJson().containsKey(
          'metadata',
        ),
        isFalse,
      );
    },
  );
  test('NAI stealth PNG and WebP fixtures retain their metadata', () async {
    for (final path in [
      'test/fixtures/metadata/v5_stealth_classic_envelope.png',
      'test/fixtures/metadata/v4_webp_exif_stealth.webp',
      'test/fixtures/metadata/v45_launcher_text_chunk.png',
    ]) {
      final bytes = await File(path).readAsBytes();
      final info = await inspectAgentAttachment(bytes);
      expect(info.metadata, isNotNull, reason: path);
      expect(info.metadata!.containsKey('rawJson'), isFalse);
    }
  });

  test('BMP original remains exact while its visual copy is PNG', () async {
    final bytes = img.encodeBmp(
      img.Image(width: 4, height: 3)..setPixelRgb(1, 1, 20, 30, 40),
    );
    await controller.attach('原图.bmp', bytes, 'image/bmp');
    final runtime = controller.selected!;
    final attachment = runtime.composer.attachments.single;
    expect(attachment.mimeType, 'image/bmp');
    expect(attachment.relativePath, endsWith('.bmp'));
    expect(
      await controller.store.readAttachment(runtime.workspace.id, attachment),
      bytes,
    );
    final png = await agentAttachmentVisualBytes(bytes, 'image/bmp');
    expect(agentImageMime(png), 'image/png');
    expect(img.decodePng(png)!.getPixel(1, 1).r, 20);
    expect(
      await controller.store.readAttachment(runtime.workspace.id, attachment),
      bytes,
    );
  });

  test('bad middle file does not stop later files or modify text', () async {
    final bytes = metadataPng();
    await controller.saveComposer('keep text');
    final report =
        await importAgentImageSources(controller, controller.selected!, [
          () async => DroppedFileData(fileName: 'a.png', bytes: bytes),
          () async =>
              DroppedFileData(fileName: 'broken.png', bytes: Uint8List(20)),
          () async => DroppedFileData(fileName: 'b.png', bytes: bytes),
        ]);
    expect(report.added, 2);
    expect(report.failures, hasLength(1));
    expect(controller.selected!.composer.text, 'keep text');
    expect(controller.selected!.composer.attachments.map((a) => a.name), [
      'a.png',
      'b.png',
    ]);
    expect(controller.selected!.importingImages, 0);
  });

  test(
    'file payload wins over synthesized image bytes and retains metadata',
    () async {
      final bytes = metadataPng();
      final file = File('${root.path}/原图 with spaces.png');
      await file.writeAsBytes(bytes);
      final reader = AgentFixtureDataReader(
        fileUri: file.uri,
        bytes: img.encodePng(img.Image(width: 1, height: 1)),
      );
      final data = await readAgentImage(reader);
      expect(data!.bytes, bytes);
      expect(data.fileName, '原图 with spaces.png');
      expect(reader.fileReads, 0);
    },
  );

  test('virtual image bytes are consumed inside file callback', () async {
    final bytes = metadataPng();
    final data = await readAgentImage(AgentFixtureDataReader(bytes: bytes));
    expect(data!.bytes, bytes);
    expect(data.sourcePath, isNull);
  });

  test(
    'pending file read keeps ownership after switching and blocks send',
    () async {
      final target = controller.selected!;
      final complete = Completer<DroppedFileData>();
      final pending = importAgentImageSources(controller, target, [
        () => complete.future,
      ]);
      expect(target.importingImages, 1);
      await controller.saveComposer('do not send while importing');
      await controller.send(); // The fake model factory throws if contacted.
      expect(target.composer.text, 'do not send while importing');
      await controller.createWorkspace('other');
      final current = controller.selected!;
      complete.complete(
        DroppedFileData(fileName: 'a.png', bytes: metadataPng()),
      );
      await pending;
      expect(current.composer.attachments, isEmpty);
      expect(target.composer.attachments, hasLength(1));
      expect(target.importingImages, 0);
      expect(
        await Directory(
          '${target.workspace.agentDirectory.path}/attachments/${target.chat.id}',
        ).exists(),
        false,
      );
      expect(await controller.store.listChats(target.workspace.id), isEmpty);
    },
  );

  test('closing during read prevents attachment creation', () async {
    final target = controller.selected!;
    final complete = Completer<DroppedFileData>();
    final pending = importAgentImageSources(controller, target, [
      () => complete.future,
    ]);
    final assertion = expectLater(
      pending,
      throwsA(isA<AgentImageInputException>()),
    );
    await controller.close();
    complete.complete(DroppedFileData(fileName: 'a.png', bytes: metadataPng()));
    await assertion;
    expect(target.composer.attachments, isEmpty);
    expect(target.importingImages, 0);
  });

  test(
    'oversized headers and bounded streams are rejected before allocation',
    () async {
      final bytes = metadataPng();
      final forged = Uint8List.fromList(bytes);
      ByteData.sublistView(forged).setUint32(16, 100000);
      ByteData.sublistView(forged).setUint32(20, 100000);
      await expectLater(
        inspectAgentAttachment(forged),
        throwsA(
          isA<AgentImageInputException>().having(
            (e) => e.code,
            'code',
            'oversized',
          ),
        ),
      );
      await expectLater(
        readAgentImageStream(
          Stream.fromIterable([Uint8List(4), Uint8List(4)]),
          maxBytes: 7,
        ),
        throwsA(isA<AgentImageInputException>()),
      );
      final file = File('${root.path}/large.png');
      final handle = await file.open(mode: FileMode.write);
      await handle.truncate(agentAttachmentMaxBytes + 1);
      await handle.close();
      await expectLater(
        readAgentImageFile(file.path),
        throwsA(isA<AgentImageInputException>()),
      );
    },
  );

  test(
    'metadata-only tool works without vision and leaves original unchanged',
    () async {
      final bytes = metadataPng();
      await File('${root.path}/original.png').writeAsBytes(bytes);
      final tools = NaiAgentStudioTools(
        workspaceDirectory: root,
        allowsImages: false,
        readDraft: () => throw StateError('No draft access'),
        readSummary: () => {},
        isGenerating: () => false,
        backupDraft: (_) async => throw StateError('No write'),
        writeDraft: (_) => throw StateError('No write'),
        readImage: (_) => null,
      );
      final result = await tools.execute('image_read', {
        'path': 'original.png',
        'metadata_only': true,
      }, NaiAgentCancellation());
      expect(
        (result['content'] as List).every((p) => p['type'] == 'text'),
        isTrue,
      );
      expect(result['details']['metadata']['seed'], 123456);
      expect(await File('${root.path}/original.png').readAsBytes(), bytes);
      await expectLater(
        tools.execute('image_read', {
          'path': 'original.png',
        }, NaiAgentCancellation()),
        throwsA(isA<NaiAgentToolError>()),
      );
    },
  );
}

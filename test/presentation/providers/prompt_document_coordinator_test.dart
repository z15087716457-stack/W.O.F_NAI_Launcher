import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_workspace_provider.dart';

/// updatePrompt / updateNegativePrompt 内联文档协调的行为验证：
/// 所有外部写入路径（Krita / 元数据导入 / 画廊复用 / 反推 / 随机 / 快捷键）
/// 都以这两个方法为唯一汇点，文档一致性不再依赖编辑器组件存活。
void main() {
  late ProviderContainer container;
  late PromptBlockWorkspaceNotifier workspace;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => _NoopLocalStorageService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    workspace = container.read(promptBlockWorkspaceNotifierProvider.notifier);
  });

  test('外部整串写入把文档无损压扁为单文本段', () async {
    const legacy = 'artist:xxx,\r\n{2::masterpiece::}, <lora:tag>,  no trim  ';
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(legacy);
    await pumpEventQueue();

    final document = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    expect(document.segments, hasLength(1));
    final segment = document.segments.single;
    expect(segment, isA<TextSegment>());
    expect((segment as TextSegment).text, legacy);
    expect(workspace.plainTextFor(PromptBlockLane.positive), legacy);
    expect(container.read(generationParamsNotifierProvider).prompt, legacy);
  });

  test('投影等价的外部写入保留文档结构', () async {
    workspace.replacePlainText(PromptBlockLane.positive, 'L');
    final textId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .single
        .id;
    workspace.insertBlockAtTextOffset(
      PromptBlockLane.positive,
      textSegmentId: textId,
      offset: 1,
      block: _block(title: '画师组合', content: 'artist:a, artist:b'),
    );
    final before = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    expect(before.segments, hasLength(3));
    final projection = workspace.plainTextFor(PromptBlockLane.positive);
    expect(projection, 'Lartist:a, artist:b');

    // 外部路径写入了恰好等于当前投影的纯文本（例如导入后又被等价复用）。
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    final after = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    expect(after.segments, hasLength(3), reason: '投影等价时不得压扁文档');
    expect(after.segments.whereType<BlockSegment>(), isNotEmpty);
  });

  test('编辑器等价链：段内编辑后投影同步 provider 且结构保留', () async {
    workspace.replacePlainText(PromptBlockLane.positive, 'base');
    final textId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .single
        .id;
    workspace.insertBlockAtTextOffset(
      PromptBlockLane.positive,
      textSegmentId: textId,
      offset: 4,
      block: _block(title: '光影', content: 'soft light'),
    );

    // 模拟编辑器 onChanged 链：文档编辑 → 投影 → updatePrompt(投影)。
    final firstTextId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .first
        .id;
    workspace.updateText(
      PromptBlockLane.positive,
      segmentId: firstTextId,
      text: 'base2',
    );
    final projection = workspace.plainTextFor(PromptBlockLane.positive);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    final document = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    expect(document.segments, hasLength(3), reason: '编辑器链不得触发压扁');
    expect(container.read(generationParamsNotifierProvider).prompt, projection);
  });

  test('updatePrompt 等值短路：重复写入不广播也不重建文档', () async {
    var notifications = 0;
    container.listen(
      generationParamsNotifierProvider.select((params) => params.prompt),
      (_, _) => notifications++,
    );

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('same');
    await pumpEventQueue();
    expect(notifications, 1);

    final documentBefore = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('same');
    await pumpEventQueue();

    expect(notifications, 1, reason: '等值写入必须短路');
    final documentAfter = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    expect(identical(documentAfter, documentBefore), isTrue);
  });

  test('负向 lane 独立协调，不影响正向文档', () async {
    workspace.replacePlainText(PromptBlockLane.positive, 'positive');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePrompt('lowres, bad');
    await pumpEventQueue();

    final state = container.read(promptBlockWorkspaceNotifierProvider);
    expect(workspace.plainTextFor(PromptBlockLane.negative), 'lowres, bad');
    expect(workspace.plainTextFor(PromptBlockLane.positive), 'positive');
    expect(state.negativeDocument.segments, hasLength(1));
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'lowres, bad',
    );
  });

  test('禁用块的正文与标题都不进入 provider 纯文本', () async {
    workspace.replacePlainText(PromptBlockLane.positive, '1girl, ');
    final textId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .single
        .id;
    workspace.insertBlockAtTextOffset(
      PromptBlockLane.positive,
      textSegmentId: textId,
      offset: 7,
      block: _block(title: '画师组合', content: 'artist:xyz'),
    );
    final blockId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .whereType<BlockSegment>()
        .single
        .id;

    workspace.toggleBlockEnabled(PromptBlockLane.positive, segmentId: blockId);
    final projection = workspace.plainTextFor(PromptBlockLane.positive);
    expect(projection, '1girl, ');
    expect(projection.contains('artist:xyz'), isFalse);
    expect(projection.contains('画师组合'), isFalse);

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    expect(container.read(generationParamsNotifierProvider).prompt, '1girl, ');
    expect(
      container.read(generationParamsNotifierProvider).prompt.contains('画师组合'),
      isFalse,
    );
  });

  test('空工作区（UI 未挂载）时外部写入后文档与 provider 一致', () async {
    expect(workspace.plainTextFor(PromptBlockLane.positive), '');

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('from krita bridge');
    await pumpEventQueue();

    expect(
      workspace.plainTextFor(PromptBlockLane.positive),
      'from krita bridge',
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'from krita bridge',
    );
  });

  test('块展开只出现一次且 provider 收到展开后文本', () async {
    workspace.replacePlainText(PromptBlockLane.positive, 'A');
    final textId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .single
        .id;
    workspace.insertBlockAtTextOffset(
      PromptBlockLane.positive,
      textSegmentId: textId,
      offset: 1,
      block: _block(title: 'T', content: 'B'),
    );
    final blockId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .whereType<BlockSegment>()
        .single
        .id;
    workspace.expandBlock(PromptBlockLane.positive, segmentId: blockId);

    final projection = workspace.plainTextFor(PromptBlockLane.positive);
    expect(projection, 'AB');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    expect(container.read(generationParamsNotifierProvider).prompt, 'AB');
  });
}

PromptBlock _block({required String title, required String content}) {
  return PromptBlock(
    id: 'source-block-$title',
    title: title,
    content: content,
    color: '#FF123456',
    createdAt: DateTime.utc(2026, 8, 30),
    updatedAt: DateTime.utc(2026, 8, 30),
  );
}

/// 无 Hive 环境下的存储桩：写入丢弃，读取走 isBoxOpen 防护的默认值。
class _NoopLocalStorageService extends LocalStorageService {
  @override
  Future<void> setLastPrompt(String prompt) async {}

  @override
  Future<void> setLastNegativePrompt(String prompt) async {}
}

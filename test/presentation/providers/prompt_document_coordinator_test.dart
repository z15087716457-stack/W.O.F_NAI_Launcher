import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';

/// updatePrompt / updateNegativePrompt 内联文档协调的行为验证：
/// 所有外部写入路径（Krita / 元数据导入 / 画廊复用 / 反推 / 随机 / 快捷键）
/// 都以这两个方法为唯一汇点，药丸文档一致性不再依赖编辑器组件存活。
void main() {
  const markerA = '\uE000';

  late ProviderContainer container;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => _NoopLocalStorageService(),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [
                _block(
                  id: 'artists',
                  title: '画师组合',
                  content: 'artist:a, artist:b',
                ),
                _block(id: 'light', title: '光影', content: 'soft light'),
              ],
              folders: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // 块库是异步加载：先等就绪，否则插入时的投影解析不到块内容。
    await container.read(promptBlockLibraryNotifierProvider.future);
  });

  PillWorkspaceNotifier mainLane() =>
      container.read(pillWorkspaceProvider(PillScopes.main).notifier);

  test('外部整串写入把药丸文档无损压扁为纯文本', () async {
    const legacy = 'artist:xxx,\r\n{2::masterpiece::}, <lora:tag>,  no trim  ';
    mainLane().insertBlockAt(offset: 0, blockId: 'artists');
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.instances,
      isNotEmpty,
    );

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(legacy);
    await pumpEventQueue();

    final document = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    expect(document.text, legacy);
    expect(document.instances, isEmpty);
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).projection,
      legacy,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, legacy);
  });

  test('投影等价的外部写入保留药丸结构', () async {
    final notifier = mainLane();
    notifier.setText('L');
    notifier.insertBlockAt(offset: 1, blockId: 'artists');
    final before = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    expect(before.instances, hasLength(1));
    final projection = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .projection;
    expect(projection, 'Lartist:a, artist:b');

    // 外部路径写入了恰好等于当前投影的纯文本（例如导入后又被等价复用）。
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    final after = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    expect(after.instances, hasLength(1), reason: '投影等价时不得压扁文档');
    expect(after.instances.values.single.blockId, 'artists');
  });

  test('编辑器等价链：文内编辑后投影同步 provider 且结构保留', () async {
    final notifier = mainLane();
    notifier.setText('base');
    notifier.insertBlockAt(offset: 4, blockId: 'light');

    // 模拟编辑器 onChanged 链：文档编辑 → 投影 → updatePrompt(投影)。
    notifier.setText('base2$markerA');
    final projection = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .projection;
    expect(projection, 'base2soft light');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    final document = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    expect(document.instances, hasLength(1), reason: '编辑器链不得触发压扁');
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
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('same');
    await pumpEventQueue();

    expect(notifications, 1, reason: '等值写入必须短路');
    final documentAfter = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    expect(identical(documentAfter, documentBefore), isTrue);
  });

  test('负向 lane 独立协调，不影响正向文档', () async {
    mainLane().setText('positive');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePrompt('lowres, bad');
    await pumpEventQueue();

    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      'lowres, bad',
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'positive',
    );
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'lowres, bad',
    );
  });

  test('禁用块的内容不进入 provider 纯文本', () async {
    final notifier = mainLane();
    notifier.setText('1girl, ');
    notifier.insertBlockAt(offset: 7, blockId: 'artists');
    notifier.toggleEnabled(markerA);
    final projection = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .projection;
    expect(projection, '1girl, ');
    expect(projection.contains('artist:a'), isFalse);

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt(projection);
    await pumpEventQueue();

    expect(container.read(generationParamsNotifierProvider).prompt, '1girl, ');
  });

  test('空工作区（UI 未挂载）时外部写入后文档与 provider 一致', () async {
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      '',
    );

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('from krita bridge');
    await pumpEventQueue();

    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'from krita bridge',
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'from krita bridge',
    );
  });
}

PromptBlock _block({
  required String id,
  required String title,
  required String content,
}) {
  return PromptBlock(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime.utc(2026, 8, 30),
    updatedAt: DateTime.utc(2026, 8, 30),
  );
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

/// 无 Hive 环境下的存储桩：写入丢弃，读取走 isBoxOpen 防护的默认值。
class _NoopLocalStorageService extends LocalStorageService {
  @override
  Future<void> setLastPrompt(String prompt) async {}

  @override
  Future<void> setLastNegativePrompt(String prompt) async {}
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/pill_instance_card.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/pill_instance_settings_dialog.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

/// B1 复现：L2 设置弹窗切「随机抽取」→ 确定 → 设置必须落进工作区状态并
/// 持久化；重开弹窗仍显示随机。修复前该链路在真实环境静默丢设置。
void main() {
  const markerA = '\uE000';
  const blockId = 'style';

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [_block(blockId, '画风1', 'A, B')],
              folders: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderContainer> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _FakeLibraryNotifier(
              PromptBlockLibraryState(
                blocks: [_block(blockId, '画风1', 'A, B')],
                folders: const [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 960,
              height: 360,
              child: PromptPillEditor(
                config: UnifiedPromptConfig(
                  enableAutocomplete: false,
                  enableSyntaxHighlight: false,
                  enableAutoFormat: false,
                  enableRegexReplace: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  group('B1 settings save (widget chain)', () {
    testWidgets(
      'apply random in L2 dialog writes mode=random into workspace state',
      (tester) async {
        final container = await pumpEditor(tester);
        await container.read(promptBlockLibraryNotifierProvider.future);
        container
            .read(pillWorkspaceNotifierProvider.notifier)
            .insertBlockAt(offset: 0, blockId: blockId);
        await tester.pump();

        // 点药丸 → L1 浮卡
        await tester.tap(find.byType(PromptPill));
        await tester.pump();
        await tester.pump();
        expect(find.byType(PillInstanceCard), findsOneWidget);

        // ⚙ → L2 弹窗（B1 修复后：开弹窗时浮卡显式关闭）
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pump();
        await tester.pump();
        expect(find.byType(PillInstanceSettingsDialog), findsOneWidget);
        expect(find.byType(PillInstanceCard), findsNothing);

        await tester.tap(find.text('随机抽取'));
        await tester.pump();
        await tester.tap(find.text('确定'));
        await tester.pump();
        await tester.pump();

        final settings = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]
            ?.settings;
        expect(settings, isNotNull);
        expect(settings!.mode, PillRollMode.random);
        // 随机模式立即物化一次 roll
        expect(
          container
              .read(pillWorkspaceNotifierProvider)
              .document
              .instances[markerA]!
              .currentRoll,
          isNotNull,
        );

        // 重开链路：再点药丸 → 浮卡 → ⚙ → 弹窗初始选中态必须仍是随机
        await tester.tap(find.byType(PromptPill));
        await tester.pump();
        await tester.pump();
        expect(find.byType(PillInstanceCard), findsOneWidget);
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pump();
        await tester.pump();
        expect(find.byType(PillInstanceSettingsDialog), findsOneWidget);
        final segmented = tester.widget<SegmentedButton<PillRollMode>>(
          find.byType(SegmentedButton<PillRollMode>),
        );
        expect(segmented.selected, {PillRollMode.random});
      },
    );

    testWidgets(
      'cancel keeps card-closed flow harmless and settings unchanged',
      (tester) async {
        final container = await pumpEditor(tester);
        await container.read(promptBlockLibraryNotifierProvider.future);
        container
            .read(pillWorkspaceNotifierProvider.notifier)
            .insertBlockAt(offset: 0, blockId: blockId);
        await tester.pump();

        await tester.tap(find.byType(PromptPill));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.byIcon(Icons.tune));
        await tester.pump();
        await tester.pump();
        await tester.tap(find.text('取消'));
        await tester.pump();
        await tester.pump();

        final instance = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA];
        expect(instance, isNotNull);
        expect(instance!.settings.mode, PillRollMode.fixed);
      },
    );
  });

  group('B1 settings save (persistence roundtrip)', () {
    late Directory hiveDirectory;

    setUpAll(() async {
      hiveDirectory = await Directory.systemTemp.createTemp(
        'pill_workspace_b1_test_',
      );
      Hive.init(hiveDirectory.path);
      await Hive.openBox<String>(PillWorkspaceStorage.boxName);
    });

    tearDownAll(() async {
      await Hive.close();
      if (await hiveDirectory.exists()) {
        await hiveDirectory.delete(recursive: true);
      }
    });

    test(
      'updateInstanceSettings persists random mode; tryLoadSync reads it back',
      () async {
        await Hive.box<String>(PillWorkspaceStorage.boxName).clear();
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);

        const scope = 'main';
        final notifier = container.read(pillWorkspaceProvider(scope).notifier)
          ..insertBlockAt(offset: 0, blockId: blockId);
        notifier.updateInstanceSettings(
          markerA,
          const PillInstanceSettings(mode: PillRollMode.random),
        );
        // persist 是 fire-and-forget：等一拍让 Box.put 落盘
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final restored = PillWorkspaceStorage().tryLoadSync(scope);
        expect(restored, isNotNull);
        expect(
          restored!.instances[markerA]?.settings.mode,
          PillRollMode.random,
        );
        expect(restored.instances[markerA]!.currentRoll, isNotNull);
      },
    );
  });
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

PromptBlock _block(String id, String title, String content) {
  return PromptBlock(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );
}

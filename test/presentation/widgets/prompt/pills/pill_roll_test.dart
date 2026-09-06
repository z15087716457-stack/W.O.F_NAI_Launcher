import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/image/image_params.dart'
    hide CharacterPrompt;
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_roll_coordinator.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/pill_instance_card.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/pill_instance_settings_dialog.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';

/// P2.5 块实例随机：工作区 roll / 协调器推送 / L1 卡 / L2 弹窗测试。
void main() {
  const markerA = '\uE000';
  const markerB = '\uE001';

  /// 交替返回 shuffle 下标的脚本化随机源：第一次 roll 取首原子，
  /// 第二次取末原子（count 抽取走 nextInt(1) 不消耗脚本步进）。
  /// 让「重 roll 必变化」在测试里确定性成立。
  final scriptedRandom = _AlternatingRandom();

  setUp(() {
    scriptedRandom.reset();
    PillWorkspaceNotifier.rng = scriptedRandom;
  });
  tearDown(() {
    PillWorkspaceNotifier.rng = Random();
  });

  ProviderContainer makeContainer({
    String blockContent = 'A, B',
    List<CharacterPrompt> characters = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [_block('style', '画风1', blockContent)],
              folders: const [],
            ),
          ),
        ),
        characterPromptNotifierProvider.overrideWith(
          () => _FakeCharacterPromptNotifier(
            CharacterPromptConfig(characters: characters),
          ),
        ),
        generationParamsNotifierProvider.overrideWith(
          () => _FakeGenerationParamsNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const randomSettings = PillInstanceSettings(
    mode: PillRollMode.random,
    countMin: 1,
    countMax: 1,
  );

  /// 顺序模式、数量固定 1：脚本源下输出完全确定（A → B → 绕回 A）。
  const sequentialSettings = PillInstanceSettings(
    mode: PillRollMode.sequential,
    countMin: 1,
    countMax: 1,
  );

  Future<void> insertRandomBlock(
    ProviderContainer container,
    String scope,
  ) async {
    final notifier = container.read(pillWorkspaceProvider(scope).notifier);
    notifier.insertBlockAt(offset: 0, blockId: 'style');
    notifier.updateInstanceSettings(markerA, randomSettings);
  }

  group('workspace roll', () {
    test('random instance projects its materialized currentRoll', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);

      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.setText('');
      notifier.insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(markerA, randomSettings);

      final state = container.read(pillWorkspaceNotifierProvider);
      final instance = state.document.instances[markerA]!;
      expect(instance.currentRoll, isNotNull);
      expect(instance.currentRoll, anyOf('A', 'B'));
      // 投影 = 物化结果，不是块原文（三源同源：L1 显示/生成/token 同一份）
      expect(state.projection, instance.currentRoll);
    });

    test('fixed mode keeps live content, roll methods are no-ops', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);

      final notifier = container.read(pillWorkspaceNotifierProvider.notifier)
        ..insertBlockAt(offset: 0, blockId: 'style');
      var state = container.read(pillWorkspaceNotifierProvider);
      expect(state.projection, 'A, B');
      expect(state.document.instances[markerA]!.currentRoll, isNull);
      expect(notifier.rollAllRandom(), isFalse);
      notifier.rollMarker(markerA);
      state = container.read(pillWorkspaceNotifierProvider);
      expect(state.document.instances[markerA]!.currentRoll, isNull);
    });

    test(
      'rollAllRandom re-rolls and reports change self-consistently',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);
        await insertRandomBlock(container, PillScopes.main);

        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
        final before = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .currentRoll;
        final changed = notifier.rollAllRandom();
        final after = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .currentRoll;
        expect(changed, before != after);
        // 交替脚本源保证这次必然换边
        expect(after, isNot(before));
        expect(container.read(pillWorkspaceNotifierProvider).projection, after);
      },
    );

    test(
      'locked random instance filters manual, automatic, and settings rolls',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);
        await insertRandomBlock(container, PillScopes.main);
        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);

        notifier.toggleLocked(markerA);
        final before = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .currentRoll;
        expect(
          container
              .read(pillWorkspaceNotifierProvider)
              .document
              .instances[markerA]!
              .locked,
          isTrue,
        );

        notifier.rollMarker(markerA);
        expect(
          container
              .read(pillWorkspaceNotifierProvider)
              .document
              .instances[markerA]!
              .currentRoll,
          before,
        );
        expect(notifier.rollAllRandom(), isFalse);

        notifier.updateInstanceSettings(
          markerA,
          const PillInstanceSettings(mode: PillRollMode.random, countMax: 2),
        );
        final locked = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!;
        expect(locked.currentRoll, before);
        expect(locked.settings.countMax, 2);

        // 解锁后恢复正常的手动 roll。
        notifier.toggleLocked(markerA);
        notifier.rollMarker(markerA);
        expect(
          container
              .read(pillWorkspaceNotifierProvider)
              .document
              .instances[markerA]!
              .currentRoll,
          isNot(before),
        );
      },
    );

    test(
      'mixed locked and unlocked instances only re-roll unlocked ones',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);
        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
        notifier.restoreDocument(
          const PillDocument(
            text: '$markerA $markerB',
            instances: {
              markerA: PillInstance(
                blockId: 'style',
                locked: true,
                settings: randomSettings,
                currentRoll: 'A',
              ),
              markerB: PillInstance(
                blockId: 'style',
                settings: randomSettings,
                currentRoll: 'B',
              ),
            },
          ),
        );

        expect(notifier.rollAllRandom(), isTrue);
        final state = container.read(pillWorkspaceNotifierProvider);
        expect(state.document.instances[markerA]!.currentRoll, 'A');
        expect(state.document.instances[markerB]!.currentRoll, 'A');
      },
    );

    test(
      'locked random instance with missing roll is not materialized',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);
        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
        notifier.restoreDocument(
          const PillDocument(
            text: markerA,
            instances: {
              markerA: PillInstance(
                blockId: 'style',
                locked: true,
                settings: randomSettings,
              ),
            },
          ),
        );

        final instance = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!;
        expect(instance.currentRoll, isNull);
      },
    );

    test('switching back to fixed restores live library content', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      await insertRandomBlock(container, PillScopes.main);

      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .updateInstanceSettings(markerA, PillInstanceSettings.fixedDefault);

      final state = container.read(pillWorkspaceNotifierProvider);
      expect(state.projection, 'A, B');
    });

    test('evolution toggle requires enabled random instances', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);

      notifier.insertBlockAt(offset: 0, blockId: 'style');
      notifier.toggleEvolution(markerA);
      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .evolutionEnabled,
        isFalse,
        reason: 'fixed instances cannot be inherited',
      );

      notifier.updateInstanceSettings(markerA, randomSettings);
      notifier.toggleEnabled(markerA);
      notifier.toggleEvolution(markerA);
      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .evolutionEnabled,
        isFalse,
        reason: 'disabled instances cannot be inherited',
      );

      notifier.toggleEnabled(markerA);
      notifier.toggleEvolution(markerA);
      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .evolutionEnabled,
        isTrue,
      );
    });
  });

  group('sequential mode (QoL-L2)', () {
    test(
      'switching to sequential materializes first batch and advances cursor',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);

        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
        notifier.setText('');
        notifier.insertBlockAt(offset: 0, blockId: 'style');
        notifier.updateInstanceSettings(markerA, sequentialSettings);

        final state = container.read(pillWorkspaceNotifierProvider);
        final instance = state.document.instances[markerA]!;
        expect(instance.currentRoll, 'A');
        expect(instance.sequenceCursor, 1);
        // 投影 = 物化结果（三源同源对顺序模式同样成立）
        expect(state.projection, 'A');
      },
    );

    test(
      'scene-act flow: lock freezes content and cursor, unlock + dice advances',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);
        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
        notifier.setText('');
        notifier.insertBlockAt(offset: 0, blockId: 'style');
        notifier.updateInstanceSettings(markerA, sequentialSettings);

        PillInstance read() => container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!;

        // 第一幕 roll 到满意内容 → 锁定：内容与游标双冻结
        notifier.toggleLocked(markerA);
        expect(read().currentRoll, 'A');
        expect(read().sequenceCursor, 1);
        expect(notifier.rollAllRandom(), isFalse);
        notifier.rollMarker(markerA);
        expect(read().currentRoll, 'A');
        expect(read().sequenceCursor, 1);

        // 需要下一幕 → 解锁 → 骰子 = 下一批
        notifier.toggleLocked(markerA);
        notifier.rollMarker(markerA);
        expect(read().currentRoll, 'B');
        expect(read().sequenceCursor, 0, reason: '池长 2，游标绕回');

        // 满意再锁
        notifier.toggleLocked(markerA);
        expect(read().locked, isTrue);
        expect(read().currentRoll, 'B');
      },
    );

    test('rollAllRandom advances each sequential instance per batch', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.setText('');
      notifier.insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(markerA, sequentialSettings);

      PillInstance read() => container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!;

      expect(notifier.rollAllRandom(), isTrue);
      expect(read().currentRoll, 'B');
      expect(read().sequenceCursor, 0);
      // 再 roll：绕回池头
      expect(notifier.rollAllRandom(), isTrue);
      expect(read().currentRoll, 'A');
      expect(read().sequenceCursor, 1);
    });

    test('trigger miss yields empty roll and keeps cursor', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.setText('');
      notifier.insertBlockAt(offset: 0, blockId: 'style');
      // 脚本源 nextDouble()=0.5：trigger 0.4 → 未中；0.6 → 命中
      notifier.updateInstanceSettings(
        markerA,
        const PillInstanceSettings(
          mode: PillRollMode.sequential,
          countMin: 1,
          countMax: 1,
          triggerProbability: 0.4,
        ),
      );

      final instance = container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!;
      expect(instance.currentRoll, '');
      expect(instance.sequenceCursor, 0, reason: '未触发=不出场且游标不动');

      notifier.updateInstanceSettings(
        markerA,
        const PillInstanceSettings(
          mode: PillRollMode.sequential,
          countMin: 1,
          countMax: 1,
          triggerProbability: 0.6,
        ),
      );
      final hit = container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!;
      expect(hit.currentRoll, 'A');
      expect(hit.sequenceCursor, 1);
    });

    test(
      'legacy document without cursor materializes from pool head',
      () async {
        final container = makeContainer();
        await container.read(promptBlockLibraryNotifierProvider.future);
        final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
        // 旧存档：settings.mode=sequential 但无 sequenceCursor/currentRoll 键
        notifier.restoreDocument(
          PillDocument.fromJson(const {
            'text': markerA,
            'instances': {
              markerA: {
                'blockId': 'style',
                'settings': {
                  'mode': 'sequential',
                  'countMin': 1,
                  'countMax': 1,
                },
              },
            },
          }),
        );

        final instance = container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!;
        // fromJson 缺键落 0（引擎单测覆盖），恢复路径兜底物化从池头取并推进
        expect(instance.currentRoll, 'A');
        expect(instance.sequenceCursor, 1);
      },
    );

    test('settings update re-rolls from current cursor position', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.setText('');
      notifier.insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(markerA, sequentialSettings);

      // 参数更新（开权重段）：从当前位置继续取下一批，不重置游标
      notifier.updateInstanceSettings(
        markerA,
        const PillInstanceSettings(
          mode: PillRollMode.sequential,
          countMin: 1,
          countMax: 1,
          weightEnabled: true,
        ),
      );
      final instance = container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!;
      expect(instance.currentRoll, contains('B'));
      expect(instance.sequenceCursor, 0);
    });

    test('evolution toggle accepts sequential instances', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier);
      notifier.setText('');
      notifier.insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(markerA, sequentialSettings);

      notifier.toggleEvolution(markerA);
      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .evolutionEnabled,
        isTrue,
        reason: '顺序实例与随机同权参与探索遗传',
      );
    });
  });

  group('roll coordinator', () {
    test('rolls every lane and pushes projections to their sinks', () async {
      final container = makeContainer(
        characters: const [CharacterPrompt(id: 'c1', name: 'C1')],
      );
      await container.read(promptBlockLibraryNotifierProvider.future);

      await insertRandomBlock(container, PillScopes.main);
      await insertRandomBlock(container, PillScopes.negative);
      await insertRandomBlock(container, PillScopes.charPos('c1'));

      final rolled = container
          .read(pillRollCoordinatorProvider)
          .rollAllLanesAndSync();

      expect(
        rolled.keys,
        containsAll([
          PillScopes.main,
          PillScopes.negative,
          PillScopes.charPos('c1'),
        ]),
      );

      final gen =
          container.read(generationParamsNotifierProvider.notifier)
              as _FakeGenerationParamsNotifier;
      expect(gen.lastPrompt, rolled[PillScopes.main]);
      expect(gen.lastNegative, rolled[PillScopes.negative]);
      expect(
        container
            .read(characterPromptNotifierProvider)
            .characters
            .single
            .prompt,
        rolled[PillScopes.charPos('c1')],
      );
      // 推送值 = 各 lane 当前投影（编辑器不挂载也不断链）
      expect(
        gen.lastPrompt,
        container.read(pillWorkspaceNotifierProvider).projection,
      );
    });

    test('no random instances means no pushes and empty result', () async {
      final container = makeContainer();
      await container.read(promptBlockLibraryNotifierProvider.future);
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: 'style');

      final rolled = container
          .read(pillRollCoordinatorProvider)
          .rollAllLanesAndSync();
      expect(rolled, isEmpty);
      final gen =
          container.read(generationParamsNotifierProvider.notifier)
              as _FakeGenerationParamsNotifier;
      expect(gen.lastPrompt, isEmpty);
    });

    test('deleted character lanes are skipped without crashing', () async {
      final container = makeContainer(
        characters: const [CharacterPrompt(id: 'c1', name: 'C1')],
      );
      await container.read(promptBlockLibraryNotifierProvider.future);
      await insertRandomBlock(container, PillScopes.charPos('c1'));

      container
          .read(characterPromptNotifierProvider.notifier)
          .removeCharacter('c1');

      // 角色已删：lane 仍在注册表（fake notifier 不走 deleteScope），
      // 协调器静默跳过不炸
      final rolled = container
          .read(pillRollCoordinatorProvider)
          .rollAllLanesAndSync();
      expect(rolled.keys, contains(PillScopes.charPos('c1')));
      expect(
        container.read(characterPromptNotifierProvider).characters,
        isEmpty,
      );
    });
  });

  group('L1 instance card', () {
    testWidgets('evolution badge replaces dice; card dice re-rolls', (
      tester,
    ) async {
      final container = await _pumpEditor(tester);
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier)
        ..insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(markerA, randomSettings);
      notifier.toggleEvolution(markerA);
      await tester.pump();

      // 遗传角标替换骰子角标，不叠加
      expect(find.byIcon(Icons.casino_outlined), findsNothing);
      expect(find.byType(DnaIcon), findsOneWidget);

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PillInstanceCard), findsOneWidget);
      // 卡内显示物化 roll（单原子脚本源取 'A'）
      expect(find.text('A'), findsOneWidget);

      final before = container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!
          .currentRoll;

      // 卡内骰子 = 重抽（按钮 key 与药丸角标相互独立）
      await tester.tap(find.byKey(const Key('pill-reroll')));
      await tester.pump();

      final after = container
          .read(pillWorkspaceNotifierProvider)
          .document
          .instances[markerA]!
          .currentRoll;
      expect(after, isNot(before));
      // 卡仍开着并显示新 roll
      expect(find.byType(PillInstanceCard), findsOneWidget);
      expect(find.text(after!), findsOneWidget);
    });

    testWidgets('lock toggle freezes re-roll and updates the pill badge', (
      tester,
    ) async {
      final container = await _pumpEditor(tester);
      await container.read(promptBlockLibraryNotifierProvider.future);
      final notifier = container.read(pillWorkspaceNotifierProvider.notifier)
        ..insertBlockAt(offset: 0, blockId: 'style');
      notifier.updateInstanceSettings(markerA, randomSettings);
      await tester.pump();

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();

      final lockButton = tester.widget<IconButton>(
        find.byKey(const Key('pill-lock-toggle')),
      );
      expect(lockButton.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('pill-lock-toggle')));
      await tester.pump();

      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .locked,
        isTrue,
      );
      expect(tester.widget<PromptPill>(find.byType(PromptPill)).locked, isTrue);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('pill-reroll')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('pill-lock-toggle')))
            .icon,
        isA<Icon>(),
      );

      await tester.tap(find.byKey(const Key('pill-lock-toggle')));
      await tester.pump();
      expect(
        container
            .read(pillWorkspaceNotifierProvider)
            .document
            .instances[markerA]!
            .locked,
        isFalse,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('pill-reroll')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('fixed mode disables the lock button', (tester) async {
      final container = await _pumpEditor(tester);
      await container.read(promptBlockLibraryNotifierProvider.future);
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: 'style');
      await tester.pump();

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('pill-lock-toggle')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('tapping outside dismisses the card', (tester) async {
      final container = await _pumpEditor(tester);
      await container.read(promptBlockLibraryNotifierProvider.future);
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: 'style');
      await tester.pump();

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PillInstanceCard), findsOneWidget);

      await tester.tapAt(const Offset(1100, 700));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PillInstanceCard), findsNothing);
    });

    testWidgets('card delete removes the marker instance', (tester) async {
      final container = await _pumpEditor(tester);
      await container.read(promptBlockLibraryNotifierProvider.future);
      container
          .read(pillWorkspaceNotifierProvider.notifier)
          .insertBlockAt(offset: 0, blockId: 'style');
      await tester.pump();

      await tester.tap(find.byType(PromptPill));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PillInstanceCard), findsNothing);
      expect(
        container.read(pillWorkspaceNotifierProvider).document.instances,
        isEmpty,
      );
      expect(container.read(pillWorkspaceNotifierProvider).document.text, '');
    });
  });

  group('L2 settings dialog', () {
    testWidgets('switching to random and applying returns drafted settings', (
      tester,
    ) async {
      PillInstanceSettings? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await PillInstanceSettingsDialog.show(
                    context,
                    PillInstanceSettings.fixedDefault,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(PillInstanceSettingsDialog), findsOneWidget);
      // 随机抽取控件初始不可见（固定模式）
      expect(find.text('随机抽取'), findsOneWidget); // segmented 段本身
      expect(find.textContaining('触发概率'), findsNothing);

      await tester.tap(find.text('随机抽取'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('触发概率'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.mode, PillRollMode.random);
    });

    testWidgets(
      'switching to sequential shows trigger/weight, hides order row',
      (tester) async {
        PillInstanceSettings? result;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await PillInstanceSettingsDialog.show(
                      context,
                      PillInstanceSettings.fixedDefault,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump();

        await tester.tap(find.text('顺序'));
        await tester.pump();
        await tester.pump();

        // 顺序模式：数量/权重/触发行可见
        expect(find.textContaining('触发概率'), findsOneWidget);
        expect(find.textContaining('抽取数量'), findsOneWidget);
        expect(find.text('随机权重'), findsOneWidget);
        // 输出顺序行是随机模式专属，顺序模式天然按池序输出
        expect(find.text('输出顺序'), findsNothing);
        expect(find.text('按抽中顺序'), findsNothing);
        expect(find.text('按池原序'), findsNothing);

        await tester.tap(find.text('确定'));
        await tester.pump();
        await tester.pump();

        expect(result, isNotNull);
        expect(result!.mode, PillRollMode.sequential);
      },
    );

    testWidgets('random mode still shows the order row (回归)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  await PillInstanceSettingsDialog.show(
                    context,
                    PillInstanceSettings.fixedDefault,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('随机抽取'));
      await tester.pump();
      await tester.pump();

      expect(find.text('输出顺序'), findsOneWidget);
      // Dropdown 未展开时只渲染当前选中项（默认按抽中顺序）
      expect(find.text('按抽中顺序'), findsOneWidget);
      expect(find.byType(DropdownButton<PillRollOrder>), findsOneWidget);
    });

    testWidgets('cancel returns null', (tester) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final r = await PillInstanceSettingsDialog.show(
                    context,
                    PillInstanceSettings.fixedDefault,
                  );
                  if (r == null) called = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('取消'));
      await tester.pump();
      await tester.pump();
      expect(called, isTrue);
    });
  });
}

// ==================== 测试搭建 ====================

class _AlternatingRandom implements Random {
  int _shuffleCalls = 0;

  void reset() => _shuffleCalls = 0;

  @override
  int nextInt(int max) {
    if (max <= 1) return 0;
    // 交替：0, max-1, 0, max-1...（roll 引擎里 nextInt(n>1) 只用于洗牌）
    final result = _shuffleCalls.isEven ? 0 : max - 1;
    _shuffleCalls++;
    return result;
  }

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}

Future<ProviderContainer> _pumpEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(
            PromptBlockLibraryState(
              blocks: [_block('style', '画风1', 'A, B')],
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

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

class _FakeCharacterPromptNotifier extends CharacterPromptNotifier {
  _FakeCharacterPromptNotifier(this._initial);

  final CharacterPromptConfig _initial;

  @override
  CharacterPromptConfig build() => _initial;

  @override
  void updateCharacter(CharacterPrompt character) {
    state = state.updateCharacter(character);
  }

  @override
  void removeCharacter(String id) {
    state = state.removeCharacter(id);
  }
}

/// 捕获 updatePrompt/updateNegativePrompt 推送的生成参数 fake
/// （真实现走 microtask+存储，测试环境不需要）。
class _FakeGenerationParamsNotifier extends GenerationParamsNotifier {
  String lastPrompt = '';
  String lastNegative = '';

  @override
  ImageParams build() => const ImageParams();

  @override
  void updatePrompt(String prompt) {
    lastPrompt = prompt;
    state = state.copyWith(prompt: prompt);
  }

  @override
  void updateNegativePrompt(String negativePrompt) {
    lastNegative = negativePrompt;
    state = state.copyWith(negativePrompt: negativePrompt);
  }
}

PromptBlock _block(String id, String title, String content) {
  return PromptBlock(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime(2026, 8, 31),
    updatedAt: DateTime(2026, 8, 31),
  );
}

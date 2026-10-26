import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  late GenRecorder r;
  setUp(() => r = GenRecorder());

  Future<void> pump(
    WidgetTester t, [
    GenViewData? data,
    double window = 1600,
    double height = 1120,
  ]) => pumpGen(
    t,
    data: data ?? GenFixture.view(),
    actions: r.actions,
    window: window,
    height: height,
  );

  group('布局', () {
    testWidgets('三栏宽度：左 420、历史 210，画布吃剩下的', (t) async {
      await pump(t);
      expect(t.getSize(find.byKey(const Key('gen-left'))).width, 420);
      expect(t.getSize(find.byKey(const Key('gen-history'))).width, 210);
      expect(
        t.getSize(find.byKey(const Key('gen-canvas'))).width,
        1552 - 420 - 210,
      );
    });

    testWidgets('收起左栏 / 历史栏回调布局', (t) async {
      await pump(t);
      await tapKey(t, 'gen-collapse-left');
      expect(r.last('onLayoutChanged'), contains('GenLayout'));
      await tapKey(t, 'gen-collapse-history');
      expect(
        r.calls.where((c) => c.startsWith('onLayoutChanged')),
        hasLength(2),
      );
    });

    testWidgets('收起后显示竖条，点竖条展开', (t) async {
      await pump(
        t,
        GenFixture.view(
          layout: const GenLayout(leftOpen: false, historyOpen: false),
        ),
      );
      expect(find.byKey(const Key('gen-left-strip')), findsOneWidget);
      expect(find.byKey(const Key('gen-history-strip')), findsOneWidget);
      await tapKey(t, 'gen-history-strip');
      expect(r.called('onLayoutChanged'), isTrue);
    });

    testWidgets('拖左栏边缘：松手才回调，夹在 352–560', (t) async {
      await pump(t);
      await t.drag(
        find.byKey(const Key('gen-left-resize')),
        const Offset(400, 0),
      );
      await t.pumpAndSettle();
      expect(
        r.calls.where((c) => c.startsWith('onLayoutChanged')),
        hasLength(1),
      );
      expect(r.last('onLayoutChanged'), contains('leftWidth: 560.0'));
    });

    testWidgets('窄窗口先把历史栏临时收成竖条，不回调', (t) async {
      await pump(t, null, 1000);
      expect(find.byKey(const Key('gen-history-strip')), findsOneWidget);
      expect(r.called('onLayoutChanged'), isFalse);
      expect(
        t.getSize(find.byKey(const Key('gen-canvas'))).width,
        greaterThanOrEqualTo(360),
      );
    });

    testWidgets('最窄 1100 × 700 没有溢出', (t) async {
      await pump(t, GenFixture.refsFull(), 1100, 700);
      expect(t.takeException(), isNull);
    });

    testWidgets('固定导航占宽后 564px 主区仍能显示与滚动画布工具', (t) async {
      await pump(t, null, 612, 860);
      expect(t.getSize(find.byKey(const Key('gen-canvas'))).width, 172);
      expect(find.byKey(const Key('gen-bar-top')), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('顶栏', () {
    testWidgets('模型菜单分新旧两组，选了回调', (t) async {
      await pump(t);
      await tapKey(t, 'gen-model');
      expect(find.text('旧模型'), findsOneWidget);
      await tapKey(t, 'gen-model-nai-diffusion-3');
      expect(r.last('onModelChanged'), 'onModelChanged(nai-diffusion-3)');
    });

    testWidgets('点 Anime 切 Furry', (t) async {
      await pump(t);
      await tapKey(t, 'gen-mode');
      expect(r.last('onFurryChanged'), 'onFurryChanged(true)');
    });

    testWidgets('额度数字允许超过 100%，旧模型仍隐藏对应格', (t) async {
      for (final (percent, label) in <(double, String)>[
        (141, '141%'),
        (275.5, '275.5%'),
        (12345, '12345%'),
        (0, '0%'),
      ]) {
        await pump(
          t,
          GenFixture.view().copyWith(
            quota: GenQuota(opusPercent: percent, anlas: 10668),
          ),
          1100,
          700,
        );
        final header = find.byKey(const Key('gen-header'));
        final value = find.descendant(of: header, matching: find.text(label));
        expect(value, findsOneWidget);
        expect(
          find.descendant(of: header, matching: find.text('100%')),
          findsNothing,
        );
        expect(t.getRect(header).contains(t.getCenter(value)), isTrue);
        expect(t.takeException(), isNull);
        await captureUiuxRegion(
          t,
          find.byKey(const Key('gen-capture')),
          'quota-${percent.toString().replaceAll('.', '-')}',
          t.getRect(header),
        );
      }
      await pump(t, GenFixture.view(v45: true));
      expect(find.text('147%'), findsNothing);
      await pump(t, GenFixture.v3());
      expect(find.byKey(const Key('gen-mode')), findsNothing);
    });
  });

  group('提示词', () {
    testWidgets('有角色时第一个页签叫“基础提示词”，切负面回调', (t) async {
      await pump(t);
      expect(find.text('基础提示词'), findsOneWidget);
      await tapKey(t, 'gen-tab-negative');
      expect(r.last('onNegativeTab'), 'onNegativeTab(true)');
    });

    testWidgets('没有角色时第一个页签同样叫“基础提示词”', (t) async {
      await pump(t, GenFixture.empty());
      expect(find.text('基础提示词'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('gen-tab-positive')),
          matching: find.text('正面'),
        ),
        findsNothing,
      );
    });

    testWidgets('编辑器槽位按目标填：基础正面 + 角色 0 正面', (t) async {
      final targets = <GenEditorTarget>[];
      await pumpGen(
        t,
        data: GenFixture.view(),
        slots: GenSlots(
          editor: (c, target) {
            targets.add(target);
            return Text('$target');
          },
        ),
      );
      expect(
        targets,
        containsAll(const [
          GenEditorTarget.base(),
          GenEditorTarget.character(0),
        ]),
      );
    });

    testWidgets('右上角 × 清空这一块', (t) async {
      await pump(t);
      await tapKey(t, 'gen-clear-base');
      expect(r.last('onClearPrompt'), 'onClearPrompt(base)');
    });

    testWidgets('V5 有透明背景，点了切换；V4.5 没有', (t) async {
      await pump(t);
      await tapKey(t, 'gen-transparent');
      expect(r.last('onTransparentChanged'), 'onTransparentChanged(true)');
      await pump(t, GenFixture.view(v45: true));
      expect(find.byKey(const Key('gen-transparent')), findsNothing);
    });

    testWidgets('质量词预设菜单', (t) async {
      await pump(t);
      await tapKey(t, 'gen-preset');
      await t.tap(find.text('标准'));
      await t.pumpAndSettle();
      expect(r.last('onQualityPreset'), 'onQualityPreset(standard)');
    });

    testWidgets('模块与开关：钉住工具、切设置开关，菜单不收起', (t) async {
      await pump(t);
      await tapKey(t, 'gen-tool-menu');
      await tapKey(t, 'gen-pin-palette');
      expect(
        r.last('onPromptTool'),
        'onPromptTool(GenPromptTool.palettePinned, false)',
      );
      await tapKey(t, 'gen-switch-sd');
      expect(
        r.last('onPromptTool'),
        'onPromptTool(GenPromptTool.sdConvert, true)',
      );
    });

    testWidgets('全屏编辑：弹窗里放同一块编辑器（fullscreen 目标）', (t) async {
      await pump(t);
      await tapKey(t, 'gen-tool-menu');
      await tapKey(t, 'gen-fullscreen');
      expect(find.byKey(const Key('gen-fullscreen-editor')), findsOneWidget);
      expect(find.byKey(const Key('gen-editor-base-full')), findsOneWidget);
      await tapKey(t, 'gen-fullscreen-close');
      expect(find.byKey(const Key('gen-fullscreen-editor')), findsNothing);
    });

    testWidgets('翻译：没配模型时点了去设置', (t) async {
      final d = GenFixture.view();
      await pump(
        t,
        d.copyWith(
          prompt: GenPromptData(
            qualityPresets: d.prompt.qualityPresets,
            translate: const GenTranslate(),
          ),
        ),
      );
      await tapKey(t, 'gen-translate-run');
      expect(r.called('onTranslationSettings'), isTrue);
    });

    testWidgets('块库侧栏按钮开关 dock', (t) async {
      await pump(t);
      await tapKey(t, 'gen-tool-dock');
      expect(r.called('onLayoutChanged'), isTrue);
    });
  });

  group('角色', () {
    testWidgets('添加菜单按性别', (t) async {
      await pump(t);
      await tapKey(t, 'gen-add-character');
      await tapKey(t, 'gen-add-male');
      expect(r.last('onAddCharacter'), 'onAddCharacter(GenGender.male)');
    });

    testWidgets('清空全部角色要确认', (t) async {
      await pump(t);
      await tapKey(t, 'gen-add-character');
      await tapKey(t, 'gen-clear-characters');
      expect(r.called('onClearCharacters'), isFalse);
      await tapKey(t, 'gen-confirm-ok');
      expect(r.called('onClearCharacters'), isTrue);
    });

    testWidgets('上移 / 下移 / 启用 / 删除', (t) async {
      await pump(t, GenFixture.characters());
      await tapKey(t, 'gen-character-down-0');
      expect(r.last('onMoveCharacter'), 'onMoveCharacter(0, 1)');
      await tapKey(t, 'gen-character-up-0');
      expect(
        r.calls.where((c) => c.startsWith('onMoveCharacter')),
        hasLength(1),
      );
      await tapKey(t, 'gen-character-enabled-2');
      expect(r.last('onCharacterEnabled'), 'onCharacterEnabled(2, true)');
      await tapKey(t, 'gen-character-delete-1');
      expect(r.last('onRemoveCharacter'), 'onRemoveCharacter(1)');
    });

    testWidgets('角色卡正负面页签是界面自己管的，切到负面换编辑器目标', (t) async {
      await pump(t);
      await tapKey(t, 'gen-character-tab-neg-0');
      expect(find.byKey(const Key('gen-editor-char0-neg')), findsOneWidget);
      expect(r.called('onNegativeTab'), isFalse);
    });

    testWidgets('双击名字改名，回车提交', (t) async {
      await pump(t);
      final name = find.byKey(const Key('gen-character-name-0'));
      await t.tap(name);
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(name);
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const Key('gen-character-rename-0')),
        '银发少女',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(r.last('onRenameCharacter'), 'onRenameCharacter(0, 银发少女)');
    });

    testWidgets('定位切换和定位板', (t) async {
      await pump(t);
      await tapKey(t, 'gen-position-custom');
      expect(r.last('onAiPositionChanged'), 'onAiPositionChanged(false)');
      await tapKey(t, 'gen-positioning');
      expect(r.last('onPositioningChanged'), 'onPositioningChanged(true)');
    });

    testWidgets('定位板：已放的角色在板上，未放的在托盘', (t) async {
      final d = GenFixture.characters();
      await pump(
        t,
        d.copyWith(
          canvas: GenCanvasData(
            focus: d.canvas.focus,
            info: d.canvas.info,
            positioning: true,
          ),
        ),
      );
      expect(find.byKey(const Key('gen-position-board')), findsOneWidget);
      expect(find.byKey(const Key('gen-position-chip-0')), findsOneWidget);
      expect(find.byKey(const Key('gen-position-tray')), findsOneWidget);
      expect(find.byKey(const Key('gen-bar-top')), findsNothing);
      await tapKey(t, 'gen-position-done');
      expect(r.last('onPositioningChanged'), 'onPositioningChanged(false)');
    });

    testWidgets('V3 没有角色模块', (t) async {
      await pump(t, GenFixture.v3());
      expect(find.byKey(const Key('gen-characters')), findsNothing);
    });
  });

  group('参考图', () {
    testWidgets('V5 只有图生图一行，V4.5 三行', (t) async {
      await pump(t);
      expect(find.byKey(const Key('gen-ref-vibe-row')), findsNothing);
      expect(find.byKey(const Key('gen-ref-precise-row')), findsNothing);
      await pump(t, GenFixture.view(v45: true));
      expect(find.byKey(const Key('gen-ref-vibe-row')), findsOneWidget);
      expect(find.byKey(const Key('gen-ref-precise-row')), findsOneWidget);
    });

    testWidgets('点行展开，空图生图给三个入口', (t) async {
      await pump(t);
      await tapKey(t, 'gen-ref-img2img-row');
      expect(find.byKey(const Key('gen-img2img-body')), findsOneWidget);
      await tapKey(t, 'gen-img2img-sketch');
      expect(r.called('onImg2ImgSketch'), isTrue);
    });

    testWidgets('风格迁移和精准参考同时启用时两边都提示冲突，可一键暂停 Vibe', (t) async {
      await pump(t, GenFixture.refsFull());
      expect(find.text('有精准参考，这次不会发送'), findsOneWidget);
      await tapKey(t, 'gen-ref-precise-row');
      await t.tap(find.text('暂停 Vibe'));
      await t.pumpAndSettle();
      expect(r.calls.where((c) => c.startsWith('onVibeChanged')), hasLength(2));
    });

    testWidgets('待编码的 Vibe 点“编码”', (t) async {
      await pump(t, GenFixture.refsFull());
      await tapKey(t, 'gen-ref-vibe-row');
      await tapKey(t, 'gen-vibe-encode-v2');
      expect(r.last('onEncodeVibe'), 'onEncodeVibe(v2)');
    });

    testWidgets('有蒙版时出局部重绘强度', (t) async {
      await pump(t, GenFixture.refsFull());
      await tapKey(t, 'gen-ref-img2img-row');
      expect(
        find.byKey(const Key('gen-img2img-inpaint-strength')),
        findsOneWidget,
      );
    });

    testWidgets('投放区包装和高亮', (t) async {
      final wrapped = <GenDropTarget>[];
      final d = GenFixture.view(v45: true);
      await pumpGen(
        t,
        data: d.copyWith(
          refs: GenRefsData(
            vibes: d.refs.vibes,
            precise: d.refs.precise,
            dropHover: GenDropTarget.vibe,
          ),
        ),
        slots: GenSlots(
          editor: (c, _) => const SizedBox(),
          drop: (c, target, child) {
            wrapped.add(target);
            return child;
          },
        ),
      );
      expect(wrapped.toSet(), GenDropTarget.values.toSet());
    });
  });

  group('图像与参数', () {
    testWidgets('换方向用同组预设', (t) async {
      await pump(t);
      await tapKey(t, 'gen-orientation-landscape');
      expect(r.last('onSizeChanged'), 'onSizeChanged(1216, 832)');
    });

    testWidgets('交换宽高', (t) async {
      await pump(t);
      await tapKey(t, 'gen-swap-size');
      expect(r.last('onSizeChanged'), 'onSizeChanged(1216, 832)');
    });

    testWidgets('手输宽度按 64 取整', (t) async {
      await pump(t);
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('gen-width')),
          matching: find.byType(TextField),
        ),
        '1000',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(r.last('onSizeChanged'), 'onSizeChanged(1024, 1216)');
    });

    testWidgets('张数分段和重复步进', (t) async {
      await pump(t);
      await tapKey(t, 'gen-count-3');
      expect(r.last('onCountChanged'), 'onCountChanged(3)');
      await tapKey(t, 'gen-repeat-up');
      expect(r.last('onRepeatChanged'), 'onRepeatChanged(2)');
      await tapKey(t, 'gen-repeat-down');
      expect(
        r.calls.where((c) => c.startsWith('onRepeatChanged')),
        hasLength(1),
      );
    });

    testWidgets('重复次数滚轮不改值，拖动 36px 松手只提交一次', (t) async {
      await pump(t);
      final value = find.byKey(const Key('gen-repeat-value'));
      final center = t.getCenter(value);
      await t.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, -40)),
      );
      await t.pump();
      expect(r.called('onRepeatChanged'), isFalse);
      final gesture = await t.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(36, 0));
      await t.pump();
      expect(r.called('onRepeatChanged'), isFalse);
      expect(find.byKey(const Key('gen-repeat-bubble')), findsOneWidget);
      expect(
        find.descendant(of: value, matching: find.text('4')),
        findsOneWidget,
      );
      await gesture.up();
      await t.pumpAndSettle();
      expect(r.calls.where((c) => c.startsWith('onRepeatChanged')), [
        'onRepeatChanged(4)',
      ]);
    });

    testWidgets('重复次数 Shift 拖动每格五次，负方向夹紧且取消不提交', (t) async {
      await pump(t);
      final value = find.byKey(const Key('gen-repeat-value'));
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      final gesture = await t.startGesture(
        t.getCenter(value),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(24, 0));
      await gesture.up();
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      expect(r.last('onRepeatChanged'), 'onRepeatChanged(11)');
      r.calls.clear();
      final cancelled = await t.startGesture(
        t.getCenter(value),
        kind: PointerDeviceKind.mouse,
      );
      await cancelled.moveBy(const Offset(10000, 0));
      await cancelled.cancel();
      await t.pumpAndSettle();
      expect(r.called('onRepeatChanged'), isFalse);
      await t.drag(value, const Offset(-60, 0));
      await t.pumpAndSettle();
      expect(r.called('onRepeatChanged'), isFalse);
    });

    testWidgets('重复拖动上限夹紧，只在松手提交', (t) async {
      await pump(t);
      final gesture = await t.startGesture(
        t.getCenter(find.byKey(const Key('gen-repeat-value'))),
      );
      await gesture.moveBy(const Offset(9999, 0));
      await t.pump();
      expect(r.called('onRepeatChanged'), false);
      await gesture.up();
      await t.pumpAndSettle();
      expect(
        r.last('onRepeatChanged'),
        'onRepeatChanged(${GenFixture.view().image.maxRepeat})',
      );
    });

    testWidgets('重复次数双击输入夹紧，回车确认、Esc 取消、失焦确认', (t) async {
      await pump(t);
      final value = find.byKey(const Key('gen-repeat-value'));
      Future<void> edit(String text) async {
        await t.tap(value);
        await t.pump(const Duration(milliseconds: 50));
        await t.tap(value);
        await t.pumpAndSettle();
        await t.enterText(find.byKey(const Key('gen-repeat-input')), text);
      }

      await edit('999999');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(
        r.last('onRepeatChanged'),
        'onRepeatChanged(${GenFixture.view().image.maxRepeat})',
      );
      r.calls.clear();
      await edit('9');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(r.called('onRepeatChanged'), isFalse);
      await edit('6');
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      expect(r.calls.where((c) => c.startsWith('onRepeatChanged')), [
        'onRepeatChanged(6)',
      ]);
    });

    testWidgets('参数条：点种子解除固定，点采样器出分组菜单', (t) async {
      await pump(t);
      expect(find.text('种子 · 固定'), findsOneWidget);
      await tapKey(t, 'gen-param-seed');
      expect(r.last('onSeedPinned'), 'onSeedPinned(false)');
      await tapKey(t, 'gen-param-sampler');
      await tapKey(t, 'gen-option-k_euler');
      expect(r.last('onSamplerChanged'), 'onSamplerChanged(k_euler)');
    });

    testWidgets('参数抽屉：展开、点遮罩收起', (t) async {
      await pump(t);
      await tapKey(t, 'gen-params-toggle');
      expect(find.byKey(const Key('gen-params-drawer')), findsOneWidget);
      expect(find.byKey(const Key('gen-drawer-noise')), findsNothing);
      await t.tapAt(
        t.getTopLeft(find.byKey(const Key('gen-left-scroll'))) +
            const Offset(30, 30),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('gen-params-drawer')), findsNothing);
    });

    testWidgets('V3 抽屉有噪声调度、Decrisp、SMEA', (t) async {
      await pump(t, GenFixture.v3());
      await tapKey(t, 'gen-params-toggle');
      expect(find.byKey(const Key('gen-drawer-noise')), findsOneWidget);
      expect(find.byKey(const Key('gen-decrisp')), findsOneWidget);
      expect(find.byKey(const Key('gen-smea-auto')), findsOneWidget);
    });
  });

  group('生成', () {
    testWidgets('就绪点生成，生成中点停止', (t) async {
      await pump(t);
      await tapKey(t, 'gen-generate');
      expect(r.called('onGenerate'), isTrue);
      await pump(t, GenFixture.generating());
      expect(find.text('停止生成'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      await tapKey(t, 'gen-generate');
      expect(r.called('onStop'), isTrue);
    });

    testWidgets('生成中：增强 / 变体 / 局部重绘不可点', (t) async {
      await pump(t, GenFixture.generating());
      await t.tap(find.byKey(const Key('gen-enhance')), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(r.called('onEnhance'), isFalse);
    });
  });

  group('画布', () {
    testWidgets('三条工具条的按钮作用在当前这张', (t) async {
      await pump(t);
      for (final (k, cb) in [
        ('gen-enhance', 'onEnhance(i1)'),
        ('gen-upscale', 'onUpscale(i1)'),
        ('gen-set-init', 'onSetInit(i1)'),
        ('gen-copy', 'onCopyImage(i1)'),
        ('gen-info', 'onOpenViewer(i1)'),
      ]) {
        await tapKey(t, k);
        expect(r.calls.last, cb);
      }
      await tapKey(t, 'gen-pin');
      expect(r.calls.last, 'onPin(i1, true)');
    });

    testWidgets('种子胶囊：用这个种子', (t) async {
      await pump(t);
      await tapKey(t, 'gen-seed-pill');
      await tapKey(t, 'gen-use-seed');
      expect(r.last('onUseSeed'), 'onUseSeed(i1)');
    });

    testWidgets('显示设置：换底纹、放大填满', (t) async {
      await pump(t);
      await tapKey(t, 'gen-display');
      await tapKey(t, 'gen-bd-checkerDark');
      expect(r.last('onBackdropChanged'), 'onBackdropChanged(checkerDark)');
      await tapKey(t, 'gen-zoom-fill');
      expect(r.last('onZoomToFillChanged'), 'onZoomToFillChanged(true)');
    });

    testWidgets('垫底：自定义色回车提交；V4.5 不出透明图就没有这一节', (t) async {
      await pump(t);
      await tapKey(t, 'gen-display');
      await t.enterText(find.byKey(const Key('gen-bd-hex')), '1a2b3c');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(r.last('onBackdropChanged'), 'onBackdropChanged(#1A2B3C)');
      await t.pumpWidget(const SizedBox());
      await pump(t, GenFixture.view(v45: true));
      await tapKey(t, 'gen-display');
      expect(find.byKey(const Key('gen-bd-checker')), findsNothing);
      expect(find.byKey(const Key('gen-zoom-fill')), findsOneWidget);
    });

    testWidgets('空画布给快捷键提示', (t) async {
      await pump(t, GenFixture.empty());
      expect(find.byKey(const Key('gen-canvas-empty')), findsOneWidget);
      expect(find.byKey(const Key('gen-bar-top')), findsNothing);
      expect(find.byKey(const Key('gen-history-empty')), findsOneWidget);
    });

    testWidgets('失败卡：重试、关闭', (t) async {
      await pump(t, GenFixture.failed());
      await tapKey(t, 'gen-retry');
      expect(r.called('onRetry'), isTrue);
      await tapKey(t, 'gen-error-close');
      expect(r.called('onDismissError'), isTrue);
    });

    testWidgets('多张一组：点另一张换焦点，300ms 内再点开大图', (t) async {
      await pump(t, GenFixture.generating());
      await tapKey(t, 'gen-tile-n1');
      expect(r.last('onFocusTile'), 'onFocusTile(n1)');
      await t.tap(find.byKey(const Key('gen-tile-n1')));
      await t.pumpAndSettle();
      expect(r.last('onOpenViewer'), 'onOpenViewer(n1)');
    });

    testWidgets('自定义画布引擎：每张图用给的 tile 画', (t) async {
      await pumpGen(
        t,
        data: GenFixture.view(),
        slots: GenSlots(
          editor: (c, _) => const SizedBox(),
          canvas: (context, tile) => Center(
            child: SizedBox(
              width: 100,
              height: 140,
              child: tile(context, GenFixture.view().canvas.focus!.tiles.first),
            ),
          ),
        ),
      );
      expect(
        t.getSize(find.byKey(const Key('gen-tile-i1'))),
        const Size(100, 140),
      );
      expect(find.byKey(const Key('gen-bar-top')), findsOneWidget);
    });
  });

  group('历史', () {
    testWidgets('单击切批，300ms 内再点开大图', (t) async {
      await pump(t);
      await tapKey(t, 'gen-batch-tile-b2');
      expect(r.last('onFocusBatch'), 'onFocusBatch(b2)');
      await t.tap(find.byKey(const Key('gen-batch-tile-b2')));
      await t.pumpAndSettle();
      expect(r.last('onOpenViewer'), 'onOpenViewer(i2)');
    });

    testWidgets('批次标题：时间 · 张数', (t) async {
      await pump(t);
      expect(find.text('16:31'), findsOneWidget);
      expect(find.text('· 4 张'), findsOneWidget);
    });

    testWidgets('多选：勾两批，保存的是两批里所有图；删除要确认', (t) async {
      await pump(t);
      await tapKey(t, 'gen-history-select');
      await tapKey(t, 'gen-batch-tile-b1');
      await tapKey(t, 'gen-batch-tile-b2');
      expect(r.called('onFocusBatch'), isFalse);
      expect(find.text('已选 3 张'), findsOneWidget);
      await tapKey(t, 'gen-history-save-selected');
      expect(r.last('onSaveImages'), 'onSaveImages([i1, i2, i3])');
      await tapKey(t, 'gen-history-delete-selected');
      await tapKey(t, 'gen-confirm-ok');
      expect(r.last('onDeleteImages'), 'onDeleteImages([i1, i2, i3])');
      expect(find.byKey(const Key('gen-history-selection')), findsNothing);
    });

    testWidgets('Ctrl+点击直接进多选', (t) async {
      await pump(t);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tapKey(t, 'gen-batch-tile-b3');
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(find.text('已选 4 张'), findsOneWidget);
    });

    testWidgets('右键菜单：发送到图生图、移除', (t) async {
      await pump(t);
      await t.tap(
        find.byKey(const Key('gen-batch-tile-b4')),
        buttons: kSecondaryButton,
      );
      await t.pumpAndSettle();
      await tapKey(t, 'gen-history-send-img2img');
      expect(r.last('onSendTo'), 'onSendTo(i5, GenSendTarget.img2img)');
    });

    testWidgets('清空历史要确认；自动保存开关', (t) async {
      await pump(t);
      await tapKey(t, 'gen-history-clear');
      await tapKey(t, 'gen-confirm-cancel');
      expect(r.called('onClearHistory'), isFalse);
      await tapKey(t, 'gen-autosave');
      expect(r.last('onAutoSaveChanged'), 'onAutoSaveChanged(false)');
    });

    testWidgets('生成中那一批：封面是第一张，标题写还剩几张', (t) async {
      await pump(t, GenFixture.generating());
      expect(find.text('· 还剩 3 张'), findsOneWidget);
    });
  });
}

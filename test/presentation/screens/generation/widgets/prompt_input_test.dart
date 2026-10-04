import 'package:nai_launcher/core/krita/bridge_session.dart';
import 'package:nai_launcher/presentation/widgets/bridge/agent_bridge_indicator.dart';
import 'package:nai_launcher/presentation/widgets/bridge/bridge_link_icon.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/data/models/image/image_params.dart'
    as image_model;
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_translation_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_input.dart';
import 'package:nai_launcher/presentation/widgets/common/weight_adjust_toolbar.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';

import '../../../../helpers/studio_capture_fonts.dart';
import 'package:nai_launcher/core/utils/app_language.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  setUpAll(() async {
    if (Platform.environment['CAPTURE_TRANSLATION_MENU'] != '1') return;
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('连接标识在负面右侧固定；真实字体五语言深浅色及窄窗弹层', (tester) async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    const agent = BridgeClient(
      id: 'test-agent',
      kind: BridgeClientKind.agent,
      name: 'Codex',
    );
    for (final locale in const [
      Locale('zh'),
      Locale('zh', 'TW'),
      Locale('en'),
      Locale('ja'),
      Locale('ko'),
    ]) {
      for (final brightness in Brightness.values) {
        for (final width in [360.0, 480.0]) {
          tester.view.devicePixelRatio = 1.25;
          tester.view.physicalSize = Size(width * 1.25, 680 * 1.25);
          final bridge = _VisibleAgentBridgeNotifier();
          final boundary = GlobalKey();
          bridge.show(
            const KritaBridgeState(
              enabled: true,
              status: KritaBridgeStatus.listening,
            ),
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                kritaBridgeNotifierProvider.overrideWith((ref) => bridge),
                bridgeClientBundleProvider.overrideWith(
                  (ref) async => const BridgeClientBundle(
                    r'C:\Studio Folder	ools\studio-bridge.exe',
                    available: true,
                  ),
                ),
                promptAssistantConfigProvider.overrideWith(
                  _TestPromptAssistantConfigNotifier.new,
                ),
                promptBlockLibraryNotifierProvider.overrideWith(
                  _EmptyPromptBlockLibraryNotifier.new,
                ),
                localStorageServiceProvider.overrideWith(
                  (ref) => _TestLocalStorageService(),
                ),
                characterPromptNotifierProvider.overrideWith(
                  _TestCharacterPromptNotifier.new,
                ),
                for (final target in PromptTokenCountTarget.values)
                  promptTokenUsageProvider(target).overrideWith(
                    (ref) async =>
                        const PromptTokenUsage(usedTokens: 0, limit: 512),
                  ),
              ],
              child: MaterialApp(
                theme: AppTheme.getTheme(AppStyle.geist, brightness),
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (_, child) =>
                    RepaintBoundary(key: boundary, child: child!),
                home: const Scaffold(
                  body: Padding(
                    padding: EdgeInsets.all(12),
                    child: PromptInputWidget(autoGrow: true),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final icon = find.byKey(const Key('agent-bridge-indicator'));
          final l = AppLocalizations.of(tester.element(icon))!;
          final negative = find.text(l.prompt_negativeTab);
          final before = tester.getRect(icon);
          expect(
            before.left,
            greaterThanOrEqualTo(tester.getRect(negative).right),
          );
          expect(
            (before.center.dy - tester.getRect(negative).center.dy).abs(),
            lessThan(2),
          );
          bridge.show(
            KritaBridgeState(
              enabled: true,
              session: BridgeSession(
                clients: const [agent],
                activities: [
                  BridgeActivity(
                    key: 'active',
                    client: agent,
                    operation: 'set_params',
                    at: DateTime(2026, 10, 4, 19, 0),
                  ),
                ],
              ),
            ),
          );
          await tester.pump();
          expect(tester.getRect(icon), before);
          expect(
            tester
                .widget<BridgeLinkIcon>(
                  find.descendant(
                    of: icon,
                    matching: find.byType(BridgeLinkIcon),
                  ),
                )
                .color,
            Theme.of(tester.element(icon)).colorScheme.primary,
          );
          await tester.tap(
            find
                .ancestor(of: negative, matching: find.byType(GestureDetector))
                .first,
          );
          await tester.pump(const Duration(milliseconds: 400));
          final afterTab = tester.getRect(icon);
          expect(afterTab.size, before.size);
          expect(afterTab.center.dy, before.center.dy);
          bridge.show(
            KritaBridgeState(
              enabled: true,
              session: BridgeSession(
                activities: [
                  BridgeActivity(
                    key: 'failure',
                    client: agent,
                    operation: 'set_params',
                    at: DateTime(2026, 10, 4, 19, 0),
                    status: BridgeActivityStatus.failed,
                    errorCode: 'conflict',
                  ),
                ],
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 700));
          expect(tester.getRect(icon), afterTab);
          expect(
            tester
                .widget<BridgeLinkIcon>(
                  find.descendant(
                    of: icon,
                    matching: find.byType(BridgeLinkIcon),
                  ),
                )
                .color,
            Colors.orange,
          );
          final container = ProviderScope.containerOf(tester.element(icon));
          final confirmed = BridgeActivity(
            key: 'confirmed',
            client: agent,
            operation: 'get_params',
            at: DateTime(2026, 10, 4, 19),
            finishedAt: DateTime(2026, 10, 4, 19),
            status: BridgeActivityStatus.completed,
            confirmedDraftVersion: container.read(bridgeDraftVersionProvider),
          );
          bridge.show(
            KritaBridgeState(
              enabled: true,
              session: BridgeSession(
                activities: [confirmed],
                latestAgentOutcome: confirmed,
              ),
            ),
          );
          await tester.pump();
          BridgeLinkIcon glyph() => tester.widget<BridgeLinkIcon>(
            find.descendant(of: icon, matching: find.byType(BridgeLinkIcon)),
          );
          expect(
            glyph().color,
            brightness == Brightness.dark
                ? const Color(0xFF63D79C)
                : const Color(0xFF17965F),
          );
          Future<void> captureState(String phase) async {
            if (Platform.environment['CAPTURE_AGENT_BRIDGE'] != '1') return;
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 1.25);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final file = File(
                '.dart_tool/bridge-motion-captures/$phase-${locale.toLanguageTag()}-${brightness.name}-${width.toInt()}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
          }

          await captureState('synced');
          final parameters = container.read(generationParamsNotifierProvider);
          container
              .read(generationParamsNotifierProvider.notifier)
              .updateSteps(parameters.steps + 1);
          await tester.pump();
          expect(
            glyph().color,
            Theme.of(
              tester.element(icon),
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          );
          expect(tester.getRect(icon), afterTab);
          await captureState('changed');
          await tester.tap(icon);
          await tester.pumpAndSettle();
          final panel = tester.getRect(find.byType(BridgeAgentPanel));
          expect(panel.left, greaterThanOrEqualTo(0));
          expect(panel.right, lessThanOrEqualTo(width));
          expect(panel.top, greaterThanOrEqualTo(before.bottom));
          expect(panel.top - before.bottom, lessThan(20));
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_AGENT_BRIDGE'] == '1') {
            final previousShadows = debugDisableShadows;
            debugDisableShadows = false;
            for (final render
                in tester.allRenderObjects.whereType<RenderPhysicalShape>()) {
              render.markNeedsPaint();
            }
            await tester.pump();
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 1.25);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final file = File(
                '.dart_tool/agent-bridge-captures/${locale.toLanguageTag()}-${brightness.name}-${width.toInt()}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
            });
            debugDisableShadows = previousShadows;
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
      }
    }
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  testWidgets('复制完整接手说明；客户端缺失禁用；最近活动限五项', (tester) async {
    final bridge = _VisibleAgentBridgeNotifier();
    const agent = BridgeClient(
      id: 'owner',
      kind: BridgeClientKind.agent,
      name: 'Codex',
    );
    bridge.show(
      KritaBridgeState(
        enabled: true,
        session: BridgeSession(
          clients: const [agent],
          activities: [
            for (var i = 0; i < 8; i++)
              BridgeActivity(
                key: '$i',
                client: BridgeClient(
                  id: '$i',
                  kind: BridgeClientKind.agent,
                  name: 'Agent-$i',
                ),
                operation: 'get_params',
                at: DateTime(2026, 10, 4),
                status: BridgeActivityStatus.completed,
              ),
          ],
        ),
      ),
    );
    var available = true;
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        kritaBridgeNotifierProvider.overrideWith((ref) => bridge),
        generationParamsNotifierProvider.overrideWith(_UnopenedDraftParams.new),
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
        ),
        characterPromptNotifierProvider.overrideWith(
          _TestCharacterPromptNotifier.new,
        ),
        bridgeClientBundleProvider.overrideWith(
          (ref) async => BridgeClientBundle(
            r'C:\Studio Folder	ools\studio-bridge.exe',
            available: available,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 340, child: BridgeAgentPanel()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Agent-4'), findsOneWidget);
    expect(find.textContaining('Agent-5'), findsNothing);
    await tester.tap(find.byKey(const Key('bridge-copy-guide')));
    await tester.pump();
    expect(copied, contains(r'C:\Studio Folder	ools\studio-bridge.exe'));
    expect(copied, contains('--base current.json'));
    expect(copied, contains('--quote quote.json --authorized'));
    expect(copied, contains('_draft.fields'));
    await tester.ensureVisible(
      find.byKey(const Key('bridge-disconnect-agents')),
    );
    await tester.tap(find.byKey(const Key('bridge-disconnect-agents')));
    expect(bridge.disconnects, 1);
    available = false;
    container.invalidate(bridgeClientBundleProvider);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('bridge-copy-guide')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
  });

  test('桥接回读未打开的文本框不创建或清空文档', () {
    final container = ProviderContainer(
      overrides: [
        generationParamsNotifierProvider.overrideWith(_UnopenedDraftParams.new),
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
        ),
        characterPromptNotifierProvider.overrideWith(
          _TestCharacterPromptNotifier.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    final draft = container.read(Provider((ref) => readBridgeDraft(ref)));
    expect(draft.fields['prompt'], 'unopened main');
    expect(draft.fields['negative_prompt'], 'unopened negative');
    expect(container.exists(pillWorkspaceProvider(PillScopes.main)), isFalse);
    expect(
      container.exists(pillWorkspaceProvider(PillScopes.negative)),
      isFalse,
    );
  });

  test('Windows 下提示词切换按钮不使用富文本 Tooltip', () {
    expect(usesRichPromptTypeTooltip(TargetPlatform.windows), isFalse);
  });

  testWidgets('未配置翻译模型时显示设置引导，不发送翻译请求', (tester) async {
    final captureBoundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptAssistantConfigProvider.overrideWith(
            _TestPromptAssistantConfigNotifier.new,
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: MaterialApp(
          theme: Platform.environment['CAPTURE_TRANSLATION_MENU'] == '1'
              ? AppTheme.getTheme(
                  AppStyle.geist,
                  Platform.environment['STUDIO_APPEARANCE'] == 'dark'
                      ? Brightness.dark
                      : Brightness.light,
                )
              : null,
          builder: (_, child) =>
              RepaintBoundary(key: captureBoundary, child: child!),
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt-translation-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('先配置翻译模型'), findsOneWidget);
    expect(find.text('前往设置'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    final control = tester.widget<Container>(
      find.byKey(const Key('prompt-translation-control')),
    );
    expect((control.decoration! as BoxDecoration).border, isNotNull);
    expect(
      tester.getSize(find.byKey(const Key('prompt-translation-control'))),
      const Size(44, 24),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('prompt-translation-control')),
        matching: find.byKey(const Key('prompt-translation-toggle')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('prompt-translation-control')),
        matching: find.byKey(const Key('prompt-translation-actions')),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('prompt-translation-actions')));
    await tester.pumpAndSettle();
    expect(find.text('未配置模型'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text('翻译新增内容'), findsNothing);
    expect(find.byTooltip('翻译新增内容'), findsOneWidget);
    expect(find.byKey(const Key('prompt-translation-undo')), findsNothing);
    expect(find.byTooltip('撤销上次翻译'), findsNothing);
    expect(
      find.byKey(const Key('prompt-translation-plain-text')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('prompt-translation-add')),
        matching: find.byIcon(Icons.add),
      ),
      findsOneWidget,
    );
    final menu = tester.widget<PopupMenuButton<String>>(
      find.byKey(const Key('prompt-translation-actions')),
    );
    expect(menu.constraints!.maxWidth, 176);
    expect(menu.menuPadding, EdgeInsets.zero);
    expect(
      tester.getSize(find.byKey(const Key('prompt-translation-menu'))),
      const Size(176, 126),
    );
    expect(
      tester
          .getSize(find.byKey(const Key('prompt-translation-configure')))
          .height,
      lessThanOrEqualTo(40),
    );
    expect(
      tester.getSize(find.byKey(const Key('prompt-translation-add'))).height,
      lessThanOrEqualTo(40),
    );
    expect(
      tester.getSize(find.byKey(const Key('prompt-translation-plain-text'))),
      const Size(74, 40),
    );
    expect(
      tester.getSize(find.byKey(const Key('prompt-translation-add'))),
      const Size(74, 40),
    );
    expect(find.text('操作教程'), findsOneWidget);
    await _captureTranslationMenu(tester, captureBoundary, 'menu');
    await tester.tap(find.byKey(const Key('prompt-translation-tutorial')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt-translation-guide')), findsOneWidget);
    expect(find.byKey(const Key('prompt-translation-add')), findsNothing);
    expect(tester.takeException(), isNull);
    await _captureTranslationMenu(tester, captureBoundary, 'guide');
    await tester.tap(find.byKey(const Key('translation-guide-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt-translation-add')), findsOneWidget);
    await tester.tap(find.byKey(const Key('prompt-translation-add')));
    await tester.pumpAndSettle();
    expect(find.text('先配置翻译模型'), findsOneWidget);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt-translation-menu')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PromptInputWidget)),
    );
    final positive = container.read(
      pillWorkspaceProvider(PillScopes.main).notifier,
    );
    final negative = container.read(
      pillWorkspaceProvider(PillScopes.negative).notifier,
    );
    positive.replaceWithPlainText('before, after');
    positive.insertTranslationAt(offset: 8, source: 'blue eyes', zh: '蓝眼睛');
    negative.insertTranslationAt(offset: 0, source: 'bad hands', zh: '坏手');
    final before = container
        .read(pillWorkspaceProvider(PillScopes.main))
        .document;
    final config =
        container.read(promptAssistantConfigProvider.notifier)
            as _TestPromptAssistantConfigNotifier;
    config.selectModelForTest('deepseek-flash');
    await tester.pump();

    await tester.tap(find.byKey(const Key('prompt-translation-actions')));
    await tester.pumpAndSettle();
    expect(find.text('deepseek-flash'), findsOneWidget);
    expect(find.byTooltip('DS / deepseek-flash'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('prompt-translation-plain-text')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('A'), findsOneWidget);
    await _captureTranslationMenu(tester, captureBoundary, 'blocks');
    await tester.tap(find.byKey(const Key('prompt-translation-plain-text')));
    await tester.pumpAndSettle();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'before, blue eyesafter',
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.instances,
      isEmpty,
    );
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.negative))
          .document
          .instances
          .length,
      1,
    );
    expect(find.byKey(const Key('prompt-translation-menu')), findsOneWidget);
    final restoreButton = tester.widget<IconButton>(
      find.byKey(const Key('prompt-translation-plain-text')),
    );
    expect(restoreButton.tooltip, '撤销原文还原，恢复翻译块');
    expect((restoreButton.icon as Icon).icon, Icons.undo);
    expect(restoreButton.onPressed, isNotNull);
    await _captureTranslationMenu(tester, captureBoundary, 'original');
    config.selectModelForTest(
      'a-very-long-model-name-that-must-fit-in-this-popover',
    );
    await tester.pumpAndSettle();
    final modelText = tester.widget<Text>(
      find.byKey(const Key('prompt-translation-model')),
    );
    expect(modelText.maxLines, 1);
    expect(modelText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('prompt-translation-plain-text')));
    await tester.pumpAndSettle();
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document,
      before,
    );
    expect(find.byKey(const Key('prompt-translation-menu')), findsOneWidget);
    expect(find.text('A'), findsOneWidget);

    container.read(promptTranslationBusyProvider.notifier).state = true;
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('prompt-translation-add')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('prompt-translation-plain-text')),
          )
          .onPressed,
      isNull,
    );
    container.read(promptTranslationBusyProvider.notifier).state = false;
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('prompt-translation-add')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('prompt-translation-plain-text')));
    await tester.pumpAndSettle();
    positive.replaceWithPlainText('new edit');
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('prompt-translation-plain-text')),
          )
          .onPressed,
      isNull,
    );
    // 菜单外的箭头命中弹层屏障，关闭菜单而不再次打开。
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('prompt-translation-actions'))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt-translation-menu')), findsNothing);
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'new edit',
    );
    await tester.tap(find.byKey(const Key('prompt-translation-actions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt-translation-menu')), findsOneWidget);
    await tester.tapAt(const Offset(10, 450));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt-translation-menu')), findsNothing);
    positive.replaceWithPlainText('before, after');
    positive.insertTranslationAt(offset: 8, source: 'blue eyes', zh: '蓝眼睛');
    positive.showAllTranslations(original: true);
    await tester.pumpAndSettle();
    final sourceInput = find.byKey(const Key('translation-pill-source-input'));
    await tester.tap(sourceInput);
    await tester.enterText(sourceInput, 'green eyes,\nsoft lighting');
    await tester.pump();
    await tester.pump();
    final inlineEditable = tester.state<EditableTextState>(
      find.descendant(of: sourceInput, matching: find.byType(EditableText)),
    );
    expect(
      inlineEditable.renderEditable
          .getLocalRectForCaret(const TextPosition(offset: 25))
          .top,
      closeTo(
        inlineEditable.renderEditable
            .getLocalRectForCaret(const TextPosition(offset: 12))
            .top,
        0.5,
      ),
    );
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances
          .values
          .single
          .translation!
          .source,
      'green eyes,\nsoft lighting',
    );
    await _captureTranslationMenu(tester, captureBoundary, 'inline-source');
    await tester.tap(find.byKey(const Key('prompt-translation-toggle')));
    await tester.pumpAndSettle();
    expect(sourceInput, findsNothing);
    expect(find.text('蓝眼睛'), findsOneWidget);
    expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    await _captureTranslationMenu(tester, captureBoundary, 'inline-reading');
    expect(tester.takeException(), isNull);
  });

  for (final code in ['en', 'ja', 'zh_TW', 'ko']) {
    testWidgets('translation menu and guide follow the $code interface', (
      tester,
    ) async {
      // Real fonts keep the translated menu measurements representative.
      await tester.runAsync(loadStudioCaptureFonts);
      final locale = AppLanguage.fromStorage(code).locale;
      final l10n = lookupAppLocalizations(locale);
      final captureBoundary = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => KritaBridgeNotifier(),
            ),
            promptAssistantConfigProvider.overrideWith(
              _TestPromptAssistantConfigNotifier.new,
            ),
            promptBlockLibraryNotifierProvider.overrideWith(
              _EmptyPromptBlockLibraryNotifier.new,
            ),
            localStorageServiceProvider.overrideWith(
              (ref) => _TestLocalStorageService(),
            ),
            characterPromptNotifierProvider.overrideWith(
              _TestCharacterPromptNotifier.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.getTheme(AppStyle.geist, Brightness.light),
            builder: (_, child) =>
                RepaintBoundary(key: captureBoundary, child: child!),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(
              body: SizedBox(
                width: 960,
                height: 420,
                child: PromptInputWidget(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('prompt-translation-toggle')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.promptTranslation_setupTitle), findsOneWidget);
      await tester.tap(find.text(l10n.promptTranslation_later));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('prompt-translation-actions')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.promptTranslation_noModel), findsOneWidget);
      expect(
        find.byTooltip(l10n.promptTranslation_translateNew),
        findsOneWidget,
      );
      expect(find.text(l10n.promptTranslation_tutorial), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _captureTranslationMenu(tester, captureBoundary, '$code-menu');
      await tester.tap(find.byKey(const Key('prompt-translation-tutorial')));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.promptTranslation_guideMiddleTitle),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _captureTranslationMenu(tester, captureBoundary, '$code-guide');
    });
  }

  testWidgets('冷启动时切换到负面提示词不会抛出异常', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith((ref) {
            return _TestLocalStorageService();
          }),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 官网式卡内页签：负面 = Undesired Content
    await tester.tap(find.text('Undesired Content').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey('generation_prompt_negative_input')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('负向药丸 lane：插入块投影进参数，外部写入同步进编辑器', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _EmptyPromptBlockLibraryNotifier(
              PromptBlockLibraryState(
                blocks: [
                  PromptBlock(
                    id: 'uc-block',
                    title: 'UC包',
                    content: 'lowres, bad anatomy',
                    color: '#FF123456',
                    createdAt: DateTime.utc(2026, 8, 30),
                    updatedAt: DateTime.utc(2026, 8, 30),
                  ),
                ],
                folders: const [],
              ),
            ),
          ),
          localStorageServiceProvider.overrideWith((ref) {
            return _TestLocalStorageService();
          }),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(const ValueKey('generation_prompt_positive_input')),
      ),
    );

    // 切到负面页签：负向药丸编辑器挂载
    await tester.tap(find.text('Undesired Content').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.byKey(const ValueKey('generation_prompt_negative_input')),
      findsOneWidget,
    );

    // 负向 lane 插块 → 投影写回生成参数
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .insertBlockAt(offset: 0, blockId: 'uc-block');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('UC包'), findsOneWidget);
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'lowres, bad anatomy',
    );

    // 外部写入（桥接/画廊发送汇点）→ 负向 lane 同步重建
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePrompt('external uc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      'external uc',
    );
    expect(find.byType(PromptPill), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ctrl+F 搜索选中命中且编辑提示词不重置光标', (tester) async {
    const prompt = 'alpha, beta, Alpha';
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => KritaBridgeNotifier(),
            ),
            promptBlockLibraryNotifierProvider.overrideWith(
              _EmptyPromptBlockLibraryNotifier.new,
            ),
            localStorageServiceProvider.overrideWith((ref) {
              return _TestLocalStorageService();
            }),
            characterPromptNotifierProvider.overrideWith(
              _TestCharacterPromptNotifier.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
          ],
          child: const MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 960,
                height: 420,
                child: PromptInputWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final promptField = find
          .descendant(
            of: find.byKey(const ValueKey('generation_prompt_positive_input')),
            matching: find.byType(TextField),
          )
          .first;

      await tester.tap(promptField);
      await tester.enterText(promptField, prompt);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final searchField = find.byKey(
        const ValueKey('prompt_input_search_field'),
      );
      expect(searchField, findsOneWidget);
      final promptTextField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == prompt,
      );
      expect(promptTextField, findsOneWidget);
      expect(
        tester.getBottomLeft(searchField).dy,
        lessThanOrEqualTo(tester.getTopLeft(promptTextField).dy),
      );

      await tester.enterText(searchField, 'alpha');
      await tester.pump();

      expect(find.text('1 / 2'), findsOneWidget);

      final promptEditable = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .singleWhere((editable) => editable.controller.text == prompt);
      expect(
        promptEditable.controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );

      final promptController = promptEditable.controller;
      final activePromptField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            identical(widget.controller, promptController),
      );
      await tester.tap(activePromptField);
      await tester.pump();

      const editedPrompt = '$prompt!';
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: editedPrompt,
          selection: TextSelection.collapsed(offset: editedPrompt.length),
        ),
      );
      await tester.pump();

      expect(promptController.text, editedPrompt);
      expect(
        promptController.selection,
        const TextSelection.collapsed(offset: editedPrompt.length),
      );
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Ctrl+H 展开替换栏并支持替换当前与全部替换', (tester) async {
    const prompt = 'alpha, beta, Alpha';
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kritaBridgeNotifierProvider.overrideWith(
              (ref) => KritaBridgeNotifier(),
            ),
            promptBlockLibraryNotifierProvider.overrideWith(
              _EmptyPromptBlockLibraryNotifier.new,
            ),
            localStorageServiceProvider.overrideWith((ref) {
              return _TestLocalStorageService();
            }),
            characterPromptNotifierProvider.overrideWith(
              _TestCharacterPromptNotifier.new,
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.positive,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
            promptTokenUsageProvider(
              PromptTokenCountTarget.negative,
            ).overrideWith(
              (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
            ),
          ],
          child: const MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                width: 960,
                height: 420,
                child: PromptInputWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final promptField = find
          .descendant(
            of: find.byKey(const ValueKey('generation_prompt_positive_input')),
            matching: find.byType(TextField),
          )
          .first;

      await tester.tap(promptField);
      await tester.enterText(promptField, prompt);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      final searchField = find.byKey(
        const ValueKey('prompt_input_search_field'),
      );
      final replaceField = find.byKey(
        const ValueKey('prompt_input_replace_field'),
      );
      expect(searchField, findsOneWidget);
      expect(replaceField, findsOneWidget);

      await tester.enterText(searchField, 'alpha');
      await tester.pump();
      await tester.enterText(replaceField, 'omega');
      await tester.pump();

      // 大小写不敏感搜索：alpha 与 Alpha 都应命中。
      expect(find.text('1 / 2'), findsOneWidget);

      final promptController = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .singleWhere((editable) => editable.controller.text == prompt)
          .controller;

      // 替换当前命中后应跳到后一处命中。
      await tester.tap(
        find.byKey(const ValueKey('prompt_input_replace_current')),
      );
      await tester.pump();
      expect(promptController.text, 'omega, beta, Alpha');
      expect(
        promptController.selection,
        const TextSelection(baseOffset: 13, extentOffset: 18),
      );

      // 全部替换应把剩余命中一次改完。
      await tester.tap(find.byKey(const ValueKey('prompt_input_replace_all')));
      await tester.pump();
      expect(promptController.text, 'omega, beta, omega');

      // 替换栏可折叠。
      await tester.tap(
        find.byKey(const ValueKey('prompt_input_replace_toggle')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('prompt_input_replace_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('prompt_input_search_field')),
        findsOneWidget,
      );

      // 全部替换的 toast 有 3 秒延迟 + 退场动画，需要等它彻底移除；
      // 输入框光标闪烁是周期定时器，这里不能用 pumpAndSettle。
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shared prompt input reads the disabled wheel setting', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(enablePromptWeightScroll: false),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();

    final wrapper = tester.widget<WeightAdjustToolbarWrapper>(
      find.byType(WeightAdjustToolbarWrapper).first,
    );
    final input = tester.widget<ThemedInput>(find.byType(ThemedInput).first);

    expect(wrapper.enableWheelAdjustment, isFalse);
    expect(input.scrollPhysics, isNull);
  });

  testWidgets('外部 provider 写入后编辑器同步显示新文本（协调器不依赖组件兜底）', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            _EmptyPromptBlockLibraryNotifier.new,
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(const ValueKey('generation_prompt_positive_input')),
      ),
    );

    // 模拟 Krita / 元数据导入 / 反推等外部路径：只写生成参数 provider。
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('external import, from bridge');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('external import, from bridge'), findsOneWidget);
    final pillWorkspace = container.read(pillWorkspaceNotifierProvider);
    expect(pillWorkspace.document.text, 'external import, from bridge');
    expect(pillWorkspace.projection, 'external import, from bridge');
    expect(tester.takeException(), isNull);
  });

  testWidgets('带块文档被外部整串写入后压扁为纯文本', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kritaBridgeNotifierProvider.overrideWith(
            (ref) => KritaBridgeNotifier(),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _EmptyPromptBlockLibraryNotifier(
              PromptBlockLibraryState(
                blocks: [
                  PromptBlock(
                    id: 'source-block-ui',
                    title: '画师组合',
                    content: 'artist:xyz',
                    color: '#FF123456',
                    createdAt: DateTime.utc(2026, 8, 30),
                    updatedAt: DateTime.utc(2026, 8, 30),
                  ),
                ],
                folders: const [],
              ),
            ),
          ),
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(),
          ),
          characterPromptNotifierProvider.overrideWith(
            _TestCharacterPromptNotifier.new,
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.positive,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
          promptTokenUsageProvider(
            PromptTokenCountTarget.negative,
          ).overrideWith(
            (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
          ),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(width: 960, height: 420, child: PromptInputWidget()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(const ValueKey('generation_prompt_positive_input')),
      ),
    );
    final pillNotifier = container.read(pillWorkspaceNotifierProvider.notifier);
    pillNotifier.replaceWithPlainText('1girl, ');
    pillNotifier.insertBlockAt(offset: 7, blockId: 'source-block-ui');
    await tester.pump();
    // 药丸编辑器：块渲染为内联药丸而非旧整行卡片
    expect(find.byType(PromptPill), findsOneWidget);
    expect(find.text('画师组合'), findsOneWidget);

    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePrompt('flattened replacement');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PromptPill), findsNothing);
    expect(find.text('flattened replacement'), findsOneWidget);
    final pillState = container.read(pillWorkspaceNotifierProvider);
    expect(pillState.document.text, 'flattened replacement');
    expect(pillState.document.instances, isEmpty);
    expect(pillState.projection, 'flattened replacement');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _captureTranslationMenu(
  WidgetTester tester,
  GlobalKey boundary,
  String state,
) async {
  if (Platform.environment['CAPTURE_TRANSLATION_MENU'] != '1') return;
  final previousShadows = debugDisableShadows;
  try {
    debugDisableShadows = false;
    for (final render
        in tester.allRenderObjects.whereType<RenderPhysicalShape>()) {
      render.markNeedsPaint();
    }
    await tester.pump();
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final appearance = Platform.environment['STUDIO_APPEARANCE'] ?? 'light';
      final file = File(
        '.dart_tool/translation-toggle-captures/$appearance-$state.png',
      );
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = previousShadows;
    for (final render
        in tester.allRenderObjects.whereType<RenderPhysicalShape>()) {
      render.markNeedsPaint();
    }
    await tester.pump();
  }
}

class _TestPromptAssistantConfigNotifier extends PromptAssistantConfigNotifier {
  _TestPromptAssistantConfigNotifier(super.ref);

  void selectModelForTest(String displayName) {
    state = PromptAssistantConfigState(
      providers: const [
        ProviderConfig(id: 'test', name: 'DS', baseUrl: 'https://example.test'),
      ],
      models: [
        ModelConfig(
          providerId: 'test',
          name: 'model',
          displayName: displayName,
        ),
      ],
      interfaces: const {
        LauncherInterface.translate: InterfaceSlotConfig(
          providerId: 'test',
          model: 'model',
        ),
      },
      providerHasApiKey: const {},
    );
  }
}

class _TestLocalStorageService extends LocalStorageService {
  @override
  Future<void> setSetting<T>(String key, T value) async {}
  _TestLocalStorageService({this.enablePromptWeightScroll = true});

  final bool enablePromptWeightScroll;

  @override
  bool getEnablePromptWeightScroll() => enablePromptWeightScroll;

  @override
  bool getEnableAutocomplete() => false;

  @override
  bool getAutoFormatPrompt() => false;

  @override
  bool getHighlightEmphasis() => false;

  @override
  bool getSdSyntaxAutoConvert() => false;

  @override
  bool getEnableCooccurrenceRecommendation() => false;

  @override
  String getLastPrompt() => '';

  @override
  Future<void> setLastPrompt(String prompt) async {}

  @override
  String getLastNegativePrompt() => '';

  @override
  Future<void> setLastNegativePrompt(String prompt) async {}

  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';

  @override
  String getDefaultSampler() => 'k_euler_ancestral';

  @override
  int getDefaultSteps() => 28;

  @override
  double getDefaultScale() => 5.0;

  @override
  int getDefaultWidth() => 832;

  @override
  int getDefaultHeight() => 1216;

  @override
  bool getLastSmea() => false;

  @override
  bool getLastSmeaDyn() => false;

  @override
  double getLastCfgRescale() => 0.0;

  @override
  String getLastNoiseSchedule() => 'native';
}

class _TestCharacterPromptNotifier extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

/// 药丸编辑器（正向主提示词）依赖块库；无 Hive 的测试环境用空库替代。
class _EmptyPromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _EmptyPromptBlockLibraryNotifier([this.initial]);

  final PromptBlockLibraryState? initial;

  @override
  Future<PromptBlockLibraryState> build() async =>
      initial ?? PromptBlockLibraryState(blocks: [], folders: []);
}

class _VisibleAgentBridgeNotifier extends KritaBridgeNotifier {
  int disconnects = 0;
  @override
  Future<void> disconnectAgents() async {
    disconnects++;
  }

  void show(KritaBridgeState value) => state = value;
  @override
  Future<void> close() async {}
}

class _UnopenedDraftParams extends GenerationParamsNotifier {
  @override
  image_model.ImageParams build() => const image_model.ImageParams(
    prompt: 'unopened main',
    negativePrompt: 'unopened negative',
  );
}

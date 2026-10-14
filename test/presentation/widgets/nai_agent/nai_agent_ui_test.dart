import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_composer.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_panel.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_generation_card.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_shared.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_input.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_artifact.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/nai_agent_settings_section.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/nai_agent_extensions_settings.dart';
import 'package:nai_launcher/presentation/screens/settings/sections/nai_agent_mcp_settings.dart';
import 'package:nai_launcher/core/nai_agent/mcp_config.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/agent_data_reader.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';

const _config = PromptAssistantConfigState(
  providers: [
    ProviderConfig(id: 'local', name: 'CPA', baseUrl: 'http://127.0.0.1'),
  ],
  models: [
    ModelConfig(
      providerId: 'local',
      name: 'model',
      displayName: 'devin/swe-2',
      supportsTools: true,
      contextWindow: 200000,
      reasoningEffort: 'medium',
      reasoningEfforts: ['none', 'low', 'medium', 'high'],
    ),
  ],
  interfaces: {},
  providerHasApiKey: {},
);

class _Local extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      key == StorageKeys.promptAssistantConfigJson
      ? _config.encode() as T
      : defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _Secrets extends SecureStorageService {
  final mcp = <String, String>{};
  @override
  Future<void> saveAgentMcpConfig(String id, String json) async {
    mcp[id] = json;
  }

  @override
  Future<String?> readAgentMcpConfig(String id) async => mcp[id];
  @override
  Future<void> deleteAgentMcpConfig(String id) async {
    mcp.remove(id);
  }

  @override
  Future<String?> getPromptAssistantApiKey(String id) async => null;
}

class _UiAuth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'synthetic');
  void simulateAccountChange() {
    state = const AuthState(
      status: AuthStatus.authenticated,
      accountId: 'new-synthetic',
    );
  }
}

class _Controller extends NaiAgentWorkspaceController {
  _Controller(AgentWorkspaceStore store)
    : super(
        store: store,
        initialWorkspaceName: '画风研究',
        initialChatName: '新聊天',
        startClient: (_, __, ___, ____, _____) =>
            Future.error(StateError('UI fixture must not start a model')),
      );
  int sends = 0;
  @override
  Future<void> send({bool steer = false}) async {
    sends++;
  }
}

// Widget tests run a fake clock; persistence has separate real IO coverage.
class _UiStore extends AgentWorkspaceStore {
  _UiStore(super.root);
  final attachmentBytes = <String, Uint8List>{};
  @override
  Future<AgentAttachment> addAttachment(
    String workspaceId,
    String sessionId, {
    required String name,
    required Uint8List bytes,
    required String mimeType,
    int? width,
    int? height,
    Map<String, dynamic>? metadata,
  }) async {
    final attachment = await super.addAttachment(
      workspaceId,
      sessionId,
      name: name,
      bytes: bytes,
      mimeType: mimeType,
      width: width,
      height: height,
      metadata: metadata,
    );
    attachmentBytes[attachment.id] = bytes;
    return attachment;
  }

  @override
  Future<Uint8List> readAttachment(
    String workspaceId,
    AgentAttachment attachment,
  ) async =>
      attachmentBytes[attachment.id] ??
      await super.readAttachment(workspaceId, attachment);
  AgentSettings value = const AgentSettings();
  @override
  Future<AgentSettings> readSettings() async => value;
  @override
  Future<AgentSettings> patchSettings(Map<String, dynamic> changes) async =>
      value = AgentSettings.fromJson({...value.toJson(), ...changes});
  @override
  Future<AgentSettings> configureExtension(
    String path, {
    bool? enabled,
    bool remove = false,
  }) => patchSettings({
    'extensions': [
      for (final extension in value.extensions)
        if (extension.path != path)
          extension.toJson()
        else if (!remove)
          {'path': path, 'enabled': enabled ?? extension.enabled},
    ],
  });
  @override
  Future<void> saveComposer(
    String workspaceId,
    String chatId,
    AgentComposerState state,
  ) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late Directory root;
  late _Controller c;
  late ProviderContainer container;
  late Future<List<DataReader>> Function() readClipboard;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-ui-');
    c = _Controller(_UiStore(root));
    readClipboard = () async => [];
    await c.initialize(restoreHistory: false);
    await c.updateSettings({'providerId': 'local', 'modelId': 'model'});
    container = ProviderContainer(
      overrides: [
        naiAgentNativeDragEnabledProvider.overrideWithValue(false),
        naiAgentClipboardReadersProvider.overrideWithValue(
          () => readClipboard(),
        ),
        naiAgentControllerProvider.overrideWith((_) => c),
        naiAgentWorkspaceStoreProvider.overrideWithValue(c.store),
        localStorageServiceProvider.overrideWithValue(_Local()),
        secureStorageServiceProvider.overrideWithValue(_Secrets()),
        authNotifierProvider.overrideWith(_UiAuth.new),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await c.close();
    await root.delete(recursive: true);
  });
  Future<void> pump(
    WidgetTester tester,
    Widget widget, {
    double width = 440,
    Locale locale = const Locale('zh'),
    Brightness brightness = Brightness.light,
    bool waitForFiles = false,
    GlobalKey? captureKey,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width, 860);
    tester.view.devicePixelRatio = 1;
    setCurrentL10nLocale(locale);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) =>
              RepaintBoundary(key: captureKey, child: child!),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.getTheme(AppStyle.geist, brightness),
          home: Scaffold(body: widget),
        ),
      ),
    );
    if (waitForFiles) {
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate()) {
          await precacheImage(
            (element.widget as Image).image,
            element,
            onError: (error, stack) {},
          );
        }
      });
    }
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.instance;
    binding.platformDispatcher.clearAllTestValues();
  });
  testWidgets('compact composer keeps workspace above and controls below', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      NaiAgentComposer(controller: c, runtime: c.selected!),
      width: 320,
    );
    final box = tester.getRect(find.byKey(const Key('nai-agent-composer')));
    final workspace = tester.getRect(
      find.byKey(const Key('nai-agent-workspace')),
    );
    final attach = tester.getRect(find.byKey(const Key('nai-agent-attach')));
    final mode = tester.getRect(find.byKey(const Key('nai-agent-mode')));
    final model = tester.getRect(find.byKey(const Key('nai-agent-model')));
    final thinking = tester.getRect(
      find.byKey(const Key('nai-agent-thinking')),
    );
    final ring = tester.getRect(find.byKey(const Key('nai-agent-context')));
    expect(workspace.bottom, lessThanOrEqualTo(box.top));
    expect(attach.top, greaterThanOrEqualTo(box.bottom));
    expect(mode.right, lessThanOrEqualTo(attach.left));
    expect(attach.right, lessThanOrEqualTo(model.left));
    expect(model.right, lessThanOrEqualTo(thinking.left));
    expect(thinking.right, lessThanOrEqualTo(ring.left));
    expect(tester.takeException(), isNull);
  });

  Future<void> finishImageImport(
    WidgetTester tester, {
    AgentChatRuntime? target,
  }) async {
    final runtime = target ?? c.selected!;
    final deadline = DateTime.now().add(const Duration(seconds: 8));
    while (runtime.importingImages > 0 && DateTime.now().isBefore(deadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(runtime.importingImages, 0);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ctrl+V preserves original attachment and exposes local metadata',
    (tester) async {
      final png = img.encodePng(
        img.Image(
          width: 2,
          height: 1,
          textData: {
            'Software': 'NovelAI',
            'Description': 'original prompt',
            'Comment': jsonEncode({
              'prompt': 'original prompt',
              'seed': 54321,
              'steps': 28,
            }),
          },
        ),
      );
      readClipboard = () async => [AgentFixtureDataReader(bytes: png)];
      await pump(tester, NaiAgentComposer(controller: c, runtime: c.selected!));
      final input = find.byKey(const Key('nai-agent-input'));
      await tester.enterText(input, 'keep text');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await finishImageImport(tester);
      final attachment = c.selected!.composer.attachments.single;
      expect(
        await tester.runAsync(
          () => c.store.readAttachment(c.selected!.workspace.id, attachment),
        ),
        png,
      );
      expect(c.selected!.composer.text, 'keep text');
      expect(attachment.metadata!['seed'], 54321);
      await pump(
        tester,
        NaiAgentComposer(controller: c, runtime: c.selected!),
        waitForFiles: true,
      );
      await tester.tap(
        find.byKey(ValueKey('agent-attachment-metadata-${attachment.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('54321'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('context menu image paste uses the same attachment route', (
    tester,
  ) async {
    readClipboard = () async => [
      AgentFixtureDataReader(
        bytes: img.encodePng(img.Image(width: 2, height: 1)),
      ),
    ];
    await pump(tester, NaiAgentComposer(controller: c, runtime: c.selected!));
    await tester.longPress(find.byKey(const Key('nai-agent-input')));
    await tester.pumpAndSettle();
    final toolbar = tester.widget<AdaptiveTextSelectionToolbar>(
      find.byType(AdaptiveTextSelectionToolbar),
    );
    toolbar.buttonItems!
        .singleWhere((item) => item.type == ContextMenuButtonType.paste)
        .onPressed!
        .call();
    await finishImageImport(tester);
    expect(c.selected!.composer.attachments, hasLength(1));
    final attachment = c.selected!.composer.attachments.single;
    expect(attachment.metadata, isNull);
    await pump(tester, NaiAgentComposer(controller: c, runtime: c.selected!));
    expect(find.byType(NaiAgentAttachmentThumbnail), findsOneWidget);
    expect(
      find.byKey(ValueKey('agent-attachment-metadata-${attachment.id}')),
      findsNothing,
    );
    expect(c.sends, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching during paste permits a new paste in the new chat', (
    tester,
  ) async {
    final first = c.selected!;
    final firstRead = Completer<List<DataReader>>();
    var reads = 0;
    final png = img.encodePng(img.Image(width: 2, height: 2));
    readClipboard = () => reads++ == 0
        ? firstRead.future
        : Future.value([AgentFixtureDataReader(bytes: png)]);
    Future<void> paste() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    await pump(tester, NaiAgentComposer(controller: c, runtime: first));
    await tester.enterText(
      find.byKey(const Key('nai-agent-input')),
      'first draft',
    );
    await paste();
    expect(first.importingImages, 1);
    await tester.runAsync(() => c.createWorkspace('second'));
    final second = c.selected!;
    await pump(tester, NaiAgentComposer(controller: c, runtime: second));
    await tester.enterText(
      find.byKey(const Key('nai-agent-input')),
      'second draft',
    );
    await paste();
    await finishImageImport(tester);
    expect(second.composer.attachments, hasLength(1));
    expect(first.composer.attachments, isEmpty);
    firstRead.complete([AgentFixtureDataReader(bytes: png)]);
    await finishImageImport(tester, target: first);
    expect(first.composer.attachments, hasLength(1));
    expect(second.composer.attachments, hasLength(1));
    expect(first.composer.text, 'first draft');
    expect(second.composer.text, 'second draft');
    expect(c.sends, 0);
  });

  testWidgets('rich clipboard failure falls back to text at latest selection', (
    tester,
  ) async {
    final complete = Completer<List<DataReader>>();
    readClipboard = () => complete.future;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async =>
          call.method == 'Clipboard.getData' ? {'text': ' pasted'} : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester, NaiAgentComposer(controller: c, runtime: c.selected!));
    final input = find.byKey(const Key('nai-agent-input'));
    await tester.enterText(input, 'old');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(input, 'latest');
    complete.completeError(StateError('rich clipboard unavailable'));
    await finishImageImport(tester);
    expect(c.selected!.composer.text, 'latest pasted');
    expect(c.selected!.composer.attachments, isEmpty);
  });
  testWidgets(
    'brand empty state is centered and suggestions only fill the composer',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, const NaiAgentPanel(), width: 380);
      final brand = tester.getRect(
        find.byKey(const Key('nai-agent-brand-welcome')),
      );
      final region = tester.getRect(
        find.byKey(const Key('nai-agent-empty-region')),
      );
      expect(brand.center.dy, closeTo(region.center.dy, 1));
      expect(find.byKey(const Key('nai-agent-brand-logo')), findsOneWidget);
      expect(find.text('从一个想法开始'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nai-agent-suggestion-0')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '看看当前草稿和参数，先不要修改。',
      );
      expect(c.sends, 0);
      await tester.tap(find.byKey(const Key('nai-agent-tip-next')));
      await tester.pumpAndSettle();
      expect(find.textContaining('拖入参考图'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nai-agent-tip-next')));
      await tester.pumpAndSettle();
      expect(find.textContaining('显示费用'), findsOneWidget);
      c.selected!.messages = [
        {'role': 'assistant', 'content': '已准备好讨论。'},
      ];
      await c.saveComposer('');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('nai-agent-brand-welcome')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'short narrow windows scroll the brand state without moving composer or header',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        const WindowChromeScope(child: NaiAgentPanel()),
        width: 320,
      );
      tester.view.physicalSize = const Size(320, 480);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('nai-agent-header'))).top, 0);
      await tester.ensureVisible(find.byKey(const Key('nai-agent-tip-next')));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('nai-agent-composer'))).bottom,
        lessThanOrEqualTo(480),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'approved brand state fits beside real caption controls in dark light and narrow panes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <String>[];
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add(call.method);
          return call.method == 'isMaximized' ? false : null;
        },
      );
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          null,
        ),
      );
      for (final (brightness, width) in [
        (Brightness.dark, 380.0),
        (Brightness.light, 380.0),
        (Brightness.dark, 320.0),
      ]) {
        final key = GlobalKey();
        await pump(
          tester,
          const IntegratedTitleBarShell(child: NaiAgentPanel()),
          width: width,
          brightness: brightness,
          captureKey: key,
        );
        expect(find.byKey(const Key('nai-agent-brand-logo')), findsOneWidget);
        expect(
          tester.getRect(find.byKey(const Key('nai-agent-header'))).height,
          39,
        );
        final label = tester.getRect(find.text('NAI Agent'));
        final minimize = tester.getRect(
          find.byIcon(Icons.remove).hitTestable(),
        );
        expect(label.right, lessThanOrEqualTo(minimize.left));
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['NAI_AGENT_BRAND_CAPTURES'];
        if (directory != null) {
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(find.byKey(key))
                .toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$directory/flutter-brand-${brightness.name}-${width.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      expect(calls, isNot(contains('setBounds')));
      expect(c.sends, 0);
    },
  );
  testWidgets('Agent header is a single 39px row', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester, const NaiAgentPanel(), width: 380);
    final header = tester.getRect(find.byKey(const Key('nai-agent-header')));
    expect(header.top, 0);
    expect(header.height, 39);
  });
  testWidgets('context ring separates current window from cumulative usage', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    c.selected!.context = {
      'tokens': 43200,
      'contextWindow': 200000,
      'percent': 21.6,
    };
    c.selected!.stats = {
      'tokens': {
        'input': 64900,
        'output': 4780,
        'cacheRead': 128400,
        'cacheWrite': 12000,
        'total': 210080,
      },
      'userMessages': 6,
      'assistantMessages': 9,
      'toolCalls': 14,
    };
    await pump(
      tester,
      NaiAgentComposer(controller: c, runtime: c.selected!),
      width: 320,
    );
    await tester.tap(find.byKey(const Key('nai-agent-context')));
    await tester.pumpAndSettle();
    expect(find.textContaining('43,200'), findsWidgets);
    expect(find.text('210,080'), findsOneWidget);
    expect(find.text('156,800'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('permission mode selector persists the actual mode', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(tester, NaiAgentComposer(controller: c, runtime: c.selected!));
    await tester.tap(find.byKey(const Key('nai-agent-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('只读').last);
    await tester.pumpAndSettle();
    expect(c.settings.toJson()['permissionMode'], 'readonly');
  });
  testWidgets('native caption reserve does not move the Agent header down', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      const WindowChromeScope(enabled: true, child: NaiAgentPanel()),
      width: 320,
    );
    expect(
      tester.getRect(find.byKey(const Key('nai-agent-header'))),
      const Rect.fromLTWH(0, 0, 320, 39),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Agent thinking selection is isolated from the model setting', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      NaiAgentComposer(controller: c, runtime: c.selected!),
      width: 320,
    );
    await tester.tap(find.byKey(const Key('nai-agent-thinking')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckedPopupMenuItem<String>).last);
    await tester.pumpAndSettle();
    expect(c.settings.reasoningEffort, 'high');
    expect(
      container
          .read(promptAssistantConfigProvider)
          .models
          .first
          .reasoningEffort,
      'medium',
    );
    await tester.tap(find.byKey(const Key('nai-agent-thinking')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('使用模型设置').last);
    await tester.pumpAndSettle();
    expect(c.settings.reasoningEffort, isNull);
  });
  testWidgets(
    'unknown model window never uses the SDK default as a confirmed limit',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      c.selected!.context = {
        'tokens': 43200,
        'contextWindow': 128000,
        'windowKnown': false,
      };
      await pump(tester, const NaiAgentPanel(), width: 320);
      await tester.tap(find.byKey(const Key('nai-agent-context')));
      await tester.pumpAndSettle();
      expect(find.textContaining('128,000'), findsNothing);
      expect(find.textContaining('43,200'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final locale in [
    const Locale('zh'),
    const Locale('zh', 'TW'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('ko'),
  ]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'compact layout matrix ${locale.toLanguageTag()} ${brightness.name}',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final r = c.selected!,
              broker = container.read(naiAgentQuestionsProvider);
          for (final width in [320.0, 380.0, 460.0]) {
            for (final state in [
              'empty',
              'multiline',
              'running',
              'approval',
              'stats',
              'unknown',
            ]) {
              r.running = state == 'running';
              r.messages = state == 'empty' || state == 'unknown'
                  ? []
                  : [
                      {'role': 'assistant', 'content': '任务概览已准备好。'},
                    ];
              r.context = state == 'empty' || state == 'unknown'
                  ? {}
                  : {
                      'tokens': 43200,
                      'contextWindow': 200000,
                      'windowKnown': true,
                    };
              r.stats = {
                'tokens': {
                  'input': 64900,
                  'output': 4780,
                  'cacheRead': 128400,
                  'cacheWrite': 12000,
                  'total': 210080,
                },
                'userMessages': 6,
                'assistantMessages': 9,
                'toolCalls': 14,
              };
              await c.saveComposer(
                state == 'multiline'
                    ? List.filled(12, '整理当前提示词并保留原始草稿').join('\n')
                    : '',
              );
              final key = GlobalKey();
              await pump(
                tester,
                const NaiAgentPanel(),
                width: width,
                locale: locale,
                brightness: brightness,
                captureKey: key,
                settle: state != 'running',
              );
              Future<Map<String, dynamic>>? approval;
              if (state == 'approval') {
                final l = AppLocalizations.of(
                  tester.element(find.byType(NaiAgentPanel)),
                )!;
                approval = broker.askExtensionUi(r.workspace.id, r.chat.id, {
                  'method': 'select',
                  'kind': 'tool_approval',
                  'title':
                      '${l.naiAgent_permissionTitle}: mcp__nai_studio__prompt_update\n{"changes":{"prompt":"test"}}',
                  'options': [
                    l.naiAgent_permissionOnce,
                    l.naiAgent_permissionSession,
                    l.naiAgent_permissionDeny,
                  ],
                }, NaiAgentCancellation());
                await tester.pumpAndSettle();
              }
              final header = tester.getRect(
                find.byKey(const Key('nai-agent-header')),
              );
              expect(header.top, 0);
              expect(header.height, 39);
              final input = tester.getRect(
                find.byKey(const Key('nai-agent-composer')),
              );
              final controls = [
                for (final id in [
                  'mode',
                  'attach',
                  'model',
                  'thinking',
                  'context',
                ])
                  tester.getRect(find.byKey(Key('nai-agent-$id'))),
              ];
              expect(
                tester
                    .getRect(find.byKey(const Key('nai-agent-workspace')))
                    .bottom,
                lessThanOrEqualTo(input.top),
              );
              expect(input.left, greaterThanOrEqualTo(0));
              expect(input.right, lessThanOrEqualTo(width));
              for (var i = 0; i < controls.length - 1; i++) {
                expect(
                  controls[i].right,
                  lessThanOrEqualTo(controls[i + 1].left),
                );
              }
              expect(controls.first.top, greaterThanOrEqualTo(input.bottom));
              expect(controls.last.right, lessThanOrEqualTo(width));
              if (state == 'stats') {
                await tester.tap(find.byKey(const Key('nai-agent-context')));
                await tester.pumpAndSettle();
                final stats = tester.getRect(
                  find.byKey(const Key('nai-agent-statistics')),
                );
                expect(stats.left, greaterThanOrEqualTo(8));
                expect(stats.right, lessThanOrEqualTo(width - 10));
                expect(stats.top, greaterThanOrEqualTo(0));
                expect(stats.bottom, lessThanOrEqualTo(860));
              }
              expect(
                tester.takeException(),
                isNull,
                reason: '$locale ${brightness.name} $width $state',
              );
              final directory =
                  Platform.environment['NAI_AGENT_COMPOSER_CAPTURES'];
              if (directory != null && locale == const Locale('zh')) {
                await tester.runAsync(() async {
                  final pixels = await tester
                      .renderObject<RenderRepaintBoundary>(find.byKey(key))
                      .toImage(pixelRatio: 1);
                  final data = await pixels.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  await Directory(directory).create(recursive: true);
                  await File(
                    '$directory/${brightness.name}-${width.toInt()}-$state.png',
                  ).writeAsBytes(data!.buffer.asUint8List());
                  pixels.dispose();
                });
              }
              if (approval != null) {
                broker.cancel(broker.forChat(r.chat.id).single.id);
                await approval;
              }
              await tester.pumpWidget(const SizedBox());
            }
          }
        },
      );
    }
  }
  testWidgets(
    'composer grows upwards to a cap; IME composition does not send',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: NaiAgentComposer(controller: c, runtime: c.selected!),
        ),
      );
      final composer = find.byKey(const Key('nai-agent-composer'));
      final field = find.byKey(const Key('nai-agent-input'));
      final before = tester.getRect(composer);
      await tester.enterText(field, '第一行\n第二行\n第三行');
      await tester.pump();
      final after = tester.getRect(composer);
      expect(after.height, greaterThan(before.height));
      expect(after.bottom, closeTo(before.bottom, 1));
      await tester.enterText(
        field,
        List.generate(24, (i) => '第$i行').join('\n'),
      );
      await tester.pump();
      expect(tester.getSize(composer).height, lessThan(290));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '输入中',
          selection: TextSelection.collapsed(offset: 3),
          composing: TextRange(start: 0, end: 3),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(c.sends, 0);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '完成输入',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(c.sends, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(c.sends, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('no configured model disables send; input is preserved', (
    tester,
  ) async {
    await c.updateSettings({'providerId': '', 'modelId': ''});
    await c.saveComposer('先保留这段输入');
    await pump(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: NaiAgentComposer(controller: c, runtime: c.selected!),
      ),
    );
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('nai-agent-send')))
          .onPressed,
      isNull,
    );
    expect(c.selected!.composer.text, '先保留这段输入');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'restored local tool artifact stays visible with its tool card collapsed',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = c.selected!;
      final output = File('${r.workspace.directory.path}/image.png');
      output.writeAsBytesSync(img.encodePng(img.Image(width: 72, height: 48)));
      r.messages = [
        {
          'role': 'assistant',
          'timestamp': 1,
          'content': [
            {
              'type': 'toolCall',
              'id': 'local-result',
              'name': 'image_tool',
              'arguments': {'action': 'upscale'},
            },
          ],
        },
        {
          'role': 'toolResult',
          'toolCallId': 'local-result',
          'isError': false,
          'content': <Map<String, dynamic>>[],
          'details': {
            'ok': true,
            'artifacts': [
              {'type': 'image', 'path': 'image.png'},
            ],
          },
        },
      ];
      await pump(tester, const NaiAgentPanel(), waitForFiles: true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NaiAgentImageArtifact), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('image.png'), findsOneWidget);
      expect(find.text('upscale'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'restored CodeMode image artifact stays visible with its tool card collapsed',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = c.selected!;
      final output = File('${r.workspace.directory.path}/image.png');
      output.writeAsBytesSync(img.encodePng(img.Image(width: 72, height: 48)));
      r.messages = [
        {
          'role': 'assistant',
          'timestamp': 1,
          'content': [
            {
              'type': 'toolCall',
              'id': 'local-result',
              'name': 'codemode',
              'arguments': {
                'code':
                    'await tools.mcp__nai_studio__image_tool({action: "upscale"})',
              },
            },
          ],
        },
        {
          'role': 'toolResult',
          'toolCallId': 'local-result',
          'isError': false,
          'content': <Map<String, dynamic>>[],
          'details': {
            'ok': true,
            'artifacts': [
              {'type': 'image', 'path': 'image.png'},
            ],
          },
        },
      ];
      await pump(tester, const NaiAgentPanel(), waitForFiles: true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NaiAgentImageArtifact), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('image.png'), findsOneWidget);
      expect(find.text('upscale'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'live image approval appears in the selected chat and its button answers the image tool',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final runtime = c.selected!,
          broker = container.read(naiAgentImageApprovalsProvider);
      final result = broker.request(
        NaiAgentConversationOwner(runtime.workspace.id, runtime.chat.id),
        {
          'tool': 'cloud_upscale',
          'width': 832,
          'height': 1216,
          'account_name': 'Synthetic account',
          'estimated_anlas': 1,
          'balance_anlas': 2218,
        },
        DateTime.now().add(const Duration(minutes: 5)),
        NaiAgentCancellation(),
        () {},
      );
      await pump(tester, const NaiAgentPanel(), width: 320);
      expect(find.byKey(const Key('agent-image-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-image-confirm')));
      await tester.pump();
      expect(await result, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  NaiAgentGenerationQuote generationQuote() => NaiAgentGenerationQuote(
    id: 'ui-quote',
    input: NaiAgentGenerationInput(
      raw: const ImageParams(nSamples: 2),
      effective: const ImageParams(
        model: 'nai-diffusion-4-5-full',
        width: 832,
        height: 1216,
      ),
      draftVersion: 'ui-draft',
      batchSize: 3,
      billing: {
        'estimated_anlas': 50,
        'per_request_anlas': 24,
        'encoding_anlas': 2,
        'balance_anlas': 2218,
      },
      accountId: 'synthetic',
      accountName: '本地测试账号 · Synthetic account',
      endpoint: 'local',
      localEnhance: {'model': 'SeedVR2 7B Sharp INT8 ConvRot', 'scale': 2.0},
    ),
    params: {},
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  );
  testWidgets(
    'generation card requires explicit click; stale quote disables Generate but permits Cancel',
    (tester) async {
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      var accepted = false;
      final account = container.read(authNotifierProvider).accountId;
      final future = broker
          .request(
            NaiAgentConversationOwner(
              c.selected!.workspace.id,
              c.selected!.chat.id,
            ),
            generationQuote(),
            NaiAgentCancellation(),
            () {
              if (container.read(authNotifierProvider).accountId != account) {
                throw const NaiAgentToolError('quote_changed', 'Changed');
              }
            },
          )
          .then((answer) {
            accepted = answer;
            return answer;
          });
      final request = broker.forChat(c.selected!.chat.id).single;
      await pump(
        tester,
        Center(child: NaiAgentGenerationCard(request: request)),
      );
      expect(accepted, false);
      expect(find.textContaining('50 Anlas'), findsOneWidget);
      expect(find.textContaining('2,218'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(accepted, false);
      (container.read(authNotifierProvider.notifier) as _UiAuth)
          .simulateAccountChange();
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('agent-generation-confirm')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('agent-generation-decline')));
      await tester.pump();
      expect(await future, false);
      expect(c.sends, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'generation approval is rendered in the owning conversation and click answers its tool',
    (tester) async {
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      final future = broker.request(
        NaiAgentConversationOwner(
          c.selected!.workspace.id,
          c.selected!.chat.id,
        ),
        generationQuote(),
        NaiAgentCancellation(),
        () {},
      );
      await pump(tester, const NaiAgentPanel());
      expect(find.byType(NaiAgentGenerationCard), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('agent-generation-confirm')),
      );
      await tester.tap(find.byKey(const Key('agent-generation-confirm')));
      await tester.pump();
      expect(await future, true);
      expect(c.sends, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'generation quote with real fonts fits $locale ${brightness.name} at 320/440px',
        (tester) async {
          final broker = container.read(naiAgentGenerationApprovalsProvider);
          final future = broker.request(
            NaiAgentConversationOwner(
              c.selected!.workspace.id,
              c.selected!.chat.id,
            ),
            generationQuote(),
            NaiAgentCancellation(),
            () {},
          );
          final request = broker.forChat(c.selected!.chat.id).single;
          for (final width in [320.0, 440.0]) {
            final key = GlobalKey();
            await pump(
              tester,
              RepaintBoundary(key: key, child: const NaiAgentPanel()),
              width: width,
              locale: Locale(locale),
              brightness: brightness,
            );
            await tester.ensureVisible(
              find.byKey(const Key('agent-generation-confirm')),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getRect(find.byType(NaiAgentGenerationCard)).right,
              lessThanOrEqualTo(width),
            );
            if (Platform.environment['CAPTURE_NAI_AGENT'] == '1' &&
                locale == 'zh') {
              await tester.runAsync(() async {
                final pixels =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final png = await pixels.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory(
                  '.dart_tool/nai-agent-stage-e3/native-captures',
                )..createSync(recursive: true);
                File(
                  '${folder.path}/generation-$locale-${brightness.name}-${width.toInt()}.png',
                ).writeAsBytesSync(png!.buffer.asUint8List());
                pixels.dispose();
              });
            }
          }
          broker.decide(request.id, generate: false);
          await tester.pump();
          await future;
          await tester.pumpWidget(const SizedBox());
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        },
      );
    }
  }
  testWidgets(
    'MCP editor saves only metadata in settings and encrypted config separately',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        const SingleChildScrollView(child: NaiAgentMcpSettings()),
        width: 780,
      );
      await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('nai-mcp-name')), 'docs');
      await tester.enterText(
        find.byKey(const Key('nai-mcp-config')),
        '{"url":"https://example.com/mcp","headers":{"Authorization":"Bearer private-secret"}}',
      );
      await tester.tap(find.byKey(const Key('nai-mcp-save')));
      await tester.pumpAndSettle();
      expect(c.settings.mcpServers.single.name, 'docs');
      expect(
        jsonEncode(c.settings.toJson()),
        isNot(contains('private-secret')),
      );
      final secure = container.read(secureStorageServiceProvider) as _Secrets;
      expect(
        secure.mcp[c.settings.mcpServers.single.configId],
        contains('private-secret'),
      );
      await tester.tap(find.widgetWithIcon(IconButton, Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.textContaining('private-secret'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pumpAndSettle();
      expect(c.settings.mcpServers, isEmpty);
      expect(secure.mcp, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'MCP tools and real fonts fit $locale ${brightness.name} at 320/780px',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await c.updateSettings({
            'mcpServers': [
              const AgentMcpServer(
                name: 'my-document-server',
                configId: 'mock-secure',
                transport: 'http',
              ).toJson(),
            ],
          });
          for (final width in [320.0, 780.0]) {
            await pump(
              tester,
              SingleChildScrollView(
                child: RepaintBoundary(
                  key: const Key('mcp-capture'),
                  child: Material(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: NaiAgentMcpSettings(
                        key: ValueKey('$locale-${brightness.name}-$width'),
                      ),
                    ),
                  ),
                ),
              ),
              width: width,
              locale: Locale(locale),
              brightness: brightness,
            );
            await tester.tap(find.text(currentL10n.naiAgent_mcpBuiltin));
            await tester.pumpAndSettle();
            expect(find.text('prompt_update'), findsOneWidget);
            expect(find.text('my-document-server'), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (Platform.environment['CAPTURE_NAI_AGENT_MCP'] == '1') {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('mcp-capture')),
              );
              await tester.runAsync(() async {
                final capture = await boundary.toImage(pixelRatio: 1);
                final data = await capture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = await Directory(
                  '.dart_tool/nai-agent-mcp/captures',
                ).create(recursive: true);
                await File(
                  '${folder.path}/mcp-$locale-${brightness.name}-${width.toInt()}.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                capture.dispose();
              });
            }
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'question requires explicit submit and answers the tool, without a queued chat',
    (tester) async {
      final broker = container.read(naiAgentQuestionsProvider),
          token = NaiAgentCancellation();
      var answered = false;
      final result = broker
          .ask(c.selectedWorkspace!.id, c.selected!.chat.id, {
            'questions': [
              {
                'id': 'direction',
                'question': '先处理哪一步？',
                'options': ['整理标签', '分析图片'],
              },
            ],
          }, token)
          .then((value) {
            answered = true;
            return value;
          });
      final request = broker.forChat(c.selected!.chat.id).single;
      await pump(
        tester,
        Center(
          child: SizedBox(
            width: 400,
            child: NaiAgentQuestionCard(request: request),
          ),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '提交回答'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, '分析图片'));
      await tester.pump();
      expect(answered, false);
      await tester.tap(find.widgetWithText(FilledButton, '提交回答'));
      await tester.pump();
      final reply = await result;
      expect((reply['details'] as Map)['answers'], [
        {'id': 'direction', 'question': '先处理哪一步？', 'answer': '分析图片'},
      ]);
      expect(c.selected!.composer.pending, isEmpty);
      expect(c.sends, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'extension select and editor use native cards with exact answers at 320px',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final broker = container.read(naiAgentQuestionsProvider);
      final selected = broker.askExtensionUi(
        c.selectedWorkspace!.id,
        c.selected!.chat.id,
        {
          'method': 'select',
          'title': 'Choose',
          'options': ['One', 'Two'],
        },
        NaiAgentCancellation(),
      );
      await pump(
        tester,
        SingleChildScrollView(
          child: NaiAgentQuestionCard(
            request: broker.forChat(c.selected!.chat.id).single,
          ),
        ),
        width: 320,
      );
      expect(find.byType(TextField), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Two'));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect((await selected)['details'], {
        'status': 'answered',
        'value': 'Two',
      });
      await tester.pumpWidget(const SizedBox());
      final edited = broker.askExtensionUi(
        c.selectedWorkspace!.id,
        c.selected!.chat.id,
        {'method': 'editor', 'title': 'Edit', 'prefill': '  initial\n'},
        NaiAgentCancellation(),
      );
      await pump(
        tester,
        SingleChildScrollView(
          child: NaiAgentQuestionCard(
            request: broker.forChat(c.selected!.chat.id).single,
          ),
        ),
        width: 320,
      );
      final editor = tester.widget<TextField>(find.byType(TextField));
      expect(editor.controller!.text, '  initial\n');
      expect(editor.maxLines, 8);
      await tester.enterText(find.byType(TextField), '\n  edited\n');
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect((await edited)['details'], {
        'status': 'answered',
        'value': '\n  edited\n',
      });
      expect(c.sends, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'instruction editors save and clear independently without replacing the base prompt',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(
        tester,
        const SingleChildScrollView(child: NaiAgentSettingsSection()),
        width: 780,
      );
      final global = find.byKey(const Key('nai-agent-globalInstructions'));
      final prefix = find.byKey(const Key('nai-agent-systemPromptPrefix'));
      await tester.enterText(global, 'SHARED_RULE');
      await tester.enterText(prefix, 'PREFIX_IDENTITY');
      expect(c.settings.globalInstructions, isEmpty);
      expect(c.settings.systemPromptPrefix, isEmpty);
      await tester.ensureVisible(
        find.byKey(const Key('nai-agent-save-globalInstructions')),
      );
      await tester.tap(
        find.byKey(const Key('nai-agent-save-globalInstructions')),
      );
      await tester.pumpAndSettle();
      expect(c.settings.globalInstructions, 'SHARED_RULE');
      expect(c.settings.systemPromptPrefix, isEmpty);
      expect(
        tester.widget<TextField>(prefix).controller!.text,
        'PREFIX_IDENTITY',
      );
      await tester.ensureVisible(
        find.byKey(const Key('nai-agent-save-systemPromptPrefix')),
      );
      await tester.tap(
        find.byKey(const Key('nai-agent-save-systemPromptPrefix')),
      );
      await tester.pumpAndSettle();
      expect(c.settings.systemPromptPrefix, 'PREFIX_IDENTITY');
      expect(c.settings.customSystemPrompt, isNull);
      await tester.enterText(global, '');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('nai-agent-save-globalInstructions')),
      );
      await tester.tap(
        find.byKey(const Key('nai-agent-save-globalInstructions')),
      );
      await tester.pumpAndSettle();
      expect(c.settings.globalInstructions, isEmpty);
      expect(c.settings.systemPromptPrefix, 'PREFIX_IDENTITY');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final save in [false, true]) {
    testWidgets(
      'leaving instructions ${save ? 'saves' : 'discards'} all unsaved fields',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey<NaiAgentSettingsSectionState>();
        await pump(
          tester,
          SingleChildScrollView(child: NaiAgentSettingsSection(key: key)),
          width: 780,
        );
        await tester.enterText(
          find.byKey(const Key('nai-agent-globalInstructions')),
          'SHARED_RULE',
        );
        await tester.enterText(
          find.byKey(const Key('nai-agent-systemPromptPrefix')),
          'PREFIX_IDENTITY',
        );
        await tester.ensureVisible(
          find.byKey(const Key('nai-agent-base-prompt')),
        );
        await tester.tap(find.byKey(const Key('nai-agent-base-prompt')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('nai-agent-custom-prompt')),
          'CUSTOM_BASE',
        );
        final leave = key.currentState!.confirmLeave();
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(save ? FilledButton : TextButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(await leave, true);
        expect(c.settings.globalInstructions, save ? 'SHARED_RULE' : '');
        expect(c.settings.systemPromptPrefix, save ? 'PREFIX_IDENTITY' : '');
        expect(c.settings.customSystemPrompt, save ? 'CUSTOM_BASE' : null);
        if (!save) {
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const Key('nai-agent-globalInstructions')),
                )
                .controller!
                .text,
            isEmpty,
          );
          expect(
            tester
                .widget<TextField>(
                  find.byKey(const Key('nai-agent-systemPromptPrefix')),
                )
                .controller!
                .text,
            isEmpty,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'instructions and real fonts fit $locale ${brightness.name} at 320/780px',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await c.updateSettings({
            'globalInstructions': 'Respect the project preferences.',
            'systemPromptPrefix': 'You are my NAI creative assistant.',
          });
          for (final width in [320.0, 780.0]) {
            await pump(
              tester,
              SingleChildScrollView(
                child: RepaintBoundary(
                  key: const Key('instructions-capture'),
                  child: Material(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: NaiAgentSettingsSection(
                        key: ValueKey('$locale-${brightness.name}-$width'),
                      ),
                    ),
                  ),
                ),
              ),
              width: width,
              locale: Locale(locale),
              brightness: brightness,
            );
            expect(
              find.byKey(const Key('nai-agent-globalInstructions')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('nai-agent-systemPromptPrefix')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('nai-agent-custom-prompt')),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
            if (Platform.environment['CAPTURE_NAI_AGENT_INSTRUCTIONS'] == '1') {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('instructions-capture')),
              );
              await tester.runAsync(() async {
                final pixels = await boundary.toImage(pixelRatio: 1);
                final data = await pixels.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = await Directory(
                  '.dart_tool/nai-agent-instructions/captures',
                ).create(recursive: true);
                await File(
                  '${folder.path}/instructions-$locale-${brightness.name}-${width.toInt()}.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                pixels.dispose();
              });
            }
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'custom prompt stays a draft until Save; restoration uses the default',
    (tester) async {
      await pump(
        tester,
        const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: NaiAgentSettingsSection(),
          ),
        ),
        width: 760,
      );
      await tester.ensureVisible(
        find.byKey(const Key('nai-agent-base-prompt')),
      );
      await tester.tap(find.byKey(const Key('nai-agent-base-prompt')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('nai-agent-custom-prompt'));
      await tester.enterText(field, '自定义 NAI Agent 规则');
      await tester.pump();
      expect(c.settings.customSystemPrompt, isNull);
      await tester.ensureVisible(
        find.byKey(const Key('nai-agent-save-base-prompt')),
      );
      await tester.tap(find.byKey(const Key('nai-agent-save-base-prompt')));
      await tester.pump();
      expect(c.settings.customSystemPrompt, '自定义 NAI Agent 规则');
      await tester.tap(find.widgetWithText(TextButton, '恢复默认'));
      await tester.pump();
      expect(c.settings.customSystemPrompt, isNull);
      expect(
        tester.widget<TextField>(field).controller!.text,
        naiAgentDefaultSystemPrompt,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'extension controls and real fonts fit $locale ${brightness.name} at 320/780px',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          const path = 'C:/extensions/palette-helper.ts';
          await c.updateSettings({
            'extensions': [
              {'path': path, 'enabled': true},
            ],
          });
          for (final width in [320.0, 780.0]) {
            await pump(
              tester,
              SingleChildScrollView(
                child: RepaintBoundary(
                  key: const Key('extension-capture'),
                  child: Material(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: NaiAgentExtensionsSettings(
                        key: ValueKey('$locale-${brightness.name}-$width'),
                      ),
                    ),
                  ),
                ),
              ),
              width: width,
              locale: Locale(locale),
              brightness: brightness,
            );
            await tester.tap(
              find.byKey(const Key('nai-agent-builtin-extension')),
            );
            await tester.pumpAndSettle();
            expect(find.text('studio_context · ask_user'), findsOneWidget);
            expect(find.text('palette-helper.ts'), findsOneWidget);
            expect(tester.takeException(), isNull);
            if (Platform.environment['CAPTURE_NAI_AGENT_EXTENSIONS'] == '1') {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('extension-capture')),
              );
              await tester.runAsync(() async {
                final capture = await boundary.toImage(pixelRatio: 1);
                final data = await capture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = await Directory(
                  '.dart_tool/nai-agent-extensions/captures',
                ).create(recursive: true);
                await File(
                  '${folder.path}/extensions-$locale-${brightness.name}-${width.toInt()}.png',
                ).writeAsBytes(data!.buffer.asUint8List());
                capture.dispose();
              });
            }
          }
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
          expect(c.settings.enabledExtensionPaths, isEmpty);
          await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
          await tester.pumpAndSettle();
          expect(c.settings.extensions, isEmpty);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
  testWidgets(
    'partial tool results show failure for live events and restored messages',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = c.selected!;
      r.messages = [
        {
          'role': 'assistant',
          'timestamp': 1,
          'content': [
            for (final id in ['live', 'restored', 'success'])
              {
                'type': 'toolCall',
                'id': id,
                'name': 'reference_library',
                'arguments': {'action': 'delete', 'id': id},
              },
          ],
        },
        {
          'role': 'toolResult',
          'toolCallId': 'restored',
          'isError': false,
          'content': <Map<String, dynamic>>[],
          'details': {
            'ok': false,
            'applied_fields': ['name'],
            'backup': {'path': 'outputs/reference-backup/entry.json'},
          },
        },
        {
          'role': 'toolResult',
          'toolCallId': 'success',
          'isError': false,
          'content': <Map<String, dynamic>>[],
          'details': {'ok': true},
        },
      ];
      r.tools['live'] = {
        'type': 'tool_execution_end',
        'isError': false,
        'result': {
          'content': <Map<String, dynamic>>[],
          'details': {
            'ok': false,
            'deleted': true,
            'residual_reference_file': true,
            'error': 'reference_file_remains',
          },
        },
      };
      await pump(tester, const NaiAgentPanel(), width: 320);
      expect(find.text('失败'), findsNWidgets(2));
      expect(find.text('完成'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      expect(find.textContaining('reference_file_remains'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
      'conversation, tools, queue and question fit a narrow ${brightness.name} panel',
      (tester) async {
        final r = c.selected!;
        r.messages = [
          {
            'role': 'user',
            'timestamp': 1,
            'content': [
              {'type': 'text', 'text': '帮我检查当前提示词，先给我建议。'},
            ],
          },
          {
            'role': 'assistant',
            'timestamp': 2,
            'content': [
              {'type': 'text', 'text': '我先读取当前设置，然后整理可调整的部分。'},
              {
                'type': 'toolCall',
                'id': 'context-1',
                'name': 'studio_context',
                'arguments': {'scope': 'draft'},
              },
            ],
          },
          {
            'role': 'toolResult',
            'toolCallId': 'context-1',
            'content': [
              {'type': 'text', 'text': '当前参数已读取。'},
            ],
          },
          {
            'role': 'assistant',
            'timestamp': 3,
            'content': [
              {'type': 'text', 'text': '画面方向清楚。可以保留现有构图，先调整背景细节。'},
            ],
          },
        ];
        r.composer = const AgentComposerState(
          text: '也看一下角色标签。',
          pending: [
            {'queueId': 'restored', 'text': '接着帮我整理成积木。', 'recovered': true},
          ],
        );
        r.stats = {
          'tokens': {'total': 2850},
        };
        final broker = container.read(naiAgentQuestionsProvider);
        final answer = broker.ask(r.workspace.id, r.chat.id, {
          'questions': [
            {
              'id': 'plan',
              'question': '这次先保留哪部分？',
              'options': ['保留构图', '保留角色'],
            },
          ],
        }, NaiAgentCancellation());
        final key = GlobalKey();
        await pump(
          tester,
          RepaintBoundary(key: key, child: const NaiAgentPanel()),
          width: 320,
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(NaiAgentQuestionCard), findsOneWidget);
        expect(find.text('接着帮我整理成积木。'), findsOneWidget);
        if (Platform.environment['CAPTURE_NAI_AGENT'] == '1') {
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final folder = Directory(
              '.dart_tool/nai-agent-stage-d/native-captures',
            )..createSync(recursive: true);
            File(
              '${folder.path}/agent-conversation-${brightness.name}-320.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        broker.cancel(broker.forChat(r.chat.id).single.id);
        await answer;
        await tester.pumpWidget(const SizedBox());
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  }
  for (final locale in ['zh', 'en', 'ja', 'ko']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets(
        'real-font $locale ${brightness.name} panel fits 320px and 440px',
        (tester) async {
          final key = GlobalKey();
          for (final width in [320.0, 440.0]) {
            await pump(
              tester,
              RepaintBoundary(key: key, child: const NaiAgentPanel()),
              width: width,
              locale: Locale(locale),
              brightness: brightness,
            );
            expect(tester.takeException(), isNull);
            expect(find.byKey(const Key('nai-agent-input')), findsOneWidget);
            expect(
              tester.getRect(find.byKey(const Key('nai-agent-composer'))).right,
              lessThanOrEqualTo(width),
            );
            if (Platform.environment['CAPTURE_NAI_AGENT'] == '1' &&
                locale == 'zh') {
              await tester.runAsync(() async {
                final image =
                    await (key.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage(pixelRatio: 1);
                final png = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory(
                  '.dart_tool/nai-agent-stage-d/native-captures',
                )..createSync(recursive: true);
                File(
                  '${folder.path}/agent-$locale-${brightness.name}-${width.toInt()}.png',
                ).writeAsBytesSync(png!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
          await tester.pumpWidget(const SizedBox());
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        },
      );
    }
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_quick_messages.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_wiring.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_input.dart';
import 'package:super_clipboard/super_clipboard.dart';

const agentTestConfig = PromptAssistantConfigState(
  providers: [
    ProviderConfig(id: 'local', name: 'Local', baseUrl: 'http://never.invalid'),
    ProviderConfig(
      id: 'disabled',
      name: 'Disabled',
      baseUrl: '',
      enabled: false,
    ),
  ],
  models: [
    ModelConfig(
      providerId: 'local',
      name: 'model',
      displayName: 'Test model',
      supportsTools: true,
      reasoningEffort: 'medium',
      reasoningEfforts: ['none', 'low', 'medium', 'high'],
    ),
    ModelConfig(
      providerId: 'local',
      name: 'no-tools',
      displayName: 'No tools',
      supportsTools: false,
    ),
    ModelConfig(
      providerId: 'disabled',
      name: 'disabled',
      displayName: 'Disabled',
    ),
  ],
  interfaces: {},
  providerHasApiKey: {},
);

class AgentTestStorage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      key == StorageKeys.promptAssistantConfigJson
      ? agentTestConfig.encode() as T
      : defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class AgentTestSecrets extends SecureStorageService {
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

class AgentTestAuth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'synthetic');
  void changeAccount() {
    state = const AuthState(
      status: AuthStatus.authenticated,
      accountId: 'changed',
    );
  }
}

class AgentTestStore extends AgentWorkspaceStore {
  AgentTestStore(super.root);
  AgentSettings value = const AgentSettings();
  final attachments = <String, Uint8List>{};
  @override
  Future<AgentSettings> readSettings() async => value;
  @override
  Future<AgentSettings> patchSettings(Map<String, dynamic> changes) async =>
      value = AgentSettings.fromJson({...value.toJson(), ...changes});
  @override
  Future<void> saveComposer(
    String workspaceId,
    String chatId,
    AgentComposerState state,
  ) async {}
  @override
  Future<Uint8List> readAttachment(
    String workspaceId,
    AgentAttachment attachment,
  ) async =>
      attachments[attachment.id] ??
      await super.readAttachment(workspaceId, attachment);
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
    final a = await super.addAttachment(
      workspaceId,
      sessionId,
      name: name,
      bytes: bytes,
      mimeType: mimeType,
      width: width,
      height: height,
      metadata: metadata,
    );
    attachments[a.id] = bytes;
    return a;
  }
}

class AgentTestController extends NaiAgentWorkspaceController {
  AgentTestController(AgentWorkspaceStore store)
    : super(
        store: store,
        initialWorkspaceName: 'Workspace',
        initialChatName: 'New chat',
        startClient: (_, __, ___, ____, _____) =>
            Future.error(StateError('No model/network in wiring tests')),
      );
  final calls = <String>[];
  final queueEdits = <(String, String?, bool, bool)>[];
  @override
  Future<void> send({bool steer = false}) async {
    calls.add(steer ? 'steer' : 'send');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  Future<void> compact() async {
    calls.add('compact');
  }

  @override
  Future<void> refreshUsage(AgentChatRuntime runtime) async {
    calls.add('usage');
  }

  @override
  Future<void> editMessage(String entryId) async {
    calls.add('edit:$entryId');
    await saveComposer('edited user');
  }

  @override
  Future<void> editQueue(
    String id, {
    String? text,
    bool remove = false,
    bool steer = false,
  }) async {
    queueEdits.add((id, text, remove, steer));
  }
}

class AgentWiringHarness {
  late Directory root;
  late AgentTestController c;
  late ProviderContainer container;
  Future<List<DataReader>> Function() clipboard = () async => [];
  Future<void> init({
    List<Override> overrides = const [],
    NaiAgentSkillInventory? skills,
    AgentTestController Function(AgentWorkspaceStore)? controller,
  }) async {
    root = await Directory.systemTemp.createTemp('agent-command-desk-');
    c = (controller ?? AgentTestController.new)(AgentTestStore(root));
    await c.initialize(restoreHistory: false);
    await c.updateSettings({'providerId': 'local', 'modelId': 'model'});
    container = ProviderContainer(
      overrides: [
        naiAgentControllerProvider.overrideWith((_) => c),
        naiAgentWorkspaceStoreProvider.overrideWithValue(c.store),
        naiAgentNativeDragEnabledProvider.overrideWithValue(false),
        naiAgentClipboardReadersProvider.overrideWithValue(() => clipboard()),
        localStorageServiceProvider.overrideWithValue(AgentTestStorage()),
        secureStorageServiceProvider.overrideWithValue(AgentTestSecrets()),
        authNotifierProvider.overrideWith(AgentTestAuth.new),
        naiAgentSkillsProvider.overrideWith(
          (_, __) async => skills ?? const NaiAgentSkillInventory([], 0, {}),
        ),
        ...overrides,
      ],
    );
  }

  Future<void>? _disposal;
  Future<void> dispose() => _disposal ??= _dispose();

  Future<void> _dispose() async {
    container.dispose();
    await c.close();
    for (var i = 0; i < 20; i++) {
      try {
        await root.delete(recursive: true);
        break;
      } on FileSystemException {
        if (i == 19) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  AgentPanel panel(WidgetTester tester) =>
      tester.widget<AgentPanel>(find.byType(AgentPanel));
  bool _cleanupRegistered = false;
  Future<void> pump(
    WidgetTester tester, {
    Widget child = const AgentWiring(),
    double width = 440,
    double height = 860,
    Locale locale = const Locale('zh'),
    Brightness brightness = Brightness.light,
    bool files = false,
    bool settle = true,
  }) async {
    if (!_cleanupRegistered) {
      _cleanupRegistered = true;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        final quick = container.exists(naiAgentQuickMessagesProvider)
            ? container.read(naiAgentQuickMessagesProvider)
            : null;
        for (var i = 0; i < 200 && quick?.loaded == false; i++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        // Let resource reads started by the last frame release their handles.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        // Store/resource continuations can belong to the fake clock even when
        // their filesystem I/O is real. Drain both while closing the draft and
        // deleting its isolated directory, or Windows can retain read handles.
        var disposed = false;
        final disposing = dispose().whenComplete(() {
          disposed = true;
        });
        for (var i = 0; i < 300 && !disposed; i++) {
          await tester.pump(const Duration(milliseconds: 10));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(disposed, true, reason: 'Agent draft cleanup did not finish');
        await disposing;
      });
    }
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    setCurrentL10nLocale(locale);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.getTheme(AppStyle.geist, brightness),
          home: Scaffold(body: child),
        ),
      ),
    );
    if (files) await finishFiles(tester);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> finishFiles(WidgetTester tester) async {
    for (var i = 0; i < 200; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (i > 15 && c.heldRuntimes.every((r) => r.importingImages == 0)) break;
    }
    expect(c.heldRuntimes.every((r) => r.importingImages == 0), true);
  }

  Future<void> paste(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }
}

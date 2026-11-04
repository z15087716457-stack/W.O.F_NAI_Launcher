import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/app_bundle_paths.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import 'nai_agent_session_provider.dart';
import 'nai_agent_workspace_controller.dart';
import 'nai_agent_questions.dart';
import 'nai_agent_management.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/services/desktop_app_shutdown_service.dart';
import 'dart:convert';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';

class NaiAgentRuntimePaths {
  const NaiAgentRuntimePaths({
    required String node,
    required this.host,
    this.bundledMacOSVersion,
  }) : _node = node;
  final String _node, host;

  /// Only the packaged macOS Node has a known minimum. Overrides can supply
  /// a different executable with different system requirements.
  final String? bundledMacOSVersion;
  String get node {
    final version = bundledMacOSVersion;
    if (version != null) {
      final match = RegExp(r'\b(\d+)(?:\.(\d+))?').firstMatch(version);
      if (match != null) {
        final major = int.parse(match[1]!);
        final minor = int.tryParse(match[2] ?? '') ?? 0;
        if (major < 13 || major == 13 && minor < 5) {
          throw NaiAgentToolError(
            'unsupported_macos',
            currentL10n.naiAgent_bundledNodeRequiresMacOS135,
          );
        }
      }
    }
    return _node;
  }

  Future<void> check() async {
    if (!await File(node).exists() || !await File(host).exists()) {
      throw const FileSystemException('NAI Agent runtime is not installed');
    }
  }
}

/// Installer preserves this adjacent directory. It is outside Flutter data/.
final naiAgentWorkspaceStoreProvider = Provider<AgentWorkspaceStore>(
  // macOS 不往应用包里写，放「应用支持」目录（见 AppBundlePaths）；内置技能随运行时在
  // 包里，不在数据目录旁边，所以显式指给它
  (ref) => AgentWorkspaceStore(
    Directory(AppBundlePaths.agentDataDirectory),
    builtinSkillsDirectory: Directory(
      p.join(AppBundlePaths.toolsDirectory, 'nai-agent', 'skills'),
    ),
  ),
);

/// Production uses the bundled runtime only; tests explicitly override paths.
final naiAgentRuntimePathsProvider = Provider<NaiAgentRuntimePaths>((ref) {
  // Windows 在 exe 旁边的 tools，macOS 在 Contents/Resources/tools（见 AppBundlePaths）
  final root = p.join(AppBundlePaths.toolsDirectory, 'nai-agent');
  return NaiAgentRuntimePaths(
    node: p.join(root, Platform.isWindows ? 'node.exe' : 'node'),
    host: p.join(root, 'host.mjs'),
    bundledMacOSVersion: Platform.isMacOS
        ? Platform.operatingSystemVersion
        : null,
  );
});

/// Generation layout only reads preferences. Opening the Agent owns workspace
/// creation and session restoration; a closed dock never starts a child.
class NaiAgentUiPreferences extends ChangeNotifier {
  AgentSettings settings = const AgentSettings();
  int _revision = 0;
  bool _disposed = false;
  Future<void> load(AgentWorkspaceStore store) async {
    final revision = _revision;
    final stored = await store.readSettings();
    if (!_disposed && revision == _revision) replace(stored);
  }

  void replace(AgentSettings value) {
    if (_disposed) return;
    _revision++;
    if (identical(settings, value)) return;
    settings = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final naiAgentUiPreferencesProvider =
    ChangeNotifierProvider<NaiAgentUiPreferences>((ref) {
      final preferences = NaiAgentUiPreferences();
      preferences
          .load(ref.read(naiAgentWorkspaceStoreProvider))
          .catchError((Object _) {});
      return preferences;
    });

final naiAgentClientFactoryProvider = Provider<AgentClientFactory>(
  (ref) => (workspace, chat, settings, prompt, resume) async {
    final paths = ref.read(naiAgentRuntimePathsProvider);
    await paths.check();
    final servers = <String, dynamic>{};
    final secure = ref.read(secureStorageServiceProvider);
    for (final server in settings.mcpServers) {
      // Disabled entries need no credential lookup and never launch a server.
      if (!server.enabled) continue;
      final text = await secure.readAgentMcpConfig(server.configId);
      if (text == null) {
        throw StateError('MCP configuration missing: ${server.name}');
      }
      servers[server.name] = {
        ...Map<String, dynamic>.from(jsonDecode(text) as Map),
        'enabled': true,
        'exposure': server.exposure,
      };
    }
    return ref.read(naiAgentSessionStarterProvider)(
      providerId: settings.providerId,
      modelId: settings.modelId,
      workspaceId: workspace.id,
      chatId: chat.id,
      workspace: workspace.directory,
      data: workspace.agentDirectory,
      sessionDirectory: workspace.sessions,
      sessionFile: resume,
      sessionName: chat.title,
      maxRequestsPerRun: settings.maxRequestsPerRun,
      reasoningEffort: settings.reasoningEffort,
      permissionMode: settings.permissionMode,
      cacheWarming: settings.cacheWarming,
      nextSuggestion: settings.nextSuggestion,
      nodeExecutable: paths.node,
      hostScript: paths.host,
      systemPrompt: prompt,
      extraToolNames: const ['ask_user'],
      extensionPaths: settings.enabledExtensionPaths,
      packages: ref
          .read(naiAgentWorkspaceStoreProvider)
          .packageConfig(workspace, settings),
      prompts: {
        'globalDirectory': ref
            .read(naiAgentWorkspaceStoreProvider)
            .globalPromptsDirectory
            .absolute
            .path,
        'workspaceDirectory': workspace.prompts.absolute.path,
      },
      skills: ref
          .read(naiAgentWorkspaceStoreProvider)
          .skillConfig(workspace, settings),
      mcp: {
        'mcpServers': servers,
        'builtinEnabled': settings.studioMcpEnabled,
        'builtinExposure': settings.studioMcpExposure,
      },
      executeExtraTool: (name, params, cancellation) {
        if (name == 'agent_manage') {
          return ref
              .read(naiAgentManagementProvider)
              .execute(workspace.id, params, cancellation);
        }
        final questions = ref.read(naiAgentQuestionsProvider);
        return name == '_nai_extension_ui'
            ? questions.askExtensionUi(
                workspace.id,
                chat.id,
                params,
                cancellation,
              )
            : questions.ask(workspace.id, chat.id, params, cancellation);
      },
    );
  },
);

final naiAgentControllerProvider =
    ChangeNotifierProvider<NaiAgentWorkspaceController>((ref) {
      var modelRevision = 0;
      ref.listen(promptAssistantConfigProvider, (_, __) => modelRevision++);
      final controller = NaiAgentWorkspaceController(
        store: ref.read(naiAgentWorkspaceStoreProvider),
        startClient: ref.read(naiAgentClientFactoryProvider),
        initialWorkspaceName: currentL10n.naiAgent_defaultWorkspace,
        initialChatName: currentL10n.naiAgent_newChat,
        readModelRevision: () => modelRevision,
      );
      ref.onDispose(
        DesktopAppShutdownService.registerCleanup(
          controller.close,
          name: 'Agent sessions',
        ),
      );
      controller.addListener(() {
        ref.read(naiAgentUiPreferencesProvider).replace(controller.settings);
      });
      controller.ready = controller
          .initialize(restoreHistory: false)
          .catchError(controller.initializationFailed);
      return controller;
    });

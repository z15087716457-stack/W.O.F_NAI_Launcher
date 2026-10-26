import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/nai_agent/pi_host_client.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/utils/localization_extension.dart';
import 'nai_agent_model_provider.dart';
import 'nai_agent_studio_provider.dart';

typedef NaiAgentSessionStarter =
    Future<PiHostClient> Function({
      required String providerId,
      required String modelId,
      required String workspaceId,
      String? chatId,
      required Directory workspace,
      required Directory data,
      required String nodeExecutable,
      required String hostScript,
      required String systemPrompt,
      Directory? sessionDirectory,
      File? sessionFile,
      String? sessionName,
      int? maxRequestsPerRun,
      String? reasoningEffort,
      String? permissionMode,
      String? cacheWarming,
      bool? nextSuggestion,
      NaiAgentToolExecutor? executeExtraTool,
      List<String>? extraToolNames,
      List<String>? extensionPaths,
      Map<String, dynamic>? mcp,
      Map<String, dynamic>? skills,
      Map<String, dynamic>? prompts,
    });

/// No process starts until the workspace/UI explicitly requests a session.
final naiAgentSessionStarterProvider = Provider<NaiAgentSessionStarter>((ref) {
  var alive = true;
  final owned = <PiHostClient>{};
  ref.onDispose(() {
    alive = false;
    for (final client in owned) {
      unawaited(client.close());
    }
  });
  return ({
    required providerId,
    required modelId,
    required workspaceId,
    chatId,
    required workspace,
    required data,
    required nodeExecutable,
    required hostScript,
    required systemPrompt,
    sessionDirectory,
    sessionFile,
    sessionName,
    maxRequestsPerRun,
    reasoningEffort,
    permissionMode = 'auto',
    cacheWarming = 'streaming',
    nextSuggestion = true,
    executeExtraTool,
    extraToolNames = const [],
    extensionPaths = const [],
    mcp = const {},
    skills = const {},
    prompts = const {},
  }) async {
    var model = await ref.read(naiAgentModelResolverProvider)(
      providerId,
      modelId,
    );
    if (reasoningEffort != null &&
        model.supportsReasoningEffort(reasoningEffort)) {
      model = model.withReasoningEffort(reasoningEffort);
    }
    final extraNames = extraToolNames ?? const <String>[];
    if (!alive) throw StateError('NAI Agent owner closed');
    final studio = ref.read(naiAgentStudioFactoryProvider)(
      workspace,
      data,
      model.allowsImages,
      visionAccess: model.visionAccess,
      owner: NaiAgentConversationOwner(workspaceId, chatId ?? workspaceId),
    );
    final client = await PiHostClient.start(
      nodeExecutable: nodeExecutable,
      hostScript: hostScript,
      workspaceId: workspaceId,
      workspaceDirectory: workspace,
      agentDirectory: data,
      systemPrompt: systemPrompt,
      visionAccess: model.visionAccess,
      privateModelConfig: {
        ...model.toPrivateJson(),
        'permissionMode': permissionMode ?? 'auto',
        'cacheWarming': cacheWarming ?? 'streaming',
        'nextSuggestion': nextSuggestion ?? true,
        'permissionLabels': {
          'title': currentL10n.naiAgent_permissionTitle,
          'once': currentL10n.naiAgent_permissionOnce,
          'session': currentL10n.naiAgent_permissionSession,
          'deny': currentL10n.naiAgent_permissionDeny,
        },
        if (maxRequestsPerRun != null) 'maxRequestsPerRun': maxRequestsPerRun,
      },
      executeTool: (name, params, cancellation) =>
          (extraNames.contains(name) || name == '_nai_extension_ui') &&
              executeExtraTool != null
          ? executeExtraTool(name, params, cancellation)
          : studio.execute(name, params, cancellation),
      extraToolNames: {...extraNames, ...studio.domainToolNames}.toList(),
      sessionDirectory: sessionDirectory,
      sessionFile: sessionFile,
      sessionName: sessionName,
      extensionPaths: extensionPaths ?? const [],
      mcp: mcp ?? const {},
      skills: skills ?? const {},
      prompts: prompts ?? const {},
    );
    if (!alive) {
      await client.close();
      throw StateError('NAI Agent owner closed');
    }
    owned.add(client);
    unawaited(client.whenClosed.then((_) => owned.remove(client)));
    return client;
  };
});

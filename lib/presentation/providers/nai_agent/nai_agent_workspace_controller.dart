import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/pi_host_client.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';

typedef AgentClientFactory =
    Future<PiHostClient> Function(
      AgentWorkspace workspace,
      AgentChat chat,
      AgentSettings settings,
      String systemPrompt,
      File? resume,
    );

/// Live projections and UI drafts only. Official Pi owns messages and execution.
class AgentChatRuntime {
  AgentChatRuntime(this.workspace, this.chat, this.composer);
  final AgentWorkspace workspace;
  AgentChat chat;
  AgentComposerState composer;
  PiHostClient? client;
  StreamSubscription<Map<String, dynamic>>? subscription;
  List<Map<String, dynamic>> messages = [], queue = [];
  Map<String, dynamic> stats = {}, context = {};
  List<Map<String, dynamic>> entries = [], userEntries = [];
  final Map<String, Map<String, dynamic>> tools = {};
  final Map<String, String> extensionStatus = {};
  final Map<String, List<String>> extensionWidgets = {};
  final List<String> extensionNotices = [];
  bool running = false, starting = false, waitingForSlot = false;
  String? error, providerId, modelId, reasoningEffort;
  int usageRevision = 0;
  int modelRevision = -1;
  int uiRevision = 0;
  int? maxRequestsPerRun;
  String? extensionSignature;
  String mcpStatus = '';
}

class NaiAgentWorkspaceController extends ChangeNotifier {
  NaiAgentWorkspaceController({
    required this.store,
    required this.startClient,
    required this.initialWorkspaceName,
    required this.initialChatName,
    int Function()? readModelRevision,
  }) : readModelRevision = readModelRevision ?? (() => 0);
  final AgentWorkspaceStore store;
  final AgentClientFactory startClient;
  final String initialWorkspaceName, initialChatName;
  final int Function() readModelRevision;
  Future<void> ready = Future.value();
  String? initializationError;
  AgentSettings settings = const AgentSettings();
  List<AgentWorkspace> workspaces = [];
  List<AgentChat> chats = [];
  final Map<String, AgentChatRuntime> _runtimes = {};
  AgentWorkspace? selectedWorkspace;
  AgentChatRuntime? selected;
  bool initialized = false, _disposed = false;
  Future<void>? _closeFuture;
  int _selectionRevision = 0;
  Iterable<AgentChatRuntime> get runningChats =>
      _runtimes.values.where((chat) => chat.running);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void initializationFailed(Object error) {
    initializationError = _error(error);
    _notify();
  }

  Future<void> loadHistory() async {
    final runtime = selected;
    if (runtime != null &&
        runtime.chat.sessionFile != null &&
        runtime.client == null) {
      try {
        await _ensureClient(runtime);
      } catch (error) {
        runtime.error = _error(error);
        _notify();
      }
    }
  }

  Future<void> initialize({bool restoreHistory = true}) async {
    settings = await store.readSettings();
    workspaces = await store.listWorkspaces();
    if (workspaces.isEmpty) {
      workspaces = [await store.createWorkspace(initialWorkspaceName)];
    }
    final workspace =
        workspaces
            .where((w) => w.id == settings.selectedWorkspaceId)
            .firstOrNull ??
        workspaces.first;
    await selectWorkspace(workspace.id, restoreHistory: restoreHistory);
    initialized = true;
    _notify();
  }

  Future<void> selectWorkspace(String id, {bool restoreHistory = true}) async {
    final revision = ++_selectionRevision;
    final workspace = await store.getWorkspace(id);
    var listed = await store.listChats(id);
    if (listed.isEmpty) listed = [await store.createChat(id, initialChatName)];
    if (_disposed || revision != _selectionRevision) return;
    selectedWorkspace = workspace;
    chats = listed;
    final chat =
        listed.where((c) => c.id == workspace.lastSessionId).firstOrNull ??
        listed.first;
    await _selectChat(chat, revision, restoreHistory: restoreHistory);
    if (_disposed || revision != _selectionRevision) return;
    settings = await store.patchSettings({'selectedWorkspaceId': id});
    _notify();
  }

  Future<void> selectChat(String id) async {
    final chat = chats.firstWhere((c) => c.id == id);
    await _selectChat(chat, ++_selectionRevision);
  }

  Future<void> _selectChat(
    AgentChat chat,
    int revision, {
    bool restoreHistory = true,
  }) async {
    for (final runtime in _runtimes.values.where(
      (r) => r.chat.id != chat.id && !r.running && !r.starting,
    )) {
      await runtime.subscription?.cancel();
      await runtime.client?.close();
      runtime.client = null;
      runtime.messages = [];
      runtime.tools.clear();
    }
    final workspace = await store.getWorkspace(chat.workspaceId);
    var runtime = _runtimes[chat.id];
    if (runtime == null) {
      runtime = AgentChatRuntime(
        workspace,
        chat,
        await store.readComposer(workspace.id, chat.id),
      );
      if (runtime.composer.pending.isNotEmpty) {
        runtime.composer = AgentComposerState(
          text: runtime.composer.text,
          attachments: runtime.composer.attachments,
          interrupted: runtime.composer.interrupted,
          pending: [
            for (final item in runtime.composer.pending)
              {...item, 'recovered': true},
          ],
        );
      }
      _runtimes[chat.id] = runtime;
    }
    if (_disposed || revision != _selectionRevision) return;
    selected = runtime;
    await store.updateWorkspace(workspace.id, lastSessionId: chat.id);
    _notify();
    // Restoring history is entirely local; no prompt or model call is made.
    if (restoreHistory && chat.sessionFile != null && runtime.client == null) {
      try {
        await _ensureClient(runtime);
      } catch (error) {
        runtime.error = _error(error);
        _notify();
      }
    }
  }

  Future<void> createWorkspace(String name) async {
    final workspace = await store.createWorkspace(name);
    workspaces = await store.listWorkspaces();
    await selectWorkspace(workspace.id);
  }

  Future<void> renameWorkspace(String id, String name) async {
    await store.updateWorkspace(id, name: name);
    workspaces = await store.listWorkspaces();
    if (selectedWorkspace?.id == id) {
      selectedWorkspace = await store.getWorkspace(id);
    }
    _notify();
  }

  Future<void> createChat() async {
    final workspace = selectedWorkspace!;
    final chat = await store.createChat(workspace.id, initialChatName);
    chats = await store.listChats(workspace.id);
    await selectChat(chat.id);
  }

  Future<void> renameChat(String id, String title) async {
    final workspace = selectedWorkspace!;
    final chat = await store.updateChat(workspace.id, id, title: title);
    _runtimes[id]?.chat = chat;
    chats = await store.listChats(workspace.id);
    await _runtimes[id]?.client?.rename(title);
    _notify();
  }

  Future<void> updateSettings(Map<String, dynamic> changes) async {
    settings = await store.patchSettings(changes);
    _notify();
    if (changes.containsKey('permissionMode')) {
      await Future.wait([
        for (final runtime in _runtimes.values)
          if (runtime.client != null && !runtime.client!.isClosed)
            () async {
              final client = runtime.client!;
              try {
                await client.setPermissionMode(settings.permissionMode);
                if (settings.permissionMode == 'readonly' && runtime.running) {
                  await _stopRuntime(runtime);
                }
              } catch (_) {
                await client.close();
                rethrow;
              }
            }(),
      ]);
    }
    if (changes.keys.any(
      {
        'customSystemPrompt',
        'globalInstructions',
        'systemPromptPrefix',
      }.contains,
    )) {
      for (final runtime in _runtimes.values) {
        if (runtime.client != null && !runtime.client!.isClosed) {
          await runtime.client!.setSystemPrompt(
            await store.effectiveSystemPrompt(runtime.workspace.id),
          );
        }
      }
    }
    _notify();
  }

  Future<void> setReasoningEffort(
    String? effort, {
    required String providerId,
    required String modelId,
  }) async {
    if (settings.providerId != providerId || settings.modelId != modelId) {
      throw StateError('Model selection changed');
    }
    await updateSettings({
      'reasoningEfforts': {settings.modelSelectionKey: effort},
    });
  }

  Future<void> refreshUsage(AgentChatRuntime runtime) async {
    final client = runtime.client;
    if (client == null || client.isClosed) return;
    final revision = runtime.usageRevision;
    final value = await client.state();
    if (_disposed ||
        runtime.client != client ||
        runtime.usageRevision != revision) {
      return;
    }
    _applyUsage(runtime, value);
    _notify();
  }

  Future<void> setWorkspacePrompt(String? text) async {
    final id = selectedWorkspace!.id;
    await store.updateWorkspace(
      id,
      customSystemPrompt: text,
      resetPrompt: text == null,
    );
    selectedWorkspace = await store.getWorkspace(id);
    for (final runtime in _runtimes.values.where((r) => r.workspace.id == id)) {
      if (runtime.client != null && !runtime.client!.isClosed) {
        await runtime.client!.setSystemPrompt(
          await store.effectiveSystemPrompt(id),
        );
      }
    }
    _notify();
  }

  Future<void> configureExtension(
    String path, {
    bool? enabled,
    bool remove = false,
  }) async {
    settings = await store.configureExtension(
      path,
      enabled: enabled,
      remove: remove,
    );
    _notify();
  }

  Future<void> mcpCommand(String action, {String? name}) async {
    final runtime = selected;
    if (runtime == null || runtime.running || runtime.starting) {
      throw StateError('Wait for the current Agent run or stop it first');
    }
    final client = await _ensureClient(runtime);
    _applyState(runtime, await client.mcpCommand(action, name: name));
    _notify();
  }

  Future<void> saveComposer(String text) async {
    final runtime = selected;
    if (runtime == null) return;
    runtime.composer = AgentComposerState(
      text: text,
      attachments: runtime.composer.attachments,
      pending: runtime.composer.pending,
      interrupted: runtime.composer.interrupted,
    );
    _notify();
    await _persist(runtime);
  }

  Future<void> attach(
    String name,
    Uint8List bytes,
    String mimeType, {
    AgentChatRuntime? target,
  }) async {
    final runtime = target ?? selected!;
    final attachment = await store.addAttachment(
      runtime.workspace.id,
      runtime.chat.id,
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: [...runtime.composer.attachments, attachment],
      pending: runtime.composer.pending,
      interrupted: runtime.composer.interrupted,
    );
    await _persist(runtime);
    _notify();
  }

  Future<void> removeAttachment(String id) async {
    final runtime = selected!;
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: runtime.composer.attachments
          .where((a) => a.id != id)
          .toList(),
      pending: runtime.composer.pending,
      interrupted: runtime.composer.interrupted,
    );
    await _persist(runtime);
    _notify();
  }

  Future<PiHostClient> _ensureClient(AgentChatRuntime runtime) async {
    var client = runtime.client;
    final changed =
        runtime.providerId != settings.providerId ||
        runtime.modelId != settings.modelId ||
        runtime.reasoningEffort != settings.reasoningEffort ||
        runtime.modelRevision != readModelRevision() ||
        runtime.maxRequestsPerRun != settings.maxRequestsPerRun ||
        runtime.extensionSignature != settings.extensionSignature;
    if (client != null && !client.isClosed && (!changed || runtime.running)) {
      return client;
    }
    if (runtime.starting) {
      throw const NaiAgentToolError('starting', 'Agent session is starting');
    }
    runtime.starting = true;
    _notify();
    try {
      await runtime.subscription?.cancel();
      await client?.close();
      final chat = runtime.chat;
      final file = chat.sessionFile == null
          ? null
          : File(p.join(runtime.workspace.directory.path, chat.sessionFile!));
      final selection = settings;
      final revision = readModelRevision();
      client = await startClient(
        runtime.workspace,
        chat,
        selection,
        await store.effectiveSystemPrompt(runtime.workspace.id),
        file != null && await file.exists() ? file : null,
      );
      if (_disposed ||
          settings.providerId != selection.providerId ||
          settings.modelId != selection.modelId ||
          settings.reasoningEffort != selection.reasoningEffort ||
          settings.permissionMode != selection.permissionMode) {
        await client.close();
        throw StateError(
          _disposed
              ? 'Agent owner closed'
              : 'Agent selection changed during startup',
        );
      }
      runtime.client = client;
      runtime.extensionStatus.clear();
      runtime.extensionWidgets.clear();
      runtime.extensionNotices.clear();
      runtime.providerId = selection.providerId;
      runtime.modelId = selection.modelId;
      runtime.reasoningEffort = selection.reasoningEffort;
      runtime.modelRevision = revision;
      runtime.maxRequestsPerRun = selection.maxRequestsPerRun;
      runtime.extensionSignature = selection.extensionSignature;
      _applyState(runtime, client.initialState);
      final path = client.initialState['sessionFile'] as String?;
      if (path != null) {
        final sessionFile = File(path);
        // Pi may expand Windows short paths when reopening an existing session.
        final canonical = await sessionFile.exists()
            ? await sessionFile.resolveSymbolicLinks()
            : p.join(
                await sessionFile.parent.resolveSymbolicLinks(),
                p.basename(path),
              );
        final root = await runtime.workspace.directory.resolveSymbolicLinks();
        runtime.chat = await store.updateChat(
          runtime.workspace.id,
          chat.id,
          sessionFile: p.relative(canonical, from: root),
        );
      }
      runtime.subscription = client.events.listen(
        (event) => _event(runtime, event),
      );
      return client;
    } finally {
      runtime.starting = false;
      _notify();
    }
  }

  Future<void> send({bool steer = false}) async {
    final runtime = selected!;
    final original = runtime.composer;
    if (runtime.starting ||
        (original.text.trim().isEmpty && original.attachments.isEmpty)) {
      return;
    }
    final wasRunning = runtime.running;
    runtime.error = null;
    try {
      final client = await _ensureClient(runtime);
      final images = <Map<String, dynamic>>[];
      if (original.attachments.isNotEmpty &&
          (client.initialState['model'] as Map?)?['vision'] != true) {
        throw const NaiAgentToolError(
          'vision_disabled',
          'Select a model with image input enabled',
        );
      }
      for (final attachment in original.attachments) {
        final bytes = await store.readAttachment(
          runtime.workspace.id,
          attachment,
        );
        final dimensions = NaiResolutionAdapter.readImageSize(bytes);
        if (dimensions == null || dimensions.$1 * dimensions.$2 > 64000000) {
          throw const NaiAgentToolError(
            'image_size',
            'Invalid image or more than 64 million pixels',
          );
        }
        final image = await optimizePromptAssistantImagePartForUpload(
          PromptAssistantImagePart(bytes: bytes, mimeType: attachment.mimeType),
        );
        if (image.bytes.length > promptAssistantImageUploadMaxBytes) {
          throw const NaiAgentToolError(
            'image_size',
            'Image exceeds model upload limit',
          );
        }
        images.add({
          'type': 'image',
          'mimeType': image.mimeType,
          'data': base64Encode(image.bytes),
        });
      }
      if (original.text != runtime.composer.text ||
          jsonEncode(original.attachments.map((a) => a.toJson()).toList()) !=
              jsonEncode(
                runtime.composer.attachments.map((a) => a.toJson()).toList(),
              )) {
        throw const NaiAgentToolError(
          'composer_changed',
          'Input changed while preparing; send the current draft again',
        );
      }
      final queueId = const Uuid().v4();
      runtime.composer = AgentComposerState(
        pending: [
          ...original.pending,
          {
            'queueId': queueId,
            'text': original.text,
            'behavior': steer ? 'steer' : 'followUp',
            'attachments': original.attachments.map((a) => a.toJson()).toList(),
          },
        ],
      );
      runtime.running = true;
      await _persist(runtime);
      _notify();
      final reply = await client.prompt(
        original.text.isEmpty ? '查看附图。' : original.text,
        images: images.isEmpty ? null : images,
        steer: steer,
        queueId: queueId,
      );
      _applyState(runtime, reply);
      if (!wasRunning) {
        if (runtime.chat.title == initialChatName &&
            original.text.trim().isNotEmpty) {
          final title = original.text.trim().replaceAll(RegExp(r'\s+'), ' ');
          runtime.chat = await store.updateChat(
            runtime.workspace.id,
            runtime.chat.id,
            title: title.characters.take(32).toString(),
          );
          await client.rename(runtime.chat.title);
          if (selectedWorkspace?.id == runtime.workspace.id) {
            chats = await store.listChats(runtime.workspace.id);
          }
        }
        runtime.running = false;
      }
      await _persist(runtime);
    } catch (error) {
      runtime.error = _error(error);
      if (!wasRunning) runtime.running = false;
      await _persist(runtime);
    } finally {
      _notify();
    }
  }

  Future<void> stop() => _stopRuntime(selected!);

  Future<void> _stopRuntime(AgentChatRuntime runtime) async {
    final recovered = [
      for (final item in runtime.composer.pending) {...item, 'recovered': true},
    ];
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: runtime.composer.attachments,
      pending: recovered,
    );
    await runtime.client?.abort();
    runtime.running = false;
    runtime.waitingForSlot = false;
    runtime.queue = [];
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: runtime.composer.attachments,
      pending: runtime.composer.pending,
    );
    await _persist(runtime);
    _notify();
  }

  Future<void> editQueue(
    String id, {
    String? text,
    bool remove = false,
    bool steer = false,
  }) async {
    final runtime = selected!;
    final reply = await runtime.client!.editQueue(
      id,
      text: text,
      remove: remove,
      steer: steer,
    );
    final pending = [
      for (final item in runtime.composer.pending)
        if (item['queueId'] != id || !remove)
          item['queueId'] == id
              ? {
                  ...item,
                  if (text != null) 'text': text,
                  if (steer) 'behavior': 'steer',
                }
              : item,
    ];
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: runtime.composer.attachments,
      pending: pending,
    );
    runtime.queue = _maps(reply['queue']);
    await _persist(runtime);
    _notify();
  }

  Future<void> editMessage(String entryId) async {
    final runtime = selected!;
    if (runtime.running) {
      throw const NaiAgentToolError(
        'busy',
        'Stop the run before editing a message',
      );
    }
    if (runtime.composer.text.isNotEmpty ||
        runtime.composer.attachments.isNotEmpty) {
      throw const NaiAgentToolError(
        'composer_not_empty',
        'Save or send the current draft before editing a message',
      );
    }
    final client = await _ensureClient(runtime);
    final reply = await client.navigate(entryId);
    _applyState(runtime, reply);
    final attachments = <AgentAttachment>[];
    for (final image in _maps(reply['editorImages'])) {
      attachments.add(
        await store.addAttachment(
          runtime.workspace.id,
          runtime.chat.id,
          name:
              'message-${attachments.length + 1}.${image['mimeType'] == 'image/jpeg' ? 'jpg' : 'png'}',
          bytes: base64Decode(image['data'] as String),
          mimeType: image['mimeType'] as String,
        ),
      );
    }
    runtime.composer = AgentComposerState(
      text: reply['editorText'] as String? ?? '',
      attachments: attachments,
    );
    await _persist(runtime);
    _notify();
  }

  Future<void> restorePending(String id) async {
    final runtime = selected!;
    final item = runtime.composer.pending.firstWhere((p) => p['queueId'] == id);
    if (runtime.composer.text.isNotEmpty ||
        runtime.composer.attachments.isNotEmpty) {
      throw const NaiAgentToolError(
        'composer_not_empty',
        'Save or send the current draft before restoring another message',
      );
    }
    if (runtime.queue.any((p) => p['queueId'] == id)) {
      await runtime.client!.editQueue(id, remove: true);
      runtime.queue.removeWhere((p) => p['queueId'] == id);
    }
    runtime.composer = AgentComposerState(
      text: item['text'] as String? ?? '',
      attachments: [
        for (final attachment in item['attachments'] as List? ?? [])
          AgentAttachment.fromJson(
            Map<String, dynamic>.from(attachment as Map),
          ),
      ],
      pending: runtime.composer.pending
          .where((p) => p['queueId'] != id)
          .toList(),
    );
    await _persist(runtime);
    _notify();
  }

  Future<void> compact() async {
    final runtime = selected!;
    if (runtime.running) return;
    final client = await _ensureClient(runtime);
    runtime.running = true;
    _notify();
    try {
      _applyState(runtime, await client.compact());
    } catch (error) {
      runtime.error = _error(error);
    } finally {
      runtime.running = false;
      await _persist(runtime);
      _notify();
    }
  }

  Future<Uint8List> exportSession(AgentChatRuntime runtime) async {
    if (runtime.running) {
      throw const NaiAgentToolError(
        'busy',
        'Wait for the current run before exporting',
      );
    }
    final relative = runtime.chat.sessionFile;
    if (relative == null) throw const FormatException('No saved session');
    final file = File(p.join(runtime.workspace.directory.path, relative));
    final canonical = await file.resolveSymbolicLinks();
    final root = await runtime.workspace.sessions.resolveSymbolicLinks();
    if (!p.isWithin(root, canonical)) {
      throw const FormatException('Session leaves workspace');
    }
    final bytes = await File(canonical).readAsBytes();
    final header = jsonDecode(utf8.decode(bytes).split('\n').first) as Map;
    if (header['type'] != 'session' ||
        header['cwd'] is! String ||
        await Directory(header['cwd'] as String).resolveSymbolicLinks() !=
            await runtime.workspace.directory.resolveSymbolicLinks()) {
      throw const FormatException('Session belongs to another workspace');
    }
    return bytes;
  }

  void _event(AgentChatRuntime runtime, Map<String, dynamic> envelope) {
    if (_disposed) return;
    runtime.uiRevision++;
    if (envelope['type'] == 'usage') _applyUsage(runtime, envelope);
    if (envelope['type'] == 'extension_error') {
      runtime.error =
          '${currentL10n.naiAgent_extensionError}\n${envelope['message'] ?? ''}';
    }
    if (envelope['type'] == 'extension_ui') {
      final key = envelope['key'] as String? ?? '';
      switch (envelope['method']) {
        case 'notify':
          runtime.extensionNotices.add('${envelope['message'] ?? ''}');
          if (runtime.extensionNotices.length > 4) {
            runtime.extensionNotices.removeAt(0);
          }
        case 'setStatus':
          if (envelope['text'] is String) {
            runtime.extensionStatus[key] = envelope['text'] as String;
          } else {
            runtime.extensionStatus.remove(key);
          }
        case 'setWidget':
          if (envelope['lines'] is List) {
            runtime.extensionWidgets[key] = List<String>.from(
              envelope['lines'] as List,
            );
          } else {
            runtime.extensionWidgets.remove(key);
          }
      }
    }
    if (envelope['type'] == 'request_permit') runtime.waitingForSlot = true;
    if (envelope['type'] == 'request_release') runtime.waitingForSlot = false;
    if (envelope['type'] == 'request_started') runtime.waitingForSlot = false;
    if (envelope['type'] == 'closed') {
      runtime.running = false;
      runtime.error = currentL10n.naiAgent_interrupted;
      runtime.composer = AgentComposerState(
        text: runtime.composer.text,
        attachments: runtime.composer.attachments,
        pending: runtime.composer.pending,
        interrupted: true,
      );
      unawaited(_persist(runtime));
    }
    final event = envelope['event'] as Map?;
    if (event != null) {
      final type = event['type'];
      if (type == 'message_start') {
        final message = Map<String, dynamic>.from(event['message'] as Map);
        runtime.messages = [...runtime.messages, message];
        if (message['role'] == 'user') {
          final content = message['content'];
          final text = content is String
              ? content
              : [
                  for (final part in content as List? ?? [])
                    if (part is Map && part['type'] == 'text')
                      part['text'] ?? '',
                ].join('\n');
          final pending = [...runtime.composer.pending];
          final consumed = pending.indexWhere(
            (item) =>
                item['recovered'] != true &&
                (item['text'] == text ||
                    (item['text'] == '' && text == '查看附图。')),
          );
          if (consumed >= 0) {
            final id = pending.removeAt(consumed)['queueId'];
            runtime.queue.removeWhere((item) => item['queueId'] == id);
            runtime.composer = AgentComposerState(
              text: runtime.composer.text,
              attachments: runtime.composer.attachments,
              pending: pending,
              interrupted: runtime.composer.interrupted,
            );
            unawaited(_persist(runtime));
          }
        }
      }
      if (type == 'message_update' || type == 'message_end') {
        final message = Map<String, dynamic>.from(event['message'] as Map);
        if (message['role'] == 'assistant' &&
            message['stopReason'] == 'error') {
          runtime.error =
              '${currentL10n.naiAgent_error}\n${message['errorMessage'] ?? ''}';
        }
        final index = runtime.messages.lastIndexWhere(
          (m) =>
              m['role'] == message['role'] &&
              m['timestamp'] == message['timestamp'],
        );
        if (index >= 0) runtime.messages[index] = message;
      }
      if (type == 'tool_execution_start' ||
          type == 'tool_execution_update' ||
          type == 'tool_execution_end') {
        final id = event['toolCallId'] as String;
        runtime.tools[id] = {
          ...?runtime.tools[id],
          ...Map<String, dynamic>.from(event),
        };
      }
    }
    _notify();
  }

  void dismissExtensionNotices(AgentChatRuntime runtime) {
    runtime.extensionNotices.clear();
    _notify();
  }

  static List<Map<String, dynamic>> _maps(dynamic value) => [
    for (final item in value as List? ?? [])
      Map<String, dynamic>.from(item as Map),
  ];
  void _applyUsage(AgentChatRuntime runtime, Map<String, dynamic> value) {
    runtime.usageRevision++;
    runtime.stats = Map<String, dynamic>.from(value['stats'] as Map? ?? {});
    runtime.context = Map<String, dynamic>.from(value['context'] as Map? ?? {});
  }

  void _applyState(AgentChatRuntime runtime, Map<String, dynamic> value) {
    runtime.mcpStatus = value['mcpStatus'] as String? ?? runtime.mcpStatus;
    runtime.uiRevision++;
    runtime.messages = _maps(value['messages']);
    final lastAssistant = runtime.messages
        .where((m) => m['role'] == 'assistant')
        .lastOrNull;
    if (lastAssistant?['stopReason'] == 'error') {
      runtime.error =
          '${currentL10n.naiAgent_error}\n${lastAssistant?['errorMessage'] ?? ''}';
    }
    runtime.queue = _maps(value['queue']);
    _applyUsage(runtime, value);
    runtime.entries = _maps(value['entries']);
    runtime.userEntries = _maps(value['userMessages']);
    final pendingIds = runtime.queue.map((item) => item['queueId']).toSet();
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: runtime.composer.attachments,
      pending: runtime.composer.pending
          .where(
            (item) =>
                item['recovered'] == true ||
                pendingIds.contains(item['queueId']),
          )
          .toList(),
      interrupted: runtime.composer.interrupted,
    );
  }

  Future<void> _persist(AgentChatRuntime runtime) => store.saveComposer(
    runtime.workspace.id,
    runtime.chat.id,
    AgentComposerState(
      text: runtime.composer.text,
      attachments: runtime.composer.attachments,
      pending: runtime.composer.pending,
      interrupted: runtime.composer.interrupted,
      wasRunning: runtime.running,
    ),
  );
  static String _error(Object error) {
    final l = currentL10n;
    if (error is NaiAgentToolError) {
      return switch (error.code) {
        'vision_disabled' => l.naiAgent_visionDisabled,
        'image_size' => l.naiAgent_imageLimit,
        'composer_changed' => l.naiAgent_inputChanged,
        'composer_not_empty' => l.naiAgent_composerNotEmpty,
        _ => error.message,
      };
    }
    if (error is FileSystemException && error.message.contains('runtime')) {
      return l.naiAgent_runtimeMissing;
    }
    return l.naiAgent_error;
  }

  Future<void> close() => _closeFuture ??= _close();
  Future<void> _close() async {
    for (final runtime in _runtimes.values) {
      await _persist(runtime);
      await runtime.subscription?.cancel();
      await runtime.client?.close();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(close());
    super.dispose();
  }
}

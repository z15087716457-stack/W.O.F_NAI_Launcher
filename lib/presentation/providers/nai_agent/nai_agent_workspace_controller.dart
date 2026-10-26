import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/attachment_manifest.dart';
import '../../../core/nai_agent/pi_host_client.dart';
import '../../../core/nai_agent/attachment_image.dart';
import '../../../core/nai_agent/vision_access.dart';
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
  AgentChatRuntime(this.workspace, this.chat, AgentComposerState composer)
    : _composer = composer;
  final AgentWorkspace workspace;
  AgentChat chat;
  AgentComposerState _composer;
  int _composerRevision = 0;
  AgentComposerState get composer => _composer;
  set composer(AgentComposerState value) {
    if (value.text != _composer.text ||
        !listEquals(value.attachments, _composer.attachments)) {
      _composerRevision++;
    }
    _composer = value;
  }

  PiHostClient? client;
  StreamSubscription<Map<String, dynamic>>? subscription;
  List<Map<String, dynamic>> messages = [], queue = [];
  List<Map<String, dynamic>> historyMessages = [];
  Map<String, dynamic> stats = {}, context = {};
  List<Map<String, dynamic>> entries = [], userEntries = [];
  final Map<String, Map<String, dynamic>> tools = {};
  final Map<String, String> extensionStatus = {};
  final Map<String, List<String>> extensionWidgets = {};
  final List<String> extensionNotices = [];
  final autoCompactions = <String>{};
  String? compactionReason;
  static String compactionKey(Map message) =>
      jsonEncode([message['summary'], message['tokensBefore']]);
  String? visionNotice;
  int _visionNoticeRevision = 0;
  void _clearVisionNotice() {
    visionNotice = null;
    _visionNoticeRevision++;
  }

  bool running = false, starting = false, waitingForSlot = false;
  String? error, providerId, modelId, reasoningEffort;
  int usageRevision = 0;
  int importingImages = 0;
  int pendingImageCount = 0;
  int pendingSends = 0;
  bool _resending = false;
  int modelRevision = -1;
  int uiRevision = 0;
  int? maxRequestsPerRun;
  int? runLimitHit;
  String? extensionSignature;
  String mcpStatus = '';

  static Map _entryMessage(Map entry) =>
      entry['message'] is Map ? entry['message'] as Map : entry;

  /// Host entries are flat and current-branch only. Older snapshots were nested.
  /// userEntries is an all-branches fork menu, not a source of branch membership.
  String? userEntryId(Map<String, dynamic> message) {
    if (message['role'] != 'user' || message['timestamp'] == null) return null;
    for (final entry in [...entries, ...userEntries]) {
      final value = _entryMessage(entry);
      final id = entry['id'] ?? entry['entryId'];
      if (id is String &&
          value['role'] == 'user' &&
          value['timestamp'] == message['timestamp']) {
        return id;
      }
    }
    return null;
  }

  /// Resolve only a user entry on the current branch, never the fork menu.
  Map<String, dynamic>? userMessageForEntry(String entryId) {
    final entry = entries.where((e) => e['id'] == entryId).firstOrNull;
    if (entry == null) return null;
    final value = _entryMessage(entry);
    if (value['role'] != 'user' || value['timestamp'] == null) return null;
    return messages
        .where(
          (m) => m['role'] == 'user' && m['timestamp'] == value['timestamp'],
        )
        .firstOrNull;
  }
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
  final Set<AgentChatRuntime> _discardedDrafts = {};
  final Set<String> _deletingChats = {}, _deletingWorkspaces = {};
  AgentWorkspace? selectedWorkspace;
  AgentChatRuntime? selected;
  bool initialized = false, _disposed = false;
  Future<void>? _closeFuture;
  int _selectionRevision = 0;

  /// Read-only inventory for sidebar chat status; never creates a runtime.
  Iterable<AgentChatRuntime> get heldRuntimes => _runtimes.values;
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
        runtime.error = _error(error, runtime);
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
    if (listed.isEmpty) listed = [_newDraft(id)];
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
    await _discardOtherDrafts(chat.id);
    for (final runtime
        in _runtimes.values
            .where((r) => r.chat.id != chat.id && !_busy(r))
            .toList()) {
      await runtime.subscription?.cancel();
      await runtime.client?.close();
      runtime.client = null;
      runtime.messages = [];
      runtime.historyMessages = [];
      runtime.runLimitHit = null;
      runtime.tools.clear();
    }
    final workspace = await store.getWorkspace(chat.workspaceId);
    var runtime = _runtimes[chat.id];
    if (runtime == null) {
      runtime = AgentChatRuntime(
        workspace,
        chat,
        chat.isDraft
            ? const AgentComposerState()
            : await store.readComposer(workspace.id, chat.id),
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
    if (!chat.isDraft) await _rememberChat(workspace.id, chat.id);
    _notify();
    // Restoring history is entirely local; no prompt or model call is made.
    if (restoreHistory && chat.sessionFile != null && runtime.client == null) {
      try {
        await _ensureClient(runtime);
      } catch (error) {
        runtime.error = _error(error, runtime);
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

  AgentChat _newDraft(String workspaceId) => AgentChat(
    id: const Uuid().v4(),
    workspaceId: workspaceId,
    title: initialChatName,
    createdAt: DateTime.now(),
    isDraft: true,
  );

  Future<void> _closeRuntime(AgentChatRuntime runtime) async {
    await runtime.subscription?.cancel();
    runtime.subscription = null;
    await runtime.client?.close();
    runtime.client = null;
    _runtimes.remove(runtime.chat.id);
  }

  Future<void> _discardOtherDrafts(String selectedId) async {
    for (final runtime
        in _runtimes.values
            .where(
              (r) => r.chat.isDraft && r.chat.id != selectedId && !_busy(r),
            )
            .toList()) {
      // An OS import owns its original target until its final callback. Hide the
      // draft now, then remove any late attachment files when the import ends.
      _discardedDrafts.add(runtime);
      chats = chats.where((chat) => chat.id != runtime.chat.id).toList();
      if (runtime.importingImages == 0) {
        await _closeRuntime(runtime);
        _discardedDrafts.remove(runtime);
      }
      await store.discardDraftChat(runtime.workspace.id, runtime.chat.id);
    }
  }

  Future<void> _rememberChat(String workspaceId, String chatId) async {
    final updated = await store.updateWorkspace(
      workspaceId,
      lastSessionId: chatId,
    );
    if (selectedWorkspace?.id == workspaceId) selectedWorkspace = updated;
    workspaces = [
      for (final item in workspaces)
        if (item.id == workspaceId) updated else item,
    ];
  }

  Future<void> _refreshChats(String workspaceId) async {
    final listed = await store.listChats(workspaceId);
    if (selectedWorkspace?.id != workspaceId) return;
    final drafts = chats
        .where(
          (chat) =>
              chat.isDraft &&
              chat.workspaceId == workspaceId &&
              !listed.any((saved) => saved.id == chat.id),
        )
        .toList();
    chats = [...drafts, ...listed];
  }

  Future<void> createChat() async {
    final workspace = selectedWorkspace!;
    // Publish the draft before the first await, so rapid '+' clicks coalesce.
    final chat =
        chats.where((chat) => chat.isDraft).firstOrNull ??
        _newDraft(workspace.id);
    chats = [chat, ...chats.where((item) => !item.isDraft)];
    await selectChat(chat.id);
  }

  Future<void> renameChat(String id, String title) async {
    final workspace = selectedWorkspace!;
    final old = chats.firstWhere((chat) => chat.id == id);
    final chat = old.isDraft
        ? AgentChat(
            id: old.id,
            workspaceId: old.workspaceId,
            title: title,
            createdAt: old.createdAt,
            isDraft: true,
          )
        : await store.updateChat(workspace.id, id, title: title);
    _runtimes[id]?.chat = chat;
    chats = [
      for (final item in chats)
        if (item.id == id) chat else item,
    ];
    await _runtimes[id]?.client?.rename(title);
    _notify();
  }

  static bool _busy(AgentChatRuntime runtime) =>
      runtime.running ||
      runtime.starting ||
      runtime.waitingForSlot ||
      runtime.pendingSends > 0;

  Future<String> deleteChat(String chatId) async {
    final runtime = _runtimes[chatId];
    final workspaceId = runtime?.workspace.id ?? selectedWorkspace!.id;
    if (runtime != null && _busy(runtime)) throw StateError('running');
    if (runtime != null && runtime.importingImages > 0) {
      throw StateError('importing');
    }
    if (_deletingWorkspaces.contains(workspaceId) ||
        !_deletingChats.add(chatId)) {
      throw StateError('deleting');
    }
    try {
      final listed = selectedWorkspace?.id == workspaceId
          ? [...chats]
          : await store.listChats(workspaceId);
      final index = listed.indexWhere((chat) => chat.id == chatId);
      if (index < 0) throw StateError('Chat missing');
      final chat = listed[index];
      if (runtime != null) await _closeRuntime(runtime);
      if (selected?.chat.id == chatId) {
        final next = index + 1 < listed.length
            ? listed[index + 1]
            : index > 0
            ? listed[index - 1]
            : null;
        selected = null;
        if (next != null) await selectChat(next.id);
      }
      final entry = chat.isDraft
          ? await store.trashDraftChat(
              chat,
              runtime?.composer ?? const AgentComposerState(),
            )
          : await store.trashChat(workspaceId, chatId);
      final workspace = await store.getWorkspace(workspaceId);
      final remaining = await store.listChats(workspaceId);
      if (workspace.lastSessionId == chatId) {
        if (remaining.isEmpty) {
          final updated = await store.updateWorkspace(
            workspaceId,
            clearLastSessionId: true,
          );
          if (selectedWorkspace?.id == workspaceId) selectedWorkspace = updated;
          workspaces = [
            for (final item in workspaces)
              if (item.id == workspaceId) updated else item,
          ];
        } else {
          await _rememberChat(workspaceId, remaining.first.id);
        }
      }
      if (selectedWorkspace?.id == workspaceId) {
        chats = chats.where((item) => item.id != chatId).toList();
        await _refreshChats(workspaceId);
        if (selected == null) {
          if (chats.isEmpty) {
            await createChat();
          } else {
            await selectChat(chats.first.id);
          }
        }
      }
      return entry.id;
    } finally {
      _deletingChats.remove(chatId);
      _notify();
    }
  }

  Future<void> undoDeleteChat(String trashId) async {
    final entry = await store.readTrashEntry('chats', trashId);
    final draft = entry.isDraft ? await store.readTrashedDraft(trashId) : null;
    await store.restoreChat(trashId);
    workspaces = await store.listWorkspaces();
    if (selectedWorkspace?.id != entry.workspaceId) {
      await selectWorkspace(entry.workspaceId, restoreHistory: false);
    }
    await _refreshChats(entry.workspaceId);
    if (draft != null) {
      await _discardOtherDrafts(draft.chat.id);
      final workspace = await store.getWorkspace(entry.workspaceId);
      _runtimes[draft.chat.id] = AgentChatRuntime(
        workspace,
        draft.chat,
        draft.composer,
      );
      chats = [draft.chat, ...chats.where((chat) => !chat.isDraft)];
    }
    await selectChat(entry.chatId!);
    _notify();
  }

  Future<String> deleteWorkspace(String workspaceId) async {
    final owned = _runtimes.values
        .where((r) => r.workspace.id == workspaceId)
        .toList();
    if (owned.any(_busy)) throw StateError('running');
    if (owned.any((r) => r.importingImages > 0)) throw StateError('importing');
    if (owned.any((runtime) => _deletingChats.contains(runtime.chat.id)) ||
        !_deletingWorkspaces.add(workspaceId)) {
      throw StateError('deleting');
    }
    try {
      final listed = await store.listWorkspaces();
      if (!listed.any((workspace) => workspace.id == workspaceId)) {
        throw StateError('Workspace missing');
      }
      if (listed.length <= 1) throw StateError('last_workspace');
      for (final runtime in owned) {
        await _closeRuntime(runtime);
      }
      if (selectedWorkspace?.id == workspaceId) {
        selected = null;
        await selectWorkspace(
          listed.firstWhere((workspace) => workspace.id != workspaceId).id,
        );
      }
      final entry = await store.trashWorkspace(workspaceId);
      workspaces = await store.listWorkspaces();
      settings = await store.patchSettings({
        'selectedWorkspaceId': selectedWorkspace!.id,
      });
      return entry.id;
    } finally {
      _deletingWorkspaces.remove(workspaceId);
      _notify();
    }
  }

  Future<void> undoDeleteWorkspace(String trashId) async {
    final entry = await store.readTrashEntry('workspaces', trashId);
    await store.restoreWorkspace(trashId);
    workspaces = await store.listWorkspaces();
    await selectWorkspace(entry.workspaceId);
    _notify();
  }

  /// Restore from the settings trash view: unlike undo, keep the current
  /// selection and only refresh lists that may now contain the item.
  Future<void> restoreTrashed(AgentTrashKind kind, String id) async {
    switch (kind) {
      case AgentTrashKind.chat:
        await store.restoreChat(id);
      case AgentTrashKind.workspace:
        await store.restoreWorkspace(id);
      case AgentTrashKind.skill:
        throw ArgumentError('Skills are restored through the skill store');
    }
    workspaces = await store.listWorkspaces();
    if (selectedWorkspace case final workspace?) {
      await _refreshChats(workspace.id);
    }
    _notify();
  }

  Future<List<AgentChatSearchHit>> searchChats(String query) =>
      store.searchChats(selectedWorkspace!.id, query);

  Future<void> updateSettings(
    Map<String, dynamic> changes, {
    Map<String, dynamic>? expected,
  }) async {
    final before = settings;
    settings = expected == null
        ? await store.patchSettings(changes)
        : await store.patchSettingsChecked(changes, expected: expected);
    if (before.providerId != settings.providerId ||
        before.modelId != settings.modelId) {
      for (final runtime in _runtimes.values) {
        runtime._clearVisionNotice();
      }
    }
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

  Future<void> setWorkspacePrompt(
    String? text, {
    String? expectedWorkspaceId,
    bool checkPrompt = false,
    String? expectedPrompt,
  }) async {
    final id = selectedWorkspace!.id;
    if (expectedWorkspaceId != null && expectedWorkspaceId != id) {
      throw StateError('Selected workspace changed while editing');
    }
    await store.updateWorkspace(
      id,
      customSystemPrompt: text,
      resetPrompt: text == null,
      checkPrompt: checkPrompt,
      expectedPrompt: expectedPrompt,
      requireSelected: expectedWorkspaceId != null,
    );
    final updated = await store.getWorkspace(id);
    if (selectedWorkspace?.id == id) selectedWorkspace = updated;
    workspaces = [
      for (final workspace in workspaces)
        if (workspace.id == id) updated else workspace,
    ];
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

  Future<void> configureSkill(String key, {bool? enabled, String? mode}) async {
    settings = await store.configureSkill(key, enabled: enabled, mode: mode);
    _notify();
  }

  Future<void> removeSkill(String key, {String? workspaceId}) async {
    settings = await store.removeSkill(key, workspaceId: workspaceId);
    _notify();
  }

  /// Folder changes are only visible to a fresh host; idle chats restart on next send.
  void skillFilesChanged() {
    for (final runtime in _runtimes.values) {
      runtime.extensionSignature = null;
    }
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
    checkImageImportTarget(runtime);
    final info = await inspectAgentAttachment(bytes);
    checkImageImportTarget(runtime);
    final attachment = await store.addAttachment(
      runtime.workspace.id,
      runtime.chat.id,
      name: name,
      bytes: bytes,
      mimeType: info.mimeType,
      width: info.width,
      height: info.height,
      metadata: info.metadata,
    );
    checkImageImportTarget(runtime);
    runtime.composer = AgentComposerState(
      text: runtime.composer.text,
      attachments: [...runtime.composer.attachments, attachment],
      pending: runtime.composer.pending,
      interrupted: runtime.composer.interrupted,
    );
    await _persist(runtime);
    _notify();
  }

  void checkImageImportTarget(AgentChatRuntime runtime) {
    if (_disposed ||
        _closeFuture != null ||
        !identical(_runtimes[runtime.chat.id], runtime)) {
      throw const AgentImageInputException('closed');
    }
  }

  /// Reserve the original conversation before the first OS/file await.
  Future<T> importImages<T>(
    AgentChatRuntime runtime,
    Future<T> Function() action, {
    int imageCount = 0,
  }) async {
    checkImageImportTarget(runtime);
    runtime.importingImages++;
    runtime.pendingImageCount += imageCount;
    _notify();
    try {
      return await action();
    } finally {
      runtime.importingImages--;
      runtime.pendingImageCount -= imageCount;
      if (runtime.importingImages == 0 && _discardedDrafts.remove(runtime)) {
        await _closeRuntime(runtime);
        await store.discardDraftChat(runtime.workspace.id, runtime.chat.id);
      }
      _notify();
    }
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
    if (_deletingChats.contains(runtime.chat.id) ||
        _deletingWorkspaces.contains(runtime.workspace.id) ||
        !identical(_runtimes[runtime.chat.id], runtime)) {
      throw StateError('deleting');
    }
    var client = runtime.client;
    final changed =
        runtime.providerId != settings.providerId ||
        runtime.modelId != settings.modelId ||
        runtime.reasoningEffort != settings.reasoningEffort ||
        runtime.modelRevision != readModelRevision() ||
        runtime.maxRequestsPerRun != settings.maxRequestsPerRun ||
        runtime.extensionSignature != settings.extensionSignature;
    if (client != null && !client.isClosed && (!changed || runtime.running)) {
      await _recordSessionFile(runtime, client);
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
      if (runtime.providerId != selection.providerId ||
          runtime.modelId != selection.modelId ||
          runtime.modelRevision != revision) {
        runtime._clearVisionNotice();
      }
      runtime.providerId = selection.providerId;
      runtime.modelId = selection.modelId;
      runtime.reasoningEffort = selection.reasoningEffort;
      runtime.modelRevision = revision;
      runtime.maxRequestsPerRun = selection.maxRequestsPerRun;
      runtime.extensionSignature = selection.extensionSignature;
      _applyState(runtime, client.initialState);
      await _recordSessionFile(runtime, client);
      runtime.subscription = client.events.listen(
        (event) => _event(runtime, event),
      );
      return client;
    } finally {
      runtime.starting = false;
      _notify();
    }
  }

  Future<void> _recordSessionFile(
    AgentChatRuntime runtime,
    PiHostClient client,
  ) async {
    final path = client.initialState['sessionFile'] as String?;
    if (path != null &&
        !runtime.chat.isDraft &&
        runtime.chat.sessionFile == null) {
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
        runtime.chat.id,
        sessionFile: p.relative(canonical, from: root),
      );
    }
  }

  Future<void> send({bool steer = false}) async {
    await _send(steer: steer);
  }

  /// Sends a standalone message without consuming or restoring over the draft.
  Future<bool> sendText(String text) => _send(text: text);

  /// Fork at a past user entry without consuming the bottom draft or its queue.
  /// Image indexes refer to the original content parts, not the image ordinal.
  Future<bool> resendFrom(
    String entryId,
    String text, {
    required List<int> keepImagePartIndexes,
  }) => _send(
    text: text,
    resendEntryId: entryId,
    keepImagePartIndexes: List.of(keepImagePartIndexes),
  );

  Future<({String text, List<Map<String, dynamic>> images, String? notice})>
  _preparePrompt(
    AgentChatRuntime runtime,
    PiHostClient client,
    String text, {
    List<AgentAttachment> attachments = const [],
    List<Map<String, dynamic>> imageParts = const [],
    List<Map<String, dynamic>> manifestRows = const [],
  }) async {
    final images = <Map<String, dynamic>>[];
    final vision = (client.initialState['model'] as Map?)?['vision'] == true;
    Future<void> addImage(Uint8List bytes, String mimeType) async {
      final dimensions = NaiResolutionAdapter.readImageSize(bytes);
      if (dimensions == null || dimensions.$1 * dimensions.$2 > 64000000) {
        throw const NaiAgentToolError(
          'image_size',
          'Invalid image or more than 64 million pixels',
        );
      }
      if (!vision) return;
      final visual = await agentAttachmentVisualBytes(bytes, mimeType);
      final image = await optimizePromptAssistantImagePartForUpload(
        PromptAssistantImagePart(
          bytes: visual,
          mimeType: mimeType == 'image/bmp' ? 'image/png' : mimeType,
        ),
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

    for (final attachment in attachments) {
      await addImage(
        await store.readAttachment(runtime.workspace.id, attachment),
        attachment.mimeType,
      );
    }
    for (final part in imageParts) {
      await addImage(
        base64Decode(part['data'] as String),
        part['mimeType'] as String,
      );
    }
    final rows = [
      ...manifestRows,
      for (final a in attachments)
        {
          'name': a.name,
          'path': a.relativePath,
          if (a.width != null) 'width': a.width,
          if (a.height != null) 'height': a.height,
          if (a.metadata != null)
            'nai_metadata': {
              for (final key in ['seed', 'model', 'steps', 'sampler'])
                if (a.metadata![key] != null) key: a.metadata![key],
            },
        },
    ];
    final count = attachments.length + imageParts.length;
    return (
      text: '$text${agentAttachmentManifest(rows, vision: vision)}',
      images: images,
      notice: !vision && count > 0
          ? client.visionAccess.skippedAttachmentsNotice(count)
          : null,
    );
  }

  Future<bool> _send({
    bool steer = false,
    String? text,
    String? resendEntryId,
    List<int> keepImagePartIndexes = const [],
  }) async {
    final runtime = selected;
    if (runtime == null) return false;
    final resending = resendEntryId != null;
    final fromComposer = text == null;
    final original = fromComposer
        ? runtime.composer
        : AgentComposerState(text: text);
    if (runtime._resending ||
        (!fromComposer && runtime.running) ||
        _deletingChats.contains(runtime.chat.id) ||
        _deletingWorkspaces.contains(runtime.workspace.id) ||
        _discardedDrafts.contains(runtime) ||
        (runtime.pendingSends > 0 && !runtime.running) ||
        runtime.starting ||
        runtime.importingImages > 0 ||
        (original.text.trim().isEmpty &&
            original.attachments.isEmpty &&
            (!resending || keepImagePartIndexes.isEmpty))) {
      return false;
    }
    if (resending && runtime.userMessageForEntry(resendEntryId) == null) {
      return false;
    }
    final wasRunning = runtime.running;
    runtime.pendingSends++;
    runtime._resending = resending;
    runtime.error = null;
    runtime.runLimitHit = null;
    try {
      if (runtime.chat.isDraft) {
        runtime.starting = true;
        try {
          runtime.chat = await store.saveDraftChat(runtime.chat);
          await _persist(runtime);
          await _rememberChat(runtime.workspace.id, runtime.chat.id);
          await _refreshChats(runtime.workspace.id);
        } finally {
          runtime.starting = false;
        }
      }
      final client = await _ensureClient(runtime);
      final imageParts = <Map<String, dynamic>>[];
      final manifestRows = <Map<String, dynamic>>[];
      if (resending) {
        final message = runtime.userMessageForEntry(resendEntryId);
        if (message == null) return false;
        final parts = message['content'] is List
            ? _maps(message['content'])
            : <Map<String, dynamic>>[];
        final keep = keepImagePartIndexes.toSet();
        if (keep.length != keepImagePartIndexes.length ||
            keep.any(
              (i) =>
                  i < 0 ||
                  i >= parts.length ||
                  parts[i]['type'] != 'image' ||
                  parts[i]['data'] is! String ||
                  parts[i]['mimeType'] is! String,
            )) {
          return false;
        }
        final rawText = message['content'] is String
            ? message['content'] as String
            : parts
                  .where((p) => p['type'] == 'text')
                  .map((p) => p['text'] ?? '')
                  .join('\n');
        final rows = agentAttachmentManifestRows(rawText);
        var imageIndex = 0;
        for (final (i, part) in parts.indexed) {
          if (part['type'] != 'image') continue;
          if (keep.contains(i)) {
            imageParts.add(part);
            if (rows.elementAtOrNull(imageIndex) case final row?) {
              manifestRows.add(row);
            }
          }
          imageIndex++;
        }
      }
      final prompt = await _preparePrompt(
        runtime,
        client,
        resending ? stripAgentAttachmentManifest(original.text) : original.text,
        attachments: original.attachments,
        imageParts: imageParts,
        manifestRows: manifestRows,
      );
      if (resending) {
        if (!identical(selected, runtime) ||
            _disposed ||
            _deletingChats.contains(runtime.chat.id) ||
            _deletingWorkspaces.contains(runtime.workspace.id) ||
            runtime.userMessageForEntry(resendEntryId) == null) {
          return false;
        }
        final navigation = await client.navigate(resendEntryId);
        _applyState(runtime, navigation);
        if (navigation['cancelled'] == true) return false;
      }
      if (fromComposer &&
          (runtime.importingImages > 0 ||
              original.text != runtime.composer.text ||
              jsonEncode(
                    original.attachments.map((a) => a.toJson()).toList(),
                  ) !=
                  jsonEncode(
                    runtime.composer.attachments
                        .map((a) => a.toJson())
                        .toList(),
                  ))) {
        throw const NaiAgentToolError(
          'composer_changed',
          'Input changed while preparing; send the current draft again',
        );
      }
      final visionNotice = prompt.notice;
      final noticeRevision = ++runtime._visionNoticeRevision;
      final queueId = resending ? null : const Uuid().v4();
      if (!resending) {
        runtime.composer = AgentComposerState(
          text: fromComposer ? '' : runtime.composer.text,
          attachments: fromComposer ? const [] : runtime.composer.attachments,
          interrupted: !fromComposer && runtime.composer.interrupted,
          pending: [
            ...runtime.composer.pending,
            {
              'queueId': queueId,
              'text': original.text,
              'behavior': steer ? 'steer' : 'followUp',
              'attachments': original.attachments
                  .map((a) => a.toJson())
                  .toList(),
            },
          ],
        );
      }
      // Client startup may have restored the previous run's terminal error.
      runtime.error = null;
      runtime.runLimitHit = null;
      runtime.running = true;
      if (visionNotice != null) runtime.visionNotice = visionNotice;
      await _persist(runtime);
      _notify();
      final reply = await client.prompt(
        prompt.text,
        images: prompt.images.isEmpty ? null : prompt.images,
        steer: steer,
        queueId: queueId,
      );
      _applyState(runtime, reply);
      if (runtime._visionNoticeRevision == noticeRevision &&
          (visionNotice != null || runtime.error == null)) {
        runtime.visionNotice = visionNotice;
      }
      if (!wasRunning) {
        if (!resending &&
            runtime.chat.title == initialChatName &&
            original.text.trim().isNotEmpty) {
          final title = original.text.trim().replaceAll(RegExp(r'\s+'), ' ');
          runtime.chat = await store.updateChat(
            runtime.workspace.id,
            runtime.chat.id,
            title: title.characters.take(32).toString(),
          );
          await client.rename(runtime.chat.title);
          if (selectedWorkspace?.id == runtime.workspace.id) {
            await _refreshChats(runtime.workspace.id);
          }
        }
        runtime.running = false;
      }
      await _persist(runtime);
      return true;
    } catch (error) {
      runtime.error = _error(error, runtime);
      if (!wasRunning) runtime.running = false;
      await _persist(runtime);
      return false;
    } finally {
      runtime._resending = false;
      runtime.pendingSends--;
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

  Future<void> restorePending(String id) async {
    if (_disposed || _closeFuture != null) return;
    final runtime = selected!;
    final item = runtime.composer.pending.firstWhere((p) => p['queueId'] == id);
    final revision = runtime._composerRevision;
    if (runtime.composer.text.isNotEmpty ||
        runtime.composer.attachments.isNotEmpty) {
      throw const NaiAgentToolError(
        'composer_not_empty',
        'Save or send the current draft before restoring another message',
      );
    }
    if (runtime.queue.any((p) => p['queueId'] == id)) {
      await runtime.client!.editQueue(id, remove: true);
      if (_disposed ||
          _closeFuture != null ||
          !identical(_runtimes[runtime.chat.id], runtime)) {
        return;
      }
      runtime.queue.removeWhere((p) => p['queueId'] == id);
      // The host no longer owns this message. Keep it recoverable if the user
      // edited the composer or a host state update already removed its row.
      final current = runtime.composer;
      runtime.composer = AgentComposerState(
        text: current.text,
        attachments: current.attachments,
        interrupted: current.interrupted,
        wasRunning: current.wasRunning,
        pending: [
          for (final pending in current.pending)
            pending['queueId'] == id
                ? {...pending, 'recovered': true}
                : pending,
          if (!current.pending.any((pending) => pending['queueId'] == id))
            {...item, 'recovered': true},
        ],
      );
      if (revision != runtime._composerRevision) {
        await _persist(runtime);
        _notify();
        return;
      }
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
    runtime.runLimitHit = null;
    runtime.running = true;
    _notify();
    try {
      _applyState(runtime, await client.compact());
      runtime.runLimitHit = null;
    } catch (error) {
      runtime.error = _error(error, runtime);
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
      runtime.runLimitHit = null;
      runtime.error =
          '${currentL10n.naiAgent_extensionError}\n${envelope['message'] ?? ''}';
    }
    if (envelope['type'] == 'extension_ui') {
      final key = envelope['key'] as String? ?? '';
      switch (envelope['method']) {
        case 'notify':
          final text = '${envelope['message'] ?? ''}';
          if (!runtime.extensionNotices.contains(text)) {
            runtime.extensionNotices.add(text);
            if (runtime.extensionNotices.length > 4) {
              runtime.extensionNotices.removeAt(0);
            }
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
      runtime.runLimitHit = null;
      runtime.error = currentL10n.naiAgent_interrupted;
      runtime.composer = AgentComposerState(
        text: runtime.composer.text,
        attachments: runtime.composer.attachments,
        pending: runtime.composer.pending,
        interrupted: true,
      );
      unawaited(_persist(runtime));
    }
    if (envelope['type'] == 'queue' && !runtime._resending) {
      final queue = _maps(envelope['queue']);
      final remaining = queue.map((item) => item['queueId']).toSet();
      final consumed = {
        ...envelope['consumedQueueIds'] as List? ?? [],
        for (final item in runtime.queue)
          if (!remaining.contains(item['queueId'])) item['queueId'],
      };
      runtime.queue = queue;
      runtime.composer = AgentComposerState(
        text: runtime.composer.text,
        attachments: runtime.composer.attachments,
        pending: runtime.composer.pending
            .where(
              (item) =>
                  item['recovered'] == true ||
                  !consumed.contains(item['queueId']),
            )
            .toList(),
        interrupted: runtime.composer.interrupted,
      );
      unawaited(_persist(runtime));
    }
    final event = envelope['event'] as Map?;
    if (event != null) {
      final type = event['type'];
      if (type == 'compaction_start') {
        runtime.compactionReason = event['reason'] as String?;
      }
      if (type == 'compaction_end') {
        final reason = event['reason'] ?? runtime.compactionReason;
        final result = event['result'];
        if ((reason == 'threshold' || reason == 'overflow') && result is Map) {
          runtime.autoCompactions.add(AgentChatRuntime.compactionKey(result));
        }
        runtime.compactionReason = null;
        unawaited(_refreshAfterCompaction(runtime));
      }
      if (type == 'message_start') {
        final message = Map<String, dynamic>.from(event['message'] as Map);
        runtime.messages = [...runtime.messages, message];
      }
      if (type == 'message_update' || type == 'message_end') {
        final message = Map<String, dynamic>.from(event['message'] as Map);
        if (message['role'] == 'assistant' &&
            message['stopReason'] == 'error') {
          _applyAssistantError(runtime, message);
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

  Future<void> _refreshAfterCompaction(AgentChatRuntime runtime) async {
    final client = runtime.client;
    if (client == null) return;
    try {
      final atRequest = List<Map<String, dynamic>>.of(runtime.messages);
      final state = await client.state();
      if (_disposed || !identical(runtime.client, client)) return;
      // state() is a snapshot. Replay messages arriving after its request so an
      // auto-compaction refresh cannot erase a concurrently streamed answer.
      final latest = List<Map<String, dynamic>>.of(runtime.messages);
      _applyState(runtime, state);
      for (final message in latest.where(
        (m) => !atRequest.any((old) => identical(old, m)),
      )) {
        if (message['role'] == 'compactionSummary') continue;
        final timestamp = message['timestamp'];
        if (timestamp == null) continue;
        final index = runtime.messages.indexWhere(
          (m) => m['role'] == message['role'] && m['timestamp'] == timestamp,
        );
        if (index >= 0) {
          runtime.messages[index] = message;
        } else {
          runtime.messages.add(message);
        }
      }
      _notify();
    } catch (_) {
      // Best-effort read refresh; never turn compaction into a model request.
    }
  }

  void dismissExtensionNotices(AgentChatRuntime runtime) {
    runtime.extensionNotices.clear();
    runtime._clearVisionNotice();
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
    runtime.historyMessages = _maps(value['historyMessages']);
    final lastAssistant = runtime.messages
        .where((m) => m['role'] == 'assistant')
        .lastOrNull;
    if (lastAssistant?['stopReason'] == 'error') {
      _applyAssistantError(runtime, lastAssistant!);
    }
    if (!runtime._resending) runtime.queue = _maps(value['queue']);
    _applyUsage(runtime, value);
    runtime.entries = _maps(value['entries']);
    runtime.userEntries = _maps(value['userMessages']);
    if (runtime._resending) return;
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

  Future<void> _persist(AgentChatRuntime runtime) =>
      runtime.chat.isDraft || !identical(_runtimes[runtime.chat.id], runtime)
      ? Future.value()
      : store.saveComposer(
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
  // Pi can serialize this as an assistant error, or reject the prompt itself.
  // Match the host's stable phrase, allowing Pi's "Error: " prefix.
  static const _runLimitMarker = 'Run request limit reached';

  bool _recordRunLimit(AgentChatRuntime runtime, Object? error) {
    if (!error.toString().contains(_runLimitMarker)) return false;
    runtime.runLimitHit =
        runtime.maxRequestsPerRun ?? settings.maxRequestsPerRun;
    runtime.error = null;
    return true;
  }

  void _applyAssistantError(
    AgentChatRuntime runtime,
    Map<String, dynamic> message,
  ) {
    if (_recordRunLimit(runtime, message['errorMessage'])) return;
    runtime.runLimitHit = null;
    runtime.error =
        '${currentL10n.naiAgent_error}\n${message['errorMessage'] ?? ''}';
  }

  String? _error(Object error, [AgentChatRuntime? runtime]) {
    if (runtime != null) {
      if (_recordRunLimit(runtime, error)) return null;
      runtime.runLimitHit = null;
    }
    final l = currentL10n;
    if (error is NaiAgentToolError) {
      return switch (error.code) {
        'vision_disabled' || 'vision_unavailable' =>
          (runtime?.client?.visionAccess ?? const NaiAgentVisionAccess())
              .unavailableMessage,
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
    for (final runtime in _runtimes.values.toList()) {
      await _persist(runtime);
      await runtime.subscription?.cancel();
      await runtime.client?.close();
      if (runtime.chat.isDraft) {
        await store.discardDraftChat(runtime.workspace.id, runtime.chat.id);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(close());
    super.dispose();
  }
}

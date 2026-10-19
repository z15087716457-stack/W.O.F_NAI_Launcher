import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/nai_agent/attachment_image.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart' as store;
import '../../../core/utils/file_name_sanitizer.dart';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/director_tools_notifier.dart';
import '../../providers/generation/cloud_upscale_provider.dart';
import '../../providers/generation/image_workflow_controller.dart';
import '../../providers/generation/local_upscale_provider.dart';
import '../../providers/generation/preview_selection_provider.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/krita/bridge_draft_snapshot.dart';
import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../providers/nai_agent/nai_agent_model_provider.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_skills_provider.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/pill_workspace_provider.dart';
import '../../providers/prompt_block_library_provider.dart';
import '../../providers/style_explore/explore_run_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../router/app_router.dart';
import '../../ui/agent/agent_contract.dart';
import '../../ui/agent/agent_panel.dart';
import '../../utils/dropped_file_reader.dart';
import '../../utils/nai_agent_file_link.dart';
import '../../utils/nai_agent_image_reader.dart';
import '../../widgets/common/app_toast.dart';
import '../../widgets/common/draggable_memory_image.dart';
import '../../widgets/nai_agent/nai_agent_image_input.dart';
import '../blocks_preferences.dart';
import 'agent_context.dart';
import 'agent_diff_undo.dart';
import 'agent_image_info.dart';
import 'agent_pending_mapper.dart';
import 'agent_resources.dart';
import 'agent_thread_mapper.dart';

/// The only provider-aware adapter for the sidebar. The controller and Dart
/// paid gates retain ownership; AgentPanel receives read-only projections.
class AgentWiring extends ConsumerStatefulWidget {
  const AgentWiring({super.key});
  @override
  ConsumerState<AgentWiring> createState() => _AgentWiringState();
}

class _AgentWiringState extends ConsumerState<AgentWiring>
    with WidgetsBindingObserver {
  late final _resources = AgentResources(_resourceChanged);
  late final _mapper = AgentThreadMapper(_resources);
  final _readingTargets = <AgentChatRuntime>{};
  var _revision = 0;
  AgentThreadMapping? _mapping;
  final _recentImages = <String, AgentImage>{};

  void _resourceChanged() {
    if (mounted) setState(() => _revision++);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final controller = ref.read(naiAgentControllerProvider);
    unawaited(
      controller.ready.then((_) async {
        if (mounted) await controller.loadHistory();
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resources.refreshRules();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resources.dispose();
    super.dispose();
  }

  NaiAgentWorkspaceController get controller =>
      ref.read(naiAgentControllerProvider);

  Future<bool> _run(Future<void> Function() action) async {
    await action();
    return true;
  }

  void _background(Future<void> Function() action) {
    unawaited(
      Future<void>.sync(action).catchError((Object _) {
        if (mounted) AppToast.error(context, context.l10n.naiAgent_error);
      }),
    );
  }

  Future<bool> _import(
    AgentChatRuntime target,
    List<Future<DroppedFileData?> Function()> sources,
  ) async {
    final report = await importAgentImageSources(controller, target, sources);
    if (mounted && identical(controller.selected, target)) {
      presentAgentImageImport(context, report);
    }
    return true; // Detailed partial-failure feedback is already presented above.
  }

  Future<bool> _pick() async {
    final target = controller.selected;
    if (target == null) return false;
    await controller.importImages(target, () async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
        allowMultiple: true,
      );
      if (result == null) return;
      await _import(target, [
        for (final file in result.files)
          () async {
            if (file.path != null) return readAgentImageFile(file.path!);
            if (file.bytes == null) {
              throw const AgentImageInputException('unreadable');
            }
            return DroppedFileData(fileName: file.name, bytes: file.bytes!);
          },
      ]);
    });
    return true;
  }

  Future<String?> _paste() async {
    final target = controller.selected;
    if (target == null || !_readingTargets.add(target)) return null;
    try {
      return await controller.importImages(target, () async {
        var readers = <DataReader>[];
        try {
          readers = await ref.read(naiAgentClipboardReadersProvider)();
        } catch (_) {
          // Native clipboard failure must not swallow ordinary text.
        }
        controller.checkImageImportTarget(target);
        final report = await importAgentImageSources(controller, target, [
          for (final reader in readers)
            () => readAgentImage(reader, clipboard: true),
        ]);
        if (report.added > 0 || report.failures.isNotEmpty) {
          if (mounted && identical(controller.selected, target)) {
            presentAgentImageImport(context, report);
          }
          return null;
        }
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        controller.checkImageImportTarget(target);
        if (!mounted || !identical(controller.selected, target)) return null;
        return data?.text;
      });
    } catch (error) {
      if (mounted &&
          (error is! AgentImageInputException || error.code != 'closed')) {
        presentAgentImageImport(
          context,
          AgentImageImportReport()..failures.add('unreadable'),
        );
      }
      return null;
    } finally {
      _readingTargets.remove(target);
    }
  }

  GeneratedImage? _selectedImage() {
    if (!ref.exists(imageGenerationNotifierProvider)) return null;
    final state = ref.read(imageGenerationNotifierProvider);
    final id = ref.read(generationPreviewSelectionProvider);
    return id == null
        ? state.mergedPanelImages.firstOrNull
        : state.findImageById(id);
  }

  Future<bool> _attachCanvas() async {
    final target = controller.selected, image = _selectedImage();
    if (target == null || image == null || !image.canDrag) return false;
    return _import(target, [
      () async => DroppedFileData(
        fileName: 'canvas_${image.id}.png',
        bytes: image.bytes,
      ),
    ]);
  }

  Future<bool> _attachImage(String id) async {
    final target = controller.selected;
    if (target == null) return false;
    final image = _mapping?.images[id] ?? _recentImages[id];
    if (image?.image case final MemoryImage memory) {
      return _import(target, [
        () async =>
            DroppedFileData(fileName: 'agent-image.png', bytes: memory.bytes),
      ]);
    }
    final historyId = image?.historyId ?? id;
    if (ref.exists(imageGenerationNotifierProvider)) {
      final history = ref
          .read(imageGenerationNotifierProvider)
          .findImageById(historyId);
      if (history != null && history.canDrag) {
        return _import(target, [
          () async => DroppedFileData(
            fileName: 'canvas_$historyId.png',
            bytes: history.bytes,
          ),
        ]);
      }
    }
    return false;
  }

  Future<bool> _export() async {
    final runtime = controller.selected;
    if (runtime == null) return false;
    final bytes = await controller.exportSession(runtime);
    if (!mounted) return false;
    final target = await FilePicker.platform.saveFile(
      dialogTitle: context.l10n.ag_menuExport,
      fileName:
          '${FileNameSanitizer.sanitize(runtime.chat.title, maxLength: 80)}.jsonl',
      type: FileType.custom,
      allowedExtensions: const ['jsonl'],
    );
    if (target != null) await File(target).writeAsBytes(bytes, flush: true);
    return true;
  }

  void _settings({bool models = false, AgentMemoryTarget? memory}) {
    final anchor = switch (memory) {
      AgentMemoryTarget.global => 'agentInstructions',
      AgentMemoryTarget.workspace => 'agentWorkspaceRules',
      AgentMemoryTarget.skills => 'agentSkills',
      null => null,
    };
    context.go(
      Uri(
        path: AppRoutes.settings,
        queryParameters: {
          'section': models ? 'models' : 'agent',
          if (anchor != null) 'anchor': anchor,
        },
      ).toString(),
    );
  }

  void _openLink(String url) {
    final runtime = controller.selected;
    final uri = Uri.tryParse(url);
    if (runtime == null || uri == null) return;
    _background(() async {
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        await launchUrl(uri);
      } else {
        final file = await resolveAgentFileLink(
          runtime.workspace.directory,
          uri,
        );
        if (file != null) await launchUrl(file);
      }
    });
  }

  /// Observe exactly the dependencies used by existing quote check closures.
  /// Never initialize services just because a standalone sidebar was mounted.
  void _watchQuoteInputs() {
    if (ref.exists(authNotifierProvider)) ref.watch(authNotifierProvider);
    if (ref.exists(subscriptionNotifierProvider)) {
      ref.watch(subscriptionNotifierProvider);
    }
    if (ref.exists(generationParamsNotifierProvider)) {
      ref.watch(generationParamsNotifierProvider);
      ref.watch(bridgeDraftVersionProvider);
    }
    if (ref.exists(imageGenerationNotifierProvider)) {
      ref.watch(imageGenerationNotifierProvider);
    }
    if (ref.exists(pillWorkspaceRevisionProvider)) {
      ref.watch(pillWorkspaceRevisionProvider);
    }
    if (ref.exists(promptBlockLibraryNotifierProvider)) {
      ref.watch(promptBlockLibraryNotifierProvider);
    }
    if (ref.exists(imageWorkflowControllerProvider)) {
      ref.watch(imageWorkflowControllerProvider);
    }
    if (ref.exists(exploreRunListNotifierProvider)) {
      ref.watch(exploreRunListNotifierProvider);
    }
    if (ref.exists(directorToolsNotifierProvider)) {
      ref.watch(directorToolsNotifierProvider);
    }
    if (ref.exists(cloudUpscaleTaskProvider)) {
      ref.watch(cloudUpscaleTaskProvider);
    }
    if (ref.exists(localUpscaleTaskProvider)) {
      ref.watch(localUpscaleTaskProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(naiAgentControllerProvider), r = c.selected;
    final l = context.l10n;
    final questions = ref.watch(naiAgentQuestionsProvider);
    final generations = ref.watch(naiAgentGenerationApprovalsProvider);
    final imageApprovals = ref.watch(naiAgentImageApprovalsProvider);
    ref.listen(naiAgentControllerProvider, (_, _) => _revision++);
    ref.listen(naiAgentQuestionsProvider, (_, _) => _revision++);
    ref.listen(naiAgentGenerationApprovalsProvider, (_, _) => _revision++);
    ref.listen(naiAgentImageApprovalsProvider, (_, _) => _revision++);
    final config = ref.watch(promptAssistantConfigProvider);
    _watchQuoteInputs();
    final pending = <AgentPending>[
      if (r != null) ...[
        for (final q in questions.forChat(r.chat.id)) agentQuestionData(q),
        for (final g in generations.forChat(r.chat.id))
          agentGenerationGate(g, l),
        for (final g in imageApprovals.forChat(r.chat.id)) agentImageGate(g, l),
      ],
    ];
    final provider = config.providers
        .where((p) => p.enabled && p.id == c.settings.providerId)
        .firstOrNull;
    final model = config.models
        .where(
          (m) =>
              m.providerId == provider?.id &&
              m.name == c.settings.modelId &&
              !m.isPlaceholder &&
              m.supportsTools != false,
        )
        .firstOrNull;
    final efforts = provider == null || model == null
        ? <String>[]
        : naiAgentReasoningEfforts(provider, model);
    final blocked = model == null
        ? AgentSendBlock.noModel
        : r?.starting == true
        ? AgentSendBlock.starting
        : (r?.importingImages ?? 0) > 0
        ? AgentSendBlock.importing
        : null;
    String? version;
    final mentions = <AgentMention>[];
    AgentDraftSummary? draft;
    if (ref.exists(generationParamsNotifierProvider)) {
      final snapshot = ref.watch(agentDraftProvider);
      version = ref.watch(bridgeDraftVersionProvider);
      mentions.addAll(agentDraftMentions(snapshot, l));
      final selected = _selectedImage();
      draft = agentDraftSummary(
        snapshot,
        ref.watch(generationParamsNotifierProvider),
        selected == null ? null : MemoryImage(selected.bytes),
      );
    }
    final mapping = r == null
        ? null
        : _mapper.map(
            r,
            draftVersion: version,
            waitingUser: pending.isNotEmpty,
          );
    _mapping = mapping;
    final recent = <String, AgentImage>{};
    for (final image
        in mapping?.shelf.groups.firstOrNull?.images ?? <AgentImage>[]) {
      recent[image.historyId ?? image.id] = image;
    }
    if (ref.exists(imageGenerationNotifierProvider)) {
      final state = ref.watch(imageGenerationNotifierProvider);
      ref.watch(generationPreviewSelectionProvider);
      for (final image in state.mergedPanelImages) {
        if (recent.length >= 8) break;
        if (!image.canDrag) continue;
        recent.putIfAbsent(
          image.id,
          () => AgentImage(
            id: image.id,
            image: MemoryImage(image.bytes),
            historyId: image.id,
            width: image.width,
            height: image.height,
          ),
        );
      }
    }
    _recentImages
      ..clear()
      ..addEntries(recent.values.take(8).map((i) => MapEntry(i.id, i)));
    for (final image in recent.values.take(8)) {
      mentions.add(
        AgentMention(
          id: image.id,
          kind: AgentMentionKind.image,
          label: image.label ?? image.historyId ?? image.id,
          detail: image.width == null ? null : '${image.width}×${image.height}',
          image: image.image,
        ),
      );
    }
    if (ref.exists(promptBlockLibraryNotifierProvider)) {
      mentions.addAll(
        agentBlockMentions(
          ref.watch(promptBlockLibraryNotifierProvider).valueOrNull,
          recentIds:
              ref.watch(blocksPreferencesProvider).valueOrNull?.recentIds ??
              const [],
        ),
      );
    }
    final skills = r == null
        ? null
        : ref.watch(naiAgentSkillsProvider(r.workspace.id)).valueOrNull;
    final active =
        skills?.skills
            .where(
              (s) =>
                  s.enabled &&
                  s.state == 'active' &&
                  !c.settings.disabledSkills.contains(s.key),
            )
            .toList() ??
        [];
    // 与设置页一致：内置 Skill 置顶，其余保持宿主给的顺序。
    final skillOptions = [
      ...active.where((s) => s.builtin),
      ...active.where((s) => !s.builtin),
    ];
    AgentChatInfo chatInfo(store.AgentChat chat) {
      final runtime = c.heldRuntimes
          .where((r) => r.chat.id == chat.id)
          .firstOrNull;
      final waiting =
          questions.forChat(chat.id).isNotEmpty ||
          generations.forChat(chat.id).isNotEmpty ||
          imageApprovals.forChat(chat.id).isNotEmpty;
      return AgentChatInfo(
        id: chat.id,
        title: chat.title,
        createdAt: chat.createdAt.toLocal(),
        canExport: chat.sessionFile != null,
        state: waiting
            ? AgentChatState.waitingUser
            : runtime != null && (runtime.running || runtime.starting)
            ? AgentChatState.running
            : AgentChatState.idle,
      );
    }

    final workspace = c.selectedWorkspace;
    final tokenStats = agentMap(r?.stats['tokens']);
    final data = AgentViewData(
      now: DateTime.now(),
      workspace: AgentWorkspaceInfo(
        id: workspace?.id ?? '',
        name: workspace?.name ?? c.initialWorkspaceName,
      ),
      chat: r == null
          ? AgentChatInfo(
              id: '',
              title: c.initialChatName,
              createdAt: DateTime.now(),
            )
          : chatInfo(r.chat),
      workspaces: [
        for (final w in c.workspaces)
          AgentWorkspaceInfo(id: w.id, name: w.name),
      ],
      chats: c.chats.map(chatInfo).toList(),
      composer: AgentComposerData(
        text: r?.composer.text ?? '',
        attachments: [
          if (r != null)
            for (final a in r.composer.attachments)
              AgentAttachment(
                id: a.id,
                name: a.name,
                image: _resources.attachment(c.store, r.workspace, a),
                width: a.width,
                height: a.height,
                metadata: agentImageInfo(a.metadata),
              ),
        ],
        queue: [
          if (r != null)
            for (final q in r.composer.pending)
              AgentQueued(
                id: q['queueId'] as String,
                text: q['text'] as String? ?? '',
                kind: q['recovered'] == true
                    ? AgentQueueKind.recovered
                    : q['behavior'] == 'steer'
                    ? AgentQueueKind.steer
                    : AgentQueueKind.queued,
              ),
        ],
        pending: pending,
        blocked: blocked,
        canSend:
            blocked == null &&
            r != null &&
            (r.composer.text.trim().isNotEmpty ||
                r.composer.attachments.isNotEmpty),
        importing: r?.importingImages ?? 0,
        canAttachCanvas: _selectedImage()?.canDrag == true,
        enterSends: c.settings.enterToSend,
      ),
      thread: mapping?.turns ?? [],
      shelf: mapping?.shelf ?? const AgentShelfData(),
      memory: AgentMemoryData(
        globalInstructions: c.settings.globalInstructions,
        workspaceRules: r == null ? '' : _resources.rules(r.workspace),
        activeSkills: active.map((s) => s.name).toList(),
      ),
      usage: AgentUsageData(
        tokens: agentInt(r?.context['tokens']),
        window: r?.context['windowKnown'] == false
            ? null
            : agentInt(r?.context['contextWindow']),
        input: agentInt(tokenStats['input']),
        output: agentInt(tokenStats['output']),
        cacheRead: agentInt(tokenStats['cacheRead']),
        cacheWrite: agentInt(tokenStats['cacheWrite']),
        total: agentInt(tokenStats['total']),
        userMessages: agentInt(r?.stats['userMessages']),
        assistantMessages: agentInt(r?.stats['assistantMessages']),
        toolCalls: agentInt(r?.stats['toolCalls']),
      ),
      models: [
        for (final p in config.providers.where((p) => p.enabled))
          for (final m in config.models.where(
            (m) =>
                m.providerId == p.id &&
                !m.isPlaceholder &&
                m.supportsTools != false,
          ))
            AgentModelOption(
              providerId: p.id,
              modelId: m.name,
              label: m.displayName.isEmpty ? m.name : m.displayName,
              provider: p.name,
              selected:
                  c.settings.providerId == p.id && c.settings.modelId == m.name,
            ),
      ],
      thinking: AgentThinkingData(
        options: [for (final e in efforts) (e, reasoningEffortLabel(l, e))],
        selected: efforts.contains(c.settings.reasoningEffort)
            ? c.settings.reasoningEffort
            : model?.reasoningEffort,
        followsModel: !efforts.contains(c.settings.reasoningEffort),
      ),
      permission:
          AgentPermissionMode.values
              .where((m) => m.name == c.settings.permissionMode)
              .firstOrNull ??
          AgentPermissionMode.auto,
      mentions: mentions,
      skills: [
        for (final s in skillOptions)
          AgentSkillOption(name: s.name, description: s.displayDescription(l)),
      ],
      draft: draft,
      status: r?.starting == true
          ? AgentRunStatus.starting
          : pending.isNotEmpty
          ? AgentRunStatus.waitingUser
          : r?.waitingForSlot == true
          ? AgentRunStatus.waitingSlot
          : r?.running == true
          ? AgentRunStatus.working
          : AgentRunStatus.idle,
      error:
          r?.error ??
          (r?.composer.interrupted == true ? l.naiAgent_interrupted : null),
      notices: [
        if (r != null) ...[
          if (r.visionNotice != null) r.visionNotice!,
          ...r.extensionNotices,
          ...r.extensionStatus.values,
          ...r.extensionWidgets.values.expand((v) => v),
        ],
      ],
      initError: c.initializationError,
      loading: r == null,
      revision: _revision + (r?.uiRevision ?? 0),
    );
    final actions = AgentActions(
      onClose: () =>
          _background(ref.read(naiAgentWindowControllerProvider).close),
      onNewChat: () => _run(c.createChat),
      onSelectChat: (id) => _run(() => c.selectChat(id)),
      onRenameChat: (id, title) => _run(() => c.renameChat(id, title)),
      onSelectWorkspace: (id) => _run(() => c.selectWorkspace(id)),
      onCreateWorkspace: (name) => _run(() => c.createWorkspace(name)),
      onRenameWorkspace: (id, name) => _run(() => c.renameWorkspace(id, name)),
      onOpenWorkspaceFolder: () {
        if (r != null) {
          _background(() async {
            await launchUrl(Uri.directory(r.workspace.directory.path));
          });
        }
      },
      onCompact: () => _run(c.compact),
      onExport: _export,
      onOpenSettings: _settings,
      onComposerChanged: (text) => _background(() => c.saveComposer(text)),
      onSend: ({required steer}) => data.composer.canSend
          ? _run(() => c.send(steer: steer))
          : Future.value(false),
      onStop: () => _run(c.stop),
      onPickImages: _pick,
      onAttachCanvas: _attachCanvas,
      onAttachImage: _attachImage,
      onPaste: _paste,
      onRemoveAttachment: (id) => _run(() => c.removeAttachment(id)),
      onEditQueued: (id, text) => _run(() => c.editQueue(id, text: text)),
      onSteerQueued: (id) => _run(() => c.editQueue(id, steer: true)),
      onWithdrawQueued: (id) => _run(() => c.editQueue(id, remove: true)),
      onRestoreQueued: (id) => _run(() => c.restorePending(id)),
      onEditMessage: (id) => _run(() => c.editMessage(id)),
      onRegenerate: () async {
        final id = mapping?.turns.lastOrNull?.user.entryId;
        if (id == null || r?.running == true || r?.starting == true) {
          return false;
        }
        await c.editMessage(id);
        if (!identical(c.selected, r)) return false;
        await c.send();
        return true;
      },
      onAnswer: questions.answer,
      onCancelAsk: questions.cancel,
      onApprove: (id, option) {
        final q = r == null
            ? null
            : questions.forChat(r.chat.id).where((q) => q.id == id).firstOrNull;
        if (q != null && q.questions.isNotEmpty) {
          questions.answer(id, {q.questions.first.id: option});
        }
      },
      onCancelApproval: questions.cancel,
      onDecideGate: (id, {required confirm}) {
        if (r == null) return;
        if (generations.forChat(r.chat.id).any((g) => g.id == id)) {
          generations.decide(id, generate: confirm);
        } else if (imageApprovals.forChat(r.chat.id).any((g) => g.id == id)) {
          imageApprovals.decide(id, run: confirm);
        }
      },
      onUndoDiff: (id) async {
        final diff = mapping?.diffs[id];
        if (diff == null || r == null || _mapper.undone.contains(id)) {
          return false;
        }
        final ok = await ref
            .read(agentDiffUndoProvider)
            .restore(diff, r.workspace.agentDirectory);
        if (ok) {
          _mapper.undone.add(id);
          if (mounted) setState(() => _revision++);
        }
        return ok;
      },
      onRevealImage: (id) {
        final history = (mapping?.images[id] ?? _recentImages[id])?.historyId;
        if (history != null) {
          ref.read(generationPreviewSelectionProvider.notifier).select(history);
        }
      },
      onOpenFile: (id) {
        final path = mapping?.files[id];
        if (path != null) _openLink(path);
      },
      onOpenLink: _openLink,
      onSelectModel: (provider, model) => _run(
        () => c.updateSettings({'providerId': provider, 'modelId': model}),
      ),
      onOpenModelSettings: () => _settings(models: true),
      onThinking: (effort) => _run(
        () => c.setReasoningEffort(
          effort,
          providerId: c.settings.providerId,
          modelId: c.settings.modelId,
        ),
      ),
      onPermission: (mode) =>
          _run(() => c.updateSettings({'permissionMode': mode.name})),
      onRefreshUsage: () async {
        if (r != null) await c.refreshUsage(r);
      },
      onDismissNotices: () {
        if (r != null) c.dismissExtensionNotices(r);
      },
      onRetryInit: () => _background(() async {
        c.initializationError = null;
        try {
          await c.initialize();
        } catch (error) {
          c.initializationFailed(error);
        }
      }),
      onEditMemory: (target) => _settings(memory: target),
    );
    return AgentPanel(
      key: ValueKey(r?.chat.id),
      data: data,
      actions: actions,
      slots: AgentSlots(
        dropTarget: (_, hover, child) => r == null
            ? child
            : NaiAgentDropTarget(
                controller: c,
                runtime: r,
                onHighlight: hover,
                child: child,
              ),
        imageDrag: (_, image, child) {
          if (!ref.read(naiAgentNativeDragEnabledProvider)) return child;
          final provider = image.image;
          return provider is! MemoryImage
              ? child
              : DraggableMemoryImage(
                  imageBytes: provider.bytes,
                  imageId: image.historyId,
                  fileName: 'agent-image.png',
                  feedbackPixelWidth: image.width,
                  feedbackPixelHeight: image.height,
                  child: child,
                );
        },
      ),
    );
  }
}

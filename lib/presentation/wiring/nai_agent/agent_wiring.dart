import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:super_clipboard/super_clipboard.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/nai_agent/attachment_image.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/attachment_manifest.dart';

import '../../../data/services/nai_agent/agent_workspace_store.dart' as store;
import '../../../core/utils/file_name_sanitizer.dart';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/models/prompt_assistant_models.dart';
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
import '../../providers/nai_agent/nai_agent_quick_messages.dart';
import '../../providers/nai_agent/nai_agent_skills_provider.dart';
import '../../providers/nai_agent/nai_agent_commands_provider.dart';
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
import '../../widgets/common/precise_reference_type_dialog.dart';
import '../../widgets/drop/image_destination_dialog.dart';
import '../../widgets/drop/global_drop_handler.dart';
import '../../widgets/nai_agent/nai_agent_image_input.dart';
import '../blocks_preferences.dart';
import '../image_viewer_generation_target.dart';
import 'agent_context.dart';
import 'agent_diff_undo.dart';
import 'agent_settings_undo.dart';
import 'agent_gallery_undo.dart';
import 'agent_image_info.dart';
import 'agent_image_actions.dart';
import 'agent_quick.dart';
import 'agent_pending_mapper.dart';
import 'agent_resources.dart';
import 'agent_thread_mapper.dart';
import 'agent_history_mapper.dart';
import '../../../core/nai_agent/prompt_set_tools.dart';
import 'agent_prompt_set_actions.dart';
import 'agent_prompt_set_mapper.dart';

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
  final _promptImports = <String, AgentPromptSetImport>{};
  final _promptBusy = <String, int>{};
  final _promptTokens = <NaiAgentCancellation>{};
  String? _promptOwner;

  String _promptKey(AgentChatRuntime r, String id) =>
      '${r.workspace.id}/${r.chat.id}/$id';

  Future<bool> _promptAction(
    AgentChatRuntime r,
    String id,
    int index,
    AgentPromptSetAction action,
  ) async {
    final key = _promptKey(r, id);
    final service = ref.read(agentPromptSetActionsProvider);
    void toast(String text) {
      if (mounted) AppToast.info(context, text);
    }

    if (action == AgentPromptSetAction.undo) {
      final entry = _promptImports[key];
      if (entry == null) return false;
      final ok = await ref
          .read(agentDiffUndoProvider)
          .restoreAll(entry.restores, r.workspace.agentDirectory);
      if (ok) {
        _promptImports.remove(key);
        if (mounted) setState(() => _revision++);
      }
      return ok;
    }
    if (_promptBusy.containsKey(key)) return false;
    final set = await NaiAgentPromptSets(r.workspace.agentDirectory).read(id);
    if (!mounted ||
        !identical(controller.selected, r) ||
        set == null ||
        index >= (set['items'] as List).length) {
      return false;
    }
    if (_promptBusy.containsKey(key)) return false;
    switch (action) {
      case AgentPromptSetAction.import:
      case AgentPromptSetAction.generate:
        final token = NaiAgentCancellation();
        _promptTokens.add(token);
        setState(() => _promptBusy[key] = index);
        try {
          final imported = await service.importItem(
            r.workspace,
            set,
            index,
            toast,
            check: token.check,
          );
          if (imported == null) return false;
          _promptImports[key] = imported;
          if (mounted) setState(() => _revision++);
          if (action == AgentPromptSetAction.generate) {
            token.check();
            await ref.read(promptBlockLibraryNotifierProvider.future);
            final generation = ref.read(
              agentPromptSetGenerationProvider((
                r.workspace.directory.path,
                r.workspace.id,
                r.chat.id,
              )),
            );
            final response = await generation.requestUserGeneration(token);
            if (agentMap(response['details'])['status'] == 'cancelled' &&
                mounted) {
              toast(context.l10n.ag_cancel);
            }
            await recordAgentPromptSetImages(
              workspace: r.workspace,
              setId: id,
              index: index,
              result: agentMap(response['details']),
              check: token.check,
            );
            _resources.refreshPromptSets();
          }
          return true;
        } on NaiAgentToolError catch (error) {
          if (mounted) AppToast.error(context, error.message);
          return true; // Already presented the native generation error.
        } finally {
          _promptTokens.remove(token);
          _promptBusy.remove(key);
          if (mounted) setState(() => _revision++);
        }
      case AgentPromptSetAction.saveBlock:
        await service.saveBlock(set);
        if (!mounted) return true;
        toast(
          context.l10n.ag_psSavedBlock(
            set['title'] as String,
            (set['items'] as List).length,
          ),
        );
        return true;
      case AgentPromptSetAction.copyItem:
      case AgentPromptSetAction.copyAll:
        await service.copy(
          set,
          action == AgentPromptSetAction.copyItem ? index : null,
        );
        if (mounted) toast(context.l10n.ag_copied);
        return true;
      case AgentPromptSetAction.undo:
        return false;
    }
  }

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
    for (final token in _promptTokens) {
      token.cancel();
    }
    _resources.dispose();
    super.dispose();
  }

  NaiAgentWorkspaceController get controller =>
      ref.read(naiAgentControllerProvider);

  Future<bool> _run(Future<dynamic> Function() action) async {
    final result = await action();
    return result is bool ? result : true;
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
        final fileReaders = readers.where((r) => r.canProvide(Formats.fileUri));
        final paths = <String>{};
        for (final reader in fileReaders) {
          paths.add((await readAgentFileUri(reader)).toFilePath());
        }
        controller.checkImageImportTarget(target);
        final textPaths = paths
            .where((path) => !isAgentImagePath(path))
            .toList();
        // A file list may also advertise a synthesized bitmap. Import the files
        // only, just as a single reader prefers its URI over its bitmap.
        final report = await importAgentImageSources(controller, target, [
          if (paths.isNotEmpty)
            for (final path in paths.where(isAgentImagePath))
              () => readAgentImageFile(path)
          else
            for (final reader in readers.where(
              (reader) =>
                  agentImageReadFormats.any(reader.canProvide) ||
                  reader.rawReader != null,
            ))
              () => readAgentImage(reader, clipboard: true),
        ]);
        if (textPaths.isNotEmpty) {
          if (!mounted || !identical(controller.selected, target)) return null;
          presentAgentImageImport(context, report);
          return textPaths.join('\n');
        }
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
    if (image?.image is! MemoryImage &&
        image?.image is! FileImage &&
        _historyBytes(image?.historyId ?? id) == null) {
      return false;
    }
    return _import(target, [
      () async {
        final bytes = await agentImageBytes(
          image,
          historyBytes: _historyBytes,
          fallbackHistoryId: id,
        );
        return bytes == null
            ? null
            : DroppedFileData(fileName: 'agent-image.png', bytes: bytes);
      },
    ]);
  }

  Uint8List? _historyBytes(String id) {
    if (!ref.exists(imageGenerationNotifierProvider)) return null;
    final image = ref.read(imageGenerationNotifierProvider).findImageById(id);
    return image?.canDrag == true ? image!.bytes : null;
  }

  Future<bool> _imageAction(String id, AgentImageAction action) =>
      AgentImageActions(
        read: ref.read,
        alive: () => mounted,
        historyBytes: _historyBytes,
        capture: () => ref
            .read(imageViewerGenerationTargetProvider)
            .capture(alive: () => mounted),
        chooseReferenceType: () => PreciseReferenceTypeDialog.show(context),
        chooseImportSelection: (bytes, metadata, fileName) async {
          final result = await ImageDestinationDialog.show(
            context,
            imageBytes: bytes,
            fileName: fileName,
            metadata: metadata,
          );
          return result?.destination == ImageDestination.extractMetadata
              ? result?.selection
              : null;
        },
      ).perform(_mapping?.images[id] ?? _recentImages[id], action);

  Future<bool> _slashAction(String name) async {
    if (name == 'export') return _export();
    if (name == 'copy') {
      final runtime = ref.read(naiAgentControllerProvider).selected;
      final message = runtime?.messages
          .where((m) => m['role'] == 'assistant')
          .lastOrNull;
      if (message == null) return false;
      final text = agentMaps(message['content'])
          .where((p) => p['type'] == 'text')
          .map((p) => p['text'] as String)
          .join('');
      if (text.isEmpty) return false;
      await Clipboard.setData(ClipboardData(text: text));
      return true;
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

  void _settings({
    bool models = false,
    AgentMemoryTarget? memory,
    String? anchor,
  }) {
    anchor ??= switch (memory) {
      AgentMemoryTarget.global => 'agentInstructions',
      AgentMemoryTarget.workspace => 'agentWorkspaceRules',
      AgentMemoryTarget.skills => 'agentSkills',
      AgentMemoryTarget.quick => 'agentQuick',
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
    final ownerKey = r == null ? null : '${r.workspace.id}/${r.chat.id}';
    if (_promptOwner != ownerKey) {
      for (final token in _promptTokens) {
        token.cancel();
      }
      _promptOwner = ownerKey;
    }
    int? promptPrice;
    if (r != null && ref.exists(generationParamsNotifierProvider)) {
      final generation = ref.watch(
        agentPromptSetGenerationProvider((
          r.workspace.directory.path,
          r.workspace.id,
          r.chat.id,
        )),
      );
      try {
        promptPrice = generation.readInput({
          'requests': 1,
          'images_per_request': 1,
        }).estimate;
      } catch (_) {
        /* Unknown quote: no price pill. */
      }
    }
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
    final localCommand = NaiAgentWorkspaceController.isBuiltinSlashCommand(
      r?.composer.text ?? '',
    );
    final blocked = model == null && !localCommand
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
    _resources.galleryLoader = r == null
        ? null
        : (id) async =>
              (await ref
                      .read(
                        agentGalleryBindingProvider((
                          r.workspace.directory.path,
                          r.workspace.id,
                          r.chat.id,
                        )),
                      )
                      .loadImage(id, NaiAgentCancellation()))
                  ?.bytes;
    final mapping = r == null
        ? null
        : _mapper.map(
            r,
            draftVersion: version,
            waitingUser: pending.isNotEmpty,
            preferences: ref.watch(agentPreferencesProvider),
            promptSetView: (value, images) {
              final id = value['set_id'] as String;
              final imported = _promptImports[_promptKey(r, id)];
              return agentPromptSetData(
                value,
                r.workspace,
                _resources,
                images,
                unitAnlas: promptPrice,
                aspect:
                    draft?.width != null &&
                        draft?.height != null &&
                        draft!.height! > 0
                    ? draft.width! / draft.height!
                    : null,
                importedIndex: imported?.index,
                canUndoImport: imported != null && imported.version == version,
                busyIndex: _promptBusy[_promptKey(r, id)],
              );
            },
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
            path: image.filePath == null || image.filePath!.isEmpty
                ? null
                : p.normalize(p.absolute(image.filePath!)),
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
    final templates = r == null
        ? <Map<String, dynamic>>[]
        : r.client != null
        ? r.commands
        : ref.watch(naiAgentCommandsProvider(r.workspace.id)).valueOrNull ?? [];
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
        title: chat.title.trim().isEmpty ? c.initialChatName : chat.title,
        createdAt: chat.createdAt.toLocal(),
        lastActivityAt: chat.lastActivityAt?.toLocal(),
        canExport: !chat.isDraft && chat.sessionFile != null,
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
      localAction: AgentLocalAction.values
          .where((a) => a.name == r?.localAction)
          .firstOrNull,
      localActionRevision: r?.localActionRevision ?? 0,
      composer: AgentComposerData(
        suggestion: r?.composer.text.isEmpty == true ? r?.suggestion : null,
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
        importing: r?.pendingImageCount ?? 0,
        canAttachCanvas: _selectedImage()?.canDrag == true,
        enterSends: c.settings.enterToSend,
      ),
      thread: mapping?.turns ?? [],
      history: agentHistoryEntries(mapping?.turns ?? []),
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
        anlas: mapping?.estimatedAnlas,
        cacheWarming: AgentCacheWarmingData.fromJson(r?.cacheWarming ?? {}),
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
              logoAsset: providerUsesMark(p) ? null : p.preset?.logoAsset,
              mark: providerUsesMark(p)
                  ? p.name.characters.take(2).toString().toUpperCase()
                  : null,
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
      bypassWarned: c.settings.bypassWarned,
      mentions: mentions,
      skills: [
        for (final s in skillOptions)
          AgentSkillOption(name: s.name, description: s.displayDescription(l)),
      ],
      slashCommands: [
        for (final s in skillOptions)
          AgentSlashCommand(
            kind: AgentSlashCommandKind.skill,
            name: s.name,
            description: s.displayDescription(l),
          ),
        for (final t in templates)
          AgentSlashCommand(
            kind: AgentSlashCommandKind.template,
            name: t['name'] as String,
            description: t['description'] as String,
            argumentHint: t['argumentHint'] as String?,
            source: t['source'] as String?,
          ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'new',
          description: l.ag_commandNew,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'compact',
          description: l.ag_commandCompact,
          argumentHint: l.ag_commandCompactArgs,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'model',
          description: l.ag_commandModel,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'thinking',
          description: l.ag_commandThinking,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'history',
          description: l.ag_commandHistory,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'rename',
          description: l.ag_commandRename,
          argumentHint: l.ag_commandRenameArgs,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'copy',
          description: l.ag_commandCopy,
        ),
        AgentSlashCommand(
          kind: AgentSlashCommandKind.builtin,
          name: 'export',
          description: l.ag_commandExport,
        ),
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
      runLimit: r?.runLimitHit,
      error: r?.runLimitHit != null
          ? null
          : r?.error ??
                (r?.composer.interrupted == true
                    ? l.naiAgent_interrupted
                    : null),
      notices: [
        if (r != null) ...[
          if (r.visionNotice != null) r.visionNotice!,
          ...r.extensionNotices,
          ...r.extensionStatus.values,
          ...r.extensionWidgets.values.expand((v) => v),
        ],
      ],
      initError: c.initializationError,
      loading: r == null && !c.initialized,
      revision: _revision + (r?.uiRevision ?? 0),
      quick: agentQuickItems(
        context.l10n,
        ref.watch(naiAgentQuickMessagesProvider).items,
      ),
    );
    final actions = AgentActions(
      onPromptSetAction: (id, index, action) async =>
          r != null && await _promptAction(r, id, index, action),
      onClose: () =>
          _background(ref.read(naiAgentWindowControllerProvider).close),
      onNewChat: () => _run(c.createChat),
      onSelectChat: (id) => _run(() => c.selectChat(id)),
      onRenameChat: (id, title) => _run(() => c.renameChat(id, title)),
      onDeleteChat: (id) async {
        try {
          return 'chat:${await c.deleteChat(id)}';
        } catch (_) {
          return null;
        }
      },
      onDeleteWorkspace: (id) async {
        try {
          return 'workspace:${await c.deleteWorkspace(id)}';
        } catch (_) {
          return null;
        }
      },
      onUndoDelete: (token) async {
        final separator = token.indexOf(':');
        if (separator <= 0 || separator == token.length - 1) return false;
        final id = token.substring(separator + 1);
        try {
          switch (token.substring(0, separator)) {
            case 'chat':
              await c.undoDeleteChat(id);
            case 'workspace':
              await c.undoDeleteWorkspace(id);
            default:
              return false;
          }
          return true;
        } catch (_) {
          return false;
        }
      },
      onSearchChats: (query) async {
        try {
          return [
            for (final hit in await c.searchChats(query))
              AgentChatHit(
                chatId: hit.chatId,
                title: hit.title.trim().isNotEmpty
                    ? hit.title
                    : c.chats
                              .where((chat) => chat.id == hit.chatId)
                              .map(chatInfo)
                              .firstOrNull
                              ?.title ??
                          c.initialChatName,
                snippet: hit.snippet,
              ),
          ];
        } catch (_) {
          return const <AgentChatHit>[];
        }
      },
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
      onCompact: () => _run(() => c.compact()),
      onExport: _export,
      onOpenSettings: _settings,
      onOpenSettingAt: (section, anchor) => context.go(
        Uri(
          path: AppRoutes.settings,
          queryParameters: {'section': section, 'anchor': anchor},
        ).toString(),
      ),
      onSelectSlashCommand: (command) async {
        if (command.executesOnSelect) {
          return _run(
            () => c.sendSlashCommand(
              '/${command.name}',
              clearComposer: true,
              onAction: _slashAction,
            ),
          );
        }
        return _run(() => c.saveComposer(command.insertion));
      },
      onAcceptSuggestion: () => _run(c.acceptSuggestion),
      onComposerChanged: (text) => _background(() => c.saveComposer(text)),
      onSend: ({required steer}) async {
        if (!data.composer.canSend) return false;
        final text = c.selected?.composer.text ?? '';
        if (NaiAgentWorkspaceController.isBuiltinSlashCommand(text)) {
          return await c.sendSlashCommand(text, onAction: _slashAction) ??
              false;
        }
        return _run(() => c.send(steer: steer));
      },
      onContinue: () async {
        try {
          return await c.sendText(context.l10n.ag_continueMessage);
        } catch (_) {
          return false;
        }
      },
      onAdjustLimit: () => _settings(anchor: 'agentMaxRequests'),
      onStop: () => _run(c.stop),
      onPickImages: _pick,
      onAttachCanvas: _attachCanvas,
      onAttachImage: _attachImage,
      onImageAction: _imageAction,
      onPaste: _paste,
      onRemoveAttachment: (id) => _run(() => c.removeAttachment(id)),
      onEditQueued: (id, text) => _run(() => c.editQueue(id, text: text)),
      onSteerQueued: (id) => _run(() => c.editQueue(id, steer: true)),
      onWithdrawQueued: (id) => _run(() => c.editQueue(id, remove: true)),
      onRestoreQueued: (id) => _run(() => c.restorePending(id)),
      onResendFrom: (entryId, text, keep) async {
        if (r == null ||
            !identical(c.selected, r) ||
            r.running ||
            r.starting ||
            r.pendingSends > 0) {
          return false;
        }
        final indexes = agentUserImagePartIndexes(r, entryId, keep);
        if (indexes == null) return false;
        return _run(
          () => c.resendFrom(entryId, text, keepImagePartIndexes: indexes),
        );
      },
      onRegenerate: () async {
        final user = mapping?.turns.lastOrNull?.user;
        final id = user?.entryId;
        if (id == null ||
            r == null ||
            !identical(c.selected, r) ||
            r.running ||
            r.starting ||
            r.pendingSends > 0) {
          return false;
        }
        final message = r.userMessageForEntry(id);
        if (message == null) return false;
        return _run(
          () => c.resendFrom(
            id,
            stripAgentAttachmentManifest(agentMessageText(message)),
            keepImagePartIndexes: [
              for (final (pi, part) in agentMaps(message['content']).indexed)
                if (part['type'] == 'image') pi,
            ],
          ),
        );
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
        if (r == null || _mapper.undone.contains(id)) return false;
        final settings = mapping?.settings[id];
        final gallery = mapping?.gallery[id];
        final diff = mapping?.diffs[id];
        final ok = settings != null
            ? await ref
                  .read(agentSettingsUndoProvider(r.workspace.directory.path))
                  .restore(settings)
            : gallery != null
            ? await AgentGalleryUndo(
                ref.read(
                  agentGalleryBindingProvider((
                    r.workspace.directory.path,
                    r.workspace.id,
                    r.chat.id,
                  )),
                ),
              ).restore(gallery)
            : diff != null &&
                  await ref
                      .read(agentDiffUndoProvider)
                      .restore(diff, r.workspace.agentDirectory);
        if (ok) {
          _mapper.undone.add(id);
          if (mounted) setState(() => _revision++);
        }
        return ok;
      },
      onUndoDiffs: (ids) async {
        // Group undo is atomic only within one draft version. Settings/gallery
        // cards each own one restore; do not silently ignore foreign ids.
        final active = ids
            .where((id) => !_mapper.undone.contains(id))
            .toSet()
            .toList();
        if (active.length == 1 && r != null) {
          final id = active.single;
          final settings = mapping?.settings[id];
          final gallery = mapping?.gallery[id];
          if (settings != null || gallery != null) {
            final ok = settings != null
                ? await ref
                      .read(
                        agentSettingsUndoProvider(r.workspace.directory.path),
                      )
                      .restore(settings)
                : await AgentGalleryUndo(
                    ref.read(
                      agentGalleryBindingProvider((
                        r.workspace.directory.path,
                        r.workspace.id,
                        r.chat.id,
                      )),
                    ),
                  ).restore(gallery!);
            if (ok) {
              _mapper.undone.add(id);
              if (mounted) setState(() => _revision++);
            }
            return ok;
          }
        }
        if (active.any((id) => mapping?.diffs[id] == null)) return false;
        final list = [
          for (final id in ids)
            if (!_mapper.undone.contains(id)) ?mapping?.diffs[id],
        ];
        if (list.isEmpty || r == null) return false;
        final ok = await ref
            .read(agentDiffUndoProvider)
            .restoreAll(list, r.workspace.agentDirectory);
        if (ok) {
          _mapper.undone.addAll(list.map((d) => d.id));
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
      onSilenceBypass: () async {
        try {
          await c.updateSettings({'bypassWarned': true});
          return true;
        } catch (_) {
          return false;
        }
      },
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
    return MetaData(
      metaData: GlobalDropHandler.excludedRegion,
      behavior: HitTestBehavior.opaque,
      child: AgentPanel(
        // Deleting the selected chat changes chats without closing the picker.
        key: ValueKey(data.workspace.id),
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
      ),
    );
  }
}

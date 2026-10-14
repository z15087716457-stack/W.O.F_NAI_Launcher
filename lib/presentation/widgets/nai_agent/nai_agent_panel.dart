import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/file_name_sanitizer.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import 'nai_agent_generation_card.dart';
import 'nai_agent_image_approval_card.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../router/app_router.dart';
import '../navigation/window_chrome_layout.dart';
import '../common/themed_divider.dart';
import 'nai_agent_composer.dart';
import 'nai_agent_shared.dart';
import 'nai_agent_image_input.dart';
import 'nai_agent_image_artifact.dart';
import '../../utils/nai_agent_file_link.dart';

class NaiAgentToggleButton extends ConsumerWidget {
  const NaiAgentToggleButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(
      naiAgentUiPreferencesProvider.select((c) => c.settings.panelExpanded),
    );
    return IconButton(
      key: const Key('nai-agent-toggle'),
      tooltip: context.l10n.naiAgent_title,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      padding: EdgeInsets.zero,
      iconSize: 17,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: expanded
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
      icon: const Icon(Icons.auto_awesome_outlined),
      onPressed: () => agentUiAction(
        context,
        ref.read(naiAgentWindowControllerProvider).toggle,
      ),
    );
  }
}

class NaiAgentPanel extends ConsumerStatefulWidget {
  const NaiAgentPanel({super.key});
  @override
  ConsumerState<NaiAgentPanel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<NaiAgentPanel> {
  final _scroll = ScrollController();
  String? _chatId;
  bool _follow = true, _unread = false;
  int _lastRevision = 0, _tipIndex = 0;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      _follow = _scroll.position.maxScrollExtent - _scroll.offset < 70;
      if (_follow && _unread && mounted) setState(() => _unread = false);
    });
    final c = ref.read(naiAgentControllerProvider);
    unawaited(
      c.ready.then((_) {
        if (mounted) return c.loadHistory();
      }),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _bottom() {
    _follow = true;
    if (_scroll.hasClients) {
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        ),
      );
    }
    setState(() => _unread = false);
  }

  Future<String?> _name(String title, String value) async {
    final input = TextEditingController(text: value);
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: input,
            autofocus: true,
            maxLength: 80,
            decoration: InputDecoration(labelText: context.l10n.naiAgent_name),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) Navigator.pop(context, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.naiAgent_cancel),
            ),
            FilledButton(
              onPressed: () {
                if (input.text.trim().isNotEmpty) {
                  Navigator.pop(context, input.text.trim());
                }
              },
              child: Text(context.l10n.naiAgent_save),
            ),
          ],
        ),
      );
    } finally {
      input.dispose();
    }
  }

  Future<void> _editPending(
    NaiAgentWorkspaceController c,
    Map<String, dynamic> item,
  ) async {
    final input = TextEditingController(text: item['text'] as String? ?? '');
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.naiAgent_editMessage),
          content: SizedBox(
            width: 460,
            child: TextField(
              controller: input,
              minLines: 2,
              maxLines: 8,
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.naiAgent_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, input.text),
              child: Text(context.l10n.naiAgent_save),
            ),
          ],
        ),
      );
      if (result != null) {
        await c.editQueue(item['queueId'] as String, text: result);
      }
    } finally {
      input.dispose();
    }
  }

  Future<void> _export(NaiAgentWorkspaceController c) async {
    final runtime = c.selected!;
    final bytes = await c.exportSession(runtime);
    if (!mounted) return;
    final target = await FilePicker.platform.saveFile(
      dialogTitle: context.l10n.naiAgent_export,
      fileName:
          '${FileNameSanitizer.sanitize(runtime.chat.title, maxLength: 80)}.jsonl',
      type: FileType.custom,
      allowedExtensions: const ['jsonl'],
    );
    if (target != null) await File(target).writeAsBytes(bytes, flush: true);
  }

  Widget _header(NaiAgentWorkspaceController c) {
    final l = context.l10n;
    Widget button(
      IconData icon,
      String tooltip,
      VoidCallback? onPressed, {
      Key? key,
    }) => SizedBox(
      width: 25,
      height: 25,
      child: IconButton(
        key: key,
        tooltip: tooltip,
        icon: Icon(icon, size: 15),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
    return SizedBox(
      key: const Key('nai-agent-header'),
      height: 39,
      child: WindowPanelHeader(
        headerHeight: 39,
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 9),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 260;
              final tiny = constraints.maxWidth < 120;
              return Row(
                children: [
                  if (!tiny) ...[
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                  ],
                  Expanded(
                    child: Tooltip(
                      message: l.naiAgent_title,
                      child: Text(
                        l.naiAgent_title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  _chats(c, compact: compact),
                  if (!compact) ...[
                    button(
                      Icons.edit_square,
                      l.naiAgent_newChat,
                      c.initialized
                          ? () => agentUiAction(context, c.createChat)
                          : null,
                    ),
                    button(
                      Icons.tune,
                      l.naiAgent_settings,
                      () => context.go('${AppRoutes.settings}?section=agent'),
                    ),
                  ],
                  button(
                    Icons.close,
                    l.naiAgent_close,
                    () => agentUiAction(
                      context,
                      ref.read(naiAgentWindowControllerProvider).close,
                    ),
                    key: const Key('nai-agent-close'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _chats(NaiAgentWorkspaceController c, {required bool compact}) {
    final l = context.l10n;
    return SizedBox(
      width: 25,
      height: 25,
      child: PopupMenuButton<String>(
        tooltip: l.naiAgent_showChats,
        padding: EdgeInsets.zero,
        icon: Icon(compact ? Icons.more_horiz : Icons.history, size: 15),
        onSelected: (id) => agentUiAction(context, () async {
          if (id == '__new__') {
            await c.createChat();
          } else if (id == '__settings__') {
            context.go('${AppRoutes.settings}?section=agent');
          } else if (id == '__rename__') {
            final chat = c.selected!.chat;
            final name = await _name(l.naiAgent_rename, chat.title);
            if (name != null) await c.renameChat(chat.id, name);
          } else if (id == '__compact__') {
            await c.compact();
          } else if (id == '__export__') {
            await _export(c);
          } else {
            await c.selectChat(id);
          }
        }),
        itemBuilder: (_) => [
          if (compact) ...[
            PopupMenuItem(
              value: '__new__',
              enabled: c.initialized,
              child: Text(l.naiAgent_newChat),
            ),
            PopupMenuItem(
              value: '__settings__',
              child: Text(l.naiAgent_settings),
            ),
            const PopupMenuDivider(),
          ],
          for (final chat in c.chats)
            PopupMenuItem(
              value: chat.id,
              child: Row(
                children: [
                  Icon(
                    c.selected?.chat.id == chat.id
                        ? Icons.check
                        : Icons.chat_bubble_outline,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(chat.title, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem(value: '__rename__', child: Text(l.naiAgent_rename)),
          PopupMenuItem(
            value: '__compact__',
            enabled:
                c.selected?.running == false && c.selected?.starting == false,
            child: Text(l.naiAgent_compact),
          ),
          PopupMenuItem(
            value: '__export__',
            enabled:
                c.selected?.running == false &&
                c.selected?.chat.sessionFile != null,
            child: Text(l.naiAgent_export),
          ),
        ],
      ),
    );
  }

  Widget _pending(NaiAgentWorkspaceController c, AgentChatRuntime r) {
    final l = context.l10n, scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
        children: [
          for (final item in r.composer.pending)
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.fromLTRB(9, 4, 4, 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    item['recovered'] == true
                        ? Icons.restore
                        : item['behavior'] == 'steer'
                        ? Icons.low_priority
                        : Icons.schedule,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (item['text'] as String?)?.isNotEmpty == true
                          ? item['text'] as String
                          : l.naiAgent_emptyAttachment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (item['recovered'] == true)
                    TextButton(
                      onPressed: () => agentUiAction(
                        context,
                        () => c.restorePending(item['queueId'] as String),
                      ),
                      child: Text(
                        l.naiAgent_restorePending,
                        style: const TextStyle(fontSize: 11),
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, size: 16),
                      onSelected: (value) => agentUiAction(context, () async {
                        if (value == 'edit') {
                          await _editPending(c, item);
                        } else if (value == 'restore') {
                          await c.restorePending(item['queueId'] as String);
                        } else {
                          await c.editQueue(
                            item['queueId'] as String,
                            remove: value == 'remove',
                            steer: value == 'steer',
                          );
                        }
                      }),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l.naiAgent_editMessage),
                        ),
                        PopupMenuItem(
                          value: 'steer',
                          child: Text(l.naiAgent_promote),
                        ),
                        PopupMenuItem(
                          value: 'restore',
                          child: Text(l.naiAgent_restorePending),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(l.naiAgent_withdraw),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _welcome(NaiAgentWorkspaceController c, {required bool compact}) {
    final l = context.l10n, theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final faint = muted.withValues(alpha: .65);
    final tips = [
      l.naiAgent_tipReadOnly,
      l.naiAgent_tipAttachments,
      l.naiAgent_tipGeneration,
    ];
    final suggestions = [
      (Icons.tune, l.naiAgent_suggestCurrent, l.naiAgent_promptCurrent),
      (Icons.image_outlined, l.naiAgent_suggestImage, l.naiAgent_promptImage),
      (
        Icons.folder_outlined,
        l.naiAgent_suggestWorkspace,
        l.naiAgent_promptWorkspace,
      ),
    ];
    return ConstrainedBox(
      key: const Key('nai-agent-brand-welcome'),
      constraints: const BoxConstraints(maxWidth: 288),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: theme.brightness == Brightness.dark ? .8 : .7,
            child: SvgPicture.asset(
              'assets/images/wof_nai_lab.svg',
              key: const Key('nai-agent-brand-logo'),
              width: compact ? 118 : 150,
              semanticsLabel: 'W.O.F NAI LAB',
              colorFilter: theme.brightness == Brightness.dark
                  ? const ColorFilter.matrix([
                      -1,
                      0,
                      0,
                      0,
                      255,
                      0,
                      -1,
                      0,
                      0,
                      255,
                      0,
                      0,
                      -1,
                      0,
                      255,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ])
                  : null,
            ),
          ),
          SizedBox(height: compact ? 10 : 15),
          Text(
            l.naiAgent_brandEyebrow,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, letterSpacing: 1.7, color: faint),
          ),
          SizedBox(height: compact ? 10 : 15),
          Text(
            l.naiAgent_welcome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l.naiAgent_welcomeHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.85, color: muted),
          ),
          SizedBox(height: compact ? 15 : 23),
          for (var i = 0; i < suggestions.length; i++) ...[
            if (i > 0) const SizedBox(height: 7),
            OutlinedButton(
              key: Key('nai-agent-suggestion-$i'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                foregroundColor: muted,
              ),
              onPressed: () => agentUiAction(
                context,
                () => c.saveComposer(suggestions[i].$3),
              ),
              child: Row(
                children: [
                  Icon(suggestions[i].$1, size: 14, color: faint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestions[i].$2,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Icon(Icons.north_east, size: 13, color: faint),
                ],
              ),
            ),
          ],
          SizedBox(height: compact ? 16 : 24),
          const ThemedDivider(height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.naiAgent_tipTitle,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: faint,
                  ),
                ),
              ),
              Text(
                '${_tipIndex + 1} / ${tips.length}',
                style: TextStyle(fontSize: 10, color: faint),
              ),
              const SizedBox(width: 7),
              IconButton(
                key: const Key('nai-agent-tip-next'),
                tooltip: l.naiAgent_tipNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 22,
                  height: 22,
                ),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.chevron_right, size: 12, color: faint),
                onPressed: () =>
                    setState(() => _tipIndex = (_tipIndex + 1) % tips.length),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                tips[_tipIndex],
                key: const Key('nai-agent-tip-copy'),
                style: TextStyle(fontSize: 11, height: 1.8, color: muted),
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 18),
          Text(
            l.naiAgent_welcomeFootnote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: faint),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(naiAgentControllerProvider), r = c.selected;
    final l = context.l10n, scheme = Theme.of(context).colorScheme;
    final questions = r == null
        ? <AgentQuestionRequest>[]
        : ref.watch(naiAgentQuestionsProvider).forChat(r.chat.id);
    final approvals = r == null
        ? <AgentGenerationApproval>[]
        : ref.watch(naiAgentGenerationApprovalsProvider).forChat(r.chat.id);
    final imageApprovals = r == null
        ? <AgentImageApproval>[]
        : ref.watch(naiAgentImageApprovalsProvider).forChat(r.chat.id);
    if (_chatId != r?.chat.id) {
      _chatId = r?.chat.id;
      _follow = true;
      _unread = false;
      _lastRevision = 0;
    }
    final revision = Object.hash(
      r?.uiRevision,
      questions.length,
      approvals.length,
      imageApprovals.length,
    );
    if (revision != _lastRevision) {
      _lastRevision = revision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_follow && _scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        } else if (!_unread && r?.messages.isNotEmpty == true) {
          setState(() => _unread = true);
        }
      });
    }
    final visible =
        r?.messages
            .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
            .toList() ??
        [];
    final panel = Material(
      color: scheme.surface,
      child: WindowPaneInset(
        enabled: false,
        child: Column(
          children: [
            _header(c),
            const ThemedDivider(height: 1),
            if (c.initializationError != null)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(c.initializationError!),
              ),
            if (r != null) ...[
              Expanded(
                child: Stack(
                  children: [
                    if (visible.isEmpty &&
                        questions.isEmpty &&
                        approvals.isEmpty &&
                        imageApprovals.isEmpty)
                      LayoutBuilder(
                        key: const Key('nai-agent-empty-region'),
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              primary: false,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: constraints.maxHeight < 500
                                        ? 12
                                        : 20,
                                  ),
                                  child: Center(
                                    child: _welcome(
                                      c,
                                      compact: constraints.maxHeight < 500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      )
                    else
                      ListView.builder(
                        key: ValueKey(r.chat.id),
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                        itemCount:
                            visible.length +
                            questions.length +
                            approvals.length +
                            imageApprovals.length,
                        itemBuilder: (context, index) => index < visible.length
                            ? _AgentMessage(
                                key: ValueKey(
                                  '${visible[index]['role']}-${visible[index]['timestamp']}-$index',
                                ),
                                message: visible[index],
                                runtime: r,
                                controller: c,
                              )
                            : index < visible.length + questions.length
                            ? NaiAgentQuestionCard(
                                key: ValueKey(
                                  questions[index - visible.length].id,
                                ),
                                request: questions[index - visible.length],
                              )
                            : index <
                                  visible.length +
                                      questions.length +
                                      approvals.length
                            ? NaiAgentGenerationCard(
                                key: ValueKey(
                                  approvals[index -
                                          visible.length -
                                          questions.length]
                                      .id,
                                ),
                                request:
                                    approvals[index -
                                        visible.length -
                                        questions.length],
                              )
                            : NaiAgentImageApprovalCard(
                                request:
                                    imageApprovals[index -
                                        visible.length -
                                        questions.length -
                                        approvals.length],
                              ),
                      ),
                    if (_unread)
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: FilledButton.tonalIcon(
                          onPressed: _bottom,
                          icon: const Icon(Icons.arrow_downward, size: 14),
                          label: Text(
                            l.naiAgent_newContent,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (r.extensionNotices.isNotEmpty ||
                  r.extensionStatus.isNotEmpty ||
                  r.extensionWidgets.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              [
                                ...r.extensionNotices,
                                ...r.extensionStatus.values,
                                ...r.extensionWidgets.values.expand(
                                  (lines) => lines,
                                ),
                              ].join('\n'),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (r.extensionNotices.isNotEmpty)
                            IconButton(
                              tooltip: l.naiAgent_cancel,
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => c.dismissExtensionNotices(r),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (r.error != null || r.composer.interrupted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
                  child: Text(
                    r.error ?? l.naiAgent_interrupted,
                    style: TextStyle(fontSize: 12, color: scheme.error),
                  ),
                ),
              if (r.running || r.starting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.starting
                              ? l.naiAgent_starting
                              : approvals.isNotEmpty
                              ? l.naiAgent_generationWaiting
                              : questions.isNotEmpty
                              ? l.naiAgent_waiting
                              : r.waitingForSlot
                              ? l.naiAgent_waitingSlot
                              : l.naiAgent_working,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (r.composer.pending.isNotEmpty) _pending(c, r),
              NaiAgentComposer(
                key: ValueKey('composer-${r.chat.id}'),
                controller: c,
                runtime: r,
              ),
            ] else
              const Expanded(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        ),
      ),
    );
    return r == null
        ? panel
        : NaiAgentDropTarget(controller: c, runtime: r, child: panel);
  }
}

String agentMessageText(Map<String, dynamic> message) {
  final content = message['content'];
  if (content is String) return content;
  return [
    for (final part in content as List? ?? [])
      if (part is Map && part['type'] == 'text') part['text'] ?? '',
  ].join('\n\n');
}

class _AgentMessage extends StatelessWidget {
  const _AgentMessage({
    super.key,
    required this.message,
    required this.runtime,
    required this.controller,
  });
  final Map<String, dynamic> message;
  final AgentChatRuntime runtime;
  final NaiAgentWorkspaceController controller;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n, scheme = Theme.of(context).colorScheme;
    final user = message['role'] == 'user', text = agentMessageText(message);
    final parts = message['content'] is List ? message['content'] as List : [];
    final entry = runtime.entries
        .where(
          (e) => e['role'] == 'user' && e['timestamp'] == message['timestamp'],
        )
        .firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(user ? 12 : 0),
            decoration: user
                ? BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (text.isNotEmpty)
                  MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: TextStyle(
                            fontSize: 13.5,
                            height: 1.65,
                            color: scheme.onSurface,
                          ),
                          code: TextStyle(
                            fontFamily: 'Geist Mono',
                            fontSize: 12,
                            color: scheme.onSurface,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    imageBuilder: (uri, title, alt) => Tooltip(
                      message: uri.toString(),
                      child: const Icon(Icons.image_outlined),
                    ),
                    onTapLink: (_, href, __) async {
                      final uri = Uri.tryParse(href ?? '');
                      if (uri == null) return;
                      if (['https', 'http'].contains(uri.scheme)) {
                        await launchUrl(uri);
                      } else {
                        final local = await resolveAgentFileLink(
                          runtime.workspace.directory,
                          uri,
                        );
                        if (local != null) await launchUrl(local);
                      }
                    },
                  ),
                if (parts.any((p) => p is Map && p['type'] == 'image'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final part in parts)
                          if (part is Map && part['type'] == 'image')
                            _MessageImage(data: part['data'] as String),
                      ],
                    ),
                  ),
                for (final part in parts)
                  if (part is Map && part['type'] == 'toolCall')
                    _ToolCard(
                      workspace: runtime.workspace.directory,
                      name: part['name'] as String,
                      args: part['arguments'],
                      event: runtime.tools[part['id']] ?? {},
                      result: runtime.messages
                          .where(
                            (m) =>
                                m['role'] == 'toolResult' &&
                                m['toolCallId'] == part['id'],
                          )
                          .firstOrNull,
                    ),
              ],
            ),
          ),
          if (text.isNotEmpty)
            Row(
              mainAxisAlignment: user
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: l.naiAgent_copyMessage,
                  icon: const Icon(Icons.copy_outlined, size: 14),
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => Clipboard.setData(ClipboardData(text: text)),
                ),
                if (!runtime.running && entry != null)
                  IconButton(
                    tooltip: l.naiAgent_editMessage,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => agentUiAction(
                      context,
                      () => controller.editMessage(entry['id'] as String),
                    ),
                  ),
                if (!user && !runtime.running && runtime.userEntries.isNotEmpty)
                  IconButton(
                    tooltip: l.naiAgent_regenerate,
                    icon: const Icon(Icons.refresh, size: 15),
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => agentUiAction(context, () async {
                      // Pi navigation branches at the selected user message; tools run normally.
                      final userEntry = runtime.entries
                          .where(
                            (e) =>
                                e['role'] == 'user' &&
                                (e['timestamp'] as num? ?? 0) <=
                                    (message['timestamp'] as num? ?? 0),
                          )
                          .lastOrNull;
                      if (userEntry != null) {
                        await controller.editMessage(userEntry['id'] as String);
                        await controller.send();
                      }
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MessageImage extends StatefulWidget {
  const _MessageImage({required this.data});
  final String data;
  @override
  State<_MessageImage> createState() => _MessageImageState();
}

class _MessageImageState extends State<_MessageImage> {
  late final Uint8List? bytes = _decode();
  Uint8List? _decode() {
    try {
      return base64Decode(widget.data);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    if (data == null) return const Icon(Icons.broken_image_outlined);
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: Stack(
            children: [
              InteractiveViewer(child: Image.memory(data, fit: BoxFit.contain)),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          data,
          width: 100,
          height: 96,
          fit: BoxFit.cover,
          cacheWidth: 200,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.name,
    required this.args,
    required this.event,
    required this.result,
    required this.workspace,
  });
  final String name;
  final Object? args;
  final Map<String, dynamic> event;
  final Map<String, dynamic>? result;
  final Directory workspace;
  Object? _display(Object? value) {
    if (value is Map) {
      if (value['type'] == 'image' && value['data'] is String) {
        return {
          'type': 'image',
          'mimeType': value['mimeType'],
          'bytes': ((value['data'] as String).length * 3 / 4).round(),
        };
      }
      return {
        for (final entry in value.entries) entry.key: _display(entry.value),
      };
    }
    if (value is List) return value.map(_display).toList();
    return value;
  }

  String _text(Object? value) {
    final text = const JsonEncoder.withIndent('  ').convert(_display(value));
    return text.length > 24000 ? '${text.substring(0, 24000)}…' : text;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, scheme = Theme.of(context).colorScheme;
    final done = event['type'] == 'tool_execution_end' || result != null;
    final value = result ?? event['result'];
    final mcp = name.startsWith('mcp__nai_studio__') && value is Map
        ? value['structuredContent']
        : null;
    final details = mcp is Map
        ? mcp['structuredContent']
        : value is Map
        ? value['details']
        : null;
    final artifacts = details is Map && details['artifacts'] is List
        ? details['artifacts'] as List
        : const [];
    final failed =
        event['isError'] == true ||
        result?['isError'] == true ||
        (details is Map && details['ok'] == false);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                dense: true,
                leading: Icon(
                  failed
                      ? Icons.error_outline
                      : done
                      ? Icons.check_circle_outline
                      : Icons.build_outlined,
                  size: 15,
                  color: failed ? scheme.error : scheme.onSurfaceVariant,
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Geist Mono',
                  ),
                ),
                subtitle: Text(
                  failed
                      ? l.naiAgent_toolFailed
                      : done
                      ? l.naiAgent_toolDone
                      : l.naiAgent_toolRunning,
                  style: const TextStyle(fontSize: 10),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.naiAgent_arguments,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    _text(args),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Geist Mono',
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.naiAgent_result,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (value is Map && value['content'] is List)
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final part in value['content'] as List)
                            if (part is Map &&
                                part['type'] == 'image' &&
                                part['data'] is String)
                              _MessageImage(data: part['data'] as String),
                        ],
                      ),
                    SelectableText(
                      _text(value),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Geist Mono',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (artifacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final artifact in artifacts)
                    if (artifact is Map &&
                        artifact['type'] == 'image' &&
                        artifact['path'] is String)
                      NaiAgentImageArtifact(
                        key: ValueKey('${workspace.path}:${artifact['path']}'),
                        workspace: workspace,
                        path: artifact['path'] as String,
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

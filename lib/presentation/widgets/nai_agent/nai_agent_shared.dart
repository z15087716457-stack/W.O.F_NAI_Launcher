import 'dart:async';
import 'dart:typed_data';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../router/app_router.dart';
import '../common/app_toast.dart';

Future<void> agentUiAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) AppToast.error(context, context.l10n.naiAgent_error);
  }
}

class NaiAgentModelPicker extends ConsumerWidget {
  const NaiAgentModelPicker({
    super.key,
    this.expanded = false,
    this.compact = false,
  });
  final bool expanded, compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(naiAgentControllerProvider);
    final config = ref.watch(promptAssistantConfigProvider);
    final provider = config.providers
        .where((p) => p.id == c.settings.providerId)
        .firstOrNull;
    final model = config.models
        .where(
          (m) =>
              m.providerId == c.settings.providerId &&
              m.name == c.settings.modelId,
        )
        .firstOrNull;
    final modelLabel = model == null
        ? context.l10n.naiAgent_chooseModel
        : model.displayName.isEmpty
        ? model.name
        : model.displayName;
    final fullLabel = model == null || provider == null
        ? context.l10n.naiAgent_chooseModel
        : '${provider.name} · $modelLabel';
    final label = compact ? modelLabel : fullLabel;
    return PopupMenuButton<(String, String)>(
      tooltip: compact ? fullLabel : context.l10n.naiAgent_chooseModel,
      constraints: const BoxConstraints(maxWidth: 410, maxHeight: 480),
      onSelected: (choice) => agentUiAction(context, () async {
        if (choice.$1 == '__settings__') {
          context.go('${AppRoutes.settings}?section=models');
          return;
        }
        await c.updateSettings({'providerId': choice.$1, 'modelId': choice.$2});
      }),
      itemBuilder: (_) => [
        for (final p in config.providers.where((p) => p.enabled))
          for (final m in config.models.where(
            (m) =>
                m.providerId == p.id &&
                !m.isPlaceholder &&
                m.supportsTools != false,
          ))
            PopupMenuItem(
              value: (p.id, m.name),
              child: Row(
                children: [
                  Icon(
                    c.settings.providerId == p.id &&
                            c.settings.modelId == m.name
                        ? Icons.check
                        : Icons.smart_toy_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p.name} · ${m.displayName.isEmpty ? m.name : m.displayName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ('__settings__', ''),
          child: Text(context.l10n.naiAgent_modelSettings),
        ),
      ],
      child: SizedBox(
        height: compact ? 25 : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 0 : 6,
            horizontal: compact ? 4 : 2,
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (expanded)
                Expanded(
                  child: Text(
                    label,
                    textAlign: compact ? TextAlign.right : TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 12),
                  ),
                )
              else
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 12),
                  ),
                ),
              Icon(Icons.keyboard_arrow_down, size: compact ? 11 : 15),
            ],
          ),
        ),
      ),
    );
  }
}

class NaiAgentQuestionCard extends ConsumerStatefulWidget {
  const NaiAgentQuestionCard({super.key, required this.request});
  final AgentQuestionRequest request;
  @override
  ConsumerState<NaiAgentQuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<NaiAgentQuestionCard> {
  final _answers = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    for (final q in widget.request.questions) {
      _answers[q.id] = TextEditingController(text: q.prefill);
    }
  }

  @override
  void dispose() {
    for (final c in _answers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (widget.request.kind == 'tool_approval') {
      return _NaiAgentPermissionCard(request: widget.request);
    }
    final valid = widget.request.questions.every(
      (q) => q.accepts(_answers[q.id]!.text),
    );
    return Container(
      key: ValueKey('agent-question-${widget.request.id}'),
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  context.l10n.naiAgent_waiting,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          for (final q in widget.request.questions) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(q.text),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                for (final option in q.options)
                  ChoiceChip(
                    label: Text(option),
                    selected: _answers[q.id]!.text == option,
                    onSelected: (_) =>
                        setState(() => _answers[q.id]!.text = option),
                  ),
              ],
            ),
            if (q.allowCustom) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _answers[q.id],
                minLines: 1,
                maxLines: q.multiline ? 8 : 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: q.placeholder ?? context.l10n.naiAgent_customAnswer,
                  isDense: true,
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: valid
                    ? () => ref.read(naiAgentQuestionsProvider).answer(
                        widget.request.id,
                        {for (final e in _answers.entries) e.key: e.value.text},
                      )
                    : null,
                child: Text(context.l10n.naiAgent_submitAnswer),
              ),
              TextButton(
                onPressed: () => ref
                    .read(naiAgentQuestionsProvider)
                    .cancel(widget.request.id),
                child: Text(context.l10n.naiAgent_cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NaiAgentPermissionCard extends ConsumerWidget {
  const _NaiAgentPermissionCard({required this.request});
  final AgentQuestionRequest request;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme,
        question = request.questions.single;
    final split = question.text.indexOf('\n');
    final heading = split < 0
        ? question.text
        : question.text.substring(0, split);
    final body = split < 0 ? '' : question.text.substring(split + 1);
    return Container(
      key: ValueKey('agent-question-${request.id}'),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    primary: false,
                    child: SelectableText(
                      body,
                      style: const TextStyle(
                        fontFamily: 'Geist Mono',
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in question.options)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    backgroundColor: option == question.options.first
                        ? scheme.onSurface
                        : null,
                    foregroundColor: option == question.options.first
                        ? scheme.surface
                        : scheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () => ref.read(naiAgentQuestionsProvider).answer(
                    request.id,
                    {question.id: option},
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 11)),
                ),
              TextButton(
                onPressed: () =>
                    ref.read(naiAgentQuestionsProvider).cancel(request.id),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                ),
                child: Text(
                  context.l10n.naiAgent_cancel,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NaiAgentAttachmentThumbnail extends ConsumerStatefulWidget {
  const NaiAgentAttachmentThumbnail({
    super.key,
    required this.workspaceId,
    required this.attachment,
    required this.onRemove,
  });
  final String workspaceId;
  final AgentAttachment attachment;
  final VoidCallback onRemove;
  @override
  ConsumerState<NaiAgentAttachmentThumbnail> createState() =>
      _AttachmentState();
}

class _AttachmentState extends ConsumerState<NaiAgentAttachmentThumbnail> {
  late Future<Uint8List> _bytes;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _bytes = ref
        .read(naiAgentWorkspaceStoreProvider)
        .readAttachment(widget.workspaceId, widget.attachment);
  }

  @override
  void didUpdateWidget(covariant NaiAgentAttachmentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.attachment.sha256Hex != widget.attachment.sha256Hex ||
        oldWidget.attachment.relativePath != widget.attachment.relativePath) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      return SizedBox(
        width: 68,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Tooltip(
                message: widget.attachment.name,
                child: InkWell(
                  onTap: bytes == null
                      ? null
                      : () => showDialog<void>(
                          context: context,
                          builder: (context) => Dialog(
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
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
                    borderRadius: BorderRadius.circular(7),
                    child: bytes == null
                        ? const Icon(
                            Icons.image_not_supported_outlined,
                            size: 22,
                          )
                        : Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            cacheWidth: 136,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              top: -5,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onRemove,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Tooltip(
                      message: context.l10n.naiAgent_removeAttachment,
                      child: const Icon(Icons.close, size: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

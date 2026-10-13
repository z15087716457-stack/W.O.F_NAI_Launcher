import 'dart:async';
import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/nai_agent/nai_agent_model_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import 'nai_agent_shared.dart';

Future<String?> agentNameDialog(
  BuildContext context,
  String title,
  String value,
) async {
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

class NaiAgentWorkspacePicker extends StatelessWidget {
  const NaiAgentWorkspacePicker({
    super.key,
    required this.controller,
    required this.runtime,
  });
  final NaiAgentWorkspaceController controller;
  final AgentChatRuntime runtime;
  @override
  Widget build(BuildContext context) {
    final c = controller,
        l = context.l10n,
        scheme = Theme.of(context).colorScheme;
    Widget chip(Widget child) => Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
    return SizedBox(
      key: const Key('nai-agent-workspace'),
      height: 24,
      child: Row(
        children: [
          Tooltip(
            message: runtime.workspace.directory.path,
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () => agentUiAction(context, () async {
                await launchUrl(
                  Uri.directory(runtime.workspace.directory.path),
                  mode: LaunchMode.externalApplication,
                );
              }),
              child: chip(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.laptop_outlined,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l.naiAgent_local,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: PopupMenuButton<String>(
              enabled: c.initialized,
              tooltip: l.naiAgent_workspace,
              onSelected: (id) => agentUiAction(context, () async {
                if (id == '__new__') {
                  final name = await agentNameDialog(
                    context,
                    l.naiAgent_createWorkspace,
                    '',
                  );
                  if (name != null) await c.createWorkspace(name);
                } else if (id == '__rename__') {
                  final workspace = c.selectedWorkspace!;
                  final name = await agentNameDialog(
                    context,
                    l.naiAgent_rename,
                    workspace.name,
                  );
                  if (name != null) await c.renameWorkspace(workspace.id, name);
                } else {
                  await c.selectWorkspace(id);
                }
              }),
              itemBuilder: (_) => [
                for (final w in c.workspaces)
                  PopupMenuItem(
                    value: w.id,
                    child: Row(
                      children: [
                        Icon(
                          c.selectedWorkspace?.id == w.id
                              ? Icons.check
                              : Icons.folder_outlined,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(w.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: '__new__',
                  child: Text(l.naiAgent_createWorkspace),
                ),
                PopupMenuItem(
                  value: '__rename__',
                  child: Text(l.naiAgent_rename),
                ),
              ],
              child: chip(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        c.selectedWorkspace?.name ?? l.naiAgent_workspace,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NaiAgentPermissionPicker extends ConsumerWidget {
  const NaiAgentPermissionPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(naiAgentControllerProvider), l = context.l10n;
    final labels = {
      'auto': l.naiAgent_permissionAuto,
      'ask': l.naiAgent_permissionAsk,
      'readonly': l.naiAgent_permissionReadOnly,
    };
    final hints = {
      'auto': l.naiAgent_permissionAutoHint,
      'ask': l.naiAgent_permissionAskHint,
      'readonly': l.naiAgent_permissionReadOnlyHint,
    };
    return PopupMenuButton<String>(
      key: const Key('nai-agent-mode'),
      tooltip: l.naiAgent_permissionMode,
      onSelected: (mode) => agentUiAction(
        context,
        () => c.updateSettings({'permissionMode': mode}),
      ),
      itemBuilder: (_) => [
        for (final mode in labels.keys)
          PopupMenuItem(
            value: mode,
            child: SizedBox(
              width: 250,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    c.settings.permissionMode == mode
                        ? Icons.check
                        : Icons.shield_outlined,
                    size: 15,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(labels[mode]!),
                        const SizedBox(height: 3),
                        Text(
                          hints[mode]!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      child: agentControlLabel(
        context,
        labels[c.settings.permissionMode]!,
        leadingPadding: 2,
      ),
    );
  }
}

Widget agentControlLabel(
  BuildContext context,
  String label, {
  double leadingPadding = 4,
  bool enabled = true,
}) => SizedBox(
  height: 25,
  child: Padding(
    padding: EdgeInsets.only(left: leadingPadding, right: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                alpha: enabled ? 1 : .5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.keyboard_arrow_down,
          size: 11,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: enabled ? 1 : .5),
        ),
      ],
    ),
  ),
);

class NaiAgentThinkingPicker extends ConsumerWidget {
  const NaiAgentThinkingPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(naiAgentControllerProvider),
        config = ref.watch(promptAssistantConfigProvider),
        l = context.l10n;
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
    final efforts = provider == null || model == null
        ? <String>[]
        : naiAgentReasoningEfforts(provider, model);
    final saved = c.settings.reasoningEffort;
    final effort = efforts.contains(saved) ? saved : model?.reasoningEffort;
    return PopupMenuButton<String>(
      key: const Key('nai-agent-thinking'),
      enabled: efforts.length > 1,
      tooltip: efforts.isEmpty
          ? l.naiAgent_thinkingUnsupported
          : l.naiAgent_thinking,
      onSelected: (effort) => agentUiAction(
        context,
        () => c.setReasoningEffort(
          effort == '__default__' ? null : effort,
          providerId: provider!.id,
          modelId: model!.name,
        ),
      ),
      itemBuilder: (_) => [
        for (final value in efforts)
          CheckedPopupMenuItem(
            value: value,
            checked: effort == value,
            child: Text(reasoningEffortLabel(l, value)),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: '__default__',
          child: Text(l.naiAgent_useModelSetting),
        ),
      ],
      child: agentControlLabel(
        context,
        efforts.isEmpty ? '—' : reasoningEffortLabel(l, effort),
        enabled: efforts.length > 1,
      ),
    );
  }
}

class NaiAgentContextRing extends ConsumerStatefulWidget {
  const NaiAgentContextRing({
    super.key,
    required this.controller,
    required this.runtime,
  });
  final NaiAgentWorkspaceController controller;
  final AgentChatRuntime runtime;
  @override
  ConsumerState<NaiAgentContextRing> createState() => _ContextRingState();
}

class _ContextRingState extends ConsumerState<NaiAgentContextRing> {
  final _menu = MenuController();
  @override
  Widget build(BuildContext context) {
    ref.watch(naiAgentControllerProvider);
    final l = context.l10n,
        scheme = Theme.of(context).colorScheme,
        r = widget.runtime;
    final info = _Usage(r.context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final tooltip = info.fraction == null
        ? l.naiAgent_contextUnknown
        : l.naiAgent_contextTooltip(
            ((1 - info.fraction!).clamp(0, 1) * 100).toStringAsFixed(1),
            format.format(info.remaining),
            format.format(info.window),
          );
    final panelWidth = math.min(330.0, MediaQuery.sizeOf(context).width - 28);
    return MenuAnchor(
      controller: _menu,
      alignmentOffset: Offset(25 - panelWidth, -5),
      onOpen: () => setState(() {}),
      onClose: () {
        if (mounted) setState(() {});
      },
      style: MenuStyle(
        alignment: Alignment.topLeft,
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: const WidgetStatePropertyAll(4),
        shadowColor: WidgetStatePropertyAll(
          scheme.shadow.withValues(alpha: .25),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
      ),
      menuChildren: [
        SizedBox(
          width: panelWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height - 70,
            ),
            child: SingleChildScrollView(
              primary: false,
              child: _AgentStatistics(
                controller: widget.controller,
                runtime: r,
                close: _menu.close,
              ),
            ),
          ),
        ),
      ],
      builder: (context, controller, child) => Tooltip(
        message: controller.isOpen ? '' : tooltip,
        child: SizedBox(
          width: 25,
          height: 25,
          child: IconButton(
            key: const Key('nai-agent-context'),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 25, height: 25),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
                return;
              }
              unawaited(
                agentUiAction(context, () => widget.controller.refreshUsage(r)),
              );
              controller.open();
            },
            icon: CustomPaint(
              size: const Size(18, 18),
              painter: _ContextPainter(
                fraction: info.fraction,
                color: info.fraction != null && info.fraction! >= .9
                    ? scheme.error
                    : scheme.onSurfaceVariant,
                track: scheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Usage {
  _Usage(Map<String, dynamic> context) {
    final used = context['tokens'], capacity = context['contextWindow'];
    if (used is num && used.isFinite && used >= 0) tokens = used.toInt();
    if (context['windowKnown'] != false &&
        capacity is num &&
        capacity.isFinite &&
        capacity >= 1) {
      window = capacity.toInt();
    }
  }
  int? tokens, window;
  double? get fraction =>
      tokens == null || window == null ? null : tokens! / window!;
  int? get remaining =>
      tokens == null || window == null ? null : math.max(0, window! - tokens!);
}

class _ContextPainter extends CustomPainter {
  const _ContextPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });
  final double? fraction;
  final Color color, track;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = size.shortestSide / 2 - 2;
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, pen);
    pen.color = color;
    if (fraction == null) {
      for (var i = 0; i < 4; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * math.pi / 2,
          .17,
          false,
          pen,
        );
      }
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        fraction!.clamp(0, 1) * math.pi * 2,
        false,
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(_ContextPainter oldDelegate) =>
      fraction != oldDelegate.fraction ||
      color != oldDelegate.color ||
      track != oldDelegate.track;
}

class _AgentStatistics extends ConsumerWidget {
  const _AgentStatistics({
    required this.controller,
    required this.runtime,
    required this.close,
  });
  final NaiAgentWorkspaceController controller;
  final AgentChatRuntime runtime;
  final VoidCallback close;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(naiAgentControllerProvider);
    final l = context.l10n,
        scheme = Theme.of(context).colorScheme,
        info = _Usage(runtime.context);
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final tokens = runtime.stats['tokens'] as Map? ?? {};
    String number(dynamic value) => value is num && value.isFinite && value >= 0
        ? format.format(value)
        : '—';
    Widget row(String label, dynamic value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value is String ? value : number(value),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
    Widget section(String label, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(height: 1, color: scheme.outlineVariant),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
    return Padding(
      key: const Key('nai-agent-statistics'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.naiAgent_statistics,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: close,
                tooltip: l.naiAgent_close,
                icon: const Icon(Icons.close, size: 15),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 22,
                  height: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.naiAgent_contextUsage,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            info.fraction == null
                ? '—'
                : '${(info.fraction! * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            '${number(info.tokens)} / ${number(info.window)}',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: info.fraction?.clamp(0, 1) ?? 0,
              color: scheme.onSurfaceVariant,
              backgroundColor: scheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 5),
          row(l.naiAgent_contextRemaining, info.remaining),
          row(l.naiAgent_contextWindow, info.window),
          if (info.fraction == null)
            Text(
              l.naiAgent_contextUnknown,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          section(l.naiAgent_sessionUsage, [
            row(l.naiAgent_tokensInput, tokens['input']),
            row(l.naiAgent_tokensOutput, tokens['output']),
            row(l.naiAgent_tokensCacheRead, tokens['cacheRead']),
            row(l.naiAgent_tokensCacheWrite, tokens['cacheWrite']),
            row(l.naiAgent_tokensTotal, tokens['total']),
            const SizedBox(height: 5),
            Text(
              l.naiAgent_cumulativeUsageHint,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
          ]),
          section(l.naiAgent_messageCounts, [
            row(
              l.naiAgent_userAssistantMessages,
              '${number(runtime.stats['userMessages'])} / ${number(runtime.stats['assistantMessages'])}',
            ),
            row(l.naiAgent_toolCalls, runtime.stats['toolCalls']),
            row(l.naiAgent_cost, l.naiAgent_unknownCost),
          ]),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: runtime.running || runtime.starting
                ? null
                : () {
                    close();
                    unawaited(agentUiAction(context, controller.compact));
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 7),
              minimumSize: const Size(0, 28),
            ),
            child: Text(
              l.naiAgent_compact,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

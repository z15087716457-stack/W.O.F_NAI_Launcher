import 'dart:io';
import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/krita/bridge_session.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import '../../providers/krita/bridge_agent_feedback.dart';
import '../../providers/settings_navigation_provider.dart';
import '../../router/app_router.dart';
import '../common/app_toast.dart';
import 'bridge_link_icon.dart';

class BridgeClientBundle {
  const BridgeClientBundle(this.path, {required this.available});
  final String path;
  final bool available;
}

final bridgeClientBundleProvider = FutureProvider<BridgeClientBundle>((
  ref,
) async {
  final path =
      '${File(Platform.resolvedExecutable).parent.path}/tools/studio-bridge.exe';
  return BridgeClientBundle(path, available: await File(path).exists());
});

String bridgeOperationLabel(AppLocalizations l, String operation) =>
    switch (operation) {
      'get_params' => l.bridge_read,
      'set_params' => l.bridge_write,
      'quote' => l.bridge_quote,
      'generate' || 'inpaint' || 'img2img' => l.bridge_generate,
      'cancel' => l.bridge_cancel,
      _ => l.bridge_ready,
    };

String bridgeActivityLabel(AppLocalizations l, BridgeActivity activity) {
  final action = l.bridge_activity(
    activity.client.name,
    bridgeOperationLabel(l, activity.operation),
  );
  if (activity.status == BridgeActivityStatus.disconnected) {
    return '$action · ${l.bridge_interrupted}';
  }
  if (activity.status == BridgeActivityStatus.failed) {
    final reason = switch (activity.errorCode) {
      'conflict' => l.bridge_conflict,
      'busy' => l.bridge_busy,
      'timeout' => l.bridge_timeout,
      _ => l.bridge_failed,
    };
    return '$action · $reason';
  }
  return action;
}

String bridgeAgentStatus(
  AppLocalizations l,
  KritaBridgeState state,
  BridgeAgentFeedback feedback,
) => switch (feedback.phase) {
  BridgeAgentPhase.synced => l.bridge_synced,
  BridgeAgentPhase.changed => l.bridge_changed,
  BridgeAgentPhase.working || BridgeAgentPhase.failed =>
    feedback.activity == null
        ? l.bridge_ready
        : bridgeActivityLabel(l, feedback.activity!),
  BridgeAgentPhase.waiting =>
    state.session.agents.isEmpty ? l.bridge_waiting : l.bridge_ready,
};

class AgentBridgeIndicator extends ConsumerWidget {
  const AgentBridgeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kritaBridgeNotifierProvider);
    if (!state.enabled) return const SizedBox.shrink();
    final feedback = ref.watch(bridgeAgentFeedbackProvider);
    final scheme = Theme.of(context).colorScheme;
    final color = switch (feedback.phase) {
      BridgeAgentPhase.working => scheme.primary,
      BridgeAgentPhase.synced =>
        Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF63D79C)
            : const Color(0xFF17965F),
      BridgeAgentPhase.failed => Colors.orange,
      _ => scheme.onSurfaceVariant.withValues(alpha: 0.55),
    };
    final label = bridgeAgentStatus(context.l10n, state, feedback);
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Tooltip(
        message: label,
        verticalOffset: 18,
        child: IconButton(
          key: const Key('agent-bridge-indicator'),
          tooltip: null,
          icon: Semantics(
            label: label,
            child: Transform.translate(
              offset: const Offset(0, 1),
              child: BridgeLinkIcon(
                color: color,
                working: feedback.phase == BridgeAgentPhase.working,
              ),
            ),
          ),
          style: IconButton.styleFrom(
            minimumSize: const Size(24, 24),
            maximumSize: const Size(24, 24),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            overlayColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          onPressed: () => _openPanel(context, ref),
        ),
      ),
    );
  }

  Future<void> _openPanel(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero, ancestor: overlay);
    await showMenu<void>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          anchor.dx,
          anchor.dy + box.size.height + 3,
          box.size.width,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(
        minWidth: math.min(300, overlay.size.width - 24),
        maxWidth: math.min(340, overlay.size.width - 24),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      menuPadding: EdgeInsets.zero,
      items: [
        _BridgePanelEntry(
          onSettings: () {
            Navigator.of(context).pop();
            ref.read(settingsBridgeOpenRequestProvider.notifier).state++;
            context.go('${AppRoutes.settings}?section=integrations&bridge=1');
          },
        ),
      ],
    );
  }
}

class _BridgePanelEntry extends PopupMenuEntry<void> {
  const _BridgePanelEntry({required this.onSettings});
  final VoidCallback onSettings;
  @override
  double get height => 300;
  @override
  bool represents(void value) => false;
  @override
  State<_BridgePanelEntry> createState() => _BridgePanelEntryState();
}

class _BridgePanelEntryState extends State<_BridgePanelEntry> {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: math.min(460, MediaQuery.sizeOf(context).height - 32),
    ),
    child: SingleChildScrollView(
      child: BridgeAgentPanel(onSettings: widget.onSettings),
    ),
  );
}

class BridgeAgentPanel extends ConsumerWidget {
  const BridgeAgentPanel({super.key, this.onSettings});
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(kritaBridgeNotifierProvider);
    final feedback = ref.watch(bridgeAgentFeedbackProvider);
    final bundle = ref.watch(bridgeClientBundleProvider).asData?.value;
    final activities = state.session.activities
        .where((a) => a.client.isAgent)
        .take(5)
        .toList();
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.bridge_agent, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            bridgeAgentStatus(l, state, feedback),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          if (state.session.agents.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l.bridge_clients(state.session.agents.length),
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l.bridge_agentHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('bridge-copy-guide'),
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: Text(l.bridge_copyGuide),
            onPressed: bundle?.available == true
                ? () async {
                    await Clipboard.setData(
                      ClipboardData(text: l.bridge_guide(bundle!.path)),
                    );
                    if (context.mounted) {
                      AppToast.success(context, l.bridge_copied);
                    }
                  }
                : null,
          ),
          if (bundle != null && !bundle.available)
            Text(l.bridge_clientMissing, style: theme.textTheme.bodySmall),
          if (bundle?.available == true)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l.bridge_copyGuide),
                    content: SizedBox(
                      width: 580,
                      child: SingleChildScrollView(
                        child: SelectableText(l.bridge_guide(bundle!.path)),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l.common_close),
                      ),
                    ],
                  ),
                ),
                child: Text(l.bridge_showGuide),
              ),
            ),
          const Divider(height: 18),
          Text(l.bridge_recent, style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          if (activities.isEmpty)
            Text(l.bridge_empty, style: theme.textTheme.bodySmall),
          for (final a in activities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      bridgeActivityLabel(l, a),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    TimeOfDay.fromDateTime(a.at.toLocal()).format(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          if (state.session.agents.isNotEmpty)
            TextButton(
              key: const Key('bridge-disconnect-agents'),
              onPressed: () => ref
                  .read(kritaBridgeNotifierProvider.notifier)
                  .disconnectAgents(),
              child: Text(l.bridge_disconnect),
            ),
          if (onSettings != null)
            TextButton(onPressed: onSettings, child: Text(l.bridge_settings)),
        ],
      ),
    );
  }
}

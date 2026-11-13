import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../ui/agent/agent_canvas_notice.dart';
import '../../widgets/common/app_toast.dart';

class AgentCanvasNoticeWiring extends ConsumerStatefulWidget {
  const AgentCanvasNoticeWiring({super.key});
  @override
  ConsumerState<AgentCanvasNoticeWiring> createState() =>
      _AgentCanvasNoticeWiringState();
}

class _AgentCanvasNoticeWiringState
    extends ConsumerState<AgentCanvasNoticeWiring> {
  String? _attentionId;
  DateTime? _attentionAt;
  @override
  Widget build(BuildContext context) {
    ref.watch(naiAgentUiPreferencesProvider);
    // A closed canvas notification must not initialize an Agent host.
    if (!ref.exists(naiAgentControllerProvider)) return const SizedBox.shrink();
    final controller = ref.watch(naiAgentControllerProvider);
    final expanded = ref.exists(naiAgentWindowControllerProvider)
        ? ref.watch(naiAgentWindowControllerProvider).presentationExpanded ??
              controller.settings.panelExpanded
        : controller.settings.panelExpanded;
    if (expanded) return const SizedBox.shrink();
    final unread =
        controller.heldRuntimes
            .where((r) => r.external?.unread == true)
            .toList()
          ..sort(
            (a, b) => b.external!.unreadAt.compareTo(a.external!.unreadAt),
          );
    final questions = ref.watch(naiAgentQuestionsProvider);
    final generations = ref.watch(naiAgentGenerationApprovalsProvider);
    final images = ref.watch(naiAgentImageApprovalsProvider);
    AgentChatRuntime? attention;
    for (final runtime in unread) {
      final chatId = runtime.chat.id;
      final id =
          questions.forChat(chatId).firstOrNull?.id ??
          generations.forChat(chatId).firstOrNull?.id ??
          images.forChat(chatId).firstOrNull?.id;
      if (id == null) continue;
      if (_attentionId != id) {
        _attentionId = id;
        _attentionAt = DateTime.now();
      }
      attention = runtime;
      break;
    }
    final results = unread.where((r) => r.external!.notice != null).toList()
      ..sort(
        (a, b) => b.external!.notice!.at.compareTo(a.external!.notice!.at),
      );
    if (attention != null &&
        (results.isEmpty ||
            results.first.external!.notice!.at.isBefore(_attentionAt!))) {
      return _notice(
        controller,
        attention,
        id: _attentionId!,
        at: _attentionAt!,
        kind: AgentCanvasNoticeKind.attention,
      );
    }
    if (results.isEmpty) return const SizedBox.shrink();
    final runtime = results.first, event = runtime.external!.notice!;
    return _notice(
      controller,
      runtime,
      id: event.id,
      at: event.at,
      title: event.title,
      kind: event.isError
          ? AgentCanvasNoticeKind.failed
          : AgentCanvasNoticeKind.updated,
    );
  }

  Widget _notice(
    NaiAgentWorkspaceController controller,
    AgentChatRuntime runtime, {
    required String id,
    required DateTime at,
    String? title,
    required AgentCanvasNoticeKind kind,
  }) => AgentCanvasNotice(
    id: id,
    at: at,
    client: runtime.chat.externalClient!,
    title: title,
    kind: kind,
    onView: () => unawaited(
      (() async {
        await controller.showExternal(runtime);
        await ref.read(naiAgentWindowControllerProvider).open();
      })().catchError((Object _) {
        if (mounted) AppToast.error(context, context.l10n.naiAgent_error);
      }),
    ),
  );
}

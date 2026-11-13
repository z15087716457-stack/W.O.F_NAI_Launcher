import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../ui/agent/agent_glyphs.dart';

const _priority = [
  AgentToggleBadge.question,
  AgentToggleBadge.approval,
  AgentToggleBadge.runLimit,
  AgentToggleBadge.error,
  AgentToggleBadge.generating,
  AgentToggleBadge.compacting,
  AgentToggleBadge.tool,
  AgentToggleBadge.writing,
  AgentToggleBadge.thinking,
  AgentToggleBadge.starting,
  AgentToggleBadge.done,
  AgentToggleBadge.none,
];

bool _isResult(AgentToggleBadge badge) => const {
  AgentToggleBadge.runLimit,
  AgentToggleBadge.error,
  AgentToggleBadge.done,
}.contains(badge);

AgentToggleBadge agentRuntimeBadge(AgentChatRuntime runtime) {
  if (runtime.compacting) return AgentToggleBadge.compacting;
  if (runtime.starting || runtime.waitingForSlot) {
    return AgentToggleBadge.starting;
  }
  if (!runtime.running) return AgentToggleBadge.none;
  if (runtime.executingTools.isNotEmpty) {
    final generating = runtime.executingTools.values.any((tool) {
      final name = (tool['toolName'] as String? ?? '').replaceFirst(
        RegExp(r'^mcp__nai_studio__'),
        '',
      );
      final args = tool['args'] as Map?;
      return name == 'generation_run' ||
          (name == 'image_generate' && args?['action'] == 'run');
    });
    return generating ? AgentToggleBadge.generating : AgentToggleBadge.tool;
  }
  return runtime.streamPhase == AgentStreamPhase.writing
      ? AgentToggleBadge.writing
      : AgentToggleBadge.thinking;
}

/// One ledger per ProviderScope for both the toolbar and the sidebar.
class AgentToggleBadgeLedger {
  bool _expanded = false;
  Set<String> _running = {};
  final _done = <String, AgentToggleBadge>{};

  bool get expanded => _expanded;

  void clearDone() => _done.clear();

  AgentToggleBadge update({
    required bool expanded,
    required Set<String> chats,
    required Map<String, AgentToggleBadge> running,
    required Map<String, AgentToggleBadge> waiting,
    Map<String, AgentToggleBadge> results = const {},
  }) {
    if (_expanded && !expanded) clearDone();
    _expanded = expanded;
    final runningIds = running.keys.toSet();
    final waitingIds = waiting.keys.toSet();
    for (final id
        in _running
            .intersection(chats)
            .difference(runningIds)
            .difference(waitingIds)) {
      _done[id] = results[id] ?? AgentToggleBadge.done;
    }
    _done.removeWhere(
      (id, _) => !chats.contains(id) || runningIds.contains(id),
    );
    _running = {
      ...runningIds,
      ..._running.intersection(chats).intersection(waitingIds),
    };
    final badges = {...waiting.values, ...running.values, ..._done.values};
    return _priority.firstWhere(
      badges.contains,
      orElse: () => AgentToggleBadge.none,
    );
  }
}

final agentToggleBadgeProvider = Provider<AgentToggleBadge>((ref) {
  final ledger = AgentToggleBadgeLedger();
  Timer? completionTimer;
  var observed = false;
  late AgentToggleBadge Function() sample;

  void cancelCompletion() {
    completionTimer?.cancel();
    completionTimer = null;
  }

  void syncCompletion(AgentToggleBadge badge) {
    if (!observed || !ledger.expanded || !_isResult(badge)) {
      cancelCompletion();
      return;
    }
    completionTimer ??= Timer(const Duration(seconds: 2), () {
      completionTimer = null;
      ledger.clearDone();
      ref.state = sample();
    });
  }

  ref.onAddListener(() {
    if (observed) return;
    observed = true;
    syncCompletion(ref.state);
  });
  ref.onCancel(() {
    observed = false;
    cancelCompletion();
  });
  ref.onDispose(cancelCompletion);

  sample = () {
    final controller = ref.read(naiAgentControllerProvider);
    final window = ref.read(naiAgentWindowControllerProvider);
    final expanded =
        window.presentationExpanded ??
        ref.read(naiAgentUiPreferencesProvider).settings.panelExpanded;
    final questions = ref.read(naiAgentQuestionsProvider);
    final generations = ref.read(naiAgentGenerationApprovalsProvider);
    final images = ref.read(naiAgentImageApprovalsProvider);
    final runtimes = controller.heldRuntimes.toList();
    final chats = {
      for (final r in runtimes) r.chat.id,
      for (final chat in controller.chats) chat.id,
    };
    final badge = ledger.update(
      expanded: expanded,
      chats: chats,
      running: {
        for (final r in runtimes)
          if (agentRuntimeBadge(r) case final badge when badge.isRunning)
            r.chat.id: badge,
      },
      waiting: {
        for (final id in chats)
          if (questions.forChat(id).isNotEmpty)
            id: AgentToggleBadge.question
          else if (generations.forChat(id).isNotEmpty ||
              images.forChat(id).isNotEmpty)
            id: AgentToggleBadge.approval,
      },
      results: {
        for (final r in runtimes)
          r.chat.id: r.runLimitHit != null
              ? AgentToggleBadge.runLimit
              : r.error != null ||
                    r.external?.notice?.isError == true ||
                    r.external?.calls.lastOrNull?.result?['isError'] == true
              ? AgentToggleBadge.error
              : AgentToggleBadge.done,
      },
    );
    final visibleBadge =
        badge == AgentToggleBadge.none &&
            runtimes.any((r) => r.external?.unread == true)
        ? AgentToggleBadge.done
        : badge;
    syncCompletion(visibleBadge);
    return visibleBadge;
  };

  // Listen instead of watch: preserve the ledger across notifications. Sampling
  // in every listener also retains short running -> idle transitions between
  // widget frames (including while another toolbar is not mounted).
  void changed() {
    final badge = sample();
    if (ref.state != badge) ref.state = badge;
  }

  ref.listen(naiAgentControllerProvider, (_, _) => changed());
  ref.listen(naiAgentQuestionsProvider, (_, _) => changed());
  ref.listen(naiAgentGenerationApprovalsProvider, (_, _) => changed());
  ref.listen(naiAgentImageApprovalsProvider, (_, _) => changed());
  ref.listen(naiAgentWindowControllerProvider, (_, _) => changed());
  ref.listen(naiAgentUiPreferencesProvider, (_, _) => changed());
  return sample();
});

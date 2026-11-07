import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../ui/agent/agent_glyphs.dart';

/// One ledger per ProviderScope for both the toolbar and the sidebar.
class AgentToggleBadgeLedger {
  bool _expanded = false;
  Set<String> _running = {};
  final _done = <String>{};

  bool get expanded => _expanded;

  void clearDone() => _done.clear();

  AgentToggleBadge update({
    required bool expanded,
    required Set<String> chats,
    required Set<String> running,
    required Set<String> waiting,
  }) {
    if (_expanded && !expanded) clearDone();
    _expanded = expanded;
    _done
      ..addAll(
        _running.intersection(chats).difference(running).difference(waiting),
      )
      ..removeWhere((id) => !chats.contains(id) || running.contains(id));
    _running = {
      ...running,
      ..._running.intersection(chats).intersection(waiting),
    };
    if (waiting.isNotEmpty) return AgentToggleBadge.waiting;
    if (running.isNotEmpty) return AgentToggleBadge.running;
    return _done.isEmpty ? AgentToggleBadge.none : AgentToggleBadge.done;
  }
}

final agentToggleBadgeProvider = Provider<AgentToggleBadge>((ref) {
  final ledger = AgentToggleBadgeLedger();
  Timer? completionTimer;
  var observed = false;

  void cancelCompletion() {
    completionTimer?.cancel();
    completionTimer = null;
  }

  void syncCompletion(AgentToggleBadge badge) {
    if (!observed || !ledger.expanded || badge != AgentToggleBadge.done) {
      cancelCompletion();
      return;
    }
    completionTimer ??= Timer(const Duration(seconds: 2), () {
      completionTimer = null;
      ledger.clearDone();
      ref.state = AgentToggleBadge.none;
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

  AgentToggleBadge sample() {
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
          if (r.running || r.starting || r.waitingForSlot) r.chat.id,
      },
      waiting: {
        for (final id in chats)
          if (questions.forChat(id).isNotEmpty ||
              generations.forChat(id).isNotEmpty ||
              images.forChat(id).isNotEmpty)
            id,
      },
    );
    syncCompletion(badge);
    return badge;
  }

  // Listen instead of watch: preserve the ledger across notifications. Sampling
  // in every listener also retains short running -> idle transitions between
  // widget frames (including while another toolbar is not mounted).
  void changed() => ref.state = sample();
  ref.listen(naiAgentControllerProvider, (_, _) => changed());
  ref.listen(naiAgentQuestionsProvider, (_, _) => changed());
  ref.listen(naiAgentGenerationApprovalsProvider, (_, _) => changed());
  ref.listen(naiAgentImageApprovalsProvider, (_, _) => changed());
  ref.listen(naiAgentWindowControllerProvider, (_, _) => changed());
  ref.listen(naiAgentUiPreferencesProvider, (_, _) => changed());
  return sample();
});

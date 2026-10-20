import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/nai_agent/nai_agent_generation_approvals.dart';
import '../../providers/nai_agent/nai_agent_image_approvals.dart';
import '../../providers/nai_agent/nai_agent_questions.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../ui/agent/agent_glyphs.dart';

/// One ledger per ProviderScope, shared by all toolbar entry points. Missing
/// runtimes (deleted/closed chats) are not mistaken for finished tasks.
class AgentToggleBadgeLedger {
  Set<String> _running = {};
  final _done = <String>{};

  AgentToggleBadge update({
    required bool expanded,
    required Set<String> chats,
    required Set<String> running,
    required Set<String> waiting,
  }) {
    if (expanded) {
      _done.clear();
    } else {
      _done.addAll(
        _running.intersection(chats).difference(running).difference(waiting),
      );
      _done.removeWhere((id) => !chats.contains(id));
    }
    _running = {
      ...running,
      if (!expanded) ..._running.intersection(chats).intersection(waiting),
    };
    if (expanded) return AgentToggleBadge.none;
    if (waiting.isNotEmpty) return AgentToggleBadge.waiting;
    if (running.isNotEmpty) return AgentToggleBadge.running;
    return _done.isEmpty ? AgentToggleBadge.none : AgentToggleBadge.done;
  }
}

final agentToggleBadgeProvider = Provider<AgentToggleBadge>((ref) {
  final ledger = AgentToggleBadgeLedger();
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
    return ledger.update(
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

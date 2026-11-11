import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/nav_activity_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/widgets/common/update_check_dialog.dart';

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void emit(bool running) => state = ImageGenerationState(
    status: running ? GenerationStatus.generating : GenerationStatus.idle,
  );
}

class _Explore extends ExploreRunRunner {
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
  void emit(bool running) => state = ExploreRunRunnerState(isRunning: running);
}

class _Activity extends NavActivityNotifier {
  @override
  NavActivityState build() => const NavActivityState();
  void emit(List<NavBackgroundTask> tasks) =>
      state = NavActivityState(tasks: tasks);
}

class _Agent extends NaiAgentWorkspaceController {
  _Agent()
    : super(
        store: AgentWorkspaceStore(Directory('unused-test-store')),
        startClient: (a, b, c, d, e) =>
            throw StateError('No host should start'),
        initialWorkspaceName: 'test',
        initialChatName: 'test',
      );
  final runtimes = <AgentChatRuntime>[];
  @override
  Iterable<AgentChatRuntime> get heldRuntimes => runtimes;
  void changed() => notifyListeners();
  @override
  Future<void> close() async {}
}

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        imageGenerationNotifierProvider.overrideWith(_Generation.new),
        exploreRunRunnerProvider.overrideWith(_Explore.new),
        navActivityProvider.overrideWith(_Activity.new),
        naiAgentControllerProvider.overrideWith((ref) => _Agent()),
      ],
    );
  });
  tearDown(() => container.dispose());
  void observe() {
    container.listen(updateTaskBusyProvider, (_, __) {});
  }

  test('opening update protection never initializes a closed Agent', () {
    observe();
    expect(container.read(updateTaskBusyProvider), isFalse);
    expect(container.exists(naiAgentControllerProvider), isFalse);
  });
  test(
    'generation, exploration and unfinished background tasks block installation',
    () {
      observe();
      final generation =
          container.read(imageGenerationNotifierProvider.notifier)
              as _Generation;
      generation.emit(true);
      expect(container.read(updateTaskBusyProvider), isTrue);
      generation.emit(false);
      expect(container.read(updateTaskBusyProvider), isFalse);
      final explore =
          container.read(exploreRunRunnerProvider.notifier) as _Explore;
      explore.emit(true);
      expect(container.read(updateTaskBusyProvider), isTrue);
      explore.emit(false);
      final activity =
          container.read(navActivityProvider.notifier) as _Activity;
      for (final source in NavTaskSource.values) {
        activity.emit([NavBackgroundTask(id: 'task', source: source)]);
        expect(container.read(updateTaskBusyProvider), isTrue);
        activity.emit([
          NavBackgroundTask(id: 'task', source: source, finished: true),
        ]);
        expect(container.read(updateTaskBusyProvider), isFalse);
      }
    },
  );
  test(
    'all retained Agent chats block while starting, queued, running or compacting',
    () {
      final agent = container.read(naiAgentControllerProvider) as _Agent;
      final workspace = AgentWorkspace(
        id: 'w',
        name: 'w',
        directory: Directory('unused'),
        createdAt: DateTime(2026),
      );
      final runtime = AgentChatRuntime(
        workspace,
        AgentChat(
          id: 'background-chat',
          workspaceId: 'w',
          title: 'test',
          createdAt: DateTime(2026),
        ),
        const AgentComposerState(),
      );
      agent.runtimes.add(runtime);
      observe();
      expect(container.read(updateTaskBusyProvider), isFalse);
      for (final set in <void Function(bool)>[
        (v) => runtime.running = v,
        (v) => runtime.starting = v,
        (v) => runtime.compacting = v,
        (v) => runtime.waitingForSlot = v,
        (v) => runtime.pendingSends = v ? 1 : 0,
      ]) {
        set(true);
        agent.changed();
        expect(container.read(updateTaskBusyProvider), isTrue);
        set(false);
        agent.changed();
        expect(container.read(updateTaskBusyProvider), isFalse);
      }
    },
  );
  test(
    'a new dialog checks an Agent created after the earlier dialog closed',
    () async {
      final first = container.listen(updateTaskBusyProvider, (_, __) {});
      expect(container.read(updateTaskBusyProvider), isFalse);
      first.close();
      await container.pump();
      final agent = container.read(naiAgentControllerProvider) as _Agent;
      final workspace = AgentWorkspace(
        id: 'w',
        name: 'w',
        directory: Directory('unused'),
        createdAt: DateTime(2026),
      );
      agent.runtimes.add(
        AgentChatRuntime(
          workspace,
          AgentChat(
            id: 'later-chat',
            workspaceId: 'w',
            title: 'test',
            createdAt: DateTime(2026),
          ),
          const AgentComposerState(),
        )..running = true,
      );
      observe();
      expect(container.read(updateTaskBusyProvider), isTrue);
      expect(container.exists(naiAgentControllerProvider), isTrue);
    },
  );
}

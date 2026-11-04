import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_commands_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_contract.dart' as view;
import 'package:path/path.dart' as p;

import '../../../helpers/nai_agent_list_stand_ins.dart';
import 'agent_wiring_harness.dart';

/// The generation page is not kept alive: leaving it takes the docked Agent
/// panel (AgentWiring) with it, coming back builds the panel again. These run
/// the real panel with the real list providers; only Node is a stand-in.
void main() {
  const platforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.windows,
  });
  late AgentWiringHarness h;
  late NodeListStandIn node;
  setUp(() async {
    node = NodeListStandIn();
    h = AgentWiringHarness();
    await h.init(
      listInventories: true,
      overrides: [
        // Read on first use, inside the test, once the variant has set the
        // platform: node.exe on Windows, node on macOS.
        naiAgentRuntimePathsProvider.overrideWith(
          (ref) => writeStandInRuntime(
            h.root,
            windows: defaultTargetPlatform == TargetPlatform.windows,
          ),
        ),
        naiAgentListProcessStarterProvider.overrideWithValue(node.start),
        // Windows' file times (the change time is the creation time) on
        // Windows, the real ones on macOS; read once the variant is set.
        naiAgentFileStatProvider.overrideWith(
          (ref) => defaultTargetPlatform == TargetPlatform.windows
              ? windowsFileTimes()
              : FileStat.stat,
        ),
        // The test has just made every folder: a clock a minute ahead takes
        // them as old.
        naiAgentInventoryCacheProvider.overrideWith(
          (ref) => NaiAgentInventoryCache(
            now: () => DateTime.now().add(const Duration(minutes: 1)),
          ),
        ),
      ],
    );
    writeSkill(h.c.store.builtinSkillsDirectory, 'nai-prompt', 'Built-in');
    writeSkill(h.c.store.globalSkillsDirectory, 'demo', 'Demo skill');
    writeTemplate(h.c.store.globalPromptsDirectory, 'review', 'Review it');
  });
  tearDown(() async => h.dispose());

  /// Skills and templates on the panel's slash menu.
  List<String> listed(WidgetTester tester) => [
    for (final command in h.panel(tester).data.slashCommands)
      if (command.kind != view.AgentSlashCommandKind.builtin)
        '${command.kind.name}:${command.name} ${command.description}',
  ];

  /// Both lists are in, so every Node run this visit needed has started.
  bool listsIn() {
    final id = h.c.selected!.workspace.id;
    final skills = naiAgentSkillsProvider(id);
    final commands = naiAgentCommandsProvider(id);
    return h.container.exists(skills) &&
        h.container.exists(commands) &&
        !h.container.read(skills).isLoading &&
        !h.container.read(commands).isLoading;
  }

  /// Lets the lists' file reads (real I/O) run until both lists are in and
  /// the panel shows what [shown] expects.
  Future<void> settle(WidgetTester tester, bool Function() shown) async {
    bool done() => listsIn() && shown();
    for (var i = 0; i < 300 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(done(), isTrue, reason: 'listed: ${listed(tester)}, ${node.runs}');
  }

  /// Opens another page: the panel, and both list providers, go.
  Future<void> leave(WidgetTester tester) async {
    await h.pump(tester, child: const SizedBox());
    final id = h.c.selected!.workspace.id;
    expect(h.container.exists(naiAgentSkillsProvider(id)), isFalse);
    expect(h.container.exists(naiAgentCommandsProvider(id)), isFalse);
  }

  testWidgets(
    'coming back to the generation page five times lists skills and commands '
    'once; the panel shows the same lists each time',
    (tester) async {
      await h.pump(tester);
      await settle(tester, () => listed(tester).length == 3);
      final first = listed(tester);
      expect(first, [
        // Built-ins first, with the localized summary.
        startsWith('skill:nai-prompt '),
        'skill:demo Demo skill',
        'template:review Review it',
      ]);
      for (var i = 0; i < 5; i++) {
        await leave(tester);
        await h.pump(tester);
        await settle(tester, () => listed(tester).length == first.length);
        expect(listed(tester), first);
      }
      expect((node.skillRuns, node.commandRuns), (1, 1));
      expect(
        p.basename(node.runs.first.executable),
        defaultTargetPlatform == TargetPlatform.windows ? 'node.exe' : 'node',
      );
    },
    variant: platforms,
  );

  testWidgets(
    'a skill or template added while away is listed on return; a refresh on '
    'the page lists both again',
    (tester) async {
      await h.pump(tester);
      await settle(tester, () => listed(tester).length == 3);

      await leave(tester);
      writeSkill(h.c.store.globalSkillsDirectory, 'added', 'Added skill');
      await h.pump(tester);
      await settle(
        tester,
        () => listed(tester).contains('skill:added Added skill'),
      );
      expect((node.skillRuns, node.commandRuns), (2, 1));

      await leave(tester);
      writeTemplate(h.c.selected!.workspace.prompts, 'draft', 'Draft it');
      await h.pump(tester);
      await settle(
        tester,
        () => listed(tester).contains('template:draft Draft it'),
      );
      expect((node.skillRuns, node.commandRuns), (2, 2));

      // What the settings page does after importing a skill, while the panel
      // stays open.
      writeSkill(h.c.store.globalSkillsDirectory, 'imported', 'Imported');
      h.container.read(naiAgentSkillRevisionProvider.notifier).state++;
      await settle(
        tester,
        () => listed(tester).contains('skill:imported Imported'),
      );
      expect((node.skillRuns, node.commandRuns), (3, 3));
    },
    variant: platforms,
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_commands_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_inventory_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  // macOS CI prepares these dependencies before this suite. Other checkouts
  // can opt in with npm ci in tool/nai_agent and NAI_AGENT_NODE if needed.
  final runtimePresent = File(
    'tool/nai_agent/node_modules/@earendil-works/pi-coding-agent/package.json',
  ).existsSync();
  group(
    'local package inventory on returning to Agent',
    () {
      late Directory root, package;
      late AgentWorkspace workspace;
      late ProviderContainer container;

      Future<void> write(String name, String text) async {
        final file = File(p.join(package.path, name));
        await file.parent.create(recursive: true);
        await file.writeAsString(text);
      }

      String skill(String name, String description) =>
          '---\nname: $name\ndescription: $description\n---\nLocal fixture.\n';
      String prompt(String description) =>
          '---\ndescription: $description\n---\nLocal fixture.\n';
      Future<void> manifest(String skills, String prompts) => write(
        'package.json',
        jsonEncode({
          'name': 'local-fixture',
          'version': '1.0.0',
          'pi': {
            'skills': ['./$skills'],
            'prompts': ['./$prompts'],
          },
        }),
      );

      setUp(() async {
        root = await Directory.systemTemp.createTemp('package-inventory-');
        package = Directory(p.join(root.path, 'local package'));
        final store = AgentWorkspaceStore(
          Directory(p.join(root.path, 'agent-data')),
          builtinSkillsDirectory: Directory(p.join(root.path, 'no-builtins')),
        );
        workspace = await store.createWorkspace('Synthetic workspace');
        await write('skills/original/SKILL.md', skill('original', 'Before'));
        await write('prompts/original.md', prompt('Before'));
        await manifest('skills', 'prompts');
        final probe = await Process.run(
          Platform.environment['NAI_AGENT_NODE'] ?? 'node',
          ['-p', 'process.execPath'],
        );
        expect(probe.exitCode, 0);
        final preferences = NaiAgentUiPreferences()
          ..replace(
            AgentSettings(
              packages: [
                AgentPackageConfig(
                  source: package.path,
                  workspaceId: workspace.id,
                ),
              ],
            ),
          );
        container = ProviderContainer(
          overrides: [
            naiAgentWorkspaceStoreProvider.overrideWithValue(store),
            naiAgentRuntimePathsProvider.overrideWithValue(
              NaiAgentRuntimePaths(
                node: (probe.stdout as String).trim(),
                host: p.absolute('tool/nai_agent/host.mjs'),
              ),
            ),
            naiAgentUiPreferencesProvider.overrideWith((_) => preferences),
            naiAgentInventoryCacheProvider.overrideWith(
              (_) => NaiAgentInventoryCache(
                now: () => DateTime.now().add(const Duration(minutes: 1)),
              ),
            ),
          ],
        );
      });
      tearDown(() async {
        container.dispose();
        await root.delete(recursive: true);
      });

      Future<(NaiAgentSkillInventory, List<Map<String, dynamic>>)>
      visit() async {
        final skills = naiAgentSkillsProvider(workspace.id);
        final commands = naiAgentCommandsProvider(workspace.id);
        final watching = [
          container.listen(skills, (_, _) {}),
          container.listen(commands, (_, _) {}),
        ];
        final result = (
          await container.read(skills.future),
          await container.read(commands.future),
        );
        for (final subscription in watching) {
          subscription.close();
        }
        await container.pump();
        expect(container.exists(skills), isFalse);
        expect(container.exists(commands), isFalse);
        return result;
      }

      test(
        'edits to the original SKILL.md are visible on the next visit',
        () async {
          expect((await visit()).$1.skills.single.description, 'Before');
          await write('skills/original/SKILL.md', skill('original', 'After'));
          expect((await visit()).$1.skills.single.description, 'After');
        },
      );

      test('edits to a package prompt are visible on the next visit', () async {
        expect((await visit()).$2.single['description'], 'Before');
        await write('prompts/original.md', prompt('After'));
        expect((await visit()).$2.single['description'], 'After');
      });

      test(
        'manifest changes replace both lists without an explicit refresh',
        () async {
          await visit();
          await write(
            'new-skills/replacement/SKILL.md',
            skill('replacement', 'New skill'),
          );
          await write('new-prompts/replacement.md', prompt('New prompt'));
          await manifest('new-skills', 'new-prompts');
          final result = await visit();
          expect(result.$1.skills.map((item) => item.name), ['replacement']);
          expect(result.$2.map((item) => item['name']), ['replacement']);
        },
      );
    },
    skip: runtimePresent
        ? false
        : 'requires the installed Agent Node dependencies',
  );
}

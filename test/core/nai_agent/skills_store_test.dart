import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late AgentWorkspaceStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('agent-skills-');
    final builtin = Directory(p.join(root.path, 'runtime', 'skills'));
    await Directory(
      p.join(builtin.path, 'nai-studio', 'references'),
    ).create(recursive: true);
    await File(p.join(builtin.path, 'nai-studio', 'SKILL.md')).writeAsString(
      '---\nname: nai-studio\ndescription: Studio.\n---\nBUILTIN',
    );
    await File(
      p.join(builtin.path, 'nai-studio', 'references', 'a.md'),
    ).writeAsString('A');
    store = AgentWorkspaceStore(
      Directory(p.join(root.path, 'agent-data')),
      builtinSkillsDirectory: builtin,
    );
  });
  tearDown(() => root.delete(recursive: true));

  test('settings keep only valid user skill switches and modes', () async {
    final settings = AgentSettings.fromJson({
      'disabledSkills': [
        'global/a',
        'builtin/nai-studio',
        'bad',
        'global/../x',
        3,
        'global/a',
      ],
      'skillModes': {
        'workspace/b': 'manual',
        'global/c': 'sometimes',
        'nope': 'auto',
      },
    });
    expect(settings.disabledSkills, ['global/a']);
    expect(settings.skillModes, {'workspace/b': 'manual'});
    expect(
      AgentSettings.fromJson(settings.toJson()).toJson(),
      settings.toJson(),
    );
    final changed = AgentSettings.fromJson({
      ...settings.toJson(),
      'skillModes': {},
    });
    expect(changed.extensionSignature, isNot(settings.extensionSignature));
  });

  test(
    'configure, import, create, copy and remove act only on user folders',
    () async {
      final workspace = await store.createWorkspace('W');
      expect(await workspace.skills.exists(), isTrue);

      await store.configureSkill('global/mine', enabled: false);
      await store.configureSkill('global/mine', mode: 'manual');
      var settings = await store.readSettings();
      expect(settings.disabledSkills, ['global/mine']);
      expect(settings.skillModes, {'global/mine': 'manual'});
      await expectLater(
        store.configureSkill('builtin/nai-studio', enabled: false),
        throwsFormatException,
      );
      await store.configureSkill('builtin/nai-studio', mode: 'manual');

      final source = Directory(p.join(root.path, 'outside', 'style-replica'));
      await Directory(p.join(source.path, 'refs')).create(recursive: true);
      await File(
        p.join(source.path, 'SKILL.md'),
      ).writeAsString('---\nname: style-replica\ndescription: S.\n---\n');
      await File(p.join(source.path, 'refs', 'x.md')).writeAsString('X');
      await Directory(p.join(source.path, '.git')).create();
      await File(p.join(source.path, '.git', 'HEAD')).writeAsString('ref');
      expect(
        await store.importSkill(
          source.path,
          source: 'workspace',
          workspaceId: workspace.id,
        ),
        'style-replica',
      );
      final copied = Directory(p.join(workspace.skills.path, 'style-replica'));
      expect(
        await File(p.join(copied.path, 'refs', 'x.md')).readAsString(),
        'X',
      );
      expect(await Directory(p.join(copied.path, '.git')).exists(), isFalse);
      await expectLater(
        store.importSkill(
          source.path,
          source: 'workspace',
          workspaceId: workspace.id,
        ),
        throwsA(isA<AgentSkillExists>()),
      );
      final noSkill = await Directory(
        p.join(root.path, 'outside', 'empty'),
      ).create();
      await expectLater(
        store.importSkill(noSkill.path, source: 'global'),
        throwsFormatException,
      );
      await expectLater(
        store.importSkill(source.path, source: 'builtin'),
        throwsFormatException,
      );

      expect(await store.createSkill('my-skill', source: 'global'), 'my-skill');
      expect(
        await File(
          p.join(store.globalSkillsDirectory.path, 'my-skill', 'SKILL.md'),
        ).readAsString(),
        contains('name: my-skill'),
      );
      await expectLater(
        store.createSkill('Bad_Name', source: 'global'),
        throwsFormatException,
      );

      expect(await store.copyBuiltinSkill('nai-studio'), 'nai-studio');
      expect(
        await File(
          p.join(
            store.globalSkillsDirectory.path,
            'nai-studio',
            'references',
            'a.md',
          ),
        ).readAsString(),
        'A',
      );
      await expectLater(
        store.copyBuiltinSkill('nai-studio'),
        throwsA(isA<AgentSkillExists>()),
      );

      await store.configureSkill('workspace/style-replica', enabled: false);
      settings = await store.removeSkill(
        'workspace/style-replica',
        workspaceId: workspace.id,
      );
      expect(await copied.exists(), isFalse);
      expect(
        settings.disabledSkills,
        isNot(contains('workspace/style-replica')),
      );
      final trash = Directory(
        p.join(store.root.path, 'skill-trash'),
      ).listSync();
      expect(trash.single.path, endsWith('workspace-style-replica'));
      await expectLater(
        store.removeSkill('builtin/nai-studio'),
        throwsFormatException,
      );
      expect(
        await File(
          p.join(store.builtinSkillsDirectory.path, 'nai-studio', 'SKILL.md'),
        ).exists(),
        isTrue,
      );
    },
  );

  test(
    'host config names all three sources; prompt no longer points at manuals',
    () async {
      final workspace = await store.createWorkspace('W');
      await store.configureSkill('global/x', enabled: false);
      final settings = await store.readSettings();
      final config = store.skillConfig(workspace, settings);
      expect(
        config['builtinDirectory'],
        store.builtinSkillsDirectory.absolute.path,
      );
      expect(
        config['globalDirectory'],
        p.join(store.root.absolute.path, 'skills'),
      );
      expect(config['workspaceDirectory'], workspace.skills.absolute.path);
      expect(config['disabled'], ['global/x']);
      final prompt = await store.effectiveSystemPrompt(workspace.id);
      expect(prompt, contains('nai-studio skill'));
      expect(prompt, isNot(contains('manuals')));
      expect(prompt, isNot(contains('Tool map')));
    },
  );
}

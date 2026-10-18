import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_skills_provider.dart';

void main() {
  NaiAgentSkill skill(String name, String source) => NaiAgentSkill(
    key: '$source/$name',
    name: name,
    source: source,
    state: 'active',
    description: 'SKILL.md text',
  );

  test('built-in skills show the localized summary, others keep SKILL.md', () {
    final zh = lookupAppLocalizations(const Locale('zh'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      skill('nai-prompt', 'builtin').displayDescription(zh),
      zh.set_agSkillDescNaiPrompt,
    );
    expect(
      skill('nai-studio', 'builtin').displayDescription(zh),
      zh.set_agSkillDescNaiStudio,
    );
    expect(zh.set_agSkillDescNaiPrompt, isNot(en.set_agSkillDescNaiPrompt));
    // A user copy with the same name shows its own description.
    expect(
      skill('nai-prompt', 'global').displayDescription(zh),
      'SKILL.md text',
    );
    expect(skill('unknown', 'builtin').displayDescription(zh), 'SKILL.md text');
  });

  test('English summaries mirror the shipped SKILL.md descriptions', () {
    final en = lookupAppLocalizations(const Locale('en'));
    for (final (name, text) in [
      ('nai-prompt', en.set_agSkillDescNaiPrompt),
      ('nai-studio', en.set_agSkillDescNaiStudio),
    ]) {
      final file = 'tool/nai_agent/skills/$name/SKILL.md';
      final line = RegExp(
        r'^description: (.*)$',
        multiLine: true,
      ).firstMatch(File(file).readAsStringSync())!.group(1)!.trim();
      expect(text, line, reason: file);
    }
  });
}

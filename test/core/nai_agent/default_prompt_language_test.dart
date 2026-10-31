import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/app_language.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';

void main() {
  late Directory root;
  late AgentWorkspaceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-prompt-lang-');
    store = AgentWorkspaceStore(root);
  });
  tearDown(() async {
    setCurrentL10nLocale(const Locale('zh'));
    await root.delete(recursive: true);
  });

  test('built-in prompt is Chinese for zh / zh_TW and English otherwise', () {
    final zh = naiAgentDefaultSystemPromptFor(AppLanguage.simplifiedChinese);
    expect(zh, startsWith('你是 NAI Agent'));
    expect(naiAgentDefaultSystemPromptFor(AppLanguage.traditionalChinese), zh);
    for (final language in [
      AppLanguage.english,
      AppLanguage.japanese,
      AppLanguage.korean,
    ]) {
      final text = naiAgentDefaultSystemPromptFor(language);
      expect(text, startsWith('You are NAI Agent'));
      expect(text, isNot(matches(RegExp(r'[\u4e00-\u9fff]'))));
      // Same tool names and skills as the Chinese text.
      for (final token in [
        'studio_context',
        'mcp__nai_studio',
        'nai-studio skill',
        'nai-prompt skill',
        'ask_user',
      ]) {
        expect(text, contains(token));
        expect(zh, contains(token));
      }
    }
  });

  test('built-in prompt stays general: no defensive fallback lines', () {
    final zh = naiAgentDefaultSystemPromptFor(AppLanguage.simplifiedChinese);
    final en = naiAgentDefaultSystemPromptFor(AppLanguage.english);
    expect(zh, contains('通用助手'));
    expect(zh, contains('可以用 ask_user'));
    expect(zh, isNot(contains('不把')));
    expect(zh, isNot(contains('缺关键输入')));
    expect(en, contains('general-purpose'));
    expect(en, isNot(contains('Never report')));
    expect(en, isNot(contains('key input is missing')));
  });

  test(
    'effective prompt follows the interface language; custom text kept',
    () async {
      final workspace = await store.createWorkspace('w');
      await File(
        '${workspace.agentDirectory.path}/instructions.md',
      ).writeAsString('RULE');
      await store.patchSettings({'globalInstructions': 'GLOBAL'});

      setCurrentL10nLocale(const Locale('en'));
      final en = await store.effectiveSystemPrompt(workspace.id);
      expect(en, startsWith('You are NAI Agent'));
      expect(en, contains('User global instructions:\nGLOBAL'));
      expect(en, contains('User workspace rules:\nRULE'));
      expect(en, isNot(matches(RegExp(r'[\u4e00-\u9fff]'))));

      setCurrentL10nLocale(const Locale('zh'));
      final zh = await store.effectiveSystemPrompt(workspace.id);
      expect(zh, startsWith('你是 NAI Agent'));
      expect(zh, contains('用户的全局指令：\nGLOBAL'));
      expect(zh, contains('用户的工作区规则：\nRULE'));

      await store.patchSettings({'customSystemPrompt': 'MY OWN BASE'});
      setCurrentL10nLocale(const Locale('en'));
      final custom = await store.effectiveSystemPrompt(workspace.id);
      expect(custom, startsWith('MY OWN BASE'));
      expect(custom, isNot(contains('You are NAI Agent')));
    },
  );
}

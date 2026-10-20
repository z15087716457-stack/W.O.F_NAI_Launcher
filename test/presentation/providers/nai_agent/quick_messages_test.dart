import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations_en.dart';
import 'package:nai_launcher/l10n/app_localizations_zh.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_quick_messages.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent/agent_quick.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('quick-'));
  tearDown(() => dir.delete(recursive: true));

  test('defaults follow the UI language until edited', () {
    final zh = agentQuickItems(AppLocalizationsZh(), naiAgentQuickDefaults);
    final en = agentQuickItems(AppLocalizationsEn(), naiAgentQuickDefaults);
    expect(zh.first.title, '检查草稿');
    expect(en.first.title, isNot('检查草稿'));
    final edited = naiAgentQuickDefaults.first.copyWith(
      title: '我的检查',
      prompt: '只看负面',
    );
    final items = agentQuickItems(AppLocalizationsEn(), [edited]);
    expect(items.single.title, '我的检查', reason: '改过的不再翻译');
    // 内容为空的条目不上欢迎页。
    expect(
      agentQuickItems(AppLocalizationsZh(), const [
        NaiAgentQuickMessage(id: 'x', title: 'only title'),
      ]),
      isEmpty,
    );
  });

  test(
    'store saves, reorders, removes, restores and survives bad files',
    () async {
      final file = File('${dir.path}/quick-messages.json');
      final store = NaiAgentQuickMessages(file);
      await store.load();
      expect(store.items, naiAgentQuickDefaults);
      const mine = NaiAgentQuickMessage(
        id: 'mine',
        icon: 'wand',
        title: 'Watercolor',
        prompt: 'make it watercolor',
        send: true,
      );
      await store.upsert(mine);
      await store.move('mine', 0);
      await store.remove('builtin-blocks');
      final reloaded = NaiAgentQuickMessages(file);
      await reloaded.load();
      expect(reloaded.items.first, mine);
      expect(reloaded.items.map((m) => m.id), [
        'mine',
        'builtin-review',
        'builtin-analyze',
        'builtin-variants',
      ]);
      await reloaded.restoreDefaults();
      expect(
        (jsonDecode(await file.readAsString()) as Map)['items'],
        hasLength(4),
      );
      await file.writeAsString('{not json');
      final broken = NaiAgentQuickMessages(file);
      await broken.load();
      expect(broken.items, naiAgentQuickDefaults);
    },
  );
}

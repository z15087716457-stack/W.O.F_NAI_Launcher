import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_activity.dart';

Future<void> _pump(WidgetTester tester, Widget child, {bool still = false}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: GeistTheme.light,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, c) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: still),
          child: c!,
        ),
        home: Scaffold(body: Center(child: child)),
      ),
    );

String _slogan(WidgetTester tester) => tester
    .widgetList<Text>(find.byKey(const Key('agent-live-slogan')))
    .last
    .data!;

void main() {
  test('tool names map to activity kinds', () {
    expect(agentActivityKind('studio_context'), AgentActivityKind.read);
    expect(agentActivityKind('bash'), AgentActivityKind.run);
    expect(agentActivityKind('mcp__codemode'), AgentActivityKind.run);
    expect(agentActivityKind('image_read'), AgentActivityKind.image);
    expect(agentActivityKind('prompt_update'), AgentActivityKind.write);
    expect(agentActivityKind('image_generate'), AgentActivityKind.gen);
    expect(agentActivityKind('ask_user'), AgentActivityKind.ask);
    expect(agentActivityKind('krita__push'), AgentActivityKind.external);
  });

  testWidgets('working line rotates slogans, shows elapsed and follows kind', (
    tester,
  ) async {
    final since = DateTime.now().subtract(const Duration(seconds: 65));
    await _pump(
      tester,
      AgentWorkingLine(
        kind: AgentActivityKind.gen,
        since: since,
        random: math.Random(1),
      ),
    );
    await tester.pump();
    final l = await AppLocalizations.delegate.load(const Locale('zh'));
    final all = {
      for (final raw in [
        l.ag_sloganBase,
        l.ag_sloganEgg,
        l.ag_sloganGen,
        l.ag_sloganThink,
      ])
        ...raw.split('\n'),
    };
    final first = _slogan(tester);
    expect(all, contains(first));
    expect(
      tester.widget<Text>(find.byKey(const Key('agent-live-elapsed'))).data,
      startsWith('· 1m 0'),
    );
    final seen = {first};
    for (var i = 0; i < 6; i++) {
      await tester.pump(AgentWorkingLine.interval);
      await tester.pump(const Duration(milliseconds: 300));
      final s = _slogan(tester);
      expect(all, contains(s));
      seen.add(s);
    }
    expect(seen.length, greaterThan(3), reason: 'rotates without repeats');
    // 换成思考：马上换一句。
    await _pump(
      tester,
      AgentWorkingLine(
        kind: AgentActivityKind.think,
        since: since,
        random: math.Random(1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(all, contains(_slogan(tester)));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion: static star, no timers', (tester) async {
    await _pump(
      tester,
      const AgentWorkingLine(kind: null, since: null),
      still: true,
    );
    final first = _slogan(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(_slogan(tester), first);
    expect(find.byKey(const Key('agent-live-elapsed')), findsNothing);
  });

  testWidgets('activity icons animate while running and settle when done', (
    tester,
  ) async {
    for (final kind in AgentActivityKind.values) {
      await _pump(
        tester,
        AgentActivityIcon(kind: kind, state: AgentActivityState.running),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: kind.name);
      await _pump(
        tester,
        AgentActivityIcon(kind: kind, state: AgentActivityState.done),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('agent-activity-${kind.name}-done')),
        findsOneWidget,
      );
    }
    await _pump(
      tester,
      const AgentActivityIcon(
        kind: AgentActivityKind.ask,
        state: AgentActivityState.waiting,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

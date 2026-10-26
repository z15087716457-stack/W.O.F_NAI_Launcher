// C03：原 40 格不变；「更多」展开新增图标，NSFW 默认隐藏，点 18+ 才出现；选中项在隐藏组时自动展开。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';

Future<List<String?>> _pump(WidgetTester t, {String? selected}) async {
  final picked = <String?>[];
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: BlockIconGrid(
            selected: selected,
            color: Colors.orange,
            onChanged: picked.add,
          ),
        ),
      ),
    ),
  );
  return picked;
}

void main() {
  testWidgets('更多 → 新增图标；18+ → NSFW', (t) async {
    final picked = await _pump(t);
    expect(find.byKey(const Key('block-icon-palette')), findsOneWidget);
    expect(find.byKey(const Key('block-icon-crown')), findsNothing);
    await t.tap(find.byKey(const Key('block-icon-more')));
    await t.pump();
    expect(find.byKey(const Key('block-icon-crown')), findsOneWidget);
    expect(find.byKey(const Key('block-icon-bed')), findsNothing);
    await t.tap(find.byKey(const Key('block-icon-nsfw')));
    await t.pump();
    expect(find.byKey(const Key('block-icon-bed')), findsOneWidget);
    await t.tap(find.byKey(const Key('block-icon-r18')));
    expect(picked, ['r18']);
    await t.tap(find.byKey(const Key('block-icon-more')));
    await t.pump();
    expect(find.byKey(const Key('block-icon-crown')), findsNothing);
    expect(find.byKey(const Key('block-icon-bed')), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('选中的是 NSFW 图标时直接展开', (t) async {
    await _pump(t, selected: 'collar');
    expect(find.byKey(const Key('block-icon-collar')), findsOneWidget);
  });
}

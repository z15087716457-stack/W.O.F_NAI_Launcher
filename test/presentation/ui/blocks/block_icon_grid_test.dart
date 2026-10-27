// C03（10-27 用户确认）：一个网格装下全部图标（原 40 → 新增 → NSFW），不折叠不隐藏；
// 网格内部滚动，可见约 4.5 行；选中项在下面时打开就滚到可见。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_extra_icons.dart';

Future<List<String?>> _pump(WidgetTester t, {String? selected}) async {
  final picked = <String?>[];
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: BlockIconGrid(
            selected: selected,
            color: Colors.orange,
            onChanged: picked.add,
          ),
        ),
      ),
    ),
  );
  await t.pump();
  return picked;
}

bool _visible(WidgetTester t, String key) {
  final f = find.byKey(Key('block-icon-$key'));
  if (f.evaluate().isEmpty) return false;
  final view = t.getRect(find.byKey(const Key('block-icon-scroll')));
  return view.overlaps(t.getRect(f));
}

void main() {
  testWidgets('全部图标同一网格，无折叠格；NSFW 在最后', (t) async {
    await _pump(t);
    expect(find.byKey(const Key('block-icon-more')), findsNothing);
    expect(find.byKey(const Key('block-icon-nsfw')), findsNothing);
    for (final k in UiBlockIcon.keys) {
      expect(find.byKey(Key('block-icon-$k')), findsOneWidget, reason: k);
    }
    final lastLegacy = t.getRect(
      find.byKey(Key('block-icon-${UiBlockIcon.legacyKeys.last}')),
    );
    final firstNsfw = UiBlockIcon.keys.firstWhere(UiExtraIcons.nsfw.contains);
    final lastExtra = UiBlockIcon.keys.lastWhere(
      (k) =>
          !UiBlockIcon.legacyKeys.contains(k) && !UiExtraIcons.nsfw.contains(k),
    );
    final nsfw = t.getRect(find.byKey(Key('block-icon-$firstNsfw')));
    final extra = t.getRect(find.byKey(Key('block-icon-$lastExtra')));
    expect(extra.top, greaterThan(lastLegacy.top));
    expect(
      nsfw.top > extra.top || (nsfw.top == extra.top && nsfw.left > extra.left),
      isTrue,
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('可见约 4.5 行，滚轮在网格内部滚动', (t) async {
    final picked = await _pump(t);
    final view = t.getRect(find.byKey(const Key('block-icon-scroll')));
    expect(view.height, BlockIconGrid.viewport);
    final firstNsfw = UiBlockIcon.keys.firstWhere(UiExtraIcons.nsfw.contains);
    expect(_visible(t, firstNsfw), isFalse);
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    for (var i = 0; i < 6; i++) {
      await t.sendEventToBinding(pointer.hover(view.center));
      await t.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
      await t.pump();
    }
    expect(_visible(t, firstNsfw), isTrue);
    await t.tap(find.byKey(Key('block-icon-$firstNsfw')));
    expect(picked, [firstNsfw]);
    expect(t.takeException(), isNull);
  });

  testWidgets('选中的图标在下面时，打开即滚到可见', (t) async {
    final last = UiBlockIcon.keys.last;
    await _pump(t, selected: last);
    expect(_visible(t, last), isTrue);
    expect(_visible(t, 'palette'), isFalse);
  });
}

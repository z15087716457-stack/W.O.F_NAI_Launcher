// 弹层：宿主重建时锚点按值比较，淡入不重放（设置页 Skill 菜单曾因此一直闪）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_popover.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_scale.dart';

void main() {
  testWidgets(
    'scaled popover anchors and hit targets share overlay coordinates',
    (t) async {
      for (final scale in [.8, 1.3, 1.5]) {
        await t.pumpWidget(const SizedBox());
        UiPopoverAnchor? anchor;
        var picks = 0;
        await t.pumpWidget(
          MaterialApp(
            builder: (_, child) => UiScale(scale: scale, child: child!),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, rebuild) => UiPopover(
                  anchor: anchor,
                  onDismiss: () => rebuild(() => anchor = null),
                  builder: (_) => GestureDetector(
                    key: const Key('pick'),
                    onTap: () => picks++,
                    child: const SizedBox(
                      width: 100,
                      height: 40,
                      child: Text('Pick'),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Builder(
                      builder: (button) => TextButton(
                        key: const Key('trigger'),
                        onPressed: () {
                          final box = button.findRenderObject()! as RenderBox;
                          rebuild(
                            () => anchor = UiPopoverAnchor(
                              box.localToGlobal(Offset(0, box.size.height)),
                            ),
                          );
                        },
                        child: const Text('Open'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.byKey(const Key('trigger')));
        await t.pumpAndSettle();
        final popup = t.getRect(find.byKey(const Key('pick')));
        final trigger = t.getRect(find.byKey(const Key('trigger')));
        expect(popup.topLeft.dx, closeTo(trigger.left, .001));
        expect(popup.topLeft.dy, closeTo(trigger.bottom, .001));
        expect(popup.width, closeTo(100 * scale, .001));
        await t.tapAt(popup.center);
        expect(picks, 1);
        expect(t.takeException(), isNull);
      }
    },
  );
  test('anchors compare by value', () {
    expect(
      const UiPopoverAnchor(Offset(10, 20), alignRight: true),
      UiPopoverAnchor(const Offset(10, 20) + Offset.zero, alignRight: true),
    );
    expect(
      const UiPopoverAnchor(Offset(10, 20)) ==
          const UiPopoverAnchor(Offset(10, 20), alignRight: true),
      isFalse,
    );
  });

  testWidgets('host rebuild with an equal anchor keeps the fade going', (
    t,
  ) async {
    late StateSetter rebuild;
    var y = 100.0;
    await t.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return UiPopover(
              // 每次重建都新建一个锚点，模拟设置页外层刷新。
              anchor: UiPopoverAnchor(Offset(100, y)),
              onDismiss: () {},
              builder: (_) => const Text('menu', key: Key('menu')),
              child: const SizedBox(width: 20, height: 20),
            );
          },
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    double opacity() => t
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const Key('menu')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    final before = opacity();
    expect(before, greaterThan(.5));
    for (var i = 0; i < 5; i++) {
      rebuild(() => y = 100);
      await t.pump(const Duration(milliseconds: 16));
      expect(opacity(), greaterThanOrEqualTo(before), reason: 'frame $i');
    }
    await t.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('anchor drift while open does not replay; reopening does', (
    t,
  ) async {
    UiPopoverAnchor? anchor = const UiPopoverAnchor(Offset(100, 100));
    late StateSetter rebuild;
    await t.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return UiPopover(
              anchor: anchor,
              onDismiss: () {},
              builder: (_) => const Text('menu', key: Key('menu')),
              child: const SizedBox(width: 20, height: 20),
            );
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    double opacity() => t
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const Key('menu')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    rebuild(() => anchor = const UiPopoverAnchor(Offset(100.4, 101)));
    await t.pump();
    expect(opacity(), 1);
    rebuild(() => anchor = null);
    await t.pump();
    rebuild(() => anchor = const UiPopoverAnchor(Offset(100, 100)));
    await t.pump();
    await t.pump();
    expect(opacity(), lessThan(1));
  });
}

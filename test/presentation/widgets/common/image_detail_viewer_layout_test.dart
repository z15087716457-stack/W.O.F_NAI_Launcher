import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/viewer_stage.dart';
import '../library/library_test_helpers.dart';

void main() {
  testWidgets('a data-independent stage keeps top, page and filmstrip apart', (
    tester,
  ) async {
    await pumpLibrary(tester, const _FakePage());
    final top = tester.getRect(find.byKey(const Key('viewer-top-slot')));
    final page = tester.getRect(find.byKey(const Key('viewer-pages')));
    final film = tester.getRect(find.byKey(const Key('viewer-filmstrip-slot')));
    expect(top.height, 52);
    expect(film.height, 82);
    expect(page.top, top.bottom + 8);
    expect(page.bottom, film.top - 14);
    expect(page.overlaps(top), isFalse);
    expect(page.overlaps(film), isFalse);
    expect(find.byKey(const Key('viewer-previous')), findsNothing);
    expect(find.byKey(const Key('viewer-next')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('viewer-panel-dock'))).width,
      360,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('viewer-panel-dock'))).width, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('viewer-panel-dock'))).width,
      360,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'narrow drawer defaults closed; escape closes drawer before page',
    (tester) async {
      var escaped = 0;
      await pumpLibrary(
        tester,
        _FakePage(onEscape: () => escaped++),
        size: const Size(1100, 800),
      );
      expect(find.byKey(const Key('viewer-panel-drawer')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.pumpAndSettle();
      final drawer = tester.getRect(
        find.byKey(const Key('viewer-panel-drawer')),
      );
      expect(drawer.width, 340);
      expect(drawer.top, 52);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('viewer-panel-drawer')), findsNothing);
      expect(escaped, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(escaped, 1);
    },
  );
  testWidgets('single page omits filmstrip and arrows', (tester) async {
    await pumpLibrary(tester, const _FakePage(count: 1));
    expect(find.byKey(const Key('viewer-filmstrip-slot')), findsNothing);
    expect(find.byKey(const Key('viewer-next')), findsNothing);
    expect(find.byKey(const Key('viewer-previous')), findsNothing);
  });
  testWidgets(
    'navigation stays bounded and page shortcuts can override arrows',
    (tester) async {
      await pumpLibrary(tester, const _FakePage());
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('page 2'), findsOneWidget);
      expect(find.byKey(const Key('viewer-next')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
      var extra = 0;
      await pumpLibrary(
        tester,
        _FakePage(
          extraShortcuts: {
            const SingleActivator(LogicalKeyboardKey.arrowRight): () => extra++,
          },
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(extra, 1);
      expect(find.text('page 0'), findsOneWidget);
    },
  );
}

class _FakePage extends StatefulWidget {
  const _FakePage({
    this.count = 3,
    this.onEscape,
    this.extraShortcuts = const {},
  });
  final int count;
  final VoidCallback? onEscape;
  final Map<ShortcutActivator, VoidCallback> extraShortcuts;
  @override
  State<_FakePage> createState() => _FakePageState();
}

class _FakePageState extends State<_FakePage> {
  int index = 0;
  @override
  Widget build(BuildContext context) => ViewerStage(
    itemCount: widget.count,
    currentIndex: index,
    onIndexChanged: (value) => setState(() => index = value),
    pageBuilder: (_, i) => Center(child: Text('page $i')),
    topBar: const ColoredBox(color: Colors.black, child: Text('top')),
    filmstrip: widget.count > 1 ? const Text('film') : null,
    panel: const ColoredBox(color: Colors.white, child: Text('information')),
    onEscape: widget.onEscape,
    extraShortcuts: widget.extraShortcuts,
  );
}

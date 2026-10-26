import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_windows_host.dart';
import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;

Widget testWindow(
  BuildContext context,
  FloatingWindowData window,
  FloatingWindowController controller,
) => ColoredBox(
  key: ValueKey('window-${window.id}'),
  color: Colors.white,
  child: Column(
    children: [
      controller.moveHandle(
        key: ValueKey('move-${window.id}'),
        child: const SizedBox(height: 32, width: double.infinity),
      ),
      Row(
        children: [
          GestureDetector(
            key: ValueKey('close-${window.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: controller.close,
            child: const SizedBox(width: 32, height: 32),
          ),
          GestureDetector(
            key: ValueKey('min-${window.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.setMinimized(!window.minimized),
            child: const SizedBox(width: 32, height: 32),
          ),
        ],
      ),
      if (!window.minimized) ...[
        const Spacer(),
        Align(
          alignment: Alignment.bottomRight,
          child: controller.resizeHandle(
            key: ValueKey('resize-${window.id}'),
            child: const SizedBox(width: 32, height: 32),
          ),
        ),
      ],
    ],
  ),
);

void main() {
  late ProviderContainer container;
  late FloatingResourceWindows manager;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryWindowSettings()),
        floatingResourceWindowsProvider.overrideWith(
          FloatingResourceWindows.new,
        ),
      ],
    );
    manager = container.read(floatingResourceWindowsProvider.notifier);
  });
  tearDown(() {
    container.dispose();
  });
  Widget app({FloatingResourceWindowBuilder builder = testWindow}) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) =>
              FloatingResourceWindowsHost(builder: builder, child: child!),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    key: const Key('navigate'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(body: Text('next page')),
                      ),
                    ),
                    child: const Text('next'),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const Key('underlay'),
                    onPressed: () => manager.open(FloatingResourceKind.blocks),
                    child: const Text('underlay'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  testWidgets(
    'non-modal host gestures move/resize/focus/close and allow underlay clicks',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final a = manager.open(FloatingResourceKind.gallery)!;
      final b = manager.open(FloatingResourceKind.vibe)!;
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('move-$a')));
      await tester.pump();
      expect(container.read(floatingResourceWindowsProvider).last.id, a);
      final before = container.read(floatingResourceWindowsProvider).last.rect;
      await tester.drag(find.byKey(ValueKey('move-$a')), const Offset(100, 80));
      await tester.pump();
      final moved = container.read(floatingResourceWindowsProvider).last.rect;
      expect(moved.left, greaterThan(before.left));
      expect(moved.top, greaterThan(before.top));
      await tester.drag(
        find.byKey(ValueKey('resize-$a')),
        const Offset(50, 45),
      );
      await tester.pump();
      final resized = container.read(floatingResourceWindowsProvider).last.rect;
      expect(resized.width, greaterThan(moved.width));
      expect(resized.height, greaterThan(moved.height));
      await tester.tap(find.byKey(ValueKey('close-$a')));
      await tester.pump();
      expect(find.byKey(ValueKey('window-$a')), findsNothing);
      expect(container.read(floatingResourceWindowsProvider).single.id, b);
      await tester.tap(find.byKey(const Key('underlay')));
      await tester.pump();
      expect(container.read(floatingResourceWindowsProvider), hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('window and controller survive router child navigation', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final id = manager.open(FloatingResourceKind.precise)!;
    await tester.pump();
    final element = tester.element(find.byKey(ValueKey('window-$id')));
    manager.move(id, const Rect.fromLTWH(200, 200, 400, 360));
    await tester.pump();
    await tester.tap(find.byKey(const Key('navigate')));
    await tester.pumpAndSettle();
    expect(find.text('next page'), findsOneWidget);
    expect(
      identical(tester.element(find.byKey(ValueKey('window-$id'))), element),
      isTrue,
    );
    await tester.tap(find.byKey(ValueKey('close-$id')));
    await tester.pump();
    expect(container.read(floatingResourceWindowsProvider), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'placeholder supports minimize geometry, localization and disposal',
    (tester) async {
      await tester.pumpWidget(app(builder: floatingResourcePlaceholder));
      await tester.pumpAndSettle();
      final id = manager.open(FloatingResourceKind.vibe)!;
      await tester.pump();
      expect(find.text('Vibe Library'), findsOneWidget);
      manager.setMinimized(id, true);
      await tester.pump();
      final box = tester.getRect(find.byType(ColoredBox).last);
      expect(box.height, 32);
      manager.setMinimized(id, false);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

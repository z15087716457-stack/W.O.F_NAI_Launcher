// D04 正式小窗外观：标题/计数、搜索、收起/关闭、缩放手柄、块列表可拖。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_window.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_windows_host.dart';

import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;
import 'floating_resource_sources_test.dart' show Blocks, block;

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
        promptBlockLibraryNotifierProvider.overrideWith(
          () => Blocks(
            PromptBlockLibraryState(
              blocks: [block('sunset'), block('crowd'), block('silver')],
              folders: const [],
            ),
          ),
        ),
      ],
    );
    manager = container.read(floatingResourceWindowsProvider.notifier);
  });
  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester t, {ValueChanged<String?>? dropped}) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1400, 900);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => FloatingResourceWindowsHost(
            builder: floatingResourceWindowBuilder,
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: DragTarget<PromptBlockDragData>(
                onAcceptWithDetails: (d) => dropped?.call(d.data.blockId),
                builder: (context, _, _) => const SizedBox(
                  key: Key('prompt-target'),
                  width: 300,
                  height: 200,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets('块库小窗：标题、计数、搜索过滤、拖到提示词', (t) async {
    String? dropped;
    await pump(t, dropped: (id) => dropped = id);
    final id = manager.open(FloatingResourceKind.blocks)!;
    manager.move(id, const Rect.fromLTWH(600, 100, 320, 360));
    await t.pumpAndSettle();
    expect(find.text('块库'), findsOneWidget);
    expect(find.text('· 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('floating-block-sunset')), findsOneWidget);
    await t.enterText(find.byKey(const Key('floating-search')), 'silver');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('floating-block-sunset')), findsNothing);
    expect(find.text('· 1'), findsOneWidget);
    final row = find.byKey(const ValueKey('floating-block-silver'));
    final g = await t.startGesture(t.getCenter(row));
    await g.moveBy(const Offset(-20, 0));
    await g.moveTo(t.getCenter(find.byKey(const Key('prompt-target'))));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(dropped, 'silver');
    expect(t.takeException(), isNull);
  });

  testWidgets('收起为标题条、展开、缩放、关闭', (t) async {
    await pump(t);
    final id = manager.open(FloatingResourceKind.blocks)!;
    manager.move(id, const Rect.fromLTWH(600, 100, 320, 360));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('floating-minimize-$id')));
    await t.pumpAndSettle();
    expect(manager.window(id)!.minimized, isTrue);
    expect(find.byKey(const Key('floating-search')), findsNothing);
    await t.tap(find.byKey(Key('floating-minimize-$id')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('floating-search')), findsOneWidget);
    final before = manager.window(id)!.rect.size;
    await t.drag(
      find.byKey(Key('floating-resize-$id')),
      const Offset(60, 40),
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await t.pumpAndSettle();
    final after = manager.window(id)!.rect.size;
    expect(after.width, greaterThan(before.width));
    expect(after.height, greaterThan(before.height));
    final start = manager.window(id)!.rect.topLeft;
    await t.drag(
      find.byKey(Key('floating-title-$id')),
      const Offset(-100, 50),
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await t.pumpAndSettle();
    expect(manager.window(id)!.rect.topLeft, isNot(start));
    await t.tap(find.byKey(Key('floating-close-$id')));
    await t.pumpAndSettle();
    expect(manager.window(id), isNull);
    expect(t.takeException(), isNull);
  });
}

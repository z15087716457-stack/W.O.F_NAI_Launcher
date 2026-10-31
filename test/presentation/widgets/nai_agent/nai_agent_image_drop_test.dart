import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_controller.dart';
import 'package:nai_launcher/presentation/widgets/nai_agent/nai_agent_image_input.dart';
import 'package:nai_launcher/presentation/widgets/drop/global_drop_handler.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../../helpers/drop_session_fixture.dart';

void main() {
  prepareDropTestPlatform();
  testWidgets('Agent surface rejects ancestor canvas import outside composer', (
    t,
  ) async {
    await t.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GlobalDropHandler(
            child: Row(
              children: [
                Expanded(child: SizedBox.expand()),
                SizedBox(
                  width: 240,
                  child: MetaData(
                    metaData: GlobalDropHandler.excludedRegion,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox.expand(key: Key('agent-area')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final drop = t.widget<DropRegion>(find.byType(DropRegion));
    final session = FixtureDropSession([]);
    Future<DropOperation> hover(Offset point) async => await drop.onDropOver(
      DropOverEvent(
        session: session,
        position: DropPosition(global: point, local: point),
      ),
    );
    expect(await hover(const Offset(40, 100)), DropOperation.copy);
    await t.pump();
    expect(
      await hover(t.getCenter(find.byKey(const Key('agent-area')))),
      DropOperation.none,
    );
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'all native readers start before drop ends while first read waits',
    (t) async {
      final c = (await t.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('agent-drop-');
        final controller = NaiAgentWorkspaceController(
          store: AgentWorkspaceStore(root),
          initialWorkspaceName: 'Test',
          initialChatName: 'Test',
          startClient: (_, __, ___, ____, _____) async =>
              throw StateError('No model'),
        );
        await controller.initialize();
        return controller;
      }))!;
      addTearDown(
        () => t.runAsync(() async {
          await c.close();
          await c.store.root.delete(recursive: true);
        }),
      );
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NaiAgentDropTarget(
              controller: c,
              runtime: c.selected!,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      final readers = await t.runAsync(
        () async => [
          for (final name in ['one.png', 'two.png'])
            HeldDropReader(
              bytes: Uint8List.fromList(
                img.encodePng(img.Image(width: 2, height: 2)),
              ),
              name: name,
            ),
        ],
      );
      final drop = t.widget<DropRegion>(find.byType(DropRegion));
      final session = FixtureDropSession(readers!);
      await t.runAsync(() async {
        await drop.onPerformDrop(session.perform());
        for (final reader in readers) {
          expect(reader.fileReads, 1);
          reader.callbackReturned = true;
        }
        expect(c.selected!.importingImages, 1);
        for (final reader in readers) {
          reader.release.complete();
        }
        for (var i = 0; i < 200 && c.selected!.importingImages != 0; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(c.selected!.composer.attachments.map((a) => a.name), [
        'one.png',
        'two.png',
      ]);
      expect(c.selected!.importingImages, 0);
      expect(t.takeException(), isNull);
    },
  );
}

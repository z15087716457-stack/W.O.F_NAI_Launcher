import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_drop_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_imports.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../helpers/drop_session_fixture.dart';

class _HeldImports extends GenerationReferenceImports {
  _HeldImports(super.ref);
  final release = Completer<void>();
  final loaded = Completer<List<GenerationReferenceFile>>();
  int calls = 0;
  @override
  Future<void> files(
    GenDropTarget target,
    Future<List<GenerationReferenceFile>> Function() load, {
    bool Function()? alive,
    bool Function()? replaceRequested,
    void Function()? onApplied,
  }) async {
    calls++;
    loaded.complete(await load());
    await release.future;
  }
}

void main() {
  prepareDropTestPlatform();
  testWidgets(
    'drop returns before reading/import finishes, snapshots every reader, rejects reentry',
    (tester) async {
      late _HeldImports imports;
      final container = ProviderContainer(
        overrides: [
          generationReferenceImportsProvider.overrideWith(
            (ref) => imports = _HeldImports(ref),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GenerationDropWiring(
              target: GenDropTarget.img2img,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      final readers = [
        HeldDropReader(bytes: Uint8List.fromList([1]), name: 'one.png'),
        HeldDropReader(bytes: Uint8List.fromList([2]), name: 'two.png'),
      ];
      final session = FixtureDropSession(readers);
      final drop = tester.widget<DropRegion>(find.byType(DropRegion));
      var returned = false;
      unawaited(
        drop.onPerformDrop(session.perform()).then((_) => returned = true),
      );
      await tester.pump();
      expect(returned, isTrue);
      expect(imports.loaded.isCompleted, isFalse);
      expect(readers.map((r) => r.fileReads), [1, 1]);
      for (final reader in readers) {
        reader.callbackReturned = true;
      }
      session.items.clear(); // native session is no longer usable
      expect(await drop.onDropOver(session.over()), DropOperation.none);
      await drop.onPerformDrop(session.perform());
      expect(imports.calls, 1);
      for (final reader in readers) {
        reader.release.complete();
      }
      await tester.pump();
      expect(imports.loaded.isCompleted, isTrue);
      expect((await imports.loaded.future).map((file) => file.name), [
        'one.png',
        'two.png',
      ]);
      imports.release.complete();
      await tester.pump();
      expect(await drop.onDropOver(session.over()), DropOperation.copy);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

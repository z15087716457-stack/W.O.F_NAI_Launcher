import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

void main() {
  const markerA = '\uE000';
  const markerB = '\uE001';

  group('allocateMarker / insertBlock', () {
    test('allocates the smallest free private-use char', () {
      var doc = PillDocument.empty();
      doc = PillDocumentEditor.insertBlock(doc, offset: 0, blockId: 'a');
      expect(doc.text, markerA);
      expect(doc.instances[markerA]?.blockId, 'a');
      expect(doc.instances[markerA]?.enabled, isTrue);

      doc = PillDocumentEditor.insertBlock(doc, offset: 0, blockId: 'b');
      expect(doc.text, '$markerB$markerA');
      expect(doc.instances[markerB]?.blockId, 'b');
    });

    test('inserts at clamped offset inside existing text', () {
      final doc = PillDocumentEditor.insertBlock(
        const PillDocument(text: 'hello', instances: {}),
        offset: 99,
        blockId: 'a',
      );
      expect(doc.text, 'hello$markerA');

      final doc2 = PillDocumentEditor.insertBlock(
        doc,
        offset: 2,
        blockId: 'b',
      );
      expect(doc2.text, 'he$markerB${'llo'}$markerA');
    });
  });

  group('moveMarker', () {
    test('moves forward with offset correction', () {
      // aAbBc → move A(0) to offset 4 → abBAc 形态
      const doc = PillDocument(
        text: 'a${markerA}b${markerB}c',
        instances: {
          markerA: PillInstance(blockId: 'a'),
          markerB: PillInstance(blockId: 'b'),
        },
      );
      final moved = PillDocumentEditor.moveMarker(
        doc,
        marker: markerA,
        occurrence: 0,
        newOffset: 4,
      );
      expect(moved.text, 'ab$markerB${markerA}c');
    });

    test('moves backward without correction', () {
      const doc = PillDocument(
        text: 'a${markerA}b${markerB}c',
        instances: {
          markerA: PillInstance(blockId: 'a'),
          markerB: PillInstance(blockId: 'b'),
        },
      );
      final moved = PillDocumentEditor.moveMarker(
        doc,
        marker: markerB,
        occurrence: 0,
        newOffset: 0,
      );
      expect(moved.text, '${markerB}a${markerA}bc');
    });

    test('moves the chosen occurrence when duplicated by paste', () {
      const doc = PillDocument(
        text: '$markerA x $markerA',
        instances: {markerA: PillInstance(blockId: 'a')},
      );
      final moved = PillDocumentEditor.moveMarker(
        doc,
        marker: markerA,
        occurrence: 1,
        newOffset: 0,
      );
      expect(moved.text, '$markerA$markerA x ');
      expect(moved.instances.length, 1);
    });

    test('missing marker is a no-op', () {
      const doc = PillDocument(
        text: 'plain',
        instances: {markerA: PillInstance(blockId: 'a')},
      );
      final moved = PillDocumentEditor.moveMarker(
        doc,
        marker: markerA,
        occurrence: 0,
        newOffset: 2,
      );
      expect(moved.text, 'plain');
    });
  });

  group('removeMarker / reconcile', () {
    test('removeMarker strips all occurrences and the instance', () {
      const doc = PillDocument(
        text: 'x$markerA y$markerA',
        instances: {markerA: PillInstance(blockId: 'a')},
      );
      final removed = PillDocumentEditor.removeMarker(doc, markerA);
      expect(removed.text, 'x y');
      expect(removed.instances, isEmpty);
    });

    test('reconcile drops instances whose marker left the text', () {
      const doc = PillDocument(
        text: 'a$markerA$markerB',
        instances: {
          markerA: PillInstance(blockId: 'a'),
          markerB: PillInstance(blockId: 'b'),
        },
      );
      // 用户删掉了 markerA 字符
      final reconciled = PillDocumentEditor.reconcile(doc, 'a$markerB');
      expect(reconciled.text, 'a$markerB');
      expect(reconciled.instances.keys, [markerB]);
    });

    test('reconcile with identical text returns the same document', () {
      const doc = PillDocument(
        text: 'a$markerA',
        instances: {markerA: PillInstance(blockId: 'a')},
      );
      expect(identical(PillDocumentEditor.reconcile(doc, 'a$markerA'), doc),
          isTrue);
    });
  });

  group('project / stripMarkers', () {
    test('enabled instances expand, disabled and unknown vanish', () {
      const doc = PillDocument(
        text: 'pre $markerA mid $markerB post ${'\uE002'}',
        instances: {
          markerA: PillInstance(blockId: 'a'),
          markerB: PillInstance(blockId: 'b', enabled: false),
        },
      );
      final projection = PillDocumentEditor.project(doc, (id) {
        return switch (id) {
          'a' => 'AAA',
          'b' => 'BBB',
          _ => null,
        };
      });
      expect(projection, 'pre AAA mid  post ');
    });

    test('resolver returning null expands to empty', () {
      const doc = PillDocument(
        text: markerA,
        instances: {markerA: PillInstance(blockId: 'gone')},
      );
      expect(PillDocumentEditor.project(doc, (_) => null), '');
    });

    test('stripMarkers removes every private-use marker', () {
      expect(PillDocumentEditor.stripMarkers('a$markerA\uE123b'), 'ab');
    });
  });

  group('json round trip', () {
    test('document survives toJson/fromJson', () {
      const doc = PillDocument(
        text: 'x$markerA',
        instances: {
          markerA: PillInstance(blockId: 'a', enabled: false),
        },
      );
      final restored = PillDocument.fromJson(doc.toJson());
      expect(restored, doc);
    });
  });
}

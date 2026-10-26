import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

void main() {
  const markerA = '\uE000';
  const markerB = '\uE001';
  const markerC = '\uE002';

  test('disabled translations unwrap without starting to send source', () {
    const document = PillDocument(
      text: 'start$markerA,$markerB end',
      instances: {
        markerA: PillInstance(
          blockId: '',
          translation: TranslationPill(source: 'latest source', zh: 'reading'),
        ),
        markerB: PillInstance(
          blockId: '',
          enabled: false,
          translation: TranslationPill(source: 'must not send', zh: 'hidden'),
        ),
      },
    );
    final projected = PillDocumentEditor.project(document, (_) => null);
    final all = PillDocumentEditor.unwrapAllTranslations(document);
    expect(all.text, 'startlatest source, end');
    expect(all.instances, isEmpty);
    expect(PillDocumentEditor.project(all, (_) => null), projected);
    final single = PillDocumentEditor.unwrapTranslation(
      document,
      markerB,
      source: 'must not send',
    );
    expect(PillDocumentEditor.project(single, (_) => null), projected);
    expect(single.instances.containsKey(markerB), isFalse);
  });

  group('allocateMarker / insertBlock', () {
    test(
      'negative marker survives document JSON without changing old markers',
      () {
        final negative = PillDocumentEditor.insertBlock(
          PillDocument.empty(),
          offset: 0,
          blockId: 'paired',
          useNegativeContent: true,
        );
        expect(negative.instances[markerA]!.useNegativeContent, isTrue);
        expect(
          PillDocument.fromJson(
            negative.toJson(),
          ).instances[markerA]!.useNegativeContent,
          isTrue,
        );
        expect(const PillInstance(blockId: 'old').useNegativeContent, isFalse);
      },
    );

    test('paired markers keep their shared identity and scope in JSON', () {
      final positive = PillDocumentEditor.insertBlock(
        PillDocument.empty(),
        offset: 0,
        blockId: 'pair',
        bundleId: 'insert-1',
        rollScopeMask: 2,
      );
      final negative = PillDocumentEditor.insertBlock(
        PillDocument.empty(),
        offset: 0,
        blockId: 'pair',
        useNegativeContent: true,
        bundleId: 'insert-1',
        rollScopeMask: 2,
      );
      final posRestored = PillDocument.fromJson(
        positive.toJson(),
      ).instances[markerA]!;
      final negRestored = PillDocument.fromJson(
        negative.toJson(),
      ).instances[markerA]!;
      expect(posRestored.bundleId, 'insert-1');
      expect(negRestored.bundleId, posRestored.bundleId);
      expect(posRestored.rollScopeMask, 2);
      expect(negRestored.rollScopeMask, 2);
    });

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

      final doc2 = PillDocumentEditor.insertBlock(doc, offset: 2, blockId: 'b');
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
    test(
      'unwrapAllTranslations restores exact source and keeps library pills',
      () {
        const doc = PillDocument(
          text: 'prefix $markerA$markerB$markerA $markerC suffix',
          instances: {
            markerA: PillInstance(
              blockId: '',
              translation: TranslationPill(source: 'blue, ', zh: '蓝色'),
            ),
            markerB: PillInstance(blockId: 'library'),
            markerC: PillInstance(
              blockId: '',
              translation: TranslationPill(source: 'green\n', zh: '绿色'),
            ),
          },
        );
        final restored = PillDocumentEditor.unwrapAllTranslations(doc);
        expect(restored.text, 'prefix blue, ${markerB}blue,  green\n suffix');
        expect(restored.instances.keys, [markerB]);
        expect(PillDocumentEditor.unwrapAllTranslations(restored), restored);
      },
    );

    test('unwrapTranslation restores source at each occurrence only', () {
      const doc = PillDocument(
        text: 'start $markerA, $markerB, $markerA end',
        instances: {
          markerA: PillInstance(
            blockId: '',
            translation: TranslationPill(source: 'blue eyes', zh: '蓝眼睛'),
          ),
          markerB: PillInstance(blockId: 'other'),
        },
      );
      final unwrapped = PillDocumentEditor.unwrapTranslation(
        doc,
        markerA,
        source: 'edited $markerA source',
      );
      expect(
        unwrapped.text,
        'start edited  source, $markerB, edited  source end',
      );
      expect(unwrapped.instances.keys, [markerB]);
      expect(
        PillDocumentEditor.unwrapTranslation(
          unwrapped,
          markerB,
          source: 'untouched',
        ),
        unwrapped,
      );
    });

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
      expect(
        identical(PillDocumentEditor.reconcile(doc, 'a$markerA'), doc),
        isTrue,
      );
    });
  });

  test(
    'expansion preserves send text for fixed/rolled/translation/disabled/shared',
    () {
      for (final instance in [
        const PillInstance(blockId: 'b'),
        const PillInstance(
          blockId: 'b',
          settings: PillInstanceSettings(mode: PillRollMode.random),
          currentRoll: '1.2::rolled::',
        ),
        const PillInstance(
          blockId: 'b',
          settings: PillInstanceSettings(mode: PillRollMode.sequential),
          currentRoll: 'next',
        ),
        const PillInstance(
          blockId: '',
          translation: TranslationPill(source: 'source', zh: '译文'),
        ),
        const PillInstance(
          blockId: '',
          enabled: false,
          translation: TranslationPill(source: 'hidden', zh: '禁用'),
        ),
      ]) {
        const marker = '\uE000';
        final doc = PillDocument(
          text: 'a${marker}b${marker}c',
          instances: {marker: instance},
        );
        String? resolve(String _, PillInstance i) =>
            i.settings.hasRoll ? i.currentRoll : 'fixed';
        final send = PillDocumentEditor.projectWithMarker(doc, resolve);
        final expanded = PillDocumentEditor.expandOccurrence(
          doc,
          marker,
          occurrence: 1,
          resolveMarker: resolve,
        );
        expect(PillDocumentEditor.projectWithMarker(expanded, resolve), send);
        expect(expanded.text.startsWith('a${marker}b'), isTrue);
        expect(expanded.instances[marker], instance);
        if (instance.translation != null) {
          expect(
            PillDocumentEditor.projectWithMarker(
              PillDocumentEditor.unwrapAllTranslations(doc),
              resolve,
            ),
            send,
          );
          expect(
            PillDocumentEditor.projectWithMarker(
              PillDocumentEditor.unwrapTranslation(
                doc,
                marker,
                source: instance.translation!.source,
              ),
              resolve,
            ),
            send,
          );
        }
      }
    },
  );

  test(
    'temporary content wins over translation and roll, round trips and can be cleared',
    () {
      final temp = PillTempContent(
        content: 'fixed temp',
        negativeContent: 'temp UC',
        originalContent: 'old',
        editedAt: DateTime(2026, 10, 26),
        editedBy: 'agent',
      );
      final instance = PillInstance(
        blockId: 'b',
        temp: temp,
        translation: const TranslationPill(source: 'old source', zh: '译文'),
        settings: const PillInstanceSettings(mode: PillRollMode.random),
        currentRoll: 'old roll',
      );
      final document = PillDocument(
        text: markerA,
        instances: {markerA: instance},
      );
      expect(
        PillDocumentEditor.project(document, (_) => 'library'),
        'fixed temp',
      );
      expect(
        PillDocumentEditor.project(
          document.copyWith(
            instances: {markerA: instance.copyWith(useNegativeContent: true)},
          ),
          (_) => 'library',
        ),
        'temp UC',
      );
      final disabled = document.copyWith(
        instances: {markerA: instance.copyWith(enabled: false)},
      );
      expect(PillDocumentEditor.unwrapAllTranslations(disabled).text, '');
      expect(
        PillDocumentEditor.unwrapAllTranslations(document).text,
        'fixed temp',
      );
      final expanded = PillDocumentEditor.expandOccurrence(
        document,
        markerA,
        resolveMarker: (_, __) => 'library',
      );
      expect(expanded.text, 'fixed temp');
      expect(PillDocument.fromJson(document.toJson()), document);
      expect(instance.copyWith().temp, temp);
      expect(instance.copyWith(temp: null).temp, isNull);
    },
  );

  group('project / stripMarkers', () {
    test('enabled instances expand, disabled and unknown vanish', () {
      const doc = PillDocument(
        text: 'pre $markerA mid $markerB post ${'\uE002'}',
        instances: {
          markerA: PillInstance(blockId: 'a'),
          markerB: PillInstance(blockId: 'b', enabled: false),
        },
      );
      final projection = PillDocumentEditor.project(doc, (instance) {
        return switch (instance.blockId) {
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

    test('marker-aware resolver receives each marker identity', () {
      const doc = PillDocument(
        text: '$markerA$markerB',
        instances: {
          markerA: PillInstance(blockId: 'a'),
          markerB: PillInstance(blockId: 'b'),
        },
      );
      final projection = PillDocumentEditor.projectWithMarker(
        doc,
        (marker, instance) => '$marker:${instance.blockId}',
      );
      expect(projection, '$markerA:a$markerB:b');
    });

    test('stripMarkers removes every private-use marker', () {
      expect(PillDocumentEditor.stripMarkers('a$markerA\uE123b'), 'ab');
    });
  });

  group('json round trip', () {
    test('evolution defaults off and old instance json stays compatible', () {
      const instance = PillInstance(blockId: 'a');
      expect(instance.evolutionEnabled, isFalse);
      expect(PillInstance.fromJson({'blockId': 'a'}).evolutionEnabled, isFalse);
      expect(instance.toJson()['evolutionEnabled'], isFalse);
    });

    test('document survives toJson/fromJson with evolution state', () {
      const doc = PillDocument(
        text: 'x$markerA',
        instances: {
          markerA: PillInstance(
            blockId: 'a',
            enabled: false,
            evolutionEnabled: true,
          ),
        },
      );
      final restored = PillDocument.fromJson(doc.toJson());
      expect(restored, doc);
      expect(restored.instances[markerA]!.evolutionEnabled, isTrue);
    });
  });
}

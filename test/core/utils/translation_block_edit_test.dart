import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/core/utils/translation_block_edit.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

void main() {
  const a = '\ue000', b = '\ue001', c = '\ue002';
  const document = PillDocument(
    text: '$a, $b, $c, tail',
    instances: {
      a: PillInstance(
        blockId: '',
        translation: TranslationPill(source: 'silver hair', zh: 'silver'),
      ),
      b: PillInstance(
        blockId: '',
        translation: TranslationPill(source: 'blue eyes', zh: 'blue'),
      ),
      c: PillInstance(
        blockId: '',
        translation: TranslationPill(source: 'dress', zh: 'dress'),
      ),
    },
  );
  PillDocument apply(
    List<Map<String, dynamic>> operations, [
    PillDocument input = document,
  ]) => TranslationBlockEdit.apply({'main': input}, operations)['main']!;
  String project(PillDocument doc) =>
      PillDocumentEditor.project(doc, (_) => null);

  test(
    'split keeps source byte-for-byte and retranslate never changes sending',
    () {
      final split = apply([
        {
          'scope': 'main',
          'op': 'split',
          'marker': a,
          'parts': [
            {'source': 'silver ', 'translation': 'silver'},
            {'source': 'hair', 'translation': 'hair'},
          ],
        },
      ]);
      expect(project(split), project(document));
      expect(split.instances.length, 4);
      final translated = apply([
        {
          'scope': 'main',
          'op': 'retranslate',
          'marker': b,
          'translation': 'new',
        },
      ], split);
      expect(project(translated), project(document));
      expect(translated.instances[b]!.translation!.zh, 'new');
    },
  );
  test(
    'arbitrary order merge keeps unrelated middle block and removes delimiters',
    () {
      final merged = apply([
        {
          'scope': 'main',
          'op': 'merge',
          'markers': [c, a],
          'source': 'dress, silver hair',
          'translation': 'merged',
        },
      ]);
      expect(merged.text, '$a, $b, tail');
      expect(project(merged), 'dress, silver hair, blue eyes, tail');
      expect(merged.instances.keys, [a, b]);
      expect(merged.instances[b], document.instances[b]);
    },
  );
  test(
    'merge preserves boundary when batch stored separators inside sources',
    () {
      final packed = document.copyWith(
        text: '$a$b$c',
        instances: {
          ...document.instances,
          a: document.instances[a]!.copyWith(
            translation: const TranslationPill(
              source: 'silver hair, ',
              zh: 'silver',
            ),
          ),
          b: document.instances[b]!.copyWith(
            translation: const TranslationPill(
              source: 'blue eyes, ',
              zh: 'blue',
            ),
          ),
        },
      );
      final merged = apply([
        {
          'scope': 'main',
          'op': 'merge',
          'markers': [c, a],
          'source': 'dress, silver hair',
          'translation': 'merged',
        },
      ], packed);
      expect(merged.text, '$a, $b');
      expect(project(merged), 'dress, silver hair, blue eyes, ');
    },
  );
  test(
    'rejoin latest source and disabled source have identical send projection',
    () {
      final disabled = document.copyWith(
        instances: {
          ...document.instances,
          b: document.instances[b]!.copyWith(enabled: false),
        },
      );
      final joined = apply([
        {'scope': 'main', 'op': 'rejoin', 'marker': a},
        {'scope': 'main', 'op': 'rejoin', 'marker': b},
      ], disabled);
      expect(project(joined), project(disabled));
      expect(joined.text, 'silver hair, , $c, tail');
      expect(joined.instances.keys, [c]);
    },
  );
  test(
    'rejects cross scope, lost source, repeated marker and mixed enabled merge',
    () {
      expect(
        () => apply([
          {'scope': 'negative', 'op': 'rejoin', 'marker': a},
        ]),
        throwsFormatException,
      );
      expect(
        () => apply([
          {
            'scope': 'main',
            'op': 'split',
            'marker': a,
            'parts': [
              {'source': 'silver', 'translation': 's'},
              {'source': 'hair', 'translation': 'h'},
            ],
          },
        ]),
        throwsFormatException,
      );
      expect(
        () => apply([
          {
            'scope': 'main',
            'op': 'merge',
            'markers': [a, a],
            'source': 'x',
            'translation': 'y',
          },
        ]),
        throwsFormatException,
      );
      final disabled = document.copyWith(
        instances: {
          ...document.instances,
          b: document.instances[b]!.copyWith(enabled: false),
        },
      );
      expect(
        () => apply([
          {
            'scope': 'main',
            'op': 'merge',
            'markers': [a, b],
            'source': 'x',
            'translation': 'y',
          },
        ], disabled),
        throwsFormatException,
      );
    },
  );
}

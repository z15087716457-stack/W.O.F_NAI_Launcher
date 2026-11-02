import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_selection.dart';

GenBatch batch(String id, List<String> ids, {int pending = 0}) => GenBatch(
  id: id,
  time: DateTime(2026, 11, 1),
  pending: pending,
  images: [
    for (final image in ids)
      GenHistoryImage(
        id: image,
        thumb: MemoryImage(Uint8List(0)),
        width: 8,
        height: 8,
      ),
  ],
);

void main() {
  late GenImageSelection selection;
  setUp(() {
    selection = GenImageSelection()
      ..sync([
        batch('new', ['a', 'b']),
        batch('middle', ['c']),
        batch('old', ['d', 'e']),
      ]);
  });
  tearDown(() => selection.dispose());

  test(
    'ordinary viewing is separate; first Ctrl selects only clicked image',
    () {
      expect(selection.tap(['a']), isFalse);
      expect(selection.active, isFalse);
      expect(selection.images, isEmpty);
      expect(selection.tap(['b'], modify: true), isTrue);
      expect(selection.images, ['b']);
      expect(selection.partial(batch('new', ['a', 'b'])), isTrue);
    },
  );

  test(
    'history chooses a batch, a canvas child can be removed independently',
    () {
      selection.setActive(true);
      selection.tap(['a', 'b']);
      expect(selection.checked(batch('new', ['a', 'b'])), isTrue);
      selection.tap(['b']);
      expect(selection.images, ['a']);
      expect(selection.partial(batch('new', ['a', 'b'])), isTrue);
      selection.tap(['a', 'b']);
      expect(selection.images, ['a', 'b']);
    },
  );

  test(
    'single-image batches use the same selection and exit when last is removed',
    () {
      selection.tap(['c'], modify: true);
      expect(selection.contains('c'), isTrue);
      selection.tap(['c']);
      expect(selection.active, isFalse);
      expect(selection.images, isEmpty);
    },
  );

  test('Shift includes both complete endpoint batches in either direction', () {
    selection.tap(['d', 'e']);
    selection.tap(['a', 'b'], range: true);
    expect(selection.images, ['a', 'b', 'c', 'd', 'e']);
    selection.setActive(false);
    selection.tap(['a', 'b']);
    selection.tap(['d', 'e'], range: true);
    expect(selection.images, ['a', 'b', 'c', 'd', 'e']);
  });

  test(
    'regrouping keeps image IDs; removing a selected image prunes just that ID',
    () {
      selection.tap(['a', 'b'], modify: true);
      selection.sync([
        batch('img:a', ['a']),
        batch('img:b', ['b']),
        batch('img:c', ['c']),
      ]);
      expect(selection.images, ['a', 'b']);
      selection.sync([
        batch('img:b', ['b']),
        batch('img:c', ['c']),
      ]);
      expect(selection.images, ['b']);
      selection.sync([
        batch('img:c', ['c']),
      ]);
      expect(selection.active, isFalse);
    },
  );

  test(
    'selected generating batch follows later results, including empty cover',
    () {
      selection.sync([batch('run', [], pending: 2)]);
      selection.tap([], modify: true, pendingBatch: 'run');
      expect(selection.active, isTrue);
      expect(selection.checked(batch('run', [], pending: 2)), isTrue);
      selection.sync([
        batch('run', ['a'], pending: 1),
      ]);
      expect(selection.images, ['a']);
      selection.sync([
        batch('run', ['a', 'b']),
      ]);
      expect(selection.images, ['a', 'b']);
    },
  );

  test(
    'editing a generating child stops selecting that batch automatically',
    () {
      selection.sync([
        batch('run', ['a', 'b'], pending: 1),
        batch('old', ['d']),
      ]);
      selection.tap(['a', 'b'], modify: true, pendingBatch: 'run');
      selection.tap(['a']);
      selection.sync([
        batch('run', ['a', 'b', 'c']),
      ]);
      expect(selection.images, ['b']);
    },
  );

  test('exit clears image IDs and pending whole-batch selection', () {
    selection.tap(['a'], modify: true);
    selection.setActive(false);
    expect(selection.images, isEmpty);
    expect(selection.contains('a'), isFalse);
    expect(selection.tap(['b']), isFalse);
  });

  test(
    'retained canvas images are included in actions even without a history row',
    () {
      selection.sync([]);
      selection.tap(['retained'], modify: true);
      expect(selection.images, ['retained']);
      selection.sync([
        batch('new', ['a']),
      ]);
      expect(selection.images, ['retained']);
      selection.setActive(false);
      expect(selection.images, isEmpty);
    },
  );
}

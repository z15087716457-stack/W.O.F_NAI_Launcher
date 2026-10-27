import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/resource_window_host.dart';
import 'package:nai_launcher/data/models/resources/floating_window_data.dart';

class Backend extends ResourceWindowBackend {
  final calls = <String>[];
  Completer<Map<String, Object?>>? pending;
  Completer<Uint8List?>? thumbnailPending;
  Completer<List<Map<String, Object?>>>? recordsPending;
  @override
  Future<List<Map<String, Object?>>> galleryRecords(List<String> ids) async {
    calls.add('records:${ids.join(',')}');
    return recordsPending?.future ??
        [
          for (final id in ids) {'id': id},
        ];
  }

  @override
  Future<Object?> galleryViewer(Map<String, Object?> arguments) async {
    calls.add('viewer:${arguments['operation']}');
    return {'records': []};
  }

  @override
  Future<Map<String, Object?>> query(ResourceQuery r) async {
    calls.add(
      'query:${r.offset}:${r.limit}:${r.groupId}:${r.query}:${r.chips}:${r.sortId}',
    );
    return pending?.future ??
        {
          'total': 125,
          'hasMore': r.offset + r.limit < 125,
          'items': List.generate(r.limit, (i) => {'id': '${r.offset + i}'}),
        };
  }

  @override
  Future<Uint8List?> thumbnail(
    FloatingResourceKind kind,
    String id,
    int revision,
  ) async {
    calls.add('thumbnail:${kind.name}:$id:$revision');
    return thumbnailPending?.future ?? Uint8List.fromList([1, 2]);
  }

  @override
  Future<Map<String, Object?>> detail(
    FloatingResourceKind kind,
    String id,
  ) async {
    if (id == 'deleted') resourceError('not_found');
    calls.add('detail:${kind.name}:$id');
    return {'itemId': id};
  }

  @override
  Future<void> action(
    FloatingResourceKind kind,
    String id,
    String actionId,
  ) async {
    calls.add('action:${kind.name}:$id:$actionId');
  }

  @override
  Future<void> favorite(FloatingResourceKind kind, String id) async {
    calls.add('favorite:${kind.name}:$id');
  }

  @override
  Future<void> open(FloatingResourceKind kind, String id) async {
    calls.add('open:${kind.name}:$id');
  }

  @override
  Future<Uri> exportGallery(String id) async {
    calls.add('export:$id');
    return Uri.file('C:/temporary/sanitized.png');
  }

  @override
  Future<void> layout(String id, Map<String, Object?> values) async {
    calls.add('layout:$id');
  }

  @override
  Future<void> preferences(
    FloatingResourceKind kind,
    Map<String, Object?> values,
  ) async {
    calls.add(
      'preferences:${kind.name}:${values['layout']}:${values['cellSize']}',
    );
  }

  @override
  Future<void> confirmSearch(String query) async {
    calls.add('search:$query');
  }
}

Map<String, Object?> query(int id, {String window = 'w', int offset = 0}) => {
  'windowId': window,
  'requestId': id,
  'kind': 'gallery',
  'groupId': 'all',
  'query': 'cat',
  'chips': ['favorite'],
  'sortId': 'fileName',
  'descending': false,
  'offset': offset,
  'limit': 60,
};
Matcher code(String value) =>
    isA<PlatformException>().having((e) => e.code, 'code', value);

void main() {
  late ResourceWindowHost host;
  late Backend backend;
  setUp(() {
    backend = Backend();
    host = ResourceWindowHost()..backend = backend;
  });
  test(
    'child viewer requests use data IPC without opening the main viewer',
    () async {
      expect(
        await host.handle(
          const MethodCall('gallery.viewer', {
            'operation': 'records',
            'ids': ['a'],
          }),
        ),
        {'records': []},
      );
      expect(backend.calls, ['viewer:records']);
    },
  );
  test(
    'visible gallery records are bounded and tied to the content revision',
    () async {
      expect(
        await host.handle(
          const MethodCall('gallery.records', {
            'revision': 0,
            'ids': ['a', 'b'],
          }),
        ),
        [
          {'id': 'a'},
          {'id': 'b'},
        ],
      );
      for (final args in [
        {'revision': 0, 'ids': List.filled(61, 'a')},
        {
          'revision': 0,
          'ids': [1],
        },
        {
          'ids': ['a'],
        },
      ]) {
        await expectLater(
          host.handle(MethodCall('gallery.records', args)),
          throwsA(code('invalid_arguments')),
        );
      }
      backend.recordsPending = Completer();
      final waiting = host.handle(
        const MethodCall('gallery.records', {
          'revision': 0,
          'ids': ['a'],
        }),
      );
      final check = expectLater(waiting, throwsA(code('cancelled')));
      host.changed(FloatingResourceKind.gallery);
      backend.recordsPending!.complete([
        {'id': 'a'},
      ]);
      await check;
      final count = backend.calls.length;
      await expectLater(
        host.handle(
          const MethodCall('gallery.records', {
            'revision': 0,
            'ids': ['a'],
          }),
        ),
        throwsA(code('cancelled')),
      );
      expect(backend.calls.length, count);
    },
  );
  test(
    'queries page 60 and preserve request IDs, filters, independent windows',
    () async {
      final first =
          await host.handle(MethodCall('resources.query', query(1))) as Map;
      final next =
          await host.handle(MethodCall('resources.query', query(2, offset: 60)))
              as Map;
      final other =
          await host.handle(
                MethodCall('resources.query', query(1, window: 'other')),
              )
              as Map;
      expect(first['requestId'], 1);
      expect(first['revision'], 0);
      expect(first['total'], 125);
      expect((next['items'] as List).first, {'id': '60'});
      expect(next['hasMore'], true);
      expect(other['requestId'], 1);
      expect(backend.calls.first, contains('all:cat:{favorite}:fileName'));
    },
  );
  test(
    'late request, changed revision and closed window are cancelled',
    () async {
      final pending = Completer<Map<String, Object?>>();
      backend.pending = pending;
      final old = host.handle(MethodCall('resources.query', query(1)));
      final assertion = expectLater(old, throwsA(code('cancelled')));
      backend.pending = null;
      await host.handle(MethodCall('resources.query', query(2)));
      pending.complete({'items': []});
      await assertion;
      await expectLater(
        host.handle(MethodCall('resources.query', query(1))),
        throwsA(code('cancelled')),
      );
      for (final close in [false, true]) {
        backend.pending = Completer();
        final waiting = host.handle(
          MethodCall('resources.query', query(close ? 4 : 3)),
        );
        final check = expectLater(waiting, throwsA(code('cancelled')));
        if (close) {
          host.closed('w');
        } else {
          host.changed(FloatingResourceKind.gallery);
        }
        backend.pending!.complete({'items': []});
        await check;
      }
    },
  );
  test(
    'not ready, version and malformed pagination are explicit errors',
    () async {
      host.backend = null;
      await expectLater(
        host.handle(MethodCall('resources.query', query(1))),
        throwsA(code('not_ready')),
      );
      host.backend = backend;
      for (final args in [
        {...query(1), 'limit': 61},
        {...query(1), 'offset': -1},
        {
          ...query(1),
          'chips': [1],
        },
        {...query(1), 'kind': 'wrong'},
        {...query(1), 'groupId': 2},
      ]) {
        await expectLater(
          host.handle(MethodCall('resources.query', args)),
          throwsA(code('invalid_arguments')),
        );
      }
      await expectLater(
        host.handle(
          const MethodCall('ready', {
            'version': 2,
            'windowId': 'w',
            'kind': 'blocks',
          }),
        ),
        throwsA(code('unsupported_version')),
      );
      await expectLater(
        host.handle(MethodCall('resources.query', {...query(1), 'version': 2})),
        throwsA(code('unsupported_version')),
      );
    },
  );
  test(
    'thumbnail is not cancelled when library revision changes in flight',
    () async {
      backend.thumbnailPending = Completer<Uint8List?>();
      host.changed(FloatingResourceKind.blocks);
      final result = host.handle(
        const MethodCall('resources.thumbnail', {
          'kind': 'blocks',
          'id': 'a',
          'thumbVersion': 'cover-v1',
          'revision': 0,
        }),
      );
      host.changed(FloatingResourceKind.blocks);
      backend.thumbnailPending!.complete(Uint8List.fromList([7]));
      expect(await result, [7]);
      expect(backend.calls.single, 'thumbnail:blocks:a:1');
    },
  );
  test(
    'sort direction is typed separately and counts do not start a query',
    () async {
      expect(ResourceQuery(query(1)).sortId, 'fileName');
      expect(ResourceQuery(query(1)).descending, false);
      expect(await host.handle(const MethodCall('resources.counts', {})), {});
      expect(backend.calls, isEmpty);
      await expectLater(
        host.handle(
          MethodCall('resources.query', {...query(1), 'descending': 'false'}),
        ),
        throwsA(code('invalid_arguments')),
      );
    },
  );
  test(
    'every other host method forwards typed values without running generation',
    () async {
      for (final kind in FloatingResourceKind.values) {
        final args = {'kind': kind.name, 'id': 'a'};
        expect(
          await host.handle(
            MethodCall('resources.thumbnail', {...args, 'revision': 0}),
          ),
          [1, 2],
        );
        expect(await host.handle(MethodCall('resources.detail', args)), {
          'itemId': 'a',
        });
        await host.handle(
          MethodCall('resources.action', {...args, 'actionId': 'add'}),
        );
        await host.handle(MethodCall('resources.favorite', args));
        await host.handle(MethodCall('resources.open', args));
        await host.handle(
          MethodCall('resources.preferences', {
            ...args,
            'layout': 'list',
            'cellSize': 150,
          }),
        );
        expect(
          backend.calls,
          containsAll([
            'action:${kind.name}:a:add',
            'favorite:${kind.name}:a',
            'open:${kind.name}:a',
            'preferences:${kind.name}:list:150',
          ]),
        );
      }
      final export =
          await host.handle(const MethodCall('gallery.export', {'id': 'a'}))
              as Map;
      expect(export['uri'], 'file:///C:/temporary/sanitized.png');
      await host.handle(
        const MethodCall('resources.layout', {
          'windowId': 'w',
          'rect': {'left': 1},
        }),
      );
      await host.handle(
        const MethodCall('resources.searchConfirmed', {'query': 'cat'}),
      );
      expect(backend.calls, containsAll(['layout:w', 'search:cat']));
      await expectLater(
        host.handle(
          const MethodCall('resources.detail', {
            'kind': 'blocks',
            'id': 'deleted',
          }),
        ),
        throwsA(code('not_found')),
      );
    },
  );
}

import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nai_launcher/presentation/resource_window/resource_window_controller.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_contract.dart';

class Session extends Mock implements DragSession {}

Map<String, Object?> page(Map<String, Object?> args, {String id = 'a'}) => {
  'requestId': args['requestId'],
  'revision': 2,
  'total': 3,
  'hasMore': args['offset'] == 0,
  'items': [
    {'id': args['offset'] == 0 ? id : 'b', 'title': id, 'favorite': false},
  ],
  'layout': 'grid',
  'cellSize': 132.0,
  'layouts': ['grid', 'list'],
  'counts': {'blocks': 3},
  'sections': [
    {
      'title': 'Library',
      'groups': [
        {'id': 'all', 'label': 'All'},
        {'id': 'folder:c', 'label': 'Child', 'parentId': 'folder:p'},
      ],
    },
  ],
  'chips': [
    {'id': 'favorite', 'label': 'Favorite'},
  ],
  'sorts': [
    {'id': 'updated', 'label': 'Updated'},
  ],
  'sortId': 'updated',
};
void main() {
  final calls = <({String method, Map<String, Object?> args})>[];
  late ResourceWindowController controller;
  Future<Object?> invoke(String method, Map<String, Object?> args) async {
    calls.add((method: method, args: args));
    if (method == 'resources.query') return page(args);
    if (method == 'resources.detail') {
      return {
        'itemId': args['id'],
        'title': 'Detail',
        'body': 'prompt',
        'actions': [
          {'id': 'add', 'label': 'Add', 'primary': true},
        ],
      };
    }
    if (method == 'gallery.export') {
      return {'uri': 'file:///C:/temporary/sanitized.png'};
    }
    return null;
  }

  setUp(() {
    calls.clear();
    controller = ResourceWindowController(
      windowId: 'w',
      kind: FloatingResourceKind.blocks,
      invoke: invoke,
    );
  });
  tearDown(() => controller.dispose());

  testWidgets('search is debounced 200ms; submit is immediate', (tester) async {
    await controller.initialize();
    calls.clear();
    controller.actions.onQuery('c');
    await tester.pump(const Duration(milliseconds: 100));
    controller.actions.onQuery('cat');
    await tester.pump(const Duration(milliseconds: 199));
    expect(calls, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls.single.args['query'], 'cat');
    controller.actions.onQuery('dog', submit: true);
    await tester.pump();
    expect(calls.last.args['query'], 'dog');
    expect(controller.data.query, 'dog');
  });
  test(
    'selection loads detail, pagination appends and preferences forward',
    () async {
      await controller.initialize();
      expect(controller.data.sections.first.groups.last.parentId, 'folder:p');
      await controller.select('a');
      expect(controller.data.selectedId, 'a');
      expect(controller.data.detail!.body, 'prompt');
      expect(controller.data.detail!.actions.single.primary, true);
      await controller.refresh(more: true);
      expect(controller.data.items.map((i) => i.id), ['a', 'b']);
      expect(
        calls.where((c) => c.method == 'resources.query').last.args['offset'],
        1,
      );
      await controller.preferences(layout: ResourceLayout.list, size: 150);
      expect(controller.data.layout, ResourceLayout.list);
      expect(controller.data.cellSize, 150);
      await controller.command('resources.action', 'a', action: 'add');
      await controller.command('resources.open', 'a');
      expect(calls.last.method, 'resources.open');
    },
  );
  testWidgets('kind change resets filters and ignores stale query/detail', (
    tester,
  ) async {
    controller.dispose();
    final old = Completer<Object?>();
    final detail = Completer<Object?>();
    controller = ResourceWindowController(
      windowId: 'w',
      kind: FloatingResourceKind.blocks,
      invoke: (method, args) {
        if (method == 'resources.detail') return detail.future;
        if (method == 'resources.query' && args['kind'] == 'blocks') {
          return old.future;
        }
        return invoke(method, args);
      },
    );
    final waiting = controller.initialize();
    final selecting = controller.select('old');
    controller.actions.onKind(FloatingResourceKind.vibe);
    await tester.pump();
    old.complete(page({'requestId': 1, 'offset': 0}, id: 'stale'));
    await waiting;
    detail.complete({'itemId': 'old', 'title': 'Stale', 'actions': []});
    await selecting;
    expect(controller.data.kind, FloatingResourceKind.vibe);
    expect(controller.data.items.single.id, 'a');
    expect(controller.data.detail, isNull);
    expect(controller.data.selectedId, isNull);
  });
  test(
    'transport failure marks disconnected; retry reconnects; domain errors do not disconnect',
    () async {
      controller.dispose();
      var broken = true, domainError = false;
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.blocks,
        invoke: (method, args) async {
          if (broken) throw WindowChannelException('CHANNEL_NOT_FOUND', 'gone');
          if (domainError) throw PlatformException(code: 'not_found');
          return invoke(method, args);
        },
      );
      await controller.initialize();
      expect(controller.data.connected, false);
      expect(controller.data.error, isNotNull);
      broken = false;
      await controller.initialize();
      expect(controller.data.connected, true);
      domainError = true;
      await controller.initialize();
      expect(controller.data.connected, true);
      expect(controller.data.error, contains('not_found'));
    },
  );
  test(
    'gallery drag provider never waits for export during gesture startup',
    () async {
      controller.dispose();
      final pending = Completer<Object?>();
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.gallery,
        invoke: (method, args) =>
            method == 'gallery.export' ? pending.future : invoke(method, args),
      );
      final prewarm = controller.prepareExport('a');
      final wrapper =
          controller.dragWrap(
                const ResourceItem(id: 'a', title: 'A'),
                const SizedBox(),
              )
              as MouseRegion;
      final drag = (wrapper.child as Listener).child as DragItemWidget;
      final request = DragItemRequest(
        location: Offset.zero,
        session: Session(),
      );
      expect(await drag.dragItemProvider(request), isNull);
      pending.complete({'uri': 'file:///C:/temporary/sanitized.png'});
      await prewarm;
      final ready = await drag.dragItemProvider(request);
      expect(ready, isNotNull);
      expect(ready!.localData, isNull);
    },
  );

  test('thumbnail cache identity is kind + id + revision', () {
    final a = ResourceWindowImage(FloatingResourceKind.blocks, 'a', 1, invoke);
    expect(a, ResourceWindowImage(FloatingResourceKind.blocks, 'a', 1, invoke));
    expect(
      a,
      isNot(ResourceWindowImage(FloatingResourceKind.vibe, 'a', 1, invoke)),
    );
    expect(
      a,
      isNot(ResourceWindowImage(FloatingResourceKind.blocks, 'a', 2, invoke)),
    );
  });
}

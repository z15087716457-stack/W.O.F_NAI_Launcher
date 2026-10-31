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
  testWidgets(
    'group changes retain the loaded page, skip repeats and discard old replies in every resource',
    (tester) async {
      for (final kind in FloatingResourceKind.values) {
        final pending =
            <({Map<String, Object?> args, Completer<Object?> result})>[];
        var delay = false;
        var queries = 0;
        var details = 0;
        Map<String, Object?> result(Map<String, Object?> args, String id) => {
          ...page(args, id: id),
          'hasMore': false,
          if (kind == FloatingResourceKind.gallery) ...{
            'timeline': [
              [id, 1000000, 832, 1216, 100],
            ],
            'groupMode': 'day',
          },
        };
        final subject = ResourceWindowController(
          windowId: 'w',
          kind: kind,
          invoke: (method, args) async {
            if (method != 'resources.query') {
              details++;
              return null;
            }
            queries++;
            if (!delay) return result(args, 'initial');
            final entry = (args: args, result: Completer<Object?>());
            pending.add(entry);
            return entry.result.future;
          },
        );
        await subject.initialize();
        subject.group('all');
        expect(queries, 1);
        delay = true;
        subject.group('folder:a');
        expect(subject.data.sections, isNotEmpty);
        expect(subject.data.total, 3);
        expect(subject.data.loading, true);
        expect(subject.data.replacing, true);
        await subject.select('initial');
        subject.open('initial');
        await subject.refresh(more: true);
        expect(details, 0);
        expect(queries, 2);
        subject.group('folder:a');
        expect(queries, 2);
        subject.group('folder:b');
        pending[1].result.complete(result(pending[1].args, 'new'));
        await tester.pump();
        pending[0].result.complete(result(pending[0].args, 'old'));
        await tester.pump();
        expect(subject.data.groupId, 'folder:b');
        expect(subject.data.replacing, false);
        expect(
          kind == FloatingResourceKind.gallery
              ? subject.galleryTimeline.single.path
              : subject.data.items.single.id,
          'new',
        );
        subject.group('folder:failed');
        pending[2].result.completeError(PlatformException(code: 'failed'));
        await tester.pump();
        expect(subject.data.sections, isNotEmpty);
        expect(subject.data.total, 0);
        expect(subject.data.error, isNotNull);
        expect(subject.data.replacing, false);
        subject.dispose();
      }
    },
  );
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

  testWidgets(
    'changed preserves loaded pages and selection, resumes interrupted more',
    (tester) async {
      controller.dispose();
      final pending = Completer<Object?>();
      var queries = 0;
      final offsets = <int>[];
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.blocks,
        invoke: (method, args) async {
          if (method != 'resources.query') return invoke(method, args);
          queries++;
          final offset = args['offset'] as int;
          offsets.add(offset);
          if (queries == 3) return pending.future;
          return {
            ...page(args),
            'total': 240,
            'hasMore': offset + 60 < 240,
            'items': List.generate(
              60,
              (i) => {
                'id': '${offset + i}',
                'title': '$i',
                'thumbVersion': 'stable',
              },
            ),
          };
        },
      );
      await controller.initialize();
      await controller.refresh(more: true);
      await controller.select('90');
      final thumb = controller.data.items.first.thumb;
      final more = controller.refresh(more: true);
      controller.changed({'kind': 'blocks', 'revision': 3});
      expect(controller.data.items, hasLength(120));
      expect(controller.data.selectedId, '90');
      await tester.pump();
      pending.complete(page({'requestId': 3, 'offset': 120}));
      await more;
      await tester.pump();
      expect(offsets, [0, 60, 120, 0, 60, 120]);
      expect(controller.data.items, hasLength(180));
      expect(controller.data.selectedId, '90');
      expect(controller.data.items.first.thumb, thumb);
      expect(controller.data.hasMore, true);
      expect(controller.data.loading, false);
      controller.actions.onLoadMore();
      controller.actions.onLoadMore();
      await tester.pump();
      expect(controller.data.items, hasLength(240));
      expect(offsets.last, 180);
    },
  );

  testWidgets(
    'counts survive kind reset and unrelated changes do not reload items',
    (tester) async {
      await controller.initialize();
      calls.clear();
      controller.actions.onKind(FloatingResourceKind.vibe);
      expect(controller.data.counts, {FloatingResourceKind.blocks: 3});
      await tester.pump();
      calls.clear();
      controller.changed({'kind': 'gallery', 'revision': 1});
      await tester.pump();
      expect(calls.map((e) => e.method), ['resources.counts']);
      expect(controller.data.items.single.id, 'a');
      controller.viewChanged({'kind': 'vibe', 'layout': 'list'});
      expect(controller.data.layout, ResourceLayout.list);
      expect(calls, hasLength(1));
    },
  );

  test(
    'operation errors emit sequential notices, not query errors; cancelled is silent',
    () async {
      controller.dispose();
      var error = PlatformException(code: 'not_found', message: 'missing');
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.blocks,
        invoke: (method, args) async {
          if (method == 'resources.query') return page(args);
          throw error;
        },
      );
      await controller.initialize();
      for (final (code, message, expected) in [
        ('not_found', 'missing', 'not_found'),
        ('not_ready', 'loading', 'not_ready'),
        ('invalid_arguments', 'Model does not support Vibe', 'unsupported'),
        ('invalid_arguments', 'bad id', 'failed'),
        ('failed', 'disk', 'failed'),
        ('window_operation_failed', 'SetWindowPos failed', 'failed'),
        ('CHANNEL_NOT_FOUND', 'gone', 'disconnected'),
      ]) {
        error = PlatformException(code: code, message: message);
        await controller.command('resources.open', 'a');
        expect(controller.data.notice!.code, expected);
        expect(controller.data.error, isNull);
      }
      expect(controller.data.notice!.id, 7);
      final notice = controller.data.notice;
      error = PlatformException(code: 'cancelled');
      await controller.command('resources.action', 'a', action: 'add');
      expect(controller.data.notice, same(notice));
    },
  );

  test(
    'detail query failure uses error rather than an operation notice',
    () async {
      controller.dispose();
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.blocks,
        invoke: (method, args) async {
          if (method == 'resources.detail') {
            throw PlatformException(code: 'not_found');
          }
          return invoke(method, args);
        },
      );
      await controller.initialize();
      await controller.select('a');
      expect(controller.data.error, contains('not_found'));
      expect(controller.data.notice, isNull);
    },
  );

  testWidgets(
    'load more failure can retry without duplicate concurrent requests',
    (tester) async {
      controller.dispose();
      var fail = true;
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.blocks,
        invoke: (method, args) async {
          if (method == 'resources.query' && args['offset'] == 1 && fail) {
            fail = false;
            throw PlatformException(code: 'failed');
          }
          return invoke(method, args);
        },
      );
      await controller.initialize();
      await controller.refresh(more: true);
      expect(controller.data.loading, false);
      expect(controller.data.hasMore, true);
      expect(controller.data.error, isNotNull);
      controller.actions.onLoadMore();
      controller.actions.onLoadMore();
      await tester.pump();
      expect(controller.data.items.map((i) => i.id), ['a', 'b']);
      expect(controller.data.error, isNull);
    },
  );

  testWidgets(
    'chrome and sort direction callbacks use separate protocol fields',
    (tester) async {
      const channel = MethodChannel('com.nailauncher/resource_window_native');
      final nativeCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            nativeCalls.add(call);
            return call.method == 'toggleMaximize' ? true : null;
          });
      await controller.initialize();
      controller.actions.onSortDirection!(false);
      await tester.pump();
      expect(calls.last.args['sortId'], 'updated');
      expect(calls.last.args['descending'], false);
      calls.clear();
      await controller.refresh();
      expect(calls.single.args['sortId'], isNull);
      expect(calls.single.args['descending'], isNull);
      controller.actions.onDragRegion!(42, [
        const Rect.fromLTWH(0, 0, 200, 42),
      ]);
      controller.actions.onToggleMaximize!();
      controller.actions.onStartDrag!();
      controller.actions.onClose!();
      await tester.pump();
      expect(controller.data.maximized, true);
      expect(nativeCalls.map((c) => c.method), [
        'setDragRegion',
        'toggleMaximize',
        'startDrag',
        'close',
      ]);
      expect((nativeCalls.first.arguments as Map)['exclusions'], [
        {'left': 0.0, 'top': 0.0, 'width': 200.0, 'height': 42.0},
      ]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );

  testWidgets(
    'DTO maps tree, directional sort, crop, card metrics and empty block covers',
    (tester) async {
      controller.dispose();
      controller = ResourceWindowController(
        windowId: 'w',
        kind: FloatingResourceKind.blocks,
        invoke: (method, args) async => {
          ...page(args),
          'hasMore': false,
          'sections': [
            {
              'id': 'folders',
              'title': 'Folders',
              'groups': [
                {
                  'id': 'folder:p',
                  'label': 'Parent',
                  'icon': 'folder',
                  'expanded': true,
                  'dim': true,
                },
              ],
            },
          ],
          'sorts': [
            {'id': 'custom', 'label': 'Custom', 'directional': false},
          ],
          'items': [
            {
              'id': 'a',
              'title': 'A',
              'hasThumb': false,
              'itemCount': 4,
              'useCount': 2,
              'hasParams': true,
              'crop': {'offsetX': .2, 'offsetY': -.3, 'scale': 1.5},
              'strength': .6,
              'secondary': .7,
              'inGeneration': true,
              'bundleCount': 3,
            },
          ],
        },
      );
      await controller.initialize();
      expect(controller.data.sections.single.id, 'folders');
      final group = controller.data.sections.single.groups.single;
      expect(group.icon, ResourceGroupIcon.folder);
      expect(group.expanded, true);
      expect(group.dim, true);
      expect(controller.data.sorts.single.directional, false);
      final item = controller.data.items.single;
      expect(item.thumb, isNull);
      expect(item.crop!.offsetX, .2);
      expect(item.crop!.scale, 1.5);
      expect(item.itemCount, 4);
      expect(item.useCount, 2);
      expect(item.hasParams, true);
      expect(item.strength, .6);
      expect(item.secondary, .7);
      expect(item.inGeneration, true);
      expect(item.bundleCount, 3);
    },
  );

  test('thumbnail cache identity is kind + id + thumbVersion', () {
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

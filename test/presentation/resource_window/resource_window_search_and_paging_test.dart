import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/resource_window_protocol.dart';
import 'package:nai_launcher/presentation/resource_window/resource_window_controller.dart';
import 'package:nai_launcher/presentation/resource_window/resource_window_entry.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_resource_kind.dart';
import 'package:nai_launcher/presentation/ui/resource_window/resource_window_contract.dart';
import '../../helpers/studio_capture_fonts.dart';

class AuditResources extends ResourceWindowController {
  AuditResources({
    required super.kind,
    required super.windowId,
    required super.invoke,
  });
  // The offscreen Flutter engine has no native OLE window; keep the production list and paging.
  @override
  Widget dragWrap(ResourceItem item, Widget child) => child;
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final gallery in [false, true]) {
    testWidgets(
      gallery
          ? 'gallery shortcuts focus search, only Enter records history, and filters can be cleared'
          : 'a failed page stays idle until retried, then appends in place',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(1050, 700);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPhysicalSize);
        final kind = gallery
            ? FloatingResourceKind.gallery
            : FloatingResourceKind.blocks;
        var attempts = 0;
        var recovered = false;
        final history = <String>[];
        final c = AuditResources(
          kind: kind,
          windowId: 'audit',
          invoke: (method, args) async {
            if (method == 'resources.searchConfirmed') {
              history.add(args['query'] as String);
              return null;
            }
            if (method == 'gallery.records') return [];
            if (method != 'resources.query') return null;
            if ((args['offset'] as int) > 0) {
              attempts++;
              expect(args['offset'], 60);
              if (!recovered) throw StateError('audit page unavailable');
              return {
                'requestId': args['requestId'],
                'revision': 1,
                'items': [
                  {'id': 'last', 'title': 'last', 'hasThumb': false},
                ],
                'total': 61,
                'hasMore': false,
                'layout': 'list',
                'cellSize': 132.0,
                'sortId': 'modifiedAt',
              };
            }
            return {
              'requestId': args['requestId'],
              'revision': 1,
              'items': [
                if (!gallery)
                  for (var i = 0; i < 60; i++)
                    {
                      'id': 'block:$i',
                      'title': '${args['query']}示例块 $i',
                      'hasThumb': false,
                    },
              ],
              'timeline': [
                if (gallery &&
                    args['query'] == '' &&
                    !(args['chips'] as List).contains('nai'))
                  ['fixture.png', 0, 256, 256, 100],
              ],
              'total': gallery ? (args['query'] == '' ? 1 : 0) : 120,
              'hasMore': !gallery,
              'layout': gallery ? 'grid' : 'list',
              'cellSize': 132.0,
              'groupMode': 'day',
              'sortId': 'modifiedAt',
              'sections': [
                if (gallery)
                  {
                    'title': '资料库',
                    'groups': [
                      {'id': 'all', 'label': '全部图片', 'count': 1},
                    ],
                  },
              ],
            };
          },
        );
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          ResourceWindowController.native,
          (_) async => null,
        );
        addTearDown(
          () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            ResourceWindowController.native,
            null,
          ),
        );
        await c.initialize();
        await t.pumpWidget(
          ResourceWindowApp(
            controller: c,
            locale: const Locale('zh'),
            arguments: ResourceWindowArguments(kind: kind),
          ),
        );
        await t.pump();
        if (gallery) {
          final field = find.descendant(
            of: find.byKey(const Key('rw-search')),
            matching: find.byType(TextField),
          );
          expect(c.data.total, 1);
          await t.sendKeyEvent(LogicalKeyboardKey.slash);
          await t.pump();
          expect(t.widget<TextField>(field).focusNode!.hasFocus, isTrue);
          t.widget<TextField>(field).focusNode!.unfocus();
          await t.pump();
          await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await t.sendKeyEvent(LogicalKeyboardKey.keyF);
          await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await t.pump();
          expect(t.widget<TextField>(field).focusNode!.hasFocus, isTrue);
          for (final text in ['sil', 'silver', 'silver hair']) {
            await t.enterText(field, text);
            await t.pump(const Duration(milliseconds: 350));
            await t.pump();
          }
          expect(history, isEmpty);
          expect(find.text('无匹配结果'), findsOneWidget);
          await t.testTextInput.receiveAction(TextInputAction.done);
          await t.pump();
          expect(history, ['silver hair']);
          await t.tap(find.widgetWithText(TextButton, '清除筛选').last);
          await t.pump();
          expect(c.data.total, 1);
          expect(history, ['silver hair']);
          c.galleryFilters(naiOnly: true);
          await t.pumpAndSettle();
          expect(find.text('清除筛选'), findsNothing);
          await t.tap(find.text('显示非 NAI 图片'));
          await t.pumpAndSettle();
          expect(c.galleryCriteria.naiOnly, isFalse);
          expect(c.galleryTimeline, hasLength(1));
        } else {
          final sc = t
              .widget<CustomScrollView>(find.byType(CustomScrollView).first)
              .controller!;
          sc.jumpTo(sc.position.maxScrollExtent);
          await t.pump();
          for (var j = 0; j < 12; j++) {
            await t.pump(const Duration(milliseconds: 16));
          }
          expect(attempts, 1);
          expect(c.data.items.length, 60);
          expect(c.data.pageFailed, true);
          recovered = true;
          await t.tap(find.text('下一页加载失败 · 重试'));
          await t.pump();
          expect(attempts, 2);
          expect(c.data.items.length, 61);
          expect(c.data.items.last.id, 'last');
          expect(sc.offset, greaterThan(0));
          final field = find.descendant(
            of: find.byKey(const Key('rw-search')),
            matching: find.byType(TextField),
          );
          await t.enterText(field, '银发');
          await t.pump(const Duration(milliseconds: 350));
          await t.pumpAndSettle();
          expect(sc.offset, 0);
          expect(find.text('银发示例块 0').hitTestable(), findsOneWidget);
        }
        await t.pumpWidget(const SizedBox());
      },
    );
  }
}

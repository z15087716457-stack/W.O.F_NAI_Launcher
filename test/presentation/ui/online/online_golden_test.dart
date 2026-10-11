// 在线画廊基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/online/online_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'online_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  Future<void> tap(WidgetTester t, String key) async {
    await t.tap(find.byKey(Key(key)));
    await t.pumpAndSettle();
  }

  Future<void> openViewer(WidgetTester t) async {
    final card = find.byKey(const Key('online-card-c14'));
    await t.tap(card);
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(card);
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  }

  final works = OnlineFixture.aiTagWorks();
  final scenes =
      <
        (
          String,
          OnlineViewData,
          double,
          bool,
          Future<void> Function(WidgetTester)?,
        )
      >[
        ('search', OnlineFixture.view(), 1600, true, null),
        (
          'favorites',
          OnlineFixture.view(mode: OnlineMode.favorites, selectedKey: 'c14'),
          1600,
          true,
          null,
        ),
        (
          'viewer',
          OnlineFixture.view(selectedKey: 'c14'),
          1600,
          true,
          openViewer,
        ),
        (
          'ranking',
          OnlineFixture.view(mode: OnlineMode.ranking),
          1600,
          false,
          null,
        ),
        (
          'danbooru',
          OnlineFixture.view(source: OnlineSource.danbooru),
          1600,
          false,
          null,
        ),
        (
          'author',
          OnlineFixture.view(mode: OnlineMode.favorites, authorId: 100),
          1600,
          false,
          null,
        ),
        (
          'select',
          OnlineFixture.view(),
          1600,
          false,
          (t) async {
            await tap(t, 'online-multi');
            for (final k in ['c03', 'c14', 't37']) {
              await tap(t, 'online-card-$k');
            }
            await tap(t, 'online-sel-favorite');
          },
        ),
        (
          'send',
          OnlineFixture.view(),
          1600,
          false,
          (t) => tap(t, 'online-insp-send'),
        ),
        (
          'source',
          OnlineFixture.view(),
          1600,
          false,
          (t) => tap(t, 'online-source-card'),
        ),
        (
          'loading',
          OnlineFixture.view(list: const OnlineList(loading: true)),
          1600,
          false,
          null,
        ),
        (
          'end',
          OnlineFixture.view(
            list: OnlineList(
              key: 'end',
              items: works.take(9).toList(),
              pages: 3,
              appendError: const OnlineAppendError(
                page: 4,
                reason: 'AI TAG 响应超时',
              ),
            ),
          ),
          1600,
          false,
          null,
        ),
        (
          'empty',
          OnlineFixture.view(
            list: const OnlineList(key: 'empty'),
            filters: const OnlineFilters(
              model: OnlineModel.v45,
              timeRange: 'y2025',
            ),
            selectedKey: null,
          ),
          1600,
          false,
          null,
        ),
        (
          'login',
          OnlineFixture.view(
            source: OnlineSource.danbooru,
            mode: OnlineMode.favorites,
            statuses: [
              for (final s in OnlineFixture.sources)
                s.source == OnlineSource.danbooru
                    ? const OnlineSourceStatus(
                        source: OnlineSource.danbooru,
                        ranking: true,
                        favorites: true,
                        favoritesWritable: true,
                        ratings: true,
                        dateRange: true,
                        fuzzy: true,
                        account: OnlineAccountState.signedOut,
                      )
                    : s,
            ],
          ),
          1600,
          false,
          null,
        ),
        ('narrow', OnlineFixture.view(), 1000, false, null),
      ];

  for (final (name, data, window, both, interact) in scenes) {
    for (final dark in both ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        await pumpOnline(t, data: data, window: window, dark: dark);
        if (interact != null) {
          await interact(t);
          await t.pumpAndSettle();
        }
        await expectLater(
          find.byKey(const Key('online-capture')),
          matchesGoldenFile('goldens/$file.png'),
        );
        debugDisableShadows = true;
      });
    }
  }
}

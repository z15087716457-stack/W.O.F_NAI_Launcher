import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/ui/online/online_fixture.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_translation.dart';
import 'package:nai_launcher/presentation/wiring/online_prompt_translation.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'online_test_harness.dart';

class _Storage extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
}

PillDocument _translated(PillDocument source) => PillDocument(
  text: '\uE000',
  instances: {
    '\uE000': PillInstance(
      blockId: '',
      translation: TranslationPill(
        source: source.text,
        zh: '翻译结果',
        languageCode: 'zh',
      ),
    ),
  },
);

void main() {
  setUpAll(loadStudioCaptureFonts);
  late RecordingOnlineActions rec;
  late List<String> requests;
  setUp(() {
    rec = RecordingOnlineActions()..translationBuilder = buildOnlineTranslation;
    requests = [];
  });

  Future<void> page(
    WidgetTester t, {
    OnlineViewData? data,
    Future<PillDocument> Function(PillDocument, String)? translator,
  }) async {
    final view = data ?? OnlineFixture.view(selectedKey: 'c14');
    t.view.physicalSize = const Size(1552, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Storage()),
          detailPromptTranslatorProvider.overrideWithValue(
            translator ??
                (document, _) async {
                  requests.add(document.text);
                  return _translated(document);
                },
          ),
        ],
        child: onlineApp(view, rec.actions),
      ),
    );
    await precacheOnline(t, view);
  }

  Finder section(String key, {bool viewer = false}) => find.descendant(
    of: find.byKey(Key(viewer ? 'online-viewer-info' : 'online-inspector')),
    matching: find.byKey(Key(key)),
  );
  Finder action(Finder section) => find.descendant(
    of: section,
    matching: find.byKey(const Key('detail-prompt-translate')),
  );
  Future<TestGesture> enter(WidgetTester t, Finder section) async {
    await t.ensureVisible(section);
    await t.pumpAndSettle();
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getTopLeft(section) + const Offset(8, 8));
    await t.pumpAndSettle();
    return mouse;
  }

  testWidgets(
    'each online prompt reveals its own button; translating and restoring preserve source',
    (t) async {
      await page(t);
      final positive = section('online-insp-prompt');
      final negative = section('online-insp-negative');
      expect(action(positive).hitTestable(), findsNothing);
      expect(action(negative).hitTestable(), findsNothing);
      expect(requests, isEmpty);
      final before = t.getRect(positive);
      final mouse = await enter(t, positive);
      expect(action(positive).hitTestable(), findsOneWidget);
      expect(action(negative).hitTestable(), findsNothing);
      expect(t.getRect(positive), before);
      await _capture(t, 'inspector-hover');
      await t.tap(action(positive));
      await t.pumpAndSettle();
      expect(requests, [OnlineFixture.prompt]);
      expect(find.text('翻译结果'), findsOneWidget);
      await t.tap(action(positive));
      await t.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(find.text('翻译结果'), findsNothing);
      await mouse.moveTo(const Offset(5, 5));
      await t.pumpAndSettle();
      expect(action(positive).hitTestable(), findsNothing);
    },
  );

  testWidgets(
    'site tags keep canonical clickable chips after explicit translation',
    (t) async {
      await page(t);
      final tags = section('online-insp-site-tags');
      await enter(t, tags);
      await t.tap(action(tags));
      await t.pumpAndSettle();
      expect(requests, [OnlineFixture.siteTags.join(', ')]);
      expect(find.text('翻译结果'), findsOneWidget);
      final tag = OnlineFixture.siteTags.first;
      await t.tap(find.byKey(Key('online-site-tag-$tag')));
      expect(rec.calls, contains('tag:$tag'));
    },
  );

  testWidgets(
    'full-screen viewer uses the same hover translation for negative prompts',
    (t) async {
      await page(t);
      final card = find.byKey(const Key('online-card-c14'));
      await t.tap(card);
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(card);
      await t.pumpAndSettle();
      final negative = section('online-insp-negative', viewer: true);
      expect(action(negative).hitTestable(), findsNothing);
      await enter(t, negative);
      await t.tap(action(negative));
      await t.pumpAndSettle();
      expect(requests, [OnlineFixture.negative]);
      expect(find.text('翻译结果'), findsOneWidget);
      await _capture(t, 'viewer-translated');
    },
  );

  testWidgets(
    'changing the work discards a late translation even when its prompt is identical',
    (t) async {
      final pending = Completer<PillDocument>();
      late PillDocument original;
      Future<PillDocument> translate(PillDocument document, String _) {
        original = document;
        return pending.future;
      }

      await page(t, translator: translate);
      final positive = section('online-insp-prompt');
      await enter(t, positive);
      await t.tap(action(positive));
      await t.pump();
      await page(
        t,
        data: OnlineFixture.view(selectedKey: 'c03'),
        translator: translate,
      );
      pending.complete(_translated(original));
      await t.pumpAndSettle();
      expect(find.text('翻译结果'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Booru grouped tags have explicit translation without changing search names',
    (t) async {
      final data = OnlineFixture.view(source: OnlineSource.danbooru);
      await page(t, data: data);
      final group = section('online-tag-group-general');
      await enter(t, group);
      await t.tap(action(group));
      await t.pumpAndSettle();
      final tags = data.detail!.tagGroups[OnlineTagGroup.general]!;
      expect(requests, [tags.map((tag) => tag.name).join(', ')]);
      final tag = tags.first.name;
      await t.tap(find.byKey(Key('online-tag-row-$tag')));
      expect(rec.calls, contains('tag:$tag'));
    },
  );

  testWidgets(
    'jump control fits complete localized labels in wide and narrow windows',
    (t) async {
      for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
        for (final width in [1600.0, 1000.0, 800.0]) {
          await pumpOnline(
            t,
            data: OnlineFixture.view(),
            window: width,
            locale: locale,
          );
          final jump = find.byKey(const Key('online-jump'));
          final label = find.descendant(of: jump, matching: find.byType(Text));
          final paragraph = t.renderObject<RenderParagraph>(label);
          expect(t.getSize(jump).width, greaterThanOrEqualTo(96));
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '$locale $width',
          );
          expect(t.getRect(jump).contains(t.getRect(label).center), isTrue);
          expect(t.takeException(), isNull);
        }
      }
    },
  );
}

Future<void> _capture(WidgetTester t, String name) async {
  final directory = Platform.environment['ONLINE_FEEDBACK_CAPTURES'];
  if (directory == null) return;
  final boundary = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('online-capture')),
  );
  await t.runAsync(() async {
    final bitmap = await boundary.toImage(pixelRatio: 1);
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    Directory(directory).createSync(recursive: true);
    File('$directory/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    bitmap.dispose();
  });
}

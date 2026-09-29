import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/autocomplete/tag_translation_lookup.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Assistant extends Mock implements PromptAssistantService {}

class _Names extends Mock implements TagTranslationLookup {}

class _Wiki implements TagWikiRepository {
  _Wiki(this.body);
  final String body;

  @override
  Future<TagWikiEntry?> find(String tag) async =>
      TagWikiEntry(tag: tag, body: body, sourceUrl: 'https://example.com/$tag');
}

class _Cache extends VisibleTagTranslationCache {
  final Map<String, CachedVisibleTagTranslation> records = {};
  int writes = 0;

  @override
  Future<CachedVisibleTagTranslation?> get({
    required String tag,
    required String route,
    required int promptVersion,
    required String wikiHash,
  }) async => records[tag];

  @override
  Future<void> put({
    required String tag,
    required String route,
    required int promptVersion,
    required String wikiHash,
    required String nameZh,
    String? wikiZh,
  }) async {
    writes++;
    records[tag] = CachedVisibleTagTranslation(nameZh: nameZh, wikiZh: wikiZh);
  }

  @override
  Future<void> close() async {}
}

Future<void> _until(bool Function() ready) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Timed out waiting for translation task');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('already Chinese wiki text does not need a model translation', () {
    expect(
      AutoTagTranslationController.shouldTranslateWiki(
        '这是中文说明，附有 blue_eyes 标签。',
      ),
      isFalse,
    );
    expect(
      AutoTagTranslationController.shouldTranslateWiki(
        'Blue eyes are visible.',
      ),
      isTrue,
    );
  });

  test(
    'known Chinese names skip AI; wiki translates only when opened',
    () async {
      final assistant = _Assistant();
      final names = _Names();
      final cache = _Cache();
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
      when(() => names.translate('blue_eyes')).thenAnswer((_) async => '蓝眼');
      when(
        () => assistant.translateVisibleTag(
          tag: 'blue_eyes',
          wikiBody: 'English wiki.',
          includeWikiTranslation: true,
          existingNameZh: '蓝眼',
          category: any(named: 'category'),
          aliases: any(named: 'aliases'),
          postCount: any(named: 'postCount'),
          relatedTo: any(named: 'relatedTo'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async =>
            const VisibleTagTranslationResult(nameZh: '蓝眼', wikiZh: '英文百科。'),
      );
      final controller = AutoTagTranslationController(
        assistant: assistant,
        localNames: names,
        wiki: _Wiki('English wiki.'),
        cache: cache,
      );
      await controller.setEnabled(true);
      controller.observe(
        surface: 'list',
        tag: 'Blue Eyes',
        visible: true,
        existingNameZh: '蓝眼',
      );
      expect(controller.nameFor('blue_eyes'), '蓝眼');
      verifyNever(
        () => assistant.translateVisibleTag(
          tag: any(named: 'tag'),
          wikiBody: any(named: 'wikiBody'),
          includeWikiTranslation: any(named: 'includeWikiTranslation'),
          existingNameZh: any(named: 'existingNameZh'),
          category: any(named: 'category'),
          aliases: any(named: 'aliases'),
          postCount: any(named: 'postCount'),
          relatedTo: any(named: 'relatedTo'),
          sessionId: any(named: 'sessionId'),
        ),
      );

      controller.requestWiki(surface: 'article', tag: 'blue_eyes');
      await _until(() => controller.wikiFor('blue_eyes') != null);
      expect(controller.wikiFor('blue_eyes'), '英文百科。');
      expect(cache.writes, 1);
      controller.requestWiki(surface: 'article', tag: 'blue_eyes');
      verify(
        () => assistant.translateVisibleTag(
          tag: 'blue_eyes',
          wikiBody: 'English wiki.',
          includeWikiTranslation: true,
          existingNameZh: '蓝眼',
          category: any(named: 'category'),
          aliases: any(named: 'aliases'),
          postCount: any(named: 'postCount'),
          relatedTo: any(named: 'relatedTo'),
          sessionId: any(named: 'sessionId'),
        ),
      ).called(1);
      controller.dispose();
    },
  );

  test(
    'unknown tag sends wiki as context without translating it early',
    () async {
      final assistant = _Assistant();
      final names = _Names();
      final requests = <bool>[];
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
      when(() => names.translate('artist_name')).thenAnswer((_) async => null);
      when(
        () => assistant.translateVisibleTag(
          tag: 'artist_name',
          wikiBody: 'English biography and tag context.',
          includeWikiTranslation: any(named: 'includeWikiTranslation'),
          existingNameZh: any(named: 'existingNameZh'),
          category: any(named: 'category'),
          aliases: any(named: 'aliases'),
          postCount: any(named: 'postCount'),
          relatedTo: any(named: 'relatedTo'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((invocation) async {
        final translateWiki =
            invocation.namedArguments[#includeWikiTranslation] as bool;
        expect(invocation.namedArguments[#category], 'artist');
        expect(invocation.namedArguments[#aliases], ['artist_alias']);
        expect(invocation.namedArguments[#postCount], 123);
        expect(invocation.namedArguments[#relatedTo], 'related_tag');
        requests.add(translateWiki);
        return VisibleTagTranslationResult(
          nameZh: '画师名',
          wikiZh: translateWiki ? '英文传记与标签语境。' : null,
        );
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        localNames: names,
        wiki: _Wiki('English biography and tag context.'),
        cache: _Cache(),
      );
      await controller.setEnabled(true);
      controller.observe(
        surface: 'list',
        tag: 'artist_name',
        visible: true,
        tagContext: const AutoTagTranslationContext(
          category: 'artist',
          aliases: ['artist_alias'],
          postCount: 123,
          relatedTo: 'related_tag',
        ),
      );
      await _until(() => controller.nameFor('artist_name') != null);
      expect(requests, [false]);
      expect(controller.wikiFor('artist_name'), isNull);

      controller.requestWiki(surface: 'article', tag: 'artist_name');
      await _until(() => controller.wikiFor('artist_name') != null);
      expect(requests, [false, true]);
      controller.dispose();
    },
  );

  test('newly visible tags take priority after the active request', () async {
    final assistant = _Assistant();
    final names = _Names();
    final cache = _Cache();
    final calls = <String>[];
    final completions = <String, Completer<VisibleTagTranslationResult>>{
      for (final tag in ['first', 'second', 'third'])
        tag: Completer<VisibleTagTranslationResult>(),
    };
    when(() => assistant.translateRouteFingerprint()).thenReturn('route');
    when(() => names.translate(any())).thenAnswer((_) async => null);
    when(
      () => assistant.translateVisibleTag(
        tag: any(named: 'tag'),
        wikiBody: any(named: 'wikiBody'),
        includeWikiTranslation: any(named: 'includeWikiTranslation'),
        existingNameZh: any(named: 'existingNameZh'),
        category: any(named: 'category'),
        aliases: any(named: 'aliases'),
        postCount: any(named: 'postCount'),
        relatedTo: any(named: 'relatedTo'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((invocation) {
      final tag = invocation.namedArguments[#tag] as String;
      calls.add(tag);
      return completions[tag]!.future;
    });
    final controller = AutoTagTranslationController(
      assistant: assistant,
      localNames: names,
      wiki: _Wiki('Context'),
      cache: cache,
      maxConcurrentRequests: 1,
    );
    await controller.setEnabled(true);
    controller.observe(surface: 'list', tag: 'first', visible: true);
    await _until(() => calls.length == 1);
    controller.observe(surface: 'list', tag: 'second', visible: true);
    controller.observe(surface: 'list', tag: 'third', visible: true);
    expect(calls, ['first']);
    completions['first']!.complete(
      const VisibleTagTranslationResult(nameZh: '第一'),
    );
    await _until(() => calls.length == 2);
    expect(calls, ['first', 'third']);
    completions['third']!.complete(
      const VisibleTagTranslationResult(nameZh: '第三'),
    );
    await _until(() => calls.length == 3);
    expect(calls, ['first', 'third', 'second']);
    completions['second']!.complete(
      const VisibleTagTranslationResult(nameZh: '第二'),
    );
    await _until(() => controller.activeRequests == 0);
    expect(cache.writes, 3);
    controller.dispose();
  });

  test('never has more than five model requests in flight', () async {
    final assistant = _Assistant();
    final names = _Names();
    final calls = <String>[];
    final completions = <String, Completer<VisibleTagTranslationResult>>{
      for (var index = 0; index < 6; index++)
        'tag_$index': Completer<VisibleTagTranslationResult>(),
    };
    when(() => assistant.translateRouteFingerprint()).thenReturn('route');
    when(() => names.translate(any())).thenAnswer((_) async => null);
    when(
      () => assistant.translateVisibleTag(
        tag: any(named: 'tag'),
        wikiBody: any(named: 'wikiBody'),
        includeWikiTranslation: any(named: 'includeWikiTranslation'),
        existingNameZh: any(named: 'existingNameZh'),
        category: any(named: 'category'),
        aliases: any(named: 'aliases'),
        postCount: any(named: 'postCount'),
        relatedTo: any(named: 'relatedTo'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((invocation) {
      final tag = invocation.namedArguments[#tag] as String;
      calls.add(tag);
      return completions[tag]!.future;
    });
    final controller = AutoTagTranslationController(
      assistant: assistant,
      localNames: names,
      wiki: _Wiki('Context'),
      cache: _Cache(),
    );
    await controller.setEnabled(true);
    for (var index = 0; index < 6; index++) {
      controller.observe(surface: 'list', tag: 'tag_$index', visible: true);
    }
    await _until(() => calls.length == 5);
    expect(controller.activeRequests, 5);
    completions[calls.first]!.complete(
      const VisibleTagTranslationResult(nameZh: '完成'),
    );
    await _until(() => calls.length == 6);
    expect(controller.activeRequests, 5);
    for (final entry in completions.entries) {
      if (!entry.value.isCompleted) {
        entry.value.complete(const VisibleTagTranslationResult(nameZh: '完成'));
      }
    }
    await _until(() => controller.activeRequests == 0);
    controller.dispose();
  });

  test('turning auto translation off cancels active model work', () async {
    final assistant = _Assistant();
    final names = _Names();
    final completion = Completer<VisibleTagTranslationResult>();
    final started = Completer<String>();
    when(() => assistant.translateRouteFingerprint()).thenReturn('route');
    when(() => names.translate('unfinished')).thenAnswer((_) async => null);
    when(
      () => assistant.translateVisibleTag(
        tag: 'unfinished',
        wikiBody: 'English context',
        includeWikiTranslation: false,
        existingNameZh: null,
        category: null,
        aliases: const [],
        postCount: null,
        relatedTo: null,
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((invocation) {
      started.complete(invocation.namedArguments[#sessionId] as String);
      return completion.future;
    });
    when(
      () => assistant.cancelCurrentTask(sessionId: any(named: 'sessionId')),
    ).thenAnswer((_) async {});
    final controller = AutoTagTranslationController(
      assistant: assistant,
      localNames: names,
      wiki: _Wiki('English context'),
      cache: _Cache(),
    );
    await controller.setEnabled(true);
    controller.observe(surface: 'list', tag: 'unfinished', visible: true);
    final session = await started.future;
    await controller.setEnabled(false);
    verify(() => assistant.cancelCurrentTask(sessionId: session)).called(1);
    completion.complete(const VisibleTagTranslationResult(nameZh: '未完成'));
    await _until(() => controller.activeRequests == 0);
    controller.dispose();
  });
}

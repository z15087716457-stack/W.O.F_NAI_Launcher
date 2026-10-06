import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/wiki/auto_tag_translation_controller.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Assistant extends Mock implements PromptAssistantService {}

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
    bool allowEarlierVersion = false,
  }) async => records[tag];

  @override
  Future<void> put({
    required String tag,
    required String route,
    required int promptVersion,
    required String wikiHash,
    required String nameZh,
    String? wikiZh,
    String? wikiOriginal,
    String? definition,
    String nameLanguage = 'zh',
    String definitionLanguage = 'zh',
  }) async {
    writes++;
    records[tag] = CachedVisibleTagTranslation(
      nameZh: nameZh,
      wikiZh: wikiZh,
      wikiOriginal: wikiOriginal,
      definition: definition,
      wikiHash: wikiHash,
      nameLanguage: nameLanguage,
      definitionLanguage: definitionLanguage,
    );
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

void _respond(
  _Assistant assistant,
  Future<VisibleTagTranslationResult> Function(Invocation) handler,
) {
  when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
      glossary: any(named: 'glossary'),
      sessionId: any(named: 'sessionId'),
    ),
  ).thenAnswer(handler);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'shared activity separates queued tasks, per-tag errors and deduplicated manual retries',
    () async {
      final assistant = _Assistant();
      final calls = <String>[];
      final pending = {
        for (final tag in ['first', 'second'])
          tag: Completer<VisibleTagTranslationResult>(),
      };
      _respond(assistant, (call) {
        final tag = call.namedArguments[#tag] as String;
        calls.add(tag);
        return pending[tag]!.future;
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('English context'),
        cache: _Cache(),
        maxConcurrentRequests: 1,
      );
      addTearDown(controller.dispose);
      await controller.setEnabled(true);
      controller.observe(surface: 'wiki', tag: 'first', visible: true);
      await _until(() => calls.length == 1);
      controller.observe(surface: 'expansion', tag: 'first', visible: true);
      controller.observe(surface: 'wiki', tag: 'second', visible: true);
      expect(
        controller.activityFor('first')!.phase,
        TagTranslationPhase.translating,
      );
      expect(
        controller.activityFor('second')!.phase,
        TagTranslationPhase.queued,
      );
      expect(calls, ['first']);
      pending['first']!.completeError(StateError('first failed'));
      await _until(() => calls.length == 2);
      pending['second']!.completeError(StateError('second failed'));
      await _until(() => controller.activeRequests == 0);
      expect(controller.activityFor('first')!.error, contains('first failed'));
      expect(
        controller.activityFor('second')!.error,
        contains('second failed'),
      );
      await controller.setEnabled(false);
      expect(
        controller.activityFor('first')!.phase,
        TagTranslationPhase.failed,
      );
      pending['first'] = Completer<VisibleTagTranslationResult>();
      controller.retranslateName(surface: 'expansion', tag: 'first');
      controller.retranslateName(surface: 'wiki', tag: 'first');
      await _until(() => calls.length == 3);
      expect(
        controller.activityFor('first')!.phase,
        TagTranslationPhase.translating,
      );
      expect(
        controller.activityFor('second')!.phase,
        TagTranslationPhase.failed,
      );
      pending['first']!.complete(
        const VisibleTagTranslationResult(nameZh: '已重试'),
      );
      await _until(() => controller.activeRequests == 0);
      expect(controller.activityFor('first'), isNull);
      expect(controller.nameFor('first'), '已重试');
      expect(calls, ['first', 'second', 'first']);
    },
  );

  test(
    'article failure persists on reopening without corrupting a translated name',
    () async {
      final assistant = _Assistant();
      var calls = 0;
      var pending = Completer<VisibleTagTranslationResult>();
      _respond(assistant, (call) {
        calls++;
        expect(call.namedArguments[#includeWikiTranslation], isTrue);
        return pending.future;
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('English context'),
        cache: _Cache(),
      );
      addTearDown(controller.dispose);
      await controller.setEnabled(true);
      controller.observe(
        surface: 'list',
        tag: 'first',
        visible: true,
        existingNameZh: '已有名称',
      );
      controller.requestWiki(surface: 'article', tag: 'first');
      await _until(() => calls == 1);
      expect(controller.activityFor('first'), isNull);
      expect(
        controller.activityFor('first', wiki: true)!.phase,
        TagTranslationPhase.translating,
      );
      pending.completeError(StateError('body failed'));
      await _until(() => controller.activeRequests == 0);
      expect(controller.activityFor('first'), isNull);
      expect(
        controller.activityFor('first', wiki: true)!.error,
        contains('body failed'),
      );
      controller.clearSurface('article');
      controller.requestWiki(surface: 'article', tag: 'first');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(calls, 1);
      pending = Completer<VisibleTagTranslationResult>();
      controller.retranslateWiki(surface: 'article', tag: 'first');
      controller.retranslateWiki(surface: 'mini-wiki', tag: 'first');
      await _until(() => calls == 2);
      pending.complete(
        const VisibleTagTranslationResult(nameZh: '新名称', wikiZh: '正文译文'),
      );
      await _until(() => controller.activeRequests == 0);
      expect(controller.activityFor('first', wiki: true), isNull);
      controller.observe(
        surface: 'list',
        tag: 'first',
        visible: true,
        existingNameZh: '已有名称',
      );
      expect(controller.nameFor('first'), '新名称');
      expect(controller.wikiFor('first'), '正文译文');
    },
  );

  test(
    'manual name retry replaces cached name without discarding its article',
    () async {
      final assistant = _Assistant();
      final cache = _Cache();
      cache.records['first'] = const CachedVisibleTagTranslation(
        nameZh: '旧名称',
        wikiZh: '已缓存正文',
        wikiOriginal: 'Cached original',
        definition: '旧释义',
        wikiHash: 'hash',
      );
      var calls = 0;
      _respond(assistant, (call) async {
        calls++;
        expect(call.namedArguments[#includeWikiTranslation], isFalse);
        expect(call.namedArguments[#existingNameZh], isNull);
        return const VisibleTagTranslationResult(
          nameZh: '新名称',
          definition: '新释义',
        );
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('English context'),
        cache: cache,
      );
      addTearDown(controller.dispose);
      controller.retranslateName(surface: 'list', tag: 'first');
      await _until(() => controller.activeRequests == 0);
      expect(calls, 1);
      expect(cache.records['first']!.nameZh, '新名称');
      expect(cache.records['first']!.definition, '新释义');
      expect(cache.records['first']!.wikiZh, '已缓存正文');
      expect(cache.records['first']!.wikiOriginal, 'Cached original');
    },
  );

  test(
    'route changes ignore stale failures and translate with the new route',
    () async {
      final assistant = _Assistant();
      final pending = <Completer<VisibleTagTranslationResult>>[];
      _respond(assistant, (_) {
        final completion = Completer<VisibleTagTranslationResult>();
        pending.add(completion);
        return completion.future;
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('English context'),
        cache: _Cache(),
      );
      addTearDown(controller.dispose);
      await controller.setEnabled(true);
      controller.observe(surface: 'list', tag: 'first', visible: true);
      await _until(() => pending.length == 1);
      when(() => assistant.translateRouteFingerprint()).thenReturn('new-route');
      controller.routeChanged();
      pending.first.completeError(StateError('stale failure'));
      await _until(() => pending.length == 2);
      expect(controller.lastError, isNull);
      expect(
        controller.activityFor('first')!.phase,
        TagTranslationPhase.translating,
      );
      pending.last.complete(const VisibleTagTranslationResult(nameZh: '新接口译文'));
      await _until(() => controller.activeRequests == 0);
      expect(controller.activityFor('first'), isNull);
      expect(controller.nameFor('first'), '新接口译文');
    },
  );

  test(
    'unopened visible tag sends full wiki, caches its definition and restores it without a new request',
    () async {
      final assistant = _Assistant();
      final cache = _Cache();
      const body =
          'A hair bunch falls from the bangs to between the eyes.\n\nFull remaining article with examples and related tags.';
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
          glossary: any(named: 'glossary'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((call) async {
        expect(call.namedArguments[#wikiBody], body);
        expect(call.namedArguments[#includeWikiTranslation], isFalse);
        return const VisibleTagTranslationResult(
          nameZh: '眼间发',
          definition: '从刘海中央垂下、长度达到双眼之间的一束头发。',
        );
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki(body),
        cache: cache,
      );
      addTearDown(controller.dispose);
      await controller.setEnabled(true);
      controller.observe(
        surface: 'list',
        tag: 'hair_between_eyes',
        visible: true,
      );
      await _until(
        () =>
            controller.activeRequests == 0 &&
            controller.nameFor('hair_between_eyes') != null,
      );
      expect(controller.wikiFor('hair_between_eyes'), isNull);
      expect(
        controller.definitionFor('hair_between_eyes'),
        '从刘海中央垂下、长度达到双眼之间的一束头发。',
      );
      expect(
        cache.records['hair_between_eyes']!.definition,
        controller.definitionFor('hair_between_eyes'),
      );
      expect(cache.records['hair_between_eyes']!.definitionLanguage, 'zh');
      final writes = cache.writes;
      controller.routeChanged();
      await _until(() => controller.activeRequests == 0);
      expect(cache.writes, writes);
      expect(
        controller.definitionFor('hair_between_eyes'),
        cache.records['hair_between_eyes']!.definition,
      );
    },
  );

  test(
    'one Wiki request sends candidate context and caches only model-selected validated links',
    () async {
      final assistant = _Assistant();
      final cache = _Cache();
      final entries = {
        for (final name in ['hat', 'visor', 'blue_eyes', 'peaked_cap'])
          name: CompletionCandidate(
            canonicalTag: name,
            category: name == 'visor'
                ? TagCategory.copyright
                : TagCategory.general,
            postCount: 1,
            matchKind: CompletionMatchKind.englishExact,
            sources: const {CompletionSourceKind.base},
          ),
      };
      final links = WikiTagLinks(
        exactLookup: (keys) async => {
          for (final name in keys)
            if (entries[name] case final item?) name: item,
        },
      );
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
      var requests = 0;
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
          glossary: any(named: 'glossary'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((invocation) async {
        requests++;
        final glossary =
            invocation.namedArguments[#glossary] as List<Map<String, Object>>;
        final visor = glossary.singleWhere((item) => item['tag'] == 'visor');
        expect(visor['category'], 'copyright');
        expect(visor['matched_texts'], ['visor']);
        return const VisibleTagTranslationResult(
          nameZh: '遮阳帽',
          wikiZh:
              '[帽子](wof-tag:hat) 的部件叫 visor。帽子只是普通重复文字。'
              '示例：[帽子](wof-tag:hat) 和 [鸭舌帽](wof-tag:peaked_cap)。[无效](wof-tag:missing)',
          wikiOriginal:
              'A [hat](wof-tag:hat) has a visor.\n\nExamples\n- [Hat](wof-tag:hat)\n- [Unknown](wof-tag:missing)',
        );
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('A hat has a visor. Blue eyes.'),
        cache: cache,
        wikiLinks: links,
      );
      addTearDown(controller.dispose);
      await controller.setEnabled(true);
      controller.requestWiki(surface: 'article', tag: 'visor_cap');
      await _until(() => controller.wikiFor('visor_cap') != null);
      expect(requests, 1);
      final result = controller.wikiFor('visor_cap')!;
      expect(result, contains('的部件叫 visor。帽子只是普通重复文字。'));
      expect(result, endsWith('无效'));
      expect(result, isNot(contains('wof-tag:missing')));
      expect(
        (await links.resolve(
          result,
        )).links.map((link) => link.candidate.canonicalTag),
        ['hat', 'hat', 'peaked_cap'],
      );
      expect(cache.records['visor_cap']!.wikiZh, result);
      final source = controller.wikiOriginalFor('visor_cap')!;
      expect(source, endsWith('- Unknown'));
      expect(
        (await links.resolve(
          source,
        )).links.map((link) => link.candidate.canonicalTag),
        ['hat', 'hat'],
      );
      expect(cache.records['visor_cap']!.wikiOriginal, source);
      controller.routeChanged();
      expect(controller.wikiOriginalFor('visor_cap'), isNull);
    },
  );

  test(
    'a previous prompt-version article loads without another model call',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'legacy_wiki_queue_',
      );
      final cache = VisibleTagTranslationCache(
        databasePath: () async => '${directory.path}/cache.db',
      );
      const source = 'Blue eyes.';
      await cache.put(
        tag: 'blue_eyes',
        route: 'route',
        promptVersion: 2,
        wikiHash: sha256.convert(utf8.encode(source)).toString(),
        nameZh: '蓝眼',
        wikiZh: '帽子以及 visor。blue_eyes',
      );
      final assistant = _Assistant();
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki(source),
        cache: cache,
      );
      addTearDown(() async {
        await cache.close();
        controller.dispose();
        await directory.delete(recursive: true);
      });
      await controller.setEnabled(true);
      controller.requestWiki(surface: 'article', tag: 'blue_eyes');
      await _until(
        () =>
            controller.activeRequests == 0 &&
            controller.wikiFor('blue_eyes') != null,
      );
      expect(controller.wikiFor('blue_eyes'), '帽子以及 visor。blue_eyes');
      expect(
        await cache.get(
          tag: 'blue_eyes',
          route: 'route',
          promptVersion: 3,
          wikiHash: sha256.convert(utf8.encode(source)).toString(),
        ),
        isNull,
      );
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
          glossary: any(named: 'glossary'),
          sessionId: any(named: 'sessionId'),
        ),
      );
    },
  );
  test(
    'closing while terminology loads prevents delayed model dispatch',
    () async {
      final assistant = _Assistant();
      final cache = _Cache();
      final pending = Completer<Map<String, CompletionCandidate>>();
      var started = false;
      final links = WikiTagLinks(
        exactLookup: (_) {
          started = true;
          return pending.future;
        },
      );
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('Blue eyes.'),
        cache: cache,
        wikiLinks: links,
      );
      await controller.setEnabled(true);
      controller.requestWiki(surface: 'article', tag: 'blue_eyes');
      await _until(() => started);
      controller.dispose();
      pending.complete({});
      await _until(() => controller.activeRequests == 0);
      expect(cache.writes, 0);
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
          glossary: any(named: 'glossary'),
          sessionId: any(named: 'sessionId'),
        ),
      );
    },
  );
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
    'manual Wiki retry bypasses cache, deduplicates and retains old body on failure',
    () async {
      final assistant = _Assistant();
      final cache = _Cache();
      cache.records['blue_eyes'] = const CachedVisibleTagTranslation(
        nameZh: '蓝眼',
        wikiZh: '旧译文',
        wikiOriginal: 'Old formatted original.',
      );
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
      var pending = Completer<VisibleTagTranslationResult>();
      var calls = 0;
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
          glossary: any(named: 'glossary'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) {
        calls++;
        return pending.future;
      });
      final controller = AutoTagTranslationController(
        assistant: assistant,
        wiki: _Wiki('English wiki.'),
        cache: cache,
      );
      await controller.setEnabled(true);
      controller.requestWiki(surface: 'article', tag: 'blue_eyes');
      await _until(
        () =>
            controller.wikiFor('blue_eyes') != null &&
            controller.activeRequests == 0,
      );
      expect(calls, 0);
      await controller.setEnabled(false);
      controller.retranslateWiki(surface: 'article', tag: 'blue_eyes');
      controller.retranslateWiki(surface: 'article', tag: 'blue_eyes');
      await _until(() => calls == 1);
      expect(controller.isWikiTranslating('blue_eyes'), isTrue);
      expect(controller.wikiFor('blue_eyes'), '旧译文');
      pending.completeError(StateError('retry failed'));
      await _until(() => controller.activeRequests == 0);
      expect(controller.wikiFor('blue_eyes'), '旧译文');
      expect(cache.writes, 0);
      expect(
        controller.wikiOriginalFor('blue_eyes'),
        'Old formatted original.',
      );
      expect(controller.lastError, contains('retry failed'));
      pending = Completer<VisibleTagTranslationResult>();
      controller.retranslateWiki(surface: 'article', tag: 'blue_eyes');
      await _until(() => calls == 2);
      pending.complete(
        const VisibleTagTranslationResult(nameZh: '蓝眼', wikiZh: '新译文'),
      );
      await _until(() => controller.activeRequests == 0);
      expect(controller.wikiFor('blue_eyes'), '新译文');
      expect(cache.records['blue_eyes']!.wikiZh, '新译文');
      expect(controller.wikiOriginalFor('blue_eyes'), isNull);
      expect(cache.records['blue_eyes']!.wikiOriginal, isNull);
      expect(cache.writes, 1);
      expect(controller.enabled, isFalse);
      controller.dispose();
    },
  );

  test(
    'known Chinese names skip AI; wiki translates only when opened',
    () async {
      final assistant = _Assistant();
      final cache = _Cache();
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
          glossary: any(named: 'glossary'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer(
        (_) async =>
            const VisibleTagTranslationResult(nameZh: '蓝眼', wikiZh: '英文百科。'),
      );
      final controller = AutoTagTranslationController(
        assistant: assistant,
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
          glossary: any(named: 'glossary'),
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
          glossary: any(named: 'glossary'),
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
      final requests = <bool>[];
      when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
          glossary: any(named: 'glossary'),
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
    final cache = _Cache();
    final calls = <String>[];
    final completions = <String, Completer<VisibleTagTranslationResult>>{
      for (final tag in ['first', 'second', 'third'])
        tag: Completer<VisibleTagTranslationResult>(),
    };
    when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
        glossary: any(named: 'glossary'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((invocation) {
      final tag = invocation.namedArguments[#tag] as String;
      calls.add(tag);
      return completions[tag]!.future;
    });
    final controller = AutoTagTranslationController(
      assistant: assistant,
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
    final calls = <String>[];
    final completions = <String, Completer<VisibleTagTranslationResult>>{
      for (var index = 0; index < 6; index++)
        'tag_$index': Completer<VisibleTagTranslationResult>(),
    };
    when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
        glossary: any(named: 'glossary'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((invocation) {
      final tag = invocation.namedArguments[#tag] as String;
      calls.add(tag);
      return completions[tag]!.future;
    });
    final controller = AutoTagTranslationController(
      assistant: assistant,
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
    final completion = Completer<VisibleTagTranslationResult>();
    final started = Completer<String>();
    when(() => assistant.translateRouteFingerprint()).thenReturn('route');
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
        glossary: any(named: 'glossary'),
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

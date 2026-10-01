import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/prompt_assistant/services/prompt_assistant_service.dart';
import '../../presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../presentation/prompt_assistant/models/prompt_assistant_models.dart';
import '../../presentation/providers/locale_provider.dart';
import '../autocomplete/tag_translation_lookup.dart';
import '../utils/tag_normalizer.dart';
import 'tag_wiki_repository.dart';
import 'visible_tag_translation_cache.dart';
import 'wiki_tag_links.dart';

final autoTagTranslationProvider =
    ChangeNotifierProvider<AutoTagTranslationController>((ref) {
      final controller = AutoTagTranslationController(
        assistant: ref.read(promptAssistantServiceProvider),
        localNames: ref.read(tagTranslationLookupProvider),
        wiki: ref.read(tagWikiRepositoryProvider),
        cache: VisibleTagTranslationCache(),
        wikiLinks: ref.read(wikiTagLinksProvider),
        readingLanguage: () => ref
            .read(promptAssistantServiceProvider)
            .targetLanguageFor(LauncherInterface.tagTranslate),
      );
      ref.listen(promptAssistantConfigProvider, (_, __) {
        controller.routeChanged();
      });
      ref.listen(localeNotifierProvider, (_, __) => controller.routeChanged());
      unawaited(controller.loadPreference());
      return controller;
    });

class _VisibleTask {
  const _VisibleTask(this.tag, this.wiki, this.priority, {this.force = false});
  final String tag;
  final bool wiki;
  final int priority;
  final bool force;
}

class AutoTagTranslationContext {
  const AutoTagTranslationContext({
    this.category,
    this.aliases = const [],
    this.postCount,
    this.relatedTo,
  });

  final String? category;
  final List<String> aliases;
  final int? postCount;
  final String? relatedTo;
}

/// Global queue shared by tag expansion and the encyclopedia. Only the latest
/// visible requests wait in the queue; requests already sent may finish and
/// populate the cache after the user scrolls away.
class AutoTagTranslationController extends ChangeNotifier {
  AutoTagTranslationController({
    required PromptAssistantService assistant,
    required TagTranslationLookup localNames,
    required TagWikiRepository wiki,
    required VisibleTagTranslationCache cache,
    WikiTagLinks? wikiLinks,
    this.maxConcurrentRequests = 5,
    String Function()? readingLanguage,
  }) : _assistant = assistant,
       _localNames = localNames,
       _wiki = wiki,
       _cache = cache,
       _wikiLinks = wikiLinks,
       _readingLanguage = readingLanguage ?? (() => 'zh');

  static const _preferenceKey = 'auto_visible_tag_translation_enabled';
  final PromptAssistantService _assistant;
  final TagTranslationLookup _localNames;
  final TagWikiRepository _wiki;
  final VisibleTagTranslationCache _cache;
  final WikiTagLinks? _wikiLinks;
  final int maxConcurrentRequests;
  final String Function() _readingLanguage;
  final Map<String, Set<String>> _visibleBySurface = {};
  final Map<String, String> _wikiBySurface = {};
  final Map<String, _VisibleTask> _pending = {};
  final Set<String> _inFlight = {};
  final Set<String> _wikiInFlight = {};
  final Map<String, String> _sessions = {};
  final Map<String, String> _names = {};
  final Map<String, String> _wikiBodies = {};
  final Map<String, AutoTagTranslationContext> _contexts = {};
  final Set<String> _failed = {};
  int _priority = 0;
  int _routeEpoch = 0;
  int _active = 0;
  bool _enabled = false;
  bool _preferenceChanged = false;
  bool _disposed = false;
  String? _route;
  String? lastError;

  bool get enabled => _enabled;
  int get activeRequests => _active;
  String? nameFor(String tag) => _names[TagNormalizer.normalize(tag)];
  String? wikiFor(String tag) => _wikiBodies[TagNormalizer.normalize(tag)];
  String? wikiErrorFor(String tag) =>
      _failed.contains(TagNormalizer.normalize(tag)) ? lastError : null;
  bool isTranslating(String tag) =>
      _inFlight.contains(TagNormalizer.normalize(tag));
  bool isWikiTranslating(String tag) {
    final canonical = TagNormalizer.normalize(tag);
    return _wikiInFlight.contains(canonical) ||
        _pending[canonical]?.wiki == true;
  }

  /// An explicit retry works even with automatic translation turned off.
  /// The old body stays visible until the complete new request succeeds.
  void retranslateWiki({required String surface, required String tag}) {
    final canonical = TagNormalizer.normalize(tag);
    if (canonical.isEmpty || isWikiTranslating(canonical)) return;
    _visibleBySurface.putIfAbsent(surface, () => <String>{}).add(canonical);
    _wikiBySurface[surface] = canonical;
    _failed.remove(canonical);
    lastError = null;
    _pending[canonical] = _VisibleTask(
      canonical,
      true,
      ++_priority,
      force: true,
    );
    notifyListeners();
    _pump();
  }

  void routeChanged() {
    _routeEpoch++;
    _route = null;
    _names.clear();
    _wikiBodies.clear();
    _failed.clear();
    lastError = null;
    notifyListeners();
    _queueVisible();
  }

  Future<void> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed || _preferenceChanged) return;
    _enabled = prefs.getBool(_preferenceKey) ?? false;
    notifyListeners();
    _queueVisible();
  }

  Future<void> setEnabled(bool enabled) async {
    _preferenceChanged = true;
    _enabled = enabled;
    lastError = null;
    _failed.clear();
    if (!enabled) {
      _pending.clear();
      for (final session in _sessions.values) {
        unawaited(_assistant.cancelCurrentTask(sessionId: session));
      }
    }
    notifyListeners();
    if (enabled) _queueVisible();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preferenceKey, enabled);
  }

  void observe({
    required String surface,
    required String tag,
    required bool visible,
    String? existingNameZh,
    AutoTagTranslationContext? tagContext,
  }) {
    final canonical = TagNormalizer.normalize(tag);
    if (canonical.isEmpty) return;
    final tags = _visibleBySurface.putIfAbsent(surface, () => <String>{});
    if (tagContext != null) _contexts[canonical] = tagContext;
    if (_readingLanguage() == 'zh' && existingNameZh?.trim().isNotEmpty == true) {
      _names[canonical] = existingNameZh!.trim();
    }
    if (visible) {
      tags.add(canonical);
      if (_enabled && !_names.containsKey(canonical)) {
        _enqueue(canonical, wiki: false);
      }
    } else {
      tags.remove(canonical);
      if (!_isVisible(canonical)) _pending.remove(canonical);
    }
  }

  /// Call only when the wiki body has actually been opened on screen.
  void requestWiki({
    required String surface,
    required String tag,
    AutoTagTranslationContext? tagContext,
  }) {
    final canonical = TagNormalizer.normalize(tag);
    if (canonical.isEmpty) return;
    _visibleBySurface.putIfAbsent(surface, () => <String>{}).add(canonical);
    if (tagContext != null) _contexts[canonical] = tagContext;
    _wikiBySurface[surface] = canonical;
    _failed.remove(canonical);
    if (_enabled && !_wikiBodies.containsKey(canonical)) {
      _enqueue(canonical, wiki: true);
    }
  }

  void clearSurface(String surface) {
    final oldWiki = _wikiBySurface.remove(surface);
    if (oldWiki != null && !_wikiBySurface.values.contains(oldWiki)) {
      final pending = _pending[oldWiki];
      if (pending?.wiki == true) {
        if (_names.containsKey(oldWiki)) {
          _pending.remove(oldWiki);
        } else {
          _pending[oldWiki] = _VisibleTask(oldWiki, false, pending!.priority);
        }
      }
    }
    final removed = _visibleBySurface.remove(surface);
    if (removed == null) return;
    for (final tag in removed) {
      if (!_isVisible(tag)) _pending.remove(tag);
    }
  }

  bool _isVisible(String tag) =>
      _visibleBySurface.values.any((tags) => tags.contains(tag));

  void _queueVisible() {
    if (!_enabled) return;
    for (final tag in _wikiBySurface.values) {
      if (!_wikiBodies.containsKey(tag)) _enqueue(tag, wiki: true);
    }
    for (final tags in _visibleBySurface.values) {
      for (final tag in tags) {
        if (!_names.containsKey(tag)) _enqueue(tag, wiki: false);
      }
    }
  }

  void _enqueue(String tag, {required bool wiki}) {
    if (!_enabled || _failed.contains(tag)) return;
    final previous = _pending[tag];
    _pending[tag] = _VisibleTask(
      tag,
      wiki || previous?.wiki == true,
      ++_priority,
      force: previous?.force ?? false,
    );
    _pump();
  }

  void _pump() {
    if (_disposed) return;
    while (_active < maxConcurrentRequests) {
      final eligible =
          _pending.values
              .where(
                (task) =>
                    (_enabled || task.force) &&
                    _isVisible(task.tag) &&
                    !_inFlight.contains(task.tag) &&
                    !_failed.contains(task.tag),
              )
              .toList()
            ..sort((a, b) {
              if (a.wiki != b.wiki) return a.wiki ? -1 : 1;
              return b.priority.compareTo(a.priority);
            });
      if (eligible.isEmpty) return;
      final task = eligible.first;
      _pending.remove(task.tag);
      _inFlight.add(task.tag);
      if (task.wiki) _wikiInFlight.add(task.tag);
      _active++;
      notifyListeners();
      unawaited(
        _run(task).whenComplete(() {
          _active--;
          _inFlight.remove(task.tag);
          _wikiInFlight.remove(task.tag);
          if (!_disposed) {
            notifyListeners();
            _pump();
          }
        }),
      );
    }
  }

  Future<void> _run(_VisibleTask task) async {
    final epoch = _routeEpoch;
    try {
      String? localName;
      try {
        if (_readingLanguage() == 'zh') {
          localName = await _localNames.translate(task.tag);
        }
      } catch (_) {
        // The optional installed dictionary must not block model translation.
      }
      if (_disposed || epoch != _routeEpoch) return;
      if (localName != null) {
        _names[task.tag] = localName;
        if (!_disposed) notifyListeners();
        if (!task.wiki) return;
      }
      final route = _assistant.translateRouteFingerprint();
      if (route.isEmpty) {
        throw StateError('请先在「模型与接口」配置可用的标签翻译模型。');
      }
      if (_route != route) {
        _route = route;
        _names.clear();
        _wikiBodies.clear();
      }
      final entry = await _wiki.find(task.tag);
      final body = entry?.body ?? '';
      final tagContext = _contexts[task.tag];
      if (task.wiki && !task.force && !shouldTranslateWiki(body)) return;
      final hash = sha256.convert(utf8.encode(body)).toString();
      final cached = task.force
          ? null
          : await _cache.get(
              tag: task.tag,
              route: route,
              promptVersion:
                  PromptAssistantService.visibleTagTranslationPromptVersion,
              wikiHash: hash,
              allowEarlierVersion: true,
            );
      if (_disposed ||
          epoch != _routeEpoch ||
          route != _assistant.translateRouteFingerprint()) {
        return;
      }
      final name = localName ?? cached?.nameZh ?? _names[task.tag];
      if (name != null) _names[task.tag] = name;
      if (cached?.wikiZh case final wikiZh?) _wikiBodies[task.tag] = wikiZh;
      if (!_disposed) notifyListeners();
      if (task.wiki && body.trim().isEmpty) return;
      if ((task.wiki && cached?.wikiZh != null) ||
          (!task.wiki && name != null)) {
        return;
      }
      if ((!_enabled && !task.force) || !_isVisible(task.tag) || _disposed) {
        return;
      }
      var translatedName = name;
      final translatedWiki = StringBuffer();
      final chunks = task.wiki
          ? _wikiChunks(body)
          : <({String text, String separator})>[(text: body, separator: '')];
      if (task.wiki && chunks.length > 1 && translatedName == null) {
        final nameSession =
            'visible-tag-${DateTime.now().microsecondsSinceEpoch}-${task.tag}-name';
        _sessions[task.tag] = nameSession;
        final nameResult = await _assistant.translateVisibleTag(
          tag: task.tag,
          wikiBody: body,
          includeWikiTranslation: false,
          category: tagContext?.category,
          aliases: tagContext?.aliases ?? const [],
          postCount: tagContext?.postCount,
          relatedTo: tagContext?.relatedTo,
          sessionId: nameSession,
        );
        _sessions.remove(task.tag);
        translatedName = nameResult.nameZh;
      }
      for (var index = 0; index < chunks.length; index++) {
        if ((!_enabled && !task.force) ||
            !_isVisible(task.tag) ||
            _disposed ||
            epoch != _routeEpoch) {
          return;
        }
        final chunk = chunks[index];
        final glossary = task.wiki
            ? await _wikiLinks?.glossaryFor(chunk.text) ??
                  const <Map<String, Object>>[]
            : const <Map<String, Object>>[];
        if (_disposed ||
            epoch != _routeEpoch ||
            (!_enabled && !task.force) ||
            !_isVisible(task.tag)) {
          return;
        }
        final sessionId =
            'visible-tag-${DateTime.now().microsecondsSinceEpoch}-${task.tag}-$index';
        _sessions[task.tag] = sessionId;
        final result = await _assistant.translateVisibleTag(
          tag: task.tag,
          wikiBody: chunk.text,
          includeWikiTranslation: task.wiki,
          existingNameZh: translatedName,
          category: tagContext?.category,
          aliases: tagContext?.aliases ?? const [],
          postCount: tagContext?.postCount,
          relatedTo: tagContext?.relatedTo,
          glossary: glossary,
          sessionId: sessionId,
        );
        _sessions.remove(task.tag);
        translatedName = result.nameZh;
        if (task.wiki) {
          translatedWiki.write(result.wikiZh);
          if (chunk.separator.isNotEmpty) translatedWiki.write('\n\n');
        }
      }
      if (_disposed ||
          epoch != _routeEpoch ||
          (!_enabled && !task.force) ||
          route != _assistant.translateRouteFingerprint()) {
        return;
      }
      String? wikiZh;
      if (task.wiki) {
        final body = translatedWiki.toString().trim();
        wikiZh = _wikiLinks == null
            ? WikiTagLinks.withoutLocalLinks(body)
            : (await _wikiLinks.resolve(body)).markdown;
      }
      if (_disposed ||
          epoch != _routeEpoch ||
          (!_enabled && !task.force) ||
          route != _assistant.translateRouteFingerprint()) {
        return;
      }
      await _cache.put(
        tag: task.tag,
        route: route,
        promptVersion:
            PromptAssistantService.visibleTagTranslationPromptVersion,
        wikiHash: hash,
        nameZh: translatedName!,
        wikiZh: wikiZh ?? cached?.wikiZh,
      );
      if (_disposed || epoch != _routeEpoch) return;
      _names[task.tag] = translatedName;
      if (wikiZh != null) _wikiBodies[task.tag] = wikiZh;
      if (!_disposed) notifyListeners();
    } catch (error) {
      if ((!_enabled && !task.force) || _disposed || epoch != _routeEpoch) {
        return;
      }
      _failed.add(task.tag);
      _pending.remove(task.tag);
      lastError = '$error';
      if (!_disposed) notifyListeners();
    } finally {
      _sessions.remove(task.tag);
    }
  }

  static List<({String text, String separator})> _wikiChunks(String body) {
    const limit = 5000;
    if (body.length <= limit) return [(text: body, separator: '')];
    final chunks = <({String text, String separator})>[];
    var start = 0;
    while (start < body.length) {
      if (body.length - start <= limit) {
        chunks.add((text: body.substring(start).trim(), separator: ''));
        break;
      }
      final end = start + limit;
      final lineBreak = body.lastIndexOf('\n', end);
      final wordBreak = body.lastIndexOf(' ', end);
      final cut = lineBreak > start + limit ~/ 2
          ? lineBreak + 1
          : wordBreak > start + limit ~/ 2
          ? wordBreak + 1
          : end;
      chunks.add((
        text: body.substring(start, cut).trim(),
        separator: body[cut - 1] == '\n' ? '\n' : ' ',
      ));
      start = cut;
    }
    return chunks;
  }

  static bool shouldTranslateWiki(String body) {
    final latin = RegExp(r'[A-Za-z]').allMatches(body).length;
    if (latin == 0) return false;
    final han = RegExp(r'[\u3400-\u9fff]').allMatches(body).length;
    return latin >= han;
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cache.close());
    super.dispose();
  }
}

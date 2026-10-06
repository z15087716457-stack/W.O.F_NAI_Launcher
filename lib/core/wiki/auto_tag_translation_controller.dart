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
import '../utils/prompt_translation_language.dart';
import '../utils/tag_normalizer.dart';
import 'tag_wiki_repository.dart';
import 'visible_tag_translation_cache.dart';
import 'wiki_tag_links.dart';
import '../utils/localization_extension.dart';
import '../utils/fatal_diagnostics.dart';

final autoTagTranslationProvider =
    ChangeNotifierProvider<AutoTagTranslationController>((ref) {
      final controller = AutoTagTranslationController(
        assistant: ref.read(promptAssistantServiceProvider),
        wiki: ref.read(tagWikiRepositoryProvider),
        cache: ref.read(visibleTagTranslationCacheProvider),
        closeCacheOnDispose: false,
        wikiLinks: ref.read(wikiTagLinksProvider),
        readingLanguage: () => ref
            .read(promptAssistantServiceProvider)
            .targetLanguageFor(LauncherInterface.tagTranslate),
        wikiReadingLanguage: () => ref
            .read(promptAssistantServiceProvider)
            .targetLanguageFor(LauncherInterface.wikiTranslate),
      );
      ref.listen(promptAssistantConfigProvider, (_, __) {
        controller.routeChanged();
      });
      ref.listen(localeNotifierProvider, (_, __) => controller.routeChanged());
      unawaited(controller.loadPreference());
      return controller;
    });

enum TagTranslationPhase { queued, translating, failed }

class TagTranslationActivity {
  const TagTranslationActivity(this.phase, {this.wiki = false, this.error});
  final TagTranslationPhase phase;
  final bool wiki;
  final String? error;
}

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
    required TagWikiRepository wiki,
    required VisibleTagTranslationCache cache,
    WikiTagLinks? wikiLinks,
    this.maxConcurrentRequests = 5,
    String Function()? readingLanguage,
    String Function()? wikiReadingLanguage,
    this.closeCacheOnDispose = true,
  }) : _assistant = assistant,
       _wiki = wiki,
       _cache = cache,
       _wikiLinks = wikiLinks,
       _readingLanguage = readingLanguage ?? (() => 'zh'),
       _wikiReadingLanguage =
           wikiReadingLanguage ?? readingLanguage ?? (() => 'zh');

  static const _preferenceKey = 'auto_visible_tag_translation_enabled';
  final PromptAssistantService _assistant;
  final TagWikiRepository _wiki;
  final VisibleTagTranslationCache _cache;
  final WikiTagLinks? _wikiLinks;
  final int maxConcurrentRequests;
  final String Function() _readingLanguage;
  final String Function() _wikiReadingLanguage;
  final bool closeCacheOnDispose;
  PromptTranslationLanguage get _reading =>
      PromptTranslationLanguage.fromCode(_readingLanguage());
  final Map<String, Set<String>> _visibleBySurface = {};
  final Map<String, String> _wikiBySurface = {};
  final Map<String, _VisibleTask> _pending = {};
  final Set<String> _inFlight = {};
  final Map<String, int> _inFlightEpoch = {};
  final Set<String> _wikiInFlight = {};
  final Map<String, String> _sessions = {};
  final Map<String, String> _names = {};
  final Map<String, String> _definitions = {};
  final Map<String, String> _wikiBodies = {};
  final Map<String, String> _wikiOriginals = {};
  final Map<String, AutoTagTranslationContext> _contexts = {};
  final Map<String, String> _nameErrors = {};
  final Map<String, String> _wikiErrors = {};
  int _priority = 0;
  int _routeEpoch = 0;
  int _active = 0;
  bool _enabled = false;
  bool _preferenceChanged = false;
  bool _disposed = false;
  String? _route;
  String? get lastError =>
      _wikiErrors.values.followedBy(_nameErrors.values).firstOrNull;

  bool get enabled => _enabled;
  int get activeRequests => _active;
  String? nameFor(String tag) => _names[TagNormalizer.normalize(tag)];
  String? definitionFor(String tag) =>
      _definitions[TagNormalizer.normalize(tag)];
  String? wikiFor(String tag) => _wikiBodies[TagNormalizer.normalize(tag)];
  String? wikiOriginalFor(String tag) =>
      _wikiOriginals[TagNormalizer.normalize(tag)];
  String? wikiErrorFor(String tag) => _wikiErrors[TagNormalizer.normalize(tag)];

  TagTranslationActivity? activityFor(String tag, {bool wiki = false}) {
    final canonical = TagNormalizer.normalize(tag);
    final currentRequest = _inFlightEpoch[canonical] == _routeEpoch;
    TagTranslationActivity active(bool article) => TagTranslationActivity(
      _sessions.containsKey(canonical)
          ? TagTranslationPhase.translating
          : TagTranslationPhase.queued,
      wiki: article,
    );
    if (wiki) {
      if (currentRequest && _wikiInFlight.contains(canonical)) {
        return active(true);
      }
      if (_pending[canonical]?.wiki == true) {
        return const TagTranslationActivity(
          TagTranslationPhase.queued,
          wiki: true,
        );
      }
      if (_wikiErrors[canonical] case final error?) {
        return TagTranslationActivity(
          TagTranslationPhase.failed,
          wiki: true,
          error: error,
        );
      }
    }
    if (currentRequest &&
        _inFlight.contains(canonical) &&
        (!_wikiInFlight.contains(canonical) ||
            !_names.containsKey(canonical))) {
      return active(_wikiInFlight.contains(canonical));
    }
    final pending = _pending[canonical];
    if (pending != null && (!pending.wiki || !_names.containsKey(canonical))) {
      return TagTranslationActivity(
        TagTranslationPhase.queued,
        wiki: pending.wiki,
      );
    }
    if (_nameErrors[canonical] case final error?) {
      return TagTranslationActivity(TagTranslationPhase.failed, error: error);
    }
    return null;
  }

  void retranslateName({required String surface, required String tag}) {
    final canonical = TagNormalizer.normalize(tag);
    if (canonical.isEmpty ||
        _inFlight.contains(canonical) ||
        _pending.containsKey(canonical)) {
      return;
    }
    _visibleBySurface.putIfAbsent(surface, () => <String>{}).add(canonical);
    _nameErrors.remove(canonical);
    _pending[canonical] = _VisibleTask(
      canonical,
      false,
      ++_priority,
      force: true,
    );
    notifyListeners();
    _pump();
  }

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
    _wikiErrors.remove(canonical);
    if (!_names.containsKey(canonical)) _nameErrors.remove(canonical);
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
    _definitions.clear();
    _wikiBodies.clear();
    _wikiOriginals.clear();
    _nameErrors.clear();
    _wikiErrors.clear();
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
    // Existing names come from the same translation interface.
    if (_reading.isChinese && existingNameZh?.trim().isNotEmpty == true) {
      _names.putIfAbsent(canonical, () => existingNameZh!.trim());
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
    if (!_enabled ||
        (wiki ? _wikiErrors : _nameErrors).containsKey(tag) ||
        (_inFlightEpoch[tag] == _routeEpoch &&
            _inFlight.contains(tag) &&
            (!wiki || _wikiInFlight.contains(tag)))) {
      return;
    }
    final previous = _pending[tag];
    _pending[tag] = _VisibleTask(
      tag,
      wiki || previous?.wiki == true,
      ++_priority,
      force: previous?.force ?? false,
    );
    notifyListeners();
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
                    !(task.wiki ? _wikiErrors : _nameErrors).containsKey(
                      task.tag,
                    ),
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
      _inFlightEpoch[task.tag] = _routeEpoch;
      if (task.wiki) _wikiInFlight.add(task.tag);
      _active++;
      notifyListeners();
      unawaited(
        _run(task).whenComplete(() {
          _active--;
          _inFlight.remove(task.tag);
          _inFlightEpoch.remove(task.tag);
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
      final route = _assistant.translateRouteFingerprint();
      if (route.isEmpty) {
        throw StateError(currentL10n.wiki_configureTagModel);
      }
      if (_route != route) {
        // Names observed before the first task came from this same interface.
        if (_route != null) {
          _names.clear();
          _definitions.clear();
          _wikiBodies.clear();
          _wikiOriginals.clear();
        }
        _route = route;
      }
      final entry = await _wiki.find(task.tag);
      final body = entry?.body ?? '';
      final tagContext = _contexts[task.tag];
      if (task.wiki && !task.force && !shouldTranslateWiki(body)) return;
      final hash = sha256.convert(utf8.encode(body)).toString();
      final cached = task.force && task.wiki
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
      final name = task.force && !task.wiki
          ? null
          : cached?.nameZh ?? _names[task.tag];
      if (name != null) _names[task.tag] = name;
      if (cached?.definition case final definition?) {
        _definitions[task.tag] = definition;
      }
      if (cached?.wikiZh case final wikiZh?) _wikiBodies[task.tag] = wikiZh;
      if (cached?.wikiOriginal case final source?) {
        _wikiOriginals[task.tag] = source;
      }
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
      var nameLanguage = name == null
          ? null
          : cached?.nameLanguage ?? _reading.code;
      var definition = task.force && !task.wiki ? null : cached?.definition;
      var definitionLanguage = task.force && !task.wiki
          ? null
          : cached?.definitionLanguage;
      final articleLanguage = _wikiReadingLanguage();
      final translatedWiki = StringBuffer();
      final originalWiki = StringBuffer();
      var completeOriginal = true;
      final chunks = task.wiki
          ? _wikiChunks(body)
          : <({String text, String separator})>[(text: body, separator: '')];
      if (task.wiki && chunks.length > 1 && translatedName == null) {
        final nameSession =
            'visible-tag-${DateTime.now().microsecondsSinceEpoch}-${task.tag}-name';
        _sessions[task.tag] = nameSession;
        notifyListeners();
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
        nameLanguage = _reading.code;
        definition = nameResult.definition;
        definitionLanguage = _reading.code;
      }
      for (var index = 0; index < chunks.length; index++) {
        if ((!_enabled && !task.force) ||
            !_isVisible(task.tag) ||
            _disposed ||
            epoch != _routeEpoch) {
          return;
        }
        final chunk = chunks[index];
        final glossary =
            await _wikiLinks?.glossaryFor(
              task.wiki ? chunk.text : TagNormalizer.toDisplay(task.tag),
              currentTag: task.tag,
              limit: task.wiki ? 64 : 1,
            ) ??
            const <Map<String, Object>>[];
        if (_disposed ||
            epoch != _routeEpoch ||
            (!_enabled && !task.force) ||
            !_isVisible(task.tag)) {
          return;
        }
        final sessionId =
            'visible-tag-${DateTime.now().microsecondsSinceEpoch}-${task.tag}-$index';
        _sessions[task.tag] = sessionId;
        notifyListeners();
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
        nameLanguage ??= task.wiki ? articleLanguage : _reading.code;
        if (definition == null && result.definition != null) {
          definition = result.definition;
          definitionLanguage = task.wiki ? articleLanguage : _reading.code;
        }
        if (task.wiki) {
          translatedWiki.write(result.wikiZh);
          if (result.wikiOriginal case final source?) {
            originalWiki.write(source);
          } else {
            completeOriginal = false;
          }
          if (chunk.separator.isNotEmpty) {
            translatedWiki.write('\n\n');
            originalWiki.write('\n\n');
          }
        }
      }
      if (_disposed ||
          epoch != _routeEpoch ||
          (!_enabled && !task.force) ||
          route != _assistant.translateRouteFingerprint()) {
        return;
      }
      String? wikiZh;
      String? wikiOriginal;
      if (task.wiki) {
        final body = translatedWiki.toString().trim();
        wikiZh = _wikiLinks == null
            ? WikiTagLinks.withoutLocalLinks(body)
            : (await _wikiLinks.resolve(body)).markdown;
        if (completeOriginal && originalWiki.toString().trim().isNotEmpty) {
          final source = originalWiki.toString().trim();
          wikiOriginal = _wikiLinks == null
              ? WikiTagLinks.withoutLocalLinks(source)
              : (await _wikiLinks.resolve(source)).markdown;
        }
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
        wikiOriginal: task.wiki ? wikiOriginal : cached?.wikiOriginal,
        definition: definition,
        nameLanguage: nameLanguage!,
        definitionLanguage: definitionLanguage ?? _reading.code,
      );
      if (_disposed || epoch != _routeEpoch) return;
      _names[task.tag] = translatedName;
      _nameErrors.remove(task.tag);
      if (definition != null) _definitions[task.tag] = definition;
      if (wikiZh != null) {
        _wikiErrors.remove(task.tag);
        _wikiBodies[task.tag] = wikiZh;
        if (wikiOriginal != null) {
          _wikiOriginals[task.tag] = wikiOriginal;
        } else {
          _wikiOriginals.remove(task.tag);
        }
      }
      if (!_disposed) notifyListeners();
    } catch (error) {
      if ((!_enabled && !task.force) || _disposed || epoch != _routeEpoch) {
        return;
      }
      final safeError = FatalDiagnostics.redactSensitiveText(
        '$error'.replaceAll(RegExp(r'https?://[^\s]+'), '[URL]'),
      );
      (task.wiki ? _wikiErrors : _nameErrors)[task.tag] = safeError;
      if (task.wiki && !_names.containsKey(task.tag)) {
        _nameErrors[task.tag] = safeError;
      }
      if (_pending[task.tag]?.wiki == task.wiki) _pending.remove(task.tag);
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
    if (closeCacheOnDispose) unawaited(_cache.close());
    super.dispose();
  }
}

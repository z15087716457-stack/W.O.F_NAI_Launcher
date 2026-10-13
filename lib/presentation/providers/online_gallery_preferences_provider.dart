import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/utils/app_logger.dart';
import '../../data/services/gallery/online_gallery_column_width_store.dart';
import '../ui/online/online_contract.dart';

class OnlineGalleryPreferences {
  const OnlineGalleryPreferences({
    this.cardSize = OnlineCardSize.medium,
    this.sidebarOpen = true,
    this.inspectorOpen = true,
    this.sendMode,
    this.recent = const {},
  });

  final OnlineCardSize cardSize;
  final bool sidebarOpen;
  final bool inspectorOpen;
  final OnlineSendMode? sendMode;
  final Map<OnlineSource, List<OnlineRecent>> recent;

  OnlineGalleryPreferences copyWith({
    OnlineCardSize? cardSize,
    bool? sidebarOpen,
    bool? inspectorOpen,
    OnlineSendMode? sendMode,
    Map<OnlineSource, List<OnlineRecent>>? recent,
  }) => OnlineGalleryPreferences(
    cardSize: cardSize ?? this.cardSize,
    sidebarOpen: sidebarOpen ?? this.sidebarOpen,
    inspectorOpen: inspectorOpen ?? this.inspectorOpen,
    sendMode: sendMode ?? this.sendMode,
    recent: recent ?? this.recent,
  );
}

class OnlineGalleryPreferencesStore {
  const OnlineGalleryPreferencesStore();

  String recentKey(OnlineSource source) =>
      '${StorageKeys.onlineGalleryRecentPrefix}${switch (source) {
        OnlineSource.aiTag => 'ai_tag',
        _ => source.name,
      }}';

  Future<OnlineGalleryPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final width = await const OnlineGalleryColumnWidthStore().load();
    final recent = <OnlineSource, List<OnlineRecent>>{};
    for (final source in OnlineSource.values) {
      final items = <OnlineRecent>[];
      for (final raw in prefs.getStringList(recentKey(source)) ?? <String>[]) {
        try {
          final json = jsonDecode(raw);
          if (json is! Map) continue;
          final kind = OnlineRecentKind.values
              .where((k) => k.name == json['kind'])
              .firstOrNull;
          final text = json['text'];
          if (kind == null || text is! String || text.trim().isEmpty) continue;
          final item = OnlineRecent(kind: kind, text: text.trim());
          if (!items.contains(item)) items.add(item);
        } on FormatException {
          continue;
        }
        if (items.length == 8) break;
      }
      recent[source] = List.unmodifiable(items);
    }
    final name = prefs.getString(StorageKeys.onlineGallerySendMode);
    return OnlineGalleryPreferences(
      cardSize: OnlineCardSize.values.reduce(
        (a, b) =>
            (onlineCardWidth(a) - width).abs() <=
                (onlineCardWidth(b) - width).abs()
            ? a
            : b,
      ),
      sidebarOpen: prefs.getBool(StorageKeys.onlineGallerySidebarOpen) ?? true,
      inspectorOpen:
          prefs.getBool(StorageKeys.onlineGalleryInspectorOpen) ?? true,
      sendMode: OnlineSendMode.values
          .where((mode) => mode.name == name)
          .firstOrNull,
      recent: Map.unmodifiable(recent),
    );
  }

  Future<void> saveCardSize(OnlineCardSize size) =>
      const OnlineGalleryColumnWidthStore().save(onlineCardWidth(size));

  Future<void> saveBool(String key, bool value) async {
    if (!await (await SharedPreferences.getInstance()).setBool(key, value)) {
      throw StateError('Online gallery preference could not be saved');
    }
  }

  Future<void> saveSendMode(OnlineSendMode mode) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      StorageKeys.onlineGallerySendMode,
      mode.name,
    )) {
      throw StateError('Online gallery preference could not be saved');
    }
  }

  Future<void> saveRecent(OnlineSource source, List<OnlineRecent> items) async {
    if (!await (await SharedPreferences.getInstance()).setStringList(
      recentKey(source),
      items
          .map(
            (item) => jsonEncode({'kind': item.kind.name, 'text': item.text}),
          )
          .toList(),
    )) {
      throw StateError('Online gallery recent searches could not be saved');
    }
  }
}

double onlineCardWidth(OnlineCardSize size) => switch (size) {
  OnlineCardSize.small => 160,
  OnlineCardSize.medium => 210,
  OnlineCardSize.large => 280,
};

final onlineGalleryPreferencesStoreProvider =
    Provider<OnlineGalleryPreferencesStore>(
      (ref) => const OnlineGalleryPreferencesStore(),
    );
final onlineGalleryPreferencesProvider =
    StateNotifierProvider<
      OnlineGalleryPreferencesNotifier,
      OnlineGalleryPreferences
    >(
      (ref) => OnlineGalleryPreferencesNotifier(
        ref.read(onlineGalleryPreferencesStoreProvider),
      ),
    );

class OnlineGalleryPreferencesNotifier
    extends StateNotifier<OnlineGalleryPreferences> {
  OnlineGalleryPreferencesNotifier(this.store)
    : super(const OnlineGalleryPreferences()) {
    ready = _restore();
  }

  final OnlineGalleryPreferencesStore store;
  late final Future<void> ready;
  Future<void> _writes = Future.value();
  final Set<String> _changed = {};

  Future<void> _restore() async {
    try {
      final saved = await store.load();
      if (!mounted) return;
      state = saved.copyWith(
        cardSize: _changed.contains('card') ? state.cardSize : null,
        sidebarOpen: _changed.contains('sidebar') ? state.sidebarOpen : null,
        inspectorOpen: _changed.contains('inspector')
            ? state.inspectorOpen
            : null,
        sendMode: _changed.contains('send') ? state.sendMode : null,
      );
    } catch (error, stack) {
      AppLogger.e(
        'Online gallery preferences failed to load',
        error,
        stack,
        'OnlineGallery',
      );
    }
  }

  Future<void> _write(Future<void> Function() operation) {
    final result = _writes.then((_) async {
      await ready;
      await operation();
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  Future<void> flush() async {
    await ready;
    await _writes;
  }

  Future<void> setCardSize(OnlineCardSize value) {
    _changed.add('card');
    state = state.copyWith(cardSize: value);
    return _write(() => store.saveCardSize(value));
  }

  Future<void> setSidebar(bool value) {
    _changed.add('sidebar');
    state = state.copyWith(sidebarOpen: value);
    return _write(
      () => store.saveBool(StorageKeys.onlineGallerySidebarOpen, value),
    );
  }

  Future<void> setInspector(bool value) {
    _changed.add('inspector');
    state = state.copyWith(inspectorOpen: value);
    return _write(
      () => store.saveBool(StorageKeys.onlineGalleryInspectorOpen, value),
    );
  }

  Future<void> rememberSend(OnlineSendMode value) {
    _changed.add('send');
    state = state.copyWith(sendMode: value);
    return _write(() => store.saveSendMode(value));
  }

  Future<void> addRecent(OnlineSource source, OnlineRecent item) => _write(
    () async {
      if (!mounted || item.text.trim().isEmpty) return;
      final normalized = OnlineRecent(kind: item.kind, text: item.text.trim());
      final items = List<OnlineRecent>.unmodifiable(
        [
          normalized,
          ...?state.recent[source]?.where((entry) => entry != normalized),
        ].take(8),
      );
      state = state.copyWith(
        recent: Map.unmodifiable({...state.recent, source: items}),
      );
      await store.saveRecent(source, items);
    },
  );

  Future<void> clearRecent(OnlineSource source) => _write(() async {
    if (!mounted) return;
    state = state.copyWith(
      recent: Map.unmodifiable({...state.recent, source: <OnlineRecent>[]}),
    );
    await store.saveRecent(source, const []);
  });
}

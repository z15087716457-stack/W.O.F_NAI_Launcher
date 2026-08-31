import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/remote/danbooru_api_service.dart';
import '../../data/services/danbooru_auth_service.dart';

class OnlineGalleryBlacklistState {
  final Set<String> localTags;
  final Set<String> remoteTags;
  final bool autoSyncOnStartup;
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final String? lastSyncError;
  final bool isInitialized;

  const OnlineGalleryBlacklistState({
    this.localTags = const {},
    this.remoteTags = const {},
    this.autoSyncOnStartup = true,
    this.isSyncing = false,
    this.lastSyncAt,
    this.lastSyncError,
    this.isInitialized = false,
  });

  Set<String> get effectiveTags => {...localTags, ...remoteTags};

  OnlineGalleryBlacklistState copyWith({
    Set<String>? localTags,
    Set<String>? remoteTags,
    bool? autoSyncOnStartup,
    bool? isSyncing,
    DateTime? lastSyncAt,
    String? lastSyncError,
    bool clearLastSyncError = false,
    bool? isInitialized,
  }) {
    return OnlineGalleryBlacklistState(
      localTags: localTags ?? this.localTags,
      remoteTags: remoteTags ?? this.remoteTags,
      autoSyncOnStartup: autoSyncOnStartup ?? this.autoSyncOnStartup,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncError: clearLastSyncError
          ? null
          : (lastSyncError ?? this.lastSyncError),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class OnlineGalleryBlacklistNotifier
    extends StateNotifier<OnlineGalleryBlacklistState> {
  static const Duration _startupSyncMinInterval = Duration(minutes: 30);
  static const Duration _authWaitStep = Duration(milliseconds: 500);
  static const int _authWaitMaxRounds = 24;

  final Ref _ref;
  final LocalStorageService _storage;
  late final Future<void> _initFuture;

  OnlineGalleryBlacklistNotifier(this._ref, this._storage)
    : super(const OnlineGalleryBlacklistState()) {
    _initFuture = _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final localRaw = _storage.getSetting<List<dynamic>>(
      StorageKeys.onlineGalleryBlacklistTags,
      defaultValue: const <dynamic>[],
    );
    final remoteRaw = _storage.getSetting<List<dynamic>>(
      StorageKeys.onlineGalleryRemoteBlacklistTags,
      defaultValue: const <dynamic>[],
    );
    final autoSync =
        _storage.getSetting<bool>(
          StorageKeys.onlineGalleryBlacklistAutoSync,
          defaultValue: true,
        ) ??
        true;
    final lastSyncAtMs = _storage.getSetting<int>(
      StorageKeys.onlineGalleryBlacklistLastSyncAt,
    );
    final lastSyncError = _storage.getSetting<String>(
      StorageKeys.onlineGalleryBlacklistLastSyncError,
    );

    state = state.copyWith(
      localTags: _normalizeTags((localRaw ?? const []).cast<String>()),
      remoteTags: _normalizeTags((remoteRaw ?? const []).cast<String>()),
      autoSyncOnStartup: autoSync,
      lastSyncAt: lastSyncAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs)
          : null,
      lastSyncError: lastSyncError,
      isInitialized: true,
    );
  }

  Future<void> ensureInitialized() => _initFuture;

  Future<void> addLocalTag(String input) async {
    await ensureInitialized();
    final normalized = _normalizeTag(input);
    if (normalized == null || state.localTags.contains(normalized)) return;

    final next = {...state.localTags, normalized};
    await _saveLocalTags(next);
    state = state.copyWith(localTags: next);
  }

  Future<void> removeLocalTag(String tag) async {
    await ensureInitialized();
    final normalized = _normalizeTag(tag);
    if (normalized == null || !state.localTags.contains(normalized)) return;

    final next = {...state.localTags}..remove(normalized);
    await _saveLocalTags(next);
    state = state.copyWith(localTags: next);
  }

  Future<void> clearLocalTags() async {
    await ensureInitialized();
    await _saveLocalTags(const <String>{});
    state = state.copyWith(localTags: const <String>{});
  }

  Future<void> setAutoSyncOnStartup(bool value) async {
    await ensureInitialized();
    await _storage.setSetting(
      StorageKeys.onlineGalleryBlacklistAutoSync,
      value,
    );
    state = state.copyWith(autoSyncOnStartup: value);
  }

  Future<void> syncOnStartup() async {
    await ensureInitialized();
    if (!state.autoSyncOnStartup) return;

    final authState = await _waitAuthReadyForStartup();
    if (!authState.isLoggedIn) return;

    final now = DateTime.now();
    final lastSyncAt = state.lastSyncAt;
    if (lastSyncAt != null &&
        now.difference(lastSyncAt) < _startupSyncMinInterval) {
      return;
    }

    await syncNow(triggeredByStartup: true);
  }

  Future<DanbooruAuthState> _waitAuthReadyForStartup() async {
    var authState = _ref.read(danbooruAuthProvider);
    for (var i = 0; i < _authWaitMaxRounds; i++) {
      if (!authState.isLoading) {
        return authState;
      }
      await Future<void>.delayed(_authWaitStep);
      authState = _ref.read(danbooruAuthProvider);
    }
    return authState;
  }

  Future<void> syncNow({bool triggeredByStartup = false}) async {
    await ensureInitialized();
    if (state.isSyncing) return;

    final authState = _ref.read(danbooruAuthProvider);
    if (!authState.isLoggedIn) {
      if (!triggeredByStartup) {
        state = state.copyWith(lastSyncError: '请先登录 Danbooru 账号');
        await _saveLastSyncError('请先登录 Danbooru 账号');
      }
      return;
    }

    state = state.copyWith(isSyncing: true, clearLastSyncError: true);

    try {
      final api = _ref.read(danbooruApiServiceProvider);
      final remoteTags = await api.fetchBlacklistedTags();
      final remoteNormalized = _normalizeTags(remoteTags);
      final merged = {...state.localTags, ...remoteNormalized};

      final pushOk = await api.updateBlacklistedTags(merged.toList()..sort());
      if (!pushOk) {
        throw Exception('推送 Danbooru 黑名单失败');
      }

      final syncTime = DateTime.now();
      await _saveLocalTags(merged);
      await _saveRemoteTags(merged);
      await _saveLastSyncAt(syncTime);
      await _clearLastSyncError();

      state = state.copyWith(
        localTags: merged,
        remoteTags: merged,
        isSyncing: false,
        lastSyncAt: syncTime,
        clearLastSyncError: true,
      );
    } catch (e, stack) {
      final message = '同步失败: $e';
      AppLogger.w(message, 'OnlineGalleryBlacklist');
      AppLogger.d('$stack', 'OnlineGalleryBlacklist');
      await _saveLastSyncError(message);
      state = state.copyWith(isSyncing: false, lastSyncError: message);
    }
  }

  Set<String> _normalizeTags(Iterable<String> values) {
    return values.map(_normalizeTag).whereType<String>().toSet();
  }

  String? _normalizeTag(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    var normalized = trimmed.toLowerCase().replaceAll(' ', '_');

    // 兼容用户误输入 Danbooru 负号语法（如 -tag）
    while (normalized.startsWith('-')) {
      normalized = normalized.substring(1);
    }

    // V1 仅支持“纯标签”黑名单，忽略 metatag 语法（如 rating:g / order:rank）。
    if (normalized.contains(':')) return null;
    if (normalized.startsWith('~')) return null;

    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _saveLocalTags(Set<String> tags) async {
    await _storage.setSetting(
      StorageKeys.onlineGalleryBlacklistTags,
      tags.toList()..sort(),
    );
  }

  Future<void> _saveRemoteTags(Set<String> tags) async {
    await _storage.setSetting(
      StorageKeys.onlineGalleryRemoteBlacklistTags,
      tags.toList()..sort(),
    );
  }

  Future<void> _saveLastSyncAt(DateTime time) async {
    await _storage.setSetting(
      StorageKeys.onlineGalleryBlacklistLastSyncAt,
      time.millisecondsSinceEpoch,
    );
  }

  Future<void> _saveLastSyncError(String message) async {
    await _storage.setSetting(
      StorageKeys.onlineGalleryBlacklistLastSyncError,
      message,
    );
  }

  Future<void> _clearLastSyncError() async {
    await _storage.deleteSetting(
      StorageKeys.onlineGalleryBlacklistLastSyncError,
    );
  }
}

final onlineGalleryBlacklistNotifierProvider =
    StateNotifierProvider<
      OnlineGalleryBlacklistNotifier,
      OnlineGalleryBlacklistState
    >((ref) {
      final storage = ref.read(localStorageServiceProvider);
      return OnlineGalleryBlacklistNotifier(ref, storage);
    });

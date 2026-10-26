import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/crypto/nai_crypto_service.dart';
import '../../core/network/nai_api_endpoint.dart';
import '../../core/network/nai_api_endpoint_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/remote/nai_auth_api_service.dart';
import '../../data/datasources/remote/nai_user_info_api_service.dart';
import '../../data/models/auth/saved_account.dart';
import 'account_manager_provider.dart';
import 'guest_session_provider.dart';
import '../../core/utils/localization_extension.dart';

part 'auth_provider.g.dart';

/// 认证状态
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// 认证错误码
enum AuthErrorCode {
  networkTimeout,
  networkError,
  authFailed,
  tokenInvalid,
  credentialsLoginUnavailable,
  serverError,
  unknown,
}

/// 认证状态模型
class AuthState {
  final AuthStatus status;
  final String? accountId;
  final String? displayName;
  final AuthErrorCode? errorCode;
  final int? httpStatusCode;
  final Map<String, dynamic>? subscriptionInfo;

  const AuthState({
    this.status = AuthStatus.initial,
    this.accountId,
    this.displayName,
    this.errorCode,
    this.httpStatusCode,
    this.subscriptionInfo,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? accountId,
    String? displayName,
    AuthErrorCode? errorCode,
    int? httpStatusCode,
    Map<String, dynamic>? subscriptionInfo,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      displayName: displayName ?? this.displayName,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      httpStatusCode: clearError
          ? null
          : (httpStatusCode ?? this.httpStatusCode),
      subscriptionInfo: subscriptionInfo ?? this.subscriptionInfo,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => errorCode != null;

  /// 从异常解析错误码
  static (AuthErrorCode, int?) parseError(Object e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;

      // 超时错误
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return (AuthErrorCode.networkTimeout, statusCode);
      }

      // 网络连接错误
      if (e.type == DioExceptionType.connectionError ||
          e.error is SocketException ||
          e.error is HandshakeException) {
        return (AuthErrorCode.networkError, statusCode);
      }

      // HTTP 状态码错误
      if (statusCode != null) {
        if (statusCode == 401) {
          return (AuthErrorCode.authFailed, statusCode);
        }
        if (statusCode == 400) {
          // 检查是否是 Authorization header 相关的错误
          final responseData = e.response?.data;
          final message = switch (responseData) {
            final Map data => data['message']?.toString(),
            final String text => text,
            _ => null,
          };
          if (message?.contains('Please refresh NovelAI.net') ?? false) {
            return (AuthErrorCode.credentialsLoginUnavailable, statusCode);
          }
          if (message?.contains('Authorization') ?? false) {
            return (AuthErrorCode.tokenInvalid, statusCode);
          }
        }
        if (statusCode >= 500) {
          return (AuthErrorCode.serverError, statusCode);
        }
      }

      return (AuthErrorCode.unknown, statusCode);
    }

    // Token 格式无效
    if (e.toString().contains('pst-')) {
      return (AuthErrorCode.tokenInvalid, null);
    }

    return (AuthErrorCode.unknown, null);
  }

  /// 获取 Anlas 余额
  int get anlasBalance {
    if (subscriptionInfo == null) return 0;
    final trainingStepsLeft = subscriptionInfo!['trainingStepsLeft'];
    if (trainingStepsLeft is Map) {
      return (trainingStepsLeft['fixedTrainingStepsLeft'] ?? 0) +
          (trainingStepsLeft['purchasedTrainingSteps'] ?? 0);
    }
    return 0;
  }
}

/// 添加账号结果
class AddAccountResult {
  final bool success;
  final AuthErrorCode? errorCode;
  final int? httpStatusCode;

  const AddAccountResult({
    required this.success,
    this.errorCode,
    this.httpStatusCode,
  });

  factory AddAccountResult.ok() => const AddAccountResult(success: true);

  factory AddAccountResult.failed(
    AuthErrorCode errorCode,
    int? httpStatusCode,
  ) {
    return AddAccountResult(
      success: false,
      errorCode: errorCode,
      httpStatusCode: httpStatusCode,
    );
  }
}

/// 认证状态 Notifier
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  static const String autoLoginPreferenceKey = 'auto_login';
  int _sessionRequest = 0;
  bool _disposed = false;
  AuthState? _loginBase;

  AuthState _captureLoginBase() {
    final previous = state.isLoading ? (_loginBase ?? state) : state;
    _loginBase = previous;
    return previous;
  }

  bool _ownsSession(int request) => !_disposed && request == _sessionRequest;

  @override
  AuthState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _sessionRequest++;
    });
    // 初始化时检查已存储的认证状态
    _checkExistingAuth();
    return const AuthState(status: AuthStatus.loading);
  }

  /// 检查已存储的认证状态
  Future<void> _checkExistingAuth() async {
    final request = ++_sessionRequest;
    // 0. 检查自动登录设置（默认启用，确保重启后自动恢复登录）
    final prefs = await SharedPreferences.getInstance();
    if (!_ownsSession(request)) return;
    final autoLogin = prefs.getBool(autoLoginPreferenceKey) ?? true;

    if (!autoLogin) {
      AppLogger.i(
        'Auto-login disabled by preference, showing login page',
        'Auth',
      );
      ref.read(naiApiEndpointServiceProvider).resetToOfficial();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    final storage = ref.read(secureStorageServiceProvider);
    final endpointService = ref.read(naiApiEndpointServiceProvider);

    // 等待 AccountManager 加载完成（最多等待 5 秒）
    final accountManagerNotifier = ref.read(
      accountManagerNotifierProvider.notifier,
    );
    var accountManagerState = ref.read(accountManagerNotifierProvider);
    int waitCount = 0;
    const maxWait = 50; // 50 * 100ms = 5秒
    while (accountManagerState.isLoading && waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_ownsSession(request)) return;
      accountManagerState = ref.read(accountManagerNotifierProvider);
      waitCount++;
    }
    if (waitCount > 0) {
      AppLogger.d(
        'Waited ${waitCount * 100}ms for AccountManager to load',
        'Auth',
      );
    }

    // 1. 检查是否有有效的全局 Token

    final token = await storage.getAccessToken();
    if (!_ownsSession(request)) return;
    if (token != null && token.isNotEmpty) {
      try {
        final apiService = ref.read(naiAuthApiServiceProvider);
        final accounts = ref.read(accountManagerNotifierProvider).accounts;
        SavedAccount? matchedAccount;

        for (final account in accounts) {
          final accountToken = await accountManagerNotifier.getAccountToken(
            account.id,
          );
          if (!_ownsSession(request)) return;
          if (accountToken == token) {
            matchedAccount = account;
            break;
          }
        }

        if (matchedAccount != null) {
          final endpoint = accountManagerNotifier.getAccountApiEndpoint(
            matchedAccount.id,
          );
          final subscriptionInfo = await apiService
              .validateToken(
                token,
                endpoint: endpoint,
                allowAnyTokenFormat: endpoint.isThirdParty,
              )
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  throw DioException(
                    type: DioExceptionType.connectionTimeout,
                    requestOptions: RequestOptions(path: '/user/subscription'),
                  );
                },
              );
          if (!_ownsSession(request)) return;

          endpointService.setCurrent(endpoint);
          accountManagerNotifier.updateLastUsed(matchedAccount.id);
          state = AuthState(
            status: AuthStatus.authenticated,
            accountId: matchedAccount.id,
            displayName: matchedAccount.displayName,
            subscriptionInfo: subscriptionInfo,
          );
          AppLogger.auth(
            'Token validation successful, account: ${matchedAccount.displayName}',
          );
          return; // 已登录，直接返回
        }

        final subscriptionInfo = await apiService
            .validateToken(token)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw DioException(
                  type: DioExceptionType.connectionTimeout,
                  requestOptions: RequestOptions(path: '/user/subscription'),
                );
              },
            );
        if (!_ownsSession(request)) return;

        AppLogger.w(
          'Token valid but no matching account found, clearing and trying auto-login...',
        );
        if (subscriptionInfo.isNotEmpty) {
          endpointService.resetToOfficial();
        }
        await storage.clearAuth();
        if (!_ownsSession(request)) return;
      } catch (e) {
        if (!_ownsSession(request)) return;
        // Token 无效，清除后尝试自动登录
        AppLogger.w('Stored token invalid, trying auto-login...');
        await storage.clearAuth();
        if (!_ownsSession(request)) return;
        endpointService.resetToOfficial();
      }
    }

    // 2. 尝试使用保存的账号自动登录
    final accountManager = ref.read(accountManagerNotifierProvider.notifier);
    final accounts = accountManager.sortedAccounts;
    // 注意：sortedAccounts 已按 lastUsedAt 排序，第一个就是最近登录的账号

    if (accounts.isNotEmpty) {
      // 使用最近登录的账号（accounts 已按 lastUsedAt 降序排序）
      final lastUsedAccount = accounts.first;
      AppLogger.auth(
        'Attempting auto-login with account: ${lastUsedAccount.displayName}',
      );

      // 获取账号的 Token 和类型
      final accountToken = await accountManager.getAccountToken(
        lastUsedAccount.id,
      );
      if (!_ownsSession(request)) return;
      final accountType = lastUsedAccount.accountType;
      final accountEndpoint = accountManager.getAccountApiEndpoint(
        lastUsedAccount.id,
      );

      if (accountToken != null && accountToken.isNotEmpty) {
        try {
          final apiService = ref.read(naiAuthApiServiceProvider);
          Map<String, dynamic> subscriptionInfo;

          // 根据账号类型选择验证方式
          // 使用较短超时（5秒），在网络不可用时快速失败
          const validationTimeout = Duration(seconds: 5);
          if (accountType == AccountType.credentials) {
            // Credentials 账号：直接验证 accessToken
            AppLogger.auth(
              'Auto-login: validating access token for credentials account...',
            );
            subscriptionInfo = await apiService
                .validateToken(accountToken, endpoint: accountEndpoint)
                .timeout(
                  validationTimeout,
                  onTimeout: () => throw DioException(
                    type: DioExceptionType.connectionTimeout,
                    requestOptions: RequestOptions(path: '/user/subscription'),
                  ),
                );
          } else {
            // Token 账号：官方端点校验 pst- 格式，第三方端点允许兼容站点自定义 Token。
            AppLogger.auth(
              'Auto-login: validating token format for token account...',
            );
            if (accountEndpoint.isOfficial &&
                !NAIAuthApiService.isValidTokenFormat(accountToken)) {
              throw Exception(currentL10n.auth_tokenMustStartPst);
            }
            subscriptionInfo = await apiService
                .validateToken(
                  accountToken,
                  endpoint: accountEndpoint,
                  allowAnyTokenFormat: accountEndpoint.isThirdParty,
                )
                .timeout(
                  validationTimeout,
                  onTimeout: () => throw DioException(
                    type: DioExceptionType.connectionTimeout,
                    requestOptions: RequestOptions(path: '/user/subscription'),
                  ),
                );
          }

          if (!_ownsSession(request)) return;
          // 保存到全局存储
          await storage.saveAuth(
            accessToken: accountToken,
            expiry: DateTime.now().add(const Duration(days: 365 * 10)),
            email: lastUsedAccount.displayName,
          );
          if (!_ownsSession(request)) return;
          endpointService.setCurrent(accountEndpoint);

          state = AuthState(
            status: AuthStatus.authenticated,
            accountId: lastUsedAccount.id,
            displayName: lastUsedAccount.displayName,
            subscriptionInfo: subscriptionInfo,
          );

          // 更新最后使用时间
          accountManager.updateLastUsed(lastUsedAccount.id);

          AppLogger.auth(
            'Auto-login successful with account: ${lastUsedAccount.displayName}',
          );

          return;
        } catch (e) {
          if (!_ownsSession(request)) return;
          AppLogger.w(
            'Auto-login failed for ${lastUsedAccount.displayName}: $e',
          );
          // 自动登录失败，设置错误状态
          final (errorCode, httpStatusCode) = AuthState.parseError(e);

          // 如果是网络错误，设置为未认证而不是错误，允许后续手动登录或重试
          if (errorCode == AuthErrorCode.networkTimeout ||
              errorCode == AuthErrorCode.networkError) {
            AppLogger.w(
              'Auto-login failed due to network error, showing login page',
              'Auth',
            );
            state = const AuthState(status: AuthStatus.unauthenticated);
          } else {
            // 非网络错误（如认证失败），显示错误状态
            state = AuthState(
              status: AuthStatus.error,
              errorCode: errorCode,
              httpStatusCode: httpStatusCode,
            );
          }
          return;
        }
      }
    }

    // 3. 无法自动登录，显示登录页
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 重新尝试自动登录
  /// 在网络恢复后由外部调用
  Future<void> retryAutoLogin() async {
    final request = _sessionRequest;
    // 只在未认证状态下才尝试自动登录
    if (state.status == AuthStatus.unauthenticated) {
      AppLogger.auth('Retrying auto-login...');

      // 短暂延迟，确保之前的请求已经超时完成
      // 避免重复请求问题
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_ownsSession(request)) return;

      // 再次检查状态，可能延迟期间状态已改变
      if (state.status != AuthStatus.unauthenticated) {
        AppLogger.auth('Auth status changed during delay, skipping retry');
        return;
      }

      state = const AuthState(status: AuthStatus.loading);
      await _checkExistingAuth();
    }
  }

  /// Validate replacement credentials before updating the existing saved ID.
  /// A response for a superseded account/session cannot overwrite a newer one.
  Future<void> replaceSavedAccountCredential(
    String accountId,
    String token,
  ) async {
    final manager = ref.read(accountManagerNotifierProvider.notifier);
    final account = ref
        .read(accountManagerNotifierProvider)
        .accounts
        .where((a) => a.id == accountId)
        .firstOrNull;
    if (account == null) throw StateError('Account no longer exists');
    final session = state;
    final endpoint = manager.getAccountApiEndpoint(accountId);
    final previousToken = await manager.getAccountToken(accountId);
    final info = await ref
        .read(naiAuthApiServiceProvider)
        .validateToken(
          token.trim(),
          endpoint: endpoint,
          allowAnyTokenFormat:
              endpoint.isThirdParty ||
              account.accountType == AccountType.credentials,
        );
    if (!identical(state, session) ||
        !ref
            .read(accountManagerNotifierProvider)
            .accounts
            .any((a) => a.id == accountId) ||
        await manager.getAccountToken(accountId) != previousToken ||
        manager.getAccountApiEndpoint(accountId) != endpoint) {
      throw StateError('Account changed while checking credentials. Retry.');
    }
    await manager.updateAccountToken(accountId, token.trim());
    if (session.isAuthenticated &&
        session.accountId == accountId &&
        identical(state, session)) {
      await ref
          .read(secureStorageServiceProvider)
          .saveAccessToken(token.trim());
      if (identical(state, session)) {
        state = session.copyWith(subscriptionInfo: info);
      }
    }
  }

  /// 使用 Token 登录
  ///
  /// [token] Persistent API Token (格式: pst-xxxx)
  /// [accountId] 账号ID（用于关联存储）
  /// [displayName] 显示名称
  Future<bool> loginWithToken(
    String token, {
    String? accountId,
    String? displayName,
  }) => _loginWithAccessToken(
    token,
    accountId: accountId,
    displayName: displayName,
    persistentToken: true,
    fallbackEmail: 'Token User',
    expiry: const Duration(days: 365 * 10),
  );

  /// 使用第三方 NAI-compatible API Token 登录。
  Future<bool> loginWithThirdPartyToken(
    String token, {
    required NaiApiEndpointConfig apiEndpoint,
    String? accountId,
    String? displayName,
  }) => _loginWithAccessToken(
    token.trim(),
    endpoint: apiEndpoint,
    fallbackEmail: apiEndpoint.mainBaseUrl,
    accountId: accountId,
    displayName: displayName,
    expiry: const Duration(days: 365 * 10),
  );

  /// 切换账号（使用已保存的 Token）
  ///
  /// [accountId] 账号ID
  /// [token] 已保存的 Token
  /// [displayName] 显示名称
  /// [accountType] 账号类型（决定验证方式）
  Future<bool> switchAccount(
    String accountId,
    String token, {
    String? displayName,
    required AccountType accountType,
  }) async {
    AppLogger.auth('Switching account: $displayName (type: $accountType)');

    final accountManager = ref.read(accountManagerNotifierProvider.notifier);
    final apiEndpoint = accountManager.getAccountApiEndpoint(accountId);

    final success = await (apiEndpoint.isThirdParty
        ? loginWithThirdPartyToken(
            token,
            apiEndpoint: apiEndpoint,
            accountId: accountId,
            displayName: displayName,
          )
        : accountType == AccountType.credentials
        ? _loginWithAccessToken(
            token,
            accountId: accountId,
            displayName: displayName,
          )
        : loginWithToken(
            token,
            accountId: accountId,
            displayName: displayName,
          ));

    // 登录成功后更新最后使用时间，确保下次启动时该账号排在最前
    if (success) {
      await accountManager.updateLastUsed(accountId);
      AppLogger.auth('Updated lastUsed for account: $displayName');
    }

    return success;
  }

  /// 内部方法：使用 accessToken 直接登录（credentials 类型）
  ///
  /// [accessToken] API 返回的 JWT accessToken
  /// [accountId] 账号ID
  /// [displayName] 显示名称
  Future<bool> _loginWithAccessToken(
    String token, {
    String? accountId,
    String? displayName,
    NaiApiEndpointConfig endpoint = NaiApiEndpointConfig.official,
    bool persistentToken = false,
    String fallbackEmail = '',
    Duration expiry = const Duration(days: 30),
  }) async {
    final request = ++_sessionRequest;
    final previousState = _captureLoginBase();
    final endpointService = ref.read(naiApiEndpointServiceProvider);
    state = state.copyWith(status: AuthStatus.loading);
    try {
      if (persistentToken && !NAIAuthApiService.isValidTokenFormat(token)) {
        throw ArgumentError(currentL10n.auth_tokenFormatDetail);
      }
      if (token.isEmpty) throw ArgumentError(currentL10n.auth_tokenEmpty);
      final subscription = await ref
          .read(naiAuthApiServiceProvider)
          .validateToken(
            token,
            endpoint: endpoint,
            allowAnyTokenFormat: endpoint.isThirdParty,
          );
      if (!_ownsSession(request)) return false;
      await _enableAutoLoginForSavedSession();
      if (!_ownsSession(request)) return false;
      await ref
          .read(secureStorageServiceProvider)
          .saveAuth(
            accessToken: token,
            expiry: DateTime.now().add(expiry),
            email: displayName ?? fallbackEmail,
          );
      if (!_ownsSession(request)) return false;
      endpointService.setCurrent(endpoint);
      state = AuthState(
        status: AuthStatus.authenticated,
        accountId: accountId,
        displayName: displayName,
        subscriptionInfo: subscription,
      );
      ref.read(guestSessionNotifierProvider.notifier).clear();
      return true;
    } catch (error) {
      if (!_ownsSession(request)) return false;
      AppLogger.e('Token session validation failed: $error');
      final (code, status) = AuthState.parseError(error);
      state = previousState.isAuthenticated
          ? previousState.copyWith(errorCode: code, httpStatusCode: status)
          : AuthState(
              status: AuthStatus.error,
              errorCode: code,
              httpStatusCode: status,
            );
      return false;
    }
  }

  /// 使用邮箱密码登录
  Future<bool> loginWithCredentials(
    String email,
    String password, {
    String? displayName,
  }) async {
    final request = ++_sessionRequest;
    // 保存当前状态，如果登录失败且之前已登录，可以恢复
    final previousState = _captureLoginBase();
    final wasAuthenticated = previousState.isAuthenticated;
    final endpointService = ref.read(naiApiEndpointServiceProvider);
    final previousEndpoint = endpointService.current;

    state = state.copyWith(status: AuthStatus.loading);

    try {
      final apiService = ref.read(naiAuthApiServiceProvider);
      final cryptoService = ref.read(naiCryptoServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final accountNotifier = ref.read(accountManagerNotifierProvider.notifier);

      // 1. 生成 Access Key（Argon2哈希）
      AppLogger.auth('Generating access key for: $email');
      final accessKey = await cryptoService.deriveAccessKey(email, password);
      if (!_ownsSession(request)) return false;
      AppLogger.auth('Access key generated, length: ${accessKey.length}');

      // 2. 使用 Access Key 登录
      AppLogger.auth('Logging in with access key...');
      final loginResponse = await apiService.loginWithKey(
        accessKey,
        endpoint: NaiApiEndpointConfig.official,
      );
      if (!_ownsSession(request)) return false;
      final accessToken = loginResponse['accessToken'] as String;
      AppLogger.auth('Login successful, received access token');

      // 3. 获取订阅信息
      AppLogger.auth('Fetching subscription info...');
      final subscriptionInfo = await apiService.validateToken(
        accessToken,
        endpoint: NaiApiEndpointConfig.official,
      );
      if (!_ownsSession(request)) return false;

      // 4. 获取显示名称
      final effectiveDisplayName = displayName ?? email.split('@').first;

      // 5. 保存账号到 AccountManager（使用 credentials 类型）
      final account = await accountNotifier.addAccount(
        identifier: email,
        token: accessToken,
        nickname: effectiveDisplayName,
        setAsDefault: true,
        accountType: AccountType.credentials,
      );
      if (!_ownsSession(request)) return false;
      final accountId = account.id;

      // 6. 保存 accessKey 用于后续 token 刷新
      AppLogger.auth('Saving accessKey for token refresh');
      await storage.saveAccountAccessKey(accountId, accessKey);
      if (!_ownsSession(request)) return false;

      // 7. 保存 Token 到安全存储
      await storage.saveAuth(
        accessToken: accessToken,
        expiry: DateTime.now().add(const Duration(days: 30)),
        email: email,
      );
      if (!_ownsSession(request)) return false;
      endpointService.resetToOfficial();

      // 8. 更新状态
      state = AuthState(
        status: AuthStatus.authenticated,
        accountId: accountId,
        displayName: effectiveDisplayName,
        subscriptionInfo: subscriptionInfo,
      );

      ref.read(guestSessionNotifierProvider.notifier).clear();
      AppLogger.auth('Credentials login successful for: $email');
      await _enableAutoLoginForSavedSession();
      if (!_ownsSession(request)) return false;
      return true;
    } catch (e) {
      if (!_ownsSession(request)) return false;
      AppLogger.e('Credentials login failed: $e');
      final (errorCode, httpStatusCode) = AuthState.parseError(e);
      endpointService.setCurrent(previousEndpoint);

      // 如果之前已登录（添加账号场景），或者在登录过程中变为已登录（如自动登录成功）
      // 则保留登录状态，只附加错误信息
      if (state.isAuthenticated) {
        // 当前已登录（可能是并发的自动登录成功了），保留当前状态只添加错误信息
        state = state.copyWith(
          errorCode: errorCode,
          httpStatusCode: httpStatusCode,
        );
        AppLogger.w(
          'Login failed but kept current authenticated state (concurrent login detected)',
          'AUTH',
        );
      } else if (wasAuthenticated) {
        // 之前是登录状态，恢复之前的状态并附加错误信息
        state = previousState.copyWith(
          errorCode: errorCode,
          httpStatusCode: httpStatusCode,
        );
        AppLogger.w(
          'Login failed but restored previous authenticated state',
          'AUTH',
        );
      } else {
        state = AuthState(
          status: AuthStatus.error,
          errorCode: errorCode,
          httpStatusCode: httpStatusCode,
        );
      }
      return false;
    }
  }

  /// 尝试添加账号（不影响当前登录状态）
  ///
  /// 用于已登录状态下添加新账号，失败时不会改变全局认证状态
  Future<AddAccountResult> tryAddAccount(
    String email,
    String password, {
    String? displayName,
  }) async {
    final request = ++_sessionRequest;
    try {
      final apiService = ref.read(naiAuthApiServiceProvider);
      final cryptoService = ref.read(naiCryptoServiceProvider);
      final storage = ref.read(secureStorageServiceProvider);
      final accountNotifier = ref.read(accountManagerNotifierProvider.notifier);
      final endpointService = ref.read(naiApiEndpointServiceProvider);

      // 1. 生成 Access Key（Argon2哈希）
      AppLogger.auth('tryAddAccount: Generating access key for: $email');
      final accessKey = await cryptoService.deriveAccessKey(email, password);
      if (!_ownsSession(request)) return const AddAccountResult(success: false);

      // 2. 使用 Access Key 登录
      AppLogger.auth('tryAddAccount: Logging in with access key...');
      final loginResponse = await apiService.loginWithKey(
        accessKey,
        endpoint: NaiApiEndpointConfig.official,
      );
      if (!_ownsSession(request)) return const AddAccountResult(success: false);
      final accessToken = loginResponse['accessToken'] as String;

      // 3. 获取订阅信息
      final subscriptionInfo = await apiService.validateToken(
        accessToken,
        endpoint: NaiApiEndpointConfig.official,
      );
      if (!_ownsSession(request)) return const AddAccountResult(success: false);

      // 4. 获取显示名称
      final effectiveDisplayName = displayName ?? email.split('@').first;

      // 5. 保存账号到 AccountManager
      final account = await accountNotifier.addAccount(
        identifier: email,
        token: accessToken,
        nickname: effectiveDisplayName,
        setAsDefault: true,
        accountType: AccountType.credentials,
      );
      if (!_ownsSession(request)) return const AddAccountResult(success: false);
      final accountId = account.id;

      // 6. 保存 accessKey 用于后续 token 刷新
      await storage.saveAccountAccessKey(accountId, accessKey);
      if (!_ownsSession(request)) return const AddAccountResult(success: false);

      // 7. 保存 Token 到安全存储
      await storage.saveAuth(
        accessToken: accessToken,
        expiry: DateTime.now().add(const Duration(days: 30)),
        email: email,
      );
      if (!_ownsSession(request)) return const AddAccountResult(success: false);
      endpointService.resetToOfficial();

      // 8. 更新全局状态（切换到新账号）
      state = AuthState(
        status: AuthStatus.authenticated,
        accountId: accountId,
        displayName: effectiveDisplayName,
        subscriptionInfo: subscriptionInfo,
      );

      ref.read(guestSessionNotifierProvider.notifier).clear();
      await _enableAutoLoginForSavedSession();
      if (!_ownsSession(request)) return const AddAccountResult(success: false);
      AppLogger.auth('tryAddAccount: Success for: $email');
      return AddAccountResult.ok();
    } catch (e) {
      if (!_ownsSession(request)) return const AddAccountResult(success: false);
      AppLogger.e('tryAddAccount: Failed: $e');
      final (errorCode, httpStatusCode) = AuthState.parseError(e);
      // 不改变全局状态，只返回错误信息
      return AddAccountResult.failed(errorCode, httpStatusCode);
    }
  }

  /// 登出
  ///
  /// [errorCode] 和 [httpStatusCode] 用于在登出时保留错误信息，以便 UI 显示提示
  Future<void> logout({AuthErrorCode? errorCode, int? httpStatusCode}) async {
    final request = ++_sessionRequest;
    _loginBase = null;
    AppLogger.w(
      '[AuthNotifier] logout() called, errorCode=$errorCode, httpStatusCode=$httpStatusCode',
      'AUTH',
    );
    AppLogger.w(
      '[AuthNotifier] current state: status=${state.status}, hasError=${state.hasError}',
      'AUTH',
    );

    final storage = ref.read(secureStorageServiceProvider);
    await storage.clearAuth();
    if (!_ownsSession(request)) return;
    ref.read(naiApiEndpointServiceProvider).resetToOfficial();
    ref.read(guestSessionNotifierProvider.notifier).clear();

    if (errorCode != null) {
      // 保留错误信息，让 UI 可以显示错误提示
      state = AuthState(
        status: AuthStatus.error,
        errorCode: errorCode,
        httpStatusCode: httpStatusCode,
      );
      AppLogger.w(
        '[AuthNotifier] state set to error: errorCode=$errorCode',
        'AUTH',
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
      AppLogger.w('[AuthNotifier] state set to unauthenticated', 'AUTH');
    }
  }

  /// 刷新订阅信息
  Future<void> refreshSubscription() async {
    if (!state.isAuthenticated) return;

    try {
      final apiService = ref.read(naiUserInfoApiServiceProvider);
      final subscriptionInfo = await apiService.getUserSubscription();
      state = state.copyWith(subscriptionInfo: subscriptionInfo);
    } catch (e) {
      AppLogger.e('Failed to refresh subscription: $e');
    }
  }

  /// 清除错误状态
  ///
  /// [delayMs] 延迟毫秒数，让 UI 有时间显示错误 Toast
  void clearError({int delayMs = 100}) async {
    AppLogger.w(
      '[AuthNotifier] clearError() called, current state: status=${state.status}, hasError=${state.hasError}',
      'AUTH',
    );

    if (state.hasError || state.status == AuthStatus.error) {
      // 延迟清除，让 UI 有时间显示错误提示
      AppLogger.w(
        '[AuthNotifier] waiting ${delayMs}ms before clearing error...',
        'AUTH',
      );
      await Future.delayed(Duration(milliseconds: delayMs));

      // 如果当前是已登录状态，清除错误但不改变状态
      // 如果当前是错误/未登录状态，重置为未登录
      final nextStatus = state.isAuthenticated
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;

      state = state.copyWith(status: nextStatus, clearError: true);
      AppLogger.w(
        '[AuthNotifier] error cleared, state now: status=${state.status}',
        'AUTH',
      );
    }
  }

  Future<void> _enableAutoLoginForSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(autoLoginPreferenceKey) != true) {
      await prefs.setBool(autoLoginPreferenceKey, true);
      AppLogger.i(
        'Auto-login enabled after successful saved session login',
        'Auth',
      );
    }
  }
}

/// 是否已认证 Provider
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
}

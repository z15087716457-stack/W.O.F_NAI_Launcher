import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/jwt_parser.dart';
import '../../presentation/providers/account_manager_provider.dart';
import '../datasources/remote/nai_auth_api_service.dart';
import '../models/auth/saved_account.dart';

part 'token_refresh_service.g.dart';

/// Token 刷新服务
///
/// 负责在 JWT token 过期时自动刷新，使用保存的 accessKey 重新获取 token。
@Riverpod(keepAlive: true)
class TokenRefreshService extends _$TokenRefreshService {
  /// 是否正在刷新中（防止并发刷新）
  bool _isRefreshing = false;

  @override
  void build() {
    // 服务初始化，无需特别操作
    AppLogger.d('TokenRefreshService initialized', 'TokenRefresh');
  }

  /// 刷新当前账号的 token
  ///
  /// 返回 true 表示刷新成功，false 表示失败或不需要刷新
  Future<bool> refreshCurrentToken() async {
    // 避免并发刷新
    if (_isRefreshing) {
      AppLogger.d(
        'Token refresh already in progress, skipping',
        'TokenRefresh',
      );
      return false;
    }

    _isRefreshing = true;
    try {
      return await _performRefresh();
    } catch (e, stack) {
      AppLogger.e('Token refresh failed: $e', e, stack, 'TokenRefresh');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 执行刷新逻辑
  Future<bool> _performRefresh() async {
    final storage = ref.read(secureStorageServiceProvider);
    final authRevision = storage.authRevision;
    final accountManager = ref.read(accountManagerNotifierProvider.notifier);
    final accounts = ref.read(accountManagerNotifierProvider).accounts;

    // 1. 获取当前 token
    final currentToken = await storage.getAccessToken();
    if (currentToken == null || currentToken.isEmpty) {
      AppLogger.w('No token to refresh', 'TokenRefresh');
      return false;
    }

    // 2. 检查是否为 JWT（Persistent Token 不需要刷新）
    if (!JWTParser.isJWT(currentToken)) {
      AppLogger.d(
        'Token is not JWT (probably pst-xxx), skip refresh',
        'TokenRefresh',
      );
      return false;
    }

    // 3. 查找对应的账号
    SavedAccount? currentAccount;
    for (final account in accounts) {
      final accountToken = await accountManager.getAccountToken(account.id);
      if (accountToken == currentToken) {
        currentAccount = account;
        break;
      }
    }

    if (currentAccount == null) {
      AppLogger.w('Cannot find account for current token', 'TokenRefresh');
      return false;
    }

    // 4. 只刷新 credentials 类型的账号
    if (currentAccount.accountType != AccountType.credentials) {
      AppLogger.d(
        'Account type is ${currentAccount.accountType}, skip refresh',
        'TokenRefresh',
      );
      return false;
    }

    // 5. 获取保存的 accessKey
    final accessKey = await storage.getAccountAccessKey(currentAccount.id);
    if (accessKey == null || accessKey.isEmpty) {
      AppLogger.w(
        'No accessKey found for account ${currentAccount.id}, cannot refresh',
        'TokenRefresh',
      );
      return false;
    }

    // 6. 使用 accessKey 重新登录获取新 token
    AppLogger.d(
      'Refreshing token for account: ${currentAccount.displayName}',
      'TokenRefresh',
    );

    final apiService = ref.read(naiAuthApiServiceProvider);
    final loginResponse = await apiService.loginWithKey(accessKey);
    final newToken = loginResponse['accessToken'] as String;

    if (!await _matchesSavedCredentials(
      currentAccount,
      currentToken,
      accessKey,
    )) {
      return false;
    }
    final accountId = currentAccount.id;
    await accountManager.updateAccountToken(accountId, newToken);

    // 刷新已保存账号不等于切换活动会话。
    if (await storage.getAccessToken() != currentToken ||
        storage.authRevision != authRevision ||
        !ref
            .read(accountManagerNotifierProvider)
            .accounts
            .any((a) => a.id == accountId)) {
      return false;
    }
    await storage.saveAuth(
      accessToken: newToken,
      expiry: DateTime.now().add(const Duration(days: 30)),
      email: currentAccount.email,
    );

    AppLogger.d('Token refreshed successfully', 'TokenRefresh');
    return true;
  }

  /// 为指定账号刷新 token（用于 401 错误时的重试）
  ///
  /// 返回新 token，如果刷新失败返回 null
  Future<String?> refreshTokenForAccount(String accountId) async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final authRevision = storage.authRevision;
      final currentToken = await storage.getAccessToken();
      final accountManager = ref.read(accountManagerNotifierProvider.notifier);
      final accounts = ref.read(accountManagerNotifierProvider).accounts;

      // 获取账号信息
      final account = accounts.where((a) => a.id == accountId).firstOrNull;
      if (account == null) {
        AppLogger.w('Account $accountId not found', 'TokenRefresh');
        return null;
      }

      // 只刷新 credentials 类型
      if (account.accountType != AccountType.credentials) {
        AppLogger.d(
          'Account type is ${account.accountType}, cannot refresh',
          'TokenRefresh',
        );
        return null;
      }

      final accountToken = await accountManager.getAccountToken(accountId);

      // 获取 accessKey
      final accessKey = await storage.getAccountAccessKey(accountId);
      if (accessKey == null || accessKey.isEmpty) {
        AppLogger.w('No accessKey for account $accountId', 'TokenRefresh');
        return null;
      }

      // 重新登录
      final apiService = ref.read(naiAuthApiServiceProvider);
      final loginResponse = await apiService.loginWithKey(accessKey);
      final newToken = loginResponse['accessToken'] as String;

      if (!await _matchesSavedCredentials(account, accountToken, accessKey)) {
        return null;
      }
      await accountManager.updateAccountToken(accountId, newToken);
      if (accountToken != null &&
          currentToken == accountToken &&
          await storage.getAccessToken() == currentToken &&
          storage.authRevision == authRevision &&
          ref
              .read(accountManagerNotifierProvider)
              .accounts
              .any((a) => a.id == accountId)) {
        await storage.saveAuth(
          accessToken: newToken,
          expiry: DateTime.now().add(const Duration(days: 30)),
          email: account.email,
        );
      }

      AppLogger.d('Token refreshed for account $accountId', 'TokenRefresh');
      return newToken;
    } catch (e, stack) {
      AppLogger.e(
        'Failed to refresh token for account $accountId: $e',
        e,
        stack,
        'TokenRefresh',
      );
      return null;
    }
  }

  Future<bool> _matchesSavedCredentials(
    SavedAccount account,
    String? token,
    String accessKey,
  ) async {
    final storage = ref.read(secureStorageServiceProvider);
    final manager = ref.read(accountManagerNotifierProvider.notifier);
    final savedToken = await manager.getAccountToken(account.id);
    final savedKey = await storage.getAccountAccessKey(account.id);
    final saved = ref
        .read(accountManagerNotifierProvider)
        .accounts
        .where((a) => a.id == account.id)
        .firstOrNull;
    return saved?.accountType == AccountType.credentials &&
        saved?.email == account.email &&
        savedToken == token &&
        savedKey == accessKey;
  }

  /// 检查当前 token 是否即将过期，如果是则刷新
  ///
  /// 用于主动刷新策略
  Future<void> checkAndRefreshIfNeeded() async {
    final storage = ref.read(secureStorageServiceProvider);
    final token = await storage.getAccessToken();

    if (token == null || token.isEmpty) return;

    // 只检查 JWT
    if (!JWTParser.isJWT(token)) return;

    // 检查是否即将过期（5 分钟内）
    if (JWTParser.isExpiringSoon(token)) {
      AppLogger.d('Token expiring soon, triggering refresh', 'TokenRefresh');
      await refreshCurrentToken();
    }
  }
}

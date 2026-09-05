import 'package:flutter_cache_manager/flutter_cache_manager.dart';

const _gelbooruReferer = 'https://gelbooru.com/';
const _gelbooruContentCookie = 'fringeBenefits=yup';
const _aiTagReferer = 'https://aitag.win/';
const _onlineGalleryBrowserUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/126.0.0.0 Safari/537.36';

const _gelbooruImageHeaders = <String, String>{
  'User-Agent': _onlineGalleryBrowserUserAgent,
  'Referer': _gelbooruReferer,
  'Cookie': _gelbooruContentCookie,
  'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
};

/// pximg（Pixiv CDN）防盗链：必须带 pixiv.net 的 Referer。
const _pximgImageHeaders = <String, String>{
  'User-Agent': _onlineGalleryBrowserUserAgent,
  'Referer': 'https://www.pixiv.net/',
  'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
};

const _aiTagImageHeaders = <String, String>{
  'User-Agent': _onlineGalleryBrowserUserAgent,
  'Referer': _aiTagReferer,
  'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
};

final _aiTagMediaHosts = <String>{'ai-img.10118899.xyz'};

/// Danbooru 图片缓存管理器
///
/// 使用自定义配置提升图片加载性能：
/// - 最大缓存对象数：1000（支持大量图片）
/// - 过期时间：7天
/// - 支持 HTTP/2（通过全局 Dio 实例）
class DanbooruImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'danbooruImageCache';

  static final DanbooruImageCacheManager _instance =
      DanbooruImageCacheManager._internal();

  factory DanbooruImageCacheManager() => _instance;

  DanbooruImageCacheManager._internal()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 1000,
        ),
      );

  /// 获取单例实例
  static DanbooruImageCacheManager get instance => _instance;
}

void registerAiTagImageHost(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !_isHttpScheme(uri.scheme) || uri.host.isEmpty) return;
  _aiTagMediaHosts.add(uri.host.toLowerCase());
}

Map<String, String> onlineGalleryImageHeadersForUrl(String url) {
  final uri = Uri.tryParse(url);
  if (_isGelbooruMediaHost(uri)) return _gelbooruImageHeaders;
  if (_isPximgMediaHost(uri)) return _pximgImageHeaders;
  if (_isAiTagMediaHost(uri)) return _aiTagImageHeaders;
  return const {};
}

String? onlineGalleryImageCacheKeyForUrl(String url) {
  final uri = Uri.tryParse(url);
  if (_isGelbooruMediaHost(uri)) return 'gelbooru-image-v2:$url';
  return null;
}

bool shouldPrefetchOnlineGalleryImage(String url) {
  return !_isGelbooruMediaHost(Uri.tryParse(url));
}

bool _isGelbooruMediaHost(Uri? uri) {
  if (uri == null || uri.host.isEmpty) return false;

  final host = uri.host.toLowerCase();
  return host == 'gelbooru.com' || host.endsWith('.gelbooru.com');
}

bool _isPximgMediaHost(Uri? uri) {
  if (uri == null || uri.host.isEmpty) return false;

  final host = uri.host.toLowerCase();
  return host == 'pximg.net' || host.endsWith('.pximg.net');
}

bool _isAiTagMediaHost(Uri? uri) {
  if (uri == null || uri.host.isEmpty || !_isHttpScheme(uri.scheme)) {
    return false;
  }
  return _aiTagMediaHosts.contains(uri.host.toLowerCase());
}

bool _isHttpScheme(String scheme) {
  final normalized = scheme.toLowerCase();
  return normalized == 'http' || normalized == 'https';
}

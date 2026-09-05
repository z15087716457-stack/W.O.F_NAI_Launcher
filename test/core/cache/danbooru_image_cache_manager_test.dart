import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/danbooru_image_cache_manager.dart';

void main() {
  group('onlineGalleryImageHeadersForUrl', () {
    test('adds browser image headers for Gelbooru CDN images', () {
      final headers = onlineGalleryImageHeadersForUrl(
        'https://img4.gelbooru.com/thumbnails/51/d1/thumbnail_image.jpg',
      );

      expect(headers['Referer'], 'https://gelbooru.com/');
      expect(headers['Accept'], contains('image/'));
      expect(headers['User-Agent'], contains('Mozilla/5.0'));
    });

    test('adds browser image headers for Gelbooru origin images', () {
      final headers = onlineGalleryImageHeadersForUrl(
        'https://gelbooru.com/images/51/d1/source.jpg',
      );

      expect(headers['Referer'], 'https://gelbooru.com/');
      expect(headers['Accept'], contains('image/'));
      expect(headers['User-Agent'], contains('Mozilla/5.0'));
    });

    test('adds the Gelbooru fringe benefits cookie for Gelbooru requests', () {
      final headers = onlineGalleryImageHeadersForUrl(
        'https://gelbooru.com/index.php',
      );

      expect(headers['Cookie'], 'fringeBenefits=yup');
    });

    test('does not add Gelbooru headers for other or invalid URLs', () {
      expect(
        onlineGalleryImageHeadersForUrl(
          'https://cdn.donmai.us/sample/test.jpg',
        ),
        isEmpty,
      );
      expect(onlineGalleryImageHeadersForUrl('not a url'), isEmpty);
    });
  });

  group('onlineGalleryImageCacheKeyForUrl', () {
    test('uses a versioned key for Gelbooru media', () {
      const url =
          'https://img4.gelbooru.com/thumbnails/51/d1/thumbnail_image.jpg';

      final key = onlineGalleryImageCacheKeyForUrl(url);

      expect(key, isNotNull);
      expect(key, isNot(url));
      expect(key, contains('gelbooru-image-v2'));
      expect(key, contains(url));
    });

    test('keeps the default cache key for other sites', () {
      expect(
        onlineGalleryImageCacheKeyForUrl(
          'https://cdn.donmai.us/sample/test.jpg',
        ),
        isNull,
      );
      expect(onlineGalleryImageCacheKeyForUrl('not a url'), isNull);
    });
  });

  group('shouldPrefetchOnlineGalleryImage', () {
    test('skips Gelbooru media that require browser headers', () {
      expect(
        shouldPrefetchOnlineGalleryImage(
          'https://img4.gelbooru.com/thumbnails/51/d1/thumbnail_image.jpg',
        ),
        isFalse,
      );
      expect(
        shouldPrefetchOnlineGalleryImage(
          'https://gelbooru.com/images/51/d1/source.jpg',
        ),
        isFalse,
      );
    });

    test('keeps bare prefetch for Danbooru media', () {
      expect(
        shouldPrefetchOnlineGalleryImage(
          'https://cdn.donmai.us/preview/test.jpg',
        ),
        isTrue,
      );
    });
  });

  group('AI TAG image strategy', () {
    test('adds browser headers for the static asset host', () {
      final headers = onlineGalleryImageHeadersForUrl(
        'https://AI-IMG.10118899.XYZ/SD/9/image.webp',
      );

      expect(headers['Referer'], 'https://aitag.win/');
      expect(headers['Accept'], contains('image/'));
      expect(headers['User-Agent'], contains('Mozilla/5.0'));
    });

    test('keeps the default URL cache key and prefetch behavior', () {
      const first = 'https://ai-img.10118899.xyz/SD/9/image.webp';
      const second = 'https://ai-img.10118899.xyz/SD/9/image.png';

      expect(onlineGalleryImageCacheKeyForUrl(first), isNull);
      expect(onlineGalleryImageCacheKeyForUrl(second), isNull);
      expect(shouldPrefetchOnlineGalleryImage(first), isTrue);
    });

    test('registers valid dynamic hosts idempotently and normalizes case', () {
      const url = 'https://Dynamic.AI-Tag.example/assets/a.png';
      registerAiTagImageHost(url);
      registerAiTagImageHost(url);

      final headers = onlineGalleryImageHeadersForUrl(
        'HTTPS://dynamic.ai-tag.example/assets/b.png',
      );
      expect(headers['Referer'], 'https://aitag.win/');
      expect(
        onlineGalleryImageCacheKeyForUrl(
          'https://DYNAMIC.ai-tag.example/assets/b.png',
        ),
        isNull,
      );
    });

    test('registers HTTP URLs and matches only the exact host', () {
      registerAiTagImageHost('http://http-ai-tag.example/assets');
      expect(
        onlineGalleryImageHeadersForUrl(
          'http://http-ai-tag.example/a.png',
        )['Referer'],
        'https://aitag.win/',
      );
      for (final url in [
        'https://sub.http-ai-tag.example/a.png',
        'https://ai-img.10118899.xyz.other.example/a.png',
        'ftp://ai-img.10118899.xyz/a.png',
      ]) {
        expect(onlineGalleryImageHeadersForUrl(url), isEmpty);
        expect(onlineGalleryImageCacheKeyForUrl(url), isNull);
      }
    });

    test('ignores invalid dynamic hosts', () {
      for (final url in [
        'ftp://invalid.example/image.png',
        '/relative/image.png',
        'https:///missing-host.png',
        '//no-scheme.example/image.png',
        'https://[invalid',
        '',
      ]) {
        registerAiTagImageHost(url);
      }
      for (final host in ['invalid.example', 'no-scheme.example']) {
        expect(
          onlineGalleryImageHeadersForUrl('https://$host/image.png'),
          isEmpty,
        );
        expect(
          onlineGalleryImageCacheKeyForUrl('https://$host/image.png'),
          isNull,
        );
      }
    });

    test('keeps Gelbooru and Pixiv strategies after host registration', () {
      const gelbooru = 'https://img4.gelbooru.com/a.png';
      const pixiv = 'https://i.pximg.net/a.png';
      registerAiTagImageHost(gelbooru);
      registerAiTagImageHost(pixiv);
      expect(
        onlineGalleryImageHeadersForUrl(gelbooru)['Referer'],
        'https://gelbooru.com/',
      );
      expect(
        onlineGalleryImageCacheKeyForUrl(gelbooru),
        'gelbooru-image-v2:$gelbooru',
      );
      expect(shouldPrefetchOnlineGalleryImage(gelbooru), isFalse);
      expect(
        onlineGalleryImageHeadersForUrl(pixiv)['Referer'],
        'https://www.pixiv.net/',
      );
      expect(
        onlineGalleryImageHeadersForUrl(pixiv)['Accept'],
        contains('image/'),
      );
      expect(
        onlineGalleryImageHeadersForUrl(pixiv)['User-Agent'],
        contains('Mozilla/5.0'),
      );
      expect(onlineGalleryImageCacheKeyForUrl(pixiv), isNull);
      expect(shouldPrefetchOnlineGalleryImage(pixiv), isTrue);
    });
  });
}

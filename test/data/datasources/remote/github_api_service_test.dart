import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/datasources/remote/github_api_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';

/// 用固定的 Release 数据代替 GitHub，不发真实请求。[octetStream] 里的地址像 GitHub 的
/// Release 附件那样按 application/octet-stream 返回。
class _ReleaseAdapter implements HttpClientAdapter {
  _ReleaseAdapter(this.routes, {this.octetStream = const {}});

  final Map<String, Object> routes;
  final Set<String> octetStream;
  final requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requested.add(url);
    final body = routes[url];
    if (body == null) return ResponseBody.fromString('', 404);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [
          octetStream.contains(url)
              ? 'application/octet-stream'
              : Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _base = 'https://api.example.test';
const _download = 'https://example.test/download';

Map<String, Object> _githubAsset(String name, int size) => {
  'name': name,
  'browser_download_url': '$_download/$name',
  'size': size,
};

Map<String, Object> _release(List<Map<String, Object>> assets) => {
  'tag_name': 'v2.1.0',
  'name': 'W.O.F NAI Studio v2.1.0',
  'body': 'notes',
  'published_at': '2026-10-30T00:00:00Z',
  'html_url': 'https://example.test/releases/v2.1.0',
  'assets': assets,
};

GitHubApiService _service(_ReleaseAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: _base))..httpClientAdapter = adapter;
  return GitHubApiService(dio: dio);
}

void main() {
  for (final scenario in [
    (
      status: 403,
      body: {'message': 'Access denied by policy'},
      headers: <String, String>{},
      limited: false,
    ),
    (
      status: 403,
      body: {'message': 'API rate limit exceeded'},
      headers: {
        'x-ratelimit-remaining': '0',
        'x-ratelimit-reset': '1893456000',
      },
      limited: true,
    ),
    (
      status: 403,
      body: {'message': 'You have exceeded a secondary rate limit'},
      headers: {
        'retry-after': '60',
        'x-ratelimit-remaining': '5',
        'x-ratelimit-reset': '1893456000',
      },
      limited: true,
    ),
    (
      status: 429,
      body: {'message': 'Too many requests'},
      headers: <String, String>{},
      limited: true,
    ),
    (
      status: 404,
      body: {'message': 'Not Found'},
      headers: <String, String>{},
      limited: false,
    ),
    (
      status: 403,
      body: {'message': 123},
      headers: {'x-ratelimit-reset': '1893456000'},
      limited: false,
    ),
  ]) {
    test(
      'HTTP ${scenario.status} preserves reason and identifies rate limits: ${scenario.body}',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        var requests = 0;
        server.listen((request) async {
          requests++;
          request.response.statusCode = scenario.status;
          request.response.headers.contentType = ContentType.json;
          scenario.headers.forEach(request.response.headers.set);
          request.response.write(jsonEncode(scenario.body));
          await request.response.close();
        });
        final dio = Dio(
          BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}'),
        );
        addTearDown(dio.close);
        final started = DateTime.now().toUtc();
        await expectLater(
          GitHubApiService(dio: dio).fetchLatestRelease(
            owner: 'test',
            repo: 'studio',
            currentVersion: '2.2.4',
          ),
          throwsA(
            isA<GitHubApiException>()
                .having((e) => e.statusCode, 'status', scenario.status)
                .having(
                  (e) => e.message,
                  'server reason',
                  scenario.body['message'] is String
                      ? scenario.body['message']
                      : 'Forbidden',
                )
                .having((e) => e.rateLimited, 'rate limited', scenario.limited)
                .having(
                  (e) => e.originalError,
                  'original error',
                  isA<DioException>(),
                )
                .having(
                  (e) => e.toString(),
                  'diagnostics',
                  contains('Response:'),
                )
                .having(
                  (e) => e.retryAt?.millisecondsSinceEpoch,
                  'retry time',
                  scenario.headers.containsKey('retry-after')
                      ? inInclusiveRange(
                          started
                              .add(const Duration(seconds: 60))
                              .millisecondsSinceEpoch,
                          DateTime.now()
                              .toUtc()
                              .add(const Duration(minutes: 2))
                              .millisecondsSinceEpoch,
                        )
                      : scenario.headers['x-ratelimit-remaining'] == '0'
                      ? DateTime.utc(2030).millisecondsSinceEpoch
                      : isNull,
                ),
          ),
        );
        expect(requests, 1);
      },
    );
  }

  const portableHash =
      'ac94c80df00816b0dec6b46d68fb82bc1a1c36c35088d6bb3ee5b29702d9b39a';
  const installerHash =
      'd7ffbef4782587155f72ea8ac93d2ca670ef6379c175174354328aa153360329';
  const releaseUrl = 'https://example.com/releases/v2.2.0';

  for (final contentType in ['application/json', 'application/octet-stream']) {
    test('reads a manifest returned as $contentType', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final baseUrl = 'http://127.0.0.1:${server.port}';
      const fileName = 'WOF_NAI_Studio_Windows_2.2.0_Portable.zip';
      server.listen((request) async {
        final manifest = request.uri.path == '/manifest';
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          manifest ? contentType : 'application/json',
        );
        request.response.add(
          utf8.encode(
            jsonEncode(
              manifest
                  ? {
                      'assets': [
                        {
                          'fileName': fileName,
                          'sha256': portableHash,
                          'label': 'manifest metadata',
                        },
                      ],
                    }
                  : {
                      'tag_name': 'v2.2.0',
                      'assets': [
                        {
                          'name': fileName,
                          'browser_download_url':
                              'https://example.com/update.zip',
                        },
                        {
                          'name': 'release_manifest.json',
                          'browser_download_url': '$baseUrl/manifest',
                        },
                      ],
                    },
            ),
          ),
        );
        await request.response.close();
      });
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      addTearDown(dio.close);

      final info = await GitHubApiService(dio: dio).fetchLatestRelease(
        owner: 'test',
        repo: 'studio',
        currentVersion: '2.1.2',
        platform: 'windows-portable',
      );

      expect(info.primaryAsset!.sha256, portableHash);
      expect(info.primaryAsset!.label, 'manifest metadata');
      expect(info.supportsInAppInstall, isTrue);
    });
  }

  for (final platform in ['windows-portable', 'windows-installer']) {
    for (final manifest in ['absent', 'unavailable', 'available']) {
      test(
        '$platform keeps automatic updating with manifest $manifest',
        () async {
          final requests = <String>[];
          final dio = Dio();
          addTearDown(dio.close);
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requests.add(options.path);
                if (options.path.endsWith('/releases/latest')) {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: {
                        'tag_name': 'v2.2.0',
                        'html_url': releaseUrl,
                        'assets': [
                          {
                            'name': 'WOF_NAI_Studio_Windows_2.2.0_Portable.zip',
                            'browser_download_url':
                                'https://example.com/update.zip',
                            'digest': 'sha256:$portableHash',
                            'size': 322937159,
                          },
                          {
                            'name': 'WOF_NAI_Studio_Windows_2.2.0_Setup.exe',
                            'browser_download_url':
                                'https://example.com/setup.exe',
                            'digest': 'sha256:$installerHash',
                            'size': 200295727,
                          },
                          if (manifest != 'absent')
                            {
                              'name': 'release_manifest.json',
                              'browser_download_url':
                                  'https://example.com/manifest',
                            },
                        ],
                      },
                    ),
                  );
                } else if (manifest == 'unavailable') {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      type: DioExceptionType.receiveTimeout,
                    ),
                  );
                } else {
                  handler.resolve(
                    Response(
                      requestOptions: options,
                      statusCode: 200,
                      data: jsonEncode({
                        'assets': [
                          {
                            'fileName':
                                'WOF_NAI_Studio_Windows_2.2.0_Portable.zip',
                            'sha256': portableHash,
                          },
                          {
                            'fileName':
                                'WOF_NAI_Studio_Windows_2.2.0_Setup.exe',
                            'sha256': installerHash,
                          },
                        ],
                      }),
                    ),
                  );
                }
              },
            ),
          );

          final info = await GitHubApiService(dio: dio).fetchLatestRelease(
            owner: 'test',
            repo: 'studio',
            currentVersion: '2.1.2',
            platform: platform,
          );

          final installer = platform == 'windows-installer';
          expect(info.version, '2.2.0');
          expect(info.htmlUrl, releaseUrl);
          expect(info.supportsInAppInstall, isTrue);
          expect(
            info.primaryAsset!.type,
            installer
                ? ReleaseAssetType.windowsInstaller
                : ReleaseAssetType.windowsPortable,
          );
          expect(
            info.primaryAsset!.sha256,
            installer ? installerHash : portableHash,
          );
          expect(requests, [
            '/repos/test/studio/releases/latest',
            if (manifest != 'absent') 'https://example.com/manifest',
          ]);
        },
      );
    }
  }

  group('Windows and macOS packages in one release', () {
    const setup = 'WOF_NAI_Studio_Windows_2.1.0_Setup.exe';
    const portable = 'WOF_NAI_Studio_Windows_2.1.0_Portable.zip';
    const mac = 'WOF_NAI_Studio_macOS_2.1.0_Portable.zip';

    // Release 里的上传顺序：校验文件夹在安装包之间，清单最后上传。
    final fullRelease = _release([
      _githubAsset('$mac.sha256', 96),
      _githubAsset(mac, 300),
      _githubAsset('$portable.sha256', 96),
      _githubAsset(portable, 200),
      _githubAsset(setup, 100),
      _githubAsset('checksums.txt', 300),
      _githubAsset('release_manifest.json', 1000),
    ]);
    final manifest = {
      'version': '2.1.0+43',
      'tag': 'v2.1.0',
      'assets': [
        {
          'platform': 'macos',
          'type': 'macos-portable',
          'fileName': mac,
          'downloadUrl': '$_download/$mac',
          'sha256': 'mac-sha',
          'size': 300,
        },
        {
          'platform': 'windows',
          'type': 'windows-installer',
          'fileName': setup,
          'downloadUrl': '$_download/$setup',
          'sha256': 'setup-sha',
          'size': 100,
        },
        {
          'platform': 'windows',
          'type': 'windows-portable',
          'fileName': portable,
          'downloadUrl': '$_download/$portable',
          'sha256': 'portable-sha',
          'size': 200,
        },
      ],
    };
    final routes = <String, Object>{
      '$_base/repos/owner/repo/releases/latest': fullRelease,
      '$_download/release_manifest.json': manifest,
    };

    test('macOS picks the app archive with its manifest checksum', () async {
      final info = await _service(_ReleaseAdapter(routes)).fetchLatestRelease(
        owner: 'owner',
        repo: 'repo',
        currentVersion: '2.0.0',
        platform: 'macos',
      );

      expect(info.isNewer, isTrue);
      expect(info.primaryAsset?.type, ReleaseAssetType.macosPortable);
      expect(info.primaryAsset?.fileName, mac);
      expect(info.primaryAsset?.sha256, 'mac-sha');
      expect(info.downloadUrl, '$_download/$mac');
      expect(info.supportsInAppInstall, isTrue);
    });

    test('macOS reads the manifest GitHub serves as octet-stream', () async {
      final info =
          await _service(
            _ReleaseAdapter(
              routes,
              octetStream: {'$_download/release_manifest.json'},
            ),
          ).fetchLatestRelease(
            owner: 'owner',
            repo: 'repo',
            currentVersion: '2.0.0',
            platform: 'macos',
          );

      expect(info.primaryAsset?.fileName, mac);
      expect(info.primaryAsset?.sha256, 'mac-sha');
      expect(info.supportsInAppInstall, isTrue);
    });

    test('macOS keeps in-app updates with only the GitHub digest', () async {
      const digest =
          'AC94C80DF00816B0DEC6B46D68FB82BC1A1C36C35088D6BB3EE5B29702D9B39A';
      final info =
          await _service(
            _ReleaseAdapter({
              '$_base/repos/owner/repo/releases/latest': _release([
                {
                  ..._githubAsset('$mac.sha256', 96),
                  'digest': 'sha256:${'b' * 64}',
                },
                {..._githubAsset(mac, 300), 'digest': 'sha256:$digest'},
                {..._githubAsset(setup, 100), 'digest': 'sha256:${'c' * 64}'},
              ]),
            }),
          ).fetchLatestRelease(
            owner: 'owner',
            repo: 'repo',
            currentVersion: '2.0.0',
            platform: 'macos',
          );

      expect(info.primaryAsset?.fileName, mac);
      expect(info.primaryAsset?.sha256, digest.toLowerCase());
      expect(info.supportsInAppInstall, isTrue);
    });

    test('macOS without a manifest still skips the checksum sidecar', () async {
      final info =
          await _service(
            _ReleaseAdapter({
              '$_base/repos/owner/repo/releases/latest': _release([
                _githubAsset('$mac.sha256', 96),
                _githubAsset(mac, 300),
                _githubAsset(setup, 100),
              ]),
            }),
          ).fetchLatestRelease(
            owner: 'owner',
            repo: 'repo',
            currentVersion: '2.0.0',
            platform: 'macos',
          );

      expect(info.primaryAsset?.fileName, mac);
      // 没有清单、GitHub 也没给 digest 就没有 SHA256，只能去 Release 页面手动下载。
      expect(info.supportsInAppInstall, isFalse);
    });

    test(
      'macOS never falls back to a Windows package when the release has no Mac build',
      () async {
        final info =
            await _service(
              _ReleaseAdapter({
                '$_base/repos/owner/repo/releases/latest': _release([
                  _githubAsset(setup, 100),
                  _githubAsset(portable, 200),
                ]),
              }),
            ).fetchLatestRelease(
              owner: 'owner',
              repo: 'repo',
              currentVersion: '2.0.0',
              platform: 'macos',
            );

        expect(info.primaryAsset, isNull);
        expect(info.downloadUrl, 'https://example.test/releases/v2.1.0');
        expect(info.supportsInAppInstall, isFalse);
      },
    );

    test(
      'Windows keeps choosing its own packages next to a Mac build',
      () async {
        final service = _service(_ReleaseAdapter(routes));

        final installer = await service.fetchLatestRelease(
          owner: 'owner',
          repo: 'repo',
          currentVersion: '2.0.0',
          platform: 'windows-installer',
        );
        final portableInfo = await service.fetchLatestRelease(
          owner: 'owner',
          repo: 'repo',
          currentVersion: '2.0.0',
          platform: 'windows-portable',
        );

        expect(installer.primaryAsset?.fileName, setup);
        expect(installer.primaryAsset?.sha256, 'setup-sha');
        expect(portableInfo.primaryAsset?.fileName, portable);
        expect(portableInfo.primaryAsset?.sha256, 'portable-sha');
      },
    );
  });
}

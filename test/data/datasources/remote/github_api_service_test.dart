import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/datasources/remote/github_api_service.dart';
import 'package:nai_launcher/data/models/version/release_asset_info.dart';

void main() {
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
}

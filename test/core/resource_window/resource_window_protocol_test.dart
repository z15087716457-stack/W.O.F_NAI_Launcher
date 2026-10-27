import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/resource_window_protocol.dart';
import 'package:nai_launcher/data/models/resources/floating_window_data.dart';

void main() {
  test('empty native arguments select the primary startup', () async {
    final calls = <String>[];
    await dispatchResourceWindow(
      arguments: '',
      startMain: () async => calls.add('main'),
      startResource: (_) async => calls.add('resource'),
    );
    expect(calls, ['main']);
  });

  for (final kind in FloatingResourceKind.values) {
    test(
      '$kind starts only the lightweight entry and preserves scope',
      () async {
        const scope = FloatingResourceScope(
          folderPath: 'D:/synthetic/gallery',
          folderId: 'folder',
          categoryId: 'category',
          collectionId: 'collection',
          favoritesOnly: true,
        );
        final calls = <String>[];
        await dispatchResourceWindow(
          arguments: ResourceWindowArguments(kind: kind, scope: scope).encode(),
          startMain: () async =>
              fail('Child must not prepare/open main stores'),
          startResource: (arguments) async {
            calls.add('resource');
            expect(arguments.kind, kind);
            expect(arguments.scope, scope);
          },
        );
        expect(calls, ['resource']);
      },
    );
  }

  test(
    'launch preserves appearance, custom font and monitor logical layout',
    () {
      const args = ResourceWindowArguments(
        kind: FloatingResourceKind.gallery,
        brightness: 'light',
        locale: 'zh-TW',
        fontKey: 'system:Arial',
        rect: {
          'left': -800.0,
          'top': 10.0,
          'width': 1040.0,
          'height': 680.0,
          'dpiScale': 1.5,
        },
        alwaysOnTop: true,
      );
      final decoded = ResourceWindowArguments.parse(args.encode())!;
      expect(decoded.brightness, 'light');
      expect(decoded.locale, 'zh-TW');
      expect(decoded.fontKey, 'system:Arial');
      expect(decoded.rect, args.rect);
      expect(decoded.alwaysOnTop, true);
    },
  );

  test(
    'unknown or invalid launches never fall back to main data preparation',
    () async {
      for (final arguments in [
        'not json',
        '[]',
        '{"type":"other","version":1}',
        '{"type":"resource","version":2}',
        '{"type":"resource","version":1,"kind":"unknown"}',
      ]) {
        await expectLater(
          dispatchResourceWindow(
            arguments: arguments,
            startMain: () async => fail('Unexpected primary startup'),
            startResource: (_) async => fail('Unexpected child startup'),
          ),
          throwsFormatException,
        );
      }
    },
  );
}

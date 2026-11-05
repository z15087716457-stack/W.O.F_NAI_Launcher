import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/proxy_settings_provider.dart';

void main() {
  test(
    'the settings proxy shares in-flight reads and rereads after leaving',
    () async {
      final pending = <Completer<String?>>[];
      final container = ProviderContainer(
        overrides: [
          systemProxyReaderProvider.overrideWithValue(() {
            final read = Completer<String?>();
            pending.add(read);
            return read.future;
          }),
        ],
      );
      addTearDown(container.dispose);

      var watcher = container.listen(detectedSystemProxyProvider, (_, _) {});
      final first = container.read(detectedSystemProxyProvider.future);
      expect(container.read(detectedSystemProxyProvider.future), same(first));
      watcher.close();
      await container.pump();

      watcher = container.listen(detectedSystemProxyProvider, (_, _) {});
      expect(container.read(detectedSystemProxyProvider.future), same(first));
      expect(pending, hasLength(1));
      pending[0].complete('127.0.0.1:1080');
      expect(await first, '127.0.0.1:1080');
      watcher.close();
      await container.pump();

      watcher = container.listen(detectedSystemProxyProvider, (_, _) {});
      expect(pending, hasLength(2));
      final second = container.read(detectedSystemProxyProvider.future);
      pending[1].complete(null);
      expect(await second, isNull);
      watcher.close();
    },
  );
}

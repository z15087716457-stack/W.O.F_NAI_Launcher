import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_model_download.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/presentation/providers/rag_model_download_provider.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';

class MemoryRagSettings extends RagSettingsController {
  @override
  RagSettings build() =>
      const RagSettings(embedding: 'old-embedding', reranker: 'old-reranker');
  @override
  Future<void> update(RagSettings next) async {
    state = next;
  }
}

class FixtureDownload extends RagModelDownloader {
  FixtureDownload(super.root);
  final result = Completer<String>();
  int starts = 0;
  @override
  Future<String> install(
    String kind,
    void Function(RagModelDownloadProgress) progress,
  ) {
    starts++;
    progress(const RagModelDownloadProgress(5, 10));
    return result.future;
  }

  @override
  void cancel() {
    if (!result.isCompleted) {
      result.completeError(const RagException('cancelled'));
    }
  }
}

void main() {
  late Directory directory;
  late ProviderContainer container;
  late FixtureDownload download;
  late Future<Directory> Function() resolve;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rag-download-state-');
    download = FixtureDownload(directory);
    resolve = () async => directory;
    container = ProviderContainer(
      overrides: [
        ragSettingsProvider.overrideWith(MemoryRagSettings.new),
        ragDirectoryProvider.overrideWithValue(() => resolve()),
        ragModelDownloaderFactoryProvider.overrideWithValue((_) => download),
      ],
    );
  });
  tearDown(() async {
    if (!download.result.isCompleted) download.result.complete('unused');
    download.dispose();
    container.dispose();
    await directory.delete(recursive: true);
  });
  test(
    'completion updates only its model path and preserves newer settings',
    () async {
      final controller = container.read(ragModelDownloadProvider.notifier);
      final future = controller.download('embedding');
      await Future<void>.delayed(Duration.zero);
      expect(container.read(ragModelDownloadProvider).progress!.received, 5);
      final settings = container.read(ragSettingsProvider);
      await container
          .read(ragSettingsProvider.notifier)
          .update(
            settings.copyWith(mode: RagContextMode.before, wikiEnabled: true),
          );
      download.result.complete('verified-embedding');
      await future;
      final finalSettings = container.read(ragSettingsProvider);
      expect(finalSettings.embedding, 'verified-embedding');
      expect(finalSettings.reranker, 'old-reranker');
      expect(finalSettings.mode, RagContextMode.before);
      expect(finalSettings.wikiEnabled, isTrue);
      expect(container.read(ragModelDownloadProvider).active, isFalse);
    },
  );
  test(
    'duplicate clicks share one download; cancellation leaves settings intact',
    () async {
      final controller = container.read(ragModelDownloadProvider.notifier);
      final future = controller.download('embedding');
      await Future<void>.delayed(Duration.zero);
      await controller.download('reranker');
      expect(download.starts, 1);
      controller.cancel();
      await future;
      expect(container.read(ragSettingsProvider).embedding, 'old-embedding');
      expect(container.read(ragModelDownloadProvider).error, isNull);
    },
  );
  test(
    'cancel before root resolution prevents the download from starting',
    () async {
      final pending = Completer<Directory>();
      resolve = () => pending.future;
      final controller = container.read(ragModelDownloadProvider.notifier);
      final future = controller.download('embedding');
      controller.cancel();
      pending.complete(directory);
      await future;
      expect(download.starts, 0);
      expect(container.read(ragModelDownloadProvider).active, isFalse);
      // The fixture downloader was never published to the controller.
      download.result.complete('unused');
      download.dispose();
    },
  );
  test('a newer selection of the same model is never overwritten', () async {
    final controller = container.read(ragModelDownloadProvider.notifier);
    final future = controller.download('embedding');
    await Future<void>.delayed(Duration.zero);
    await container
        .read(ragSettingsProvider.notifier)
        .update(
          container
              .read(ragSettingsProvider)
              .copyWith(embedding: 'user-new-choice'),
        );
    download.result.complete('verified-embedding');
    await future;
    expect(container.read(ragSettingsProvider).embedding, 'user-new-choice');
  });
  test('a path resolution failure clears runtime installation state', () async {
    resolve = () async => throw const RagException('path_unavailable');
    final controller = container.read(ragControllerProvider.notifier);
    await controller.installRuntime(cuda: false);
    expect(container.read(ragControllerProvider).installPhase, isNull);
    expect(container.read(ragControllerProvider).error, isNotNull);
  });
  test(
    'runtime cancellation while resolving paths prevents installation',
    () async {
      final pending = Completer<Directory>();
      resolve = () => pending.future;
      final controller = container.read(ragControllerProvider.notifier);
      final future = controller.installRuntime(cuda: false);
      controller.cancelInstall();
      pending.complete(directory);
      await future;
      expect(container.read(ragControllerProvider).installPhase, isNull);
      expect(container.read(ragControllerProvider).error, isNull);
      expect(await File('${directory.path}/uv-0.13.1.exe').exists(), isFalse);
    },
  );
}

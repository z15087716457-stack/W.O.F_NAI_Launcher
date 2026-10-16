import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../core/rag/rag_client.dart';
import '../../core/rag/rag_model_download.dart';
import '../../core/rag/rag_maintenance.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/services/desktop_app_shutdown_service.dart';
import 'rag_provider.dart';

class RagModelDownloadState {
  const RagModelDownloadState({this.kind, this.progress, this.error});
  final String? kind, error;
  final RagModelDownloadProgress? progress;
  bool get active => kind != null;
}

final ragModelDownloaderFactoryProvider =
    Provider<RagModelDownloader Function(Directory)>(
      (ref) =>
          (root) => RagModelDownloader(root),
    );
final ragModelDownloadProvider =
    NotifierProvider<RagModelDownloads, RagModelDownloadState>(
      RagModelDownloads.new,
    );

class RagModelDownloads extends Notifier<RagModelDownloadState> {
  RagModelDownloader? _job;
  bool _disposed = false;
  bool _cancelRequested = false;
  @override
  RagModelDownloadState build() {
    final unregister = DesktopAppShutdownService.registerCleanup(
      () async => _job?.cancel(),
    );
    ref.onDispose(() {
      _disposed = true;
      unregister();
      _job?.dispose();
    });
    return const RagModelDownloadState();
  }

  Future<void> download(String kind) async {
    if (state.active) return;
    if (!const ['embedding', 'reranker'].contains(kind)) {
      throw const RagException('invalid_model');
    }
    final status = ref.read(ragControllerProvider);
    final release = ref
        .read(ragMaintenanceProvider)
        .claim(indexBusy: status.anyBusy || status.installPhase != null);
    final selected = ref.read(ragSettingsProvider);
    final previousPath = kind == 'embedding'
        ? selected.embedding
        : selected.reranker;
    _cancelRequested = false;
    state = RagModelDownloadState(kind: kind);
    try {
      final root = await ref.read(ragDirectoryProvider)();
      if (_disposed) return;
      if (_cancelRequested) {
        state = const RagModelDownloadState();
        return;
      }
      final job = _job = ref.read(ragModelDownloaderFactoryProvider)(root);
      final path = await job.install(kind, (progress) {
        if (!_disposed) {
          state = RagModelDownloadState(kind: kind, progress: progress);
        }
      });
      if (!_disposed) {
        final latest = ref.read(ragSettingsProvider);
        final currentPath = kind == 'embedding'
            ? latest.embedding
            : latest.reranker;
        if (currentPath == previousPath) {
          await ref
              .read(ragSettingsProvider.notifier)
              .update(
                kind == 'embedding'
                    ? latest.copyWith(embedding: path)
                    : latest.copyWith(reranker: path),
              );
        }
        state = const RagModelDownloadState();
      }
    } catch (error) {
      if (!_disposed) {
        state = RagModelDownloadState(
          error:
              error is RagException && error.code == 'cancelled' ||
                  error is DioException && error.type == DioExceptionType.cancel
              ? null
              : error is RagException
              ? error.code
              : 'model_download_failed',
        );
      }
    } finally {
      _job?.dispose();
      _job = null;
      release();
      if (!_disposed && ref.read(ragSettingsProvider).enabled) {
        unawaited(ref.read(ragControllerProvider.notifier).refresh());
      }
    }
  }

  void cancel() {
    _cancelRequested = true;
    _job?.cancel();
  }
}

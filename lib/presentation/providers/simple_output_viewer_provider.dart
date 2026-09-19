import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/storage/local_storage_service.dart';

part 'simple_output_viewer_provider.g.dart';

/// 输出查看器模式开关。
///
/// false = NAI5 自由画布（G11，默认）；true = 简单经典视图（回退档）。
/// 官网同款设置键 `simpleOutputViewer`。
@Riverpod(keepAlive: true)
class SimpleOutputViewerNotifier extends _$SimpleOutputViewerNotifier {
  @override
  bool build() {
    final storage = ref.read(localStorageServiceProvider);
    return storage.getSimpleOutputViewer();
  }

  Future<void> setSimple(bool simple) async {
    state = simple;
    await ref
        .read(localStorageServiceProvider)
        .setSimpleOutputViewer(simple);
  }
}

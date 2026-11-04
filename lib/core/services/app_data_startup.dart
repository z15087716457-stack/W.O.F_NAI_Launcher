import 'dart:io';

/// Database/service startup must never continue with unprepared storage. Keep
/// the failure presentation independent of those databases and providers.
Future<void> startWithPreparedAppData({
  required Future<Object?> Function() prepare,
  required Future<void> Function() start,
  required Future<void> Function(Object error, StackTrace stackTrace) onFailure,
}) async {
  try {
    await prepare();
  } catch (error, stackTrace) {
    await onFailure(error, stackTrace);
    return;
  }
  await start();
}

/// 启动恢复页「打开目录」：目录还不在时打开它的上一级。Windows 用资源管理器，
/// macOS 在访达里打开。
Future<void> openStartupDataDirectory(
  String path, {
  Future<Object?> Function(String executable, List<String> arguments)? run,
  bool? macOS,
}) async {
  final directory = Directory(path);
  final target = await directory.exists()
      ? directory.path
      : directory.parent.path;
  await (run ?? Process.run)(
    (macOS ?? Platform.isMacOS) ? 'open' : 'explorer.exe',
    [target],
  );
}

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

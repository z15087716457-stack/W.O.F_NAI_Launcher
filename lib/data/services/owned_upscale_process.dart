import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/upscale/local_upscale_models.dart';

typedef OwnedUpscaleStarter =
    Future<Process> Function(
      String executable,
      List<String> arguments,
      Map<String, String> environment,
    );

class OwnedUpscaleProcessResult {
  const OwnedUpscaleProcessResult(this.exitCode, this.diagnostics);
  final int exitCode;
  final String diagnostics;
}

/// The bundled host owns a Windows job and waits for its descendants on cancel.
/// No process is terminated by name and no console window is created.
Future<OwnedUpscaleProcessResult> runOwnedUpscaleProcess({
  required String host,
  required String executable,
  required List<String> arguments,
  required LocalUpscaleCancellation cancellation,
  Map<String, String> environment = const {},
  Duration timeout = const Duration(minutes: 30),
  void Function(String)? onLine,
  OwnedUpscaleStarter? startProcess,
}) async {
  cancellation.check();
  final process =
      await (startProcess ??
          (exe, args, env) => Process.start(exe, args, environment: env))(
        host,
        ['--run', executable, ...arguments],
        environment,
      );
  var timedOut = false;
  var stopping = false;
  Timer? fallback;
  Future<void> stop() async {
    if (stopping) return;
    stopping = true;
    fallback = Timer(const Duration(seconds: 20), process.kill);
    try {
      process.stdin.writeln('cancel');
      await process.stdin.flush();
    } catch (_) {
      process.kill();
    }
  }

  final removeCancel = cancellation.listen(() => unawaited(stop()));
  final timer = Timer(timeout, () {
    timedOut = true;
    unawaited(stop());
  });
  var diagnostics = '';
  void line(String value) {
    diagnostics = '$diagnostics\n$value';
    if (diagnostics.length > 16384) {
      diagnostics =
          '${diagnostics.substring(0, 8192)}\n...\n${diagnostics.substring(diagnostics.length - 8187)}';
    }
    if (!cancellation.isCancelled) onLine?.call(value);
  }

  final stdout = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .listen(line)
      .asFuture<void>();
  final stderr = process.stderr
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .listen(line)
      .asFuture<void>();
  try {
    final exit = await process.exitCode;
    await Future.wait([stdout, stderr]);
    cancellation.check();
    if (timedOut) {
      throw const LocalUpscaleException(LocalUpscaleError.timeout);
    }
    return OwnedUpscaleProcessResult(exit, diagnostics);
  } finally {
    removeCancel();
    timer.cancel();
    fallback?.cancel();
    await process.stdin.close().catchError((_) {});
  }
}

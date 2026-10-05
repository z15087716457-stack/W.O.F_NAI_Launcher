import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/utils/pica_lanczos_resizer.dart';
import '../models/upscale/local_upscale_models.dart';
import 'local_upscale_model_manager.dart';

typedef UpscaleProcessStarter = Future<Process> Function(String, List<String>);

/// One short-lived native worker per job. No remote generation or ComfyUI.
class LocalUpscaleService {
  static const maxNativeOutputPixels = 64000000;
  LocalUpscaleService(
    this.models, {
    UpscaleProcessStarter? startProcess,
    this.timeout = const Duration(minutes: 10),
    bool? supportedPlatform,
  }) : _startProcess =
           startProcess ?? ((exe, args) => Process.start(exe, args)),
       _supportedPlatform = supportedPlatform ?? Platform.isWindows;

  final LocalUpscaleModelManager models;
  final UpscaleProcessStarter _startProcess;
  final bool _supportedPlatform;
  final Duration timeout;
  bool _running = false;
  bool get isRunning => _running;

  Future<LocalUpscaleResult> upscale(
    Uint8List source, {
    required String modelId,
    required double scale,
    required LocalUpscaleCancellation cancellation,
    void Function(LocalUpscaleProgress)? onProgress,
  }) async {
    if (!_supportedPlatform) {
      throw const LocalUpscaleException(LocalUpscaleError.unsupportedPlatform);
    }
    if (_running) throw const LocalUpscaleException(LocalUpscaleError.busy);
    if (!scale.isFinite || scale < 1 || scale > 4) {
      throw const LocalUpscaleException(LocalUpscaleError.sizeLimit);
    }
    cancellation.check();
    models.claimInference(modelId);
    _running = true;
    Directory? job;
    void progress(LocalUpscalePhase phase, [double? fraction]) {
      if (!cancellation.isCancelled) {
        onProgress?.call(LocalUpscaleProgress(phase, fraction));
      }
    }

    try {
      progress(LocalUpscalePhase.preparing);
      final (executable, modelPath, model) = await models.resolve(modelId);
      cancellation.check();
      // The pinned native engine builds model paths into a 256-character buffer.
      if (modelPath.length + model.engineName.length + 12 > 245) {
        throw const LocalUpscaleException(LocalUpscaleError.modelMissing);
      }
      final nativeScale = model.inferenceScale(scale);
      final frozen = Uint8List.fromList(source);
      final prepared = await _imageWorker({
        'source': frozen,
        'scale': scale,
        'nativeScale': nativeScale,
      }, cancellation);
      final width = prepared['width'] as int;
      final height = prepared['height'] as int;
      final targetWidth = (width * scale).round();
      final targetHeight = (height * scale).round();
      job = Directory(p.join(models.directory.path, 'jobs', const Uuid().v4()));
      await job.create(recursive: true);
      final input = File(p.join(job.path, 'input.png'));
      final output = File(p.join(job.path, 'output.png'));
      await input.writeAsBytes(prepared['bytes'] as Uint8List, flush: true);
      cancellation.check();
      progress(LocalUpscalePhase.inference);
      Process process;
      try {
        process = await _startProcess(executable, [
          '-i',
          input.path,
          '-o',
          output.path,
          '-m',
          modelPath,
          '-n',
          model.engineName,
          '-s',
          '$nativeScale',
          '-t',
          '128',
          '-j',
          '1:1:1',
        ]);
      } on ProcessException {
        throw const LocalUpscaleException(LocalUpscaleError.engineMissing);
      }
      var timedOut = false;
      var diagnostics = '';
      final stop = cancellation.listen(() => process.kill());
      final timer = Timer(timeout, () {
        timedOut = true;
        process.kill();
      });
      final stderrDone = process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen((line) {
            diagnostics = '$diagnostics\n$line';
            if (diagnostics.length > 8192) {
              diagnostics = diagnostics.substring(diagnostics.length - 8192);
            }
            final match = RegExp(
              r'^\s*([0-9]+(?:\.[0-9]+)?)%\s*$',
            ).firstMatch(line);
            if (match != null) {
              progress(
                LocalUpscalePhase.inference,
                (double.parse(match.group(1)!) / 100).clamp(0, 1),
              );
            }
          })
          .asFuture<void>();
      final stdoutDone = process.stdout.drain<void>();
      int exit;
      try {
        // Do not release the model/GPU lock before the child has really exited.
        exit = await process.exitCode;
        await Future.wait([stderrDone, stdoutDone]);
      } finally {
        timer.cancel();
        stop();
      }
      cancellation.check();
      if (timedOut) {
        throw const LocalUpscaleException(LocalUpscaleError.timeout);
      }
      if (exit != 0 || !await output.exists()) {
        final vulkanFailure = RegExp(
          r'vkCreate|no.*vulkan|invalid gpu|no.*gpu|vkEnumerate',
          caseSensitive: false,
        ).hasMatch(diagnostics);
        throw LocalUpscaleException(
          vulkanFailure
              ? LocalUpscaleError.noVulkan
              : LocalUpscaleError.processFailed,
        );
      }
      progress(LocalUpscalePhase.resizing);
      final result = await _imageWorker({
        'source': frozen,
        'output': await output.readAsBytes(),
        'width': width,
        'height': height,
        'nativeScale': nativeScale,
        'targetWidth': targetWidth,
        'targetHeight': targetHeight,
      }, cancellation);
      cancellation.check();
      progress(LocalUpscalePhase.complete, 1);
      return LocalUpscaleResult(
        result['bytes'] as Uint8List,
        targetWidth,
        targetHeight,
      );
    } on LocalUpscaleException {
      rethrow;
    } catch (_) {
      cancellation.check();
      throw const LocalUpscaleException(LocalUpscaleError.processFailed);
    } finally {
      try {
        if (job != null && await job.exists()) {
          if (!p.isWithin(
            await models.directory.resolveSymbolicLinks(),
            await job.resolveSymbolicLinks(),
          )) {
            throw const LocalUpscaleException(LocalUpscaleError.processFailed);
          }
          await job.delete(recursive: true);
        }
      } finally {
        _running = false;
        models.releaseInference();
      }
    }
  }
}

Future<Map<String, Object>> _imageWorker(
  Map<String, Object> input,
  LocalUpscaleCancellation cancellation,
) async {
  cancellation.check();
  final messages = ReceivePort();
  final errors = ReceivePort();
  final complete = Completer<Map<String, Object>>();
  final subscription = messages.listen((message) {
    if (complete.isCompleted) return;
    final result = message as Map;
    if (result['error'] != null) {
      complete.completeError(
        LocalUpscaleException(
          LocalUpscaleError.values.byName(result['error'] as String),
        ),
      );
    } else {
      complete.complete(result.cast<String, Object>());
    }
  });
  final errorSubscription = errors.listen((_) {
    if (!complete.isCompleted) {
      complete.completeError(
        const LocalUpscaleException(LocalUpscaleError.invalidImage),
      );
    }
  });
  Isolate? worker;
  final stop = cancellation.listen(() {
    worker?.kill(priority: Isolate.immediate);
    if (!complete.isCompleted) {
      complete.completeError(
        const LocalUpscaleException(LocalUpscaleError.cancelled),
      );
    }
  });
  // Attach an error handler immediately, including cancellation while spawning.
  final future = complete.future;
  unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace __) {}));
  try {
    worker = await Isolate.spawn(_imageWorkerEntry, (
      messages.sendPort,
      input,
    ), onError: errors.sendPort);
    if (cancellation.isCancelled) worker.kill(priority: Isolate.immediate);
    return await future;
  } finally {
    stop();
    worker?.kill(priority: Isolate.immediate);
    await subscription.cancel();
    await errorSubscription.cancel();
    messages.close();
    errors.close();
  }
}

void _imageWorkerEntry((SendPort, Map<String, Object>) args) {
  try {
    final input = args.$2;
    final bytes = input['source'] as Uint8List;
    if (bytes.length > 64 * 1024 * 1024) {
      throw const LocalUpscaleException(LocalUpscaleError.sizeLimit);
    }
    final decoder = img.findDecoderForData(bytes);
    final info = decoder?.startDecode(bytes);
    if (info == null) {
      throw const LocalUpscaleException(LocalUpscaleError.invalidImage);
    }
    final nativeScale = input['nativeScale'] as int;
    if (info.width <= 0 ||
        info.height <= 0 ||
        info.width * info.height * nativeScale * nativeScale >
            LocalUpscaleService.maxNativeOutputPixels) {
      throw const LocalUpscaleException(LocalUpscaleError.sizeLimit);
    }
    final original = decoder!.decodeFrame(0);
    if (original == null) {
      throw const LocalUpscaleException(LocalUpscaleError.invalidImage);
    }
    if (input['output'] == null) {
      args.$1.send({
        'width': original.width,
        'height': original.height,
        'bytes': Uint8List.fromList(img.encodePng(original)),
      });
      return;
    }
    final scaled = img.decodePng(input['output'] as Uint8List);
    if (scaled == null ||
        scaled.width != original.width * nativeScale ||
        scaled.height != original.height * nativeScale) {
      throw const LocalUpscaleException(LocalUpscaleError.processFailed);
    }
    final width = input['targetWidth'] as int;
    final height = input['targetHeight'] as int;
    var result = PicaLanczosResizer.resizeImage(
      scaled,
      width: width,
      height: height,
    );
    if (original.hasAlpha) {
      result = result.convert(numChannels: 4);
      final alpha = PicaLanczosResizer.resizeImage(
        original,
        width: width,
        height: height,
      );
      for (final pixel in result) {
        final a = alpha.getPixel(pixel.x, pixel.y).a;
        pixel.a = a;
        if (a == 0) pixel.setRgba(0, 0, 0, 0);
      }
    }
    args.$1.send({'bytes': Uint8List.fromList(img.encodePng(result))});
  } on LocalUpscaleException catch (error) {
    args.$1.send({'error': error.code.name});
  } catch (_) {
    args.$1.send({'error': LocalUpscaleError.invalidImage.name});
  }
}

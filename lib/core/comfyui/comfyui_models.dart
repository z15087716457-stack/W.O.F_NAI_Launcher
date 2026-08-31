import 'dart:typed_data';

/// ComfyUI 连接状态
enum ComfyUIConnectionStatus { disconnected, connecting, connected, error }

/// ComfyUI 任务状态
enum ComfyUITaskStatus {
  uploading,
  queued,
  running,
  completed,
  failed,
  cancelled,
}

/// ComfyUI 进度事件
class ComfyUIProgress {
  final String promptId;
  final ComfyUITaskStatus status;
  final int currentStep;
  final int totalSteps;
  final String? currentNodeId;
  final String? errorMessage;
  final Uint8List? previewImage;

  const ComfyUIProgress({
    required this.promptId,
    required this.status,
    this.currentStep = 0,
    this.totalSteps = 0,
    this.currentNodeId,
    this.errorMessage,
    this.previewImage,
  });

  double get progressFraction =>
      totalSteps > 0 ? currentStep / totalSteps : 0.0;

  ComfyUIProgress copyWith({
    String? promptId,
    ComfyUITaskStatus? status,
    int? currentStep,
    int? totalSteps,
    String? currentNodeId,
    String? errorMessage,
    Uint8List? previewImage,
    bool clearPreview = false,
  }) {
    return ComfyUIProgress(
      promptId: promptId ?? this.promptId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      currentNodeId: currentNodeId ?? this.currentNodeId,
      errorMessage: errorMessage ?? this.errorMessage,
      previewImage: clearPreview ? null : (previewImage ?? this.previewImage),
    );
  }
}

/// ComfyUI 提交结果
class ComfyUIPromptResult {
  final String promptId;
  final int? number;

  const ComfyUIPromptResult({required this.promptId, this.number});
}

/// ComfyUI 系统状态
class ComfyUISystemStats {
  final String? cudaDevice;
  final int? vramTotal;
  final int? vramFree;

  const ComfyUISystemStats({this.cudaDevice, this.vramTotal, this.vramFree});
}

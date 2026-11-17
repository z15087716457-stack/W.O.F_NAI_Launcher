import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/models/prompt_reading.dart';
import '../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../prompt_assistant/services/prompt_assistant_service.dart';
import 'locale_provider.dart';
import 'pill_workspace_provider.dart';
import 'prompt_translation_mode_provider.dart';
import 'prompt_translation_provider.dart';

final promptAutoTranslationFailuresProvider = StateProvider<Set<String>>(
  (ref) => {},
);

final promptAutoTranslationProvider = Provider<PromptAutoTranslation>((ref) {
  final controller = PromptAutoTranslation(ref);
  ref.listen(
    promptAutoTranslationEnabledProvider,
    (_, __) => controller.suspend(),
  );
  ref.listen(promptTranslationModeProvider, (_, __) => controller.suspend());
  ref.listen(promptAssistantConfigProvider, (_, __) => controller.suspend());
  ref.listen(localeNotifierProvider, (_, __) => controller.suspend());
  ref.listen(promptTranslationBusyProvider, (_, busy) {
    if (!busy) controller._pump();
  });
  ref.onDispose(controller.dispose);
  return controller;
});

typedef _PendingTranslation = ({
  Object editor,
  String scope,
  String text,
  bool Function() isActive,
});

/// One automatic batch at a time. Typing during a request retains only the
/// latest pending edit; provider rebuilds and annotation changes never enqueue.
class PromptAutoTranslation {
  PromptAutoTranslation(this._ref);
  final Ref _ref;
  Timer? _timer;
  _PendingTranslation? _pending, _running;
  var _epoch = 0;
  var _disposed = false;

  bool get _enabled =>
      _ref.read(promptAutoTranslationEnabledProvider) &&
      _ref.read(promptTranslationModeProvider) !=
          PromptTranslationMode.blocks &&
      _ref.read(promptAssistantConfigProvider).promptTranslationRoute != null;

  void edited({
    required Object editor,
    required String scope,
    required TextEditingValue value,
    required bool Function() isActive,
  }) {
    clearFailure(scope);
    _timer?.cancel();
    _timer = null;
    _pending = null;
    if (!_enabled || !isActive() || value.composing.isValid) {
      return;
    }
    _pending = (
      editor: editor,
      scope: scope,
      text: value.text,
      isActive: isActive,
    );
    _timer = Timer(const Duration(milliseconds: 800), () {
      _timer = null;
      _pump();
    });
  }

  bool _current(_PendingTranslation request) =>
      !_disposed &&
      _enabled &&
      request.isActive() &&
      _ref.read(pillWorkspaceProvider(request.scope)).document.text ==
          request.text &&
      _ref.read(pillWorkspaceProvider(request.scope)).document.readingsVisible;

  Future<void> _pump() async {
    if (_disposed ||
        _timer != null ||
        _running != null ||
        _ref.read(promptTranslationBusyProvider)) {
      return;
    }
    final request = _pending;
    _pending = null;
    if (request == null || !_current(request)) return;
    _running = request;
    final epoch = _epoch;
    bool current() => epoch == _epoch && _current(request);
    try {
      await _ref
          .read(promptTranslationCoordinatorProvider)
          .translateInlineScope(request.scope, canApply: current);
    } catch (_) {
      if (current()) {
        _ref.read(promptAutoTranslationFailuresProvider.notifier).state = {
          ..._ref.read(promptAutoTranslationFailuresProvider),
          request.scope,
        };
        AppLogger.w('Automatic prompt translation failed', 'PromptTranslation');
      }
    } finally {
      _running = null;
      if (!_disposed) _pump();
    }
  }

  void clearFailure(String scope) {
    final failures = _ref.read(promptAutoTranslationFailuresProvider);
    if (failures.contains(scope)) {
      _ref.read(promptAutoTranslationFailuresProvider.notifier).state = {
        ...failures,
      }..remove(scope);
    }
  }

  void _cancelRunning() {
    _epoch++;
    if (_running case final request?) {
      unawaited(
        _ref
            .read(promptAssistantServiceProvider)
            .cancelCurrentTask(sessionId: 'prompt-auto-${request.scope}'),
      );
    }
  }

  void suspend() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _cancelRunning();
  }

  void forget(Object editor) {
    if (identical(_pending?.editor, editor)) {
      _timer?.cancel();
      _timer = null;
      _pending = null;
    }
    if (identical(_running?.editor, editor)) _cancelRunning();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}

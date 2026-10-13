import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/utils/localization_extension.dart';

class AgentQuestion {
  AgentQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.allowCustom = true,
    this.allowEmpty = false,
    this.multiline = false,
    this.prefill = '',
    this.placeholder,
    this.preserveWhitespace = false,
  });
  final String id, text;
  final List<String> options;
  final bool allowCustom, allowEmpty, multiline, preserveWhitespace;
  final String prefill;
  final String? placeholder;
  bool accepts(String answer) =>
      (allowEmpty || answer.trim().isNotEmpty) &&
      (allowCustom || options.contains(answer));
}

class AgentQuestionRequest {
  AgentQuestionRequest({
    required this.id,
    required this.workspaceId,
    required this.chatId,
    required this.questions,
    this.kind,
  });
  final String id, workspaceId, chatId;
  final String? kind;
  final List<AgentQuestion> questions;
  final completion = Completer<Map<String, dynamic>>();
}

class NaiAgentQuestions extends ChangeNotifier {
  final _pending = <String, AgentQuestionRequest>{};
  bool _disposed = false;
  List<AgentQuestionRequest> forChat(String chatId) =>
      _pending.values.where((question) => question.chatId == chatId).toList();
  Future<Map<String, dynamic>> ask(
    String workspaceId,
    String chatId,
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation, {
    int maxOptions = 8,
    bool toolApproval = false,
  }) async {
    cancellation.check();
    final rows = params['questions'];
    if (rows is! List || rows.isEmpty || rows.length > 3) {
      throw const NaiAgentToolError(
        'invalid_question',
        'Ask one to three questions',
      );
    }
    final questions = <AgentQuestion>[], ids = <String>{};
    for (final row in rows) {
      if (row is! Map ||
          row['id'] is! String ||
          row['question'] is! String ||
          (row['question'] as String).trim().isEmpty ||
          !ids.add(row['id'] as String)) {
        throw const NaiAgentToolError(
          'invalid_question',
          'Question identity/text is invalid',
        );
      }
      final options = row['options'] as List? ?? [];
      if (options.length > maxOptions ||
          options.any((option) => option is! String)) {
        throw const NaiAgentToolError(
          'invalid_question',
          'Options must be short strings',
        );
      }
      questions.add(
        AgentQuestion(
          id: row['id'] as String,
          text: row['question'] as String,
          options: options.cast<String>(),
          allowCustom: row['allowCustom'] != false,
          allowEmpty: row['allowEmpty'] == true,
          multiline: row['multiline'] == true,
          prefill: row['prefill'] as String? ?? '',
          placeholder: row['placeholder'] as String?,
          preserveWhitespace: row['preserveWhitespace'] == true,
        ),
      );
    }
    if (_disposed) {
      throw const NaiAgentToolError('closed', 'Question owner closed');
    }
    final request = AgentQuestionRequest(
      id: const Uuid().v4(),
      workspaceId: workspaceId,
      chatId: chatId,
      questions: questions,
      kind: toolApproval ? 'tool_approval' : null,
    );
    _pending[request.id] = request;
    notifyListeners();
    unawaited(
      cancellation.whenCancelled.then((_) {
        _pending.remove(request.id);
        if (!request.completion.isCompleted) {
          request.completion.completeError(
            const NaiAgentToolError('cancelled', 'Question cancelled'),
          );
        }
        if (!_disposed) notifyListeners();
      }),
    );
    try {
      return naiAgentTextResult(await request.completion.future);
    } finally {
      _pending.remove(request.id);
      if (!_disposed) notifyListeners();
    }
  }

  void answer(String requestId, Map<String, String> answers) {
    final request = _pending[requestId];
    if (request == null || request.completion.isCompleted) return;
    if (request.questions.any(
      (q) => !answers.containsKey(q.id) || !q.accepts(answers[q.id]!),
    )) {
      return;
    }
    request.completion.complete({
      'status': 'answered',
      'answers': [
        for (final question in request.questions)
          {
            'id': question.id,
            'question': question.text,
            'answer': question.preserveWhitespace
                ? answers[question.id]!
                : answers[question.id]!.trim(),
          },
      ],
    });
  }

  Future<Map<String, dynamic>> askExtensionUi(
    String workspaceId,
    String chatId,
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    final method = params['method'], title = params['title'];
    if (!{'select', 'confirm', 'input', 'editor'}.contains(method) ||
        title is! String) {
      throw const NaiAgentToolError(
        'invalid_question',
        'Unsupported extension dialog',
      );
    }
    final confirm = method == 'confirm';
    final confirmLabel = currentL10n.common_confirm;
    final result = await ask(
      workspaceId,
      chatId,
      {
        'kind': params['kind'],
        'questions': [
          {
            'id': 'value',
            'question': confirm ? '$title\n${params['message'] ?? ''}' : title,
            'options': confirm
                ? [confirmLabel, currentL10n.common_cancel]
                : method == 'select'
                ? params['options']
                : <String>[],
            'allowCustom': method == 'input' || method == 'editor',
            'allowEmpty': method == 'input' || method == 'editor',
            'multiline': method == 'editor',
            'prefill': params['prefill'],
            'placeholder': params['placeholder'],
            'preserveWhitespace': true,
          },
        ],
      },
      cancellation,
      maxOptions: 128,
      toolApproval: params['kind'] == 'tool_approval',
    );
    final value =
        jsonDecode((result['content'] as List).first['text'] as String) as Map;
    if (value['status'] != 'answered') {
      return naiAgentTextResult({'status': 'cancelled'});
    }
    final answer = (value['answers'] as List).first['answer'];
    return naiAgentTextResult({
      'status': 'answered',
      'value': confirm ? answer == confirmLabel : answer,
    });
  }

  void cancel(String requestId) {
    final request = _pending[requestId];
    if (request == null || request.completion.isCompleted) return;
    request.completion.complete({'status': 'cancelled', 'answers': []});
  }

  @override
  void dispose() {
    _disposed = true;
    for (final request in _pending.values) {
      if (!request.completion.isCompleted) {
        request.completion.completeError(
          const NaiAgentToolError('closed', 'Question owner closed'),
        );
      }
    }
    _pending.clear();
    super.dispose();
  }
}

final naiAgentQuestionsProvider = ChangeNotifierProvider<NaiAgentQuestions>(
  (ref) => NaiAgentQuestions(),
);

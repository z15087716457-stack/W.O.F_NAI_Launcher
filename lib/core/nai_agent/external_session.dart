/// External operations are saved separately from official Pi conversations.
/// The message-shaped projection below is only an input to the shared UI mapper.
class ExternalAgentSession {
  ExternalAgentSession({this.summary = '', List<ExternalAgentCall>? calls})
    : calls = calls ?? [];

  factory ExternalAgentSession.fromJson(Map<String, dynamic> value) =>
      ExternalAgentSession(
        summary: value['summary'] as String? ?? '',
        calls: [
          for (final row in value['calls'] as List? ?? const [])
            ExternalAgentCall.fromJson(Map<String, dynamic>.from(row as Map)),
        ],
      );

  String summary;
  final List<ExternalAgentCall> calls;
  final Set<String> connections = {};
  bool get connected => connections.isNotEmpty;
  bool revealed = false;
  bool unread = false;
  int unreadAt = 0;
  ExternalAgentNotice? notice;

  Map<String, dynamic> toJson() => {
    'schema': 1,
    'summary': summary,
    'calls': [for (final call in calls) call.toJson()],
  };

  List<Map<String, dynamic>> displayMessages(DateTime createdAt) => [
    if (summary.isNotEmpty)
      {
        'role': 'user',
        'timestamp': createdAt.millisecondsSinceEpoch,
        'content': [
          {'type': 'text', 'text': summary},
        ],
      },
    if (calls.isNotEmpty)
      {
        'role': 'assistant',
        'timestamp': calls.first.startedAt,
        'content': [
          for (final call in calls)
            {
              'type': 'toolCall',
              'id': call.id,
              'name': call.name,
              'arguments': call.arguments,
            },
        ],
      },
    for (final call in calls)
      if (call.result != null)
        {
          ...call.result!,
          'role': 'toolResult',
          'toolCallId': call.id,
          'timestamp': call.finishedAt ?? call.startedAt,
        },
  ];

  Map<String, Map<String, dynamic>> get displayTools => {
    for (final call in calls)
      call.id: {
        'toolCallId': call.id,
        'toolName': call.name,
        'args': call.arguments,
        'startedAt': call.startedAt,
        if (call.finishedAt != null)
          'durationMs': call.finishedAt! - call.startedAt,
        if (call.result != null) 'result': call.result,
        'isError': call.result?['isError'] == true,
      },
  };
}

/// Transient UI event; restored histories never replay a toast.
class ExternalAgentNotice {
  const ExternalAgentNotice({
    required this.id,
    required this.at,
    required this.isError,
    this.title,
  });
  final String id;
  final DateTime at;
  final bool isError;
  final String? title;
}

class ExternalAgentCall {
  ExternalAgentCall({
    required this.id,
    required this.name,
    required this.arguments,
    required this.startedAt,
  });

  factory ExternalAgentCall.fromJson(Map<String, dynamic> value) {
    final call = ExternalAgentCall(
      id: value['id'] as String,
      name: value['name'] as String,
      arguments: Map<String, dynamic>.from(value['arguments'] as Map),
      startedAt: value['startedAt'] as int,
    );
    call.finishedAt = value['finishedAt'] as int?;
    call.result = value['result'] == null
        ? null
        : Map<String, dynamic>.from(value['result'] as Map);
    // Restoring the operation log never replays an interrupted tool call.
    if (call.result == null) {
      call.finishedAt = call.startedAt;
      call.result = {
        'isError': true,
        'details': {
          'ok': false,
          'error': 'interrupted',
          'message': 'External operation was interrupted',
        },
      };
    }
    return call;
  }
  final String id, name;
  final Map<String, dynamic> arguments;
  final int startedAt;
  int? finishedAt;
  Map<String, dynamic>? result;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'arguments': arguments,
    'startedAt': startedAt,
    'finishedAt': finishedAt,
    'result': result,
  };
}

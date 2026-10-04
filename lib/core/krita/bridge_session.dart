import 'krita_bridge_models.dart';

enum BridgeClientKind { krita, agent }

class BridgeClient {
  const BridgeClient({
    required this.id,
    required this.kind,
    required this.name,
  });
  final String id;
  final BridgeClientKind kind;

  /// A label declared by an authenticated local client, not a verified vendor.
  final String name;
  bool get isAgent => kind == BridgeClientKind.agent;
}

class BridgeRequest {
  const BridgeRequest({required this.client, required this.message});
  final BridgeClient client;
  final KritaBridgeMessage message;
  String get key => '${client.id}:${message.type}:${message.id}';
}

enum BridgeActivityStatus { running, completed, failed, disconnected }

class BridgeActivity {
  const BridgeActivity({
    required this.key,
    required this.client,
    required this.operation,
    required this.at,
    this.status = BridgeActivityStatus.running,
    this.errorCode,
    this.confirmedDraftVersion,
    this.finishedAt,
  });
  final String key;
  final BridgeClient client;
  final String operation;
  final DateTime at;
  final BridgeActivityStatus status;
  final String? errorCode;
  final String? confirmedDraftVersion;
  final DateTime? finishedAt;

  BridgeActivity confirm(String version) => BridgeActivity(
    key: key,
    client: client,
    operation: operation,
    at: at,
    status: status,
    errorCode: errorCode,
    confirmedDraftVersion: version,
    finishedAt: finishedAt,
  );

  BridgeActivity finish(
    BridgeActivityStatus status, {
    String? errorCode,
    DateTime? finishedAt,
  }) => BridgeActivity(
    key: key,
    client: client,
    operation: operation,
    at: at,
    status: status,
    errorCode: errorCode ?? this.errorCode,
    confirmedDraftVersion: confirmedDraftVersion,
    finishedAt: finishedAt,
  );
}

class BridgeSession {
  const BridgeSession({
    this.clients = const [],
    this.activities = const [],
    this.latestAgentOutcome,
  });
  final List<BridgeClient> clients;
  final List<BridgeActivity> activities;

  /// Completion order can differ from request order when reads overlap a task.
  final BridgeActivity? latestAgentOutcome;

  List<BridgeClient> get agents => clients.where((c) => c.isAgent).toList();
  BridgeActivity? get agentActivity {
    for (final a in activities) {
      if (a.client.isAgent && a.status == BridgeActivityStatus.running) {
        return a;
      }
    }
    return null;
  }

  BridgeActivity? get latestAgentActivity {
    for (final a in activities) {
      if (a.client.isAgent) return a;
    }
    return null;
  }
}

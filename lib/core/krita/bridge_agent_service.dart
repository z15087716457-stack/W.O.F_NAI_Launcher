import 'bridge_session.dart';

abstract class BridgeAgentService {
  Future<void> handle(BridgeRequest request);
  void disconnected(BridgeClient client);
  void close();
}

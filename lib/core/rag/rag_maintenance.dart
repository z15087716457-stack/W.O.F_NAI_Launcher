import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rag_client.dart';

final ragMaintenanceProvider = Provider((ref) => RagMaintenance());

/// Synchronous admission before the first await, shared by all RAG writers.
/// Active indexing is additionally checked from the controller's live status.
class RagMaintenance {
  Object? _owner;
  bool get busy => _owner != null;

  void Function() claim({bool indexBusy = false}) {
    if (busy || indexBusy) throw const RagException('index_busy');
    final owner = _owner = Object();
    return () {
      if (identical(_owner, owner)) _owner = null;
    };
  }
}

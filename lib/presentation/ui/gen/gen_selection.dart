import 'package:flutter/foundation.dart';

import 'gen_contract.dart';

/// Shared bulk selection for the history panel and both output viewers.
/// Viewing focus stays with the existing canvas; operations use real image IDs.
class GenImageSelection extends ChangeNotifier {
  bool active = false;
  int revision = 0;
  final _ids = <String>{};
  final _pendingBatches = <String>{};
  List<String> _anchor = const [];
  List<String> _order = const [];
  List<GenBatch> _batches = const [];

  bool contains(String id) => _ids.contains(id);
  List<String> get images {
    final ordered = _order.toSet();
    return [
      ..._order.where(_ids.contains),
      // Retained canvas/pin images can be viewed after history is cleared.
      ..._ids.where((id) => !ordered.contains(id)),
    ];
  }

  bool checked(GenBatch batch) =>
      _pendingBatches.contains(batch.id) ||
      batch.images.isNotEmpty && batch.images.every((i) => contains(i.id));

  bool partial(GenBatch batch) =>
      !checked(batch) && batch.images.any((i) => contains(i.id));

  void sync(List<GenBatch> batches) {
    if (identical(_batches, batches)) return;
    final before = Set.of(_ids);
    final pendingBefore = Set.of(_pendingBatches);
    _batches = batches;
    final order = [for (final b in batches) ...b.images.map((i) => i.id)];
    _ids.removeAll(_order.toSet().difference(order.toSet()));
    _order = order;
    // An explicitly selected generating batch includes its later results.
    for (final batch in batches) {
      if (_pendingBatches.contains(batch.id)) {
        _ids.addAll(batch.images.map((i) => i.id));
      }
    }
    _pendingBatches.retainAll([
      for (final batch in batches)
        if (batch.pending > 0) batch.id,
    ]);
    if (!setEquals(before, _ids) ||
        !setEquals(pendingBefore, _pendingBatches)) {
      if (_ids.isEmpty && _pendingBatches.isEmpty) active = false;
      _changed();
    }
  }

  void setActive(bool value) {
    active = value;
    if (!value) {
      _ids.clear();
      _pendingBatches.clear();
      _anchor = const [];
    }
    _changed();
  }

  /// False means this is an ordinary viewing click, handled by the caller.
  bool tap(
    List<String> ids, {
    bool modify = false,
    bool range = false,
    String? pendingBatch,
  }) {
    if (!active && !modify && !range) {
      _anchor = ids;
      return false;
    }
    if (ids.isEmpty && pendingBatch == null) return false;
    active = true;
    if (range && _anchor.isNotEmpty) {
      final endpoints = [
        for (final id in [..._anchor, ...ids])
          if (_order.indexOf(id) case final index when index >= 0) index,
      ]..sort();
      if (endpoints.isNotEmpty) {
        _ids.addAll(_order.sublist(endpoints.first, endpoints.last + 1));
      }
      for (final batch in _batches) {
        if (batch.pending > 0 &&
            batch.images.isNotEmpty &&
            batch.images.every((i) => contains(i.id))) {
          _pendingBatches.add(batch.id);
        }
      }
      if (pendingBatch != null) _pendingBatches.add(pendingBatch);
    } else {
      final selected = ids.isEmpty
          ? _pendingBatches.contains(pendingBatch)
          : ids.every(contains);
      selected ? _ids.removeAll(ids) : _ids.addAll(ids);
      // Editing a child ends whole-batch following for that batch.
      _pendingBatches.removeWhere(
        (key) => _batches.any(
          (batch) =>
              batch.id == key && batch.images.any((i) => ids.contains(i.id)),
        ),
      );
      if (pendingBatch != null) {
        selected
            ? _pendingBatches.remove(pendingBatch)
            : _pendingBatches.add(pendingBatch);
      }
      _anchor = ids;
    }
    if (_ids.isEmpty && _pendingBatches.isEmpty) active = false;
    _changed();
    return true;
  }

  void _changed() {
    revision++;
    notifyListeners();
  }
}

List<String>? extractChoiceListFromCandidateFields(
  Map<String, dynamic> fields,
  Iterable<String> candidateKeys,
) {
  for (final key in candidateKeys) {
    final choices = extractChoiceListFromObjectInfoField(fields[key]);
    if (choices != null && choices.isNotEmpty) {
      return choices;
    }
  }
  return null;
}

List<String>? extractChoiceListFromObjectInfoField(dynamic field) {
  if (field == null) return null;

  if (field is List) {
    if (field.isEmpty) return null;

    final first = field.first;
    if (first is List) {
      final nested = first
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      return nested.isEmpty ? null : nested;
    }

    if (first == 'COMBO') {
      for (final entry in field.skip(1)) {
        final choices = extractChoiceListFromObjectInfoField(entry);
        if (choices != null && choices.isNotEmpty) {
          return choices;
        }
      }
      return null;
    }

    final directChoices = field
        .whereType<String>()
        .where((s) => s.isNotEmpty && s != 'COMBO')
        .toList();
    if (directChoices.isNotEmpty) {
      return directChoices;
    }

    for (final entry in field) {
      if (entry is String) continue;
      final choices = extractChoiceListFromObjectInfoField(entry);
      if (choices != null && choices.isNotEmpty) {
        return choices;
      }
    }
    return null;
  }

  if (field is Map) {
    for (final key in const ['choices', 'options', 'values', 'items']) {
      final value = field[key];
      if (value is List) {
        final choices = value
            .whereType<String>()
            .where((s) => s.isNotEmpty && s != 'COMBO')
            .toList();
        if (choices.isNotEmpty) {
          return choices;
        }
      }
    }
  }

  return null;
}

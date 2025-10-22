enum IncidentCategory {
  fire,
  localHazard,
  falseAlarm,
}

class IncidentEntry {
  const IncidentEntry({
    required this.id,
    required this.category,
    this.timestamp,
    this.note,
  });

  final String id;
  final IncidentCategory category;
  final DateTime? timestamp;
  final String? note;

  IncidentEntry copyWith({
    String? id,
    IncidentCategory? category,
    Object? timestamp = _undefined,
    Object? note = _undefined,
  }) {
    return IncidentEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      timestamp:
          timestamp == _undefined ? this.timestamp : timestamp as DateTime?,
      note: note == _undefined ? this.note : note as String?,
    );
  }
}

const Object _undefined = Object();

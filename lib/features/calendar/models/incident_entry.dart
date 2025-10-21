enum IncidentCategory {
  fire,
  localHazard,
  falseAlarm,
}

class IncidentEntry {
  const IncidentEntry({
    required this.id,
    required this.category,
    required this.timestamp,
    this.note,
  });

  final String id;
  final IncidentCategory category;
  final DateTime timestamp;
  final String? note;

  IncidentEntry copyWith({
    String? id,
    IncidentCategory? category,
    DateTime? timestamp,
    Object? note = _undefined,
  }) {
    return IncidentEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      note: note == _undefined ? this.note : note as String?,
    );
  }
}

const Object _undefined = Object();

class ReportPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String rank; // stopień
  final String position; // stanowisko
  final String unit; // komórka organizacyjna (opcjonalne)

  ReportPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.rank,
    required this.position,
    this.unit = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'rank': rank,
      'position': position,
      'unit': unit,
    };
  }

  factory ReportPerson.fromMap(Map<String, dynamic> map, String documentId) {
    return ReportPerson(
      id: documentId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      rank: map['rank'] ?? '',
      position: map['position'] ?? '',
      unit: map['unit'] ?? '',
    );
  }
  
  String get fullName => '$rank $firstName $lastName';
  
  ReportPerson copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? rank,
    String? position,
    String? unit,
  }) {
    return ReportPerson(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      rank: rank ?? this.rank,
      position: position ?? this.position,
      unit: unit ?? this.unit,
    );
  }
}

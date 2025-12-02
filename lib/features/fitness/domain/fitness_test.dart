import 'package:uuid/uuid.dart';

class FitnessTest {
  final String id;
  final DateTime testDate;
  final String firefighterName;
  final int firefighterAge;
  final String gender; // 'M' or 'F'
  
  // Results
  final int? pullUps; // Number of pull-ups (Men)
  final double? ballThrowDistance; // Distance in meters (Women)
  final double coneRunTime; // Time in seconds
  final int beepTestLevel; // Beep test level
  final int beepTestShuttles; // Beep test shuttles
  
  // Calculated
  final int pullUpScore;
  final int coneRunScore;
  final int beepTestScore;
  final double averageScore;
  final int preferentialPoints;
  final double finalScore;
  final int grade;
  final String gradeLabel;

  FitnessTest({
    required this.id,
    required this.testDate,
    required this.firefighterName,
    required this.firefighterAge,
    required this.gender,
    this.pullUps,
    this.ballThrowDistance,
    required this.coneRunTime,
    required this.beepTestLevel,
    required this.beepTestShuttles,
    required this.pullUpScore,
    required this.coneRunScore,
    required this.beepTestScore,
    required this.averageScore,
    required this.preferentialPoints,
    required this.finalScore,
    required this.grade,
    required this.gradeLabel,
  });

  factory FitnessTest.create({
    required String firefighterName,
    required int firefighterAge,
    required String gender,
    required DateTime testDate,
    int? pullUps,
    double? ballThrowDistance,
    required double coneRunTime,
    required int beepTestLevel,
    required int beepTestShuttles,
  }) {
    // Calculate scores
    final pullUpScore = _calculatePullUpScore(pullUps, ballThrowDistance, gender);
    final coneRunScore = _calculateConeRunScore(coneRunTime);
    final beepTestScore = _calculateBeepTestScore(beepTestLevel, beepTestShuttles);
    
    // Calculate average
    final averageScore = (pullUpScore + coneRunScore + beepTestScore) / 3.0;
    
    // Calculate preferential points
    final preferentialPoints = _calculatePreferentialPoints(firefighterAge);
    
    // Final score
    final finalScore = averageScore + preferentialPoints;
    
    // Grade
    final (grade, gradeLabel) = _calculateGrade(finalScore);

    return FitnessTest(
      id: const Uuid().v4(),
      testDate: testDate,
      firefighterName: firefighterName,
      firefighterAge: firefighterAge,
      gender: gender,
      pullUps: pullUps,
      ballThrowDistance: ballThrowDistance,
      coneRunTime: coneRunTime,
      beepTestLevel: beepTestLevel,
      beepTestShuttles: beepTestShuttles,
      pullUpScore: pullUpScore,
      coneRunScore: coneRunScore,
      beepTestScore: beepTestScore,
      averageScore: averageScore,
      preferentialPoints: preferentialPoints,
      finalScore: finalScore,
      grade: grade,
      gradeLabel: gradeLabel,
    );
  }

  static int _calculatePullUpScore(int? pullUps, double? distance, String gender) {
    if (gender == 'M') {
      if (pullUps == null) return 0;
      if (pullUps >= 26) return 75;
      if (pullUps >= 25) return 74;
      if (pullUps >= 24) return 73;
      if (pullUps >= 23) return 72;
      if (pullUps >= 22) return 71;
      if (pullUps >= 21) return 70;
      if (pullUps >= 20) return 69;
      if (pullUps >= 19) return 68;
      if (pullUps >= 18) return 67;
      if (pullUps >= 17) return 66;
      if (pullUps >= 16) return 65;
      if (pullUps >= 15) return 63;
      if (pullUps >= 14) return 61;
      if (pullUps >= 13) return 58;
      if (pullUps >= 12) return 55;
      if (pullUps >= 11) return 50;
      if (pullUps >= 10) return 45;
      if (pullUps >= 9) return 40;
      if (pullUps >= 8) return 35;
      if (pullUps >= 7) return 30;
      if (pullUps >= 6) return 25;
      if (pullUps >= 5) return 20;
      if (pullUps >= 4) return 15;
      if (pullUps >= 3) return 10;
      if (pullUps >= 2) return 5;
      return 0;
    } else {
      if (distance == null) return 0;
      if (distance >= 10.00) return 75;
      if (distance >= 9.50) return 70;
      if (distance >= 9.40) return 69;
      if (distance >= 9.30) return 68;
      if (distance >= 9.20) return 67;
      if (distance >= 9.10) return 66;
      if (distance >= 9.00) return 65;
      if (distance >= 8.90) return 64;
      if (distance >= 8.80) return 63;
      if (distance >= 8.70) return 62;
      if (distance >= 8.60) return 61;
      if (distance >= 8.50) return 60;
      if (distance >= 8.40) return 59;
      if (distance >= 8.30) return 58;
      if (distance >= 8.20) return 57;
      if (distance >= 8.10) return 56;
      if (distance >= 8.00) return 55;
      if (distance >= 7.90) return 53;
      if (distance >= 7.80) return 51;
      if (distance >= 7.50) return 45;
      if (distance >= 7.40) return 43;
      if (distance >= 7.30) return 41;
      if (distance >= 7.20) return 39;
      if (distance >= 7.10) return 37;
      if (distance >= 7.00) return 35;
      if (distance >= 6.90) return 33;
      if (distance >= 6.80) return 31;
      if (distance >= 6.70) return 29;
      if (distance >= 6.60) return 25;
      if (distance >= 6.40) return 20;
      if (distance >= 6.20) return 19;
      if (distance >= 6.10) return 17;
      if (distance >= 6.00) return 15;
      if (distance >= 5.90) return 13;
      if (distance >= 5.80) return 11;
      if (distance >= 5.70) return 9;
      if (distance >= 5.60) return 7;
      if (distance >= 5.40) return 5; // Table says 5.40 is 5 pkt, also 5.20 is 3 pkt.
      if (distance >= 5.20) return 3;
      return 0;
    }
  }

  static int _calculateConeRunScore(double time) {
    if (time <= 22.00) return 75;
    if (time <= 22.25) return 70;
    if (time <= 22.30) return 69;
    if (time <= 22.35) return 68;
    if (time <= 22.40) return 67;
    if (time <= 22.45) return 66;
    if (time <= 22.50) return 65;
    if (time <= 22.55) return 64;
    if (time <= 22.60) return 63;
    if (time <= 22.65) return 62;
    if (time <= 22.70) return 61;
    if (time <= 22.75) return 60;
    if (time <= 22.80) return 59;
    if (time <= 22.85) return 58;
    if (time <= 22.90) return 57;
    if (time <= 22.95) return 56;
    if (time <= 23.00) return 55;
    if (time <= 23.05) return 54;
    if (time <= 23.10) return 53;
    if (time <= 23.15) return 52;
    if (time <= 23.20) return 51;
    if (time <= 23.25) return 50;
    if (time <= 23.30) return 49;
    if (time <= 23.35) return 48;
    if (time <= 23.40) return 47;
    if (time <= 23.45) return 46;
    if (time <= 23.50) return 45;
    if (time <= 23.60) return 44;
    if (time <= 23.70) return 43;
    if (time <= 23.80) return 42;
    if (time <= 23.90) return 41;
    if (time <= 24.00) return 40;
    if (time <= 24.10) return 39;
    if (time <= 24.20) return 38;
    if (time <= 24.30) return 37;
    if (time <= 24.40) return 36;
    if (time <= 24.50) return 35;
    if (time <= 24.60) return 34;
    if (time <= 24.70) return 33;
    if (time <= 24.80) return 32;
    if (time <= 24.90) return 31;
    if (time <= 25.00) return 30;
    if (time <= 25.70) return 25;
    if (time <= 25.80) return 24;
    if (time <= 25.90) return 23;
    if (time <= 26.10) return 21;
    if (time <= 26.20) return 20;
    if (time <= 26.30) return 19;
    if (time <= 26.40) return 18;
    if (time <= 26.50) return 17;
    if (time <= 26.60) return 16;
    if (time <= 26.70) return 15;
    if (time <= 26.80) return 14;
    if (time <= 26.90) return 13;
    if (time <= 27.00) return 12;
    if (time <= 27.10) return 11;
    if (time <= 27.20) return 10;
    if (time <= 27.30) return 9;
    if (time <= 27.40) return 8;
    if (time <= 27.50) return 7;
    if (time <= 27.60) return 6;
    if (time <= 27.70) return 5;
    return 0;
  }

  static int _calculateBeepTestScore(int level, int shuttles) {
    // Convert level-shuttles to a comparable value or just use if-else logic
    // Since the table is not linear, we'll use a lookup or a series of checks.
    // A simple way is to convert to total shuttles if we knew the shuttles per level,
    // but the table gives specific X-Y values.
    // We can implement a comparator or just a long list of checks.
    
    // Helper to compare (level, shuttles) >= (targetLevel, targetShuttles)
    bool gte(int l, int s) {
      if (level > l) return true;
      if (level == l && shuttles >= s) return true;
      return false;
    }

    if (gte(12, 5)) return 75;
    if (gte(11, 12)) return 70;
    if (gte(11, 11)) return 69;
    if (gte(11, 10)) return 68;
    if (gte(11, 9)) return 67;
    if (gte(11, 8)) return 66;
    if (gte(11, 7)) return 65;
    if (gte(11, 6)) return 64;
    if (gte(11, 5)) return 63;
    if (gte(11, 4)) return 62;
    if (gte(11, 3)) return 61;
    if (gte(11, 2)) return 60;
    if (gte(11, 1)) return 59;
    if (gte(10, 11)) return 58;
    if (gte(10, 10)) return 57;
    if (gte(10, 9)) return 56;
    if (gte(10, 8)) return 55;
    if (gte(10, 7)) return 54;
    if (gte(10, 6)) return 53;
    if (gte(10, 5)) return 52;
    if (gte(10, 4)) return 51;
    if (gte(10, 3)) return 50;
    if (gte(10, 2)) return 49;
    if (gte(10, 1)) return 47;
    if (gte(9, 10)) return 46;
    if (gte(9, 9)) return 45;
    if (gte(9, 8)) return 44;
    if (gte(9, 7)) return 43;
    if (gte(9, 6)) return 42;
    if (gte(9, 5)) return 41;
    if (gte(9, 4)) return 40;
    if (gte(9, 3)) return 39;
    if (gte(9, 2)) return 38;
    if (gte(9, 1)) return 37;
    if (gte(8, 11)) return 36;
    if (gte(8, 10)) return 35;
    if (gte(8, 9)) return 34;
    if (gte(8, 8)) return 33;
    if (gte(8, 7)) return 32;
    if (gte(8, 6)) return 31;
    if (gte(8, 5)) return 30;
    if (gte(7, 2)) return 25;
    if (gte(7, 1)) return 23;
    if (gte(6, 11)) return 22;
    if (gte(6, 10)) return 21;
    if (gte(6, 9)) return 20;
    if (gte(6, 8)) return 19;
    if (gte(6, 7)) return 18;
    if (gte(6, 6)) return 17;
    if (gte(6, 5)) return 16;
    if (gte(6, 4)) return 15;
    if (gte(6, 3)) return 14;
    if (gte(6, 2)) return 13;
    if (gte(6, 1)) return 12;
    if (gte(5, 9)) return 11;
    if (gte(5, 8)) return 10;
    if (gte(5, 7)) return 9;
    if (gte(5, 6)) return 8;
    if (gte(5, 5)) return 7;
    if (gte(5, 4)) return 6;
    if (gte(5, 3)) return 5;
    return 0;
  }

  static int _calculatePreferentialPoints(int age) {
    if (age >= 50) return 35;
    if (age >= 45) return 30;
    if (age >= 40) return 25;
    if (age >= 35) return 20;
    if (age >= 30) return 10;
    return 0;
  }

  static (int, String) _calculateGrade(double score) {
    if (score > 60) return (6, 'Wybitna');
    if (score >= 56) return (5, 'Bardzo dobra');
    if (score >= 51) return (4, 'Dobra');
    if (score >= 46) return (3, 'Dostateczna');
    if (score >= 41) return (2, 'Słaba');
    return (1, 'Niedostateczna');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testDate': testDate.toIso8601String(),
      'firefighterName': firefighterName,
      'firefighterAge': firefighterAge,
      'gender': gender,
      'pullUps': pullUps,
      'ballThrowDistance': ballThrowDistance,
      'coneRunTime': coneRunTime,
      'beepTestLevel': beepTestLevel,
      'beepTestShuttles': beepTestShuttles,
      'pullUpScore': pullUpScore,
      'coneRunScore': coneRunScore,
      'beepTestScore': beepTestScore,
      'averageScore': averageScore,
      'preferentialPoints': preferentialPoints,
      'finalScore': finalScore,
      'grade': grade,
      'gradeLabel': gradeLabel,
    };
  }

  factory FitnessTest.fromJson(Map<String, dynamic> json) {
    return FitnessTest(
      id: json['id'],
      testDate: DateTime.parse(json['testDate']),
      firefighterName: json['firefighterName'],
      firefighterAge: json['firefighterAge'],
      gender: json['gender'],
      pullUps: json['pullUps'],
      ballThrowDistance: json['ballThrowDistance'],
      coneRunTime: json['coneRunTime'],
      beepTestLevel: json['beepTestLevel'],
      beepTestShuttles: json['beepTestShuttles'],
      pullUpScore: json['pullUpScore'],
      coneRunScore: json['coneRunScore'],
      beepTestScore: json['beepTestScore'],
      averageScore: json['averageScore'],
      preferentialPoints: json['preferentialPoints'],
      finalScore: json['finalScore'],
      grade: json['grade'],
      gradeLabel: json['gradeLabel'],
    );
  }
}

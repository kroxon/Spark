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
      if (pullUps == 25) return 74;
      if (pullUps == 24) return 73;
      if (pullUps == 23) return 72;
      if (pullUps == 22) return 71;
      if (pullUps == 21) return 70;
      if (pullUps == 20) return 69;
      if (pullUps == 19) return 68;
      if (pullUps == 18) return 67;
      if (pullUps == 17) return 66;
      if (pullUps == 16) return 65;
      if (pullUps == 15) return 63;
      if (pullUps == 14) return 61;
      if (pullUps == 13) return 58;
      if (pullUps == 12) return 55;
      if (pullUps == 11) return 50;
      if (pullUps == 10) return 45;
      if (pullUps == 9) return 40;
      if (pullUps == 8) return 35;
      if (pullUps == 7) return 30;
      if (pullUps == 6) return 25;
      if (pullUps == 5) return 20;
      if (pullUps == 4) return 15;
      if (pullUps == 3) return 10;
      if (pullUps == 2) return 5;
      if (pullUps == 1) return 1;
      return 0;
    } else {
      if (distance == null) return 0;
      // Round to 1 decimal place for comparison safety
      double d = (distance * 10).round() / 10.0;
      
      if (d >= 10.0) return 75;
      if (d >= 8.0) {
        // 8.0 -> 55. 10.0 -> 75. (2.0m diff = 20 pts). 1 pt per 0.1m.
        return 55 + ((d - 8.0) * 10).round();
      }
      if (d >= 6.0) {
        // 6.0 -> 15. 7.9 -> 53. (1.9m diff = 38 pts). 2 pts per 0.1m.
        return 15 + ((d - 6.0) * 20).round();
      }
      if (d >= 5.6) {
        // 5.6 -> 7. 5.9 -> 13. (0.3m diff = 6 pts). 2 pts per 0.1m.
        return 7 + ((d - 5.6) * 20).round();
      }
      if (d >= 5.0) {
        // 5.0 -> 1. 5.5 -> 6. (0.5m diff = 5 pts). 1 pt per 0.1m.
        return 1 + ((d - 5.0) * 10).round();
      }
      return 0;
    }
  }

  static int _calculateConeRunScore(double time) {
    if (time <= 22.00) return 75;
    
    // 22.00 - 23.50: 1 pt per 0.05s
    // 22.00 is 75. 23.50 is 45.
    // Diff 1.5s = 30 steps of 0.05s. Points diff 30. Correct.
    if (time <= 23.50) {
      double diff = time - 22.00;
      int steps = (diff / 0.05).ceil(); // ceil because lower time is better, so slightly above 22.00 drops a point
      // Example: 22.01 -> steps=1 -> 74. Correct.
      // Example: 22.05 -> steps=1 -> 74. Correct.
      // Example: 22.06 -> steps=2 -> 73. Correct.
      return 75 - steps;
    }
    
    // 23.50 - 27.90: 1 pt per 0.10s
    // 23.50 is 45. 27.90 is 1.
    // Diff 4.4s = 44 steps of 0.10s. Points diff 44. Correct.
    if (time <= 27.90) {
      double diff = time - 23.50;
      int steps = (diff / 0.10).ceil();
      return 45 - steps;
    }
    
    return 0;
  }

  static int _calculateBeepTestScore(int level, int shuttles) {
    if (level < 5) return 0;
    if (level == 5) {
      // 5-5 is 1 pt. 5-9 is 5 pts.
      if (shuttles < 5) return 0;
      return shuttles - 4;
    }
    if (level == 6) return 5 + shuttles;   // 6-1 -> 6
    if (level == 7) return 15 + shuttles;  // 7-1 -> 16
    if (level == 8) return 25 + shuttles;  // 8-1 -> 26
    if (level == 9) return 36 + shuttles;  // 9-1 -> 37
    if (level == 10) return 47 + shuttles; // 10-1 -> 48
    if (level == 11) return 58 + shuttles; // 11-1 -> 59
    if (level == 12) return 70 + shuttles; // 12-1 -> 71
    
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

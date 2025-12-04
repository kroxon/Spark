enum Gender {
  male,
  female;

  String get label => this == Gender.male ? 'Mężczyzna' : 'Kobieta';
  String get code => this == Gender.male ? 'M' : 'F';
}

enum AgeGroup {
  group1(0, 29, 'do 29 lat'),
  group2(30, 34, '30-34 lata'),
  group3(35, 39, '35-39 lat'),
  group4(40, 44, '40-44 lata'),
  group5(45, 49, '45-49 lat'),
  group6(50, 99, '50+ lat');

  final int minAge;
  final int maxAge;
  final String displayName;

  const AgeGroup(this.minAge, this.maxAge, this.displayName);
}

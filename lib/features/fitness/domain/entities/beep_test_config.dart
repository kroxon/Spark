class BeepLevelConfig {
  final int level;
  final int shuttles;
  final double timePerShuttle;

  const BeepLevelConfig(this.level, this.shuttles, this.timePerShuttle);

  double get speedKmh => (20.0 / timePerShuttle) * 3.6;
}

const List<BeepLevelConfig> beepConfig = [
  BeepLevelConfig(1, 7, 9.0),
  BeepLevelConfig(2, 8, 8.0),
  BeepLevelConfig(3, 8, 7.5),
  BeepLevelConfig(4, 9, 7.2),
  BeepLevelConfig(5, 9, 6.8),
  BeepLevelConfig(6, 10, 6.5),
  BeepLevelConfig(7, 10, 6.2),
  BeepLevelConfig(8, 11, 6.0),
  BeepLevelConfig(9, 11, 5.7),
  BeepLevelConfig(10, 11, 5.5),
  BeepLevelConfig(11, 12, 5.3),
  BeepLevelConfig(12, 6, 5.1),
];

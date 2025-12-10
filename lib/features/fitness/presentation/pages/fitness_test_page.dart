import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iskra/features/fitness/domain/fitness_test.dart';
import 'package:iskra/features/fitness/domain/entities/fitness_enums.dart';
import 'package:iskra/features/fitness/domain/entities/beep_test_config.dart';
import 'package:iskra/features/fitness/presentation/widgets/fitness_test/fitness_test_header.dart';
import 'package:iskra/features/fitness/presentation/widgets/fitness_test/fitness_test_settings.dart';
import 'package:iskra/features/fitness/presentation/widgets/fitness_test/fitness_test_measurements.dart';
import 'package:iskra/features/fitness/presentation/widgets/fitness_test/beep_test_player.dart';

class FitnessTestPage extends ConsumerStatefulWidget {
  const FitnessTestPage({super.key});

  @override
  ConsumerState<FitnessTestPage> createState() => _FitnessTestPageState();
}

class _FitnessTestPageState extends ConsumerState<FitnessTestPage> with SingleTickerProviderStateMixin {
  // Generated timestamps from audio analysis
  static const Map<String, int> _beepTimestamps = {
  '1-1': 9066, // 9.003s
  '1-2': 18069, // 9.003s
  '1-3': 27072, // 9.002s
  '1-4': 36074, // 8.982s
  '1-5': 45056, // 9.024s
  '1-6': 54080, // 9.002s
  '1-7': 63082, // 9.003s
  '2-1': 72085, // 7.979s
  '2-2': 80064, // 8.000s
  '2-3': 88064, // 8.000s
  '2-4': 96064, // 8.000s
  '2-5': 104064, // 8.000s
  '2-6': 112064, // 8.000s
  '2-7': 120064, // 8.000s
  '2-8': 128064, // 8.021s
  '3-1': 136085, // 7.573s
  '3-2': 143658, // 7.574s
  '3-3': 151232, // 7.573s
  '3-4': 158805, // 7.595s
  '3-5': 166400, // 7.573s
  '3-6': 173973, // 7.573s
  '3-7': 181546, // 7.595s
  '3-8': 189141, // 7.573s
  '4-1': 196714, // 7.190s
  '4-2': 203904, // 7.210s
  '4-3': 211114, // 7.190s
  '4-4': 218304, // 7.210s
  '4-5': 225514, // 7.190s
  '4-6': 232704, // 7.210s
  '4-7': 239914, // 7.190s
  '4-8': 247104, // 7.210s
  '4-9': 254314, // 7.190s
  '5-1': 261504, // 6.869s
  '5-2': 268373, // 6.869s
  '5-3': 275242, // 6.848s
  '5-4': 282090, // 6.870s
  '5-5': 288960, // 6.848s
  '5-6': 295808, // 6.869s
  '5-7': 302677, // 6.848s
  '5-8': 309525, // 6.869s
  '5-9': 316394, // 6.870s
  '6-1': 323264, // 6.528s
  '6-2': 329792, // 6.570s
  '6-3': 336362, // 6.550s
  '6-4': 342912, // 6.549s
  '6-5': 349461, // 6.549s
  '6-6': 356010, // 6.550s
  '6-7': 362560, // 6.549s
  '6-8': 369109, // 6.549s
  '6-9': 375658, // 6.550s
  '6-10': 382208, // 6.549s
  '7-1': 388757, // 6.251s
  '7-2': 395008, // 6.272s
  '7-3': 401280, // 6.250s
  '7-4': 407530, // 6.272s
  '7-5': 413802, // 6.251s
  '7-6': 420053, // 6.251s
  '7-7': 426304, // 6.272s
  '7-8': 432576, // 6.250s
  '7-9': 438826, // 6.272s
  '7-10': 445098, // 6.251s
  '8-1': 451349, // 5.995s
  '8-2': 457344, // 6.016s
  '8-3': 463360, // 5.994s
  '8-4': 469354, // 5.995s
  '8-5': 475349, // 5.995s
  '8-6': 481344, // 6.016s
  '8-7': 487360, // 5.994s
  '8-8': 493354, // 5.995s
  '8-9': 499349, // 5.995s
  '8-10': 505344, // 6.144s
  '8-11': 511488, // 5.866s
  '9-1': 517354, // 5.760s
  '9-2': 523114, // 5.760s
  '9-3': 528874, // 5.760s
  '9-4': 534634, // 5.760s
  '9-5': 540394, // 5.760s
  '9-6': 546154, // 5.760s
  '9-7': 551914, // 5.760s
  '9-8': 557674, // 5.760s
  '9-9': 563434, // 5.760s
  '9-10': 569194, // 5.760s
  '9-11': 574954, // 5.760s
  '10-1': 580714, // 5.547s
  '10-2': 586261, // 5.525s
  '10-3': 591786, // 5.547s
  '10-4': 597333, // 5.547s
  '10-5': 602880, // 5.525s
  '10-6': 608405, // 5.547s
  '10-7': 613952, // 5.546s
  '10-8': 619498, // 5.526s
  '10-9': 625024, // 5.546s
  '10-10': 630570, // 5.547s
  '10-11': 636117, // 5.547s
  '11-1': 641664, // 5.312s
  '11-2': 646976, // 5.333s
  '11-3': 652309, // 5.333s
  '11-4': 657642, // 5.334s
  '11-5': 662976, // 5.333s
  '11-6': 668309, // 5.333s
  '11-7': 673642, // 5.312s
  '11-8': 678954, // 5.334s
  '11-9': 684288, // 5.333s
  '11-10': 689621, // 5.333s
  '11-11': 694954, // 5.334s
  '11-12': 700288, // 5.333s
  '12-1': 705621, // 5.141s
  '12-2': 710762, // 5.120s
  '12-3': 715882, // 5.142s
  '12-4': 721024, // 6.080s
  '12-5': 727104, // 4.202s
  '12-6': 731306, // End
  };

  // State
  Gender _gender = Gender.male;
  AgeGroup _ageGroup = AgeGroup.group1;
  
  // Beep Test
  int _beepLevel = 1;
  int _beepShuttle = 1;
  
  // Beep Test Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const double _introDuration = 9.0;
  bool _isPlayerExpanded = false;
  bool _isPlaying = false;
  bool _autoSyncResult = false;
  int _playerLevel = 1;
  int _playerShuttle = 1;
  Timer? _testTimer;
  double _totalElapsedTime = 0.0;
  double _currentShuttleElapsed = 0.0;
  double _currentShuttleDuration = 9.0;
  
  // Cone Run
  final TextEditingController _coneRunController = TextEditingController();
  
  // Strength
  final TextEditingController _ballThrowController = TextEditingController();
  int _strengthReps = 13; // Pull-ups
  late PageController _strengthController;
  double _strengthPage = 13.0;

  // Animation
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;
  double _displayedScore = 0;
  double _targetScore = 0;

  @override
  void initState() {
    super.initState();
    _totalElapsedTime = -_introDuration;
    // Preload audio
    _initAudio();

    _strengthController = PageController(viewportFraction: 0.18, initialPage: 13);
    _strengthController.addListener(() {
      setState(() {
        _strengthPage = _strengthController.page ?? 0;
      });
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    )..addListener(() {
        setState(() {
          _displayedScore = _scoreAnimation.value;
        });
      });

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScore());
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('data/Beep_Test_Dzwiek.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Error initializing audio: $e");
    }
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _audioPlayer.dispose();
    _animController.dispose();
    _coneRunController.dispose();
    _ballThrowController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  // --- Beep Test Player Logic ---

  void _togglePlayer() {
    setState(() {
      _isPlayerExpanded = !_isPlayerExpanded;
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseTest();
    } else {
      _startTest();
    }
  }

  void _startTest() async {
    if (_isPlaying) return;

    setState(() {
      _isPlaying = true;
      if (_currentShuttleDuration <= 0) {
        _updateShuttleDuration();
      }
    });

    try {
      // Seek to correct position (handle intro)
      double seekSeconds = _totalElapsedTime + _introDuration;
      if (seekSeconds < 0) seekSeconds = 0;
      
      final seekMs = (seekSeconds * 1000).round();
      await _audioPlayer.seek(Duration(milliseconds: seekMs));
      await _audioPlayer.resume();

      _testTimer?.cancel();
      _testTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
        final position = await _audioPlayer.getCurrentPosition();
        if (position == null) return;

        _syncStateFromTime(position.inMilliseconds);
      });
    } catch (e) {
      debugPrint("Error starting playback: $e");
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _pauseTest() {
    _testTimer?.cancel();
    _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _resetTest() {
    _pauseTest();
    _audioPlayer.stop();
    setState(() {
      _playerLevel = 1;
      _playerShuttle = 1;
      _totalElapsedTime = -_introDuration; // Reset to start of intro
      _currentShuttleElapsed = 0.0;
      _updateShuttleDuration();
      if (_autoSyncResult) {
        _beepLevel = 1;
        _beepShuttle = 1;
        _updateScore();
      }
    });
  }

  void _updateShuttleDuration() {
    int startTime = _getTimeForLevelShuttle(_playerLevel, _playerShuttle);
    
    int nextL = _playerLevel;
    int nextS = _playerShuttle + 1;
    int maxS = _getMaxShuttles(_playerLevel);
    if (nextS > maxS) {
      nextL++;
      nextS = 1;
    }
    
    String nextK = '$nextL-$nextS';
    if (_beepTimestamps.containsKey(nextK)) {
      int nextTime = _beepTimestamps[nextK]!;
      _currentShuttleDuration = (nextTime - startTime) / 1000.0;
    } else {
      final config = beepConfig.firstWhere((c) => c.level == _playerLevel, orElse: () => beepConfig.last);
      _currentShuttleDuration = config.timePerShuttle;
    }
  }

  void _nextShuttle() {
    double current = _getGlobalProgress();
    double target = (current.floor() + 1).toDouble();
    if (target > _totalTestShuttles) target = _totalTestShuttles.toDouble();
    _seekTo(target);
  }

  void _syncStateFromTime(int curTime) {
    int level = 1;
    int shuttle = 1;
    double shuttleDuration = 9.0;
    double shuttleElapsed = 0.0;

    if (curTime < 9024) {
      // Intro
      level = 1;
      shuttle = 1;
      shuttleDuration = 9.0;
      shuttleElapsed = 0.0;
    } else {
      // Find the current interval
      int startTime = 9024;
      
      // Iterate through all defined timestamps to find the one we are in
      for (final config in beepConfig) {
        for (int s = 1; s <= config.shuttles; s++) {
          String key = '${config.level}-$s';
          if (_beepTimestamps.containsKey(key)) {
            int t = _beepTimestamps[key]!;
            if (curTime >= t) {
              startTime = t;
              level = config.level;
              shuttle = s;
            } else {
              // We passed the current time, so we are in the previous interval
              break;
            }
          }
        }
        if (curTime < startTime) break;
      }
      
      // Calculate duration to next beep
      int nextL = level;
      int nextS = shuttle + 1;
      int maxS = _getMaxShuttles(level);
      if (nextS > maxS) {
        nextL++;
        nextS = 1;
      }
      
      String nextK = '$nextL-$nextS';
      if (_beepTimestamps.containsKey(nextK)) {
        int nextTime = _beepTimestamps[nextK]!;
        shuttleDuration = (nextTime - startTime) / 1000.0;
      } else {
        // Fallback to config duration
        final config = beepConfig.firstWhere((c) => c.level == level, orElse: () => beepConfig.last);
        shuttleDuration = config.timePerShuttle;
      }
      
      shuttleElapsed = (curTime - startTime) / 1000.0;
    }

    setState(() {
      _playerLevel = level;
      _playerShuttle = shuttle;
      _currentShuttleDuration = shuttleDuration;
      _currentShuttleElapsed = shuttleElapsed;
      _totalElapsedTime = (curTime - 9024) / 1000.0;

      if (_autoSyncResult) {
        _beepLevel = _playerLevel;
        _beepShuttle = _playerShuttle;
        _updateScore();
      }
    });
  }

  int _calculateTotalDistance() {
    int distance = 0;
    // Add full levels
    for (int i = 1; i < _playerLevel; i++) {
      distance += _getMaxShuttles(i) * 20;
    }
    // Add completed shuttles in current level
    distance += (_playerShuttle - 1) * 20;
    
    // Add partial distance for current shuttle
    if (_currentShuttleDuration > 0) {
      double progress = _currentShuttleElapsed / _currentShuttleDuration;
      distance += (progress * 20).toInt();
    }
    
    return distance;
  }

  // --- End Logic ---

  void _updateScore() {
    final test = _calculateCurrentState();
    final newScore = test.finalScore;
    
    if (newScore != _targetScore) {
      _targetScore = newScore;
      _scoreAnimation = Tween<double>(
        begin: _displayedScore,
        end: newScore,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart));
      
      _animController
        ..reset()
        ..forward();
    }
  }

  FitnessTest _calculateCurrentState() {
    String text = _coneRunController.text.replaceAll(',', '.');
    double? coneTime = double.tryParse(text);
    
    // If empty or invalid, treat as 30.0 (0 points)
    double effectiveTime = coneTime ?? 30.0;
    if (effectiveTime == 0) effectiveTime = 30.0;

    double? ballThrowDist;
    if (_gender == Gender.female) {
      String ballText = _ballThrowController.text.replaceAll(',', '.');
      ballThrowDist = double.tryParse(ballText) ?? 0.0;
    }

    return FitnessTest.create(
      firefighterName: 'Kalkulator',
      firefighterAge: _ageGroup.minAge,
      gender: _gender.code,
      testDate: DateTime.now(),
      beepTestLevel: _beepLevel,
      beepTestShuttles: _beepShuttle,
      coneRunTime: effectiveTime,
      pullUps: _gender == Gender.male ? _strengthReps : null,
      ballThrowDistance: ballThrowDist,
    );
  }

  // --- Logic Helpers ---

  int get _totalTestShuttles => beepConfig.fold(0, (sum, item) => sum + item.shuttles);

  int _getMaxShuttles(int level) {
    final config = beepConfig.firstWhere(
      (c) => c.level == level, 
      orElse: () => beepConfig.last
    );
    return config.shuttles;
  }

  double _getGlobalProgress() {
    int shuttlesBefore = 0;
    for (final config in beepConfig) {
      if (config.level < _playerLevel) {
        shuttlesBefore += config.shuttles;
      } else {
        break;
      }
    }
    
    // Current shuttle index (0-based) + progress within shuttle
    double currentShuttleProgress = 0.0;
    if (_currentShuttleDuration > 0) {
      currentShuttleProgress = (_currentShuttleElapsed / _currentShuttleDuration).clamp(0.0, 1.0);
    }
    
    return shuttlesBefore + (_playerShuttle - 1) + currentShuttleProgress;
  }

  int _getTimeForLevelShuttle(int level, int shuttle) {
    String key = '$level-$shuttle';
    if (_beepTimestamps.containsKey(key)) {
      return _beepTimestamps[key]!;
    }
    return 9024;
  }

  void _seekTo(double globalValue) {
    // We interpret the value as "completed shuttles so far".
    // So 0.0 means start of 1st shuttle.
    // 1.0 means start of 2nd shuttle.
    
    int shuttleIndex = globalValue.floor(); 
    
    int accumulatedShuttles = 0;
    int targetLevel = 1;
    int targetShuttle = 1;
    
    for (final config in beepConfig) {
      if (shuttleIndex < accumulatedShuttles + config.shuttles) {
        targetLevel = config.level;
        targetShuttle = (shuttleIndex - accumulatedShuttles) + 1;
        break;
      }
      accumulatedShuttles += config.shuttles;
      targetLevel = config.level;
    }
    
    // Edge case for max value
    if (shuttleIndex >= _totalTestShuttles) {
      targetLevel = 12;
      targetShuttle = 5;
    }

    setState(() {
      _playerLevel = targetLevel;
      _playerShuttle = targetShuttle;
      
      // Calculate start time
      int startTime = _getTimeForLevelShuttle(targetLevel, targetShuttle);
      
      // Calculate duration
      int nextL = targetLevel;
      int nextS = targetShuttle + 1;
      int maxS = _getMaxShuttles(targetLevel);
      if (nextS > maxS) {
        nextL++;
        nextS = 1;
      }
      
      double durationMs = 0;
      String nextK = '$nextL-$nextS';
      
      if (_beepTimestamps.containsKey(nextK)) {
        int nextTime = _beepTimestamps[nextK]!;
        durationMs = (nextTime - startTime).toDouble();
      } else {
        final config = beepConfig.firstWhere((c) => c.level == targetLevel, orElse: () => beepConfig.last);
        durationMs = config.timePerShuttle * 1000;
      }
      
      _currentShuttleDuration = durationMs / 1000.0;
      
      // Snap to start of the shuttle
      _currentShuttleElapsed = 0.0;
      _totalElapsedTime = (startTime - 9024) / 1000.0;
      
      _audioPlayer.seek(Duration(milliseconds: startTime));

      if (_autoSyncResult) {
        _beepLevel = _playerLevel;
        _beepShuttle = _playerShuttle;
        _updateScore();
      }
    });
  }

  void _updateBeepTest(int? newLevel, int? newShuttle) {
    setState(() {
      if (newLevel != null) {
        _beepLevel = newLevel.clamp(1, 12);
        int maxS = _getMaxShuttles(_beepLevel);
        if (_beepShuttle > maxS) _beepShuttle = maxS;
      }
      if (newShuttle != null) {
        int maxS = _getMaxShuttles(_beepLevel);
        _beepShuttle = newShuttle.clamp(1, maxS);
      }
      _updateScore();
    });
  }

  double _getCurrentSpeed() {
    if (!_isPlaying || _totalElapsedTime < 0) return 0.0;
    return beepConfig.firstWhere((c) => c.level == _playerLevel, orElse: () => beepConfig.last).speedKmh;
  }

  @override
  Widget build(BuildContext context) {
    final test = _calculateCurrentState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F7),
      body: Stack(
        children: [
          Column(
            children: [
              FitnessTestHeader(
                test: test,
                displayedScore: _displayedScore,
                gender: _gender,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FitnessTestSettings(
                          gender: _gender,
                          ageGroup: _ageGroup,
                          onGenderChanged: (g) {
                            setState(() {
                              _gender = g;
                              _updateScore();
                            });
                          },
                          onAgeGroupChanged: (a) {
                            setState(() {
                              _ageGroup = a;
                              _updateScore();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        FitnessTestMeasurements(
                          gender: _gender,
                          beepLevel: _beepLevel,
                          beepShuttle: _beepShuttle,
                          coneRunController: _coneRunController,
                          ballThrowController: _ballThrowController,
                          strengthReps: _strengthReps,
                          strengthController: _strengthController,
                          strengthPage: _strengthPage,
                          onBeepUpdate: _updateBeepTest,
                          onStrengthRepsChanged: (index) {
                            setState(() {
                              _strengthReps = index;
                              _updateScore();
                            });
                          },
                          onInputChanged: _updateScore,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          BeepTestPlayer(
            isExpanded: _isPlayerExpanded,
            isPlaying: _isPlaying,
            playerLevel: _playerLevel,
            playerShuttle: _playerShuttle,
            currentShuttleElapsed: _currentShuttleElapsed,
            currentShuttleDuration: _currentShuttleDuration,
            totalElapsedTime: _totalElapsedTime,
            globalProgress: _getGlobalProgress(),
            totalTestShuttles: _totalTestShuttles,
            totalDistance: _calculateTotalDistance(),
            currentSpeed: _getCurrentSpeed(),
            autoSyncResult: _autoSyncResult,
            onToggleExpand: _togglePlayer,
            onTogglePlayPause: _togglePlayPause,
            onReset: _resetTest,
            onNextShuttle: _nextShuttle,
            onSeek: (val) {
              _pauseTest();
              _seekTo(val);
            },
            onAutoSyncChanged: (val) {
              setState(() {
                _autoSyncResult = val;
                if (val) {
                  _beepLevel = _playerLevel;
                  _beepShuttle = _playerShuttle;
                  _updateScore();
                }
              });
            },
          ),
        ],
      ),
    );
  }
}








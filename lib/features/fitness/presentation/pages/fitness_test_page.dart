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
  '1-1': 9024,
  '1-2': 18026,
  '1-3': 27029,
  '1-4': 36032,
  '1-5': 45013,
  '1-6': 54037,
  '1-7': 63018,
  '2-1': 72021,
  '2-2': 80021,
  '2-3': 88021,
  '2-4': 96021,
  '2-5': 104021,
  '2-6': 112021,
  '2-7': 120021,
  '2-8': 128021,
  '3-1': 136021,
  '3-2': 143616,
  '3-3': 151189,
  '3-4': 158762,
  '3-5': 166336,
  '3-6': 173930,
  '3-7': 181504,
  '3-8': 189077,
  '4-1': 196672,
  '4-2': 203861,
  '4-3': 211072,
  '4-4': 218261,
  '4-5': 225472,
  '4-6': 232661,
  '4-7': 239872,
  '4-8': 247061,
  '4-9': 254272,
  '5-1': 261461,
  '5-2': 268330,
  '5-3': 275178,
  '5-4': 282048,
  '5-5': 288896,
  '5-6': 295765,
  '5-7': 302634,
  '5-8': 309482,
  '5-9': 316352,
  '6-1': 323221,
  '6-2': 329749,
  '6-3': 336298,
  '6-4': 342848,
  '6-5': 349397,
  '6-6': 355946,
  '6-7': 362496,
  '6-8': 369045,
  '6-9': 375616,
  '6-10': 382165,
  '7-1': 388714,
  '7-2': 394965,
  '7-3': 401216,
  '7-4': 407488,
  '7-5': 413738,
  '7-6': 420010,
  '7-7': 426261,
  '7-8': 432533,
  '7-9': 438784,
  '7-10': 445056,
  '8-1': 451306,
  '8-2': 457301,
  '8-3': 463296,
  '8-4': 469312,
  '8-5': 475306,
  '8-6': 481301,
  '8-7': 487296,
  '8-8': 493312,
  '8-9': 499306,
  '8-10': 505301,
  '8-11': 511424,
  '9-1': 517312,
  '9-2': 523904,
  '9-3': 528832,
  '9-4': 534592,
  '9-5': 540608,
  '9-6': 546112,
  '9-7': 551872,
  '9-8': 557632,
  '9-9': 563648,
  '9-10': 569152,
  '9-11': 574912,
  '10-1': 580928,
  '10-2': 587114,
  '10-3': 591744,
  '10-4': 597290,
  '10-5': 602816,
  '10-6': 608362,
  '10-7': 613909,
  '10-8': 619456,
  '10-9': 624981,
  '10-10': 631296,
  '10-11': 636074,
  '11-1': 642090,
  '11-2': 646933,
  '11-3': 652266,
  '11-4': 657600,
  '11-5': 663744,
  '11-6': 668245,
  '11-7': 674410,
  '11-8': 678912,
  '11-9': 685312,
  '11-10': 689578,
  '11-11': 695658,
  '11-12': 700245,
  '12-1': 706304,
  '12-2': 710698,
  '12-3': 715840,
  '12-4': 720981,
  '12-5': 727104,
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
  bool _autoSyncResult = true;
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
    final config = beepConfig.firstWhere((c) => c.level == _playerLevel, orElse: () => beepConfig.last);
    _currentShuttleDuration = config.timePerShuttle;
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
      _updateShuttleDuration();
      _currentShuttleElapsed = 0.0; // Always start at 0
      
      // Calculate time using generated map
      int seekMs = _getTimeForLevelShuttle(targetLevel, targetShuttle);
      _totalElapsedTime = (seekMs - 9024) / 1000.0;
      
      // Seek audio
      _audioPlayer.seek(Duration(milliseconds: seekMs));

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








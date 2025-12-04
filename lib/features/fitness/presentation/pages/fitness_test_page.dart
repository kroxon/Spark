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

    // Logic based on provided Java code
    if (curTime < 9000) {
      level = 1;
      shuttle = 1;
      shuttleDuration = 9.0;
      shuttleElapsed = 0.0;
    } else if (curTime >= 9000 && curTime < 72000) {
      level = 1;
      int start = 9000;
      int duration = 9000;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 72000 && curTime < 136000) {
      level = 2;
      int start = 72000;
      int duration = 8000;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 136000 && curTime < 196000) {
      level = 3;
      int start = 136000;
      int duration = 7500;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 196000 && curTime < 260800) {
      level = 4;
      int start = 196000;
      int duration = 7200;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 260800 && curTime < 322000) {
      level = 5;
      int start = 260800;
      int duration = 6800;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 322600 && curTime < 387000) {
      level = 6;
      int start = 322600;
      int duration = 6500;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 387700 && curTime < 449000) {
      level = 7;
      int start = 387800;
      int duration = 6200;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 450300 && curTime < 515000) {
      level = 8;
      int start = 450500;
      int duration = 6000;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 517000 && curTime < 577700) {
      level = 9;
      int start = 517000;
      int duration = 5700;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 579700 && curTime < 638200) {
      level = 10;
      int start = 580200;
      int duration = 5500;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 641000 && curTime < 701800) {
      level = 11;
      int start = 641200;
      int duration = 5300;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else if (curTime >= 704600) {
      level = 12;
      int start = 704800;
      int duration = 5100;
      shuttle = ((curTime - start) / duration).floor() + 1;
      shuttleDuration = duration / 1000.0;
      shuttleElapsed = ((curTime - start) % duration) / 1000.0;
    } else {
      // In a gap
      setState(() {
        _totalElapsedTime = (curTime - 9000) / 1000.0;
      });
      return;
    }

    setState(() {
      _playerLevel = level;
      _playerShuttle = shuttle;
      _currentShuttleDuration = shuttleDuration;
      _currentShuttleElapsed = shuttleElapsed;
      _totalElapsedTime = (curTime - 9000) / 1000.0;

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
      int time = 0;
      if (level == 1) time = 9000 + (shuttle - 1) * 9000;
      else if (level == 2) time = 72000 + (shuttle - 1) * 8000;
      else if (level == 3) time = 136000 + (shuttle - 1) * 7500;
      else if (level == 4) time = 196000 + (shuttle - 1) * 7200;
      else if (level == 5) time = 260800 + (shuttle - 1) * 6800;
      else if (level == 6) time = 322600 + (shuttle - 1) * 6500;
      else if (level == 7) time = 387800 + (shuttle - 1) * 6200;
      else if (level == 8) time = 450500 + (shuttle - 1) * 6000;
      else if (level == 9) time = 517000 + (shuttle - 1) * 5700;
      else if (level == 10) time = 580200 + (shuttle - 1) * 5500;
      else if (level == 11) time = 641200 + (shuttle - 1) * 5300;
      else if (level == 12) time = 704800 + (shuttle - 1) * 5100;
      return time;
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
      
      // Calculate time using Java logic
      int seekMs = _getTimeForLevelShuttle(targetLevel, targetShuttle);
      _totalElapsedTime = (seekMs - 9000) / 1000.0;
      
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








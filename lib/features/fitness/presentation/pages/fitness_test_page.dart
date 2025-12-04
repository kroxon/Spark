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

        final double audioTime = position.inMilliseconds / 1000.0;
        final double testTime = audioTime - _introDuration;

        _syncStateFromTime(testTime);
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

  void _syncStateFromTime(double time) {
    if (time < 0) {
       // Intro logic
       setState(() {
         _totalElapsedTime = time;
         _playerLevel = 1;
         _playerShuttle = 1;
         _currentShuttleElapsed = 0;
       });
       return;
    }

    double accumulatedTime = 0;
    int newLevel = 1;
    int newShuttle = 1;
    double shuttleElapsed = 0;
    bool isFinished = true;
    
    for (final config in beepConfig) {
      double levelDuration = config.shuttles * config.timePerShuttle;
      
      if (time < accumulatedTime + levelDuration) {
        newLevel = config.level;
        double timeInLevel = time - accumulatedTime;
        int shuttleIndex = (timeInLevel / config.timePerShuttle).floor();
        newShuttle = shuttleIndex + 1;
        shuttleElapsed = timeInLevel - (shuttleIndex * config.timePerShuttle);
        
        // Clamp shuttle
        if (newShuttle > config.shuttles) {
           newShuttle = config.shuttles;
           shuttleElapsed = config.timePerShuttle; 
        }
        isFinished = false;
        break;
      }
      
      accumulatedTime += levelDuration;
      newLevel = config.level; 
    }
    
    // Handle end of test
    if (isFinished) {
       newLevel = 12;
       newShuttle = 5;
       shuttleElapsed = 0; 
       _pauseTest(); // Stop if finished
    }

    setState(() {
      _playerLevel = newLevel;
      _playerShuttle = newShuttle;
      _currentShuttleElapsed = shuttleElapsed;
      _totalElapsedTime = time;
      _updateShuttleDuration();
      
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
      _recalculateTotalTime();
      
      // Seek audio
      final seekMs = ((_totalElapsedTime + _introDuration) * 1000).round();
      _audioPlayer.seek(Duration(milliseconds: seekMs));

      if (_autoSyncResult) {
        _beepLevel = _playerLevel;
        _beepShuttle = _playerShuttle;
        _updateScore();
      }
    });
  }

  void _recalculateTotalTime() {
    double totalTime = 0.0;
    
    for (final config in beepConfig) {
      if (config.level < _playerLevel) {
        totalTime += config.shuttles * config.timePerShuttle;
      } else if (config.level == _playerLevel) {
        totalTime += (_playerShuttle - 1) * config.timePerShuttle;
        break;
      }
    }
    
    totalTime += _currentShuttleElapsed;
    _totalElapsedTime = totalTime;
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








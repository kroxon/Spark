import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/features/fitness/domain/fitness_test.dart';

// --- Local Enums ---

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
  
  // Cone Run
  final TextEditingController _coneRunController = TextEditingController();
  
  // Strength
  int _strengthReps = 0; // Pull-ups or Throw distance (m)

  // Animation
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;
  double _displayedScore = 0;
  double _targetScore = 0;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animController.dispose();
    _coneRunController.dispose();
    super.dispose();
  }

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
    double? coneTime = double.tryParse(_coneRunController.text.replaceAll(',', '.'));
    
    return FitnessTest.create(
      firefighterName: 'Kalkulator',
      firefighterAge: _ageGroup.minAge,
      gender: _gender.code,
      testDate: DateTime.now(),
      beepTestLevel: _beepLevel,
      beepTestShuttles: _beepShuttle,
      coneRunTime: coneTime ?? 0,
      pullUps: _gender == Gender.male ? _strengthReps : null,
      ballThrowDistance: _gender == Gender.female ? _strengthReps.toDouble() : null,
    );
  }

  // --- Logic Helpers ---

  int _getMaxShuttles(int level) {
    if (level < 1) return 7;
    if (level == 1) return 7;
    if (level == 2) return 8;
    if (level == 3) return 8;
    if (level == 4) return 9;
    if (level == 5) return 9;
    if (level == 6) return 10;
    if (level == 7) return 10;
    if (level == 8) return 11;
    if (level == 9) return 11;
    if (level == 10) return 11;
    if (level == 11) return 12;
    if (level == 12) return 12;
    if (level == 13) return 13;
    return 16; 
  }

  void _updateBeepTest(int? newLevel, int? newShuttle) {
    setState(() {
      if (newLevel != null) {
        _beepLevel = newLevel.clamp(1, 21);
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

  @override
  Widget build(BuildContext context) {
    final test = _calculateCurrentState();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2F4F7),
      body: Column(
        children: [
          _buildCompactHeader(test, theme),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSettingsCard(theme),
                    const SizedBox(height: 16),
                    _buildMeasurementsCard(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(FitnessTest test, ThemeData theme) {
    final gradeColor = test.grade == 5 ? Colors.greenAccent : 
                       test.grade >= 4 ? Colors.lightGreenAccent :
                       test.grade >= 3 ? Colors.orangeAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Text(
                'Kalkulator Sprawności',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayedScore.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'pkt',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ocena: ',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                Text(
                  test.gradeLabel,
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGenderTab(Gender.male, 'Mężczyzna', Icons.male),
                  _buildGenderTab(Gender.female, 'Kobieta', Icons.female),
                ],
              ),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AgeGroup.values.length,
              itemBuilder: (context, index) {
                final group = AgeGroup.values[index];
                final isSelected = _ageGroup == group;
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _ageGroup = group;
                        _updateScore();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? theme.primaryColor : theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        group.displayName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderTab(Gender gender, String label, IconData icon) {
    final isSelected = _gender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _gender = gender;
            _updateScore();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.black87 : Colors.grey,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black87 : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementsCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBeepTestRow(theme),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildConeRunRow(theme),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildStrengthRow(theme),
        ],
      ),
    );
  }

  Widget _buildBeepTestRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_run, color: theme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Text(
                'Beep Test',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Poziom $_beepLevel - Odcinek $_beepShuttle',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStepper(
                  label: 'Poziom',
                  value: _beepLevel,
                  onChanged: (val) => _updateBeepTest(val, null),
                  min: 1,
                  max: 21,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStepper(
                  label: 'Odcinek',
                  value: _beepShuttle,
                  onChanged: (val) => _updateBeepTest(null, val),
                  min: 1,
                  max: _getMaxShuttles(_beepLevel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepBtn(Icons.remove, () => onChanged(value - 1), value > min),
          Column(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          _buildStepBtn(Icons.add, () => onChanged(value + 1), value < max),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap, bool enabled) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: enabled ? onTap : null,
      color: enabled ? Colors.black87 : Colors.grey.withOpacity(0.3),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 20,
    );
  }

  Widget _buildConeRunRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: theme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Koperta (3x10m)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Czas w sekundach',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _coneRunController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
                hintText: '00.00',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => _updateScore(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthRow(ThemeData theme) {
    final isPullUps = _gender == Gender.male;
    final label = isPullUps ? 'Podciąganie' : 'Rzut piłką';
    final subLabel = isPullUps ? 'Liczba powtórzeń' : 'Odległość (m)';
    final icon = isPullUps ? Icons.fitness_center : Icons.sports_handball;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subLabel,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '$_strengthReps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 51, // 0 to 50
              itemBuilder: (context, index) {
                final val = index;
                final isSelected = _strengthReps == val;
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _strengthReps = val;
                        _updateScore();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        val.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iskra/features/fitness/domain/entities/fitness_enums.dart';
import 'package:iskra/features/fitness/domain/entities/beep_test_config.dart';
import 'decimal_input_formatter.dart';

class FitnessTestMeasurements extends StatelessWidget {
  final Gender gender;
  final int beepLevel;
  final int beepShuttle;
  final TextEditingController coneRunController;
  final TextEditingController ballThrowController;
  final int strengthReps;
  final PageController strengthController;
  final double strengthPage;
  final Function(int?, int?) onBeepUpdate;
  final Function(int) onStrengthRepsChanged;
  final VoidCallback onInputChanged;

  const FitnessTestMeasurements({
    super.key,
    required this.gender,
    required this.beepLevel,
    required this.beepShuttle,
    required this.coneRunController,
    required this.ballThrowController,
    required this.strengthReps,
    required this.strengthController,
    required this.strengthPage,
    required this.onBeepUpdate,
    required this.onStrengthRepsChanged,
    required this.onInputChanged,
  });

  int _getMaxShuttles(int level) {
    final config = beepConfig.firstWhere(
      (c) => c.level == level, 
      orElse: () => beepConfig.last
    );
    return config.shuttles;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                'Poziom $beepLevel - Odcinek $beepShuttle',
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
                  value: beepLevel,
                  onChanged: (val) => onBeepUpdate(val, null),
                  min: 1,
                  max: 12,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStepper(
                  label: 'Odcinek',
                  value: beepShuttle,
                  onChanged: (val) => onBeepUpdate(null, val),
                  min: 1,
                  max: _getMaxShuttles(beepLevel),
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
              controller: coneRunController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                DecimalInputFormatter(),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                isDense: true,
                hintText: '23,50',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => onInputChanged(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthRow(ThemeData theme) {
    final isPullUps = gender == Gender.male;
    final label = isPullUps ? 'Podciąganie' : 'Rzut piłką';
    final subLabel = isPullUps ? 'Liczba powtórzeń' : 'Odległość (m)';
    final icon = isPullUps ? Icons.fitness_center : Icons.sports_handball;

    if (!isPullUps) {
      // Female: Ball Throw (TextField)
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
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
            SizedBox(
              width: 100,
              child: TextField(
                controller: ballThrowController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  DecimalInputFormatter(),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  hintText: '9,50',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => onInputChanged(),
              ),
            ),
          ],
        ),
      );
    }

    // Male: Pull-ups (Spinner)
    // Range: 0-26 for pullups (26 is 26+)
    const itemCount = 27;

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
                strengthReps >= 26 ? '26+' : '$strengthReps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 80,
            child: PageView.builder(
              controller: strengthController,
              itemCount: itemCount,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                onStrengthRepsChanged(index);
              },
              itemBuilder: (context, index) {
                // Calculate scale and opacity based on distance from center
                double distance = (strengthPage - index).abs();
                double scale = (1.0 - (distance * 0.3)).clamp(0.4, 1.2);
                double opacity = (1.0 - (distance * 0.4)).clamp(0.2, 1.0);
                
                String text = index.toString();
                if (index == 26) text = "26+";

                final isSelected = index == strengthReps;

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Center(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.primaryColor : Colors.grey,
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

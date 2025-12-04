import 'package:flutter/material.dart';
import 'package:iskra/features/fitness/domain/entities/fitness_enums.dart';

class FitnessTestSettings extends StatelessWidget {
  final Gender gender;
  final AgeGroup ageGroup;
  final Function(Gender) onGenderChanged;
  final Function(AgeGroup) onAgeGroupChanged;

  const FitnessTestSettings({
    super.key,
    required this.gender,
    required this.ageGroup,
    required this.onGenderChanged,
    required this.onAgeGroupChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                final isSelected = ageGroup == group;
                return Center(
                  child: GestureDetector(
                    onTap: () => onAgeGroupChanged(group),
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

  Widget _buildGenderTab(Gender g, String label, IconData icon) {
    final isSelected = gender == g;
    return Expanded(
      child: GestureDetector(
        onTap: () => onGenderChanged(g),
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
}

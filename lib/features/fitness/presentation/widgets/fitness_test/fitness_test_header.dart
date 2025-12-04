import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/features/fitness/domain/fitness_test.dart';
import 'package:iskra/features/fitness/domain/entities/fitness_enums.dart';

class FitnessTestHeader extends StatelessWidget {
  final FitnessTest test;
  final double displayedScore;
  final Gender gender;

  const FitnessTestHeader({
    super.key,
    required this.test,
    required this.displayedScore,
    required this.gender,
  });

  String _formatScore(double score) {
    if (score % 1 == 0) {
      return score.toInt().toString();
    }
    return score.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = test.grade == 5 ? Colors.greenAccent : 
                       test.grade >= 4 ? Colors.lightGreenAccent :
                       test.grade >= 3 ? Colors.orangeAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
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
                'Test Sprawności Fizycznej',
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatScore(displayedScore),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      test.gradeLabel,
                      style: TextStyle(
                        color: gradeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 50, color: Colors.white12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMiniScoreRow(
                    gender == Gender.male ? Icons.fitness_center : Icons.sports_handball,
                    test.pullUpScore,
                  ),
                  const SizedBox(height: 4),
                  _buildMiniScoreRow(Icons.timer_outlined, test.coneRunScore),
                  const SizedBox(height: 4),
                  _buildMiniScoreRow(Icons.directions_run, test.beepTestScore),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    height: 1,
                    width: 80,
                    color: Colors.white30,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Średnia',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatScore(test.averageScore),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (test.preferentialPoints > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Wiek',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${test.preferentialPoints}',
                          style: const TextStyle(
                            color: Colors.lightGreenAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScoreRow(IconData icon, num score, {bool isDouble = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 8),
        Text(
          isDouble ? score.toStringAsFixed(1) : score.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

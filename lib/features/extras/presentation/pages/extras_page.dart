import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';

class ExtrasPage extends StatelessWidget {
  const ExtrasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildExtraTile(
            context,
            title: '2048: PSP Edition',
            description: 'Połącz dystynkcje i awansuj od strażaka do generała!',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF3949AB), // Indigo 600
            route: AppRouteName.game2048,
            delay: 100,
          ),
          const SizedBox(height: 20),
          _buildExtraTile(
            context,
            title: 'Nauka KPP',
            description: 'Baza pytań, fiszki i tryb nauki do egzaminu KPP.',
            icon: Icons.medical_services_outlined,
            color: const Color(0xFFD32F2F), // Red 700
            route: AppRouteName.kppMenu,
            delay: 200,
          ),
          const SizedBox(height: 20),
          _buildExtraTile(
            context,
            title: 'Testy Sprawności',
            description: 'Oblicz swoją ocenę i trenuj z interaktywnym Beep Testem.',
            icon: Icons.fitness_center,
            color: const Color(0xFF2E7D32), // Green 800
            route: AppRouteName.fitnessMenu,
            delay: 300,
          ),
          const SizedBox(height: 20),
          _buildExtraTile(
            context,
            title: 'Generator Raportów',
            description: 'Twórz profesjonalne raporty i notatki z pomocą AI.',
            icon: Icons.description_outlined,
            color: const Color(0xFFF57C00), // Orange 700
            route: AppRouteName.reportTemplateSelector,
            delay: 400,
          ),
        ],
      ),
    );
  }

  Widget _buildExtraTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
    required int delay,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(route),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        color.withOpacity(0.7),
                        color.withOpacity(0.3),
                      ]
                    : [
                        color,
                        color.withOpacity(0.85),
                      ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative background circle
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Icon Container
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                height: 1.3,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Arrow
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.1, end: 0);
  }
}

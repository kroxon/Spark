import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/navigation/routes.dart';
import 'package:flutter_animate/flutter_animate.dart';

class KppMenuPage extends StatelessWidget {
  const KppMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Nauka KPP'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.blueGrey.shade900, Colors.blue.shade900]
                        : [Colors.blue.shade50, Colors.white],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.medical_services_outlined,
                        size: 160,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildMenuCard(
                    context,
                    title: 'Fiszki',
                    description: 'Przeglądaj pytania i sprawdzaj swoją wiedzę.',
                    icon: Icons.style_rounded,
                    color: Colors.blueAccent,
                    gradientColors: [Colors.blueAccent, Colors.lightBlueAccent],
                    onTap: () => context.pushNamed(AppRouteName.kppFlashcards),
                    delay: 200.ms,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    context,
                    title: 'Test (Wkrótce)',
                    description: 'Symulacja egzaminu z losowymi pytaniami.',
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                    gradientColors: [Colors.orange, Colors.deepOrangeAccent],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tryb testowy będzie dostępny wkrótce!')),
                      );
                    },
                    delay: 400.ms,
                    isLocked: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required Duration delay,
    bool isLocked = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLocked ? [Colors.grey.shade400, Colors.grey.shade600] : gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isLocked ? Colors.grey : color).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isLocked ? theme.colorScheme.onSurface.withOpacity(0.5) : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(isLocked ? 0.5 : 1),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: delay).fadeIn().slideY(begin: 0.2, end: 0);
  }
}

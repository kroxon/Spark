import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dashed_ring_painter.dart';
import 'modern_progress_painter.dart';

class BeepTestPlayer extends StatelessWidget {
  final bool isExpanded;
  final bool isPlaying;
  final int playerLevel;
  final int playerShuttle;
  final double currentShuttleElapsed;
  final double currentShuttleDuration;
  final double totalElapsedTime;
  final double globalProgress;
  final int totalTestShuttles;
  final int totalDistance;
  final double currentSpeed;
  final bool autoSyncResult;
  final VoidCallback onToggleExpand;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onReset;
  final VoidCallback onNextShuttle;
  final Function(double) onSeek;
  final Function(bool) onAutoSyncChanged;

  const BeepTestPlayer({
    super.key,
    required this.isExpanded,
    required this.isPlaying,
    required this.playerLevel,
    required this.playerShuttle,
    required this.currentShuttleElapsed,
    required this.currentShuttleDuration,
    required this.totalElapsedTime,
    required this.globalProgress,
    required this.totalTestShuttles,
    required this.totalDistance,
    required this.currentSpeed,
    required this.autoSyncResult,
    required this.onToggleExpand,
    required this.onTogglePlayPause,
    required this.onReset,
    required this.onNextShuttle,
    required this.onSeek,
    required this.onAutoSyncChanged,
  });

  String _formatTime(double totalSeconds) {
    if (totalSeconds < 0) return "00:00";
    int minutes = totalSeconds ~/ 60;
    int seconds = (totalSeconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final progress = (currentShuttleElapsed / currentShuttleDuration).clamp(0.0, 1.0);
    
    // Height calculation
    final height = isExpanded ? 700.0 + bottomPadding : 100.0;

    // Dynamic colors
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final accentColor = theme.primaryColor;
    
    // Gradient for "standing out"
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark 
          ? [const Color(0xFF2C2C2C).withOpacity(0.98), const Color(0xFF1A1A1A).withOpacity(0.99)]
          : [Colors.white.withOpacity(0.98), const Color(0xFFF5F5F5).withOpacity(0.99)],
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuint,
      left: isExpanded ? 0 : 16,
      right: isExpanded ? 0 : 16,
      bottom: isExpanded ? 0 : (bottomPadding + 16),
      height: height,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            if (!isExpanded) onToggleExpand();
          } else if (details.primaryVelocity! > 0) {
            if (isExpanded) onToggleExpand();
          }
        },
        onTap: isExpanded ? null : onToggleExpand,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(32),
            bottom: Radius.circular(isExpanded ? 0 : 32),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(32),
                  bottom: Radius.circular(isExpanded ? 0 : 32),
                ),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subTextColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  if (!isExpanded) 
                    _buildCollapsedView(context, progress, textColor, subTextColor, accentColor),
                  if (isExpanded) 
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 650,
                          child: _buildExpandedView(context, progress, textColor, subTextColor, accentColor, isDark),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedView(BuildContext context, double progress, Color textColor, Color subTextColor, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "POZIOM $playerLevel",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      "ODCINEK $playerShuttle",
                      style: TextStyle(
                        color: subTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text("•", style: TextStyle(color: subTextColor)),
                    ),
                    Text(
                      _formatTime(totalElapsedTime),
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildPlayButton(size: 48, accentColor: accentColor, isPlaying: isPlaying),
              const SizedBox(width: 24),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleExpand,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: subTextColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: subTextColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildExpandedView(BuildContext context, double progress, Color textColor, Color subTextColor, Color accentColor, bool isDark) {
    return Column(
      children: [
        // Header with Collapse Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Auto-save Toggle (Subtle & Professional)
              GestureDetector(
                onTap: () => onAutoSyncChanged(!autoSyncResult),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: autoSyncResult ? accentColor.withOpacity(0.1) : subTextColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: autoSyncResult ? accentColor.withOpacity(0.2) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        autoSyncResult ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 14,
                        color: autoSyncResult ? accentColor : subTextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Auto-zapis",
                        style: TextStyle(
                          color: autoSyncResult ? accentColor : subTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleExpand,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor, size: 32),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Main Circular Timer
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Pulsing Aura (Background)
                      Animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                        effects: [
                          ScaleEffect(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut),
                          FadeEffect(begin: 0.5, end: 0.8, duration: 2000.ms),
                        ],
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.15),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Rotating Decorative Ring
                      Animate(
                        onPlay: (controller) => controller.repeat(),
                        effects: [
                          RotateEffect(begin: 0, end: 1, duration: 10.seconds, curve: Curves.linear),
                        ],
                        child: Container(
                          width: 290,
                          height: 290,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: subTextColor.withOpacity(0.05),
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: CustomPaint(
                            painter: DashedRingPainter(color: subTextColor.withOpacity(0.1)),
                          ),
                        ),
                      ),

                      // 3. Main Progress Painter
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return CustomPaint(
                            size: const Size(260, 260),
                            painter: ModernProgressPainter(
                              progress: value,
                              color: accentColor,
                              trackColor: subTextColor.withOpacity(0.05),
                              strokeWidth: 22,
                            ),
                          );
                        },
                      ),

                      // 4. Inner Content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "POZIOM",
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$playerLevel",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 84,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: -2,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              "ODCINEK $playerShuttle",
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                // Slider
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accentColor,
                        inactiveTrackColor: subTextColor.withOpacity(0.1),
                        thumbColor: textColor,
                        overlayColor: accentColor.withOpacity(0.2),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      ),
                      child: Slider(
                        value: globalProgress.clamp(0.0, totalTestShuttles.toDouble()),
                        min: 0.0,
                        max: totalTestShuttles.toDouble(),
                        onChanged: onSeek,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Start', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            '${(globalProgress / totalTestShuttles * 100).toInt()}%',
                            style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text('Koniec', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                // Stats Grid
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: subTextColor.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("DYSTANS", "$totalDistance", "m", textColor, subTextColor),
                      Container(width: 1, height: 40, color: subTextColor.withOpacity(0.1)),
                      _buildStatItem("CZAS", _formatTime(totalElapsedTime), "", textColor, subTextColor),
                      Container(width: 1, height: 40, color: subTextColor.withOpacity(0.1)),
                      _buildStatItem("PRĘDKOŚĆ", currentSpeed.toStringAsFixed(1), "km/h", textColor, subTextColor),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, end: 0, delay: 100.ms),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleButton(
                      icon: Icons.refresh_rounded,
                      onTap: onReset,
                      color: subTextColor.withOpacity(0.1),
                      iconColor: textColor,
                    ),
                    _buildPlayButton(size: 88, isLarge: true, accentColor: accentColor, isPlaying: isPlaying),
                    _buildCircleButton(
                      icon: Icons.skip_next_rounded,
                      onTap: onNextShuttle,
                      color: subTextColor.withOpacity(0.1),
                      iconColor: textColor,
                    ),
                  ],
                ).animate().slideY(begin: 0.2, end: 0, delay: 200.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                " $unit",
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
      ),
    );
  }

  Widget _buildPlayButton({
    double size = 60, 
    bool isLarge = false, 
    required Color accentColor,
    required bool isPlaying,
  }) {
    return GestureDetector(
      onTap: onTogglePlayPause,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              blurRadius: isPlaying ? 10 : 20,
              spreadRadius: isPlaying ? 0 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

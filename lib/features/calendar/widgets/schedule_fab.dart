import 'package:flutter/material.dart';
import 'package:iskra/features/calendar/widgets/vacation_dialog.dart';
import 'package:iskra/features/calendar/widgets/sick_leave_dialog.dart';

class ScheduleFab extends StatefulWidget {
  const ScheduleFab({
    super.key,
    required this.onScheduleEditToggle,
    required this.isEditing,
  });

  final VoidCallback onScheduleEditToggle;
  final bool isEditing;

  @override
  State<ScheduleFab> createState() => _ScheduleFabState();
}

class _ScheduleFabState extends State<ScheduleFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fab1Anim;
  late Animation<double> _fab2Anim;
  late Animation<double> _fab3Anim;
  late Animation<double> _rotationAnim;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    // Use a single controller and derive staggered animations for each child FAB.
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Staggered intervals: slightly offset to create progressive appearance.
    _fab1Anim = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _fab2Anim = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.12, 0.82, curve: Curves.easeOut),
    );
    _fab3Anim = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.24, 0.94, curve: Curves.easeOut),
    );

    // Rotation for the main FAB: small rotation when open.
    _rotationAnim = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant ScheduleFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing && oldWidget.isEditing) {
      _resetFabState();
    }
  }

  void _resetFabState() {
    setState(() {
      _isOpen = false;
    });
    _animationController.reverse();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onVacationPressed() {
    _toggleFab();
    VacationDialog.show(context: context);
  }

  void _onSchedulePressed() {
    _toggleFab();
    widget.onScheduleEditToggle();
  }

  void _onSickLeavePressed() {
    _toggleFab();
    SickLeaveDialog.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.isEditing) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFab,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

          Positioned(
            bottom: 80, // 8 (main FAB position) + 72 (FAB height + spacing)
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FadeTransition(
                  opacity: _fab1Anim,
                  child: ScaleTransition(
                    scale: _fab1Anim,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 50), // Align left edge with longest FAB
                      child: FloatingActionButton.extended(
                        heroTag: 'vacation',
                        onPressed: _onVacationPressed,
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        tooltip: 'Dodaj urlop',
                        elevation: 8,
                        extendedPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        label: const Text(
                          'Urlop',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(Icons.beach_access, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _fab2Anim,
                  child: ScaleTransition(
                    scale: _fab2Anim,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FloatingActionButton.extended(
                        heroTag: 'schedule',
                        onPressed: _onSchedulePressed,
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        tooltip: 'Harmonogram',
                        elevation: 8,
                        extendedPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        label: const Text(
                          'Harmonogram',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _fab3Anim,
                  child: ScaleTransition(
                    scale: _fab3Anim,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 15), // Align left edge with longest FAB
                      child: FloatingActionButton.extended(
                        heroTag: 'sick_leave',
                        onPressed: _onSickLeavePressed,
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        tooltip: 'Dodaj zwolnienie',
                        elevation: 8,
                        extendedPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        label: const Text(
                          'Zwolnienie',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        icon: const Icon(Icons.medical_services, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 8, // 8px above bottom navigation
            right: 16,
            child: FloatingActionButton(
              onPressed: _toggleFab,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 8,
              child: RotationTransition(
                turns: _rotationAnim,
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
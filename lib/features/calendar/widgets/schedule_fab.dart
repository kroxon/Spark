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
  with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fab1Anim;
  late Animation<double> _fab2Anim;
  late Animation<double> _fab3Anim;
  late Animation<Offset> _fab1Slide;
  late Animation<Offset> _fab2Slide;
  late Animation<Offset> _fab3Slide;
  late Animation<double> _rotationAnim;
  // Controller used for fast, simultaneous collapse of the child FABs.
  late AnimationController _collapseController;
  late Animation<double> _collapseOpacity;
  late Animation<Offset> _collapseSlide;
  late Animation<double> _rotationCollapseAnim;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    // Use a single controller and derive staggered animations for each child FAB.
    // Shorter duration for a snappier feel (was 1000ms)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Collapse controller runs faster (half the open duration) and drives
    // simultaneous collapse for all three FABs.
    _collapseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Staggered intervals: bottom-most FAB appears first, then middle, then top.
    // We reverse the interval ordering relative to the Column child order so
    // the lowest FAB slides up first (more natural "drawer from bottom" feeling).
    _fab1Anim = CurvedAnimation(
      parent: _animationController,
      // top-most FAB: animate last
      curve: const Interval(0.24, 0.94, curve: Curves.easeOut),
    );
    _fab2Anim = CurvedAnimation(
      parent: _animationController,
      // middle FAB: animate middle
      curve: const Interval(0.12, 0.82, curve: Curves.easeOut),
    );
    _fab3Anim = CurvedAnimation(
      parent: _animationController,
      // bottom-most FAB: animate first
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    // Create slide animations (from below) derived from the double-valued
    // curved animations. We don't use scaling — the FABs will slide up.
    _fab1Slide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(_fab1Anim);
    _fab2Slide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(_fab2Anim);
    _fab3Slide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(_fab3Anim);

    // Collapse animations (same for all FABs) — they run simultaneously
    // when the user closes the FAB menu.
    _collapseOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut),
    );
    _collapseSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.6)).animate(
      CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut),
    );

    // Rotation for the main FAB: complete 4× faster than the full controller
    // timeline by ending at 1/4 of the controller's progress. This makes the
    // rotation feel snappier while the child FABs continue their stagger.
    _rotationAnim = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.25, curve: Curves.easeInOut)),
    );

    // A fast rotation animation used while collapsing so the main FAB rotates
    // back at the same (fast) pace as the collapse controller.
    _rotationCollapseAnim = Tween<double>(begin: 0.125, end: 0.0).animate(
      CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut),
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
    // Reset both controllers to initial state.
    _animationController.value = 0.0;
    _collapseController.value = 0.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    if (!_isOpen) {
      // Opening: run the staggered open animation.
      setState(() => _isOpen = true);
      _collapseController.reset();
      _animationController.forward();
    } else {
      // Closing: run a fast, simultaneous collapse driven by the collapse
      // controller (2× faster than opening). After collapse finishes we
      // immediately reset the open controller to 0 so next open starts clean.
      _collapseController.forward(from: 0.0).then((_) {
        _animationController.value = 0.0;
        _collapseController.value = 0.0;
        setState(() => _isOpen = false);
      });
    }
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
                AnimatedBuilder(
                  animation: Listenable.merge([_animationController, _collapseController]),
                  builder: (context, child) {
                    final collapsing = _collapseController.status == AnimationStatus.forward || _collapseController.value > 0.0;
                    final opacity = collapsing ? _collapseOpacity.value : _fab1Anim.value;
                    final offset = collapsing ? _collapseSlide.value : _fab1Slide.value;
                    return Opacity(
                      opacity: opacity,
                      child: FractionalTranslation(
                        translation: offset,
                        child: child,
                      ),
                    );
                  },
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
                      // Show both umbrella and tree icons (parasolka i drzewo)
                      icon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.beach_access, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Icon(Icons.park, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),

                AnimatedBuilder(
                  animation: Listenable.merge([_animationController, _collapseController]),
                  builder: (context, child) {
                    final collapsing = _collapseController.status == AnimationStatus.forward || _collapseController.value > 0.0;
                    final opacity = collapsing ? _collapseOpacity.value : _fab2Anim.value;
                    final offset = collapsing ? _collapseSlide.value : _fab2Slide.value;
                    return Opacity(
                      opacity: opacity,
                      child: FractionalTranslation(
                        translation: offset,
                        child: child,
                      ),
                    );
                  },
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

                AnimatedBuilder(
                  animation: Listenable.merge([_animationController, _collapseController]),
                  builder: (context, child) {
                    final collapsing = _collapseController.status == AnimationStatus.forward || _collapseController.value > 0.0;
                    final opacity = collapsing ? _collapseOpacity.value : _fab3Anim.value;
                    final offset = collapsing ? _collapseSlide.value : _fab3Slide.value;
                    return Opacity(
                      opacity: opacity,
                      child: FractionalTranslation(
                        translation: offset,
                        child: child,
                      ),
                    );
                  },
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
              child: AnimatedBuilder(
                animation: Listenable.merge([_animationController, _collapseController]),
                builder: (context, child) {
                  final collapsing = _collapseController.status == AnimationStatus.forward || _collapseController.value > 0.0;
                  final turns = collapsing ? _rotationCollapseAnim.value : _rotationAnim.value;
                  return RotationTransition(
                    turns: AlwaysStoppedAnimation(turns),
                    child: child,
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
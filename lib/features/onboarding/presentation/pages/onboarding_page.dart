import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/core/navigation/routes.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Shift selection
  int? _selectedShiftId;

  // Step 2: Vacation hours
  final TextEditingController _standardVacationController = TextEditingController(text: '208');
  final TextEditingController _additionalVacationController = TextEditingController(text: '104');

  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _standardVacationController.dispose();
    _additionalVacationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_selectedShiftId == null) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(userProfileRepositoryProvider);
      final currentYear = DateTime.now().year;

      // Add shift assignment
      await repository.addShiftAssignment(
        uid: user.uid,
        shiftId: _selectedShiftId!,
        startDate: DateTime(currentYear, 1, 1),
      );

      // Update vacation hours
      final standardHours = double.tryParse(_standardVacationController.text) ?? 208;
      final additionalHours = double.tryParse(_additionalVacationController.text) ?? 104;
      await repository.updateVacationHours(
        uid: user.uid,
        standardVacationHours: standardHours,
        additionalVacationHours: additionalHours,
      );

      if (mounted) {
        context.go(AppRoutePath.schedule);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas zapisywania: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 2,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _ShiftSelectionStep(
                    selectedShiftId: _selectedShiftId,
                    onShiftSelected: (shiftId) => setState(() => _selectedShiftId = shiftId),
                  ),
                  _VacationHoursStep(
                    standardController: _standardVacationController,
                    additionalController: _additionalVacationController,
                  ),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Wstecz'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _currentPage == 0
                          ? (_selectedShiftId != null ? _nextPage : null)
                          : (_isSaving ? null : _completeOnboarding),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_currentPage == 0 ? 'Dalej' : 'Zakończ'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftSelectionStep extends StatelessWidget {
  const _ShiftSelectionStep({
    required this.selectedShiftId,
    required this.onShiftSelected,
  });

  final int? selectedShiftId;
  final ValueChanged<int> onShiftSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wybierz swoją zmianę',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wybierz numer zmiany, do której jesteś przypisany. To określi Twoje harmonogramy i statystyki.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          ...[1, 2, 3].map((shiftId) => _ShiftOption(
                shiftId: shiftId,
                isSelected: selectedShiftId == shiftId,
                onTap: () => onShiftSelected(shiftId),
              )),
        ],
      ),
    );
  }
}

class _ShiftOption extends StatelessWidget {
  const _ShiftOption({
    required this.shiftId,
    required this.isSelected,
    required this.onTap,
  });

  final int shiftId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getShiftColor(shiftId),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    shiftId.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zmiana $shiftId',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getShiftDescription(shiftId),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getShiftColor(int shiftId) {
    switch (shiftId) {
      case 1:
        return const Color(0xFF1E88E5); // Blue
      case 2:
        return const Color(0xFF43A047); // Green
      case 3:
        return const Color(0xFFF4511E); // Orange
      default:
        return Colors.grey;
    }
  }

  String _getShiftDescription(int shiftId) {
    switch (shiftId) {
      case 1:
        return 'Pierwsza zmiana';
      case 2:
        return 'Druga zmiana';
      case 3:
        return 'Trzecia zmiana';
      default:
        return '';
    }
  }
}

class _VacationHoursStep extends StatelessWidget {
  const _VacationHoursStep({
    required this.standardController,
    required this.additionalController,
  });

  final TextEditingController standardController;
  final TextEditingController additionalController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ustaw saldo urlopów',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wprowadź liczbę godzin urlopów wypoczynkowych i dodatkowych. Możesz to zmienić później w ustawieniach.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: standardController,
            decoration: const InputDecoration(
              labelText: 'Urlop wypoczynkowy (godziny)',
              hintText: 'np. 208',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: additionalController,
            decoration: const InputDecoration(
              labelText: 'Urlop dodatkowy (godziny)',
              hintText: 'np. 104',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
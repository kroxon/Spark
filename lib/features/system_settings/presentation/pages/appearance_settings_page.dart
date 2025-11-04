import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_color_picker_wheel/flutter_color_picker_wheel.dart';
import 'package:flutter_color_picker_wheel/models/button_behaviour.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/core/theme/theme_mode_controller.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/application/calendar_indicator_settings_controller.dart';
import 'package:iskra/features/system_settings/presentation/widgets/overtime_indicator_settings_card.dart';
import 'package:iskra/features/system_settings/presentation/widgets/theme_mode_switch_card.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';

class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  ConsumerState<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends ConsumerState<AppearanceSettingsPage> {
  bool _isUpdatingTheme = false;
  bool _isSavingOvertimeThreshold = false;
  double? _overtimeThresholdDraft;
  int _selectedShift = 1;

  Future<void> _onThemeChanged(BuildContext context, bool isEnabled) async {
    if (_isUpdatingTheme) return;

    setState(() => _isUpdatingTheme = true);
    try {
      final controller = ref.read(themePreferencesControllerProvider);
      await controller.setThemeMode(isEnabled ? ThemeMode.dark : ThemeMode.light);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać motywu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingTheme = false);
    }
  }

  Future<void> _onSaveOvertimeThreshold(BuildContext context, double hours) async {
    if (_isSavingOvertimeThreshold) return;

    setState(() => _isSavingOvertimeThreshold = true);
    try {
      final controller = ref.read(calendarIndicatorSettingsControllerProvider);
      await controller.setOvertimeIndicatorThreshold(hours);
      if (mounted) setState(() => _overtimeThresholdDraft = hours);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zapisano próg dla wskaźnika służby.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać progu: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingOvertimeThreshold = false);
    }
  }

  void _showShiftColorsStudio(BuildContext context) {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) return;

  final profile = ref.read(userProfileProvider(UserProfileRequest(uid: currentUser.uid, email: currentUser.email))).value;

    // Always start with Shift 1 selected and build a local draft palette (not persisted until Save)
    _selectedShift = 1;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);

        Color currentColorForShift(int id) {
          final p = profile;
          if (p == null) return ShiftColorPalette.defaults.colorForShift(id);
          return p.shiftColorPalette.colorForShift(id);
        }

        // Local drafts for all 3 shifts; modified only in-dialog
        final drafts = <int, Color>{
          1: currentColorForShift(1),
          2: currentColorForShift(2),
          3: currentColorForShift(3),
        };

        return StatefulBuilder(
          builder: (context, setModalState) {
            final selected = _selectedShift;

            void updateDraft(Color c) {
              setModalState(() => drafts[selected] = c);
            }

            Future<void> saveDraft() async {
              final uid = currentUser.uid;
              final repo = ref.read(userProfileRepositoryProvider);
              await repo.updateShiftColorPalette(
                uid: uid,
                shift1: drafts[1]!.value,
                shift2: drafts[2]!.value,
                shift3: drafts[3]!.value,
              );
              if (mounted) Navigator.of(context).pop();
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Kolory zmian', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Shift selector and current colors
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final chips = [
                              for (final id in [1, 2, 3])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    selected: selected == id,
                                    onSelected: (_) => setModalState(() {
                                      _selectedShift = id;
                                    }),
                                    label: Text('Zmiana $id'),
                                  ),
                                ),
                            ];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(children: chips),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        for (final id in [1, 2, 3])
                                          CircleAvatar(radius: 10, backgroundColor: drafts[id]!),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Wheel color picker
                        Text('Koło kolorów', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final innerRadius = maxW < 380 ? 80.0 : 100.0;
                            final pieceHeight = maxW < 380 ? 18.0 : 22.0;
                            final buttonSize = maxW < 380 ? 44.0 : 52.0;
                            return Center(
                              child: WheelColorPicker(
                                key: ValueKey('wheel-${selected}-${drafts[selected]!.value}'),
                                onSelect: (Color newColor) => updateDraft(newColor),
                                behaviour: ButtonBehaviour.clickToOpen,
                                defaultColor: drafts[selected]!,
                                animationConfig: fanLikeAnimationConfig,
                                colorList: simpleColors,
                                buttonSize: buttonSize,
                                pieceHeight: pieceHeight,
                                innerRadius: innerRadius,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  drafts[1] = ShiftColorPalette.defaults.colorForShift(1);
                                  drafts[2] = ShiftColorPalette.defaults.colorForShift(2);
                                  drafts[3] = ShiftColorPalette.defaults.colorForShift(3);
                                });
                              },
                              child: const Text('Resetuj'),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Anuluj'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: () => saveDraft(),
                              child: const Text('Zapisz'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
  final user = ref.watch(firebaseAuthProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wygląd'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemeModeSwitchCard(
                isDarkMode: isDarkMode,
                isUpdating: _isUpdatingTheme,
                onChanged: (value) => _onThemeChanged(context, value),
              ),
              const SizedBox(height: 12),
              _ShiftColorsCard(onOpenConfigurator: () => _showShiftColorsStudio(context)),
              const SizedBox(height: 12),
              if (user != null)
                Builder(
                  builder: (context) {
                    final profileAsync = ref.watch(
                      userProfileProvider(
                        UserProfileRequest(uid: user.uid, email: user.email),
                      ),
                    );

                    return profileAsync.when(
                      data: (profile) => OvertimeIndicatorSettingsCard(
                        currentThreshold: profile.overtimeIndicatorThresholdHours,
                        draftThreshold: _overtimeThresholdDraft,
                        isSaving: _isSavingOvertimeThreshold,
                        onDraftChanged: (value) => setState(() => _overtimeThresholdDraft = value),
                        onSavePressed: (hours) => _onSaveOvertimeThreshold(context, hours),
                      ),
                      loading: () => const Card(
                        elevation: 1,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (error, _) => Card(
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nie udało się załadować ustawień wskaźnika.',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$error',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftColorsCard extends StatelessWidget {
  const _ShiftColorsCard({required this.onOpenConfigurator});
  final VoidCallback onOpenConfigurator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text('Kolory zmian', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Personalizuj kolory dla różnych typów zmian w kalendarzu.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onOpenConfigurator,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Otwórz konfigurator'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Removed legacy HSV sliders in favor of the WheelColorPicker

// Removed preview tile widget per request

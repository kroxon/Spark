import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_color_picker_wheel/flutter_color_picker_wheel.dart';
import 'package:flutter_color_picker_wheel/models/button_behaviour.dart';
import 'package:iskra/core/firebase/firebase_providers.dart';
import 'package:iskra/core/theme/theme_mode_controller.dart';
import 'package:iskra/features/auth/data/user_profile_repository.dart';
import 'package:iskra/features/calendar/application/calendar_indicator_settings_controller.dart';
import 'package:iskra/features/calendar/widgets/on_duty_indicator.dart';
import 'package:iskra/features/system_settings/presentation/widgets/overtime_indicator_settings_card.dart';
import 'package:iskra/features/system_settings/presentation/widgets/theme_mode_switch_card.dart';
import 'package:iskra/features/system_settings/presentation/widgets/app_theme_selector_card.dart';
import 'package:iskra/features/calendar/models/shift_color_palette.dart';
import 'package:iskra/core/theme/app_theme_type.dart';

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
  Color? _indicatorDraft;

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

  Future<void> _onAppThemeChanged(BuildContext context, AppThemeType theme) async {
    if (_isUpdatingTheme) return;

    setState(() => _isUpdatingTheme = true);
    try {
      final controller = ref.read(themePreferencesControllerProvider);
      await controller.setAppTheme(theme);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się zapisać motywu aplikacji: $error'),
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
                            Color textOn(Color bg) =>
                                bg.computeLuminance() < 0.5 ? Colors.white : Colors.black;

                            // Responsive sizing presets based on available width
                            final double w = constraints.maxWidth;
                            final bool compact = w < 340;
                            final bool spacious = w > 560;
                            // Further reduce internal paddings
                            final double padH = compact ? 4 : (spacious ? 8 : 6);
                            final double padV = compact ? 2 : (spacious ? 4 : 3);
                            // External spacing only used in scroll (fallback) layout
                            final double outerGap = compact ? 14 : (spacious ? 22 : 18);
                            final double borderR = compact ? 10 : 12;

                            Widget chip(int id) {
                              final isSel = selected == id;
                              final base = drafts[id]!;
                              // Same intensity for all chips; selection is expressed by size only
                              final chipBg = base.withValues(alpha: 0.80);
                              final txtStyle = theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: textOn(chipBg),
                              );
                              final double padHX = (padH - 2).clamp(2, 24).toDouble();
                              final double padVX = (padV - 2).clamp(1, 16).toDouble();
                              return AnimatedScale(
                                // Active is 25% larger than inactive
                                scale: isSel ? 1.25 : 1.0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                child: RawChip(
                                  selected: isSel,
                                  onSelected: (_) => setModalState(() {
                                    _selectedShift = id;
                                  }),
                                  showCheckmark: false,
                                  label: Text('Zmiana $id', style: txtStyle),
                                  backgroundColor: chipBg,
                                  selectedColor: chipBg,
                                  padding: EdgeInsets.symmetric(horizontal: padHX, vertical: padVX),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(borderR),
                                    side: BorderSide(
                                      color: isSel
                                          ? theme.colorScheme.outline
                                          : theme.colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Keep chips side-by-side. If they don't fit, allow horizontal scroll;
                            // if they do fit, spread them evenly.
                            const double minChipWidth = 100;
                            final double minTotal = minChipWidth * 3 + 2 * 8; // including gaps
                            final bool canFit = w >= minTotal;

                            final Widget chipLine = canFit
                                ? Row(
                                    children: [
                                      Expanded(child: Center(child: chip(1))),
                                      Expanded(child: Center(child: chip(2))),
                                      Expanded(child: Center(child: chip(3))),
                                    ],
                                  )
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        chip(1),
                                        SizedBox(width: outerGap),
                                        chip(2),
                                        SizedBox(width: outerGap),
                                        chip(3),
                                      ],
                                    ),
                                  );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                chipLine,
                                const SizedBox(height: 4),
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

  void _showIndicatorColorStudio(BuildContext context) {
    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) return;

    final profile = ref
        .read(
          userProfileProvider(
            UserProfileRequest(uid: currentUser.uid, email: currentUser.email),
          ),
        )
        .value;

    final initial = profile?.onDutyIndicatorColor ?? Colors.yellow.shade400;
    _indicatorDraft = initial;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);

        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveDraft() async {
              if (_indicatorDraft == null) return;
              final uid = currentUser.uid;
              final repo = ref.read(userProfileRepositoryProvider);
              await repo.updateOnDutyIndicatorColor(
                uid: uid,
                color: _indicatorDraft!.value,
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
                            Text(
                              'Kolor wskaźnika służby',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Wybierz kolor poświaty wskaźnika na kafelkach kalendarza.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth;
                            final innerRadius = maxW < 380 ? 80.0 : 100.0;
                            final pieceHeight = maxW < 380 ? 18.0 : 22.0;
                            final buttonSize = maxW < 380 ? 44.0 : 52.0;
                            return Center(
                              child: WheelColorPicker(
                                key: ValueKey('wheel-indicator-${_indicatorDraft?.value}'),
                                onSelect: (Color newColor) => setModalState(() => _indicatorDraft = newColor),
                                behaviour: ButtonBehaviour.clickToOpen,
                                defaultColor: _indicatorDraft ?? initial,
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
                                  _indicatorDraft = Colors.yellow.shade400;
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
    final appTheme = ref.watch(appThemeProvider);
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
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              AppThemeSelectorCard(
                currentTheme: appTheme,
                onThemeSelected: (value) => _onAppThemeChanged(context, value),
                isUpdating: _isUpdatingTheme,
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _ShiftColorsCard(onOpenConfigurator: () => _showShiftColorsStudio(context)),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (user != null)
                Builder(
                  builder: (context) {
                    final profileAsync = ref.watch(
                      userProfileProvider(
                        UserProfileRequest(uid: user.uid, email: user.email),
                      ),
                    );

                    return profileAsync.when(
                      data: (profile) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OvertimeIndicatorSettingsCard(
                            currentThreshold: profile.overtimeIndicatorThresholdHours,
                            draftThreshold: _overtimeThresholdDraft,
                            isSaving: _isSavingOvertimeThreshold,
                            onDraftChanged: (value) => setState(() => _overtimeThresholdDraft = value),
                            onSavePressed: (hours) => _onSaveOvertimeThreshold(context, hours),
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          _IndicatorColorSettingsCard(
                            currentColor: profile.onDutyIndicatorColor,
                            onEdit: () => _showIndicatorColorStudio(context),
                          ),
                        ],
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

class _ShiftColorsCard extends ConsumerWidget {
  const _ShiftColorsCard({required this.onOpenConfigurator});
  final VoidCallback onOpenConfigurator;

  Color _textOn(Color bg) => bg.computeLuminance() < 0.5 ? Colors.white : Colors.black;

  Widget _indicator(Color color, String label, ThemeData theme) {
    return Container(
      width: 33, // +50% size
      height: 33, // +50% size
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12, // keep label size unchanged
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: _textOn(color),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(firebaseAuthProvider).currentUser;

    ShiftColorPalette palette = ShiftColorPalette.defaults;
    if (user != null) {
      final profileAsync = ref.watch(
        userProfileProvider(UserProfileRequest(uid: user.uid, email: user.email)),
      );
      palette = profileAsync.maybeWhen(
        data: (p) => p.shiftColorPalette,
        orElse: () => ShiftColorPalette.defaults,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kolory zmian', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Personalizuj kolory dla różnych typów zmian w kalendarzu.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _indicator(palette.shift1, '1', theme),
                  _indicator(palette.shift2, '2', theme),
                  _indicator(palette.shift3, '3', theme),
                ],
              ),
              OutlinedButton(
                onPressed: onOpenConfigurator,
                child: const Text('Otwórz konfigurator'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Removed legacy HSV sliders in favor of the WheelColorPicker

// Removed preview tile widget per request

class _IndicatorColorSettingsCard extends StatelessWidget {
  const _IndicatorColorSettingsCard({required this.currentColor, required this.onEdit});
  final Color currentColor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kolor wskaźnika służby', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Ustaw kolor poświaty kropki w dniu służby.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OnDutyIndicator(
                iconSize: 22,
                glowColor: currentColor.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.4 : 0.75,
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Edytuj'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

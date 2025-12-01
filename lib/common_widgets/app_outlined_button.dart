import 'package:flutter/material.dart';
import 'package:iskra/core/theme/app_colors.dart';

/// Outlined button variant with burgundy accents.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveOnPressed = isLoading ? null : onPressed;
    final style = OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.85),
    );

    final Widget labelWidget = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          )
        : Text(
            label,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
          );

    if (icon != null && !isLoading) {
      return OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: icon!,
        label: labelWidget,
      );
    }

    return OutlinedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: labelWidget,
    );
  }
}

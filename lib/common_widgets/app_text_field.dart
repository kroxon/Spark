import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iskra/core/theme/app_colors.dart';

/// Standard text form field with the project-wide burgundy styling.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.enableObscureToggle = false,
    this.prefixIcon,
    this.suffixIcon,
    this.autocorrect,
    this.enableSuggestions,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool enableObscureToggle;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  Timer? _relockTimer;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void dispose() {
    _relockTimer?.cancel();
    super.dispose();
  }

  void _toggleVisibility() {
    _relockTimer?.cancel();
    setState(() {
      _obscureText = !_obscureText;
    });
    if (!_obscureText) {
      _relockTimer = Timer(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _obscureText = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool shouldShowToggle = widget.enableObscureToggle && widget.obscureText;

    final baseDecoration = InputDecoration(
      labelText: widget.label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      prefixIcon: widget.prefixIcon != null
          ? Icon(widget.prefixIcon, color: AppColors.primary)
          : null,
      suffixIcon: shouldShowToggle
          ? IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.primary,
              ),
              onPressed: _toggleVisibility,
              tooltip: _obscureText ? 'Pokaż hasło' : 'Ukryj hasło',
            )
          : widget.suffixIcon,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
      ),
    );

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      obscureText: widget.obscureText ? _obscureText : false,
      autocorrect: widget.autocorrect ?? true,
      enableSuggestions: widget.enableSuggestions ?? true,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: baseDecoration,
    );
  }
}

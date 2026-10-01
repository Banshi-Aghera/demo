import 'package:flutter/material.dart';

/// Full-width filled button with a built-in loading state.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Text(label);

    if (icon != null && !loading) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      );
    }
    return FilledButton(onPressed: loading ? null : onPressed, child: child);
  }
}

/// Outlined variant with the same loading behaviour.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const OutlinedButton(
        onPressed: null,
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon!,
        label: Text(label),
      );
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

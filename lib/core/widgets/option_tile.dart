import 'package:flutter/material.dart';

/// Radio-style choice row. Version-proof alternative to RadioListTile.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Null disables the row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.5,
        child: ListTile(
          minTileHeight: 64,
          onTap: onTap,
          leading: Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: icon == null ? null : Icon(icon, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

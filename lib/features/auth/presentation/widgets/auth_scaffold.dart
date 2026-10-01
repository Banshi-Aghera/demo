import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';

/// Shared layout for auth screens: centered, width-capped, scrollable,
/// with the logo, a title and a subtitle on top.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
    this.showLogo = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: Gap.l, vertical: Gap.l),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppConstants.maxFormWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AppLogo(size: 56),
                    ),
                    const SizedBox(height: Gap.l),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Gap.s),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.m),
          child: Text(label, style: TextStyle(color: color)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// "Already have an account? Log in" style row.
class AuthSwitchRow extends StatelessWidget {
  const AuthSwitchRow({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

/// Simple multicolour "G" so we don't need a bundled logo asset.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

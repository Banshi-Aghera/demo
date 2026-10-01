import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';

/// Page body with a width cap so wide desktop screens stay readable.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: Gap.m),
            child,
          ],
        ),
      ),
    );
  }
}

/// Standard loading / error / empty handling for admin lists.
class AdminAsyncList<T> extends StatelessWidget {
  const AdminAsyncList({
    super.key,
    required this.value,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.builder,
    required this.onRetry,
  });

  final AsyncValue<List<T>> value;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget Function(List<T> items) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(Gap.xl),
        child: CircularProgressIndicator(),
      )),
      error: (_, _) => EmptyState(
        icon: Icons.wifi_off_rounded,
        title: AppStrings.errGeneric,
        message: AppStrings.errNoInternet,
        actionLabel: AppStrings.retry,
        onAction: onRetry,
      ),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: emptyIcon,
              title: AppStrings.noResults,
              message: emptyMessage,
            )
          : builder(items),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
        ),
      );
}

/// Confirm dialog. Returns true when the user confirms.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 44),
            backgroundColor: destructive ? scheme.error : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Number field shared by the product and settings forms.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    this.allowDecimal = true,
    this.min = 0,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final String? suffix;
  final bool allowDecimal;
  final double min;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          suffixText: suffix,
        ),
        validator: validator ??
            (v) {
              final n = double.tryParse((v ?? '').trim());
              if (n == null) return AppStrings.errNumber;
              if (n < min) return AppStrings.errNumber;
              return null;
            },
      );
}

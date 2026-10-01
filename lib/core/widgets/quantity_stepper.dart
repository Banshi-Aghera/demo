import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_spacing.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.max,
    this.min = 1,
    this.busy = false,
  });

  final int value;
  final int min;
  final int? max;
  final bool busy;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDecrease = !busy && value > min;
    final canIncrease = !busy && (max == null || value < max!);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '-',
            constraints: const BoxConstraints.tightFor(
                width: Gap.tapTarget, height: Gap.tapTarget),
            icon: Icon(value <= 1 && min == 0
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded),
            onPressed: canDecrease ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: busy
                ? const Center(
                    child: SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : Text(
                    '$value',
                    semanticsLabel: '${AppStrings.quantity} $value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
          IconButton(
            tooltip: '+',
            constraints: const BoxConstraints.tightFor(
                width: Gap.tapTarget, height: Gap.tapTarget),
            icon: const Icon(Icons.add_rounded),
            onPressed: canIncrease ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

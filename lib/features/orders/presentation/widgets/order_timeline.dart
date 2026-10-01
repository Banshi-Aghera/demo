import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/app_order.dart';
import 'order_status.dart';

/// Vertical tracker: Placed → Packed → Shipped → Out for delivery →
/// Delivered, with Cancelled / Return steps when they apply.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});

  final AppOrder order;

  static const _track = [
    OrderStatus.placed,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[];
    final fmt = DateFormat('d MMM, h:mm a');

    if (order.status == OrderStatus.cancelled) {
      // Show the steps actually reached, then the cancellation.
      for (final s in _track) {
        final at = order.timeOf(s);
        if (at != null) steps.add(_Step(s, at, done: true));
      }
      steps.add(_Step(OrderStatus.cancelled, order.timeOf(OrderStatus.cancelled),
          done: true, terminal: true, note: order.cancelReason));
    } else if (order.status == OrderStatus.pendingPayment) {
      steps.add(_Step(OrderStatus.pendingPayment, order.createdAt, done: true, current: true));
      for (final s in _track) {
        steps.add(_Step(s, null, done: false));
      }
    } else {
      final reached = _reachedIndex(order.status);
      for (var i = 0; i < _track.length; i++) {
        steps.add(_Step(_track[i], order.timeOf(_track[i]),
            done: i <= reached, current: i == reached && reached < _track.length - 1));
      }
      if (order.status == OrderStatus.returnRequested || order.status == OrderStatus.returned) {
        steps.add(_Step(OrderStatus.returnRequested, order.timeOf(OrderStatus.returnRequested),
            done: true, current: order.status == OrderStatus.returnRequested));
        steps.add(_Step(OrderStatus.returned, order.timeOf(OrderStatus.returned),
            done: order.status == OrderStatus.returned));
      }
    }

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1, fmt: fmt),
      ],
    );
  }

  int _reachedIndex(OrderStatus s) {
    if (s == OrderStatus.returnRequested || s == OrderStatus.returned) {
      return _track.length - 1;
    }
    final i = _track.indexOf(s);
    return i < 0 ? 0 : i;
  }
}

class _Step {
  const _Step(this.status, this.at,
      {required this.done, this.current = false, this.terminal = false, this.note});
  final OrderStatus status;
  final DateTime? at;
  final bool done;
  final bool current;
  final bool terminal;
  final String? note;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast, required this.fmt});

  final _Step step;
  final bool isLast;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = step.terminal
        ? AppColors.danger
        : step.done
            ? scheme.primary
            : scheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: step.done ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: step.done
                      ? Icon(step.terminal ? Icons.close_rounded : Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: step.done ? color : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Gap.m),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Gap.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    orderStatusLabel(step.status),
                    style: TextStyle(
                      fontWeight: step.current || step.terminal ? FontWeight.w700 : FontWeight.w500,
                      color: step.done ? null : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (step.at != null)
                    Text(fmt.format(step.at!),
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  if (step.note != null && step.note!.isNotEmpty)
                    Text(step.note!,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../data/models/daily_stat.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dailyStatsProvider(_days));
    final pending = ref.watch(pendingOrdersCountProvider).value;
    final newUsers = ref.watch(newUsersCountProvider).value;
    final lowStock = ref.watch(lowStockProductsProvider);

    final list = stats.value ?? const <DailyStat>[];
    final today = list.isEmpty ? null : list.last;
    final totalOrders = list.fold<int>(0, (a, s) => a + s.orders);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(dailyStatsProvider)
          ..invalidate(pendingOrdersCountProvider)
          ..invalidate(newUsersCountProvider)
          ..invalidate(lowStockProductsProvider);
      },
      child: AdminPage(
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            LayoutBuilder(
              builder: (context, c) {
                final columns = c.maxWidth > 900 ? 4 : (c.maxWidth > 520 ? 2 : 1);
                final width = (c.maxWidth - (columns - 1) * Gap.m) / columns;
                return Wrap(
                  spacing: Gap.m,
                  runSpacing: Gap.m,
                  children: [
                    _StatTile(width: width, label: AppStrings.todayRevenue,
                        value: Money.format(today?.revenue ?? 0),
                        icon: Icons.payments_rounded, color: AppColors.primary),
                    _StatTile(width: width, label: '${AppStrings.totalOrders} ($_days d)',
                        value: '$totalOrders',
                        icon: Icons.receipt_long_rounded, color: AppColors.accent),
                    _StatTile(width: width, label: AppStrings.pendingOrders,
                        value: pending == null ? '—' : '$pending',
                        icon: Icons.pending_actions_rounded, color: AppColors.warning),
                    _StatTile(width: width, label: AppStrings.newUsers,
                        value: newUsers == null ? '—' : '$newUsers',
                        icon: Icons.person_add_alt_rounded, color: AppColors.success),
                  ],
                );
              },
            ),
            const SizedBox(height: Gap.m),
            AdminSectionCard(
              title: AppStrings.salesChart,
              trailing: SegmentedButton<int>(
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: 7, label: Text(AppStrings.last7Days)),
                  ButtonSegment(value: 30, label: Text(AppStrings.last30Days)),
                ],
                selected: {_days},
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
              child: SizedBox(
                height: 220,
                child: stats.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _SalesChart(stats: list),
              ),
            ),
            const SizedBox(height: Gap.m),
            _TopProducts(stats: list),
            const SizedBox(height: Gap.m),
            AdminSectionCard(
              title: AppStrings.lowStock,
              child: lowStock.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text(AppStrings.errGeneric),
                data: (items) => items.isEmpty
                    ? const Text(AppStrings.noLowStock)
                    : Column(children: [
                        for (final p in items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppNetworkImage(url: p.thumbnail, width: 40, height: 40),
                            ),
                            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              '${p.stock}',
                              style: TextStyle(
                                color: p.stock == 0 ? AppColors.danger : AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ]),
              ),
            ),
            const SizedBox(height: Gap.xl),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(label,
                      maxLines: 2,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.stats});

  final List<DailyStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.every((s) => s.revenue == 0)) {
      return const Center(child: Text(AppStrings.noSalesYet));
    }
    final scheme = Theme.of(context).colorScheme;
    final maxY = stats.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);
    final labelEvery = (stats.length / 6).ceil();
    final dayFmt = DateFormat('d MMM');

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(0)}k'
                    : value.toStringAsFixed(0),
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                if (i % labelEvery != 0 && i != stats.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dayFmt.format(DateTime.parse(stats[i].day)),
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final stat = stats[s.x.toInt()];
              return LineTooltipItem(
                '${Money.format(stat.revenue)}\n${stat.orders} ${AppStrings.totalOrders.toLowerCase()}',
                TextStyle(color: scheme.onInverseSurface, fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < stats.length; i++)
                FlSpot(i.toDouble(), stats[i].revenue),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: stats.length <= 10),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProducts extends ConsumerWidget {
  const _TopProducts({required this.stats});

  final List<DailyStat> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sum units sold per product across the selected period.
    final totals = <String, int>{};
    for (final s in stats) {
      s.productUnits.forEach((id, units) {
        totals[id] = (totals[id] ?? 0) + units;
      });
    }
    final top = totals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = top.take(5).toList();

    return AdminSectionCard(
      title: AppStrings.topProducts,
      child: shown.isEmpty
          ? const Text(AppStrings.noSalesYet)
          : Column(children: [
              for (final e in shown)
                Consumer(
                  builder: (context, ref, _) {
                    final product = ref.watch(productByIdProvider(e.key)).value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppNetworkImage(
                            url: product?.thumbnail, width: 40, height: 40),
                      ),
                      title: Text(product?.name ?? e.key,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text('${e.value} ${AppStrings.sold}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    );
                  },
                ),
            ]),
    );
  }
}

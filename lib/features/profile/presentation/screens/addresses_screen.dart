import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../data/models/address.dart';
import '../providers/address_providers.dart';

/// Manage addresses. With [selectMode], tapping one returns it (checkout).
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key, this.selectMode = false, this.selectedId});

  final bool selectMode;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    Future<void> openForm([Address? address]) async {
      final savedId = await context.push<String>(Routes.addressForm, extra: address);
      if (selectMode && savedId != null && context.mounted) {
        context.pop(savedId);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(AppStrings.addAddress),
      ),
      body: addresses.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: const [ShimmerBox(height: 120), SizedBox(height: Gap.m), ShimmerBox(height: 120)],
        ),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(addressesProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.location_on_outlined,
                title: AppStrings.noAddressesTitle,
                message: AppStrings.noAddressesBody,
                actionLabel: AppStrings.addAddress,
                onAction: () => openForm(),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.m),
                itemBuilder: (context, i) => AddressCard(
                  address: list[i],
                  selected: selectMode && list[i].id == selectedId,
                  onTap: selectMode ? () => context.pop(list[i].id) : null,
                  onEdit: () => openForm(list[i]),
                ),
              ),
      ),
    );
  }
}

String addressLabelText(AddressLabel l) => switch (l) {
      AddressLabel.home => AppStrings.labelHome,
      AddressLabel.work => AppStrings.labelWork,
      AddressLabel.other => AppStrings.labelOther,
    };

class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected = false,
    this.onTap,
    this.onEdit,
  });

  final Address address;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Gap.radius),
        side: BorderSide(
          color: selected ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                switch (address.label) {
                  AddressLabel.home => Icons.home_outlined,
                  AddressLabel.work => Icons.work_outline_rounded,
                  AddressLabel.other => Icons.location_on_outlined,
                },
                color: scheme.primary,
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(addressLabelText(address.label),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: Gap.s),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(AppStrings.defaultTag,
                              style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: Gap.xs),
                    Text(address.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(address.formatted, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
                    Text(address.phone, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary)
              else if (onEdit != null)
                IconButton(
                  tooltip: AppStrings.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

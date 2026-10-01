import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/option_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../cart/data/models/pricing_settings.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/widgets/price_summary_card.dart';
import '../../../profile/data/models/address.dart';
import '../../../profile/presentation/providers/address_providers.dart';
import '../../../profile/presentation/screens/addresses_screen.dart';
import '../payment_flow.dart';
import '../providers/checkout_providers.dart';

enum _Pay { online, cod }

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with AsyncActionMixin<CheckoutScreen> {
  String? _addressId;
  _Pay _pay = kIsWeb ? _Pay.cod : _Pay.online;
  bool _verifying = false;

  /// True once an order exists, so the emptied cart doesn't flash.
  bool _submitted = false;

  Address? _selected(List<Address> list) {
    if (list.isEmpty) return null;
    for (final a in list) {
      if (a.id == _addressId) return a;
    }
    return list.first; // default address sorts first
  }

  Future<void> _changeAddress(String? currentId) async {
    final id = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => AddressesScreen(selectMode: true, selectedId: currentId),
    ));
    if (id != null) setState(() => _addressId = id);
  }

  Future<void> _placeOrder(Address address) async {
    final coupon = ref.read(appliedCouponProvider);
    await runAction('place', () async {
      final result = await ref.read(checkoutRepositoryProvider).placeOrder(
            addressId: address.id,
            paymentMethod: _pay == _Pay.online ? 'razorpay' : 'cod',
            couponCode: coupon?.code,
          );
      _submitted = true;
      ref.read(appliedCouponProvider.notifier).remove();
      if (!mounted) return;
      if (result.razorpay == null) {
        context.go(Routes.orderSuccessPath(result.orderId));
      } else {
        await runOnlinePayment(context, ref, result, onVerifying: (v) {
          if (mounted) setState(() => _verifying = v);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartItemsProvider).value ?? const [];
    final summary = ref.watch(cartSummaryProvider);
    final settings = ref.watch(pricingSettingsProvider).value ?? const PricingSettings();
    final addresses = ref.watch(addressesProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    if (_verifying) {
      return const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: Gap.m),
            Text(AppStrings.verifyingPayment),
          ]),
        ),
      );
    }

    if (items.isEmpty && !_submitted && !isAnyBusy) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.checkout)),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: AppStrings.cartEmptyTitle,
          message: AppStrings.cartEmptyBody,
          actionLabel: AppStrings.continueShopping,
          onAction: () => context.go(Routes.home),
        ),
      );
    }

    final codAllowed = summary.grandTotal <= settings.codMaxAmount;
    if (!codAllowed && _pay == _Pay.cod && !kIsWeb) _pay = _Pay.online;
    final address = _selected(addresses.value ?? const []);

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: Gap.m),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(left: Gap.xs, bottom: Gap.s),
              child: Text(title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            child,
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.checkout)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              section(
                AppStrings.deliverTo,
                addresses.isLoading
                    ? const Card(child: SizedBox(height: 96, child: Center(child: CircularProgressIndicator())))
                    : address == null
                        ? Card(
                            child: ListTile(
                              minTileHeight: 72,
                              leading: const Icon(Icons.add_location_alt_outlined),
                              title: const Text(AppStrings.addAddress),
                              subtitle: const Text(AppStrings.selectAddressFirst),
                              onTap: () async {
                                final id = await context.push<String>(Routes.addressForm);
                                if (id != null) setState(() => _addressId = id);
                              },
                            ),
                          )
                        : Stack(children: [
                            AddressCard(address: address),
                            Positioned(
                              right: Gap.s,
                              top: Gap.s,
                              child: TextButton(
                                onPressed: () => _changeAddress(address.id),
                                child: const Text(AppStrings.changeAddress),
                              ),
                            ),
                          ]),
              ),
              section(
                AppStrings.deliveryOption,
                // Neighbour Drop slots join this list in Phase 5.
                const Card(
                  child: OptionTile(
                    selected: true,
                    title: AppStrings.standardDelivery,
                    subtitle: AppStrings.standardDeliveryBody,
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
              ),
              section(
                AppStrings.paymentMethod,
                Card(
                  child: Column(children: [
                    OptionTile(
                      selected: _pay == _Pay.online,
                      title: AppStrings.payOnline,
                      subtitle: kIsWeb ? AppStrings.onlineUnavailableWeb : AppStrings.payOnlineBody,
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: kIsWeb ? null : () => setState(() => _pay = _Pay.online),
                    ),
                    const Divider(height: 1),
                    OptionTile(
                      selected: _pay == _Pay.cod,
                      title: AppStrings.cashOnDelivery,
                      subtitle: codAllowed
                          ? AppStrings.codBody
                          : fill(AppStrings.codUnavailable,
                              {'amount': Money.format(settings.codMaxAmount)}),
                      icon: Icons.payments_outlined,
                      onTap: codAllowed ? () => setState(() => _pay = _Pay.cod) : null,
                    ),
                  ]),
                ),
              ),
              section(
                '${AppStrings.orderSummary} (${summary.itemCount})',
                Card(
                  child: Column(children: [
                    for (final item in items)
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(url: item.imageUrl, width: 48, height: 48),
                        ),
                        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [if (item.variantLabel != null) item.variantLabel!, '× ${item.quantity}'].join('  '),
                          style: TextStyle(color: muted),
                        ),
                        trailing: Text(Money.format(item.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ]),
                ),
              ),
              PriceSummaryCard(summary: summary),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: PrimaryButton(
              label: _pay == _Pay.online
                  ? fill(AppStrings.payAmount, {'amount': Money.format(summary.grandTotal)})
                  : '${AppStrings.placeOrder} · ${Money.format(summary.grandTotal)}',
              loading: isBusy('place'),
              onPressed: isAnyBusy || items.isEmpty
                  ? null
                  : () {
                      if (address == null) {
                        showErrorSnackBar(context, AppStrings.selectAddressFirst);
                        return;
                      }
                      _placeOrder(address);
                    },
            ),
          ),
        ),
      ),
    );
  }
}

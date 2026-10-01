import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/india_states.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../cart/data/models/pricing_settings.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/business_settings.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_product_form.dart' show Validators2;

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen>
    with AsyncActionMixin<AdminSettingsScreen> {
  final _pricingKey = GlobalKey<FormState>();
  final _rewardsKey = GlobalKey<FormState>();
  final _businessKey = GlobalKey<FormState>();

  final _deliveryFee = TextEditingController();
  final _freeAbove = TextEditingController();
  final _codMax = TextEditingController();

  final _pointsPerParcel = TextEditingController();
  final _pointsPerRupee = TextEditingController();
  final _lendingFee = TextEditingController();
  final _minOrdersSlot = TextEditingController();

  final _legalName = TextEditingController();
  final _gstin = TextEditingController();
  final _addressLine = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _state;

  /// Filled once from the server; later edits stay as typed.
  bool _pricingLoaded = false;
  bool _rewardsLoaded = false;
  bool _businessLoaded = false;

  @override
  void dispose() {
    for (final c in [
      _deliveryFee, _freeAbove, _codMax, _pointsPerParcel, _pointsPerRupee,
      _lendingFee, _minOrdersSlot, _legalName, _gstin, _addressLine, _city,
      _pincode, _email, _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _n(num v) => v % 1 == 0 ? v.toStringAsFixed(0) : '$v';

  @override
  Widget build(BuildContext context) {
    final pricing = ref.watch(pricingSettingsProvider).value;
    final rewards = ref.watch(rewardSettingsProvider).value;
    final business = ref.watch(businessSettingsProvider).value;

    if (pricing != null && !_pricingLoaded) {
      _pricingLoaded = true;
      _deliveryFee.text = _n(pricing.deliveryFee);
      _freeAbove.text = _n(pricing.freeDeliveryAbove);
      _codMax.text = _n(pricing.codMaxAmount);
    }
    if (rewards != null && !_rewardsLoaded) {
      _rewardsLoaded = true;
      _pointsPerParcel.text = '${rewards.pointsPerParcel}';
      _pointsPerRupee.text = '${rewards.pointsPerRupee}';
      _lendingFee.text = _n(rewards.lendingFeePercent);
      _minOrdersSlot.text = '${rewards.minOrdersPerSlot}';
    }
    if (business != null && !_businessLoaded) {
      _businessLoaded = true;
      _legalName.text = business.legalName;
      _gstin.text = business.gstin;
      _addressLine.text = business.addressLine;
      _city.text = business.city;
      _pincode.text = business.pincode;
      _email.text = business.email;
      _phone.text = business.phone;
      _state = business.state.isEmpty ? null : business.state;
    }

    Future<void> savePricing() async {
      if (!_pricingKey.currentState!.validate()) return;
      final ok = await runAction(
        'pricing',
        () => ref.read(adminRepositoryProvider).savePricing(PricingSettings(
              deliveryFee: double.parse(_deliveryFee.text.trim()),
              freeDeliveryAbove: double.parse(_freeAbove.text.trim()),
              codMaxAmount: double.parse(_codMax.text.trim()),
            )),
      );
      if (ok && mounted) showInfoSnackBar(context, AppStrings.settingsSaved);
    }

    Future<void> saveRewards() async {
      if (!_rewardsKey.currentState!.validate()) return;
      final ok = await runAction(
        'rewards',
        () => ref.read(adminRepositoryProvider).saveRewards(RewardSettings(
              pointsPerParcel: int.parse(_pointsPerParcel.text.trim()),
              pointsPerRupee: int.parse(_pointsPerRupee.text.trim()),
              lendingFeePercent: double.parse(_lendingFee.text.trim()),
              minOrdersPerSlot: int.parse(_minOrdersSlot.text.trim()),
            )),
      );
      if (ok && mounted) showInfoSnackBar(context, AppStrings.settingsSaved);
    }

    Future<void> saveBusiness() async {
      if (!_businessKey.currentState!.validate()) return;
      final state = _state == null ? null : stateByName(_state!);
      final ok = await runAction(
        'business',
        () => ref.read(adminRepositoryProvider).saveBusiness(BusinessSettings(
              legalName: _legalName.text.trim(),
              gstin: _gstin.text.trim().toUpperCase(),
              addressLine: _addressLine.text.trim(),
              city: _city.text.trim(),
              state: state?.name ?? '',
              stateCode: state?.gstCode ?? '',
              pincode: _pincode.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
            )),
      );
      if (ok && mounted) showInfoSnackBar(context, AppStrings.settingsSaved);
    }

    return AdminPage(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.all(Gap.m),
        children: [
          AdminSectionCard(
            title: AppStrings.settingsDelivery,
            child: Form(
              key: _pricingKey,
              child: Column(children: [
                NumberField(controller: _deliveryFee, label: AppStrings.deliveryFeeLabel, prefix: '₹ '),
                const SizedBox(height: Gap.m),
                NumberField(controller: _freeAbove, label: AppStrings.freeDeliveryAbove, prefix: '₹ '),
                const SizedBox(height: Gap.m),
                NumberField(controller: _codMax, label: AppStrings.codMaxLabel, prefix: '₹ '),
                const SizedBox(height: Gap.m),
                PrimaryButton(label: AppStrings.save, loading: isBusy('pricing'),
                    onPressed: isAnyBusy ? null : savePricing),
              ]),
            ),
          ),
          const SizedBox(height: Gap.m),
          AdminSectionCard(
            title: AppStrings.settingsRewards,
            child: Form(
              key: _rewardsKey,
              child: Column(children: [
                NumberField(controller: _pointsPerParcel, label: AppStrings.pointsPerParcel, allowDecimal: false),
                const SizedBox(height: Gap.m),
                NumberField(controller: _pointsPerRupee, label: AppStrings.pointsValue, allowDecimal: false, min: 1),
                const SizedBox(height: Gap.m),
                NumberField(controller: _lendingFee, label: AppStrings.lendingFeePercent, suffix: '%'),
                const SizedBox(height: Gap.m),
                NumberField(controller: _minOrdersSlot, label: AppStrings.minOrdersPerSlot, allowDecimal: false, min: 1),
                const SizedBox(height: Gap.m),
                PrimaryButton(label: AppStrings.save, loading: isBusy('rewards'),
                    onPressed: isAnyBusy ? null : saveRewards),
              ]),
            ),
          ),
          const SizedBox(height: Gap.m),
          AdminSectionCard(
            title: AppStrings.settingsBusiness,
            child: Form(
              key: _businessKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(AppStrings.businessHelp,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: Gap.m),
                AppTextField(controller: _legalName, label: AppStrings.legalName, validator: Validators2.required),
                const SizedBox(height: Gap.m),
                AppTextField(
                  controller: _gstin,
                  label: AppStrings.gstinLabel,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) =>
                      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9A-Z]{3}$')
                              .hasMatch((v ?? '').trim().toUpperCase())
                          ? null
                          : AppStrings.errGstin,
                ),
                const SizedBox(height: Gap.m),
                AppTextField(controller: _addressLine, label: AppStrings.address, validator: Validators2.required),
                const SizedBox(height: Gap.m),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: AppTextField(controller: _city, label: AppStrings.city, validator: Validators2.required)),
                  const SizedBox(width: Gap.m),
                  Expanded(child: AppTextField(controller: _pincode, label: AppStrings.pincode, validator: Validators2.required)),
                ]),
                const SizedBox(height: Gap.m),
                DropdownButtonFormField<String>(
                  initialValue: _state,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: AppStrings.state),
                  items: [for (final s in indiaStates) DropdownMenuItem(value: s.name, child: Text(s.name))],
                  onChanged: (v) => setState(() => _state = v),
                  validator: (v) => v == null ? AppStrings.errSelectState : null,
                ),
                const SizedBox(height: Gap.m),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: AppTextField(controller: _email, label: AppStrings.email)),
                  const SizedBox(width: Gap.m),
                  Expanded(child: AppTextField(controller: _phone, label: AppStrings.phone)),
                ]),
                const SizedBox(height: Gap.m),
                PrimaryButton(label: AppStrings.save, loading: isBusy('business'),
                    onPressed: isAnyBusy ? null : saveBusiness),
              ]),
            ),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }
}
